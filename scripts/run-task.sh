#!/usr/bin/env bash
# 사용법: ./scripts/run-task.sh <TASK_ID> <arm>   (arm: aside|playwright|chrome)
#
# 포그라운드 전용. 실행 전 무엇을 보아야 하는지 안내하고, 화면을 녹화하고,
# 끝나면 녹화 길이를 실행 시간과 대조해 유효성을 판정한다.
# 녹화가 유효하지 않으면 metrics.json에 recording_valid=false 로 남고
# 그 실행은 무효(재실행 대상)다.
set -uo pipefail
cd "$(dirname "$0")/.."

TASK=$1; ARM=$2
MODEL="claude-opus-5"
TIMEOUT_SECS=${TIMEOUT_SECS:-900}
REC_DISPLAY=${REC_DISPLAY:-2}   # 녹화 대상 디스플레이 (2 = 맥북 내장 = 서브 모니터)

TASK_FILE=$(ls tasks/${TASK}-*.md 2>/dev/null | head -1)
[ -f "$TASK_FILE" ] || { echo "과제 파일 없음: $TASK"; exit 1; }
PROMPT=$(awk '/^## Prompt/{f=1;next}/^## /{f=0}f' "$TASK_FILE" | sed '/^$/d' | sed '/^(/d')
[ -n "$PROMPT" ] || { echo "프롬프트 추출 실패"; exit 1; }

OUT="runs/${TASK}-${ARM}"
[ -d "$OUT" ] && { echo "이미 존재: $OUT — 재실행하려면 먼저 삭제하세요"; exit 1; }
mkdir -p "$OUT/raw"

case $ARM in
  aside)      WATCH="Aside 브라우저 창";;
  aside-solo) WATCH="Aside 브라우저 창 (자체 에이전트)";;
  playwright) WATCH="Chrome 창 (Playwright 확장이 조작)";;
  chrome)     WATCH="Chrome 창 (Claude in Chrome 탭 그룹)";;
  *) echo "unknown arm: $ARM"; exit 1;;
esac

cat <<BANNER

┌─────────────────────────────────────────────
│  ${TASK} × ${ARM}
│  볼 곳: ${WATCH}
│  제한: ${TIMEOUT_SECS}초 · 모델: ${MODEL}
└─────────────────────────────────────────────
프롬프트: ${PROMPT}

3초 후 녹화와 함께 시작합니다 (녹화: 디스플레이 ${REC_DISPLAY} = 서브 모니터).
브라우저 창을 서브 모니터에 두세요. 화면 잠금·절전 금지.
BANNER
sleep 3

caffeinate -dimsu -w $$ &   # 실행 동안 절전·화면잠금 방지
REC_FILE="$OUT/raw/rec.mov"
screencapture -v -D $REC_DISPLAY "$REC_FILE" >/dev/null 2>&1 &
REC=$!
sleep 2
kill -0 $REC 2>/dev/null || { echo "[중단] 녹화 프로세스가 기동하지 못했습니다. preflight.sh를 먼저 확인하세요."; rm -rf "$OUT"; exit 1; }

# aside 계열은 매 실행 전 로컬 메모리를 비워 콜드 스타트로 맞춘다.
# (이전 실행에서 학습한 사이트 공략이 다음 실행의 이점이 되는 것을 막는다)
if [ "$ARM" = "aside" ] || [ "$ARM" = "aside-solo" ]; then
  rm -rf "$HOME/.aside/u/0/memory" && mkdir -p "$HOME/.aside/u/0/memory"
  echo "[준비] Aside 로컬 메모리 초기화 완료 (콜드 스타트)"
fi

START=$(date +%s)
STARTED_AT=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# 격리 작업 디렉터리: 세션이 저장소(= 다른 암의 결과)를 우연히 읽지 못하게 한다.
# 과제가 참조하는 자료(assets/)만 복사해 넣는다.
REPO=$(pwd)
WORK=$(mktemp -d /tmp/bside-run-XXXXXX)
cp -R assets "$WORK"/ 2>/dev/null || true
cd "$WORK"

