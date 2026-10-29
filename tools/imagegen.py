"""Imágenes de IA para la vitrina (miniaturas, ícono y anuncios) y hojas de íconos del HUD, desde una receta.

  python tools/imagegen.py prompt receta.json [--set clave=valor ...] [--ref render.png ...] [--avatar AVATAR_GIRL]
  python tools/imagegen.py generate receta.json --out carpeta [--provider gemini|openai] [--model ID] [--n 4]
         [--ref render.png ...] [--set clave=valor ...] [--avatar ...] [--quality medium] [--max-usd 3]
  python tools/imagegen.py selftest

- prompt: arma el prompt final y lo imprime con las referencias que hay que adjuntar. El prompt tiene
  el estilo de los hits (skills/_shared/vitrina/estilo-ia.json), la escena de la receta (campo "ia"),
  la luz, la composición y "sin texto". Sirve para pegarlo en ChatGPT o Gemini, o para el conector
  Higgsfield desde Claude.
- generate: llama a la API y guarda N variantes PNG en --out. Cada una lleva al lado un .json con el
  prompt, el modelo, las referencias (con su SHA-256) y el costo. Los textos se agregan después:
  python tools/thumbs.py compose receta.json --base variante.png --set ...

Las referencias son renders o capturas del juego: así la imagen muestra lo que hay adentro (regla
oficial; skills/_shared/vitrina-hits.md §2 y §6).

Hojas de íconos (recetas "kind": "iconset" de skills/_shared/iconos/recetas): 9 íconos en 3x3 con el
estilo HUD de los hits; la referencia es skills/_shared/iconos/referencia-estilo.png. Con OpenAI salen
con fondo transparente. Después se cortan con tools/iconsheet.py slice.

Proveedores (documentación oficial revisada el 2026-10-29):
- openai (por defecto): GPT Image con /v1/images/generations, o /v1/images/edits si hay referencias.
  Modelos: gpt-image-2.5-flare (el que mejor salió en las recetas), gpt-image-2.5-sunburst (más
  preciso al editar) y gpt-image-2. Clave: OPENAI_API_KEY.
- gemini: Nano Banana con la Interactions API (POST /v1beta/interactions), para comparar o para
  respetar un modelo exacto. Modelos: gemini-3-pro-image (Nano Banana Pro) y gemini-nano-banana-2.1
  (más barato). Hasta 14 referencias. Clave: GEMINI_API_KEY.
Las claves van solo en variables de entorno y nunca se imprimen.
"""
import argparse
import base64
import hashlib
import io
import json
import os
import struct
import sys
import time
import urllib.error
import urllib.request
import uuid
import zlib
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
STYLE_PATH = ROOT / "skills" / "_shared" / "vitrina" / "estilo-ia.json"
GEMINI_URL = "https://generativelanguage.googleapis.com/v1beta/interactions"
OPENAI_URL = "https://api.openai.com/v1/images"
PROVIDERS = {
    "gemini": {"env": "GEMINI_API_KEY", "model": "gemini-3-pro-image"},
    "openai": {"env": "OPENAI_API_KEY", "model": "gpt-image-2.5-flare"},
}
# Formato de salida por tipo de receta. OpenAI pide ancho y alto múltiplos de 16 (2560x1440 es el
# 16:9 más grande que no es experimental); Gemini pide proporción y tamaño.
FORMATS = {
    "thumbnail": {"openai": "2560x1440", "aspect": "16:9"},
    "ad": {"openai": "2560x1440", "aspect": "16:9"},
    "icon": {"openai": "1536x1536", "aspect": "1:1"},
    "iconset": {"openai": "1536x1536", "aspect": "1:1"},
}
GEMINI_SIZE = "2K"
# USD por imagen de 2K en Gemini (pricing oficial del 2026-10-29).
GEMINI_PRICE = {"gemini-3-pro-image": 0.134, "gemini-nano-banana-2.1": 0.0504, "gemini-3.1-flash-image": 0.101}
# OpenAI cobra por tokens. Estimación por imagen: tabla oficial de GPT Image 2 a 1536x1024; GPT Image
# 2.5 usa las mismas tarifas pero no los mismos tokens. El costo real sale de "usage".
OPENAI_ESTIMATE = {"low": 0.005, "medium": 0.041, "high": 0.165}
OPENAI_RATES = {"text": 5.0, "image": 8.0, "output": 30.0}  # USD por millón de tokens
MAX_REF_EDGE = 2048
MIME = {".png": "image/png", ".jpg": "image/jpeg", ".jpeg": "image/jpeg", ".webp": "image/webp"}


