#!/usr/bin/env python3
"""Referencias por nombre que los tipos de Luau no ven, y rutas citadas en la documentación.

Un evento, remote, sonido o ícono se nombra con un texto ("Kit:Rolled", "BuyRod", "Legendary"): si un
lado cambia y el otro no, luau-lsp no se entera y el juego falla callado en Studio (un aviso que no
llega, un sonido mudo, un ícono que muestra "money_boost"). Lo corre tools/check.py en la plantilla y en
cada juego:

- KitFx: cada evento que manda el servidor tiene quien lo escuche en el cliente (Bus.on("Kit:X")), y al
  revés.
- Remotes: lo que el cliente pide existe en el servidor, y cada remote del servidor lo usa el cliente
  (uno sin uso es superficie de ataque sin motivo).
- Bus: cada Bus.call/Bus.has tiene su Bus.handle, y cada Bus.on su Bus.emit.
- Sonidos, voces y música: cada nombre está en AudioConfig.
- Íconos: cada nombre de ícono escrito en el código o la configuración tiene emoji de respaldo
  (Icons.luau o `iconFallbacks` de la receta), para que la UI no muestre el nombre en el primer playtest.

Y en los .md: cada ruta del repo citada entre comillas invertidas existe.

    python tools/xref.py template        # una carpeta de juego o la plantilla
    python tools/xref.py docs            # rutas citadas en la documentación
    python tools/xref.py selftest
"""
import re
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SKIP_DIRS = {".git", ".cache", ".claude", "node_modules", ".preview"}

LONG_COMMENT = re.compile(r"--\[(=*)\[.*?\]\1\]", re.S)
STRING = re.compile(r'"(?:[^"\\\n]|\\.)*"')


def strip_line(line: str) -> str:
    """La línea sin su comentario `--`, salvo que el `--` esté dentro de un texto."""
    quote = None
    i = 0
    while i < len(line):
        c = line[i]
        if quote:
            if c == "\\":
                i += 1
            elif c == quote:
                quote = None
        elif c in "\"'`":
            quote = c
        elif line.startswith("--", i):
            return line[:i]
        i += 1
    return line


def code_of(text: str) -> str:
    """El código sin comentarios."""
    return "\n".join(strip_line(line) for line in LONG_COMMENT.sub("", text).splitlines())


def table_keys(text: str, name: str) -> set:
    """Claves de primer nivel de `NAME = { ... }` en un módulo de configuración."""
    start = re.search(rf"\b{name}\s*(?::[^=\n]*)?=\s*\{{", text)
    if not start:
        return set()
    depth, i = 1, start.end()
    body_start = i
    while i < len(text) and depth:
        if text[i] == "{":
            depth += 1
        elif text[i] == "}":
            depth -= 1
        i += 1
    body = text[body_start:i - 1]
    keys, depth = set(), 0
    for line in body.splitlines():
        if depth == 0:
            m = re.match(r"\s*([A-Za-z_]\w*)\s*=", line)
            if m:
                keys.add(m.group(1))
        depth += line.count("{") - line.count("}")
    return keys


class Project:
    def __init__(self, base: Path):
        self.base = base
        self.code = {}
        for path in sorted((base / "src").rglob("*.luau")):
            self.code[path.relative_to(base).as_posix()] = code_of(path.read_text(encoding="utf-8"))

    def find(self, pattern: str, prefix: str = "") -> dict:
        rx = re.compile(pattern)
        out: dict = {}
        for rel, text in self.code.items():
            if rel.startswith(prefix):
                for m in rx.finditer(text):
                    out.setdefault(m.group(1), set()).add(rel)
        return out

    def literals(self, prefix: str = "") -> set:
        out = set()
        for rel, text in self.code.items():
            if rel.startswith(prefix):
                out.update(s[1:-1] for s in STRING.findall(text))
        return out


def where(files: set) -> str:
    return ", ".join(sorted(files)[:3]) + ("…" if len(files) > 3 else "")


