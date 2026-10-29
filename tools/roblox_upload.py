"""Sube assets del repo a Roblox con Open Cloud (Assets API) y anota sus ids en un archivo de bloqueo.

  python tools/roblox_upload.py upload <archivo> [<archivo>...] --lock games/<juego>/assets.lock.json
         [--name "Nombre"] [--description "..."] [--group-id ID | --user-id ID] [--dry-run]
  python tools/roblox_upload.py status <operationId>
  python tools/roblox_upload.py image-id <archivo.png> <imageId> --lock games/<juego>/assets.lock.json
  python tools/roblox_upload.py luau --lock games/<juego>/assets.lock.json --out games/<juego>/src/shared/Config/AssetIds.luau
  python tools/roblox_upload.py selftest

- upload: sube cada archivo, espera a que Roblox termine de procesarlo y guarda su assetId en el
  archivo de bloqueo. Si el archivo no cambió desde la última subida (mismo SHA-256), no lo sube de
  nuevo: el cupo de audio es de 100 por mes con ID verificado.
- status: consulta una operación pendiente (por si la moderación tardó más que la espera).
- luau: escribe Config/AssetIds.luau del juego con los ids por nombre de archivo: íconos
  (assets/ui/...), efectos y voces (assets/audio/..., las voces en carpetas "voices"), texturas de
  partículas (carpetas "vfx") y modelos. La UI y AudioConfig los usan solos.
- image-id: anota el id de IMAGEN de una imagen subida. Open Cloud sube las imágenes como Decal y el id
  de Decal no sirve en ImageLabel.Image (DevForum 3594046): `luau` imprime un script para la barra de
  comandos de Studio (o run_code del MCP) que resuelve cada Decal con InsertService:LoadAsset y lee su
  Texture. También sirve el id que da el Asset Manager de Studio o upload_image del MCP.

La clave va SOLO en la variable de entorno ROBLOX_OPEN_CLOUD_API_KEY (Creator Dashboard → Open Cloud →
API Keys, permiso "assets" de lectura y escritura). El dueño de lo subido sale de --group-id/--user-id
o de ROBLOX_CREATOR_GROUP_ID / ROBLOX_CREATOR_USER_ID. Nunca se imprime la clave.

Tipos (https://create.roblox.com/docs/cloud/guides/usage-assets, revisado el 2026-10-28):
audio .mp3/.ogg/.wav/.flac (hasta 7 min), imagen .png/.jpg/.bmp/.tga (se sube como Decal, menor a
8000x8000) y modelo .fbx/.gltf/.glb/.rbxm/.rbxmx (llega como paquete). Hasta 20 MB por archivo.
Para imágenes de UI conviene `upload_image` del MCP de Studio (skills/_shared/conectores.md).
"""
import argparse
import hashlib
import json
import os
import sys
import time
import urllib.error
import urllib.request
import uuid
from datetime import datetime, timezone
from pathlib import Path

API = "https://apis.roblox.com/assets/v1"
MAX_BYTES = 20 * 1024 * 1024
KEY_ENV = "ROBLOX_OPEN_CLOUD_API_KEY"

# extensión -> (assetType de la API, content type)
TYPES = {
    ".mp3": ("Audio", "audio/mpeg"),
    ".ogg": ("Audio", "audio/ogg"),
    ".wav": ("Audio", "audio/wav"),
    ".flac": ("Audio", "audio/flac"),
    ".png": ("Decal", "image/png"),
    ".jpg": ("Decal", "image/jpeg"),
    ".jpeg": ("Decal", "image/jpeg"),
    ".bmp": ("Decal", "image/bmp"),
    ".tga": ("Decal", "image/tga"),
    ".fbx": ("Model", "model/fbx"),
    ".gltf": ("Model", "model/gltf+json"),
    ".glb": ("Model", "model/gltf-binary"),
    ".rbxm": ("Model", "model/x-rbxm"),
    ".rbxmx": ("Model", "model/x-rbxm"),
}


class UploadError(Exception):
    pass


