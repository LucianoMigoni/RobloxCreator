"""Miniaturas, íconos y creatividades de anuncios estilo hit, armados por capas desde una receta JSON.

  python tools/thumbs.py compose receta.json [--out salida.png] [--set clave=valor ...] [--base ia.png]
  python tools/thumbs.py check imagen.png --kind thumbnail|icon|ad [--previews carpeta]
  python tools/thumbs.py sheet a.png b.png ... --out hoja.jpg [--cols 3]
  python tools/thumbs.py selftest

- compose: arma la imagen. Las recetas de skills/_shared/vitrina/recetas/ traen las composiciones de
  los hits ("robo con tensión", "número gigante", "huevo gigante"...); `{{clave}}` en la receta se
  reemplaza con --set clave=valor (por ejemplo la ruta del render del personaje) o con el valor de
  "_defaults". Sin --base sale el boceto (fondo, renders y textos); con --base ia.png la imagen
  generada por IA (tools/imagegen.py) es el fondo y solo se dibujan los textos y las flechas.
  Cada imagen de IA sale distinta: --at id=x,y mueve un texto (id de la capa en la receta),
  --at id=x0,y0,x1,y1 mueve una flecha y --hide id saca una capa.
- check: tamaño, peso y proporción oficiales, zona de abajo que tapa el contador de jugadores,
  saturación y contraste comparados con los hits, y vistas previas al tamaño real en que se ven
  (ícono a 150 px, mosaico de Home). Salida: avisos y PNG en --previews.
- sheet: hoja de contacto para elegir entre variantes.

Reglas oficiales (skills/_shared/vitrina-hits.md): miniatura 16:9, ideal 1920x1080 y menos de 3 MB
para Home; ícono cuadrado de 512x512 o más que se lea a 150x150. Las imágenes de entrada son renders
o capturas propias del juego, assets del catálogo con uso comercial o imágenes de IA hechas con esas
referencias: nada de arte de otros juegos. Necesita Pillow (pip install pillow).
"""
import argparse
import json
import math
import sys
from pathlib import Path

try:
    from PIL import Image, ImageChops, ImageDraw, ImageEnhance, ImageFilter, ImageFont, ImageStat
except ImportError:  # pragma: no cover - el mensaje lo ve quien no tiene Pillow
    print("Falta Pillow: pip install pillow", file=sys.stderr)
    raise

ROOT = Path(__file__).resolve().parent.parent
FONTS = {
    "luckiest-guy": "assets/fonts/luckiest-guy/LuckiestGuy-Regular.ttf",
    "titan-one": "assets/fonts/titan-one/TitanOne-Regular.ttf",
    "lilita-one": "assets/fonts/lilita-one/LilitaOne-Regular.ttf",
    "bangers": "assets/fonts/bangers/Bangers-Regular.ttf",
    "fredoka": "assets/fonts/fredoka/Fredoka-Variable.ttf",
}
KINDS = {
    # tamaño ideal, proporción, peso máximo (bytes), fracción de abajo que no debe tener nada esencial
    "thumbnail": {"size": (1920, 1080), "ratio": 16 / 9, "max_bytes": 3 * 1024 * 1024, "safe_bottom": 0.2},
    "ad": {"size": (1920, 1080), "ratio": 16 / 9, "max_bytes": 3 * 1024 * 1024, "safe_bottom": 0.0},
    "icon": {"size": (512, 512), "ratio": 1.0, "max_bytes": None, "safe_bottom": 0.0},
}
RAINBOW = ["#ff3b3b", "#ff9a1f", "#ffe11f", "#3cff5a", "#2ec5ff", "#7a5cff", "#ff4fd8"]
# Saturación media (canal S de HSV, 0-255) y desvío de luminancia de las imágenes oficiales de 15
# hits (15 íconos y 76 miniaturas: Steal An Egg, Steal a Brainrot, Fish It!, Grow a Garden, Pet
# Simulator 99, +1 Speed Keyboard Escape...), medidos el 2026-10-28 con tools/roblox_research.py
# images. (mediana, percentil 25): por debajo del p25 la imagen es más apagada o plana que 3 de
# cada 4 hits. Es una referencia para avisar, no una regla.
HIT_LOOK = {
    "icon": {"saturation": (169, 132), "contrast": (66, 58)},
    "thumbnail": {"saturation": (160, 139), "contrast": (55, 49)},
}
HIT_LOOK["ad"] = HIT_LOOK["thumbnail"]


class ThumbError(Exception):
    pass


