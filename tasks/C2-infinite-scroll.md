# C2: Threads — 무한 스크롤 탐색

## Prompt (모든 암 동일, 이 블록을 그대로 투입)

Threads(threads.com)에서 Claude Code 활용 팁이 담긴 게시물 3개를 찾아서 링크와 한 줄 요약을 정리해줘.

## Success criteria

유효한 게시물 링크 3개와 실제 내용에 부합하는 요약이 산출됨.

## Rubric

- [ ] R1: 피드/검색 스크롤 탐색 생존 (DOM 재구성 중 오류 없음)
- [ ] R2: 링크 3개 모두 유효 (하네스가 HTTP 200 확인)
- [ ] R3: 요약이 실제 게시물 내용과 일치

## Allowed interventions

없음 (로그인 사전 완료).

## Notes

무한 스크롤 = 스크롤마다 DOM 재구성 + 가상화로 인접 게시물 텍스트 혼입 위험.
EVIDENCE claim 3 검증 과제.
