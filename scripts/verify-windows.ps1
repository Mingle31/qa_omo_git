param(
    [switch]$Quiet
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Check {
    param([string]$Message)
    if (-not $Quiet) {
        Write-Host "[CHECK] $Message" -ForegroundColor Cyan
    }
}

function Write-Ok {
    param([string]$Message)
    if (-not $Quiet) {
        Write-Host "[OK] $Message" -ForegroundColor Green
    }
}

function Fail {
    param([string]$Message)
    Write-Host "[FAIL] $Message" -ForegroundColor Red
    exit 1
}

function Test-WindowsHost {
    return ($env:OS -eq "Windows_NT")
}

function Assert-Command {
    param([string]$Name)
    $command = Get-Command $Name -ErrorAction SilentlyContinue
    if ($null -eq $command) {
        Fail "$Name is not available on PATH."
    }
    Write-Ok "$Name found: $($command.Source)"
}

function Test-ConfigContains {
    param(
        [string]$Config,
        [string]$Pattern,
        [string]$Description
    )
    if ($Config -notmatch $Pattern) {
        Fail "Codex config is missing $Description."
    }
    Write-Ok "Codex config contains $Description"
}

if (-not (Test-WindowsHost)) {
    Fail "Run this verifier from native Windows PowerShell."
}

Write-Check "Commands"
Assert-Command "node"
Assert-Command "npm"
Assert-Command "npx"
Assert-Command "codex"

Write-Check "Codex config"
$codexHome = if ([string]::IsNullOrWhiteSpace($env:CODEX_HOME)) {
    Join-Path $HOME ".codex"
} else {
    $env:CODEX_HOME
}
$configPath = Join-Path $codexHome "config.toml"
if (-not (Test-Path -LiteralPath $configPath)) {
    Fail "Codex config not found: $configPath"
}
$config = Get-Content -LiteralPath $configPath -Raw
Test-ConfigContains $config "\[marketplaces\.sisyphuslabs\]" "marketplace sisyphuslabs"
Test-ConfigContains $config '\[plugins\."omo@sisyphuslabs"\]' "plugin omo@sisyphuslabs"
Test-ConfigContains $config "plugins\s*=\s*true" "features.plugins = true"
Test-ConfigContains $config "plugin_hooks\s*=\s*true" "features.plugin_hooks = true"

if ($config -match 'approval_policy\s*=\s*"never"') {
    Write-Ok "Autonomous approval policy is enabled"
} else {
    Write-Host "[WARN] approval_policy = `"never`" is not set. This is fine if you installed with -NoAutonomous." -ForegroundColor Yellow
}

Write-Check "Plugin cache"
$pluginCache = Join-Path $codexHome "plugins\cache\sisyphuslabs\omo"
if (-not (Test-Path -LiteralPath $pluginCache)) {
    Fail "OMO plugin cache not found: $pluginCache"
}
Write-Ok "OMO plugin cache found: $pluginCache"

Write-Check "Git Bash"
$gitBashPath = $env:OMO_CODEX_GIT_BASH_PATH
if ([string]::IsNullOrWhiteSpace($gitBashPath)) {
    $gitBashPath = "C:\Program Files\Git\bin\bash.exe"
}
if (-not (Test-Path -LiteralPath $gitBashPath)) {
    Fail "Git Bash not found. Set OMO_CODEX_GIT_BASH_PATH to bash.exe."
}
Write-Ok "Git Bash found: $gitBashPath"

Write-Check "Component commands"
$binDir = if ([string]::IsNullOrWhiteSpace($env:CODEX_LOCAL_BIN_DIR)) {
    Join-Path $HOME ".local\bin"
} else {
    $env:CODEX_LOCAL_BIN_DIR
}
$expectedCommands = @(
    "omo.cmd",
    "omo-rules.cmd",
    "omo-lsp.cmd",
    "omo-comment-checker.cmd",
    "omo-git-bash-hook.cmd",
    "omo-ultrawork.cmd",
    "omo-start-work-continuation.cmd",
    "omo-telemetry.cmd"
)
foreach ($commandName in $expectedCommands) {
    $path = Join-Path $binDir $commandName
    if (-not (Test-Path -LiteralPath $path)) {
        Fail "Expected command shim not found: $path"
    }
}
Write-Ok "OMO command shims found in $binDir"

Write-Host ""
Write-Ok "Verification passed."
