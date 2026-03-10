#!/usr/bin/env bash
# progress-reminder.sh — Portable hook: checks if a solution file was recently created
# without a corresponding tracker update. Outputs a reminder if so.
# Usage: bash .github/hooks/scripts/progress-reminder.sh [filepath]

set -euo pipefail

WORKSPACE_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
FILE="${1:-}"

if [[ -z "$FILE" ]]; then
  echo "Usage: progress-reminder.sh <filepath>"
  exit 0
fi

# Check if the file is a solution file (in DSA/, HLD/, LLD/, System-Design/, etc.)
SOLUTION_PATTERNS="DSA/|HLD/|LLD/|System-Design/|Machine-Coding/|ML-Algorithms/|ML-System-Design/|Component-Design/|Test-Design/|Infrastructure-Design/"

if echo "$FILE" | grep -qE "$SOLUTION_PATTERNS"; then
  # Extract company name from path
  COMPANY=$(echo "$FILE" | sed -n 's|.*/Companies/\([^/]*\)/.*|\1|p')
  if [[ -n "$COMPANY" ]]; then
    echo ""
    echo "📋 Progress Reminder: You just created a solution file for $COMPANY."
    echo "   → Update the Prep Tracker in WORKSPACE.md if this completes a milestone."
    echo "   → Check if the company's Analysis doc tracker needs updating too."
    echo ""
  fi
fi