def asset_kind(path: Path) -> tuple:
    kind = TYPES.get(path.suffix.lower())
    if not kind:
        raise UploadError(f"{path.name}: tipo no admitido (admitidos: {', '.join(sorted(TYPES))})")
    return kind


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def creator_from(args_group: str, args_user: str, env=os.environ) -> dict:
    group = args_group or env.get("ROBLOX_CREATOR_GROUP_ID", "")
    user = args_user or env.get("ROBLOX_CREATOR_USER_ID", "")
    if group and user:
        raise UploadError("elegir un solo dueño: grupo o usuario")
    if group:
        return {"groupId": str(group)}
    if user:
        return {"userId": str(user)}
    raise UploadError("falta el dueño: --group-id/--user-id o ROBLOX_CREATOR_GROUP_ID/ROBLOX_CREATOR_USER_ID")


def multipart(request: dict, filename: str, content_type: str, data: bytes, boundary: str = "") -> tuple:
    """Cuerpo multipart/form-data con los campos `request` (JSON) y `fileContent` (el archivo)."""
    boundary = boundary or uuid.uuid4().hex
    safe_name = filename.replace('"', "")
    head = (
        f"--{boundary}\r\n"
        'Content-Disposition: form-data; name="request"\r\n'
        "Content-Type: application/json\r\n\r\n"
        f"{json.dumps(request)}\r\n"
        f"--{boundary}\r\n"
        f'Content-Disposition: form-data; name="fileContent"; filename="{safe_name}"\r\n'
        f"Content-Type: {content_type}\r\n\r\n"
    ).encode("utf-8")
    tail = f"\r\n--{boundary}--\r\n".encode("utf-8")
    return head + data + tail, f"multipart/form-data; boundary={boundary}"


def http(method: str, url: str, key: str, body: bytes = None, content_type: str = "", attempts: int = 4) -> dict:
    headers = {"x-api-key": key, "Accept": "application/json", "User-Agent": "RobloxCreator-upload/1.0"}
    if content_type:
        headers["Content-Type"] = content_type
    for attempt in range(attempts):
        req = urllib.request.Request(url, data=body, method=method, headers=headers)
        try:
            with urllib.request.urlopen(req, timeout=120) as r:
                return json.loads(r.read().decode("utf-8") or "{}")
        except urllib.error.HTTPError as e:
            detail = e.read().decode("utf-8", "replace")[:400]
            if e.code in (429, 500, 502, 503) and attempt + 1 < attempts:
                wait = float(e.headers.get("Retry-After") or 2 ** attempt * 2)
                time.sleep(min(wait, 60))
                continue
            if e.code in (401, 403):
                raise UploadError(f"HTTP {e.code}: la clave no tiene permiso 'assets' (lectura y escritura) "
                                  f"para ese dueño, o la IP no está permitida. {detail}") from None
            raise UploadError(f"HTTP {e.code} en {method} {url}: {detail}") from None
        except urllib.error.URLError as e:
            raise UploadError(f"sin conexión con {url}: {e.reason}") from None
    raise UploadError(f"sin respuesta de {url}")


def wait_operation(path: str, key: str, send=http, timeout: float = 120, sleep=time.sleep) -> dict:
    """Espera a que la operación termine. Devuelve la operación (con `response` o `error`)."""
    op_id = path.split("/")[-1]
    delay, waited = 1.0, 0.0
    while True:
        op = send("GET", f"{API}/operations/{op_id}", key)
        if op.get("done"):
            return op
        if waited >= timeout:
            return op
        sleep(delay)
        waited += delay
        delay = min(delay * 2, 10)


def load_lock(path: Path) -> dict:
    if path.exists():
        return json.loads(path.read_text(encoding="utf-8"))
    return {"_info": "Ids de Roblox de los assets subidos con tools/roblox_upload.py. No editar a mano.",
            "assets": {}}


def save_lock(path: Path, lock: dict):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(lock, indent=2, ensure_ascii=False, sort_keys=True) + "\n", encoding="utf-8")


