# Prepara RobloxCreator en esta maquina y verifica el entorno. Ver SETUP.md.
#
#   powershell -ExecutionPolicy Bypass -File .\setup.ps1             # prepara y verifica
#   powershell -ExecutionPolicy Bypass -File .\setup.ps1 -CheckOnly  # solo verifica
#
# Se puede correr cuantas veces haga falta: lo que ya esta bien no se toca.
# Solo ASCII en este archivo: Windows PowerShell 5.1 lee los .ps1 sin BOM como ANSI y rompe los acentos.

[CmdletBinding()]
param(
    [switch]$CheckOnly
)

$ErrorActionPreference = 'Stop'
# catalog.py escribe UTF-8; sin esto la consola muestra los acentos rotos.
# En PowerShell ISE no hay consola real y la asignacion falla: ahi solo se ven mal los acentos.
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch { }
$root = $PSScriptRoot
$script:faltas = 0
# $IsWindows no existe en Windows PowerShell 5.1, que solo corre en Windows.
$onWindows = ($PSVersionTable.PSEdition -eq 'Desktop') -or $IsWindows

function Write-Step([string]$msg) { Write-Host "`n$msg" -ForegroundColor Cyan }
function Write-Ok([string]$msg) { Write-Host "  [ok]    $msg" -ForegroundColor Green }
function Write-Missing([string]$msg) {
    Write-Host "  [falta] $msg" -ForegroundColor Yellow
    $script:faltas++
}

# Devuelve la primera linea de salida, o $null si el comando no existe o falla.
function Invoke-Probe([string]$cmd, [string[]]$cmdArgs) {
    if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) { return $null }
    # Con 'Stop', Windows PowerShell 5.1 convierte cualquier linea de stderr de un ejecutable en excepcion.
    $ErrorActionPreference = 'Continue'
    $out = @(& $cmd @cmdArgs 2>&1)
    if ($LASTEXITCODE -ne 0) { return $null }
    # Mostrar stdout si hay: una advertencia en stderr no es la version.
    $stdout = @($out | Where-Object { $_ -isnot [System.Management.Automation.ErrorRecord] })
    if ($stdout.Count -gt 0) { $out = $stdout }
    $first = "$($out | Select-Object -First 1)".Trim()
    if ($first) { return $first }
    return 'ok'
}

function Test-Program([string]$cmd, [string[]]$cmdArgs, [string]$help) {
    $version = Invoke-Probe $cmd $cmdArgs
    if ($version) { Write-Ok "${cmd}: $version"; return $true }
    Write-Missing "$cmd no esta instalado o no responde ($help)"
    return $false
}

Write-Host "RobloxCreator: preparando $root" -ForegroundColor Cyan
if ($CheckOnly) { Write-Host '(modo -CheckOnly: no se crea ni instala nada)' }

# ---------------------------------------------------------------------------
Write-Step '1. Programas base (SETUP.md, paso 1)'

Test-Program git @('--version') 'paso 1' | Out-Null
if (Test-Program gh @('--version') 'paso 1') {
    if (Invoke-Probe gh @('auth', 'status')) { Write-Ok 'gh: sesion iniciada' }
    else { Write-Missing 'gh: sin sesion. Correr: gh auth login' }
}
Test-Program claude @('--version') 'paso 1' | Out-Null

# En Windows, "python" puede ser el alias de la Microsoft Store, que existe pero no ejecuta nada.
$python = $null
foreach ($candidate in @('python', 'py', 'python3')) {
    $version = Invoke-Probe $candidate @('--version')
    if ($version) { $python = $candidate; Write-Ok "${candidate}: $version"; break }
}
if (-not $python) { Write-Missing 'Python 3 no esta instalado (paso 1)' }

# ---------------------------------------------------------------------------
Write-Step '2. Enlace .claude\skills -> skills (SETUP.md, paso 8)'

$link = Join-Path $root '.claude/skills'
$existing = Get-Item -LiteralPath $link -Force -ErrorAction SilentlyContinue
if (Test-Path (Join-Path $link '_shared/mcp-tools.md')) {
    Write-Ok '.claude\skills apunta a skills'
} elseif ($existing) {
    Write-Missing '.claude\skills existe pero no apunta a skills: borrarlo a mano y volver a correr el script'
} elseif ($CheckOnly) {
    Write-Missing '.claude\skills no existe (correr sin -CheckOnly)'
} else {
    New-Item -ItemType Directory -Force -Path (Join-Path $root '.claude') | Out-Null
    # Junction en Windows: no pide permisos de administrador, a diferencia de un symlink.
    $type = if ($onWindows) { 'Junction' } else { 'SymbolicLink' }
    New-Item -ItemType $type -Path $link -Target (Join-Path $root 'skills') | Out-Null
    Write-Ok ".claude\skills creado ($type). Reiniciar Claude Code para que liste los skills."
}

