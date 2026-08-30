# Bside — Benchmarks for Aside

> **Independent project. Not affiliated with, endorsed, or sponsored by Aside / at inc.**

Does the [Aside](https://aside.com) browser actually outperform existing
browser-automation setups on the real web? We run the same three tasks — on
sites notorious for breaking automation (Naver SmartEditor, Hometax, Naver Map)
— through three setups. Two are controlled (Claude Code + Opus 5, only the
browser backend changes); one is Aside's own agent as a reference:

| Arm | Interface | Role |
|-----|-----------|------|
| Aside | `aside` CLI | controlled |
| Playwright | `@playwright/cli` | controlled |
| Aside solo | `aside exec` (own agent loop) | reference |

Claude in Chrome was excluded up front: its extension refuses to open
naver.com and coupang.com at all (a built-in domain policy users cannot
change), so it cannot even start two of the three tasks.

**Results: TBD after runs** <!-- 결과 요약표 + 영상 링크로 교체 -->

Benchmarks are the A-side. The real web is the B-side.

- Methodology & task definitions: [`tasks/`](tasks/) — committed **before** any run (see git history)
- Why these sites: [`EVIDENCE.md`](EVIDENCE.md)
- Raw run data: [`runs/`](runs/) · Full report: [`report/RESULTS.md`](report/RESULTS.md)

Every run that reaches a page is screen-recorded, and the recording is
verified against the wall-clock time before the run counts. Runs that lose
their recording are re-run. The one exception is a run blocked before any page
loads: there is nothing on screen to record, so its transcript stands as the
evidence and the run record says so.
