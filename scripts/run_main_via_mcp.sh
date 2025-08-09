#!/usr/bin/env bash
set -euo pipefail

# Wrapper to send a Luau script to a Roblox Studio MCP run_code endpoint.
# Usage:
#   MCP_CMD=/path/to/rbx-studio-mcp ./scripts/run_main_via_mcp.sh [path-to-script]
#
# By default it sends src/server_code/DirectLogMainModule.luau

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT_PATH="${1:-$ROOT/src/server_code/DirectLogMainModule.luau}"
MCP_CMD="${2:-${MCP_CMD:-rbx-studio-mcp}}"

echo "[run_main_via_mcp] Root: $ROOT"
echo "[run_main_via_mcp] Script: $SCRIPT_PATH"
echo "[run_main_via_mcp] MCP command: $MCP_CMD"

if [ ! -f "$SCRIPT_PATH" ]; then
  echo "Error: script not found: $SCRIPT_PATH"
  exit 2
fi

# Test if MCP command looks available
if command -v "$MCP_CMD" >/dev/null 2>&1; then
  echo "[run_main_via_mcp] Found MCP command in PATH."
  # Try to run with --stdio if supported
  if "$MCP_CMD" --help 2>&1 | grep -qi -- '--stdio'; then
      echo "[run_main_via_mcp] Using --stdio mode"
      cat "$SCRIPT_PATH" | "$MCP_CMD" --stdio
  else
      echo "[run_main_via_mcp] MCP CLI does not advertise --stdio. Attempting to run with the file as argument."
      "$MCP_CMD" "$SCRIPT_PATH"
  fi
else
  # If the path is executable, try to run it directly (useful for Windows absolute paths)
  if [ -x "$MCP_CMD" ]; then
      echo "[run_main_via_mcp] Executing provided MCP path: $MCP_CMD"
      cat "$SCRIPT_PATH" | "$MCP_CMD" --stdio
  else
      echo ""
      echo "MCP command not found: $MCP_CMD"
      echo "Set MCP_CMD environment variable to the MCP client binary or pass the binary as the second argument."
      echo "On Windows you can find the configured client in [.kilocode/mcp.json](.kilocode/mcp.json:1)."
      echo ""
      echo "As a fallback, you can open the file and paste it into your MCP client's run_code UI:"
      echo "  less $SCRIPT_PATH"
      exit 3
  fi
fi

echo "[run_main_via_mcp] Completed."