def color(value, alpha=255):
    """'#rrggbb', '#rrggbbaa' o [r, g, b(, a)] -> tupla RGBA."""
    if isinstance(value, (list, tuple)):
        return tuple(int(v) for v in value) + ((alpha,) if len(value) == 3 else ())
    value = value.lstrip("#")
    if len(value) == 6:
        return tuple(int(value[i:i + 2], 16) for i in (0, 2, 4)) + (alpha,)
    if len(value) == 8:
        return tuple(int(value[i:i + 2], 16) for i in (0, 2, 4, 6))
    raise ThumbError(f"color inválido: {value}")


def resolve(path: str, base: Path) -> Path:
    p = Path(path)
    for candidate in (p, base / p, ROOT / p):
        if candidate.exists():
            return candidate
    raise ThumbError(f"no existe {path}")


def font(name: str, px: int):
    path = FONTS.get(name, name)
    f = ImageFont.truetype(str(resolve(path, ROOT)), px)
    if name == "fredoka":
        try:
            f.set_variation_by_name("Bold")
        except (OSError, ValueError):
            pass
    return f


def substitute(spec, values: dict):
    if isinstance(spec, dict):
        return {k: substitute(v, values) for k, v in spec.items()}
    if isinstance(spec, list):
        return [substitute(v, values) for v in spec]
    if isinstance(spec, str):
        for key, val in values.items():
            spec = spec.replace("{{" + key + "}}", val)
        return spec
    return spec


# Claves cuyo valor es un número (o una lista de números): un "{{you_x}}" ya reemplazado se convierte,
# para mover la flecha o un texto según dónde quedó el avatar en la imagen de IA.
NUMERIC_KEYS = {"x", "y", "size", "height", "width", "curve", "rotate", "max_width", "opacity", "angle",
                "radius", "blur", "darken", "vignette", "from", "to", "center", "offset", "focus"}


def coerce_numbers(spec, key=None):
    if isinstance(spec, dict):
        return {k: coerce_numbers(v, k) for k, v in spec.items()}
    if isinstance(spec, list):
        return [coerce_numbers(v, key) for v in spec]
    if isinstance(spec, str) and key in NUMERIC_KEYS:
        try:
            return float(spec)
        except ValueError:
            raise ThumbError(f"{key} tiene que ser un número: {spec!r}")
    return spec


def adjust_layers(spec: dict, moves=(), hidden=()) -> dict:
    """Mueve u oculta capas por su "id" (--at y --hide), para acomodar los textos a cada imagen."""
    layers = {l.get("id"): l for l in spec.get("layers", []) if l.get("id")}
    for name in list(hidden) + [m.split("=", 1)[0] for m in moves]:
        if name not in layers:
            raise ThumbError(f"no hay una capa con id {name!r} (hay: {', '.join(sorted(layers)) or 'ninguna'})")
    for move in moves:
        name, _, coords = move.partition("=")
        try:
            nums = [float(v) for v in coords.split(",")]
        except ValueError:
            raise ThumbError(f"--at {move}: van números separados por coma")
        layer = layers[name]
        if layer.get("type") == "arrow":
            if len(nums) != 4:
                raise ThumbError(f"--at {move}: una flecha lleva x0,y0,x1,y1")
            layer["from"], layer["to"] = nums[:2], nums[2:]
        else:
            if len(nums) != 2:
                raise ThumbError(f"--at {move}: un texto o imagen lleva x,y")
            layer["x"], layer["y"] = nums
    spec["layers"] = [l for l in spec.get("layers", []) if l.get("id") not in set(hidden)]
    return spec


def final_spec(spec: dict, base_image: str) -> dict:
    """La receta sobre una imagen de IA: esa imagen de fondo, sin rayos ni renders; quedan textos y flechas."""
    final = spec.get("final", {})
    out = {k: v for k, v in spec.items() if k not in ("background", "rays", "layers")}
    out["background"] = {"image": base_image, "focus": final.get("focus", [0.5, 0.5])}
    if final.get("grade"):
        out["background"]["grade"] = final["grade"]
    out["layers"] = [l for l in spec.get("layers", []) if l.get("type") != "image" and l.get("final", True)]
    out["vignette"] = final.get("vignette", spec.get("vignette", 0))
    return out


