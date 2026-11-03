#!/usr/bin/env python3
"""Pasa a un juego (games/<juego>) las mejoras del núcleo de la plantilla.

Cada juego es una copia de template/ y no recibe solo lo que mejora después. Esta herramienta compara
template/src y template/tests con los del juego y:
- copia los archivos del núcleo nuevos o cambiados (todo menos src/shared/Config/);
- nunca toca la configuración del juego (src/shared/Config/: receta, precios, textos); la lista y,
  para UiText, dice qué claves nuevas de la plantilla le faltan al juego, para agregarlas a mano;
- borra los archivos del núcleo que la plantilla borró (lo sabe por el historial de git); los demás
  archivos que la plantilla no tiene son del juego y no se tocan;
- respeta los archivos del núcleo que el juego hizo propios a propósito: una ruta o patrón por línea en
  games/<juego>/sync-ignore.txt (por ejemplo `src/client/Controllers/HudController.luau`); nunca se copian.

    python tools/sync_template.py games/prueba            # qué cambiaría
    python tools/sync_template.py games/prueba --diff     # y qué cambió en la configuración, para pasarlo a mano
    python tools/sync_template.py games/prueba --apply    # aplicarlo
    python tools/sync_template.py selftest

Después: `python tools/check.py` y probar en Studio.
"""
import argparse
import difflib
import filecmp
import fnmatch
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PARTS = ("src", "tests")
CONFIG = Path("src/shared/Config")
KEY = re.compile(r"^\s*([A-Z][A-Z0-9_]*)\s*=", re.M)
IGNORE = "sync-ignore.txt"


def files(base: Path) -> set:
    out = set()
    for part in PARTS:
        folder = base / part
        if folder.is_dir():
            out.update(p.relative_to(base) for p in folder.rglob("*") if p.is_file())
    return out


RECIPE = CONFIG / "KitConfig.luau"  # la receta: siempre distinta, es el juego


def is_config(rel: Path) -> bool:
    return CONFIG in rel.parents


def ignored(game: Path) -> list:
    path = game / IGNORE
    if not path.exists():
        return []
    lines = (line.split("#", 1)[0].strip() for line in path.read_text(encoding="utf-8").splitlines())
    return [line for line in lines if line]


def in_template_history(rel: Path) -> bool:
    """¿La plantilla tuvo alguna vez ese archivo? (historial de git de template/)."""
    try:
        out = subprocess.run(["git", "log", "--format=%h", "-1", "--", f"template/{rel.as_posix()}"], cwd=ROOT,
                             capture_output=True, text=True, timeout=30)
    except (OSError, subprocess.SubprocessError):
        return False
    return out.returncode == 0 and out.stdout.strip() != ""


def plan(template: Path, game: Path, was_in_template=in_template_history) -> dict:
    t, g = files(template), files(game)
    patterns = ignored(game)
    result = {"add": [], "update": [], "config": [], "extra": [], "removed": [], "uitext": [], "own": []}
    for rel in sorted(t):
        if rel == RECIPE:
            continue
        if any(fnmatch.fnmatch(rel.as_posix(), pattern) for pattern in patterns):
            if rel not in g or not filecmp.cmp(template / rel, game / rel, shallow=False):
                result["own"].append(rel)
        elif rel not in g:
            (result["config"] if is_config(rel) else result["add"]).append(rel)
        elif not filecmp.cmp(template / rel, game / rel, shallow=False):
            (result["config"] if is_config(rel) else result["update"]).append(rel)
    for rel in sorted(g - t):
        if is_config(rel) or any(fnmatch.fnmatch(rel.as_posix(), pattern) for pattern in patterns):
            continue
        (result["removed"] if was_in_template(rel) else result["extra"]).append(rel)
    ui = CONFIG / "UiText.luau"
    if (template / ui).exists() and (game / ui).exists():
        have = set(KEY.findall((game / ui).read_text(encoding="utf-8")))
        result["uitext"] = [k for k in KEY.findall((template / ui).read_text(encoding="utf-8")) if k not in have]
    return result


def apply(template: Path, game: Path, result: dict) -> None:
    for rel in result["add"] + result["update"]:
        (game / rel).parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(template / rel, game / rel)
    for rel in result["removed"]:
        (game / rel).unlink()


def diffs(template: Path, game: Path, result: dict) -> None:
    """Lo que cambió en la configuración de la plantilla, para pasarlo a mano a la del juego."""
    for rel in result["config"]:
        new = (template / rel).read_text(encoding="utf-8").splitlines()
        old = (game / rel).read_text(encoding="utf-8").splitlines() if (game / rel).exists() else []
        print(f"--- {rel} (juego) / +++ plantilla")
        for line in difflib.unified_diff(old, new, "juego", "plantilla", lineterm="", n=1):
            print("  " + line)


