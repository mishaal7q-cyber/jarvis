# JARVIS setup — installs a private Python runtime inside this folder.
# Nothing is installed system-wide and no administrator rights are required.

$ErrorActionPreference = "Stop"
Set-Location -Path $PSScriptRoot
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Write-Host ""
Write-Host "  JARVIS · first-run setup" -ForegroundColor Cyan
Write-Host "  ------------------------" -ForegroundColor DarkCyan

$tools = Join-Path $PSScriptRoot "tools"
New-Item -ItemType Directory -Force -Path $tools | Out-Null
$uv = Join-Path $tools "uv.exe"

if (-not (Test-Path $uv)) {
    Write-Host "  Downloading uv (portable Python installer)…" -ForegroundColor Yellow
    $zip = Join-Path $tools "uv.zip"
    Invoke-WebRequest -Uri "https://github.com/astral-sh/uv/releases/latest/download/uv-x86_64-pc-windows-msvc.zip" -OutFile $zip -UseBasicParsing
    Expand-Archive -Path $zip -DestinationPath $tools -Force
    Remove-Item $zip -Force
}

$env:UV_CACHE_DIR = Join-Path $PSScriptRoot ".uv-cache"
$env:UV_PYTHON_INSTALL_DIR = Join-Path $PSScriptRoot ".python"

Write-Host "  Installing Python 3.12 (project-local)…" -ForegroundColor Yellow
& $uv python install 3.12
if ($LASTEXITCODE -ne 0) { throw "Could not install Python." }

$venvPython = Join-Path $PSScriptRoot ".venv\Scripts\python.exe"
if (-not (Test-Path $venvPython)) {
    Write-Host "  Creating virtual environment…" -ForegroundColor Yellow
    & $uv venv .venv --python 3.12 --python-preference only-managed
    if ($LASTEXITCODE -ne 0) { throw "Could not create the virtual environment." }
}

Write-Host "  Installing dependencies…" -ForegroundColor Yellow
& $uv pip install --python $venvPython -r (Join-Path $PSScriptRoot "requirements.txt")
if ($LASTEXITCODE -ne 0) { throw "Dependency installation failed." }

Write-Host ""
Write-Host "  Setup complete. Starting JARVIS…" -ForegroundColor Green
Write-Host ""
