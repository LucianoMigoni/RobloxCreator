"""Corta una hoja de íconos hecha con IA en íconos sueltos con fondo transparente, listos para el HUD.

  python tools/iconsheet.py slice hoja.png --grid 3x3 --names coins,cash,gem,... --out carpeta [--size 512]
  python tools/iconsheet.py preview carpeta --sheet revision.jpg
  python tools/iconsheet.py selftest

- slice: encuentra las filas y columnas por los huecos vacíos entre íconos (la IA no los alinea
  perfecto), recorta cada uno, saca el fondo y lo centra en un cuadrado con margen. Si la hoja ya es
  transparente (GPT Image con background transparent) usa ese alfa; si no, saca el fondo liso desde
  los bordes (como Nano Banana con fondo blanco) y limpia el halo claro del borde.
- preview: cada ícono sobre fondo oscuro y claro, y a 96 y 48 px (el tamaño real en un botón del HUD).

Los íconos son nuestros si la imagen se generó en un plan pago o con API (skills/_shared/conectores.md).
Necesita Pillow.
"""
import argparse
import hashlib
import json
import math
import sys
import tempfile
from datetime import datetime, timezone
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parent.parent
FONT = ROOT / "assets" / "fonts" / "lilita-one" / "LilitaOne-Regular.ttf"


class SheetError(Exception):
    pass


def has_alpha(img: Image.Image) -> bool:
    return img.mode == "RGBA" and img.getchannel("A").getextrema()[0] < 250


def background_mask(img: Image.Image, tolerance: int) -> Image.Image:
    """255 donde hay fondo: lo parecido al color de las esquinas y conectado con el borde."""
    rgb = img.convert("RGB")
    w, h = rgb.size
    corners = [rgb.getpixel(p) for p in ((0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1))]
    bg = tuple(sorted(c[i] for c in corners)[1] for i in range(3))
    # Distancia al color de fondo, y relleno por inundación desde un marco de 1 px alrededor.
    diff = ImageChops.difference(rgb, Image.new("RGB", rgb.size, bg)).convert("L")
    near = diff.point(lambda v: 255 if v <= tolerance else 0)
    framed = Image.new("L", (w + 2, h + 2), 255)
    framed.paste(near, (1, 1))
    ImageDraw.floodfill(framed, (0, 0), 128, thresh=0)
    return framed.crop((1, 1, w + 1, h + 1)).point(lambda v: 255 if v == 128 else 0)


def foreground(img: Image.Image, tolerance: int) -> tuple:
    """(RGBA con el fondo transparente, máscara de primer plano)."""
    if has_alpha(img):
        rgba = img.convert("RGBA")
        return rgba, rgba.getchannel("A").point(lambda v: 255 if v > 24 else 0)
    bg = background_mask(img, tolerance)
    fg = ImageChops.invert(bg)
    rgba = img.convert("RGBA")
    rgba.putalpha(fg)
    return defringe(rgba, bg), fg


def defringe(rgba: Image.Image, bg: Image.Image) -> Image.Image:
    """En la franja del borde, el píxel es mezcla de contorno oscuro y fondo claro: se le saca el fondo."""
    band = ImageChops.subtract(bg.filter(ImageFilter.MaxFilter(5)), bg)  # 2 px de primer plano junto al fondo
    r, g, b, a = rgba.split()
    lum = rgba.convert("L")
    # alfa proporcional a lo oscuro (fondo claro = 255, contorno ~40) y color "sin blanco".
    edge_alpha = lum.point(lambda v: max(0, min(255, int((255 - v) * 255 / 215))))
    new_a = Image.composite(edge_alpha, a, band)

    def unmix(ch):
        return Image.composite(ch.point(lambda v: 30), ch, band)  # el borde toma el tono del contorno

    return Image.merge("RGBA", (unmix(r), unmix(g), unmix(b), new_a))


def runs(profile: list, threshold: float) -> list:
    """[(inicio, fin)] de los tramos con contenido en un perfil de columnas o filas."""
    out, start = [], None
    for i, v in enumerate(profile + [0]):
        if v > threshold and start is None:
            start = i
        elif v <= threshold and start is not None:
            out.append((start, i))
            start = None
    return out


def pixels(img: Image.Image) -> list:
    """Valores de los píxeles en una lista (getdata pasó a get_flattened_data en Pillow 12)."""
    return list(img.get_flattened_data() if hasattr(img, "get_flattened_data") else img.getdata())


