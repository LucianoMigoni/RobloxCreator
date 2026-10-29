"""Texturas de la UI estilo hit (studs de Roblox, damero, puntos, franjas de brillo, rayos de sol, destello,
sombra, flechas de camino), dibujadas por código.

  python tools/ui_textures.py generate [--out assets/ui/hit-skin]
  python tools/ui_textures.py preview [--out assets/ui/hit-skin] --sheet hoja.jpg
  python tools/ui_textures.py selftest

Por qué existen: los hits no arman la UI con colores planos. Steal An Egg y +1 Speed Keyboard Escape
ponen studs de Roblox en ventanas y botones, Anime Dice un damero en tarjetas y botones, y las
cabeceras llevan franjas diagonales de brillo (skills/roblox-ui-designer/references/hud-hits.md).
Con estas texturas encima de un Frame con degradé, UIKit consigue ese material sin una imagen por color.

- Las de patrón son mosaicos: ImageLabel con ScaleType Tile y TileSize en píxeles (creator-docs,
  ImageLabel.ScaleType y TileSize, revisado el 2026-10-29). Mezclan blanco (brillo) y negro (sombra)
  semitransparentes, así sirven sobre cualquier color; la intensidad la pone ImageTransparency.
- `shadow` es de 9 cortes (ScaleType Slice, SliceCenter en manifest.json).
- `sunburst`, `glow` y `sparkle` salen en blanco: el color lo pone ImageColor3.
- `arrows` es para un Beam en el piso que guía al jugador (flechas que avanzan con TextureSpeed).

Se dibujan 4 veces más grandes y se achican, para bordes suaves. Son nuestras: licencia "propio".
Necesita Pillow.
"""
import argparse
import json
import math
import sys
import tempfile
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "ui" / "hit-skin"
SS = 4  # supersampling


def shrink(img, size):
    return img.resize(size, Image.LANCZOS)


def solid(alpha_mask, rgb):
    """Imagen de un color con la máscara como alfa."""
    img = Image.new("RGBA", alpha_mask.size, rgb + (0,))
    img.putalpha(alpha_mask)
    return img


def scale_mask(mask, k):
    return mask.point(lambda v: min(255, int(v * k)))


def over(base, top):
    return Image.alpha_composite(base, top)


def rounded_mask(size, box, radius, blur=0):
    m = Image.new("L", size, 0)
    ImageDraw.Draw(m).rounded_rectangle(box, radius=radius, fill=255)
    return m.filter(ImageFilter.GaussianBlur(blur)) if blur else m


