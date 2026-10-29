"""Texturas de partículas estilo hit (destellos, estrellas, anillos, rayos, confeti, humo...), dibujadas por código.

  python tools/vfx_textures.py generate [--out assets/vfx/hit]
  python tools/vfx_textures.py preview [--out assets/vfx/hit] --sheet hoja.jpg
  python tools/vfx_textures.py selftest

- generate: dibuja todas las texturas en PNG con fondo transparente y escribe manifest.json con el
  uso sugerido de cada una (ParticleEmitter, Beam o Trail, y los valores de flipbook).
- preview: hoja de contacto sobre fondo oscuro, cada textura teñida como en el juego (LightEmission 1)
  y tres efectos armados (recompensa, huevo SECRET, velocidad).

Las de un solo color salen en blanco y gris: el color lo pone ParticleEmitter.Color, así una misma
textura sirve para dorado, cian o arcoíris. Las de confeti traen color y van en flipbook: con
FlipbookStartRandom y FlipbookFramerate 0 cada partícula toma un cuadro distinto (creator-docs,
ParticleEmitter, revisado el 2026-10-29). Se dibujan 4 veces más grandes y se achican, para bordes
suaves. Son nuestras: licencia "propio". Necesita Pillow.
"""
import argparse
import json
import math
import random
import sys
import tempfile
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "vfx" / "hit"
SS = 4  # supersampling
HIT_COLORS = {"gold": "#ffd34d", "cyan": "#4fe3ff", "magenta": "#ff4fd8", "lime": "#8dff4f", "white": "#ffffff"}
CONFETTI_COLORS = ["#ff3b6b", "#ffd23f", "#3bd1ff", "#8dff4f"]


# --- utilidades de máscaras (modo "L": 0 transparente, 255 opaco) ------------------------------

def blank(w, h=None):
    return Image.new("L", (w, h or w), 0)


def blur(m, r):
    return m.filter(ImageFilter.GaussianBlur(r)) if r > 0 else m


def scale(m, k):
    return m.point(lambda v: min(255, int(v * k)))


def lighter(*masks):
    out = masks[0]
    for m in masks[1:]:
        out = ImageChops.lighter(out, m)
    return out


def curve(m, power):
    return m.point(lambda v: int(255 * (v / 255) ** power))


def radial(size, power=1.0):
    """255 en el centro y 0 en el borde del círculo inscripto."""
    g = Image.radial_gradient("L").resize((size, size), Image.BICUBIC)
    return curve(ImageChops.invert(g), power)


def shape(size, draw_fn, round_px=0):
    """Dibuja a 4x y achica. round_px redondea las esquinas (desenfoque + umbral)."""
    big = blank(size * SS)
    draw_fn(ImageDraw.Draw(big), size * SS)
    if round_px:
        big = blur(big, round_px * SS).point(lambda v: 255 if v > 127 else 0)
    return big.resize((size, size), Image.LANCZOS)


def polygon(points):
    return lambda d, s: d.polygon([(x * s, y * s) for x, y in points], fill=255)


def white(alpha, shade=None):
    """RGBA blanco (o gris del sombreado) con la máscara como alfa."""
    rgb = shade if shade is not None else Image.new("L", alpha.size, 255)
    return Image.merge("RGBA", (rgb, rgb, rgb, alpha))


def bevel(alpha, size):
    """Sombreado suave para formas sólidas: centro claro, borde un poco más oscuro (le da volumen)."""
    inner = blur(alpha, size * 0.06)
    return inner.point(lambda v: int(185 + 70 * v / 255))


# --- texturas ----------------------------------------------------------------------------------

def astroid(cx, cy, r, p=2.5, n=200):
    pts = []
    for i in range(n):
        t = 2 * math.pi * i / n
        c, s = math.cos(t), math.sin(t)
        pts.append((cx + r * math.copysign(abs(c) ** p, c), cy + r * math.copysign(abs(s) ** p, s)))
    return pts