def rel(path: Path) -> str:
    try:
        return path.resolve().relative_to(Path.cwd().resolve()).as_posix()
    except ValueError:
        return path.as_posix()


def upload_one(path: Path, lock: dict, creator: dict, key: str, name: str = "", description: str = "",
               send=http, dry_run: bool = False, timeout: float = 120) -> dict:
    """Sube un archivo si cambió. Devuelve la entrada del archivo de bloqueo."""
    asset_type, content_type = asset_kind(path)
    data = path.read_bytes()
    if len(data) > MAX_BYTES:
        raise UploadError(f"{path.name}: pesa {len(data) // 1024 // 1024} MB (máximo 20 MB)")
    digest = sha256(data)
    entry = lock["assets"].get(rel(path))
    if entry and entry.get("sha256") == digest and entry.get("assetId"):
        return {**entry, "skipped": True}
    # Nombre visible en el inventario: sin rutas ni extensión, máximo 50 caracteres.
    display = (name or path.stem.replace("_", " ").replace("-", " ").title())[:50]
    request = {"assetType": asset_type, "displayName": display,
               "description": (description or f"{display} (RobloxCreator)")[:1000],
               "creationContext": {"creator": creator}}
    if dry_run:
        return {"assetType": asset_type, "displayName": display, "sha256": digest, "dryRun": True}
    body, ctype = multipart(request, path.name, content_type, data)
    op = send("POST", f"{API}/assets", key, body, ctype)
    if not op.get("path"):
        raise UploadError(f"{path.name}: respuesta inesperada {json.dumps(op)[:300]}")
    op = wait_operation(op["path"], key, send, timeout)
    entry = {"assetType": asset_type, "displayName": display, "sha256": digest,
             "uploadedAt": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
             "operation": op.get("path", "")}
    if op.get("error"):
        raise UploadError(f"{path.name}: Roblox rechazó la subida: {json.dumps(op['error'])[:300]}")
    response = op.get("response") or {}
    if response.get("assetId"):
        entry["assetId"] = str(response["assetId"])
        entry["rbxassetid"] = f"rbxassetid://{response['assetId']}"
        entry["moderation"] = (response.get("moderationResult") or {}).get("moderationState", "")
    else:
        entry["pending"] = True
    lock["assets"][rel(path)] = entry
    return entry


def cmd_upload(args) -> int:
    key = os.environ.get(KEY_ENV, "")
    if not key and not args.dry_run:
        print(f"Falta la variable de entorno {KEY_ENV} (ver SETUP.md, Open Cloud).", file=sys.stderr)
        return 2
    try:
        creator = creator_from(args.group_id, args.user_id)
    except UploadError as e:
        print(e, file=sys.stderr)
        return 2
    lock_path = Path(args.lock)
    lock = load_lock(lock_path)
    failed = 0
    for name in args.files:
        path = Path(name)
        try:
            entry = upload_one(path, lock, creator, key, args.name if len(args.files) == 1 else "",
                               args.description, dry_run=args.dry_run)
        except (UploadError, OSError) as e:
            print(f"  [error] {e}")
            failed += 1
            continue
        if entry.get("skipped"):
            print(f"  [igual] {path.name}: {entry.get('rbxassetid')}")
        elif entry.get("dryRun"):
            print(f"  [simulado] {path.name}: {entry['assetType']} '{entry['displayName']}'")
        elif entry.get("pending"):
            print(f"  [pendiente] {path.name}: sigue procesándose. Consultar: status {entry['operation'].split('/')[-1]}")
        else:
            print(f"  [ok] {path.name}: {entry['rbxassetid']} ({entry.get('moderation') or 'sin estado'})")
        if not args.dry_run:
            save_lock(lock_path, lock)
    return 1 if failed else 0