# 암별 도구 격리: 지정 도구만 허용하고 나머지 브라우저 자동화 경로는 차단한다.
DENY_COMMON=("Bash(playwriter:*)" "Bash(npx playwriter:*)" "Bash(bunx playwriter:*)")
case $ARM in
  aside-solo)
    # 참조군: Aside 자체 에이전트 루프 (하네스는 Claude Code가 아님 — 토큰 측정 불가)
    timeout $TIMEOUT_SECS aside exec "$PROMPT" 2>&1 | tee "$REPO/$OUT/raw/output.txt";;
  aside)
    timeout $TIMEOUT_SECS claude -p "$PROMPT" --model $MODEL \
      --allowedTools "Bash(aside:*)" \
      --disallowedTools "${DENY_COMMON[@]}" "Bash(npx playwright-cli:*)" \
      --append-system-prompt "브라우저 작업 규칙: 이 세션의 모든 브라우저 작업은 반드시 aside CLI(aside exec, aside repl)로만 수행한다. 다른 브라우저 자동화 도구는 사용하지 않는다. 작업은 현재 작업 디렉터리 안에서만 수행하고, 상위 디렉터리나 다른 프로젝트 폴더를 탐색하지 않는다. 화면이 녹화되고 있으므로 작업 중인 탭을 항상 화면 맨 앞의 활성 탭으로 두고 조작한다. 백그라운드 탭에서 조작하지 않는다." \
      2>&1 | tee "$REPO/$OUT/raw/output.txt";;
  playwright)
    set -a; source "$REPO/.env.local"; set +a
    npx playwright-cli eval "1" >/dev/null 2>&1 || npx playwright-cli attach --extension=chrome --session default >/dev/null 2>&1
    if ! npx playwright-cli eval "1" >/dev/null 2>&1; then
      echo "[중단] Playwright가 사용자 Chrome에 붙지 못했습니다. 확장 토큰을 확인하세요."
      kill -INT $REC 2>/dev/null; cd "$REPO"; rm -rf "$WORK" "$OUT"; exit 1
    fi
    timeout $TIMEOUT_SECS claude -p "$PROMPT" --model $MODEL \
      --allowedTools "Bash(npx playwright-cli:*)" \
      --disallowedTools "${DENY_COMMON[@]}" "Bash(aside:*)" \
      --append-system-prompt "브라우저 작업 규칙: 이 세션의 모든 브라우저 작업은 반드시 npx playwright-cli로만 수행한다. 브라우저는 이미 사용자의 로그인된 Chrome에 연결되어 있다(세션 이름 default). open 명령으로 새 브라우저를 띄우지 말고 기존 세션을 그대로 사용한다. 새 탭이 필요하면 tab-new를 쓴다. 다른 브라우저 자동화 도구는 사용하지 않는다. 작업은 현재 작업 디렉터리 안에서만 수행하고, 상위 디렉터리나 다른 프로젝트 폴더를 탐색하지 않는다. 화면이 녹화되고 있으므로 작업 중인 탭을 항상 화면 맨 앞의 활성 탭으로 두고 조작한다. 백그라운드 탭에서 조작하지 않는다." \
      2>&1 | tee "$REPO/$OUT/raw/output.txt";;
  chrome)
    timeout $TIMEOUT_SECS claude --chrome -p "$PROMPT" --model $MODEL \
      --disallowedTools "${DENY_COMMON[@]}" "Bash(aside:*)" "Bash(npx playwright-cli:*)" \
      --append-system-prompt "브라우저 작업 규칙: 이 세션의 모든 브라우저 작업은 반드시 내장 Claude in Chrome 브라우저 도구로만 수행한다. 다른 브라우저 자동화 도구는 사용하지 않는다. 작업은 현재 작업 디렉터리 안에서만 수행하고, 상위 디렉터리나 다른 프로젝트 폴더를 탐색하지 않는다. 화면이 녹화되고 있으므로 작업 중인 탭을 항상 화면 맨 앞의 활성 탭으로 두고 조작한다. 백그라운드 탭에서 조작하지 않는다." \
      2>&1 | tee "$REPO/$OUT/raw/output.txt";;