def check_project(base: Path) -> list:
    p = Project(base)
    errors = []
    server, client, shared = "src/server", "src/client", "src/shared"

    # KitFx: servidor → cliente.
    sent = p.find(r'KitFx\.send\(\s*[^,()]+(?:\([^()]*\))?\s*,\s*"(\w+)"', server)
    for name, files in p.find(r'KitFx\.all\(\s*"(\w+)"', server).items():
        sent.setdefault(name, set()).update(files)
    heard = p.find(r'Bus\.on\(\s*"Kit:(\w+)"', client)
    for name, files in sorted(sent.items()):
        if name not in heard:
            errors.append(f"KitFx \"{name}\" ({where(files)}): ningún Bus.on(\"Kit:{name}\") en el cliente; el momento no se ve ni se oye")
    server_text = p.literals(server)
    for name, files in sorted(heard.items()):
        if name not in sent and name not in server_text:
            errors.append(f"Bus.on(\"Kit:{name}\") ({where(files)}): el servidor nunca manda \"{name}\" por KitFx")

    # Remotes.
    created = p.find(r'Remotes\.(?:onEvent|onInvoke|toClient)\(\s*"(\w+)"', server)
    client_text = p.literals(client) | p.literals(shared)
    for name, files in sorted(created.items()):
        if name not in client_text:
            errors.append(f"remote \"{name}\" ({where(files)}): el cliente no lo usa; sacarlo o darle su pantalla")
    asked = p.find(r'(?:Net\.(?:event|func)|\binvoke|\bfire)\(\s*"(\w+)"', client)
    for name, files in sorted(asked.items()):
        if name not in created:
            errors.append(f"remote \"{name}\" ({where(files)}): el servidor no lo crea (Remotes.onEvent/onInvoke/toClient)")

    # Bus.
    handled = p.find(r'Bus\.handle\(\s*"(\w+)"', client)
    for name, files in sorted(p.find(r'Bus\.(?:call|has)\(\s*"(\w+)"', client).items()):
        if name not in handled:
            errors.append(f"Bus.call(\"{name}\") ({where(files)}): nadie hace Bus.handle(\"{name}\")")
    emitted = p.find(r'Bus\.emit\(\s*"(\w+)"', client)
    for name, files in sorted(p.find(r'Bus\.on\(\s*"(\w+)"', client).items()):
        if name not in emitted:
            errors.append(f"Bus.on(\"{name}\") ({where(files)}): nadie hace Bus.emit(\"{name}\")")

    # Sonidos, voces y música.
    audio_path = base / "src/shared/Config/AudioConfig.luau"
    if audio_path.exists():
        audio = audio_path.read_text(encoding="utf-8")
        sounds, voices, music = table_keys(audio, "SOUNDS"), table_keys(audio, "VOICES"), table_keys(audio, "MUSIC")
        used = p.find(r'Sound\.play\(\s*"(\w+)"')
        for name, files in p.find(r'\bsound\s*=\s*"(\w+)"').items():
            used.setdefault(name, set()).update(files)
        for rel, text in p.code.items():
            for block in re.findall(r"Sound\.preload\(\s*\{([^}]*)\}", text):
                for name in re.findall(r'"(\w+)"', block):
                    used.setdefault(name, set()).add(rel)
        for name, files in sorted(used.items()):
            if name not in sounds:
                errors.append(f"sonido \"{name}\" ({where(files)}): no está en AudioConfig.SOUNDS")
        for name, files in sorted(p.find(r'Sound\.voice\(\s*"(\w+)"').items()):
            if name not in voices:
                errors.append(f"voz \"{name}\" ({where(files)}): no está en AudioConfig.VOICES")
        for name, files in sorted(p.find(r'Sound\.playMusic\(\s*"(\w+)"').items()):
            if name not in music:
                errors.append(f"música \"{name}\" ({where(files)}): no está en AudioConfig.MUSIC")

    # Íconos con respaldo.
    icons_path = base / "src/shared/Icons.luau"
    if icons_path.exists():
        fallback = table_keys(icons_path.read_text(encoding="utf-8"), "EMOJI")
        recipe = base / "src/shared/Config/KitConfig.luau"
        if recipe.exists():
            fallback |= table_keys(recipe.read_text(encoding="utf-8"), "iconFallbacks")
        used = p.find(r'\bicon\s*=\s*"(\w+)"')
        for name, files in p.find(r'Icons\.(?:resolve|flat|hasImage)\(\s*"(\w+)"').items():
            used.setdefault(name, set()).update(files)
        for name, files in sorted(used.items()):
            if name not in fallback:
                errors.append(f"ícono \"{name}\" ({where(files)}): sin emoji de respaldo en Icons.luau ni en iconFallbacks; la UI mostraría el nombre")
    return errors