class GenError(Exception):
    pass


def load_style(path: Path = STYLE_PATH) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def fill(text: str, values: dict) -> str:
    for key, val in values.items():
        text = text.replace("{{" + key + "}}", val)
    missing = sorted(set(part.split("}}")[0] for part in text.split("{{")[1:]))
    if missing:
        raise GenError(f"faltan valores: {', '.join(missing)} (usar --set clave=valor, en inglés)")
    return text


def build_prompt(recipe: dict, values: dict, has_refs: bool, style: dict, avatar: str = "AVATAR") -> str:
    kind = recipe.get("kind", "thumbnail")
    if "ia" not in recipe:
        raise GenError("la receta no tiene el campo \"ia\" con la escena")
    if avatar not in style["avatars"]:
        raise GenError(f"avatar desconocido: {avatar} (hay: {', '.join(style['avatars'])})")
    merged = dict(style["avatars"])
    merged["AVATAR"] = style["avatars"][avatar]
    merged.update(recipe.get("_defaults", {}))
    merged.update(values)
    if kind == "iconset":
        block = style["iconset"]
        # "redraw": la referencia es nuestra base 3D de esos mismos íconos (tools/render3d/icons.cjs).
        ref_text = block["redraw"] if recipe["ia"].get("mode") == "redraw" else block["references"]
        parts = [block["style"]] + ([ref_text] if has_refs else [])
        return "\n\n".join(parts + [fill(recipe["ia"]["prompt"], merged), block["background"], block["negative"]])
    parts = [style["style"][kind]]
    if has_refs:
        parts.append(style["references"])
    parts.append("Scene: " + fill(recipe["ia"]["prompt"], merged))
    parts += [style["light"], style["composition"][kind], style["negative"]]
    return "\n\n".join(parts)


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def load_ref(path: Path) -> tuple:
    """(bytes, mime) de una referencia; si pasa de 2048 px se achica para no pagar tokens de más."""
    mime = MIME.get(path.suffix.lower())
    if not mime:
        raise GenError(f"{path}: la referencia tiene que ser PNG, JPG o WebP")
    data = path.read_bytes()
    try:
        from PIL import Image
    except ImportError:
        return data, mime
    with Image.open(io.BytesIO(data)) as img:
        if max(img.size) <= MAX_REF_EDGE:
            return data, mime
        img.thumbnail((MAX_REF_EDGE, MAX_REF_EDGE), Image.LANCZOS)
        out = io.BytesIO()
        img.save(out, format="PNG")
        return out.getvalue(), "image/png"


def multipart(fields: dict, files: list, boundary: str = "") -> tuple:
    """multipart/form-data con campos de texto y archivos [(nombre del campo, archivo, mime, bytes)]."""
    boundary = boundary or uuid.uuid4().hex
    body = b""
    for name, value in fields.items():
        body += (f"--{boundary}\r\nContent-Disposition: form-data; name=\"{name}\"\r\n\r\n{value}\r\n").encode("utf-8")
    for field, filename, mime, data in files:
        safe = filename.replace('"', "")
        body += (f"--{boundary}\r\nContent-Disposition: form-data; name=\"{field}\"; filename=\"{safe}\"\r\n"
                 f"Content-Type: {mime}\r\n\r\n").encode("utf-8") + data + b"\r\n"
    body += f"--{boundary}--\r\n".encode("utf-8")
    return body, f"multipart/form-data; boundary={boundary}"


