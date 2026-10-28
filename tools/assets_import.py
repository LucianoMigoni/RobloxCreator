"""Trae recursos con licencia libre al catálogo (assets/) y los registra en index.json y LICENSES.md.

  python tools/assets_import.py kenney <slug> [<slug>...]     # paquete de https://kenney.nl/assets/<slug> (CC0)
  python tools/assets_import.py fluent <Nombre> [<Nombre>...]  # ícono 3D de Fluent Emoji (MIT), p. ej. "Wrapped gift"
  python tools/assets_import.py fluent --list                  # los íconos de la lista del hub (FLUENT_DEFAULT)
  python tools/assets_import.py manifest <carpeta>            # rehace el manifiesto de un paquete ya copiado
  python tools/assets_import.py selftest

Cada paquete queda en su carpeta con un manifest.json (un elemento por archivo, con triángulos y
animaciones de cada modelo) y una sola entrada `pack` en el índice. Buscar adentro:
`python assets/catalog.py find chest`.

Kenney (CC0) se baja por el mismo flujo público de su web ("Continue without donating"). Fluent Emoji
(MIT, Microsoft) se baja de github.com/microsoft/fluentui-emoji: la licencia MIT pide conservar el aviso
de copyright, que va en assets/LICENSES.md y en los créditos del juego.
"""
import datetime as dt
import io
import json
import re
import shutil
import struct
import sys
import tempfile
import time
import urllib.parse
import urllib.request
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ASSETS = ROOT / "assets"
UA = "Mozilla/5.0 (RobloxCreator asset import)"
FLUENT_RAW = "https://raw.githubusercontent.com/microsoft/fluentui-emoji/main/assets/"

# Qué va a cada carpeta según el tipo de archivo del paquete.
KIND_DIRS = {"model3d": "3d/kenney", "sound": "audio/kenney", "image": "vfx/kenney"}

# Íconos para HUD, tienda, ítems y géneros de los hits (nombres exactos de la carpeta de Fluent Emoji).
FLUENT_DEFAULT = [
    "Wrapped gift", "Shopping cart", "Shopping bags", "Money bag", "Money with wings", "Coin", "Dollar banknote",
    "Gem stone", "Crown", "Trophy", "1st place medal", "2nd place medal", "3rd place medal", "Sports medal",
    "Four leaf clover", "High voltage", "Fire", "Sparkles", "Star", "Glowing star", "Dizzy", "Collision",
    "Rocket", "Party popper", "Confetti ball", "Balloon", "Ribbon", "Magic wand", "Crystal ball", "Game die",
    "Slot machine", "Video game", "Joystick", "Musical notes", "Speaker high volume", "Bell", "Megaphone",
    "Gear", "Wrench", "Hammer", "Pick", "Hammer and pick", "Axe", "Shield", "Locked", "Unlocked", "Key",
    "Old key", "Magnifying glass tilted left", "Check mark button", "Cross mark", "Warning", "Plus",
    "Red heart", "Hundred points", "Calendar", "Spiral calendar", "Scroll", "Envelope", "Package", "Ticket",
    "Admission tickets", "Chart increasing", "Alarm clock", "Hourglass done", "Hourglass not done",
    "Stopwatch", "Timer clock", "Light bulb", "Battery", "Magnet", "Bomb", "Firecracker", "Teddy bear",
    "Puzzle piece", "Crossed swords", "Bow and arrow", "Open book", "Books", "Recycling symbol", "Counterclockwise arrows button",
    "Globe showing americas", "World map", "Compass", "Desert island", "Volcano", "Mountain", "Rainbow",
    "Snowflake", "Sun", "Crescent moon", "Cloud", "Cloud with lightning and rain", "Comet", "Ringed planet",
    "Milky way", "Evergreen tree", "Deciduous tree", "Cactus", "Mushroom", "Seedling", "Sunflower",
    "Cherry blossom", "Jack-o-lantern", "Ghost", "Skull", "Spider web", "Bat", "Christmas tree", "Snowman",
    "Candy", "Lollipop", "Chocolate bar", "Doughnut", "Cookie", "Birthday cake", "Ice cream", "Popcorn",
    "Watermelon", "Red apple", "Strawberry", "Cherries", "Banana", "Carrot", "Hamburger", "Pizza", "Egg",
    "Hatching chick", "Baby chick", "Dog face", "Cat face", "Hamster", "Rabbit face", "Fox", "Panda", "Frog",
    "Penguin", "Monkey face", "Tiger face", "Lion", "Unicorn", "Dragon", "Dragon face", "T-Rex", "Sauropod",
    "Honeybee", "Butterfly", "Turtle", "Octopus", "Shark", "Spouting whale", "Dolphin", "Crab", "Lobster",
    "Fish", "Tropical fish", "Blowfish", "Fishing pole", "Anchor", "Speedboat", "Sailboat", "Pirate flag",
    "Alien", "Robot", "Ninja", "Ring", "Running shoe", "Footprints", "Keyboard", "Racing car", "Hole",
    "Flying saucer", "Kite", "Yo-yo", "Bubbles", "Soap", "Broom", "Sponge", "Basket", "Bucket", "Ticket",
]


