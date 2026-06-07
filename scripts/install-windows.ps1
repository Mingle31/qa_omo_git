param(
    [switch]$NoAutonomous,
    [switch]$SkipGitBashInstall,
    [switch]$AddToUserPath,
    [string]$GitBashPath,
    [string]$CodexLocalBinDir
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message)
    Write-Host ""
    Write-Host "==> $Message" -ForegroundColor Cyan
}

function Write-Ok {
    param([string]$Message)
    Write-Host "[OK] $Message" -ForegroundColor Green
}

function Write-Warn {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Fail {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
    exit 1
}

function Test-WindowsHost {
    return ($env:OS -eq "Windows_NT")
}

function Get-CommandPath {
    param([string]$Name)
    $command = Get-Command $Name -ErrorAction SilentlyContinue
    if ($null -eq $command) {
        return $null
    }
    return $command.Source
}

function Assert-Command {
    param(
        [string]$Name,
        [string]$InstallHint
    )
    $path = Get-CommandPath $Name
    if ($null -eq $path) {
        Fail "$Name is not available. $InstallHint"
    }
    Write-Ok "$Name found: $path"
}

function Get-NpxExecutable {
    $cmdPath = Get-CommandPath "npx.cmd"
    if ($null -ne $cmdPath) {
        return $cmdPath
    }

    $npxPath = Get-CommandPath "npx"
    if ($null -ne $npxPath) {
        return $npxPath
    }

    Fail "npx is not available. Install Node.js LTS from https://nodejs.org/"
}

function Test-IsGitBash {
    param([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path)) {
        return $false
    }
    return ($Path.ToLowerInvariant().EndsWith("bash.exe") -and (Test-Path -LiteralPath $Path))
}

function Find-GitBash {
    $candidates = @()
    if (-not [string]::IsNullOrWhiteSpace($GitBashPath)) {
        $candidates += $GitBashPath
    }
    if (-not [string]::IsNullOrWhiteSpace($env:OMO_CODEX_GIT_BASH_PATH)) {
        $candidates += $env:OMO_CODEX_GIT_BASH_PATH
    }
    $candidates += "C:\Program Files\Git\bin\bash.exe"
    $candidates += "C:\Program Files (x86)\Git\bin\bash.exe"

    $whereOutput = & where.exe bash 2>$null
    if ($LASTEXITCODE -eq 0) {
        $candidates += $whereOutput
    }

    foreach ($candidate in $candidates) {
        $trimmed = [string]$candidate
        $trimmed = $trimmed.Trim()
        if (Test-IsGitBash $trimmed) {
            return $trimmed
        }
    }
    return $null
}

function Add-DirectoryToUserPath {
    param([string]$Directory)
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($null -eq $userPath) {
        $userPath = ""
    }
    $parts = $userPath -split ";" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    $alreadyPresent = $false
    foreach ($part in $parts) {
        if ($part.TrimEnd("\") -ieq $Directory.TrimEnd("\")) {
            $alreadyPresent = $true
            break
        }
    }
    if ($alreadyPresent) {
        Write-Ok "User PATH already contains $Directory"
        return
    }
    $nextPath = if ($userPath.Length -eq 0) { $Directory } else { "$userPath;$Directory" }
    [Environment]::SetEnvironmentVariable("Path", $nextPath, "User")
    Write-Ok "Added $Directory to the user PATH. Restart VS Code terminals to pick it up."
}

Write-Step "Checking host"
if (-not (Test-WindowsHost)) {
    Fail "Run this script from native Windows PowerShell in VS Code, not from WSL or Linux."
}
Write-Ok "Windows host detected"

Write-Step "Checking prerequisites"
Assert-Command "node" "Install Node.js LTS from https://nodejs.org/"
Assert-Command "npm" "Install Node.js LTS from https://nodejs.org/"
Assert-Command "npx" "Install Node.js LTS from https://nodejs.org/"
Assert-Command "codex" "Install OpenAI Codex CLI first, then run this script again."

Write-Step "Preparing Codex directories"
$codexHome = if ([string]::IsNullOrWhiteSpace($env:CODEX_HOME)) {
    Join-Path $HOME ".codex"
} else {
    $env:CODEX_HOME
}
New-Item -ItemType Directory -Force -Path $codexHome | Out-Null
Write-Ok "CODEX_HOME: $codexHome"

if ([string]::IsNullOrWhiteSpace($CodexLocalBinDir)) {
    $CodexLocalBinDir = Join-Path $HOME ".local\bin"
}
New-Item -ItemType Directory -Force -Path $CodexLocalBinDir | Out-Null
$env:CODEX_LOCAL_BIN_DIR = $CodexLocalBinDir
[Environment]::SetEnvironmentVariable("CODEX_LOCAL_BIN_DIR", $CodexLocalBinDir, "User")
Write-Ok "CODEX_LOCAL_BIN_DIR: $CodexLocalBinDir"

if ($AddToUserPath) {
    Add-DirectoryToUserPath $CodexLocalBinDir
} elseif (($env:Path -split ";") -notcontains $CodexLocalBinDir) {
    Write-Warn "$CodexLocalBinDir is not in the current PATH. Re-run with -AddToUserPath if you want omo*.cmd commands available in new VS Code terminals."
}

Write-Step "Checking Git Bash"
$resolvedGitBash = Find-GitBash
if ($null -eq $resolvedGitBash -and -not $SkipGitBashInstall) {
    $winget = Get-CommandPath "winget"
    if ($null -ne $winget) {
        Write-Warn "Git Bash was not found. Trying winget install --id Git.Git -e --source winget"
        & winget install --id Git.Git -e --source winget
        $resolvedGitBash = Find-GitBash
    } else {
        Write-Warn "winget is not available, so Git Bash cannot be installed automatically."
    }
}

if ($null -eq $resolvedGitBash) {
    Fail "Git Bash is required. Install Git for Windows or set OMO_CODEX_GIT_BASH_PATH to C:\path\to\bash.exe."
}

$env:OMO_CODEX_GIT_BASH_PATH = $resolvedGitBash
[Environment]::SetEnvironmentVariable("OMO_CODEX_GIT_BASH_PATH", $resolvedGitBash, "User")
Write-Ok "Git Bash: $resolvedGitBash"

Write-Step "Installing OMO/LazyCodex for Codex"
$npxExecutable = Get-NpxExecutable
$installArgs = @("lazycodex-ai", "install", "--no-tui")
if ($NoAutonomous) {
    $installArgs += "--no-codex-autonomous"
} else {
    $installArgs += "--codex-autonomous"
}

& $npxExecutable @installArgs
if ($LASTEXITCODE -ne 0) {
    Fail "npx lazycodex-ai install failed with exit code $LASTEXITCODE."
}

Write-Step "Verifying installation"
& (Join-Path $PSScriptRoot "verify-windows.ps1")
if ($LASTEXITCODE -ne 0) {
    Fail "Verification failed."
}

Write-Host ""
Write-Ok "Windows VS Code Codex harness setup is complete."
Write-Host "Restart VS Code terminals if PATH or user environment variables were changed."
