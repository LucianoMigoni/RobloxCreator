"""Chequeo del hub: corre en cada push (GitHub Actions) y antes de pedir revisión.

  python tools/check.py

Necesita `rojo`, `luau-lsp` y `luau` en el PATH: `rokit install` en la raíz los instala con las
versiones de rokit.toml. Las definiciones de tipos de Roblox se descargan una vez a .cache/.
"""
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CACHE = ROOT / ".cache"
DEFS_URL = "https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/{version}/scripts/globalTypes.d.luau"
SKIP_DIRS = {".git", ".cache", ".claude", "node_modules"}


def pinned_tools(manifest: Path) -> dict:
    """{'rojo': '7.7.1', ...} de un rokit.toml (líneas `alias = "dueño/repo@versión"`)."""
    text = manifest.read_text(encoding="utf-8")
    return dict(re.findall(r'^\s*([\w-]+)\s*=\s*"[\w.-]+/[\w.-]+@([^"]+)"', text, re.M))


def run(cmd: list, cwd: Path = ROOT, env=None) -> tuple:
    p = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True, encoding="utf-8",
                       errors="replace", env=env)
    # luau-lsp mezcla líneas de log ([INFO], [WARN]) con los errores.
    lines = [l for l in (p.stdout + p.stderr).splitlines() if not l.startswith(("[INFO]", "[WARN]"))]
    return p.returncode == 0, "\n".join(lines).strip()


def files(pattern: str):
    for path in sorted(ROOT.rglob(pattern)):
        if not SKIP_DIRS.intersection(path.relative_to(ROOT).parts):
            yield path


def rojo_projects() -> list:
    """template/ y cada games/<juego>/ con default.project.json."""
    candidates = [ROOT / "template"] + sorted((ROOT / "games").glob("*"))
    return [p for p in candidates if (p / "default.project.json").exists()]


def check_tools(tools: dict) -> list:
    errors = []
    # El CLI de luau no informa su versión: solo se verifica que esté.
    for name, flag, versioned in (("rojo", "--version", True), ("luau-lsp", "--version", True), ("luau", "--help", False)):
        if not shutil.which(name):
            errors.append(f"{name} no está en el PATH: correr `rokit install` en la raíz del repo")
            continue
        ok, out = run([name, flag])
        if not ok or (versioned and tools.get(name, "?") not in out):
            errors.append(f"{name} responde '{out[:80]}', pero rokit.toml fija {tools.get(name)}")
    for project in rojo_projects():
        manifest = project / "rokit.toml"
        if manifest.exists() and pinned_tools(manifest).get("rojo") != tools.get("rojo"):
            rel = manifest.relative_to(ROOT).as_posix()
            errors.append(f"{rel} fija rojo {pinned_tools(manifest).get('rojo')} y la raíz {tools.get('rojo')}")
    return errors


def roblox_definitions(version: str) -> Path:
    path = CACHE / f"luau-lsp-{version}" / "globalTypes.d.luau"
    if not path.exists():
        path.parent.mkdir(parents=True, exist_ok=True)
        with urllib.request.urlopen(DEFS_URL.format(version=version), timeout=60) as response:
            path.write_bytes(response.read())
    return path


def check_luau(definitions: Path) -> list:
    errors = []
    base = ["luau-lsp", "analyze", "--platform", "roblox", f"--definitions=@roblox={definitions}"]
    with tempfile.TemporaryDirectory() as tmp:
        for project in rojo_projects():
            rel = project.relative_to(ROOT).as_posix()
            ok, out = run(["rojo", "build", "-o", str(Path(tmp) / "place.rbxlx")], cwd=project)
            if not ok:
                errors.append(f"{rel}: rojo build falló\n{out}")
                continue
            # Con el sourcemap, luau-lsp resuelve require(ReplicatedStorage.Shared.X) igual que en Studio.
            # Sus rutas son relativas a la carpeta del proyecto: los dos comandos corren desde ahí.
            sourcemap = str(Path(tmp) / "sourcemap.json")
            ok, out = run(["rojo", "sourcemap", "-o", sourcemap], cwd=project)
            if not ok:
                errors.append(f"{rel}: rojo sourcemap falló\n{out}")
                continue
            if any((project / "src").rglob("*.luau")):
                ok, out = run(base + ["--sourcemap", sourcemap, "src"], cwd=project)
                if not ok:
                    errors.append(f"{rel}: errores de Luau\n{out}")
    ok, out = run(base + ["skills"])
    if not ok:
        errors.append(f"skills: errores de Luau\n{out}")
    return errors


