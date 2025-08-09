Param(
    [string]$ScriptPath = $null,
    [string]$McpCmd = $null
)

$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$Root = Resolve-Path (Join-Path $ScriptDir '..') | Select-Object -ExpandProperty Path

if (-not $ScriptPath) {
    $ScriptPath = Join-Path $Root 'src\server_code\DirectLogMainModule.luau'
}

Write-Host "[run_main_via_mcp.ps1] Root: $Root"
Write-Host "[run_main_via_mcp.ps1] Script: $ScriptPath"

if (-not $McpCmd) {
    $mcpJson = Join-Path $Root '.kilocode\mcp.json'
    if (Test-Path $mcpJson) {
        try {
            $mcpObj = Get-Content $mcpJson -Raw | ConvertFrom-Json -ErrorAction Stop
            if ($mcpObj -and $mcpObj.mcpServers -and $mcpObj.mcpServers.'roblox-studio' -and $mcpObj.mcpServers.'roblox-studio'.command) {
                $McpCmd = $mcpObj.mcpServers.'roblox-studio'.command
            }
        } catch {
            Write-Host "[run_main_via_mcp.ps1] Failed to parse .kilocode/mcp.json: $_"
        }
    }
}

if (-not $McpCmd) {
    # Fall back to environment variable
    $McpCmd = $env:MCP_CMD
}

if (-not (Test-Path $ScriptPath)) {
    Write-Error "Script not found: $ScriptPath"
    exit 2
}

if (-not $McpCmd) {
    Write-Host ""
    Write-Host "MCP command not found. Set `$env:MCP_CMD or pass the MCP executable as the -McpCmd parameter."
    Write-Host "See .kilocode/mcp.json for configured MCP entries."
    exit 3
}

# Separate executable and arguments if command contains spaces
$parts = $McpCmd -split '\s+'
$exe = $parts[0]
$args = if ($parts.Count -gt 1) { $parts[1..($parts.Count-1)] -join ' ' } else { '' }

# Try to execute by piping script content to MCP using --stdio if supported
try {
    if (Get-Command $exe -ErrorAction SilentlyContinue) {
        Write-Host "[run_main_via_mcp.ps1] Found MCP executable: $exe"
        if ($args -match '--stdio') {
            Write-Host "[run_main_via_mcp.ps1] Using --stdio mode"
            Get-Content -Raw $ScriptPath | & $exe $args
            Write-Host "[run_main_via_mcp.ps1] Completed."
            exit 0
        } else {
            # Try piping even if --stdio not present; some clients accept STDIN
            try {
                Get-Content -Raw $ScriptPath | & $exe $args
                Write-Host "[run_main_via_mcp.ps1] Completed (piped)."
                exit 0
            } catch {
                Write-Host "[run_main_via_mcp.ps1] Piping failed; will try temp-file fallback."
            }
        }
    } elseif (Test-Path $exe) {
        Write-Host "[run_main_via_mcp.ps1] Found MCP path: $exe"
    } else {
        Write-Host "[run_main_via_mcp.ps1] MCP executable not found in PATH: $exe"
    }
} catch {
    Write-Host "[run_main_via_mcp.ps1] Error while trying to run MCP: $_"
}

# Fallback: write to a temp file and call MCP with the file path as argument
$tempFile = [System.IO.Path]::GetTempFileName() + '.luau'
Copy-Item -Path $ScriptPath -Destination $tempFile -Force
Write-Host "[run_main_via_mcp.ps1] Using temp file fallback: $tempFile"

$startArgs = @()
if ($args -ne '') {
    $startArgs += $args
}
$startArgs += $tempFile

try {
    $proc = Start-Process -FilePath $exe -ArgumentList $startArgs -Wait -NoNewWindow -PassThru
    Write-Host "[run_main_via_mcp.ps1] Process exited with code $($proc.ExitCode)"
} catch {
    Write-Error "[run_main_via_mcp.ps1] Failed to execute MCP: $_"
    Remove-Item -Force $tempFile -ErrorAction SilentlyContinue
    exit 4
}

Remove-Item -Force $tempFile -ErrorAction SilentlyContinue
Write-Host "[run_main_via_mcp.ps1] Done."
exit $proc.ExitCode