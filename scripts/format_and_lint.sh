#!/usr/bin/env bash
set -euo pipefail

# Format and lint Luau files with auto-fix where available.
# - Runs a Luau formatter (attempts several common binaries)
# - Runs Selene linter and attempts to auto-fix if supported
#
# Usage: ./scripts/format_and_lint.sh

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "[format_and_lint] Locating Luau formatter..."
if command -v luau-format >/dev/null 2>&1; then
  FORMAT_CMD="luau-format -i"
elif command -v luauformat >/dev/null 2>&1; then
  FORMAT_CMD="luauformat -w"
elif command -v luafmt >/dev/null 2>&1; then
  FORMAT_CMD="luafmt -w"
else
  FORMAT_CMD=""
fi

# Build file list (exclude test artifacts and staging folders)
mapfile -t LUAFILES < <(git ls-files '*.luau' ':!:minitest/*' ':!:staging_removed_tests_*/*' ':!:**/*.spec.luau' || true)

if [ "${#LUAFILES[@]}" -eq 0 ]; then
  echo "[format_and_lint] No .luau files found to format/lint."
else
  if [ -n "$FORMAT_CMD" ]; then
    echo "[format_and_lint] Running formatter: $FORMAT_CMD"
    # Some formatters accept glob lists, run per-file for broad compatibility
    for f in "${LUAFILES[@]}"; do
      echo "[format_and_lint] Formatting $f"
      $FORMAT_CMD "$f" || echo "[format_and_lint] Warning: formatting failed for $f"
    done
  else
    echo "[format_and_lint] Luau formatter not found (looked for luau-format, luauformat, luafmt). Skipping formatting."
  fi

  if command -v selene >/dev/null 2>&1; then
    echo "[format_and_lint] Running Selene linter (attempting autofix if supported)"
    # Try to run selene with --fix if available, otherwise run it normally
    if selene --help 2>&1 | grep -q 'fix'; then
      selene --fix --config selene.toml "${LUAFILES[@]}" || echo "[format_and_lint] Selene returned non-zero exit code"
    else
      selene --config selene.toml "${LUAFILES[@]}" || echo "[format_and_lint] Selene returned non-zero exit code"
    fi
  else
    echo "[format_and_lint] Selene not installed. Install Selene to enable linting: https://github.com/Kampfar/selene"
  fi
fi

echo "[format_and_lint] Done."