def asset_groups(lock: dict) -> tuple:
    """(grupos para AssetIds, decals sin id de imagen). Agrupa por tipo y carpeta del archivo."""
    groups = {"icons": {}, "flat": {}, "flatPlain": {}, "textures": {}, "sounds": {}, "voices": {}, "vfx": {}, "models": {}}
    pending = []
    for rel_path, entry in sorted(lock.get("assets", {}).items()):
        name = Path(rel_path).stem
        parts = set(Path(rel_path).parts)
        kind = entry.get("assetType")
        if kind == "Audio" and entry.get("assetId"):
            groups["voices" if any("voice" in part for part in parts) else "sounds"][name] = entry["rbxassetid"]
        elif kind == "Decal" and entry.get("assetId"):
            if entry.get("imageId"):
                # Los íconos planos repiten nombres de los 3D ("shop"): van en su propio grupo.
                if "icons-flat" in parts:
                    group = "flatPlain" if "plain" in parts else "flat"
                elif "hit-skin" in parts:
                    group = "textures"
                else:
                    group = "vfx" if "vfx" in parts else "icons"
                groups[group][name] = f"rbxassetid://{entry['imageId']}"
            else:
                pending.append((rel_path, entry["assetId"]))
        elif kind == "Model" and entry.get("assetId"):
            groups["models"][name] = entry["rbxassetid"]
    return groups, pending


def render_luau(groups: dict) -> str:
    lines = [
        "--!strict",
        "-- Ids de Roblox de los assets propios del juego, por nombre de archivo sin extensión. Lo escribe",
        "-- `python tools/roblox_upload.py luau` desde games/<juego>/assets.lock.json: no editar a mano.",
        "-- Lo que falta: Icons muestra el emoji y AudioConfig usa los sonidos de la biblioteca de Roblox.",
        "",
        "return {",
    ]
    for group in ("icons", "flat", "flatPlain", "textures", "sounds", "voices", "vfx", "models"):
        items = groups.get(group, {})
        if not items:
            lines.append(f"	{group} = {{}} :: {{ [string]: string }},")
            continue
        lines.append(f"	{group} = {{")
        for name, value in sorted(items.items()):
            key = name if name.replace("_", "a").isalnum() and not name[0].isdigit() else f'["{name}"]'
            lines.append(f'		{key} = "{value}",')
        lines.append("	} :: { [string]: string },")
    lines.append("}")
    return "\n".join(lines) + "\n"


def resolver_script(pending: list) -> str:
    ids = ", ".join(str(asset_id) for _, asset_id in pending)
    return (
        "local InsertService = game:GetService(\"InsertService\")\n"
        f"for _, id in {{ {ids} }} do\n"
        "\tlocal ok, model = pcall(InsertService.LoadAsset, InsertService, id)\n"
        "\tlocal decal = ok and model:FindFirstChildWhichIsA(\"Decal\", true)\n"
        "\tprint(id, decal and decal.Texture or \"(no se pudo cargar)\")\n"
        "\tif ok then model:Destroy() end\n"
        "end\n"
    )


def cmd_luau(args) -> int:
    lock = load_lock(Path(args.lock))
    groups, pending = asset_groups(lock)
    out = Path(args.out)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(render_luau(groups), encoding="utf-8")
    counts = ", ".join(f"{len(v)} {k}" for k, v in groups.items() if v) or "nada todavía"
    print(f"  [ok] {out}: {counts}")
    if pending:
        print(f"  {len(pending)} imágenes subidas como Decal todavía sin id de imagen (ImageLabel no usa el de Decal).")
        print("  En Studio (barra de comandos o run_code del MCP) correr:\n")
        print(resolver_script(pending))
        print("  y anotar cada Texture con: python tools/roblox_upload.py image-id <archivo> <id> --lock ...")
    return 0


def cmd_image_id(args) -> int:
    lock_path = Path(args.lock)
    lock = load_lock(lock_path)
    key = rel(Path(args.file))
    entry = lock["assets"].get(key)
    if not entry:
        print(f"{key} no está en {lock_path}: subirlo primero.", file=sys.stderr)
        return 2
    image_id = str(args.image_id).replace("rbxassetid://", "").strip()
    if not image_id.isdigit():
        print(f"id inválido: {args.image_id}", file=sys.stderr)
        return 2
    entry["imageId"] = image_id
    save_lock(lock_path, lock)
    print(f"  [ok] {key}: imagen rbxassetid://{image_id}")
    return 0


