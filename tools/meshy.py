#!/usr/bin/env python3
"""Modelos 3D con IA (Meshy) por su API REST, sin el MCP: anda igual en la nube y en las PCs.

  python tools/meshy.py image <imagen.png> --out <carpeta> [--name id] [--model smart|latest|meshy-6]
                        [--polycount N] [--texture 2k|4k|8k|none] [--formats glb,fbx] [--max-credits 40] [--dry-run]
  python tools/meshy.py batch <carpeta-con-imagenes> --out <carpeta> [--only a,b] [mismas opciones] [--max-credits 300]
  python tools/meshy.py selftest

- image: una imagen (el ícono de la unidad hecho con GPT Image) → modelo 3D con textura. Espera la tarea
  y baja enseguida el modelo, la textura y las vistas previas: Meshy las guarda solo 3 días. Al lado deja
  <id>.json con lo pedido (sin la imagen ni la clave), el id de la tarea, los créditos y el SHA-256 de
  la imagen.
- batch: cada PNG de la carpeta (o los de --only), salteando los que ya tienen modelo en --out.
- --model smart (por defecto): Smart Topology (meshy-t2.5), la malla limpia de juego que recomienda
  skills/_shared/conectores.md, hecha a --polycount caras; con textura 2K cuesta 15 créditos. latest
  (meshy-7.1) da más detalle, cuesta 30 y se remalla a --polycount.
- --polycount: 5.000 caras por defecto (mascotas: de 2.000 a 6.000; objetos repetidos: de 500 a 2.000).
  Roblox acepta hasta 20.000 triángulos por malla.
- Lo generado va a meshy_output/ (Git lo ignora). Al repo pasa solo lo elegido, a assets/3d/meshy/<nombre>/.
- --dry-run: muestra el pedido y el costo, sin mandar nada ni gastar créditos.

Documentación oficial revisada el 2026-11-03 (https://docs.meshy.ai/api/image-to-3d, /api/pricing,
/api/authentication, /api/asset-retention):
- POST https://api.meshy.ai/openapi/v1/image-to-3d con `image_url` como data URI en base64 (PNG, JPG o
  WebP de hasta 20 MB y al menos 32 px por lado) → `result` es el id de la tarea.
- GET .../image-to-3d/<id> hasta SUCCEEDED, FAILED o CANCELED, esperando `Retry-After` (5 s si no viene).
- `model_urls`, `texture_urls`, `thumbnail_urls` (con `multi_view_thumbnails`) y `alpha_thumbnail_url`
  son enlaces firmados que vencen: se bajan sin la clave.
- La clave va en `MESHY_API_KEY` (Bearer msy_...), solo en variables de entorno, y nunca se imprime. La
  API usa créditos prepagos de un plan pago: sin créditos responde 402.
Para Roblox: el GLB o el FBX van al 3D Importer de Studio (Scale Unit: Studs) y el juego los toma de
ReplicatedStorage.Assets.Units[def.model] (skills/roblox-game-kits). Registrar cada modelo en
assets/index.json (source "ai-generated") y en assets/LICENSES.md en el mismo cambio.
"""
import argparse
import base64
import hashlib
import json
import os
import sys
import tempfile
import time
import urllib.error
import urllib.request
from pathlib import Path

API = "https://api.meshy.ai/openapi/v1/image-to-3d"
TERMINAL = {"SUCCEEDED", "FAILED", "CANCELED"}
POLL_SECONDS = 5
MAX_WAIT = 30 * 60
USER_AGENT = "RobloxCreator-meshy/1.0"
MIME = {".png": "image/png", ".jpg": "image/jpeg", ".jpeg": "image/jpeg", ".webp": "image/webp"}
# Roblox acepta hasta 20.000 triángulos por malla (/art/modeling/specifications, verificado el
# 2026-11-03). Por defecto, una malla de mascota liviana para el teléfono.
ROBLOX_MAX_TRIANGLES = 20000
DEFAULT_POLYCOUNT = 5000  # mascotas: de 2.000 a 6.000 caras (skills/_shared/conectores.md, Meshy)

# Créditos por pedido de Image to 3D (tabla oficial del 2026-11-03).
COST = {
    "latest": {"none": 20, "2k": 30, "4k": 30, "8k": 35},
    "meshy-6": {"none": 20, "2k": 30, "4k": 30, "8k": 35},
    "smart": {"none": 5, "2k": 15, "4k": 15, "8k": 20},
}


class MeshyError(Exception):
    pass


def credits(model: str, texture: str) -> int:
    return COST[model][texture]