def http(url: str, headers: dict, body: bytes, content_type: str, attempts: int = 3) -> dict:
    headers = dict(headers, **{"Content-Type": content_type, "Accept": "application/json",
                               "User-Agent": "RobloxCreator-imagegen/1.0"})
    for attempt in range(attempts):
        req = urllib.request.Request(url, data=body, method="POST", headers=headers)
        try:
            with urllib.request.urlopen(req, timeout=300) as r:
                return json.loads(r.read().decode("utf-8") or "{}")
        except urllib.error.HTTPError as e:
            detail = e.read().decode("utf-8", "replace")[:500]
            # Un bloqueo de moderación o un pedido inválido no se arregla reintentando.
            if e.code in (429, 500, 502, 503, 504) and attempt < attempts - 1:
                time.sleep(2 ** (attempt + 1))
                continue
            raise GenError(f"HTTP {e.code}: {detail}")
        except urllib.error.URLError as e:
            if attempt < attempts - 1:
                time.sleep(2 ** (attempt + 1))
                continue
            raise GenError(f"sin conexión: {e.reason}")
    raise GenError("sin respuesta")


def openai_request(key: str, model: str, prompt: str, refs: list, size: str, quality: str, n: int,
                   background: str = "auto") -> tuple:
    headers = {"Authorization": f"Bearer {key}"}
    if refs:
        fields = {"model": model, "prompt": prompt, "size": size, "quality": quality, "n": str(n), "output_format": "png",
                  "background": background}
        files = [("image[]", name, mime, data) for name, mime, data in refs]
        body, ctype = multipart(fields, files)
        return f"{OPENAI_URL}/edits", headers, body, ctype
    payload = {"model": model, "prompt": prompt, "size": size, "quality": quality, "n": n, "output_format": "png",
               "background": background}
    return f"{OPENAI_URL}/generations", headers, json.dumps(payload).encode("utf-8"), "application/json"


def gemini_request(key: str, model: str, prompt: str, refs: list, aspect: str) -> tuple:
    content = [{"type": "text", "text": prompt}]
    for _, mime, data in refs:
        content.append({"type": "image", "mime_type": mime, "data": base64.b64encode(data).decode("ascii")})
    payload = {"model": model, "input": content,
               "response_format": {"type": "image", "aspect_ratio": aspect, "image_size": GEMINI_SIZE}}
    return GEMINI_URL, {"x-goog-api-key": key}, json.dumps(payload).encode("utf-8"), "application/json"


def openai_images(resp: dict) -> list:
    return [(base64.b64decode(item["b64_json"]), "image/png") for item in resp.get("data", []) if item.get("b64_json")]


def gemini_images(resp) -> list:
    """Bloques de imagen de la respuesta (steps[].content[] de tipo "image"), buscados en todo el JSON."""
    found = []
    if isinstance(resp, dict):
        if resp.get("type") == "image" and resp.get("data"):
            found.append((base64.b64decode(resp["data"]), resp.get("mime_type", "image/png")))
        for value in resp.values():
            found += gemini_images(value)
    elif isinstance(resp, list):
        for value in resp:
            found += gemini_images(value)
    return found


def openai_cost(usage: dict) -> float:
    details = usage.get("input_tokens_details") or {}
    text_in = details.get("text_tokens", 0)
    image_in = details.get("image_tokens", usage.get("input_tokens", 0) - text_in)
    return round((text_in * OPENAI_RATES["text"] + image_in * OPENAI_RATES["image"]
                  + usage.get("output_tokens", 0) * OPENAI_RATES["output"]) / 1_000_000, 4)


def estimate(provider: str, model: str, quality: str, n: int):
    if provider == "gemini":
        price = GEMINI_PRICE.get(model)
    else:
        price = OPENAI_ESTIMATE.get(quality)
    return None if price is None else round(price * n, 3)


def cmd_prompt(args) -> int:
    recipe = json.loads(Path(args.recipe).read_text(encoding="utf-8"))
    values = dict(v.split("=", 1) for v in args.set or [])
    try:
        prompt = build_prompt(recipe, values, bool(args.ref), load_style(), args.avatar)
    except GenError as e:
        print(e, file=sys.stderr)
        return 2
    print(prompt)
    kind = recipe.get("kind", "thumbnail")
    print(f"\n--- formato: {FORMATS[kind]['aspect']} (en ChatGPT pedir \"{FORMATS[kind]['aspect']}\"; en Gemini elegir la proporción)")
    for ref in args.ref or []:
        print(f"--- adjuntar: {ref}")
    return 0


