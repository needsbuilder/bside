#!/usr/bin/env bash
# 사용법: ./scripts/preflight.sh
# 실행 전 환경 점검. 하나라도 실패하면 실행하지 않는다.
set -uo pipefail
cd "$(dirname "$0")/.."
FAIL=0

echo "=== Bside preflight ==="

# 1) 화면 녹화 권한·동작 확인 (3초 프로브)
PROBE=/tmp/bside-probe.mov
rm -f "$PROBE"
screencapture -v -D ${REC_DISPLAY:-2} -V 3 "$PROBE" >/dev/null 2>&1
if [ -f "$PROBE" ]; then
  DUR=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$PROBE" 2>/dev/null | cut -d. -f1)
  if [ -n "$DUR" ] && [ "$DUR" -ge 2 ] 2>/dev/null; then
    echo "  [OK] 화면 녹화: ${DUR}초 프로브 성공"
  else
    echo "  [FAIL] 화면 녹화: 파일은 생겼으나 길이 비정상(${DUR:-0}s)"; FAIL=1
  fi
else
  echo "  [FAIL] 화면 녹화 불가 — 시스템 설정 > 개인정보 보호 > 화면 기록에서 터미널 허용 필요"; FAIL=1
fi
rm -f "$PROBE"

# 2) 도구 3종
for c in "aside --version" "npx playwright-cli --version" "claude --version"; do
  if $c >/dev/null 2>&1; then echo "  [OK] ${c%% *}"; else echo "  [FAIL] ${c%% *} 없음"; FAIL=1; fi
done

# 3) Aside 데몬
if aside account status >/dev/null 2>&1; then echo "  [OK] Aside 데몬·로그인"; else echo "  [FAIL] Aside 앱 실행 필요"; FAIL=1; fi

# 4) Playwright 실크롬 연결
if [ -f .env.local ]; then
  set -a; source .env.local; set +a
  if npx playwright-cli eval "1" >/dev/null 2>&1 || npx playwright-cli attach --extension=chrome --session default >/dev/null 2>&1; then
    echo "  [OK] Playwright ↔ 실크롬 확장 연결"
  else
    echo "  [FAIL] Playwright 확장 연결 실패 — 확장 패널의 토큰을 .env.local에 갱신"; FAIL=1
  fi
else
  echo "  [FAIL] .env.local 없음 (PLAYWRIGHT_MCP_EXTENSION_TOKEN=...)"; FAIL=1
fi

# 5) 절전 방지
pgrep -x caffeinate >/dev/null && echo "  [OK] caffeinate 작동 중" || echo "  [INFO] 실행 시 caffeinate 자동 기동"

echo "======================="
[ $FAIL -eq 0 ] && echo "준비 완료 — run-task.sh 실행 가능" || { echo "실패 항목을 해결한 뒤 다시 실행하세요"; exit 1; }