def tex_sparkle(size=512, rays=True, glow=1.0):
    # Estrella de 4 puntas con lados bien cóncavos (✦) y otra chica en diagonal, como los destellos de los hits.
    main = shape(size, polygon(astroid(0.5, 0.5, 0.45, 3.6)))
    diag = shape(size, polygon(astroid(0.5, 0.5, 0.2, 3.2))).rotate(45, resample=Image.BICUBIC)
    star = lighter(main, scale(diag, 0.85))
    halo = scale(blur(star, size * 0.025), 1.3 * glow)
    core = radial(size, 7.0)
    parts = [star, halo, core, scale(radial(size, 3.0), 0.35 * glow)]
    if rays:
        lines = shape(size, lambda d, s: (d.line([(0.0, 0.5 * s), (s, 0.5 * s)], fill=255, width=int(0.008 * s)),
                                          d.line([(0.5 * s, 0.0), (0.5 * s, s)], fill=255, width=int(0.008 * s))))
        parts.append(ImageChops.multiply(blur(lines, size * 0.002), radial(size, 1.1)))
    return white(lighter(*parts))


def tex_star(size=512):
    pts = []
    for i in range(10):
        r = 0.44 if i % 2 == 0 else 0.2
        a = -math.pi / 2 + i * math.pi / 5
        pts.append((0.5 + r * math.cos(a), 0.53 + r * math.sin(a)))
    star = shape(size, polygon(pts), round_px=size * 0.02)
    glow = scale(blur(star, size * 0.04), 0.6)
    return white(lighter(star, glow), bevel(star, size))


def tex_glow(size=512, power=2.2):
    return white(radial(size, power))


def tex_glow_core(size=512):
    return white(lighter(scale(radial(size, 1.8), 0.55), radial(size, 7.0)))


def tex_ring(size=512, width=0.035, soft=0.006):
    def draw(d, s):
        r1, r2 = 0.44 * s, (0.44 - width) * s
        d.ellipse((s / 2 - r1, s / 2 - r1, s / 2 + r1, s / 2 + r1), fill=255)
        d.ellipse((s / 2 - r2, s / 2 - r2, s / 2 + r2, s / 2 + r2), fill=0)
    ring = blur(shape(size, draw), size * soft)
    return white(lighter(ring, scale(blur(ring, size * 0.03), 1.3)))


def tex_rays(size=512, count=16, width=0.5):
    def draw(d, s):
        c = s / 2
        for i in range(count):
            a = 2 * math.pi * i / count
            half = math.pi / count * width
            d.polygon([(c, c), (c + s * math.cos(a - half), c + s * math.sin(a - half)),
                       (c + s * math.cos(a + half), c + s * math.sin(a + half))], fill=255)
    rays = blur(shape(size, draw), size * 0.004)
    return white(scale(ImageChops.multiply(rays, radial(size, 0.9)), 1.3))


def tex_beam(w=512, h=128):
    col = Image.new("L", (1, h))
    for y in range(h):
        d = (y - (h - 1) / 2) / (h / 2)
        v = 255 * min(1.0, math.exp(-(d / 0.12) ** 2) + 0.55 * math.exp(-(d / 0.45) ** 2))
        col.putpixel((0, y), int(v) if v >= 3 else 0)  # bordes del todo transparentes
    return white(col.resize((w, h), Image.BICUBIC))