def cmd_generate(args, send=http, env=os.environ) -> int:
    recipe_path = Path(args.recipe)
    recipe = json.loads(recipe_path.read_text(encoding="utf-8"))
    kind = recipe.get("kind", "thumbnail")
    provider = args.provider or "openai"
    model = args.model or PROVIDERS[provider]["model"]
    values = dict(v.split("=", 1) for v in args.set or [])
    try:
        refs = []
        for ref in args.ref or []:
            data, mime = load_ref(Path(ref))
            refs.append((Path(ref).name, mime, data))
        prompt = build_prompt(recipe, values, bool(refs), load_style(), args.avatar)
    except (GenError, OSError) as e:
        print(e, file=sys.stderr)
        return 2
    cost = estimate(provider, model, args.quality, args.n)
    if cost is not None and cost > args.max_usd:
        print(f"Costo estimado {cost} USD: supera --max-usd {args.max_usd}. Subir el tope si es a propósito.", file=sys.stderr)
        return 2
    key = env.get(PROVIDERS[provider]["env"], "")
    if not key:
        print(f"Falta la clave en la variable de entorno {PROVIDERS[provider]['env']} (SETUP.md). "
              f"Sin clave: python tools/imagegen.py prompt ... y pegarlo en ChatGPT o Gemini.", file=sys.stderr)
        return 2
    print(f"  {provider} · {model} · {args.n} variante(s) · {len(refs)} referencia(s) · "
          f"costo estimado {cost if cost is not None else 'según uso'} USD")
    images, usage = [], {}
    try:
        if provider == "openai":
            background = "transparent" if kind == "iconset" else "auto"
            url, headers, body, ctype = openai_request(key, model, prompt, refs, FORMATS[kind]["openai"], args.quality,
                                                       args.n, background)
            resp = send(url, headers, body, ctype)
            images, usage = openai_images(resp), resp.get("usage") or {}
        else:
            for _ in range(args.n):
                url, headers, body, ctype = gemini_request(key, model, prompt, refs, FORMATS[kind]["aspect"])
                images += gemini_images(send(url, headers, body, ctype))[-1:]
    except GenError as e:
        print(f"  [error] {e}", file=sys.stderr)
        if not images:
            return 1
    if not images:
        print("  [error] la respuesta no trajo imágenes", file=sys.stderr)
        return 1
    if usage:
        cost = openai_cost(usage)
    out_dir = Path(args.out)
    out_dir.mkdir(parents=True, exist_ok=True)
    stamp = datetime.now(timezone.utc).strftime("%Y%m%d-%H%M%S")
    for i, (data, mime) in enumerate(images, 1):
        ext = ".jpg" if mime == "image/jpeg" else ".webp" if mime == "image/webp" else ".png"
        path = out_dir / f"{recipe_path.stem}-{stamp}-{i}{ext}"
        path.write_bytes(data)
        meta = {
            "recipe": recipe_path.as_posix(), "provider": provider, "model": model, "kind": kind,
            "format": FORMATS[kind]["openai"] if provider == "openai" else f"{FORMATS[kind]['aspect']} {GEMINI_SIZE}",
            "quality": args.quality if provider == "openai" else None, "avatar": args.avatar, "values": values,
            "refs": [{"file": name, "sha256": sha256(data_ref)} for name, _, data_ref in refs],
            "prompt": prompt, "cost_usd": cost, "usage": usage or None, "sha256": sha256(data),
            "created": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        }
        path.with_suffix(path.suffix + ".json").write_text(json.dumps(meta, ensure_ascii=False, indent=2), encoding="utf-8")
        print(f"  [ok] {path}")
    if kind == "iconset":
        print(f"  Siguiente: python tools/iconsheet.py slice <hoja> --grid {recipe.get('grid', '3x3')} "
              f"--names {','.join(recipe.get('names', []))} --out <carpeta>")
    else:
        print(f"  Siguiente: python tools/thumbs.py compose {recipe_path.as_posix()} --base <variante> --set ... --out <final>")
    return 0


def tiny_png(rgb=(255, 200, 40)) -> bytes:
    def chunk(tag, data):
        return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)
    raw = b"".join(b"\x00" + bytes(rgb) * 2 for _ in range(2))
    return (b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", 2, 2, 8, 2, 0, 0, 0))
            + chunk(b"IDAT", zlib.compress(raw)) + chunk(b"IEND", b""))


