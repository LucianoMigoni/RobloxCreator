"""Imágenes de la tienda (Game Passes y Developer Products) estilo hit, en hojas de 9 hechas con IA.

  python tools/storeart.py base receta.json --out base.png
  python tools/imagegen.py generate receta.json --ref base.png --quality high --n 1 --out <carpeta>
  python tools/storeart.py finish receta.json --sheet <hoja de la IA>.png --out assets/ui/store-art
  python tools/storeart.py selftest

- base: arma la hoja 3x3 de bocetos con lo nuestro: cada cuadro con el degradé de su color y el ícono
  de assets/ui/hud-icons (o pet-icons) grande en el centro. Es la referencia que la IA redibuja con
  rayos, brillo y profundidad (receta "kind": "artset", skills/_shared/tienda/recetas).
- finish: corta la hoja de la IA en 9 imágenes de 512x512 y estampa la etiqueta de cada una ("2X",
  "VIP", "+4") abajo al centro, con la fuente de los títulos y contorno grueso. Abajo al centro porque
  Roblox muestra los Game Passes recortados en círculo: así la etiqueta y el objeto nunca se cortan.

Las etiquetas son números, símbolos o una palabra corta en inglés (regla de las imágenes,
skills/_shared/vitrina-hits.md): no se traducen. Necesita Pillow.
"""
import argparse
import json
import sys
import tempfile
from pathlib import Path

try:
    from PIL import Image, ImageDraw, ImageFilter, ImageFont
except ImportError:  # pragma: no cover
    print("Falta Pillow: pip install pillow", file=sys.stderr)
    raise

ROOT = Path(__file__).resolve().parent.parent
ICON_DIRS = [ROOT / "assets" / "ui" / "hud-icons", ROOT / "assets" / "ui" / "pet-icons"]
FONT = ROOT / "assets" / "fonts" / "luckiest-guy" / "LuckiestGuy-Regular.ttf"
INK = (26, 20, 38)
GAP = 0.05  # fracción del cuadro entre cuadros (blanco)
INSET = 0.035  # al cortar, fracción del cuadro que se saca de cada borde
WHITE = (255, 255, 255)


class ArtError(Exception):
    pass


def hex_rgb(value: str) -> tuple:
    value = value.lstrip("#")
    if len(value) != 6:
        raise ArtError(f"color inválido: #{value}")
    return tuple(int(value[i:i + 2], 16) for i in (0, 2, 4))


def load_recipe(path: Path) -> dict:
    recipe = json.loads(path.read_text(encoding="utf-8"))
    if recipe.get("kind") != "artset":
        raise ArtError(f"{path.name}: la receta no es \"artset\"")
    rows, cols = (int(x) for x in recipe["grid"].split("x"))
    items = recipe.get("items", [])
    if len(items) != rows * cols or [i["name"] for i in items] != recipe.get("names"):
        raise ArtError(f"{path.name}: `items` tiene que tener {rows * cols} y en el orden de `names`")
    return recipe


def find_icon(name: str) -> Path:
    for folder in ICON_DIRS:
        path = folder / f"{name}.png"
        if path.exists():
            return path
    raise ArtError(f"no hay ícono '{name}' en hud-icons ni en pet-icons")