def gradient(size, colors, angle=90.0):
    """Degradé lineal entre varios colores que cubre toda la imagen; angle 90 = de arriba hacia abajo,
    0 = de izquierda a derecha."""
    w, h = size
    stops = [color(c) for c in colors]
    if len(stops) == 1:
        return Image.new("RGBA", size, stops[0])
    rad = math.radians(angle)
    # Largo de la imagen proyectada sobre la dirección: el degradé va completo de un borde al otro.
    span = max(2, int(math.ceil(abs(w * math.cos(rad)) + abs(h * math.sin(rad)))))
    width = int(math.ceil(math.hypot(w, h))) + 2
    ramp = Image.linear_gradient("L").resize((width, span), Image.BILINEAR)
    ramp = ramp.rotate(90 - angle, resample=Image.BILINEAR, expand=True)
    left, top = (ramp.width - w) // 2, (ramp.height - h) // 2
    ramp = ramp.crop((left, top, left + w, top + h))
    luts = [[], [], [], []]
    for v in range(256):
        t = v / 255 * (len(stops) - 1)
        k = min(int(t), len(stops) - 2)
        f = t - k
        for c in range(4):
            luts[c].append(round(stops[k][c] + (stops[k + 1][c] - stops[k][c]) * f))
    return Image.merge("RGBA", [ramp.point(lut) for lut in luts])


def rays(size, center, count, col, opacity):
    w, h = size
    layer = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    cx, cy = center[0] * w, center[1] * h
    r = math.hypot(w, h)
    rgba = color(col)[:3] + (int(255 * opacity),)
    for i in range(count):
        a0 = 2 * math.pi * i / count
        a1 = a0 + math.pi / count
        draw.polygon([(cx, cy), (cx + r * math.cos(a0), cy + r * math.sin(a0)), (cx + r * math.cos(a1), cy + r * math.sin(a1))], fill=rgba)
    return layer