def http(url: str, referer: str = None, binary: bool = True):
    headers = {"User-Agent": UA}
    if referer:
        headers["Referer"] = referer
    req = urllib.request.Request(url, headers=headers)
    with urllib.request.urlopen(req, timeout=120) as r:
        data = r.read()
    return data if binary else data.decode("utf-8")


def glb_info(data: bytes) -> dict:
    """Triángulos, texturas y animaciones de un .glb (sin dependencias)."""
    if data[:4] != b"glTF":
        return {}
    clen, _ = struct.unpack("<I4s", data[12:20])
    j = json.loads(data[20:20 + clen])
    tris = 0
    for mesh in j.get("meshes", []):
        for prim in mesh.get("primitives", []):
            if "indices" in prim:
                tris += j["accessors"][prim["indices"]]["count"] // 3
    return {
        "triangles": tris,
        "animations": [a.get("name") for a in j.get("animations", []) if a.get("name")],
        "parts": [n.get("name") for n in j.get("nodes", []) if "mesh" in n],
        "textures": [i.get("uri") for i in j.get("images", []) if i.get("uri")],
    }


def kind_of(path: Path) -> str:
    ext = path.suffix.lower()
    if ext in (".glb", ".gltf"):
        return "model3d"
    if ext in (".ogg", ".mp3", ".wav"):
        return "sound"
    return "image"


