"""Buscar y validar el catálogo de assets (assets/index.json).

  python assets/catalog.py search [--type T] [--tag X ...] [--commercial] [--uploaded]
  python assets/catalog.py validate
  python assets/catalog.py selftest
"""
import argparse
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
TYPES = {"model3d", "icon", "button", "panel", "font", "texture", "image", "sound"}
SOURCES = {"blender-generated", "studio-generated", "creator-store", "user", "third-party"}
REQUIRED = ("id", "path", "type", "tags", "robloxAssetId", "source", "license", "commercialUse", "author")


def load(root=ROOT):
    return json.loads((root / "index.json").read_text(encoding="utf-8"))["assets"]


def all_tags(asset):
    return {t.lower() for group in asset.get("tags", {}).values() for t in group}


def search(assets, type_=None, tags=(), commercial=False, uploaded=False):
    wanted = {t.lower() for t in tags}
    return [
        a for a in assets
        if (not type_ or a["type"] == type_)
        and wanted <= all_tags(a)
        and (not commercial or a["commercialUse"] is True)
        and (not uploaded or a["robloxAssetId"])
    ]


def validate(assets, root=ROOT):
    errors, seen = [], set()
    licenses = (root / "LICENSES.md").read_text(encoding="utf-8")
    for i, a in enumerate(assets):
        name = a.get("id", f"#{i}")
        for f in REQUIRED:
            if f not in a:
                errors.append(f"{name}: falta '{f}'")
        if name in seen:
            errors.append(f"{name}: id duplicado")
        seen.add(name)
        if a.get("type") not in TYPES:
            errors.append(f"{name}: type inválido '{a.get('type')}'")
        if a.get("source") not in SOURCES:
            errors.append(f"{name}: source inválido '{a.get('source')}'")
        if a.get("type") == "model3d" and not isinstance(a.get("polycount"), int):
            errors.append(f"{name}: model3d requiere polycount entero")
        if not isinstance(a.get("commercialUse"), bool):
            errors.append(f"{name}: commercialUse debe ser true/false")
        if "path" in a and not (root / a["path"]).exists():
            errors.append(f"{name}: no existe el archivo {a['path']}")
        if f"| {name} |" not in licenses:
            errors.append(f"{name}: sin fila en LICENSES.md")
    return errors


def selftest():
    import tempfile
    with tempfile.TemporaryDirectory() as d:
        root = Path(d)
        (root / "3d").mkdir()
        (root / "3d" / "a.fbx").write_text("x")
        good = {"id": "a", "path": "3d/a.fbx", "type": "model3d", "polycount": 300,
                "tags": {"style": ["LowPoly"], "genre": ["tycoon"], "theme": []},
                "robloxAssetId": None, "source": "blender-generated", "license": "propio",
                "commercialUse": True, "author": "RobloxCreator"}
        bad = {"id": "b", "path": "3d/missing.fbx", "type": "model3d", "tags": {},
               "robloxAssetId": "123", "source": "x", "license": "?", "commercialUse": "yes", "author": "?"}
        (root / "LICENSES.md").write_text("| a | propio |", encoding="utf-8")
        assert validate([good], root) == []
        errs = validate([bad], root)
        for frag in ("polycount", "source inválido", "commercialUse", "no existe", "LICENSES"):
            assert any(frag in e for e in errs), frag
        assert search([good, bad], tags=["lowpoly"]) == [good]
        assert search([good, bad], commercial=True) == [good]
        assert search([good, bad], uploaded=True) == [bad]
    print("selftest OK")


def main():
    p = argparse.ArgumentParser()
    sub = p.add_subparsers(dest="cmd", required=True)
    s = sub.add_parser("search")
    s.add_argument("--type")
    s.add_argument("--tag", action="append", default=[])
    s.add_argument("--commercial", action="store_true")
    s.add_argument("--uploaded", action="store_true", help="solo los que ya tienen robloxAssetId")
    sub.add_parser("validate")
    sub.add_parser("selftest")
    args = p.parse_args()
    sys.stdout.reconfigure(encoding="utf-8")  # la consola de Windows no es UTF-8 por defecto

    if args.cmd == "selftest":
        return selftest()
    assets = load()
    if args.cmd == "search":
        for a in search(assets, args.type, args.tag, args.commercial, args.uploaded):
            print(json.dumps(a, ensure_ascii=False))
    else:
        errors = validate(assets)
        print("\n".join(errors) or f"OK: {len(assets)} assets válidos")
        sys.exit(1 if errors else 0)


if __name__ == "__main__":
    main()
