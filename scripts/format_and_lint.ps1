# PowerShell script to format and lint Luau files (Windows)
Param()
$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$Root = Resolve-Path (Join-Path $ScriptDir '..') | Select-Object -ExpandProperty Path
Set-Location $Root

Write-Host "[format_and_lint.ps1] Running in $Root"

# Build file list (prefer git if available)
if (Get-Command git -ErrorAction SilentlyContinue) {
    $luafiles = & git ls-files '*.luau' ':!:minitest/*' ':!:staging_removed_tests_*/*' ':!:**/*.spec.luau' 2>$null | Where-Object { $_ -ne '' }
} else {
    $luafiles = Get-ChildItem -Path $Root -Recurse -Filter '*.luau' -File |
        Where-Object { $_.FullName -notmatch '\\minitest\\' -and $_.FullName -notmatch 'staging_removed_tests_' -and $_.Name -notlike '*.spec.luau' } |
        ForEach-Object { $_.FullName }
}

if (-not $luafiles -or $luafiles.Count -eq 0) {
    Write-Host "[format_and_lint.ps1] No .luau files found to format/lint."
    exit 0
}

# Locate Luau formatter
$fmtCmd = $null
$fmtArgs = $null

if (Get-Command luau-format -ErrorAction SilentlyContinue) {
    $fmtCmd = 'luau-format'
    $fmtArgs = '-i'
} elseif (Get-Command luauformat -ErrorAction SilentlyContinue) {
    $fmtCmd = 'luauformat'
    $fmtArgs = '-w'
} elseif (Get-Command luafmt -ErrorAction SilentlyContinue) {
    $fmtCmd = 'luafmt'
    $fmtArgs = '-w'
}

if ($fmtCmd) {
    Write-Host "[format_and_lint.ps1] Using formatter: $fmtCmd $fmtArgs"
    foreach ($f in $luafiles) {
        Write-Host "[format_and_lint.ps1] Formatting $f"
        try {
            & $fmtCmd $fmtArgs $f
        } catch {
            Write-Warning "[format_and_lint.ps1] Formatting failed for $f: $_"
        }
    }
} else {
    Write-Host "[format_and_lint.ps1] Luau formatter not found (looked for luau-format, luauformat, luafmt). Skipping formatting."
}

# Run Selene linter (attempt autofix if supported)
if (Get-Command selene -ErrorAction SilentlyContinue) {
    Write-Host "[format_and_lint.ps1] Running Selene linter"
    $help = & selene --help 2>&1
    $supportsFix = $help -match 'fix'
    try {
        if ($supportsFix) {
            Write-Host "[format_and_lint.ps1] Selene supports --fix; running with auto-fix"
            & selene --fix --config selene.toml @luafiles
        } else {
            & selene --config selene.toml @luafiles
        }
    } catch {
        Write-Warning "[format_and_lint.ps1] Selene returned non-zero exit code"
    }
} else {
    Write-Host "[format_and_lint.ps1] Selene not found. Install Selene to enable linting: https://github.com/Kampfar/selene"
}

Write-Host "[format_and_lint.ps1] Done."