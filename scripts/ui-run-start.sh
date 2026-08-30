#!/usr/bin/env bash
# 사용법: ./scripts/ui-run-start.sh <TASK_ID> <arm>
# UI 구동 암(aside-solo) 전용. 메모리를 비우고 녹화를 시작한 뒤,
# 프롬프트를 출력하고 대기 상태로 빠진다. 실제 프롬프트 입력은 컴퓨터유즈로 수행한다.
set -uo pipefail
cd "$(dirname "$0")/.."

TASK=$1; ARM=$2
REC_DISPLAY=${REC_DISPLAY:-2}
TASK_FILE=$(ls tasks/${TASK}-*.md 2>/dev/null | head -1)
PROMPT=$(awk '/^## Prompt/{f=1;next}/^## /{f=0}f' "$TASK_FILE" | sed '/^$/d' | sed '/^(/d')

OUT="runs/${TASK}-${ARM}"
[ -d "$OUT" ] && { echo "이미 존재: $OUT — 재실행하려면 먼저 삭제하세요"; exit 1; }
mkdir -p "$OUT/raw"

# 콜드 스타트
rm -rf "$HOME/.aside/u/0/memory" && mkdir -p "$HOME/.aside/u/0/memory"

# 기존 세션 목록 스냅샷 (실행 후 새로 생긴 세션을 식별하기 위해)
ls ~/.aside/u/0/sessions > "$OUT/raw/sessions-before.txt" 2>/dev/null

caffeinate -dimsu -w $$ &
screencapture -v -D $REC_DISPLAY "$OUT/raw/rec.mov" >/dev/null 2>&1 &
echo $! > "$OUT/raw/rec.pid"
sleep 2

date -u +%Y-%m-%dT%H:%M:%SZ > "$OUT/raw/started_at.txt"
cat <<BANNER
┌─────────────────────────────────────────────
│  ${TASK} × ${ARM}  (UI 구동)
│  녹화 시작됨 (디스플레이 ${REC_DISPLAY})
└─────────────────────────────────────────────
아래 프롬프트를 Aside의 에이전트 입력창에 넣고 실행하세요.

${PROMPT}

완료되면: ./scripts/ui-run-end.sh ${TASK} ${ARM}
BANNER