# Documentación ------------------------------------------------------------------------------------

EXTENSIONS = (".md", ".luau", ".py", ".json", ".cjs", ".js", ".ps1", ".jpg", ".jpeg", ".png", ".webp", ".yml",
              ".yaml", ".toml", ".mp3", ".ogg", ".glb", ".fbx", ".html", ".txt", ".csv")
TICKED = re.compile(r"`([^`\s]+)`")


def md_files():
    for path in sorted(ROOT.rglob("*.md")):
        if not SKIP_DIRS.intersection(path.relative_to(ROOT).parts):
            yield path


def candidates(md: Path, ref: str):
    ref = ref.split("#", 1)[0].split(":", 1)[0] if not ref.startswith("http") else ref
    yield md.parent / ref
    yield ROOT / ref
    # Dentro de un skill, las rutas son del skill (references/, scripts/).
    parts = md.relative_to(ROOT).parts
    if len(parts) > 2 and parts[0] == "skills":
        yield ROOT / parts[0] / parts[1] / ref
    # Dentro de un juego o de la plantilla, las rutas del juego ("src/...", "docs/...").
    if len(parts) > 2 and parts[0] == "games":
        yield ROOT / parts[0] / parts[1] / ref
    for base in ("template", "template/src", "template/src/shared", "template/src/server", "template/src/client",
                 "template/src/shared/Kits", "template/src/client/Kits"):
        yield ROOT / base / ref


# Rutas que no son del repo: las salidas de cada juego (docs/ de un juego), la documentación oficial de
# Roblox (creator-docs) y ejemplos ("tools/x.py", "AAAA-MM-DD").
NOT_REPO = ("docs/", "content/en-us/", "production/", "cloud/", "reference/", "en-us/")
EXAMPLE = re.compile(r"(^|/)(x|X)(\.|$)|AAAA|<|>")


def repo_index() -> set:
    out = set()
    for path in ROOT.rglob("*"):
        rel = path.relative_to(ROOT)
        if not SKIP_DIRS.intersection(rel.parts):
            out.add(rel.as_posix())
    return out


# `Modulo.miembro` o `Modulo:metodo(...)`; "Merge:Lucky" sin paréntesis es un premio, no un método.
API = re.compile(r"`([A-Z]\w*)(?:\.([A-Za-z_]\w*)|:([A-Za-z_]\w*)\()[^`]*`")


def luau_modules() -> dict:
    """Nombre de módulo → textos de los .luau con ese nombre (la plantilla y los scripts de los skills)."""
    out: dict = {}
    for base in (ROOT / "template/src", ROOT / "skills"):
        for path in base.rglob("*.luau"):
            name = path.name.split(".")[0]
            out.setdefault(name, []).append(path.read_text(encoding="utf-8"))
    return out


def has_member(texts: list, module: str, member: str) -> bool:
    patterns = (rf"\bfunction\s+{module}[.:]{member}\b", rf"\b{module}\.{member}\s*=", rf"(?m)^\s*{member}\s*[=:]",
                rf"\bexport\s+type\s+{member}\b", rf"(?m)^\s*local\s+function\s+{member}\b")
    return any(re.search(pattern, text) for text in texts for pattern in patterns)


