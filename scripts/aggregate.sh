#!/usr/bin/env bash
# 사용법: ./scripts/aggregate.sh   → runs/**/metrics.json을 markdown 표로 집계
set -euo pipefail
cd "$(dirname "$0")/.."

echo "| Task | Arm | Outcome | Time(s) | Rec(s) | Tokens | Tool calls | Interv | Rubric |"
echo "|------|-----|---------|---------|--------|--------|------------|--------|--------|"
for f in $(ls runs/*/metrics.json 2>/dev/null | sort); do
  jq -r '"| \(.task) | \(.arm) | \(.outcome // "?") | \(.wall_seconds) | \(.recording.seconds)\(if .recording.valid then "" else "✗" end) | \(.tokens.total // "?") | \(.tool_calls // "?") | \(.interventions | length) | \([.rubric | to_entries[] | select(.value == true)] | length)/\([.rubric | to_entries[] | select(.value != null)] | length) |"' "$f"
done
