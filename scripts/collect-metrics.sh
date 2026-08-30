#!/usr/bin/env bash
# 사용법: ./scripts/collect-metrics.sh <TASK_ID> <arm>
# 직전 실행의 Claude Code 세션 JSONL에서 토큰·툴콜을 추출해 metrics.json에 병합.
set -euo pipefail
cd "$(dirname "$0")/.."

TASK=$1; ARM=$2
OUT="runs/${TASK}-${ARM}"
[ -f "$OUT/metrics.json" ] || { echo "metrics.json 없음 — run-task.sh 먼저"; exit 1; }

if [ "$(jq -r '.recording.valid' "$OUT/metrics.json")" != "true" ]; then
  echo "경고: 이 실행은 녹화가 무효입니다. 기록하지 말고 재실행하세요."; exit 1
fi

SESSION_FILE="$OUT/raw/transcript.jsonl"
[ -f "$SESSION_FILE" ] || { echo "트랜스크립트 없음: $SESSION_FILE — 이 실행은 지표 집계 불가"; exit 1; }

TOKENS=$(jq -s '[.[] | select(.message.usage) | .message.usage] |
  { input_fresh: ([.[] | .input_tokens // 0] | add // 0),
    cache_read: ([.[] | .cache_read_input_tokens // 0] | add // 0),
    cache_creation: ([.[] | .cache_creation_input_tokens // 0] | add // 0),
    output: ([.[] | .output_tokens // 0] | add // 0) } |
  . + { total: (.input_fresh + .cache_read + .cache_creation + .output) }' "$SESSION_FILE")

TOOL_CALLS=$(jq -s '[.[] | select(.message.content? and (.message.content | type == "array")) |
  .message.content[] | select(.type? == "tool_use")] | length' "$SESSION_FILE")

jq --argjson tokens "$TOKENS" --argjson calls "$TOOL_CALLS" --arg session "$(basename "$SESSION_FILE")" \
  '.tokens = $tokens | .tool_calls = $calls | .session_file = $session' \
  "$OUT/metrics.json" > "$OUT/metrics.json.tmp" && mv "$OUT/metrics.json.tmp" "$OUT/metrics.json"

jq '{task, arm, wall_seconds, recording, tokens, tool_calls}' "$OUT/metrics.json"
echo "남은 수동 기입: outcome, rubric, interventions, notes"
