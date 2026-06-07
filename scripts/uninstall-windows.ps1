Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if ($env:OS -ne "Windows_NT") {
    Write-Host "[ERROR] Run this script from native Windows PowerShell." -ForegroundColor Red
    exit 1
}

$npxCommand = Get-Command "npx.cmd" -ErrorAction SilentlyContinue
if ($null -eq $npxCommand) {
    $npxCommand = Get-Command "npx" -ErrorAction SilentlyContinue
}
if ($null -eq $npxCommand) {
    Write-Host "[ERROR] npx is not available. Install Node.js LTS first." -ForegroundColor Red
    exit 1
}

Write-Host "==> Uninstalling OMO/LazyCodex from Codex" -ForegroundColor Cyan
& $npxCommand.Source lazycodex-ai uninstall
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] npx lazycodex-ai uninstall failed with exit code $LASTEXITCODE." -ForegroundColor Red
    exit 1
}

Write-Host "[OK] Uninstall completed. Check ~/.codex/config.toml backups if you need to inspect removed settings." -ForegroundColor Green