def build_request(image: bytes, mime: str, model: str, texture: str, polycount: int, formats: list) -> dict:
    """El cuerpo del pedido, siempre con una malla que Roblox acepta (`polycount` 0 = DEFAULT_POLYCOUNT)."""
    faces = polycount or DEFAULT_POLYCOUNT
    if not 100 <= faces <= ROBLOX_MAX_TRIANGLES:
        raise MeshyError(f"--polycount tiene que estar entre 100 y {ROBLOX_MAX_TRIANGLES} (límite de Roblox por malla)")
    body: dict = {
        "image_url": f"data:{mime};base64,{base64.b64encode(image).decode('ascii')}",
        "should_texture": texture != "none",
        "target_formats": formats,
        "multi_view_thumbnails": True,
        "alpha_thumbnail": True,
    }
    if texture != "none":
        body["texture_resolution"] = texture
    if model == "smart":
        body.update(model_type="smart-topology", ai_model="meshy-t2.5", target_polycount=faces)
    else:
        body.update(ai_model=model, should_remesh=True, topology="triangle", target_polycount=faces)
    return body


def shown(body: dict) -> dict:
    """El pedido para mostrar o guardar: sin la imagen."""
    out = dict(body)
    out["image_url"] = out["image_url"][:30] + "...(base64)"
    return out


def http(method: str, url: str, key: str, payload: dict = None, attempts: int = 4) -> tuple:
    """(json, segundos de Retry-After o None). Reintenta 429 y 5xx respetando Retry-After."""
    data = json.dumps(payload).encode("utf-8") if payload is not None else None
    headers = {"Authorization": f"Bearer {key}", "Accept": "application/json", "User-Agent": USER_AGENT}
    if data is not None:
        headers["Content-Type"] = "application/json"
    for attempt in range(attempts):
        req = urllib.request.Request(url, data=data, method=method, headers=headers)
        try:
            with urllib.request.urlopen(req, timeout=120) as r:
                retry = r.headers.get("Retry-After")
                return json.loads(r.read().decode("utf-8") or "{}"), (int(retry) if retry and retry.isdigit() else None)
        except urllib.error.HTTPError as e:
            detail = e.read().decode("utf-8", "replace")[:300]
            if e.code in (429, 500, 502, 503, 504) and attempt < attempts - 1:
                retry = e.headers.get("Retry-After")
                time.sleep(int(retry) if retry and retry.isdigit() else 2 ** (attempt + 1))
                continue
            hints = {401: "clave inválida o ausente (MESHY_API_KEY)", 402: "sin créditos de API o plan gratis",
                     403: "la moderación bloqueó la imagen", 429: "límite de pedidos"}
            raise MeshyError(f"HTTP {e.code} ({hints.get(e.code, 'pedido rechazado')}): {detail}")
        except urllib.error.URLError as e:
            if attempt < attempts - 1:
                time.sleep(2 ** (attempt + 1))
                continue
            raise MeshyError(f"sin conexión: {e.reason}")
    raise MeshyError("sin respuesta")


def fetch(url: str) -> bytes:
    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(req, timeout=300) as r:
        return r.read()


def wait(task_id: str, key: str, send=http, sleep=time.sleep, clock=time.monotonic) -> dict:
    start = clock()
    while True:
        task, retry = send("GET", f"{API}/{task_id}", key)
        status = task.get("status")
        if status in TERMINAL:
            if status != "SUCCEEDED":
                error = (task.get("task_error") or {}).get("message") or "sin detalle"
                raise MeshyError(f"la tarea {task_id} terminó {status}: {error}")
            return task
        if clock() - start > MAX_WAIT:
            raise MeshyError(f"la tarea {task_id} sigue {status} después de {MAX_WAIT // 60} min")
        sleep(retry or POLL_SECONDS)


def save_outputs(task: dict, out: Path, name: str, get=fetch) -> list:
    """Baja el modelo, la textura y las vistas previas. Devuelve los archivos guardados."""
    files = []

    def keep(url, filename):
        if url:
            path = out / filename
            path.write_bytes(get(url))
            files.append(path)

    for fmt, url in (task.get("model_urls") or {}).items():
        if fmt in ("glb", "fbx", "obj", "usdz", "stl"):
            keep(url, f"{name}.{fmt}")
    textures = task.get("texture_urls") or []
    if textures:
        keep(textures[0].get("base_color"), f"{name}_texture.png")
    keep(task.get("alpha_thumbnail_url") or task.get("thumbnail_url"), f"{name}_preview.png")
    for side, url in (task.get("thumbnail_urls") or {}).items():
        keep(url, f"{name}_{side}.png")
    return files


