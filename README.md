# Bside — Benchmarks for Aside

> **Independent project. Not affiliated with, endorsed, or sponsored by Aside / at inc.**

Does the [Aside](https://aside.com) browser actually outperform existing
browser-automation setups on the real web? We run the same tasks — on sites
notorious for breaking automation (Coupang, Naver, gov.kr, Instagram) — through
three setups, all driven by Claude Code with the same model (Opus 5):

| Arm | Interface |
|-----|-----------|
| Aside | `aside` CLI |
| Playwright | `@playwright/cli` |
| Claude in Chrome | built-in `--chrome` |

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
