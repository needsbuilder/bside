#!/usr/bin/env bash
# 사용법: ./scripts/ui-run-end.sh <TASK_ID> <arm>
# 녹화를 종료하고, Aside 세션 기록에서 정확한 소요 시간을 산출해 metrics.json을 만든다.
set -uo pipefail
cd "$(dirname "$0")/.."

TASK=$1; ARM=$2
OUT="runs/${TASK}-${ARM}"
REC_FILE="$OUT/raw/rec.mov"

# 녹화 종료 + finalize 대기
REC=$(cat "$OUT/raw/rec.pid" 2>/dev/null)
[ -n "$REC" ] && kill -INT "$REC" 2>/dev/null
for _ in $(seq 1 60); do kill -0 "$REC" 2>/dev/null || break; sleep 1; done
kill -TERM "$REC" 2>/dev/null; sleep 1

# 이번 실행에서 새로 생긴 Aside 세션 찾기
NEW=$(comm -13 <(sort "$OUT/raw/sessions-before.txt") <(ls ~/.aside/u/0/sessions | sort) | tail -1)
WALL=0
if [ -n "$NEW" ] && [ -f "$HOME/.aside/u/0/sessions/$NEW/messages.jsonl" ]; then
  cp "$HOME/.aside/u/0/sessions/$NEW/messages.jsonl" "$OUT/raw/aside-session.jsonl"
  WALL=$(jq -s '(map(.timestamp) | (max - min)) / 1000 | floor' "$OUT/raw/aside-session.jsonl")
  echo "Aside 세션: $NEW (메시지 $(wc -l < "$OUT/raw/aside-session.jsonl" | tr -d ' ')개)"
else
  echo "경고: 새 Aside 세션을 찾지 못했습니다. 시간은 수동 기입이 필요합니다."
fi

REC_DUR=0
[ -f "$REC_FILE" ] && REC_DUR=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$REC_FILE" 2>/dev/null | cut -d. -f1)
REC_DUR=${REC_DUR:-0}
REC_VALID=false
[ "$REC_DUR" -gt 0 ] && [ "$WALL" -gt 0 ] && [ "$REC_DUR" -ge $(( WALL * 9 / 10 )) ] 2>/dev/null && REC_VALID=true

if [ "$REC_DUR" -gt 10 ] 2>/dev/null; then
  for pct in 25 50 75; do
    ffmpeg -v error -ss $(( REC_DUR * pct / 100 )) -i "$REC_FILE" -frames:v 1 \
      -vf scale=1100:-1 "$OUT/raw/frame-${pct}.png" -y 2>/dev/null
  done
fi

jq -n --arg task "$TASK" --arg arm "$ARM" --arg started "$(cat "$OUT/raw/started_at.txt")" \
  --argjson wall "$WALL" --argjson recdur "$REC_DUR" --argjson recvalid "$REC_VALID" '
{ task: $task, arm: $arm, started_at: $started, wall_seconds: $wall,
  outcome: null, rubric: {}, tokens: null, tool_calls: null, interventions: [],
  block_mode: null, misreads: [], retried_infra: false,
  driver: "UI (사람이 쓰듯 Aside 에이전트 입력창에 프롬프트 투입, 컴퓨터유즈로 타이핑)",
  recording: { seconds: $recdur, valid: $recvalid }, video: null, notes: "" }' > "$OUT/metrics.json"

echo "실행 ${WALL}초 (Aside 세션 타임스탬프 기준) · 녹화 ${REC_DUR}초 · 유효: $REC_VALID"
echo "샘플 프레임: $OUT/raw/frame-{25,50,75}.png"