def vignette(size, strength):
    w, h = size
    mask = Image.new("L", (w // 8, h // 8), 0)
    draw = ImageDraw.Draw(mask)
    draw.ellipse((-w // 40, -h // 40, w // 8 + w // 40, h // 8 + h // 40), fill=255)
    mask = mask.filter(ImageFilter.GaussianBlur(max(w, h) // 60)).resize(size, Image.BILINEAR)
    dark = Image.new("RGBA", size, (0, 0, 0, int(255 * strength)))
    dark.putalpha(ImageChops.invert(mask).point(lambda v: int(v * strength)))
    return dark


def silhouette(alpha: Image.Image, grow: int) -> Image.Image:
    """Agranda la silueta `grow` píxeles (borde o brillo alrededor de un recorte)."""
    if grow <= 0:
        return alpha
    out = alpha
    while grow > 0:
        step = min(grow, 12)
        out = out.filter(ImageFilter.MaxFilter(step * 2 + 1))
        grow -= step
    return out


def composite(canvas: Image.Image, img: Image.Image, left: int, top: int):
    """alpha_composite que admite que la capa se salga del lienzo (la recorta)."""
    src_left, src_top = max(0, -left), max(0, -top)
    dst_left, dst_top = max(0, left), max(0, top)
    width = min(img.width - src_left, canvas.width - dst_left)
    height = min(img.height - src_top, canvas.height - dst_top)
    if width > 0 and height > 0:
        canvas.alpha_composite(img.crop((src_left, src_top, src_left + width, src_top + height)), (dst_left, dst_top))


def place(canvas: Image.Image, img: Image.Image, x: float, y: float, anchor: str = "center", pad: int = 0):
    """Ubica `img` con su ancla ("center", "bottom", "top-left", "bottom-right"...) en (x, y) relativos.
    `pad` es el margen transparente agregado alrededor (brillo, borde): el ancla se mide sin él."""
    parts = anchor.split("-")
    horiz = next((p for p in parts if p in ("left", "right")), "center")
    vert = next((p for p in parts if p in ("top", "bottom")), "center")
    inner_w, inner_h = img.width - 2 * pad, img.height - 2 * pad
    ox = {"left": 0, "center": inner_w / 2, "right": inner_w}[horiz] + pad
    oy = {"top": 0, "center": inner_h / 2, "bottom": inner_h}[vert] + pad
    composite(canvas, img, int(x * canvas.width - ox), int(y * canvas.height - oy))


def image_layer(canvas, layer, base):
    w, h = canvas.size
    img = Image.open(resolve(layer["path"], base)).convert("RGBA")
    if layer.get("crop_alpha", True):
        box = img.getchannel("A").getbbox()
        if box:
            img = img.crop(box)
    if layer.get("flip"):
        img = img.transpose(Image.FLIP_LEFT_RIGHT)
    target_h = layer.get("height")
    target_w = layer.get("width")
    if target_h:
        scale = target_h * h / img.height
    elif target_w:
        scale = target_w * w / img.width
    else:
        scale = 1.0
    img = img.resize((max(1, int(img.width * scale)), max(1, int(img.height * scale))), Image.LANCZOS)
    if layer.get("rotate"):
        img = img.rotate(layer["rotate"], resample=Image.BICUBIC, expand=True)
    pad = int(max(img.size) * 0.15)
    padded = Image.new("RGBA", (img.width + pad * 2, img.height + pad * 2), (0, 0, 0, 0))
    padded.alpha_composite(img, (pad, pad))
    alpha = padded.getchannel("A")
    out = Image.new("RGBA", padded.size, (0, 0, 0, 0))
    if "shadow" in layer:
        sh = layer["shadow"]
        offset = sh.get("offset", [0, 0.02])
        blur = sh.get("blur", 0.02) * max(padded.size)
        shadow = Image.new("RGBA", padded.size, color(sh.get("color", "#00000099")))
        shadow.putalpha(alpha.filter(ImageFilter.GaussianBlur(blur)).point(lambda v: v * color(sh.get("color", "#00000099"))[3] // 255))
        composite(out, shadow, int(offset[0] * padded.width), int(offset[1] * padded.height))
    if "glow" in layer:
        g = layer["glow"]
        radius = int(g.get("radius", 0.05) * max(padded.size))
        glow_alpha = silhouette(alpha, radius // 2).filter(ImageFilter.GaussianBlur(radius / 2))
        glow = Image.new("RGBA", padded.size, color(g.get("color", "#fff27a")))
        glow.putalpha(glow_alpha.point(lambda v: int(v * g.get("opacity", 0.85))))
        out.alpha_composite(glow)
    if "outline" in layer:
        o = layer["outline"]
        width = max(1, int(o.get("width", 0.02) * max(padded.size)))
        ring = Image.new("RGBA", padded.size, color(o.get("color", "#ffffff")))
        ring.putalpha(silhouette(alpha, width))
        out.alpha_composite(ring)
    out.alpha_composite(padded)
    place(canvas, out, layer.get("x", 0.5), layer.get("y", 0.5), layer.get("anchor", "center"), pad)


def text_image(layer, canvas_h):
    px = max(8, int(layer.get("size", 0.1) * canvas_h))
    f = font(layer.get("font", "luckiest-guy"), px)
    text = str(layer["text"])
    stroke = layer.get("stroke", {"color": "#1a1a1a", "width": 0.12})
    stroke_w = int(stroke.get("width", 0.12) * px) if stroke else 0
    left, top, right, bottom = f.getbbox(text, stroke_width=stroke_w)
    pad = stroke_w + px // 4
    size = (right - left + pad * 2, bottom - top + pad * 2)
    origin = (pad - left, pad - top)
    mask = Image.new("L", size, 0)
    ImageDraw.Draw(mask).text(origin, text, font=f, fill=255)
    out = Image.new("RGBA", size, (0, 0, 0, 0))
    if stroke_w:
        smask = Image.new("L", size, 0)
        ImageDraw.Draw(smask).text(origin, text, font=f, fill=255, stroke_width=stroke_w, stroke_fill=255)
        sh = layer.get("shadow", {"offset": [0, 0.08], "color": "#00000088"})
        if sh:
            shadow = Image.new("RGBA", size, color(sh.get("color", "#00000088")))
            shadow.putalpha(smask.point(lambda v: v * color(sh.get("color", "#00000088"))[3] // 255))
            moved = Image.new("RGBA", size, (0, 0, 0, 0))
            composite(moved, shadow, int(sh["offset"][0] * px), int(sh["offset"][1] * px))
            out.alpha_composite(moved)
        stroke_layer = Image.new("RGBA", size, color(stroke.get("color", "#1a1a1a")))
        stroke_layer.putalpha(smask)
        out.alpha_composite(stroke_layer)
    fill = layer.get("fill", "#ffffff")
    if fill == "rainbow" or isinstance(fill, dict):
        colors = RAINBOW if fill == "rainbow" else fill.get("gradient", RAINBOW)
        angle = 0 if fill == "rainbow" else fill.get("angle", 90)
        fill_img = gradient(size, colors, angle)
    else:
        fill_img = Image.new("RGBA", size, color(fill))
    fill_img.putalpha(mask)
    out.alpha_composite(fill_img)
    if layer.get("rotate"):
        out = out.rotate(layer["rotate"], resample=Image.BICUBIC, expand=True)
    return out


def text_layer(canvas, layer):
    if not str(layer.get("text", "")).strip():
        return
    img = text_image(layer, canvas.height)
    max_w = layer.get("max_width")
    if max_w and img.width > max_w * canvas.width:
        k = max_w * canvas.width / img.width
        img = img.resize((int(img.width * k), int(img.height * k)), Image.LANCZOS)
    place(canvas, img, layer.get("x", 0.5), layer.get("y", 0.5), layer.get("anchor", "center"))


def arrow_layer(canvas, layer):
    """Flecha curva gruesa con borde blanco, como las de "YOU!" en las miniaturas de los hits."""
    w, h = canvas.size
    x0, y0 = layer["from"][0] * w, layer["from"][1] * h
    x1, y1 = layer["to"][0] * w, layer["to"][1] * h
    bend = layer.get("curve", 0.25)
    mx, my = (x0 + x1) / 2, (y0 + y1) / 2
    nx, ny = -(y1 - y0), (x1 - x0)
    cx, cy = mx + nx * bend, my + ny * bend
    pts = []
    for i in range(41):
        t = i / 40
        pts.append(((1 - t) ** 2 * x0 + 2 * (1 - t) * t * cx + t * t * x1, (1 - t) ** 2 * y0 + 2 * (1 - t) * t * cy + t * t * y1))
    width = int(layer.get("width", 0.022) * h)
    head = width * 2.4
    ex, ey = pts[-1]
    px, py = pts[-6]
    ang = math.atan2(ey - py, ex - px)
    tip = (ex + math.cos(ang) * head * 0.5, ey + math.sin(ang) * head * 0.5)
    left = (ex + math.cos(ang + 2.4) * head, ey + math.sin(ang + 2.4) * head)
    right = (ex + math.cos(ang - 2.4) * head, ey + math.sin(ang - 2.4) * head)
    layer_img = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer_img)
    outline = layer.get("outline", "#ffffff")
    for col, extra in ((outline, int(width * 0.45)), (layer.get("color", "#ff2a2a"), 0)):
        if col is None:
            continue
        rgba = color(col)
        draw.line(pts[:-3], fill=rgba, width=width + extra * 2, joint="curve")
        for p in (pts[0],):
            r = (width + extra * 2) / 2
            draw.ellipse((p[0] - r, p[1] - r, p[0] + r, p[1] + r), fill=rgba)
        grow = extra * 1.2
        draw.polygon([(tip[0] + math.cos(ang) * grow, tip[1] + math.sin(ang) * grow),
                      (left[0] + math.cos(ang + 2.4) * grow, left[1] + math.sin(ang + 2.4) * grow),
                      (right[0] + math.cos(ang - 2.4) * grow, right[1] + math.sin(ang - 2.4) * grow)], fill=rgba)
    canvas.alpha_composite(layer_img)


def compose(spec: dict, base: Path) -> Image.Image:
    kind = spec.get("kind", "thumbnail")
    size = tuple(spec.get("size") or KINDS.get(kind, KINDS["thumbnail"])["size"])
    bg = spec.get("background", {"gradient": ["#4fd1ff", "#1f6bff"]})
    if "image" in bg:
        canvas = Image.open(resolve(bg["image"], base)).convert("RGBA")
        ratio = max(size[0] / canvas.width, size[1] / canvas.height)
        canvas = canvas.resize((math.ceil(canvas.width * ratio), math.ceil(canvas.height * ratio)), Image.LANCZOS)
        if ratio > 1:
            # Agrandar ablanda los bordes (salidas de IA de 1K): se recupera nitidez.
            canvas = canvas.filter(ImageFilter.UnsharpMask(radius=2, percent=60, threshold=2))
        fx, fy = bg.get("focus", [0.5, 0.5])
        left = round((canvas.width - size[0]) * min(1, max(0, fx)))
        top = round((canvas.height - size[1]) * min(1, max(0, fy)))
        canvas = canvas.crop((left, top, left + size[0], top + size[1]))
        grade = bg.get("grade")
        if grade:
            alpha = canvas.getchannel("A")
            rgb = canvas.convert("RGB")
            rgb = ImageEnhance.Color(rgb).enhance(grade.get("saturation", 1.0))
            rgb = ImageEnhance.Contrast(rgb).enhance(grade.get("contrast", 1.0))
            canvas = rgb.convert("RGBA")
            canvas.putalpha(alpha)
        if bg.get("blur"):
            canvas = canvas.filter(ImageFilter.GaussianBlur(bg["blur"] * size[1] / 1080))
        if bg.get("darken"):
            canvas.alpha_composite(Image.new("RGBA", size, (0, 0, 0, int(255 * bg["darken"]))))
    else:
        canvas = gradient(size, bg.get("gradient", ["#4fd1ff", "#1f6bff"]), bg.get("angle", 90))
    if "rays" in spec:
        r = spec["rays"]
        canvas.alpha_composite(rays(size, r.get("center", [0.5, 0.5]), r.get("count", 16), r.get("color", "#ffffff"), r.get("opacity", 0.12)))
    for layer in spec.get("layers", []):
        kind_l = layer.get("type")
        if kind_l == "image":
            image_layer(canvas, layer, base)
        elif kind_l == "text":
            text_layer(canvas, layer)
        elif kind_l == "arrow":
            arrow_layer(canvas, layer)
        else:
            raise ThumbError(f"capa desconocida: {kind_l}")
    if spec.get("vignette"):
        canvas.alpha_composite(vignette(size, spec["vignette"]))
    return canvas


def metrics(img: Image.Image) -> dict:
    small = img.convert("RGB").resize((192, int(192 * img.height / img.width)))
    hsv = small.convert("HSV")
    sat = ImageStat.Stat(hsv.getchannel("S")).mean[0]
    lum = ImageStat.Stat(small.convert("L")).stddev[0]
    return {"saturation": round(sat), "contrast": round(lum)}


def check(path: Path, kind: str, previews: Path = None) -> list:
    """Devuelve avisos (vacío = todo bien) y opcionalmente guarda las vistas previas."""
    rules = KINDS[kind]
    warnings = []
    img = Image.open(path)
    w, h = img.size
    if abs(w / h - rules["ratio"]) > 0.01:
        warnings.append(f"proporción {w}x{h}: tiene que ser {'16:9' if rules['ratio'] > 1 else 'cuadrada'} (Roblox estira o recorta)")
    ideal = rules["size"]
    if w < ideal[0] or h < ideal[1]:
        warnings.append(f"tamaño {w}x{h}: menor al ideal {ideal[0]}x{ideal[1]}")
    if rules["max_bytes"] and path.stat().st_size > rules["max_bytes"]:
        warnings.append(f"pesa {path.stat().st_size // 1024} KB: Home acepta hasta 3 MB (guardar como JPG de calidad 90)")
    m = metrics(img)
    look = HIT_LOOK[kind]
    if m["saturation"] < look["saturation"][1]:
        warnings.append(f"saturación {m['saturation']}: más apagada que 3 de cada 4 hits (mediana {look['saturation'][0]})")
    if m["contrast"] < look["contrast"][1]:
        warnings.append(f"contraste {m['contrast']}: más plana que 3 de cada 4 hits (mediana {look['contrast'][0]}); separar sujeto y fondo")
    if previews:
        previews.mkdir(parents=True, exist_ok=True)
        stem = path.stem
        rgb = img.convert("RGB")
        if kind == "icon":
            for s in (150, 100):
                rgb.resize((s, s), Image.LANCZOS).save(previews / f"{stem}_{s}px.png")
        else:
            tile = rgb.resize((384, 216), Image.LANCZOS)
            mock = tile.copy()
            if rules["safe_bottom"]:
                band = Image.new("RGBA", (384, int(216 * rules["safe_bottom"])), (0, 0, 0, 150))
                mock = mock.convert("RGBA")
                mock.alpha_composite(band, (0, 216 - band.height))
                ImageDraw.Draw(mock).text((8, 216 - band.height + 8), "123K playing  92%", fill=(255, 255, 255, 255))
            mock.convert("RGB").save(previews / f"{stem}_home_tile.png")
            rgb.resize((240, 135), Image.LANCZOS).save(previews / f"{stem}_small.png")
    return warnings


def sheet(paths, out: Path, cols: int = 3, cell_w: int = 640):
    imgs = [Image.open(p).convert("RGB") for p in paths]
    cell_h = int(cell_w * max(i.height / i.width for i in imgs))
    rows = math.ceil(len(imgs) / cols)
    pad = 16
    canvas = Image.new("RGB", (cols * (cell_w + pad) + pad, rows * (cell_h + pad + 28) + pad), (24, 24, 28))
    draw = ImageDraw.Draw(canvas)
    for i, (p, img) in enumerate(zip(paths, imgs)):
        k = min(cell_w / img.width, cell_h / img.height)
        thumb = img.resize((int(img.width * k), int(img.height * k)), Image.LANCZOS)
        x = pad + (i % cols) * (cell_w + pad)
        y = pad + (i // cols) * (cell_h + pad + 28)
        canvas.paste(thumb, (x, y))
        draw.text((x, y + cell_h + 6), Path(p).name, fill=(230, 230, 230))
    out.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(out, quality=90)


def save(img: Image.Image, out: Path, kind: str):
    out.parent.mkdir(parents=True, exist_ok=True)
    if out.suffix.lower() in (".jpg", ".jpeg"):
        img.convert("RGB").save(out, quality=90, optimize=True)
    else:
        img.save(out, optimize=True)
    rules = KINDS.get(kind, KINDS["thumbnail"])
    if rules["max_bytes"] and out.stat().st_size > rules["max_bytes"] and out.suffix.lower() == ".png":
        jpg = out.with_suffix(".jpg")
        img.convert("RGB").save(jpg, quality=90, optimize=True)
        print(f"  {out.name} pasa de 3 MB: también se guardó {jpg.name} para subir a Home")


def cmd_compose(args) -> int:
    spec_path = Path(args.spec)
    spec = json.loads(spec_path.read_text(encoding="utf-8"))
    values = dict(spec.get("_defaults", {}))
    values.update(dict(v.split("=", 1) for v in args.set or []))
    if getattr(args, "base", None):
        spec = final_spec(spec, str(Path(args.base).resolve()))
    spec = {k: v for k, v in spec.items() if k not in ("ia", "final") and not k.startswith("_")}
    spec = substitute(spec, values)
    missing = sorted(set(part.split("}}")[0] for part in json.dumps(spec).split("{{")[1:]))
    if missing:
        print(f"Faltan valores: {', '.join(missing)} (usar --set clave=valor)", file=sys.stderr)
        return 2
    try:
        spec = adjust_layers(coerce_numbers(spec), getattr(args, "at", None) or [], getattr(args, "hide", None) or [])
        img = compose(spec, spec_path.parent)
    except (ThumbError, OSError) as e:
        print(e, file=sys.stderr)
        return 1
    kind = spec.get("kind", "thumbnail")
    if kind not in KINDS:
        print(f"kind inválido: {kind} (thumbnail, icon o ad)", file=sys.stderr)
        return 2
    out = Path(args.out or spec.get("out") or spec_path.with_suffix(".png").name)
    save(img, out, kind)
    print(f"  [ok] {out} ({img.width}x{img.height})")
    for w in check(out, kind):
        print(f"  [aviso] {w}")
    return 0


def cmd_check(args) -> int:
    warnings = check(Path(args.image), args.kind, Path(args.previews) if args.previews else None)
    m = metrics(Image.open(args.image))
    look = HIT_LOOK[args.kind]
    print(f"  saturación {m['saturation']} · contraste {m['contrast']} "
          f"(medianas de los hits: {look['saturation'][0]} · {look['contrast'][0]})")
    for w in warnings:
        print(f"  [aviso] {w}")
    if not warnings:
        print("  [ok] cumple tamaño, peso y proporción")
    return 1 if warnings else 0


def selftest() -> int:
    import tempfile

    assert color("#ff0000") == (255, 0, 0, 255) and color("#00ff0080") == (0, 255, 0, 128)
    assert substitute({"a": ["{{x}}/b"]}, {"x": "z"}) == {"a": ["z/b"]}
    with tempfile.TemporaryDirectory() as tmp:
        tmp = Path(tmp)
        hero = Image.new("RGBA", (300, 300), (0, 0, 0, 0))
        ImageDraw.Draw(hero).ellipse((40, 20, 260, 290), fill=(255, 220, 60, 255))
        hero.save(tmp / "hero.png")
        spec = {
            "kind": "thumbnail",
            "background": {"gradient": ["#4fd1ff", "#1f6bff"]},
            "rays": {"center": [0.7, 0.45], "count": 14, "opacity": 0.15},
            "layers": [
                {"type": "image", "path": "{{hero}}", "x": 0.7, "y": 0.5, "height": 0.7,
                 "glow": {"color": "#fff27a", "radius": 0.06}, "outline": {"color": "#ffffff", "width": 0.02},
                 "shadow": {"offset": [0, 0.03]}},
                {"type": "text", "text": "$1,000,000/s", "font": "titan-one", "size": 0.13, "x": 0.5, "y": 0.12, "fill": "#7dff4f"},
                {"type": "text", "text": "SECRET", "font": "luckiest-guy", "size": 0.08, "x": 0.3, "y": 0.4, "fill": "rainbow"},
                {"type": "arrow", "from": [0.45, 0.6], "to": [0.6, 0.5]},
            ],
            "vignette": 0.25,
        }
        (tmp / "r.json").write_text(json.dumps(spec), encoding="utf-8")
        args = argparse.Namespace(spec=str(tmp / "r.json"), out=str(tmp / "out.png"), set=[f"hero={tmp / 'hero.png'}"], base=None)
        assert cmd_compose(args) == 0
        out = Image.open(tmp / "out.png")
        assert out.size == (1920, 1080), out.size
        # El centro del sujeto quedó amarillo y el título tiene relleno verde.
        r, g, b = out.convert("RGB").getpixel((int(0.7 * 1920), int(0.5 * 1080)))
        assert r > 200 and g > 180 and b < 140, (r, g, b)
        check(tmp / "out.png", "thumbnail", tmp / "prev")
        assert (tmp / "prev" / "out_home_tile.png").exists()
        icon = compose({"kind": "icon", "background": {"gradient": ["#ff7ad9", "#7a3cff"]}, "layers": []}, tmp)
        assert icon.size == (512, 512)
        icon.save(tmp / "icon.png")
        warns = check(tmp / "icon.png", "icon", tmp / "prev")
        assert (tmp / "prev" / "icon_150px.png").exists(), warns
        bad = Image.new("RGB", (800, 800), (120, 120, 120))
        bad.save(tmp / "bad.png")
        warns = check(tmp / "bad.png", "thumbnail")
        assert any("proporción" in w for w in warns) and any("saturación" in w for w in warns), warns
        sheet([tmp / "out.png", tmp / "icon.png"], tmp / "sheet.jpg", cols=2, cell_w=200)
        assert (tmp / "sheet.jpg").exists()
        # Final sobre imagen de IA: fondo recortado a 16:9 desde el foco, sin renders (no pide {{hero}})
        # y la flecha ubicada con un valor numérico por --set.
        ia = Image.new("RGB", (1200, 900), (30, 160, 60))
        ImageDraw.Draw(ia).rectangle((0, 0, 1200, 300), fill=(250, 40, 40))
        ia.save(tmp / "ia.png")
        spec["_defaults"] = {"you_x": "0.5"}
        spec["final"] = {"focus": [0.5, 0.0], "grade": {"saturation": 1.1, "contrast": 1.05}}
        spec["layers"][-1] = {"type": "arrow", "id": "you", "from": [0.2, 0.6], "to": ["{{you_x}}", 0.5]}
        spec["layers"][2]["id"] = "rarity"
        spec["ia"] = {"aspect": "16:9", "prompt": "{{scene}}"}
        (tmp / "r.json").write_text(json.dumps(spec), encoding="utf-8")
        args = argparse.Namespace(spec=str(tmp / "r.json"), out=str(tmp / "final.png"), set=["you_x=0.66"],
                                  base=str(tmp / "ia.png"), at=["you=0.1,0.1,0.2,0.2"], hide=["rarity"])
        assert cmd_compose(args) == 0
        args.at = ["nope=0.1,0.1"]
        assert cmd_compose(args) == 1
        args.at = ["you=0.1,0.1"]
        assert cmd_compose(args) == 1
        args.at = ["you=0.1,0.1,0.2,0.2"]
        assert cmd_compose(args) == 0
        final = Image.open(tmp / "final.png").convert("RGB")
        assert final.size == (1920, 1080), final.size
        r, g, b = final.getpixel((40, 40))
        assert r > 200 and g < 80, (r, g, b)  # foco arriba: la franja roja quedó en el borde superior
        r, g, b = final.getpixel((int(0.7 * 1920), int(0.5 * 1080)))
        assert g > r, (r, g, b)  # sin el render amarillo del boceto
        try:
            coerce_numbers({"x": "abc"})
            raise AssertionError("tenía que fallar")
        except ThumbError:
            pass
    print("selftest OK")
    return 0


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    sub = parser.add_subparsers(dest="cmd", required=True)
    c = sub.add_parser("compose")
    c.add_argument("spec")
    c.add_argument("--out")
    c.add_argument("--set", action="append", help="clave=valor para {{clave}} en la receta")
    c.add_argument("--base", help="imagen de IA (tools/imagegen.py) como fondo: solo se agregan textos y flechas")
    c.add_argument("--at", action="append", help="id=x,y (texto) o id=x0,y0,x1,y1 (flecha): mueve esa capa")
    c.add_argument("--hide", action="append", help="id de una capa que no va")
    k = sub.add_parser("check")
    k.add_argument("image")
    k.add_argument("--kind", choices=sorted(KINDS), default="thumbnail")
    k.add_argument("--previews")
    s = sub.add_parser("sheet")
    s.add_argument("images", nargs="+")
    s.add_argument("--out", required=True)
    s.add_argument("--cols", type=int, default=3)
    sub.add_parser("selftest")
    args = parser.parse_args(argv)
    if args.cmd == "compose":
        return cmd_compose(args)
    if args.cmd == "check":
        return cmd_check(args)
    if args.cmd == "sheet":
        sheet(args.images, Path(args.out), args.cols)
        print(f"  [ok] {args.out}")
        return 0
    return selftest()


if __name__ == "__main__":
    sys.exit(main())
