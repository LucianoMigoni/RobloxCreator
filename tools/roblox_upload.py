"""Sube assets del repo a Roblox con Open Cloud (Assets API) y anota sus ids en un archivo de bloqueo.

  python tools/roblox_upload.py upload <archivo> [<archivo>...] --lock games/<juego>/assets.lock.json
         [--name "Nombre"] [--description "..."] [--group-id ID | --user-id ID] [--dry-run]
  python tools/roblox_upload.py status <operationId>
  python tools/roblox_upload.py selftest

- upload: sube cada archivo, espera a que Roblox termine de procesarlo y guarda su assetId en el
  archivo de bloqueo. Si el archivo no cambió desde la última subida (mismo SHA-256), no lo sube de
  nuevo: el cupo de audio es de 100 por mes con ID verificado.
- status: consulta una operación pendiente (por si la moderación tardó más que la espera).

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
    sub.add_parser("selftest")
    args = parser.parse_args(argv)
    if args.cmd == "upload":
        return cmd_upload(args)
    if args.cmd == "status":
        return cmd_status(args)
    return selftest()


if __name__ == "__main__":
    sys.exit(main())