def check_docs() -> list:
    errors = []
    index = repo_index()
    modules = luau_modules()
    for md in md_files():
        rel = md.relative_to(ROOT).as_posix()
        text = md.read_text(encoding="utf-8")
        for number, line in enumerate(text.splitlines(), 1):
            for module, dotted, method in API.findall(line):
                member = dotted or method
                # Nombres de archivo ("DataService.luau", "Main.client", "KitCheck.spec") y prefijos ("UiText.ERR_").
                if member in ("luau", "server", "client", "spec", "md", "json") or member.endswith("_"):
                    continue
                texts = modules.get(module)
                if texts and not has_member(texts, module, member):
                    errors.append(f"{rel}:{number}: `{module}.{member}` no existe en {module}.luau")
            for ref in TICKED.findall(line):
                if ("/" not in ref or not ref.lower().endswith(EXTENSIONS) or ref.startswith(("http", "~", "%", "$"))
                        or any(c in ref for c in "<>*{}|…") or ref.startswith(("C:", "/"))):
                    continue
                if ref.startswith(NOT_REPO) or EXAMPLE.search(ref):
                    continue
                if any(c.exists() for c in candidates(md, ref)):
                    continue
                # Forma corta de una ruta que existe ("hud-hits/muestra-kit.jpg", "references/bloques.md").
                if any(path.endswith("/" + ref) for path in index):
                    continue
                errors.append(f"{rel}:{number}: `{ref}` no existe")
    return errors


# Autotest -------------------------------------------------------------------------------------------

def selftest() -> int:
    with tempfile.TemporaryDirectory() as tmp:
        base = Path(tmp)
        (base / "src/server").mkdir(parents=True)
        (base / "src/client").mkdir(parents=True)
        (base / "src/shared/Config").mkdir(parents=True)
        (base / "src/shared/Config/AudioConfig.luau").write_text(
            "return {\n\tSOUNDS = {\n\t\tClick = { id = 1 },\n\t\tCoin = { id = 2, pitch = { 1, 2 } },\n\t} :: any,\n"
            "\tVOICES = {\n\t\tLegendary = \"legendary\",\n\t},\n\tMUSIC = {\n\t\tLobby = { \"a\" },\n\t},\n}\n")
        (base / "src/shared/Icons.luau").write_text("local EMOJI: { [string]: string } = {\n\tcoins = \"🪙\",\n}\n")
        (base / "src/server/A.luau").write_text(
            'KitFx.send(player, "Rolled", {})\nKitFx.send(p, "Lost")\n'
            'Remotes.onInvoke("BuyRod", spec, f)\nRemotes.onEvent("Dead", spec, f)\n'
            '-- KitFx.send(player, "Commented")\nlocal s = "texto -- no es comentario"\n')
        (base / "src/client/B.luau").write_text(
            'Bus.on("Kit:Rolled", f)\nBus.on("Kit:Ghost", f)\ninvoke("BuyRod")\nfire("Nope")\n'
            'Bus.call("OpenShop")\nBus.handle("OpenIndex", f)\nBus.on("Ping", f)\n'
            'Sound.play("Click")\nSound.play("Boom")\nSound.voice("Legendary")\nSound.voice("Epic")\n'
            'Sound.playMusic("Lobby")\nlocal x = { icon = "coins" }\nlocal y = { icon = "nope_icon" }\n')
        errors = "\n".join(check_project(base))
        expect = ['"Lost"', '"Kit:Ghost"', 'remote "Dead"', 'remote "Nope"', 'Bus.call("OpenShop")',
                  'Bus.on("Ping")', 'sonido "Boom"', 'voz "Epic"', 'ícono "nope_icon"']
        for fragment in expect:
            assert fragment in errors, (fragment, errors)
        for fragment in ['"Rolled"', '"BuyRod"', '"Commented"', 'sonido "Click"', 'ícono "coins"', 'música']:
            assert fragment not in errors, (fragment, errors)
        assert len(errors.splitlines()) == len(expect), errors
    assert code_of('local a = "x -- y" -- comentario') == 'local a = "x -- y" ', code_of('local a = "x -- y" -- comentario')
    assert table_keys("X = {\n\tA = 1,\n\tB = { C = 2 },\n} :: any", "X") == {"A", "B"}
    print("selftest OK")
    return 0


def main() -> int:
    sys.stdout.reconfigure(encoding="utf-8")
    if len(sys.argv) != 2:
        print(__doc__)
        return 2
    arg = sys.argv[1]
    if arg == "selftest":
        return selftest()
    errors = check_docs() if arg == "docs" else check_project((ROOT / arg).resolve())
    for error in errors:
        print("  " + error)
    print(f"{len(errors)} problema(s)")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