def selftest() -> int:
    import tempfile

    style = load_style()
    recipe = {"kind": "thumbnail", "ia": {"aspect": "16:9", "prompt": "{{AVATAR}} hugs {{prize_desc}}."}}
    prompt = build_prompt(recipe, {"prize_desc": "a golden egg"}, True, style)
    assert prompt.startswith(style["style"]["thumbnail"]) and style["references"] in prompt
    assert "bacon" in prompt and "a golden egg" in prompt and prompt.endswith(style["negative"])
    assert style["references"] not in build_prompt(recipe, {"prize_desc": "x"}, False, style)
    assert "pink hair" in build_prompt(recipe, {"prize_desc": "x"}, False, style, "AVATAR_GIRL")
    for bad in ({}, {"prize_desc": "x", "AVATAR": "y"}):
        try:
            build_prompt(recipe, bad, False, style, "NOPE" if bad else "AVATAR")
            raise AssertionError("tenía que fallar")
        except GenError:
            pass
    # Las recetas del repo arman su prompt con valores de ejemplo.
    shared = ROOT / "skills" / "_shared"
    for path in sorted((shared / "vitrina" / "recetas").glob("*.json")) + sorted((shared / "iconos" / "recetas").glob("*.json")):
        r = json.loads(path.read_text(encoding="utf-8"))
        names = set(part.split("}}")[0] for part in r["ia"]["prompt"].split("{{")[1:]) - set(style["avatars"])
        build_prompt(r, {n: "x" for n in names}, False, style)
        assert FORMATS[r["kind"]]["aspect"] == r["ia"]["aspect"], path.name
        if r["kind"] == "iconset":
            rows, cols = (int(x) for x in r["grid"].split("x"))
            assert len(r["names"]) == rows * cols == r["ia"]["prompt"].count(") "), path.name
    icons = {"kind": "iconset", "grid": "3x3", "names": list("abcdefghi"), "ia": {"aspect": "1:1", "prompt": "Icons: 1) a coin."}}
    sheet = build_prompt(icons, {}, True, style)
    assert sheet.startswith(style["iconset"]["style"]) and style["iconset"]["references"] in sheet
    redraw = build_prompt({**icons, "ia": {**icons["ia"], "mode": "redraw"}}, {}, True, style)
    assert style["iconset"]["redraw"] in redraw and style["iconset"]["references"] not in redraw
    assert sheet.endswith(style["iconset"]["negative"]) and style["light"] not in sheet
    body, ctype = multipart({"model": "m"}, [("image[]", "a.png", "image/png", b"PNG")], boundary="B")
    assert ctype == "multipart/form-data; boundary=B" and b'name="image[]"; filename="a.png"' in body
    assert openai_cost({"input_tokens": 1000, "input_tokens_details": {"text_tokens": 200, "image_tokens": 800},
                        "output_tokens": 4000}) == round((200 * 5 + 800 * 8 + 4000 * 30) / 1e6, 4)
    png = tiny_png()
    with tempfile.TemporaryDirectory() as tmp:
        tmp = Path(tmp)
        (tmp / "r.json").write_text(json.dumps(recipe), encoding="utf-8")
        (tmp / "ref.png").write_bytes(png)
        sent = []

        def fake(url, headers, body, ctype):
            sent.append((url, headers, body, ctype))
            if "openai" in url:
                return {"data": [{"b64_json": base64.b64encode(png).decode()}] * 2,
                        "usage": {"input_tokens": 10, "output_tokens": 100}}
            return {"id": "i", "steps": [{"type": "model_output", "content": [
                {"type": "text", "text": "ok"}, {"type": "image", "mime_type": "image/png", "data": base64.b64encode(png).decode()}]}]}

        base = dict(recipe=str(tmp / "r.json"), out=str(tmp / "out"), set=["prize_desc=a golden egg"],
                    ref=[str(tmp / "ref.png")], avatar="AVATAR", quality="medium", max_usd=3.0, model=None)
        # Gemini: un pedido por variante, referencias en base64, proporción y tamaño.
        args = argparse.Namespace(provider="gemini", n=2, **base)
        assert cmd_generate(args, send=fake, env={"GEMINI_API_KEY": "k"}) == 0
        assert len(sent) == 2 and sent[0][0] == GEMINI_URL and sent[0][1] == {"x-goog-api-key": "k"}
        payload = json.loads(sent[0][2])
        assert payload["model"] == "gemini-3-pro-image" and payload["input"][1]["type"] == "image"
        assert payload["response_format"] == {"type": "image", "aspect_ratio": "16:9", "image_size": "2K"}
        outs = sorted((tmp / "out").glob("*.png"))
        assert len(outs) == 2 and outs[0].read_bytes() == png
        meta = json.loads(outs[0].with_suffix(".png.json").read_text(encoding="utf-8"))
        assert meta["refs"][0]["sha256"] == sha256(png) and meta["cost_usd"] == 0.268 and "k" not in json.dumps(meta["values"])
        # OpenAI: con referencias va a /edits en multipart; sin referencias, JSON a /generations.
        sent.clear()
        args = argparse.Namespace(provider="openai", n=2, **dict(base, out=str(tmp / "o1")))
        assert cmd_generate(args, send=fake, env={"OPENAI_API_KEY": "k"}) == 0
        assert sent[0][0] == f"{OPENAI_URL}/edits" and sent[0][3].startswith("multipart/form-data")
        assert b"gpt-image-2.5-flare" in sent[0][2] and b"2560x1440" in sent[0][2] and sent[0][1]["Authorization"] == "Bearer k"
        assert len(list((tmp / "o1").glob("*.png"))) == 2
        sent.clear()
        args = argparse.Namespace(provider="openai", n=1, **dict(base, out=str(tmp / "o2"), ref=[]))
        assert cmd_generate(args, send=fake, env={"OPENAI_API_KEY": "k"}) == 0
        assert sent[0][0] == f"{OPENAI_URL}/generations" and json.loads(sent[0][2])["quality"] == "medium"
        assert json.loads(sent[0][2])["background"] == "auto"
        # Hoja de íconos: fondo transparente en OpenAI.
        sent.clear()
        (tmp / "i.json").write_text(json.dumps(icons), encoding="utf-8")
        args = argparse.Namespace(provider=None, n=1, **dict(base, recipe=str(tmp / "i.json"), out=str(tmp / "o3"), ref=[], set=[]))
        assert cmd_generate(args, send=fake, env={"OPENAI_API_KEY": "k"}) == 0
        payload = json.loads(sent[0][2])
        assert payload["background"] == "transparent" and payload["size"] == "1536x1536"
        # Sin clave o por encima del tope no se llama a la API.
        sent.clear()
        assert cmd_generate(argparse.Namespace(provider="gemini", n=1, **base), send=fake, env={}) == 2
        assert cmd_generate(argparse.Namespace(provider="gemini", n=40, **base), send=fake, env={"GEMINI_API_KEY": "k"}) == 2
        assert not sent
    print("selftest OK")
    return 0


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    sub = parser.add_subparsers(dest="cmd", required=True)
    for name in ("prompt", "generate"):
        p = sub.add_parser(name)
        p.add_argument("recipe")
        p.add_argument("--set", action="append", help="clave=valor (en inglés) para {{clave}} de la escena")
        p.add_argument("--ref", action="append", help="render o captura del juego que la IA tiene que respetar")
        p.add_argument("--avatar", default="AVATAR", help="AVATAR, AVATAR_GIRL o AVATAR_NOOB (estilo-ia.json)")
        if name == "generate":
            p.add_argument("--out", required=True)
            p.add_argument("--provider", choices=sorted(PROVIDERS), help="openai (por defecto) o gemini")
            p.add_argument("--model")
            p.add_argument("--n", type=int, default=4)
            p.add_argument("--quality", default="medium", choices=["low", "medium", "high", "xhigh", "max"],
                           help="solo OpenAI")
            p.add_argument("--max-usd", type=float, default=3.0, help="tope del costo estimado de la corrida")
    sub.add_parser("selftest")
    args = parser.parse_args(argv)
    if args.cmd == "prompt":
        return cmd_prompt(args)
    if args.cmd == "generate":
        return cmd_generate(args)
    return selftest()


if __name__ == "__main__":
    sys.exit(main())