# ---------------------------------------------------------------------------
Write-Step '3. Rokit, Rojo y plugin de Rojo (SETUP.md, pasos 2 a 4)'

if (Test-Program rokit @('--version') 'paso 2') {
    $projects = @(Join-Path $root 'template')
    $gamesDir = Join-Path $root 'games'
    if (Test-Path $gamesDir) {
        $projects += Get-ChildItem $gamesDir -Directory |
            Where-Object { Test-Path (Join-Path $_.FullName 'rokit.toml') } |
            ForEach-Object { $_.FullName }
    }
    Push-Location (Join-Path $root 'template')
    try {
        if (-not $CheckOnly) {
            & rokit trust rojo-rbx/rojo
            foreach ($project in $projects) {
                Write-Host "  rokit install en $project"
                Push-Location $project
                try { & rokit install } finally { Pop-Location }
            }
        }
        # Rojo se resuelve por el rokit.toml de la carpeta actual: en la raiz del repo no hay.
        if (Test-Program rojo @('--version') 'pasos 2-3') {
            if (-not $CheckOnly) {
                # Reinstalar siempre deja el plugin en la misma version que el Rojo fijado.
                & rojo plugin install
                if ($LASTEXITCODE -eq 0) { Write-Ok 'plugin de Rojo instalado (reiniciar Studio si estaba abierto)' }
                else { Write-Missing 'rojo plugin install fallo: abrir Roblox Studio una vez y reintentar' }
            } elseif ($onWindows) {
                $plugin = Join-Path $env:LOCALAPPDATA 'Roblox/Plugins/RojoManagedPlugin.rbxm'
                if (Test-Path $plugin) { Write-Ok "plugin de Rojo en $plugin" }
                else { Write-Missing 'plugin de Rojo no instalado (correr sin -CheckOnly)' }
            }
        }
    } finally {
        Pop-Location
    }
}

# ---------------------------------------------------------------------------
Write-Step '4. MCP de Roblox Studio en Claude Code (SETUP.md, paso 5)'

if ($onWindows) {
    $mcpServer = Join-Path $env:LOCALAPPDATA 'Roblox/mcp.bat'
    $addCommand = 'claude mcp add Roblox_Studio --scope user -- cmd.exe /c %LOCALAPPDATA%\Roblox\mcp.bat'
} elseif ($IsMacOS) {
    $mcpServer = '/Applications/RobloxStudio.app/Contents/MacOS/StudioMCP'
    $addCommand = "claude mcp add Roblox_Studio --scope user -- $mcpServer"
} else {
    $mcpServer = $null
}

if (-not $mcpServer) {
    Write-Host '  Roblox Studio no existe para este sistema: se omite.'
} else {
    if (Test-Path $mcpServer) { Write-Ok "servidor MCP de Studio en $mcpServer" }
    else { Write-Missing "no existe $mcpServer`: instalar o actualizar Roblox Studio" }

    if (Get-Command claude -ErrorAction SilentlyContinue) {
        if (Invoke-Probe claude @('mcp', 'get', 'Roblox_Studio')) {
            Write-Ok 'Roblox_Studio registrado en Claude Code'
        } else {
            Write-Missing "Roblox_Studio no esta registrado. Correr una sola vez (en Windows, desde CMD): $addCommand"
        }
    }
}

# ---------------------------------------------------------------------------
Write-Step '5. Verificacion del hub (SETUP.md, paso 9)'

if ($python) {
    Push-Location $root
    try {
        foreach ($catalogCmd in @('selftest', 'validate')) {
            $result = Invoke-Probe $python @('assets/catalog.py', $catalogCmd)
            if ($result) { Write-Ok "catalog.py ${catalogCmd}: $result" }
            else { Write-Missing "catalog.py $catalogCmd fallo: correr '$python assets/catalog.py $catalogCmd' para ver el error" }
        }
    } finally {
        Pop-Location
    }
}

Write-Host ''
if ($script:faltas -eq 0) {
    Write-Host 'Todo listo. Ultima prueba (a mano): con Studio abierto, pedirle a Claude Code que llame a list_roblox_studios.' -ForegroundColor Green
    exit 0
}
Write-Host "Pendientes: $($script:faltas). Ver los [falta] de arriba y SETUP.md." -ForegroundColor Yellow
exit 1