def bevel(size, shape_mask, depth, light=0.55, dark=0.45):
    """Brillo arriba a la izquierda y sombra abajo a la derecha del borde de una forma (relieve)."""
    shifted_dark = ImageChops.offset(shape_mask, depth, depth)
    shifted_light = ImageChops.offset(shape_mask, -depth, -depth)
    rim_light = ImageChops.subtract(shape_mask, shifted_dark)  # borde que mira arriba-izquierda
    rim_dark = ImageChops.subtract(shape_mask, shifted_light)  # borde que mira abajo-derecha
    soft = max(1, depth // 2)
    rim_light = rim_light.filter(ImageFilter.GaussianBlur(soft))
    rim_dark = rim_dark.filter(ImageFilter.GaussianBlur(soft))
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    img = over(img, solid(scale_mask(rim_dark, dark), (0, 0, 0)))
    img = over(img, solid(scale_mask(rim_light, light), (255, 255, 255)))
    return img


# --- patrones (mosaicos) -------------------------------------------------------------------------

def studs(tile=64):
    """Un stud de Roblox por mosaico: placa con relieve suave y botón redondo con brillo y sombra."""
    n = tile * SS
    size = (n, n)
    inset, radius = int(n * 0.06), int(n * 0.16)
    plate = rounded_mask(size, (inset, inset, n - inset, n - inset), radius)
    img = bevel(size, plate, int(n * 0.035), light=0.35, dark=0.35)
    r = int(n * 0.24)
    c = n // 2
    stud = Image.new("L", size, 0)
    ImageDraw.Draw(stud).ellipse((c - r, c - r, c + r, c + r), fill=255)
    # Sombra proyectada solo por fuera del botón, para que se vea en relieve y no hundido.
    drop = ImageChops.offset(stud, int(n * 0.035), int(n * 0.045)).filter(ImageFilter.GaussianBlur(n * 0.02))
    drop = ImageChops.subtract(drop, stud)
    img = over(img, solid(scale_mask(drop, 0.45), (0, 0, 0)))
    img = over(img, solid(scale_mask(stud, 0.16), (255, 255, 255)))
    img = over(img, bevel(size, stud, int(n * 0.03), light=0.75, dark=0.3))
    return shrink(img, (tile, tile))


def checker(tile=64):
    """Damero 2x2: dos cuadros blancos opacos (la transparencia la pone ImageTransparency)."""
    img = Image.new("RGBA", (tile, tile), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    h = tile // 2
    d.rectangle((0, 0, h - 1, h - 1), fill=(255, 255, 255, 255))
    d.rectangle((h, h, tile - 1, tile - 1), fill=(255, 255, 255, 255))
    return img


def dots(tile=64):
    """Lunares en tresbolillo: uno al centro y cuartos en las esquinas."""
    n = tile * SS
    m = Image.new("L", (n, n), 0)
    d = ImageDraw.Draw(m)
    r = int(n * 0.13)
    for cx, cy in ((n // 2, n // 2), (0, 0), (n, 0), (0, n), (n, n)):
        d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=255)
    return shrink(solid(m, (255, 255, 255)), (tile, tile))


# --- brillos y luces ----------------------------------------------------------------------------

def stripes(w=512, h=128):
    """Franjas diagonales de brillo para cabeceras de ventana y botones grandes (como Steal An Egg)."""
    W, H = w * SS, h * SS
    m = Image.new("L", (W, H), 0)
    d = ImageDraw.Draw(m)
    skew = H * 0.62
    # (centro relativo, ancho relativo, intensidad)
    for cx, width, alpha in ((0.30, 0.12, 255), (0.43, 0.05, 200), (0.70, 0.08, 150)):
        x0 = cx * W - width * W / 2
        x1 = x0 + width * W
        d.polygon([(x0 + skew, 0), (x1 + skew, 0), (x1 - skew * 0.1, H), (x0 - skew * 0.1, H)], fill=alpha)
    return shrink(solid(m.filter(ImageFilter.GaussianBlur(SS)), (255, 255, 255)), (w, h))


def sunburst(size=512, rays=12):
    """Rayos de sol para girar detrás de una oferta, una mascota nueva o un premio."""
    n = size * SS
    c = n / 2
    m = Image.new("L", (n, n), 0)
    d = ImageDraw.Draw(m)
    half = math.pi / rays * 0.5  # mitad rayo, mitad hueco
    for i in range(rays):
        a = i * 2 * math.pi / rays
        p1 = (c + math.cos(a - half) * n, c + math.sin(a - half) * n)
        p2 = (c + math.cos(a + half) * n, c + math.sin(a + half) * n)
        d.polygon([(c, c), p1, p2], fill=255)
    m = m.filter(ImageFilter.GaussianBlur(n * 0.004))
    # Se desvanece recién cerca del borde y tiene un núcleo de luz.
    fade = Image.new("L", (n, n), 0)
    fd = ImageDraw.Draw(fade)
    steps = 64
    for i in range(steps):
        r = c * (1 - i / steps)
        v = int(255 * min(1.0, (i / steps) / 0.45) ** 0.8)
        fd.ellipse((c - r, c - r, c + r, c + r), fill=v)
    m = ImageChops.multiply(m, fade)
    core = Image.new("L", (n, n), 0)
    ImageDraw.Draw(core).ellipse((c - n * 0.16, c - n * 0.16, c + n * 0.16, c + n * 0.16), fill=230)
    m = ImageChops.lighter(m, core.filter(ImageFilter.GaussianBlur(n * 0.06)))
    return shrink(solid(m, (255, 255, 255)), (size, size))


def glow(size=256):
    n = size * SS
    c = n / 2
    m = Image.new("L", (n, n), 0)
    d = ImageDraw.Draw(m)
    steps = 96
    for i in range(steps):
        r = c * (1 - i / steps)
        d.ellipse((c - r, c - r, c + r, c + r), fill=int(255 * (i / steps) ** 2.2))
    return shrink(solid(m, (255, 255, 255)), (size, size))


def sparkle(size=128):
    """Destello de 4 puntas con halo (esquinas de las tarjetas destacadas)."""
    n = size * SS
    c = n / 2
    m = Image.new("L", (n, n), 0)
    d = ImageDraw.Draw(m)
    long_, thin = n * 0.48, n * 0.07
    d.polygon([(c, c - long_), (c + thin, c), (c, c + long_), (c - thin, c)], fill=255)
    d.polygon([(c - long_, c), (c, c - thin), (c + long_, c), (c, c + thin)], fill=255)
    halo = Image.new("L", (n, n), 0)
    ImageDraw.Draw(halo).ellipse((c - n * 0.14, c - n * 0.14, c + n * 0.14, c + n * 0.14), fill=170)
    m = ImageChops.lighter(m, halo.filter(ImageFilter.GaussianBlur(n * 0.05)))
    return shrink(solid(m, (255, 255, 255)), (size, size))


def shadow(size=128, radius=28, blur=14):
    """Sombra suave de 9 cortes para ventanas y botones grandes."""
    n = size * SS
    pad = int(n * 0.3)
    m = rounded_mask((n, n), (pad, pad, n - pad, n - pad), radius * SS, blur * SS)
    return shrink(solid(scale_mask(m, 0.75), (0, 0, 0)), (size, size))


def arrows(w=256, h=64):
    """Tres flechas gordas con borde, para un Beam en el piso que marca el camino al objetivo."""
    W, H = w * SS, h * SS
    m = Image.new("L", (W, H), 0)
    d = ImageDraw.Draw(m)
    count = 3
    cell = W / count
    for i in range(count):
        x = i * cell + cell * 0.18
        t = cell * 0.30  # grosor
        tip = cell * 0.62
        d.polygon([(x, H * 0.08), (x + t, H * 0.08), (x + tip, H * 0.5), (x + t, H * 0.92), (x, H * 0.92), (x + tip - t, H * 0.5)], fill=255)
    edge = m.filter(ImageFilter.MaxFilter(9))
    img = over(solid(edge, (40, 10, 10)), solid(m, (255, 255, 255)))
    return shrink(img, (w, h))


TEXTURES = {
    "studs": (studs, "Mosaico: TileSize 64x64 px a 1080p; ImageTransparency 0.55-0.8 sobre paneles y botones"),
    "checker": (checker, "Mosaico: TileSize 48-64 px; ImageTransparency 0.9-0.94 en tarjetas y botones"),
    "dots": (dots, "Mosaico: TileSize 40-64 px; ImageTransparency 0.85-0.92 en fondos de tarjeta"),
    "stripes": (stripes, "Estirada sobre la cabecera de una ventana o un botón grande; ImageTransparency 0.55-0.75"),
    "sunburst": (sunburst, "Detrás de una oferta o premio, girando (Rotation += 30 grados/s); ImageColor3 al gusto"),
    "glow": (glow, "Halo detrás de íconos y tarjetas raras; ImageColor3 del color de la rareza"),
    "sparkle": (sparkle, "Destellos en las esquinas de tarjetas destacadas, con pulso de escala"),
    "shadow": (shadow, "9 cortes detrás de ventanas: ScaleType Slice, SliceCenter Rect(48,48,80,80)"),
    "arrows": (arrows, "Beam en el piso hacia el objetivo: TextureMode Wrap, TextureSpeed 1-2, Color rojo o amarillo"),
}


def generate(out: Path) -> list:
    out.mkdir(parents=True, exist_ok=True)
    items = []
    for name, (fn, usage) in TEXTURES.items():
        img = fn()
        path = out / f"{name}.png"
        img.save(path)
        items.append({"name": name, "file": path.name, "size": list(img.size), "usage": usage})
    manifest = {
        "pack": "hit-skin",
        "kind": "ui-texture",
        "count": len(items),
        "source": "código propio: tools/ui_textures.py",
        "license": "propio",
        "style": "Material de la UI de los hits: studs, damero, franjas de brillo, rayos y destellos",
        "notes": "Subir con tools/roblox_upload.py; UIKit las toma de AssetIds.textures. Sin subir, la UI se ve igual pero plana.",
        "items": items,
    }
    (out / "manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    return items


def tile_fill(size, tile_img, tile_px):
    t = tile_img.resize((tile_px, tile_px), Image.LANCZOS)
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    for y in range(0, size[1], tile_px):
        for x in range(0, size[0], tile_px):
            img.alpha_composite(t, (x, y))
    return img


def fade(img, transparency):
    r, g, b, a = img.split()
    a = a.point(lambda v: int(v * (1 - transparency)))
    return Image.merge("RGBA", (r, g, b, a))


def preview(out: Path, sheet: Path):
    """Cada textura como se usa en el juego, sobre los colores de los hits."""
    tex = {name: Image.open(out / f"{name}.png").convert("RGBA") for name in TEXTURES}
    W, H = 1500, 900
    canvas = Image.new("RGBA", (W, H), (24, 22, 34, 255))
    swatches = [((62, 201, 74), "studs", 0.55), ((41, 168, 232), "studs", 0.6), ((58, 58, 66), "studs", 0.8),
                ((214, 82, 214), "checker", 0.9), ((40, 46, 92), "checker", 0.92), ((246, 166, 35), "dots", 0.85)]
    for i, (rgb, name, tr) in enumerate(swatches):
        x, y = 30 + (i % 3) * 490, 30 + (i // 3) * 210
        base = Image.new("RGBA", (460, 180), rgb + (255,))
        base.alpha_composite(fade(tile_fill((460, 180), tex[name], 48), tr))
        canvas.alpha_composite(base, (x, y))
    header = Image.new("RGBA", (700, 120), (92, 214, 92, 255))
    header.alpha_composite(fade(tex["stripes"].resize((700, 120)), 0.55))
    canvas.alpha_composite(header, (30, 470))
    sun = tex["sunburst"].resize((300, 300))
    tinted = Image.new("RGBA", sun.size, (255, 214, 90, 255))
    tinted.putalpha(sun.split()[3])
    canvas.alpha_composite(tinted, (780, 450))
    canvas.alpha_composite(tex["glow"].resize((200, 200)), (1100, 470))
    canvas.alpha_composite(tex["sparkle"], (1330, 500))
    canvas.alpha_composite(tex["shadow"].resize((260, 160)), (1180, 700))
    canvas.alpha_composite(tex["arrows"].resize((512, 128)), (30, 640))
    tinted_arrows = Image.new("RGBA", (512, 128), (235, 40, 40, 255))
    tinted_arrows.putalpha(tex["arrows"].resize((512, 128)).split()[3])
    canvas.alpha_composite(tinted_arrows, (580, 760))
    canvas.convert("RGB").save(sheet, quality=88)
    print(f"Hoja: {sheet}")


def selftest() -> int:
    with tempfile.TemporaryDirectory() as tmp:
        out = Path(tmp)
        items = generate(out)
        assert len(items) == len(TEXTURES)
        for it in items:
            img = Image.open(out / it["file"])
            assert img.mode == "RGBA", it
            alpha = img.split()[3]
            assert alpha.getextrema()[1] > 0, f"{it['name']} vacía"
        # Los mosaicos tienen que repetirse sin costura: bordes opuestos parecidos.
        st = Image.open(out / "studs.png").split()[3]
        left = [st.getpixel((0, y)) for y in range(64)]
        right = [st.getpixel((63, y)) for y in range(64)]
        assert max(abs(a - b) for a, b in zip(left, right)) < 40, "studs con costura"
        ck = Image.open(out / "checker.png")
        assert ck.getpixel((0, 0))[3] == 255 and ck.getpixel((40, 0))[3] == 0
        manifest = json.loads((out / "manifest.json").read_text(encoding="utf-8"))
        assert manifest["count"] == len(TEXTURES) and manifest["license"] == "propio"
        preview(out, out / "hoja.jpg")
        assert (out / "hoja.jpg").stat().st_size > 10000
    print("ui_textures selftest OK")
    return 0


def main(argv=None) -> int:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest="cmd", required=True)
    g = sub.add_parser("generate")
    g.add_argument("--out", default=str(OUT))
    v = sub.add_parser("preview")
    v.add_argument("--out", default=str(OUT))
    v.add_argument("--sheet", required=True)
    sub.add_parser("selftest")
    a = p.parse_args(argv)
    if a.cmd == "generate":
        items = generate(Path(a.out))
        print(f"{len(items)} texturas en {a.out}")
        return 0
    if a.cmd == "preview":
        preview(Path(a.out), Path(a.sheet))
        return 0
    return selftest()


if __name__ == "__main__":
    sys.exit(main())