def generate(image_path: Path, out: Path, name: str, args, key: str, send=http, get=fetch, sleep=time.sleep) -> dict:
    image = image_path.read_bytes()
    mime = MIME.get(image_path.suffix.lower())
    if not mime:
        raise MeshyError(f"{image_path}: tiene que ser PNG, JPG o WebP")
    if len(image) > 20 * 1024 * 1024:
        raise MeshyError(f"{image_path}: pesa más de 20 MB")
    body = build_request(image, mime, args.model, args.texture, args.polycount, args.formats)
    cost = credits(args.model, args.texture)
    if args.dry_run:
        print(f"  [dry-run] {image_path.name} → {name}: {cost} créditos\n  " + json.dumps(shown(body)))
        return {"dry_run": True, "credits": cost}
    out.mkdir(parents=True, exist_ok=True)
    created, _ = send("POST", API, key, body)
    task_id = created.get("result")
    if not task_id:
        raise MeshyError(f"Meshy no devolvió el id de la tarea: {created}")
    print(f"  {name}: tarea {task_id} creada ({cost} créditos estimados), esperando...")
    task = wait(task_id, key, send, sleep)
    files = save_outputs(task, out, name, get)
    record = {
        "task": task_id,
        "request": shown(body),
        "image": {"path": image_path.as_posix(), "sha256": hashlib.sha256(image).hexdigest()},
        "credits": task.get("consumed_credits", cost),
        "files": [f.name for f in files],
        "generatedAt": time.strftime("%Y-%m-%d"),
        "source": "ai-generated (Meshy Image to 3D)",
    }
    (out / f"{name}.json").write_text(json.dumps(record, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"  {name}: listo ({record['credits']} créditos) → " + ", ".join(record["files"]))
    return record


def key_or_fail(env=os.environ) -> str:
    key = env.get("MESHY_API_KEY", "")
    if not key:
        raise MeshyError("falta MESHY_API_KEY (en la nube: secreto del entorno; en la PC: variable de entorno). "
                         "Ver SETUP.md, paso 7, y skills/_shared/conectores.md")
    return key


def cmd_image(args, env=os.environ) -> int:
    key = "" if args.dry_run else key_or_fail(env)
    cost = credits(args.model, args.texture)
    if cost > args.max_credits:
        raise MeshyError(f"cuesta {cost} créditos y el tope es {args.max_credits} (--max-credits)")
    path = Path(args.image)
    generate(path, Path(args.out), args.name or path.stem, args, key)
    return 0


def cmd_batch(args, env=os.environ) -> int:
    folder, out = Path(args.folder), Path(args.out)
    only = {n.strip() for n in args.only.split(",")} if args.only else None
    todo = []
    for path in sorted(folder.iterdir()):
        if path.suffix.lower() not in MIME or (only is not None and path.stem not in only):
            continue
        if (out / f"{path.stem}.json").exists():
            print(f"  {path.stem}: ya tiene modelo, se saltea")
            continue
        todo.append(path)
    total = credits(args.model, args.texture) * len(todo)
    print(f"  {len(todo)} modelo(s), {total} créditos estimados")
    if total > args.max_credits:
        raise MeshyError(f"la corrida cuesta {total} créditos y el tope es {args.max_credits} (--max-credits)")
    key = "" if args.dry_run else key_or_fail(env)
    for path in todo:
        generate(path, out, path.stem, args, key)
    return 0


def selftest() -> int:
    png = base64.b64decode("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFBQIAX8jx0gAAAABJRU5ErkJggg==")
    args = argparse.Namespace(model="smart", texture="2k", polycount=0, formats=["glb", "fbx"], dry_run=False,
                              max_credits=40, name=None)
    body = build_request(png, "image/png", "smart", "2k", 0, ["glb", "fbx"])
    assert body["image_url"].startswith("data:image/png;base64,"), body["image_url"][:40]
    assert body["model_type"] == "smart-topology" and body["ai_model"] == "meshy-t2.5"
    assert body["target_polycount"] == DEFAULT_POLYCOUNT and body["texture_resolution"] == "2k"
    assert "image_enhancement" not in body, "smart-topology rechaza image_enhancement (400)"
    std = build_request(png, "image/png", "latest", "none", 6000, ["glb"])
    assert std["should_texture"] is False and "texture_resolution" not in std
    assert std["should_remesh"] is True and std["topology"] == "triangle" and std["target_polycount"] == 6000
    payload = body["image_url"].split(",", 1)[1]
    assert payload not in json.dumps(shown(body)) and len(shown(body)["image_url"]) < 60, "lo mostrado no lleva la imagen"
    assert credits("smart", "2k") == 15 and credits("latest", "2k") == 30
    latest = build_request(png, "image/png", "latest", "2k", 0, ["glb"])
    assert latest["should_remesh"] is True and latest["target_polycount"] == DEFAULT_POLYCOUNT, "latest siempre remalla"
    try:
        build_request(png, "image/png", "latest", "2k", 50000, ["glb"])
        raise AssertionError("más de 20.000 caras no entra en Roblox")
    except MeshyError:
        pass

    calls = []
    states = iter([({"status": "PENDING"}, 7), ({"status": "IN_PROGRESS", "progress": 60}, None),
                   ({"status": "SUCCEEDED", "consumed_credits": 15,
                     "model_urls": {"glb": "u/glb", "fbx": "u/fbx", "pre_remeshed_glb": "u/pre"},
                     "texture_urls": [{"base_color": "u/tex"}], "alpha_thumbnail_url": "u/alpha",
                     "thumbnail_urls": {"front": "u/front"}}, None)])

    def send(method, url, key, payload=None):
        calls.append((method, url, key, payload is not None))
        if method == "POST":
            return {"result": "task-1"}, None
        return next(states)

    slept = []
    with tempfile.TemporaryDirectory() as tmp:
        src = Path(tmp) / "pebble_pup.png"
        src.write_bytes(png)
        out = Path(tmp) / "out"
        record = generate(src, out, "pebble_pup", args, "msy_test", send=send, get=lambda url: url.encode(),
                          sleep=slept.append)
        assert calls[0][:2] == ("POST", API) and calls[0][3], calls
        assert calls[1][1] == f"{API}/task-1", calls
        assert slept == [7, POLL_SECONDS], f"respeta Retry-After y después {POLL_SECONDS} s: {slept}"
        names = sorted(p.name for p in out.iterdir())
        assert names == ["pebble_pup.fbx", "pebble_pup.glb", "pebble_pup.json", "pebble_pup_front.png",
                         "pebble_pup_preview.png", "pebble_pup_texture.png"], names
        saved = json.loads((out / "pebble_pup.json").read_text(encoding="utf-8"))
        assert saved["credits"] == 15 and saved["task"] == "task-1" and "msy_" not in json.dumps(saved)
        assert record["image"]["sha256"] == hashlib.sha256(png).hexdigest()

    failed = iter([({"status": "FAILED", "task_error": {"message": "bad image"}}, None)])
    try:
        wait("task-2", "k", send=lambda *a, **k: next(failed), sleep=lambda s: None)
        raise AssertionError("una tarea FAILED tiene que dar error")
    except MeshyError as e:
        assert "bad image" in str(e)
    try:
        key_or_fail({})
        raise AssertionError("sin clave tiene que dar error")
    except MeshyError as e:
        assert "MESHY_API_KEY" in str(e)
    print("selftest OK")
    return 0


def main(argv=None) -> int:
    sys.stdout.reconfigure(encoding="utf-8")
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    sub = parser.add_subparsers(dest="cmd", required=True)
    for name in ("image", "batch"):
        p = sub.add_parser(name)
        p.add_argument("image" if name == "image" else "folder")
        p.add_argument("--out", required=True)
        if name == "image":
            p.add_argument("--name", help="nombre de los archivos (por defecto, el de la imagen)")
        else:
            p.add_argument("--only", help="nombres sin extensión, separados por coma")
        p.add_argument("--model", default="smart", choices=sorted(COST), help="smart (meshy-t2.5, por defecto), latest (meshy-7.1) o meshy-6")
        p.add_argument("--polycount", type=int, default=0, help=f"caras objetivo (por defecto {DEFAULT_POLYCOUNT}; Roblox: hasta 20.000)")
        p.add_argument("--texture", default="2k", choices=["2k", "4k", "8k", "none"])
        p.add_argument("--formats", default="glb,fbx", type=lambda s: [f.strip() for f in s.split(",") if f.strip()])
        p.add_argument("--max-credits", type=int, default=40 if name == "image" else 300, help="tope de créditos de la corrida")
        p.add_argument("--dry-run", action="store_true")
    sub.add_parser("selftest")
    args = parser.parse_args(argv)
    try:
        if args.cmd == "image":
            return cmd_image(args)
        if args.cmd == "batch":
            return cmd_batch(args)
        return selftest()
    except MeshyError as e:
        print(f"  [error] {e}")
        return 1


if __name__ == "__main__":
    sys.exit(main())
