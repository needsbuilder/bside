# Run order

## 구조 (2026-08-30 확정)

- **과제 3개**: T1 네이버 블로그 발행 / T2 정부24 등본 / T3 용인 점심 예약(실사용 일정)
- **통제군 3암**: Claude Code + Opus 5 고정, 브라우저 백엔드만 교체
  - `aside` (aside CLI) · `playwright` (@playwright/cli) · `chrome` (Claude in Chrome)
- **참조군 1암**: `aside-solo` — Aside 자체 에이전트(`aside exec`), 모델 동일(Opus 5).
  하네스가 다르므로 통제 비교가 아니라 "제품이 의도한 형태의 상한"으로 해석.
  토큰·툴콜은 Claude Code 트랜스크립트 밖이라 측정 불가(null)로 표기.

## 순서 (과제마다 회전, 실행 전 고정)

| Task | 1st | 2nd | 3rd | 4th |
|------|-----|-----|-----|-----|
| T1 블로그 | playwright | chrome | aside | aside-solo |
| T2 정부24 | aside | aside-solo | playwright | chrome |
| T3 용인 점심 | chrome | playwright | aside-solo | aside |

## 실행 규칙

- 과제당 각 암 1회. 인프라 실패(도구 크래시·네트워크·녹화 무효)만 1회 재시도하고 기록.
- 녹화는 길이(실행의 90%↑)와 **내용**(25/50/75% 샘플 프레임에 작업 화면이 담겼는지)
  둘 다 확인해야 유효. 작업 탭은 항상 화면 앞에 둔다.
- 타임아웃 900초. 사람 개입은 간편인증·CAPTCHA만 허용(횟수 기록).
- 과제 산출물(PDF 등)은 실행 직후 비공개 경로로 이동해 다음 암이 못 보게 한다.