def groups(mask: Image.Image, count: int, axis: str) -> list:
    """Divide en `count` grupos por los huecos más anchos entre tramos con contenido."""
    w, h = mask.size
    line = mask.resize((w, 1), Image.BOX) if axis == "x" else mask.resize((1, h), Image.BOX)
    profile = pixels(line)
    segs = runs(profile, 0.5)
    if len(segs) < count:
        raise SheetError(f"se encontraron {len(segs)} {'columnas' if axis == 'x' else 'filas'} y se esperaban {count}")
    gaps = sorted(range(len(segs) - 1), key=lambda i: segs[i + 1][0] - segs[i][1], reverse=True)[:count - 1]
    cuts = sorted(gaps)
    out, first = [], 0
    for c in cuts:
        out.append((segs[first][0], segs[c][1]))
        first = c + 1
    out.append((segs[first][0], segs[-1][1]))
    return out


def square(icon: Image.Image, size: int, margin: float) -> Image.Image:
    bbox = icon.getchannel("A").getbbox()
    if not bbox:
        raise SheetError("celda vacía")
    icon = icon.crop(bbox)
    inner = int(size * (1 - 2 * margin))
    k = inner / max(icon.size)
    icon = icon.resize((max(1, round(icon.width * k)), max(1, round(icon.height * k))), Image.LANCZOS)
    out = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    out.alpha_composite(icon, ((size - icon.width) // 2, (size - icon.height) // 2))
    return out


def slice_sheet(path: Path, rows: int, cols: int, names: list, out: Path, size=512, margin=0.06, tolerance=40) -> list:
    img = Image.open(path)
    if names and len(names) != rows * cols:
        raise SheetError(f"--names tiene {len(names)} nombres y la grilla {rows}x{cols} = {rows * cols}")
    rgba, fg = foreground(img, tolerance)
    col_groups = groups(fg, cols, "x")
    out.mkdir(parents=True, exist_ok=True)
    results = []
    for c, (x0, x1) in enumerate(col_groups):
        column = fg.crop((x0, 0, x1, fg.height))
        for r, (y0, y1) in enumerate(groups(column, rows, "y")):
            index = r * cols + c
            name = names[index] if names else f"icon_{index + 1:02d}"
            icon = square(rgba.crop((x0, y0, x1, y1)), size, margin)
            file = out / f"{name}.png"
            icon.save(file, optimize=True)
            results.append({"name": name, "file": file.name, "index": index + 1})
    results.sort(key=lambda item: item["index"])
    manifest = {
        "source": path.name, "sha256": hashlib.sha256(path.read_bytes()).hexdigest(), "grid": f"{rows}x{cols}",
        "size": size, "created": datetime.now(timezone.utc).isoformat(timespec="seconds"), "items": results,
    }
    (out / f"{path.stem}.manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    return results


def preview(folder: Path, sheet_path: Path, cols: int = 6):
    icons = sorted(p for p in folder.glob("*.png"))
    if not icons:
        raise SheetError(f"no hay PNG en {folder}")
    cell, pad, label = 200, 12, 30
    font = ImageFont.truetype(str(FONT), 20)
    rows = math.ceil(len(icons) / cols)
    w = pad + cols * (cell + pad)
    h = pad + rows * (cell + label + 60 + pad)
    sheet = Image.new("RGB", (w, h), (20, 20, 30))
    draw = ImageDraw.Draw(sheet)
    for i, p in enumerate(icons):
        icon = Image.open(p).convert("RGBA")
        x = pad + (i % cols) * (cell + pad)
        y = pad + (i // cols) * (cell + label + 60 + pad)
        dark = Image.new("RGBA", (cell, cell // 2 * 2), (40, 44, 70, 255))
        half = icon.resize((cell // 2 - 8, cell // 2 - 8), Image.LANCZOS)
        dark.alpha_composite(icon.resize((cell - 40, cell - 40), Image.LANCZOS), (20, 20))
        sheet.paste(dark.convert("RGB"), (x, y))
        light = Image.new("RGBA", (cell, 56), (235, 238, 245, 255))
        for k, s in enumerate((48, 32)):
            light.alpha_composite(icon.resize((s, s), Image.LANCZOS), (8 + k * 60, (56 - s) // 2))
        light.alpha_composite(half.resize((48, 48), Image.LANCZOS).transpose(Image.FLIP_LEFT_RIGHT), (cell - 56, 4))
        sheet.paste(light.convert("RGB"), (x, y + cell + 2))
        draw.text((x + 4, y + cell + 60), p.stem, font=font, fill=(235, 235, 245))
    sheet_path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(sheet_path, quality=90)


def selftest() -> int:
    with tempfile.TemporaryDirectory() as tmp:
        tmp = Path(tmp)
        # Hoja de 2x3 con círculos de contorno oscuro sobre blanco, desalineados como los de la IA.
        sheet = Image.new("RGB", (900, 600), (255, 255, 255))
        d = ImageDraw.Draw(sheet)
        colors = [(255, 200, 0), (60, 200, 90), (40, 140, 255), (230, 60, 60), (200, 120, 40), (180, 90, 255)]
        for i, col in enumerate(colors):
            cx = 150 + (i % 3) * 300 + (i * 13) % 30 - 15
            cy = 150 + (i // 3) * 300 + (i * 7) % 20 - 10
            d.ellipse((cx - 100, cy - 100, cx + 100, cy + 100), fill=(25, 25, 50))
            d.ellipse((cx - 88, cy - 88, cx + 88, cy + 88), fill=col)
            d.ellipse((cx - 50, cy - 60, cx - 20, cy - 30), fill=(255, 255, 255))  # brillo blanco adentro
        sheet.save(tmp / "hoja.png")
        names = ["a", "b", "c", "d", "e", "f"]
        out = slice_sheet(tmp / "hoja.png", 2, 3, names, tmp / "icons", size=256)
        assert [o["name"] for o in out] == names, out
        icon = Image.open(tmp / "icons" / "c.png")
        assert icon.size == (256, 256) and icon.mode == "RGBA"
        assert icon.getchannel("A").getpixel((2, 2)) == 0 and icon.getchannel("A").getpixel((128, 128)) == 255
        r, g, b, a = icon.getpixel((128, 128))
        assert b > 200 and r < 100, (r, g, b)  # el tercero es el azul: orden por filas
        # El brillo blanco de adentro no se borra (no está conectado con el fondo).
        assert min(pixels(Image.open(tmp / "icons" / "a.png").convert("RGBA").getchannel("A").crop((70, 60, 110, 100)))) == 255
        # Sin halo claro: en el borde no quedan píxeles casi blancos y opacos.
        edge = [px for px in pixels(icon) if 0 < px[3] < 255]
        assert edge and all(min(px[:3]) < 200 for px in edge), edge[:5]
        # Hoja ya transparente: usa su alfa.
        t = Image.new("RGBA", (600, 300), (0, 0, 0, 0))
        dt = ImageDraw.Draw(t)
        for i in range(2):
            dt.rectangle((50 + i * 300, 50, 250 + i * 300, 250), fill=(255, 0, 0, 255))
        t.save(tmp / "t.png")
        assert len(slice_sheet(tmp / "t.png", 1, 2, [], tmp / "t", size=128)) == 2
        try:
            slice_sheet(tmp / "t.png", 1, 3, [], tmp / "t3")
            raise AssertionError("tenía que fallar")
        except SheetError:
            pass
        preview(tmp / "icons", tmp / "rev.jpg")
        assert (tmp / "rev.jpg").exists()
    print("selftest OK")
    return 0


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    sub = parser.add_subparsers(dest="cmd", required=True)
    s = sub.add_parser("slice")
    s.add_argument("sheet")
    s.add_argument("--grid", default="3x3", help="filas x columnas")
    s.add_argument("--names", default="", help="nombres separados por coma, en orden de lectura")
    s.add_argument("--out", required=True)
    s.add_argument("--size", type=int, default=512)
    s.add_argument("--margin", type=float, default=0.06)
    s.add_argument("--tolerance", type=int, default=40, help="cuánto puede variar el color del fondo liso")
    p = sub.add_parser("preview")
    p.add_argument("folder")
    p.add_argument("--sheet", required=True)
    sub.add_parser("selftest")
    args = parser.parse_args(argv)
    try:
        if args.cmd == "slice":
            rows, cols = (int(v) for v in args.grid.lower().split("x"))
            names = [n.strip() for n in args.names.split(",") if n.strip()]
            for item in slice_sheet(Path(args.sheet), rows, cols, names, Path(args.out), args.size, args.margin, args.tolerance):
                print(f"  [ok] {item['file']}")
            return 0
        if args.cmd == "preview":
            preview(Path(args.folder), Path(args.sheet))
            print(f"  [ok] {args.sheet}")
            return 0
    except (SheetError, OSError, ValueError) as e:
        print(e, file=sys.stderr)
        return 1
    return selftest()


if __name__ == "__main__":
    sys.exit(main())