def report(result: dict, applied: bool) -> None:
    verb = "copiado" if applied else "se copiaría"
    for rel in result["add"]:
        print(f"  [nuevo] {rel} ({verb})")
    for rel in result["update"]:
        print(f"  [cambió] {rel} ({verb})")
    for rel in result["config"]:
        print(f"  [config] {rel}: distinto en la plantilla; revisarlo a mano (no se toca)")
    if result["uitext"]:
        print(f"  [UiText] claves nuevas de la plantilla que le faltan al juego: {', '.join(result['uitext'])}")
    for rel in result["own"]:
        print(f"  [propio] {rel}: distinto en la plantilla, pero el juego lo hizo suyo ({IGNORE}); no se toca")
    for rel in result["removed"]:
        print(f"  [borrado en la plantilla] {rel} ({'borrado' if applied else 'se borraría'})")
    for rel in result["extra"]:
        print(f"  [solo del juego] {rel}: no está en la plantilla; no se toca")
    total = len(result["add"]) + len(result["update"]) + len(result["removed"])
    print(f"  {total} archivo(s) del núcleo {'al día' if applied else 'para poner al día'}, {len(result['config'])} de configuración para revisar"
          + ("" if applied or not result["config"] else " (--diff los muestra)"))


def selftest() -> int:
    with tempfile.TemporaryDirectory() as tmp:
        t, g = Path(tmp) / "t", Path(tmp) / "g"
        for base in (t, g):
            (base / "src/shared/Config").mkdir(parents=True)
            (base / "tests").mkdir(parents=True)
        (t / "src/core.luau").write_text("v2")
        (g / "src/core.luau").write_text("v1")
        (t / "src/new.luau").write_text("new")
        (g / "src/old.luau").write_text("old")
        (g / "src/gone.luau").write_text("la plantilla lo borró")
        (t / "src/shared/Config/KitConfig.luau").write_text("plantilla")
        (g / "src/shared/Config/KitConfig.luau").write_text("juego")
        (t / "src/shared/Config/UiText.luau").write_text("return {\n\tA = 'a',\n\tB = 'b',\n}")
        (t / "src/hud.luau").write_text("plantilla")
        (g / "src/hud.luau").write_text("propio")
        (g / IGNORE).write_text("# archivos del núcleo propios\nsrc/hud.luau\n")
        (g / "src/shared/Config/UiText.luau").write_text("return {\n\tA = 'a',\n}")
        result = plan(t, g, lambda rel: rel.as_posix() == "src/gone.luau")
        assert result["update"] == [Path("src/core.luau")], result
        assert result["add"] == [Path("src/new.luau")], result
        assert Path("src/shared/Config/KitConfig.luau") not in result["config"], "la receta no se compara"
        assert Path("src/shared/Config/UiText.luau") in result["config"], result
        assert result["uitext"] == ["B"], result
        assert result["extra"] == [Path("src/old.luau")], result
        assert result["removed"] == [Path("src/gone.luau")], result
        assert result["own"] == [Path("src/hud.luau")], result
        apply(t, g, result)
        assert (g / "src/core.luau").read_text() == "v2"
        assert (g / "src/new.luau").read_text() == "new"
        assert (g / "src/shared/Config/KitConfig.luau").read_text() == "juego", "la receta del juego no se toca"
        assert (g / "src/old.luau").exists(), "no se borra lo del juego"
        assert not (g / "src/gone.luau").exists(), "lo que la plantilla borró se borra"
        assert (g / "src/hud.luau").read_text() == "propio", "lo que el juego hizo suyo no se toca"
    print("selftest OK")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("game", help="carpeta del juego (games/<juego>) o 'selftest'")
    parser.add_argument("--apply", action="store_true", help="poner al día los archivos del núcleo")
    parser.add_argument("--diff", action="store_true", help="mostrar lo que cambió en la configuración")
    args = parser.parse_args()
    if args.game == "selftest":
        return selftest()
    game = (ROOT / args.game).resolve()
    template = ROOT / "template"
    if game == template:
        print("  [error] esa es la plantilla: pasar la carpeta de un juego (games/<juego>)")
        return 2
    if not (game / "default.project.json").exists():
        print(f"  [error] {args.game} no es un juego (falta default.project.json)")
        return 2
    result = plan(template, game)
    if args.apply:
        apply(template, game, result)
    report(result, args.apply)
    if args.diff:
        diffs(template, game, result)
    return 0


if __name__ == "__main__":
    sys.exit(main())