def build_manifest(folder: Path, meta: dict) -> dict:
    items = []
    for f in sorted(folder.rglob("*")):
        if not f.is_file() or f.name == "manifest.json" or "Textures" in f.parts and f.suffix == ".png" and meta.get("kind") == "model3d":
            continue
        if f.suffix.lower() not in (".glb", ".gltf", ".ogg", ".mp3", ".wav", ".png"):
            continue
        item = {"name": f.stem, "file": f.relative_to(folder).as_posix(), "kb": max(1, f.stat().st_size // 1024)}
        if f.suffix.lower() == ".glb":
            item.update(glb_info(f.read_bytes()))
        items.append(item)
    manifest = dict(meta)
    manifest["count"] = len(items)
    manifest["items"] = items
    (folder / "manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=1), encoding="utf-8")
    return manifest


def pick_files(extracted: Path) -> list:
    """Archivos útiles de un zip de Kenney: modelos .glb (con su carpeta Textures), audio o PNG transparentes."""
    glb_dirs = [d for d in extracted.rglob("*") if d.is_dir() and d.name in ("GLB format", "GLTF format")]
    for d in glb_dirs:
        glbs = sorted(d.glob("*.glb"))
        if glbs:
            textures = sorted((d / "Textures").glob("*.png")) if (d / "Textures").exists() else []
            return [("model3d", g, g.name) for g in glbs] + [("model3d", t, "Textures/" + t.name) for t in textures]
    audio = sorted(p for p in extracted.rglob("*") if p.suffix.lower() in (".ogg", ".mp3", ".wav") and p.name != "Preview.ogg")
    if audio:
        return [("sound", a, a.relative_to(extracted / "Audio").as_posix() if (extracted / "Audio") in a.parents else a.name) for a in audio]
    pngs = [p for p in extracted.rglob("*.png") if "Black background" not in str(p) and "Rotated" not in p.parts
            and "Spritesheet" not in p.parts and p.name not in ("Preview.png", "Sample.png")]
    # Si el paquete trae variantes (Default/Double, Transparent/Black), quedarse con una sola.
    for preferred in ("Transparent", "PNG/Default"):
        subset = [p for p in pngs if preferred in p.as_posix()]
        if subset:
            pngs = subset
            break
    return [("image", p, p.name) for p in sorted(pngs)]


def kenney_download(slug: str) -> bytes:
    page = f"https://kenney.nl/assets/{slug}"
    http(page)
    hexid = f"assets/{slug}".encode().hex()
    info = json.loads(http(f"https://kenney.nl/download-link/{hexid}", referer=page, binary=False))
    if not info.get("url"):
        raise RuntimeError(f"Kenney no dio link para {slug}: {info}")
    return http(info["url"], referer=page)


def register(entry: dict, license_row: str):
    index_path = ASSETS / "index.json"
    index = json.loads(index_path.read_text(encoding="utf-8"))
    index["assets"] = [a for a in index["assets"] if a["id"] != entry["id"]] + [entry]
    index_path.write_text(json.dumps(index, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    licenses_path = ASSETS / "LICENSES.md"
    lines = licenses_path.read_text(encoding="utf-8").rstrip("\n").split("\n")
    lines = [l for l in lines if not l.startswith(f"| {entry['id']} |")] + [license_row]
    licenses_path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def import_kenney(slug: str, data: bytes = None) -> dict:
    data = data or kenney_download(slug)
    with tempfile.TemporaryDirectory() as tmp:
        extracted = Path(tmp)
        zipfile.ZipFile(io.BytesIO(data)).extractall(extracted)
        files = pick_files(extracted)
        if not files:
            raise RuntimeError(f"{slug}: el zip no trae modelos, audio ni PNG reconocibles")
        kind = files[0][0]
        # Las imágenes que no son partículas (peces, íconos 2D) van con la UI.
        folder = "ui/kenney" if kind == "image" and "particle" not in slug else KIND_DIRS[kind]
        target = ASSETS / folder / slug
        if target.exists():
            shutil.rmtree(target)
        for _, src, rel in files:
            dst = target / rel
            dst.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(src, dst)
        license_text = (extracted / "License.txt").read_text(encoding="utf-8", errors="ignore") if (extracted / "License.txt").exists() else ""
    if "CC0" not in license_text and "Creative Commons Zero" not in license_text:
        raise RuntimeError(f"{slug}: no encontré la licencia CC0 en el zip; no se registra")
    today = dt.date.today().isoformat()
    meta = {"pack": f"kenney-{slug}", "kind": kind, "source": f"https://kenney.nl/assets/{slug}",
            "license": "CC0-1.0", "author": "Kenney (www.kenney.nl)", "imported": today}
    manifest = build_manifest(target, meta)
    tris = [i.get("triangles", 0) for i in manifest["items"] if "triangles" in i]
    entry = {
        "id": f"kenney-{slug}",
        "path": target.relative_to(ASSETS).as_posix(),
        "type": "pack",
        "packType": kind,
        "count": manifest["count"],
        "tags": {"style": ["lowpoly", "cartoon", "kenney"], "genre": [], "theme": slug.replace("-kit", "").split("-")},
        "robloxAssetId": None,
        "source": "third-party",
        "sourceUrl": meta["source"],
        "license": "CC0-1.0",
        "commercialUse": True,
        "author": meta["author"],
        "notes": (f"{manifest['count']} archivos; triángulos por modelo {min(tris)}–{max(tris)}. " if tris else f"{manifest['count']} archivos. ")
                 + "Detalle por archivo en manifest.json (`python assets/catalog.py find <palabra>`).",
    }
    if tris:
        entry["polycount"] = max(tris)
    row = f"| {entry['id']} | Kenney, paquete \"{slug}\" | CC0 1.0 (dominio público) | sí | Kenney (www.kenney.nl) | {meta['source']} | {today} |"
    register(entry, row)
    return entry


def fluent_path(name: str) -> list:
    snake = re.sub(r"[^a-z0-9]+", "_", name.lower()).strip("_")
    hyphen = re.sub(r"[^a-z0-9\-]+", "_", name.lower()).strip("_")  # "Jack-o-lantern" → jack-o-lantern
    quoted = urllib.parse.quote(name)
    paths = [f"{quoted}/3D/{snake}_3d.png", f"{quoted}/Default/3D/{snake}_3d_default.png"]
    if hyphen != snake:
        paths += [f"{quoted}/3D/{hyphen}_3d.png", f"{quoted}/Default/3D/{hyphen}_3d_default.png"]
    return paths


def import_fluent(names: list) -> dict:
    target = ASSETS / "ui" / "fluent-emoji-3d"
    target.mkdir(parents=True, exist_ok=True)
    ok, missing = 0, []
    for name in dict.fromkeys(names):
        snake = re.sub(r"[^a-z0-9]+", "_", name.lower()).strip("_")
        if (target / f"{snake}.png").exists():
            ok += 1
            continue
        for rel in fluent_path(name):
            try:
                (target / f"{snake}.png").write_bytes(http(FLUENT_RAW + rel))
                ok += 1
                break
            except Exception:
                continue
        else:
            missing.append(name)
        time.sleep(0.1)
    today = dt.date.today().isoformat()
    meta = {"pack": "fluent-emoji-3d", "kind": "icon", "source": "https://github.com/microsoft/fluentui-emoji",
            "license": "MIT", "author": "Microsoft Corporation", "imported": today}
    manifest = build_manifest(target, meta)
    entry = {
        "id": "fluent-emoji-3d",
        "path": "ui/fluent-emoji-3d",
        "type": "pack",
        "packType": "icon",
        "count": manifest["count"],
        "tags": {"style": ["3d", "glossy", "emoji"], "genre": ["any"], "theme": ["icon", "hud", "button", "item"]},
        "robloxAssetId": None,
        "source": "third-party",
        "sourceUrl": meta["source"],
        "license": "MIT",
        "commercialUse": True,
        "author": "Microsoft Corporation",
        "notes": "PNG 256×256 con fondo transparente. Subir con Asset Manager o tools/upload_asset.py y usar como Image de ImageLabel/ImageButton. MIT: mantener el aviso en los créditos del juego.",
    }
    row = f"| fluent-emoji-3d | Fluent Emoji 3D (Microsoft) | MIT (Copyright (c) Microsoft Corporation) | sí, con el aviso de copyright | Microsoft | {meta['source']} | {today} |"
    register(entry, row)
    if missing:
        print("No encontrados (revisar el nombre exacto en el repo de Fluent Emoji):", ", ".join(missing))
    return entry


def selftest() -> int:
    # Un .glb mínimo con 1 triángulo, una animación y textura externa.
    gltf = {"asset": {"version": "2.0"}, "meshes": [{"primitives": [{"indices": 0}]}],
            "accessors": [{"count": 3, "type": "SCALAR"}], "nodes": [{"name": "body", "mesh": 0}],
            "animations": [{"name": "idle"}], "images": [{"uri": "Textures/colormap.png"}]}
    js = json.dumps(gltf).encode()
    js += b" " * ((4 - len(js) % 4) % 4)
    glb = b"glTF" + struct.pack("<II", 2, 20 + len(js)) + struct.pack("<I4s", len(js), b"JSON") + js
    info = glb_info(glb)
    assert info == {"triangles": 1, "animations": ["idle"], "parts": ["body"], "textures": ["Textures/colormap.png"]}, info
    assert fluent_path("Wrapped gift")[0] == "Wrapped%20gift/3D/wrapped_gift_3d.png"
    assert fluent_path("1st place medal")[0].endswith("1st_place_medal_3d.png")
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        (root / "Models" / "GLB format" / "Textures").mkdir(parents=True)
        (root / "Models" / "GLB format" / "cat.glb").write_bytes(glb)
        (root / "Models" / "GLB format" / "Textures" / "colormap.png").write_bytes(b"png")
        picked = pick_files(root)
        assert [p[2] for p in picked] == ["cat.glb", "Textures/colormap.png"], picked
        out = root / "out"
        out.mkdir()
        shutil.copyfile(root / "Models" / "GLB format" / "cat.glb", out / "cat.glb")
        m = build_manifest(out, {"pack": "x", "kind": "model3d"})
        assert m["count"] == 1 and m["items"][0]["triangles"] == 1, m
    print("selftest OK")
    return 0


def main(argv=None) -> int:
    args = sys.argv[1:] if argv is None else argv
    if not args:
        print(__doc__)
        return 2
    cmd, rest = args[0], args[1:]
    if cmd == "selftest":
        return selftest()
    if cmd == "kenney":
        for slug in rest:
            entry = import_kenney(slug)
            print(f"{entry['id']}: {entry['count']} archivos en assets/{entry['path']}")
            time.sleep(1)
        return 0
    if cmd == "fluent":
        names = FLUENT_DEFAULT if rest == ["--list"] else rest
        entry = import_fluent(names)
        print(f"fluent-emoji-3d: {entry['count']} íconos en assets/{entry['path']}")
        return 0
    if cmd == "manifest":
        folder = Path(rest[0]).resolve()
        old = json.loads((folder / "manifest.json").read_text(encoding="utf-8"))
        meta = {k: v for k, v in old.items() if k not in ("count", "items")}
        print(f"{build_manifest(folder, meta)['count']} archivos")
        return 0
    print(__doc__)
    return 2


if __name__ == "__main__":
    sys.exit(main())