def cmd_status(args) -> int:
    key = os.environ.get(KEY_ENV, "")
    if not key:
        print(f"Falta la variable de entorno {KEY_ENV}.", file=sys.stderr)
        return 2
    try:
        op = http("GET", f"{API}/operations/{args.operation}", key)
    except UploadError as e:
        print(e, file=sys.stderr)
        return 1
    print(json.dumps(op, indent=2, ensure_ascii=False))
    return 0


def selftest() -> int:
    import email.parser
    import tempfile

    assert asset_kind(Path("a/Coin.MP3")) == ("Audio", "audio/mpeg")
    assert asset_kind(Path("pet.glb")) == ("Model", "model/gltf-binary")
    try:
        asset_kind(Path("x.exe"))
        raise AssertionError("debía rechazar .exe")
    except UploadError:
        pass
    assert creator_from("", "", {"ROBLOX_CREATOR_GROUP_ID": "77"}) == {"groupId": "77"}
    assert creator_from("", "5", {}) == {"userId": "5"}
    for bad in (("1", "2", {}), ("", "", {})):
        try:
            creator_from(*bad)
            raise AssertionError(bad)
        except UploadError:
            pass

    body, ctype = multipart({"assetType": "Audio"}, 'co"in.mp3', "audio/mpeg", b"ID3data", "BOUND")
    msg = email.parser.BytesParser().parsebytes(b"Content-Type: " + ctype.encode() + b"\r\n\r\n" + body)
    parts = {p.get_param("name", header="content-disposition"): p for p in msg.get_payload()}
    assert json.loads(parts["request"].get_payload()) == {"assetType": "Audio"}
    assert parts["fileContent"].get_payload(decode=True) == b"ID3data"
    assert parts["fileContent"].get_content_type() == "audio/mpeg"
    assert parts["fileContent"].get_filename() == "coin.mp3"

    calls = []

    def fake(method, url, key, body=None, ctype=""):
        calls.append((method, url))
        assert key == "k"
        if method == "POST":
            assert b'"groupId": "9"' in body
            return {"path": "operations/op1"}
        if len([c for c in calls if c[0] == "GET"]) < 2:
            return {"path": "operations/op1", "done": False}
        return {"path": "operations/op1", "done": True,
                "response": {"assetId": "123", "moderationResult": {"moderationState": "MODERATION_STATE_APPROVED"}}}

    with tempfile.TemporaryDirectory() as tmp:
        cwd = os.getcwd()
        os.chdir(tmp)
        try:
            Path("coin_pop.mp3").write_bytes(b"sonido")
            lock = load_lock(Path("lock.json"))
            entry = upload_one(Path("coin_pop.mp3"), lock, {"groupId": "9"}, "k", send=fake, timeout=30,
                               dry_run=False)
            assert entry["rbxassetid"] == "rbxassetid://123" and entry["displayName"] == "Coin Pop", entry
            assert entry["moderation"] == "MODERATION_STATE_APPROVED"
            save_lock(Path("lock.json"), lock)
            again = upload_one(Path("coin_pop.mp3"), load_lock(Path("lock.json")), {"groupId": "9"}, "k", send=fake)
            assert again.get("skipped") and len([c for c in calls if c[0] == "POST"]) == 1, calls
            Path("coin_pop.mp3").write_bytes(b"sonido nuevo")
            dry = upload_one(Path("coin_pop.mp3"), load_lock(Path("lock.json")), {"groupId": "9"}, "k", dry_run=True)
            assert dry.get("dryRun") and dry["assetType"] == "Audio"
            Path("big.png").write_bytes(b"0" * (MAX_BYTES + 1))
            try:
                upload_one(Path("big.png"), lock, {"groupId": "9"}, "k", send=fake)
                raise AssertionError("debía rechazar más de 20 MB")
            except UploadError:
                pass
        finally:
            os.chdir(cwd)

    # AssetIds: audio directo, imágenes solo con id de imagen, voces y partículas por carpeta.
    lock = {"assets": {
        "assets/audio/hit-sfx/coin_pickup_A.mp3": {"assetType": "Audio", "assetId": "11", "rbxassetid": "rbxassetid://11"},
        "assets/audio/hit-voices/deep_legendary.mp3": {"assetType": "Audio", "assetId": "12", "rbxassetid": "rbxassetid://12"},
        "assets/ui/hit-icons/cash.png": {"assetType": "Decal", "assetId": "13", "rbxassetid": "rbxassetid://13", "imageId": "113"},
        "assets/ui/hit-icons/gem.png": {"assetType": "Decal", "assetId": "14", "rbxassetid": "rbxassetid://14"},
        "assets/vfx/hit/sparkle.png": {"assetType": "Decal", "assetId": "15", "rbxassetid": "rbxassetid://15", "imageId": "115"},
        "assets/3d/pets/dragon.glb": {"assetType": "Model", "assetId": "16", "rbxassetid": "rbxassetid://16"},
        "assets/ui/icons-flat/cash.png": {"assetType": "Decal", "assetId": "17", "rbxassetid": "rbxassetid://17", "imageId": "117"},
        "assets/ui/icons-flat/plain/cash.png": {"assetType": "Decal", "assetId": "18", "rbxassetid": "rbxassetid://18", "imageId": "118"},
        "assets/ui/hit-skin/studs.png": {"assetType": "Decal", "assetId": "19", "rbxassetid": "rbxassetid://19", "imageId": "119"},
    }}
    groups, pending = asset_groups(lock)
    assert groups["sounds"] == {"coin_pickup_A": "rbxassetid://11"} and groups["voices"] == {"deep_legendary": "rbxassetid://12"}
    assert groups["icons"] == {"cash": "rbxassetid://113"} and groups["vfx"] == {"sparkle": "rbxassetid://115"}, groups
    assert groups["models"] == {"dragon": "rbxassetid://16"} and pending == [("assets/ui/hit-icons/gem.png", "14")]
    assert groups["flat"] == {"cash": "rbxassetid://117"} and groups["flatPlain"] == {"cash": "rbxassetid://118"}, groups
    assert groups["textures"] == {"studs": "rbxassetid://119"}, groups
    text = render_luau(groups)
    assert 'cash = "rbxassetid://113",' in text and "voices = {" in text and text.startswith("--!strict")
    assert "{ 14 }" in resolver_script(pending)

    slept = []
    op = wait_operation("operations/x", "k", lambda *a, **k: {"done": False}, timeout=3, sleep=slept.append)
    assert op == {"done": False} and sum(slept) >= 3, slept
    print("selftest OK")
    return 0


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    sub = parser.add_subparsers(dest="cmd", required=True)
    u = sub.add_parser("upload")
    u.add_argument("files", nargs="+")
    u.add_argument("--lock", required=True, help="games/<juego>/assets.lock.json")
    u.add_argument("--name", default="", help="nombre visible (solo con un archivo)")
    u.add_argument("--description", default="")
    u.add_argument("--group-id", default="")
    u.add_argument("--user-id", default="")
    u.add_argument("--dry-run", action="store_true", help="muestra qué subiría, sin subir")
    s = sub.add_parser("status")
    s.add_argument("operation")
    lu = sub.add_parser("luau")
    lu.add_argument("--lock", required=True)
    lu.add_argument("--out", required=True, help="games/<juego>/src/shared/Config/AssetIds.luau")
    im = sub.add_parser("image-id")
    im.add_argument("file")
    im.add_argument("image_id")
    im.add_argument("--lock", required=True)
    sub.add_parser("selftest")
    args = parser.parse_args(argv)
    if args.cmd == "upload":
        return cmd_upload(args)
    if args.cmd == "status":
        return cmd_status(args)
    if args.cmd == "luau":
        return cmd_luau(args)
    if args.cmd == "image-id":
        return cmd_image_id(args)
    return selftest()


if __name__ == "__main__":
    sys.exit(main())
