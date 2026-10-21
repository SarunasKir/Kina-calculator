#!/usr/bin/env bash
# Fails when line coverage in an lcov file is below a minimum percentage.
# Usage: tool/check_coverage.sh <lcov.info> <minimum-percent>
set -euo pipefail

file="$1"
minimum="$2"

read -r hit found < <(awk -F'[:,]' '
  /^DA:/ { found++; if ($3 > 0) hit++ }
  END { print hit + 0, found + 0 }
' "$file")

if [ "$found" -eq 0 ]; then
  echo "No coverage data in $file" >&2
  exit 1
fi

percent=$(awk -v h="$hit" -v f="$found" 'BEGIN { printf "%.2f", h * 100 / f }')
echo "Line coverage: $percent% ($hit of $found lines)"

if awk -v p="$percent" -v m="$minimum" 'BEGIN { exit !(p < m) }'; then
  echo "Coverage is below the required $minimum%" >&2
  exit 1
fi