def tile(color: tuple, icon: Image.Image, size: int) -> Image.Image:
    """Cuadro de boceto: degradé radial del color (más claro al centro), esquinas redondeadas e ícono."""
    light = tuple(min(255, int(c + (255 - c) * 0.45)) for c in color)
    dark = tuple(int(c * 0.62) for c in color)
    grad = Image.new("RGB", (size, size), dark)
    draw = ImageDraw.Draw(grad)
    steps = 48
    for i in range(steps):
        t = i / (steps - 1)
        r = int(size * 0.75 * (1 - t))
        col = tuple(int(d + (l - d) * t) for d, l in zip(dark, light))
        draw.ellipse((size / 2 - r, size * 0.46 - r, size / 2 + r, size * 0.46 + r), fill=col)
    grad = grad.filter(ImageFilter.GaussianBlur(size / 40))
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, size - 1, size - 1), radius=int(size * 0.12), fill=255)
    out = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    out.paste(grad, (0, 0), mask)
    w = int(size * 0.66)
    out.alpha_composite(icon.convert("RGBA").resize((w, w), Image.LANCZOS), ((size - w) // 2, int(size * 0.12)))
    return out


def cmd_base(recipe_path: Path, out: Path, cell: int = 512) -> Path:
    recipe = load_recipe(recipe_path)
    rows, cols = (int(x) for x in recipe["grid"].split("x"))
    gap = int(cell * GAP)
    sheet = Image.new("RGB", (cols * cell + (cols + 1) * gap, rows * cell + (rows + 1) * gap), WHITE)
    for index, item in enumerate(recipe["items"]):
        r, c = divmod(index, cols)
        icon = Image.open(find_icon(item["icon"]))
        t = tile(hex_rgb(item["color"]), icon, cell)
        sheet.paste(t, (gap + c * (cell + gap), gap + r * (cell + gap)), t)
    out.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(out)
    return out


def stamp(img: Image.Image, text: str) -> Image.Image:
    """Etiqueta abajo al centro: letras gordas blancas (amarillas si es un número) con contorno oscuro."""
    if not text:
        return img
    out = img.copy()
    draw = ImageDraw.Draw(out)
    size = img.width
    font_size = int(size * (0.26 if len(text) <= 3 else 0.19))
    font = ImageFont.truetype(str(FONT), font_size)
    box = draw.textbbox((0, 0), text, font=font, stroke_width=int(font_size * 0.12))
    w, h = box[2] - box[0], box[3] - box[1]
    x = (size - w) / 2 - box[0]
    y = size * 0.9 - h - box[1]
    fill = (255, 226, 74) if any(ch.isdigit() for ch in text) else WHITE
    shadow = Image.new("RGBA", out.size, (0, 0, 0, 0))
    ImageDraw.Draw(shadow).text((x, y + font_size * 0.07), text, font=font, fill=INK + (255,),
                                stroke_width=int(font_size * 0.12), stroke_fill=INK + (255,))
    out.alpha_composite(shadow)
    draw = ImageDraw.Draw(out)
    draw.text((x, y), text, font=font, fill=fill, stroke_width=int(font_size * 0.12), stroke_fill=INK)
    return out


def cells(sheet: Image.Image, rows: int, cols: int) -> list:
    """Los cuadros de la hoja: la grilla pareja menos el blanco de los bordes de cada cuadro."""
    w, h = sheet.size
    cw, ch = w / cols, h / rows
    out = []
    for r in range(rows):
        for c in range(cols):
            box = (int(c * cw), int(r * ch), int((c + 1) * cw), int((r + 1) * ch))
            cell = sheet.crop(box).convert("RGB")
            # Recorta el blanco del separador: filas y columnas casi blancas en los bordes.
            gray = cell.convert("L").point(lambda v: 0 if v > 244 else 255)
            x0, y0, x1, y1 = gray.getbbox() or (0, 0, cell.width, cell.height)
            # Un poco hacia adentro: el borde del cuadro de la IA trae blanco del separador y la esquina
            # redondeada. Recortado justo (sin agrandar a cuadrado con blanco) y llevado a cuadrado.
            inset = int(max(x1 - x0, y1 - y0) * INSET)
            out.append(cell.crop((x0 + inset, y0 + inset, x1 - inset, y1 - inset)))
    return out


def cmd_finish(recipe_path: Path, sheet_path: Path, out: Path, size: int = 512) -> list:
    recipe = load_recipe(recipe_path)
    rows, cols = (int(x) for x in recipe["grid"].split("x"))
    sheet = Image.open(sheet_path)
    out.mkdir(parents=True, exist_ok=True)
    files = []
    for item, cell in zip(recipe["items"], cells(sheet, rows, cols)):
        img = cell.resize((size, size), Image.LANCZOS).convert("RGBA")
        mask = Image.new("L", (size, size), 0)
        ImageDraw.Draw(mask).rounded_rectangle((0, 0, size - 1, size - 1), radius=int(size * 0.12), fill=255)
        rounded = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        rounded.paste(img, (0, 0), mask)
        final = stamp(rounded, item.get("label", ""))
        path = out / f"{item['name']}.png"
        final.save(path, optimize=True)
        files.append(path)
    return files


def selftest() -> int:
    with tempfile.TemporaryDirectory() as tmp:
        t = Path(tmp)
        icon = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
        ImageDraw.Draw(icon).ellipse((8, 8, 56, 56), fill=(255, 200, 40, 255))
        ICON_DIRS.insert(0, t)
        try:
            icon.save(t / "coin.png")
            names = [f"a{i}" for i in range(9)]
            items = [{"name": n, "icon": "coin", "color": "#46D64B", "label": "2X" if i == 0 else ""} for i, n in enumerate(names)]
            recipe = {"kind": "artset", "grid": "3x3", "names": names, "items": items,
                      "ia": {"aspect": "1:1", "mode": "redraw", "prompt": "x"}}
            path = t / "r.json"
            path.write_text(json.dumps(recipe), encoding="utf-8")
            base = cmd_base(path, t / "base.png", cell=96)
            img = Image.open(base)
            assert img.size == (3 * 96 + 4 * int(96 * GAP),) * 2, img.size
            files = cmd_finish(path, base, t / "out", size=128)
            assert [f.stem for f in files] == names
            first = Image.open(files[0])
            assert first.size == (128, 128) and first.mode == "RGBA"
            assert first.getpixel((0, 0))[3] == 0, "las esquinas quedan transparentes"
            bad = dict(recipe, names=names[:8])
            path.write_text(json.dumps(bad), encoding="utf-8")
            try:
                load_recipe(path)
                raise AssertionError("tenía que fallar")
            except ArtError:
                pass
        finally:
            ICON_DIRS.pop(0)
    for recipe in sorted((ROOT / "skills" / "_shared" / "tienda" / "recetas").glob("*.json")):
        r = load_recipe(recipe)
        for item in r["items"]:
            find_icon(item["icon"])
            hex_rgb(item["color"])
    print("storeart selftest ok")
    return 0


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest="cmd", required=True)
    b = sub.add_parser("base")
    b.add_argument("recipe")
    b.add_argument("--out", required=True)
    b.add_argument("--cell", type=int, default=512)
    f = sub.add_parser("finish")
    f.add_argument("recipe")
    f.add_argument("--sheet", required=True)
    f.add_argument("--out", required=True)
    f.add_argument("--size", type=int, default=512)
    sub.add_parser("selftest")
    args = parser.parse_args(argv)
    try:
        if args.cmd == "base":
            print(f"  [ok] {cmd_base(Path(args.recipe), Path(args.out), args.cell)}")
        elif args.cmd == "finish":
            for path in cmd_finish(Path(args.recipe), Path(args.sheet), Path(args.out), args.size):
                print(f"  [ok] {path.name}")
        else:
            return selftest()
    except (ArtError, OSError, KeyError) as e:
        print(e, file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
