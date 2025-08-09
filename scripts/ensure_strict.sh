#!/usr/bin/env bash
set -euo pipefail

# Ensure all project .luau files contain the `--!strict` header as the first non-empty line.
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

find "$ROOT" -type f -name "*.luau" ! -path "*/minitest/*" ! -path "*/staging_removed_tests_*/*" ! -name "*.spec.luau" | while read -r f; do
  # Find first non-empty line number
  first_non_blank=$(grep -n -m1 -v '^[[:space:]]*$' "$f" | cut -d: -f1 || true)
  if [ -z "$first_non_blank" ]; then
    # Empty file -> add strict header
    echo "--!strict" > "$f"
    continue
  fi
  line=$(sed -n "${first_non_blank}p" "$f")
  if [ "$line" != "--!strict" ]; then
    echo "Prepending --!strict to $f"
    sed -i '1i--!strict' "$f"
  fi
done