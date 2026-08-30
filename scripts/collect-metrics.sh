#!/usr/bin/env bash
# 사용법: ./scripts/collect-metrics.sh <TASK_ID> <arm>
# 직전 실행의 Claude Code 세션 JSONL에서 토큰·툴콜을 추출해 metrics.json에 병합.
set -euo pipefail
cd "$(dirname "$0")/.."

TASK=$1; ARM=$2
OUT="runs/${TASK}-${ARM}"
[ -f "$OUT/metrics.json" ] || { echo "metrics.json 없음 — run-task.sh 먼저"; exit 1; }

if [ "$(jq -r '.recording.valid' "$OUT/metrics.json")" != "true" ]; then
  if [ "${ALLOW_INVALID_RECORDING:-0}" = "1" ]; then
    echo "주의: 녹화 무효 상태로 기록합니다(ALLOW_INVALID_RECORDING=1). 사유를 notes에 반드시 남길 것."
  else
    echo "경고: 이 실행은 녹화가 무효입니다. 재실행하거나 ALLOW_INVALID_RECORDING=1로 사유와 함께 기록하세요."; exit 1
  fi
fi

if [ "$ARM" = "aside-solo" ]; then
  # Aside는 세션 기록에 usage(토큰·비용)와 toolName을 남긴다
  AF="$OUT/raw/aside-session.jsonl"
  [ -f "$AF" ] || { echo "Aside 세션 파일 없음: $AF"; exit 1; }
  AGG=$(jq -s '{
    tokens: { input: (map(.usage.input // 0)|add), output: (map(.usage.output // 0)|add),
              cache_read: (map(.usage.cacheRead // 0)|add), cache_write: (map(.usage.cacheWrite // 0)|add),
              reasoning: (map(.usage.reasoning // 0)|add), total: (map(.usage.totalTokens // 0)|add) },
    cost_usd: (map(.usage.cost.total // 0)|add),
    tool_calls: (map(select(.toolName)) | length),
    tools_used: (map(.toolName)|map(select(.))|group_by(.)|map({(.[0]): length})|add)
  }' "$AF")
  jq --argjson a "$AGG" '.tokens = $a.tokens | .tool_calls = $a.tool_calls
     | .cost_usd = $a.cost_usd | .tools_used = $a.tools_used
     | .session_file = "aside-session.jsonl"' "$OUT/metrics.json" > "$OUT/metrics.json.tmp" \
    && mv "$OUT/metrics.json.tmp" "$OUT/metrics.json"
  jq '{task, arm, wall_seconds, recording, tokens, tool_calls, cost_usd, tools_used}' "$OUT/metrics.json"
  echo "남은 수동 기입: outcome, rubric, interventions, notes"; exit 0
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
