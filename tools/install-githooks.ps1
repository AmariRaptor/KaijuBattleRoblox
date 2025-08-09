# PowerShell installer for Git hooks - sets repository to use the .githooks directory
Param(
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$Root = Resolve-Path (Join-Path $ScriptDir '..') | Select-Object -ExpandProperty Path

Write-Host "[install-githooks] Repository root: $Root"

$githooksDir = Join-Path $Root '.githooks'
$gitDir = Join-Path $Root '.git'

if (-not (Test-Path $githooksDir)) {
    Write-Error "[install-githooks] .githooks directory not found at $githooksDir"
    exit 1
}

# Prefer configuring git to use .githooks, which is portable and doesn't modify .git
if (Get-Command git -ErrorAction SilentlyContinue) {
    Write-Host "[install-githooks] Setting git config core.hooksPath to .githooks"
    & git config core.hooksPath .githooks
    Write-Host "[install-githooks] Done. Git will now use .githooks as hooks path."
} else {
    # Fallback: copy files to .git/hooks
    if (-not (Test-Path $gitDir)) {
        Write-Error "[install-githooks] .git directory not found and git is not available."
        exit 1
    }
    $hooksDir = Join-Path $gitDir 'hooks'
    if (-not (Test-Path $hooksDir)) {
        New-Item -ItemType Directory -Path $hooksDir | Out-Null
    }
    Write-Host "[install-githooks] Copying hooks to .git/hooks..."
    Get-ChildItem -Path $githooksDir -File | ForEach-Object {
        Copy-Item -Path $_.FullName -Destination (Join-Path $hooksDir $_.Name) -Force
    }
    Write-Host "[install-githooks] Hooks copied to .git/hooks"
}

# Make executable in POSIX if bash/chmod exists - best-effort
if (Get-Command bash -ErrorAction SilentlyContinue) {
    try {
        & bash -lc "chmod +x '.githooks'/*" | Out-Null
        Write-Host "[install-githooks] Set executable bit for .githooks hooks (via bash)."
    } catch {
        Write-Host "[install-githooks] Failed to set chmod via bash: $_"
    }
} else {
    Write-Host "[install-githooks] Bash not available; skipping chmod step."
}

Write-Host "[install-githooks] Installation complete. To verify, run 'git config --get core.hooksPath' (should output .githooks) or check .git/hooks contents."