esac
EXIT_CODE=${PIPESTATUS[0]}
WALL=$(( $(date +%s) - START ))

# 이 실행의 세션 트랜스크립트를 확보한다 (격리 폴더 경로 기준 slug).
SLUG=$(printf '%s' "$WORK" | sed 's|^/private||; s|/|-|g')
SLUG_DIR="$HOME/.claude/projects/-private${SLUG}"
[ -d "$SLUG_DIR" ] || SLUG_DIR="$HOME/.claude/projects/${SLUG}"
SESSION=$(ls -t "$SLUG_DIR"/*.jsonl 2>/dev/null | head -1)

cd "$REPO"
[ -n "$SESSION" ] && cp "$SESSION" "$OUT/raw/transcript.jsonl"

# 실행이 작업폴더에 남긴 산출물을 보존한다 (assets 사본은 제외)
mkdir -p "$OUT/raw/artifacts"
(cd "$WORK" && find . -type f -not -path "./assets/*" -print0 2>/dev/null | \
  xargs -0 -I{} cp -p "{}" "$REPO/$OUT/raw/artifacts/" 2>/dev/null) || true
rmdir "$OUT/raw/artifacts" 2>/dev/null || true
rm -rf "$WORK"

# 녹화 종료 + finalize 대기 (파일이 커질수록 수 초 걸린다)
kill -INT $REC 2>/dev/null
for _ in $(seq 1 60); do kill -0 $REC 2>/dev/null || break; sleep 1; done
kill -TERM $REC 2>/dev/null; sleep 1

# 녹화 유효성 판정: 파일 존재 + 길이가 실행 시간의 90% 이상
REC_DUR=0
[ -f "$REC_FILE" ] && REC_DUR=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$REC_FILE" 2>/dev/null | cut -d. -f1)
REC_DUR=${REC_DUR:-0}
REC_VALID=false
[ "$REC_DUR" -ge $(( WALL * 9 / 10 )) ] 2>/dev/null && [ "$REC_DUR" -gt 0 ] && REC_VALID=true

TIMED_OUT=false; [ $EXIT_CODE -eq 124 ] && TIMED_OUT=true
jq -n --arg task "$TASK" --arg arm "$ARM" --arg started "$STARTED_AT" \
  --argjson wall "$WALL" --argjson timeout "$TIMED_OUT" \
  --argjson recdur "$REC_DUR" --argjson recvalid "$REC_VALID" '
{ task: $task, arm: $arm, started_at: $started, wall_seconds: $wall,
  outcome: (if $timeout then "timeout" else null end),
  rubric: {}, tokens: null, tool_calls: null, interventions: [],
  block_mode: null, misreads: [], retried_infra: false,
  recording: { seconds: $recdur, valid: $recvalid }, video: null, notes: "" }' > "$OUT/metrics.json"

# 녹화 내용 확인용 프레임 3장 (25%/50%/75% 지점)
if [ "$REC_DUR" -gt 10 ] 2>/dev/null; then
  for pct in 25 50 75; do
    ffmpeg -v error -ss $(( REC_DUR * pct / 100 )) -i "$REC_FILE" -frames:v 1 \
      -vf scale=1100:-1 "$OUT/raw/frame-${pct}.png" -y 2>/dev/null
  done
fi

echo ""
echo "─────────────────────────────────────────────"
echo "실행 ${WALL}초 (timeout: $TIMED_OUT) · 녹화 ${REC_DUR}초"
if [ "$REC_VALID" = true ]; then
  echo "[OK] 녹화 유효 — 이 실행은 기록 대상입니다."
  echo "샘플 프레임: $OUT/raw/frame-{25,50,75}.png — 작업 화면이 담겼는지 확인할 것"
  echo "다음: ./scripts/collect-metrics.sh $TASK $ARM"
else
  echo "[무효] 녹화가 실행 시간을 담지 못했습니다. 이 실행은 폐기하고 재실행하세요:"
  echo "  rm -rf $OUT && ./scripts/run-task.sh $TASK $ARM"
fi
echo "─────────────────────────────────────────────"
