"""Íconos planos de botones chicos: Material Symbols de Google (redondeados, rellenos, trazo 700).

  python tools/flat_icons.py fetch          # baja los SVG que faltan a assets/ui/icons-flat/svg
  python tools/flat_icons.py render         # PNG: blanco con contorno y blanco liso (usa tools/render3d)
  python tools/flat_icons.py list
  python tools/flat_icons.py selftest

Por qué: los hits usan dos clases de ícono (skills/roblox-ui-designer/references/hud-hits.md §Íconos).
- Objetos 3D (billetes, regalo, huevos, corona): tools/render3d/icons.cjs render.
- Íconos planos de siempre en los botones chicos y en la barra de Roblox: el carrito y el libro de
  Shop e Index en Steal An Egg, el engranaje y la nota musical de +1 Speed Keyboard Escape, el
  calendario de "Daily" en Anime Dice. Esos son estos.

Salidas en assets/ui/icons-flat/:
- <nombre>.png: blanco con contorno oscuro grueso, 256 px, para botones de color (como Steal An Egg).
- plain/<nombre>.png: blanco liso, para la barra de Roblox y para teñir con ImageColor3.

Material Symbols es Apache 2.0 (uso comercial libre; se guarda el aviso de licencia junto a los SVG).
Versión fijada en VERSION; la lista de nombres está en ICONS (nombre nuestro -> nombre de Material).
"""
import argparse
import json
import subprocess
import sys
import tempfile
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "ui" / "icons-flat"
VERSION = "0.48.2"
CDN = "https://cdn.jsdelivr.net/npm/@material-symbols/svg-700@{v}/rounded/{name}-fill.svg"
LICENSE_URL = "https://raw.githubusercontent.com/google/material-design-icons/master/LICENSE"

# Nombre nuestro (el mismo que usan Icons.luau y los íconos 3D cuando hay) -> nombre en Material Symbols.
ICONS = {
    "shop": "shopping_cart",
    "shop_basket": "shopping_basket",
    "index": "menu_book",
    "rebirth": "autorenew",
    "settings": "settings",
    "daily": "calendar_month",
    "quests": "assignment",
    "gift": "redeem",
    "trade": "swap_horiz",
    "inventory": "backpack",
    "teleport": "cyclone",
    "spin": "attractions",
    "codes": "confirmation_number",
    "friends": "group",
    "invite": "person_add",
    "speed": "sprint",
    "strength": "fitness_center",
    "trophy": "trophy",
    "star": "star",
    "lock": "lock",
    "music": "music_note",
    "sound": "volume_up",
    "mute": "volume_off",
    "notifications": "notifications",
    "search": "search",
    "map": "map",
    "base": "home",
    "pets": "pets",
    "egg": "egg",
    "timer": "timer",
    "moon": "dark_mode",
    "fire": "local_fire_department",
    "heart": "favorite",
    "close": "close",
    "plus": "add",
    "check": "check",
    "info": "info",
    "question": "help",
    "vip": "workspace_premium",
    "cash": "payments",
    "coins": "paid",
    "gem": "diamond",
    "boost": "bolt",
    "potion": "science",
    "chest": "inventory_2",
    "sell": "sell",
    "leaderboard": "leaderboard",
    "pickaxe": "hardware",
    "fishing": "phishing",
    "battle": "swords",
    "play": "play_arrow",
    "hide": "visibility_off",
    "camera": "photo_camera",
    "skip": "fast_forward",
    "rocket": "rocket_launch",
    "key": "key",
    "emote": "mood",
    "upgrade": "arrow_circle_up",
    "auto": "autoplay",
}


def fetch(out: Path, names=None) -> list:
    svg_dir = out / "svg"
    svg_dir.mkdir(parents=True, exist_ok=True)
    got, missing = [], []
    for ours, material in ICONS.items():
        if names and ours not in names:
            continue
        path = svg_dir / f"{ours}.svg"
        if path.exists():
            continue
        url = CDN.format(v=VERSION, name=material)
        try:
            with urllib.request.urlopen(url, timeout=30) as r:
                data = r.read()
        except urllib.error.HTTPError as e:
            missing.append(f"{ours} ({material}: HTTP {e.code})")
            continue
        if not data.lstrip().startswith(b"<svg"):
            raise RuntimeError(f"{ours}: {url} no devolvió un SVG")
        path.write_bytes(data)
        got.append(ours)
    if missing:
        print("No están en Material Symbols " + VERSION + ": " + ", ".join(missing))
    license_path = svg_dir / "LICENSE-material-symbols.txt"
    if not license_path.exists():
        with urllib.request.urlopen(LICENSE_URL, timeout=30) as r:
            license_path.write_bytes(r.read())
    write_manifest(out)
    return got


def write_manifest(out: Path):
    items = [{"name": k, "material": v, "file": f"{k}.png", "plain": f"plain/{k}.png", "svg": f"svg/{k}.svg"}
             for k, v in ICONS.items()]
    manifest = {
        "pack": "icons-flat",
        "kind": "icon",
        "count": len(items),
        "source": f"Material Symbols (Google), @material-symbols/svg-700@{VERSION}, estilo rounded relleno",
        "license": "Apache-2.0 (svg/LICENSE-material-symbols.txt)",
        "style": "Plano: blanco con contorno oscuro grueso (botones de color) o blanco liso (barra de Roblox, teñible)",
        "notes": "Para objetos (billetes, regalo, huevos) usar los 3D de assets/ui/icons3d.",
        "items": items,
    }
    (out / "manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")


def render(out: Path, names=None) -> int:
    cmd = ["node", str(ROOT / "tools" / "render3d" / "icons.cjs"), "flat", "--out", str(out)] + list(names or [])
    return subprocess.call(cmd)


def selftest() -> int:
    # Sin red: la tabla, el manifiesto y que cada nombre de Icons.luau con ícono plano esté en la tabla.
    assert len(ICONS) == len(set(ICONS)), "nombres repetidos"
    assert all(v and v.replace("_", "").isalnum() for v in ICONS.values())
    with tempfile.TemporaryDirectory() as tmp:
        out = Path(tmp)
        write_manifest(out)
        m = json.loads((out / "manifest.json").read_text(encoding="utf-8"))
        assert m["count"] == len(ICONS) and m["items"][0]["plain"].startswith("plain/")
    for core in ("shop", "index", "rebirth", "settings", "daily", "quests", "gift", "close", "plus", "check"):
        assert core in ICONS, core
    print("flat_icons selftest OK")
    return 0


def main(argv=None) -> int:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest="cmd", required=True)
    for name in ("fetch", "render"):
        c = sub.add_parser(name)
        c.add_argument("names", nargs="*")
        c.add_argument("--out", default=str(OUT))
    sub.add_parser("list")
    sub.add_parser("selftest")
    a = p.parse_args(argv)
    if a.cmd == "fetch":
        got = fetch(Path(a.out), a.names)
        print(f"{len(got)} SVG nuevos en {Path(a.out) / 'svg'}")
        return 0
    if a.cmd == "render":
        return render(Path(a.out), a.names)
    if a.cmd == "list":
        for k, v in ICONS.items():
            print(f"{k:14} {v}")
        return 0
    return selftest()


if __name__ == "__main__":
    sys.exit(main())