def tex_trail(w=512, h=64):
    fade = Image.linear_gradient("L").rotate(90, expand=True).resize((w, h))  # 255 a la izquierda -> 0 a la derecha
    fade = ImageChops.invert(fade) if fade.getpixel((0, h // 2)) < 128 else fade
    col = Image.new("L", (1, h))
    for y in range(h):
        d = (y - (h - 1) / 2) / (h / 2)
        col.putpixel((0, y), int(255 * math.exp(-(d / 0.5) ** 2)))
    return white(ImageChops.multiply(curve(fade, 1.3), col.resize((w, h), Image.BICUBIC)))


def tex_smoke(size=512, seed=0):
    """Nube de "¡puf!" de dibujo animado: círculos que se pisan, borde limpio y sombra abajo a la derecha."""
    rnd = random.Random(seed)
    circles = [(0.5, 0.52, 0.2)]
    for i in range(7):
        a = 2 * math.pi * i / 7 + rnd.uniform(-0.3, 0.3)
        d = rnd.uniform(0.17, 0.24)
        circles.append((0.5 + d * math.cos(a), 0.52 + d * 0.8 * math.sin(a), rnd.uniform(0.1, 0.16)))

    def draw(dr, s):
        for x, y, r in circles:
            dr.ellipse(((x - r) * s, (y - r) * s, (x + r) * s, (y + r) * s), fill=255)

    puff = blur(shape(size, draw), size * 0.006)
    # Luz desde arriba a la izquierda: la sombra es la nube corrida hacia arriba a la izquierda.
    lit = ImageChops.offset(puff, -int(size * 0.04), -int(size * 0.05))
    shade = ImageChops.multiply(blur(lit, size * 0.03), puff).point(lambda v: int(175 + 80 * v / 255))
    return white(puff, shade)


def tex_heart(size=512):
    pts = []
    for i in range(240):
        t = 2 * math.pi * i / 240
        x = 16 * math.sin(t) ** 3
        y = 13 * math.cos(t) - 5 * math.cos(2 * t) - 2 * math.cos(3 * t) - math.cos(4 * t)
        pts.append((0.5 + x / 38, 0.47 - y / 38))
    heart = shape(size, polygon(pts))
    return white(lighter(heart, scale(blur(heart, size * 0.035), 0.55)), bevel(heart, size))


def tex_bubble(size=512):
    def rim(d, s):
        r1, r2 = 0.42 * s, 0.39 * s
        d.ellipse((s / 2 - r1, s / 2 - r1, s / 2 + r1, s / 2 + r1), fill=255)
        d.ellipse((s / 2 - r2, s / 2 - r2, s / 2 + r2, s / 2 + r2), fill=0)
    ring = blur(shape(size, rim), size * 0.004)
    fill = scale(ImageChops.invert(radial(size, 0.7)), 0.25)
    disk = shape(size, lambda d, s: d.ellipse((0.08 * s, 0.08 * s, 0.92 * s, 0.92 * s), fill=255))
    spot = blur(shape(size, lambda d, s: d.ellipse((0.27 * s, 0.22 * s, 0.43 * s, 0.33 * s), fill=255)), size * 0.008)
    return white(lighter(ring, ImageChops.multiply(fill, disk), spot))


def tex_bolt(size=512):
    pts = [(0.56, 0.04), (0.24, 0.55), (0.46, 0.55), (0.36, 0.96), (0.78, 0.4), (0.54, 0.4), (0.68, 0.04)]
    bolt = shape(size, polygon(pts), round_px=size * 0.006)
    return white(lighter(bolt, scale(blur(bolt, size * 0.04), 1.2)), bevel(bolt, size))


def tex_swirl(size=512):
    big = blank(size * SS)
    d = ImageDraw.Draw(big)
    s = size * SS
    # Trazo que se afina hacia el centro: círculos pegados (sin los serruchos de unir líneas de distinto ancho).
    steps = 900
    for i in range(steps):
        t = i / steps
        a = t * 3.2 * math.pi
        r = s * (0.05 + 0.38 * t)
        x, y = s / 2 + r * math.cos(a), s / 2 + r * math.sin(a)
        w = s * 0.028 * (0.25 + t)
        d.ellipse((x - w, y - w, x + w, y + w), fill=int(255 * (0.3 + 0.7 * t)))
    swirl = big.resize((size, size), Image.LANCZOS)
    return white(lighter(swirl, scale(blur(swirl, size * 0.03), 1.1)))


def tex_dust(size=128):
    return white(radial(size, 3.0))


def tex_glint(size=512):
    streak = shape(size, polygon([(0.08, 0.92), (0.92, 0.08), (0.98, 0.14), (0.14, 0.98)]))
    streak = ImageChops.multiply(blur(streak, size * 0.01), radial(size, 1.2))
    return white(lighter(streak, scale(radial(size, 8.0), 0.9)))


def flipbook(frames, grid):
    size = frames[0].width
    sheet = Image.new("RGBA", (size * grid, size * grid), (0, 0, 0, 0))
    for i, frame in enumerate(frames):
        sheet.alpha_composite(frame, ((i % grid) * size, (i // grid) * size))
    return sheet


def tex_twinkle(frame=256):
    frames = []
    for i in range(16):
        t = i / 15
        k = math.sin(math.pi * t)  # crece y se apaga
        spark = tex_sparkle(frame, rays=True).rotate(t * 45, resample=Image.BICUBIC)
        a = spark.getchannel("A").point(lambda v: int(v * k))
        small = Image.new("RGBA", (frame, frame), (0, 0, 0, 0))
        side = max(1, int(frame * (0.35 + 0.65 * k)))
        piece = Image.merge("RGBA", (*spark.split()[:3], a)).resize((side, side), Image.LANCZOS)
        small.alpha_composite(piece, ((frame - side) // 2, (frame - side) // 2))
        frames.append(small)
    return flipbook(frames, 4)


def tex_confetti(frame=256):
    def rect(d, s):
        d.polygon([(0.3 * s, 0.18 * s), (0.62 * s, 0.12 * s), (0.72 * s, 0.82 * s), (0.4 * s, 0.88 * s)], fill=255)

    def ribbon(d, s):
        pts = [(s * (0.15 + 0.7 * t), s * (0.5 + 0.18 * math.sin(t * 2.5 * math.pi))) for t in [i / 60 for i in range(61)]]
        d.line(pts, fill=255, width=int(0.11 * s), joint="curve")

    def tri(d, s):
        d.polygon([(0.5 * s, 0.14 * s), (0.86 * s, 0.82 * s), (0.14 * s, 0.82 * s)], fill=255)

    def dot(d, s):
        d.ellipse((0.24 * s, 0.24 * s, 0.76 * s, 0.76 * s), fill=255)

    frames = []
    for draw in (rect, ribbon, tri, dot):
        alpha = shape(frame, draw, round_px=frame * 0.012)
        shade = blur(alpha, frame * 0.05).point(lambda v: int(200 + 55 * v / 255))  # borde un poco más oscuro
        for hexcol in CONFETTI_COLORS:
            r, g, b = (int(hexcol[i:i + 2], 16) for i in (1, 3, 5))
            rgb = [shade.point(lambda v, c=c: c * v // 255) for c in (r, g, b)]
            frames.append(Image.merge("RGBA", (*rgb, alpha)))
    return flipbook(frames, 4)


# Nombre -> (función, uso sugerido para el manifest)
TEXTURES = {
    "sparkle": (tex_sparkle, "ParticleEmitter. El destello de todo: premios, rarezas, monedas. LightEmission 1, rotación al azar."),
    "sparkle_soft": (lambda: tex_sparkle(rays=False, glow=1.6), "ParticleEmitter. Destello sin rayos para estelas mágicas y auras."),
    "twinkle_4x4": (tex_twinkle, "ParticleEmitter con FlipbookLayout Grid4x4 y FlipbookMode OneShot: el destello aparece, gira y se apaga."),
    "star": (tex_star, "ParticleEmitter. Estrella con volumen para ráfagas de recompensa y subidas de nivel."),
    "glow": (tex_glow, "ParticleEmitter (o BillboardGui). Brillo suave detrás de ítems, auras de rareza."),
    "glow_core": (tex_glow_core, "ParticleEmitter. Brillo con centro intenso: orbes, chispas grandes."),
    "ring": (tex_ring, "ParticleEmitter con Size creciente y Transparency que sube: onda expansiva de huevo, renacer o compra."),
    "ring_soft": (lambda: tex_ring(width=0.12, soft=0.02), "ParticleEmitter. Onda gruesa y suave para auras y zonas."),
    "rays": (tex_rays, "ParticleEmitter con RotSpeed lento (o ImageLabel en UI): rayos detrás del premio."),
    "rays_thin": (lambda: tex_rays(count=32, width=0.35), "ParticleEmitter. Estallido de rayos finos para revelaciones SECRET."),
    "beam": (tex_beam, "Beam (textura a lo largo): pilares de luz de rareza, rayos entre objetos."),
    "trail": (tex_trail, "Trail: estela de velocidad detrás del avatar o de un ítem que vuela."),
    "smoke_2x2": (lambda: flipbook([tex_smoke(seed=i) for i in range(4)], 2),
                  "ParticleEmitter con FlipbookLayout Grid2x2, FlipbookStartRandom y FlipbookFramerate 0: polvo al correr, puf al aparecer."),
    "confetti_4x4": (tex_confetti, "ParticleEmitter con FlipbookLayout Grid4x4, FlipbookStartRandom y FlipbookFramerate 0: confeti de 4 formas y 4 colores. Color blanco (ya trae color)."),
    "heart": (tex_heart, "ParticleEmitter. Corazones para likes, regalos y mascotas."),
    "bubble": (tex_bubble, "ParticleEmitter. Burbujas para agua, pesca y pociones."),
    "bolt": (tex_bolt, "ParticleEmitter. Rayo para boosts de velocidad y golpes."),
    "swirl": (tex_swirl, "ParticleEmitter con RotSpeed: remolino mágico para renacer, fusión o portal."),
    "dust": (tex_dust, "ParticleEmitter. Punto suave chico para chispitas y polvo fino."),
    "glint": (tex_glint, "ParticleEmitter (una partícula, vida corta): brillo que cruza un ítem 'shiny'."),
}


def generate(out: Path) -> list:
    out.mkdir(parents=True, exist_ok=True)
    items = []
    for name, (fn, use) in TEXTURES.items():
        img = fn()
        path = out / f"{name}.png"
        img.save(path, optimize=True)
        items.append({"name": name, "file": path.name, "size": list(img.size), "use": use,
                      "kb": round(path.stat().st_size / 1024)})
    manifest = {
        "pack": "hit-vfx", "kind": "image", "source": "tools/vfx_textures.py", "license": "propio",
        "author": "RobloxCreator", "count": len(items),
        "notes": "Blancas o grises para teñir con ParticleEmitter.Color (salvo confetti_4x4, que trae color). "
                 "Subir con tools/roblox_upload.py y usar el id en Texture.",
        "items": items,
    }
    (out / "manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    return items


def tint(img: Image.Image, hexcol: str) -> Image.Image:
    r, g, b = (int(hexcol[i:i + 2], 16) for i in (1, 3, 5))
    rr, gg, bb, a = img.split()
    rgb = [ch.point(lambda v, c=c: v * c // 255) for ch, c in ((rr, r), (gg, g), (bb, b))]
    return Image.merge("RGBA", (*rgb, a))


def additive(base: Image.Image, img: Image.Image, xy=(0, 0), opacity=1.0):
    """Suma como LightEmission 1: color por alfa, sumado al fondo."""
    layer = Image.new("RGB", base.size, (0, 0, 0))
    rgb = img.convert("RGB")
    alpha = img.getchannel("A").point(lambda v: int(v * opacity))
    premul = Image.composite(rgb, Image.new("RGB", img.size, (0, 0, 0)), alpha)
    layer.paste(premul, xy)
    return ImageChops.add(base, layer)


def frame_of(sheet: Image.Image, grid: int, index: int) -> Image.Image:
    s = sheet.width // grid
    return sheet.crop(((index % grid) * s, (index // grid) * s, (index % grid + 1) * s, (index // grid + 1) * s))


def demos(src: Path) -> list:
    load = lambda n: Image.open(src / f"{n}.png").convert("RGBA")  # noqa: E731
    rnd = random.Random(7)
    size = 512
    bg = (16, 16, 26)

    reward = Image.new("RGB", (size, size), bg)
    reward = additive(reward, tint(load("rays"), HIT_COLORS["gold"]), opacity=0.55)
    reward = additive(reward, tint(load("glow"), HIT_COLORS["gold"]), opacity=0.8)
    star = tint(load("star").resize((220, 220), Image.LANCZOS), HIT_COLORS["gold"])
    reward.paste(star, (146, 140), star)
    confetti = load("confetti_4x4")
    for _ in range(26):
        piece = frame_of(confetti, 4, rnd.randrange(16)).resize((40, 40), Image.LANCZOS).rotate(rnd.randrange(360), expand=True)
        reward.paste(piece, (rnd.randrange(0, size - 50), rnd.randrange(0, size - 50)), piece)
    for _ in range(9):
        s = rnd.randrange(50, 120)
        reward = additive(reward, load("sparkle").resize((s, s), Image.LANCZOS), (rnd.randrange(0, size - s), rnd.randrange(0, size - s)))

    secret = Image.new("RGB", (size, size), bg)
    rays = load("rays_thin")
    for i, col in enumerate(("#ff4fd8", "#4fe3ff", "#ffd34d")):
        secret = additive(secret, tint(rays.rotate(i * 4, resample=Image.BICUBIC), col), opacity=0.45)
    secret = additive(secret, tint(load("ring"), HIT_COLORS["magenta"]))
    secret = additive(secret, tint(load("ring_soft").resize((360, 360), Image.LANCZOS), HIT_COLORS["cyan"]), (76, 76), 0.8)
    secret = additive(secret, tint(load("glow_core").resize((300, 300), Image.LANCZOS), "#ffffff"), (106, 106))
    twinkle = load("twinkle_4x4")
    for _ in range(10):
        s = rnd.randrange(40, 110)
        f = frame_of(twinkle, 4, rnd.randrange(4, 12)).resize((s, s), Image.LANCZOS)
        secret = additive(secret, tint(f, rnd.choice(["#ffffff", HIT_COLORS["cyan"], HIT_COLORS["magenta"]])),
                          (rnd.randrange(0, size - s), rnd.randrange(0, size - s)))

    speed = Image.new("RGB", (size, size), bg)
    trail = load("trail")
    for i in range(7):
        t = tint(trail.resize((rnd.randrange(260, 460), rnd.randrange(30, 60)), Image.LANCZOS), HIT_COLORS["cyan"])
        speed = additive(speed, t, (rnd.randrange(150, 260), 60 + i * 60), 0.85)
    bolt = tint(load("bolt").resize((240, 240), Image.LANCZOS), HIT_COLORS["gold"])
    speed = additive(speed, bolt, (40, 130))
    smoke = load("smoke_2x2")
    for i in range(5):
        puff = frame_of(smoke, 2, i % 4).resize((110, 110), Image.LANCZOS)
        speed.paste(puff, (300 + i * 38 - 60, 380 + rnd.randrange(-20, 20)), puff)
    for _ in range(14):
        s = rnd.randrange(14, 40)
        speed = additive(speed, tint(load("dust").resize((s, s), Image.LANCZOS), HIT_COLORS["white"]),
                         (rnd.randrange(0, size - s), rnd.randrange(0, size - s)))
    return [("Recompensa", reward), ("Huevo SECRET", secret), ("Velocidad", speed)]


def preview(src: Path, sheet_path: Path):
    names = list(TEXTURES)
    colors = ["gold", "cyan", "magenta", "white", "lime"]
    cell, pad, cols = 220, 14, 5
    rows = math.ceil(len(names) / cols)
    font_path = ROOT / "assets" / "fonts" / "lilita-one" / "LilitaOne-Regular.ttf"
    font = ImageFont.truetype(str(font_path), 22)
    big_font = ImageFont.truetype(str(font_path), 28)
    demo_h = 512 + 50
    w = pad + cols * (cell + pad)
    h = pad + rows * (cell + 34 + pad) + demo_h + pad
    sheet = Image.new("RGB", (w, h), (12, 12, 18))
    draw = ImageDraw.Draw(sheet)
    for i, name in enumerate(names):
        img = Image.open(src / f"{name}.png").convert("RGBA")
        if name.endswith("4x4"):
            img = img if name.startswith("confetti") else frame_of(img, 4, 7)
        elif name.endswith("2x2"):
            img = frame_of(img, 2, 0)
        k = min(cell / img.width, cell / img.height)
        img = img.resize((max(1, int(img.width * k)), max(1, int(img.height * k))), Image.LANCZOS)
        if not name.startswith(("confetti", "smoke")):
            img = tint(img, HIT_COLORS[colors[i % len(colors)]])
        x = pad + (i % cols) * (cell + pad)
        y = pad + (i // cols) * (cell + 34 + pad)
        tile = Image.new("RGB", (cell, cell), (24, 24, 36))
        xy = ((cell - img.width) // 2, (cell - img.height) // 2)
        if name.startswith(("confetti", "smoke")):
            tile.paste(img, xy, img)
        else:
            tile = additive(tile, img, xy)
        sheet.paste(tile, (x, y))
        draw.text((x + 4, y + cell + 4), name, font=font, fill=(235, 235, 245))
    y0 = pad + rows * (cell + 34 + pad)
    x = pad
    for title, img in demos(src):
        small = img.resize((int((w - 4 * pad) / 3), int((w - 4 * pad) / 3)), Image.LANCZOS)
        if small.height > demo_h - 50:
            small = img.resize((demo_h - 50, demo_h - 50), Image.LANCZOS)
        sheet.paste(small, (x, y0 + 40))
        draw.text((x, y0 + 4), title, font=big_font, fill=(255, 255, 255))
        x += small.width + pad
    sheet = sheet.crop((0, 0, w, y0 + 40 + small.height + pad))
    sheet_path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(sheet_path, quality=90)


def selftest() -> int:
    with tempfile.TemporaryDirectory() as tmp:
        tmp = Path(tmp)
        items = generate(tmp)
        assert len(items) == len(TEXTURES)
        for item in items:
            img = Image.open(tmp / item["file"])
            assert img.mode == "RGBA", item
            lo, hi = img.getchannel("A").getextrema()
            assert lo == 0 and hi >= 200, (item["name"], lo, hi)  # fondo transparente y forma visible
            w, h = img.size
            if item["name"].endswith("4x4"):
                assert w == h and w % 4 == 0, item
            if item["name"].endswith("2x2"):
                assert w == h and w % 2 == 0, item
        # El centro de un destello es opaco; la esquina, transparente.
        spark = Image.open(tmp / "sparkle.png")
        assert spark.getchannel("A").getpixel((256, 256)) > 240 and spark.getchannel("A").getpixel((5, 5)) < 10
        # El confeti trae color; el resto es blanco o gris para teñir.
        conf = frame_of(Image.open(tmp / "confetti_4x4.png").convert("RGBA"), 4, 0)
        r, g, b, a = conf.getpixel((128, 128))
        assert a > 200 and r > g + 60, (r, g, b, a)
        r, g, b, _ = Image.open(tmp / "star.png").getpixel((256, 280))
        assert r == g == b, (r, g, b)
        manifest = json.loads((tmp / "manifest.json").read_text(encoding="utf-8"))
        assert manifest["count"] == len(TEXTURES) and manifest["license"] == "propio"
        preview(tmp, tmp / "hoja.jpg")
        assert Image.open(tmp / "hoja.jpg").width > 1000
    print("selftest OK")
    return 0


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    sub = parser.add_subparsers(dest="cmd", required=True)
    g = sub.add_parser("generate")
    g.add_argument("--out", default=str(OUT))
    p = sub.add_parser("preview")
    p.add_argument("--out", default=str(OUT))
    p.add_argument("--sheet", required=True)
    sub.add_parser("selftest")
    args = parser.parse_args(argv)
    if args.cmd == "generate":
        for item in generate(Path(args.out)):
            print(f"  [ok] {item['file']} {item['size'][0]}x{item['size'][1]} ({item['kb']} KB)")
        return 0
    if args.cmd == "preview":
        preview(Path(args.out), Path(args.sheet))
        print(f"  [ok] {args.sheet}")
        return 0
    return selftest()


if __name__ == "__main__":
    sys.exit(main())
