# Run order

암 순서는 과제마다 회전시킨다. 같은 암이 항상 먼저/나중에 들어가서 생기는
편향(사이트가 첫 방문자를 다르게 대하는 경우, 계정 상태 변화 등)을 상쇄하기
위한 것이며, **실행 전에 고정**한다.

| Task | 1st | 2nd | 3rd |
|------|-----|-----|-----|
| A1 쿠팡 | aside | playwright | chrome |
| A2 네이버 블로그 | playwright | chrome | aside |
| A3 네이버 지도 | chrome | aside | playwright |
| A4 인스타그램 | aside | chrome | playwright |
| A5 정부24 | playwright | aside | chrome |
| C1 업비트 | chrome | playwright | aside |
| C2 Threads | aside | playwright | chrome |
| C3 올리브영 | playwright | chrome | aside |
| D1 (선정 예정) | chrome | aside | playwright |
| D2 (선정 예정) | playwright | aside | chrome |

## 실행 규칙

- 과제당 각 암 1회. 인프라 실패(도구 크래시·네트워크)만 1회 재시도하고 기록한다.
- 녹화가 무효(실행 시간의 90% 미만)면 그 실행은 폐기하고 다시 돌린다.
- 타임아웃 900초. 초과 시 실패로 기록하고 도달 지점을 남긴다.
- C3(올리브영)는 비회원 장바구니가 불가하므로 로그인 확인 후 실행한다.