def check_tests(definitions: Path) -> list:
    """Corre tests/*.spec.luau de cada proyecto con el CLI de luau y los analiza con luau-lsp."""
    errors = []
    for project in rojo_projects():
        rel = project.relative_to(ROOT).as_posix()
        specs = sorted((project / "tests").glob("*.spec.luau"))
        if not specs:
            continue
        # Con los tipos de Roblox porque el código que prueban los usa; si un test usara algo que el
        # CLI de luau no tiene, falla al correrlo.
        ok, out = run(["luau-lsp", "analyze", "--platform", "roblox", f"--definitions=@roblox={definitions}", "tests"],
                      cwd=project)
        if not ok:
            errors.append(f"{rel}/tests: errores de Luau\n{out}")
        for spec in specs:
            ok, out = run(["luau", spec.relative_to(project).as_posix()], cwd=project)
            if not ok:
                errors.append(f"{rel}/tests/{spec.name} falló\n{out}")
    return errors


# (regla, expresión, archivos permitidos): reglas de CLAUDE.md y de roblox-security que se pueden ver en el texto.
SOURCE_RULES = [
    ("remote escuchado fuera de server/Net/Remotes.luau: registrarlo con Remotes.onEvent/onInvoke",
     re.compile(r"\.OnServer(Event|Invoke)\b"), ("server/Net/Remotes.luau",)),
    ("remote creado fuera de server/Net/Remotes.luau",
     re.compile(r'Instance\.new\(\s*"(Unreliable)?Remote(Event|Function)"'), ("server/Net/Remotes.luau",)),
    ("wait/spawn/delay heredados: usar task.wait/task.spawn/task.delay",
     re.compile(r"(?<![\w.:])(wait|spawn|delay)\s*\("), ()),
]


def check_source_rules() -> list:
    errors = []
    roots = [p / "src" for p in rojo_projects()] + sorted((ROOT / "skills").glob("*/scripts"))
    for base in roots:
        for path in sorted(base.rglob("*.luau")):
            rel = path.relative_to(ROOT).as_posix()
            for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
                code = line.split("--", 1)[0]
                for message, pattern, allowed in SOURCE_RULES:
                    if pattern.search(code) and not rel.endswith(allowed or ("\0",)):
                        errors.append(f"{rel}:{number}: {message}")
    return errors


def check_catalog() -> list:
    errors = []
    for cmd in ("selftest", "validate"):
        ok, out = run([sys.executable, "assets/catalog.py", cmd])
        if not ok:
            errors.append(f"catalog.py {cmd}: {out}")
    return errors


def check_json() -> list:
    errors = []
    for path in files("*.json"):
        try:
            json.loads(path.read_text(encoding="utf-8"))
        except ValueError as e:
            errors.append(f"{path.relative_to(ROOT).as_posix()}: JSON inválido ({e})")
    return errors


def check_powershell() -> list:
    errors = []
    shell = shutil.which("pwsh") or shutil.which("powershell")
    parse = ("$e=$null; [void][System.Management.Automation.Language.Parser]::ParseFile("
             "$env:CHECK_PS1,[ref]$null,[ref]$e); if ($e) { $e | ForEach-Object { $_.ToString() }; exit 1 }")
    for path in files("*.ps1"):
        rel = path.relative_to(ROOT).as_posix()
        # Windows PowerShell 5.1 lee los .ps1 sin BOM como ANSI: un acento rompe los textos.
        if any(b > 127 for b in path.read_bytes()):
            errors.append(f"{rel}: tiene caracteres no ASCII")
        if shell:
            ok, out = run([shell, "-NoProfile", "-NonInteractive", "-Command", parse],
                          env={**os.environ, "CHECK_PS1": str(path)})
            if not ok:
                errors.append(f"{rel}: error de sintaxis de PowerShell\n{out}")
    if not shell:
        print("  (sin pwsh/powershell: se omite el análisis de sintaxis de los .ps1)")
    return errors


def main() -> int:
    sys.stdout.reconfigure(encoding="utf-8")  # la consola de Windows no es UTF-8 por defecto
    tools = pinned_tools(ROOT / "rokit.toml")
    steps = [
        ("herramientas y versiones", lambda: check_tools(tools)),
        ("Luau (rojo build + luau-lsp)", lambda: check_luau(roblox_definitions(tools["luau-lsp"]))),
        ("tests de Luau", lambda: check_tests(roblox_definitions(tools["luau-lsp"]))),
        ("reglas de seguridad y estilo", check_source_rules),
        ("catálogo de assets", check_catalog),
        ("JSON", check_json),
        ("PowerShell", check_powershell),
    ]
    failed = 0
    for name, step in steps:
        try:
            errors = step()
        except Exception as e:  # una herramienta que falta no debe ocultar el resto del reporte
            errors = [f"{type(e).__name__}: {e}"]
        print(f"[{'ok' if not errors else 'error'}] {name}")
        for error in errors:
            print("    " + error.replace("\n", "\n    "))
        failed += bool(errors)
    print("Chequeo OK" if not failed else f"Chequeo con errores en {failed} paso(s)")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
