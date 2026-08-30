# Run order

## 구조 (2026-08-30 확정)

- **과제 3개**: T1 네이버 블로그 발행 / T2 홈택스 사업자등록증명 / T3 용인 점심 예약(실사용 일정)
- **통제군 2암**: Claude Code + Opus 5 고정, 브라우저 백엔드만 교체
  - `aside` (aside CLI) · `playwright` (@playwright/cli)
  - Claude in Chrome은 제외 — 확장이 naver.com·coupang.com 도메인 이동 자체를
    차단해(사용자 설정으로 해제 불가) 3과제 중 2개에서 시작이 불가능하다.
    이 사실은 리포트에 별도 기재한다.
- **참조군 1암**: `aside-solo` — Aside 자체 에이전트를 **브라우저 UI로 구동**한다.
  일반 사용자가 쓰는 방식 그대로 Aside의 에이전트 입력창에 프롬프트를 넣으며,
  타이핑은 컴퓨터유즈(orca)로 수행한다(사람의 손 역할). CLI(`aside exec`)를 쓰지
  않는 이유는 그것이 실사용 경로가 아니기 때문.
  - 시간은 Aside 세션 기록(`~/.aside/u/0/sessions/*/messages.jsonl`)의 첫 메시지와
    마지막 메시지 타임스탬프 차이로 측정한다(밀리초 단위 기록).
  - 토큰·툴콜은 Claude Code 트랜스크립트 밖이라 측정 불가(null).
  - 실행 스크립트: `ui-run-start.sh` → (UI 투입) → `ui-run-end.sh`

## 순서 (과제마다 회전, 실행 전 고정)

| Task | 1st | 2nd | 3rd |
|------|-----|-----|-----|
| T1 블로그 | playwright | aside | aside-solo |
| T2 홈택스 | playwright | aside | aside-solo |
| T3 용인 점심 | playwright | aside | aside-solo |
| T4 지원사업 | playwright | aside | aside-solo |
| T5 부동산 | playwright | aside | aside-solo |

암 순서는 T3부터 `playwright → aside → aside-solo`로 고정한다(회전 없음).

## 실행 규칙

- 과제당 각 암 1회. 인프라 실패(도구 크래시·네트워크·녹화 무효)만 1회 재시도하고 기록.
- 녹화는 길이(실행의 90%↑)와 **내용**(25/50/75% 샘플 프레임에 작업 화면이 담겼는지)
  둘 다 확인해야 유효. 작업 탭은 항상 화면 앞에 둔다.
- 타임아웃 900초. 사람 개입은 간편인증·CAPTCHA만 허용(횟수 기록).
- 과제 산출물(PDF 등)은 실행 직후 비공개 경로로 이동해 다음 암이 못 보게 한다.
- **aside·aside-solo는 매 실행 직전 로컬 메모리(`~/.aside/u/0/memory`)를 비운다.**
  Aside는 사이트 공략을 마크다운 메모리에 축적하는데, 이를 남겨두면 뒤에 실행되는
  과제가 앞선 실행의 학습을 이점으로 갖게 되어 실행 간 독립성이 깨진다.
  따라서 모든 aside 계열 실행은 콜드 스타트다. (메모리 축적 효과 자체는 이번
  스코프 밖이며, 별도 실험으로 다뤄야 한다.)
