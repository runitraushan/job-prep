#!/usr/bin/env bash
# session-context.sh — Portable hook: reads workspace prep state and outputs a context summary.
# Run at session start to inject active company/role context into any AI tool.
# Usage: bash .github/hooks/scripts/session-context.sh

set -euo pipefail

WORKSPACE_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
TRACKER_FILE="$WORKSPACE_ROOT/WORKSPACE.md"

echo "=== Session Context ==="

# 1. Show active companies from Prep Tracker
if [[ -f "$TRACKER_FILE" ]]; then
  echo ""
  echo "## Active Prep Companies"
  # Extract data rows from Prep Tracker table
  sed -n '/^| Company/,/^$/p' "$TRACKER_FILE" | grep -E '^\|' | grep -v '^|[-| ]*$' | grep -v '^| Company' | while IFS='|' read -r _ company role _ _ _ _ status _; do
    company="$(echo "$company" | xargs)"
    role="$(echo "$role" | xargs)"
    status="$(echo "$status" | xargs)"
    [[ -n "$company" ]] && echo "- $company ($role) — $status"
  done
fi

# 2. List company folders with analysis docs
echo ""
echo "## Companies with Analysis Docs"
for dir in "$WORKSPACE_ROOT"/Companies/*/; do
  if [[ -d "$dir" ]]; then
    company="$(basename "$dir")"
    analysis=$(find "$dir" -maxdepth 1 -name "*-Analysis.md" 2>/dev/null | head -1)
    if [[ -n "$analysis" ]]; then
      echo "- $company: $(basename "$analysis")"
    else
      echo "- $company: (no analysis doc yet)"
    fi
  fi
done

echo ""
echo "=== End Session Context ==="
