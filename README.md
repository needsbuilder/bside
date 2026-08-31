# Bside — Benchmarks for Aside

> **Independent project. Not affiliated with, endorsed, or sponsored by Aside / at inc.**

Does the [Aside](https://aside.com) browser actually beat existing
browser-automation setups on the real web? Korean dev threads were arguing
about it with no numbers, so we ran five real errands — on sites known for
breaking automation — through three setups and published everything.

**The headline: the same browser produced opposite outcomes depending on how
you use it.**

| Arm | What it is | Record |
|-----|-----------|--------|
| **Aside solo** | Aside's own agent, prompted in its browser UI | **5–0** |
| **Aside CLI** | Claude Code + Opus 5 → `aside` CLI | 1–4 |
| **Playwright** | Claude Code + Opus 5 → `@playwright/cli` → real Chrome | 3–2 |

Aside driven by its own agent finished every task and was the fastest arm on
all five. The same Aside handed to a coding agent as a CLI lost to Playwright.

📄 **[Full report](report/RESULTS.md)** · **[한국어 리포트](report/RESULTS.ko.md)**

Benchmarks are the A-side. The real web is the B-side.

---

## The tasks

Five errands, chosen because they are known to break automation — not because
they flatter any tool. Each is something a Korean solo founder actually does.

| # | Task | Site |
|---|------|------|
| T1 | Publish a post meeting six SEO constraints | Naver Blog (SmartEditor) |
| T2 | Draft a tax invoice, stop before issuing | Hometax |
| T3 | Find lunch near a real meeting, reach the booking screen | Naver Map |
| T4 | Match government grant programs to a solo business | bizinfo + K-Startup |
| T5 | Cross-check rental listings across two portals | Naver Land + Zigbang |

Definitions and rubrics are in [`tasks/`](tasks/), **committed before any run** —
the git history is the proof. Where we later found a flaw in our own task design
(T5's price cap made the criteria unsatisfiable; T2's first draft asked a
business to invoice itself), the amendment and its reason are committed too.

## Method

- The two controlled arms share harness, model (Opus 5), and prompt. **Only the
  browser backend differs.** The third arm changes the harness itself, so it is
  a reference point, not a controlled comparison.
- One run per arm per task, 15-minute cap. Human intervention limited to
  phone-approval auth and CAPTCHA — **all 15 runs needed zero**.
- Each arm is confined to its own tool at the harness level, so a run cannot
  silently escape into another arm's tooling.
- Aside's local memory is wiped before every Aside run, so each starts cold.
- Every run is screen-recorded, and each recording is checked against the
  wall-clock time and sampled for content. Where a recording is missing or
  incomplete, the run record says so explicitly (`recording.valid: false` plus
  the reason) and the session transcript — with the artifacts the run produced —
  stands as the evidence. We flag these rather than quietly reporting them.

Claude in Chrome was excluded up front: its extension refuses to open
naver.com and coupang.com at all — a built-in policy users cannot change —
which made most of these tasks impossible to start. It also refuses to read
such a page a human has already opened.

## What's here

- [`tasks/`](tasks/) — task definitions and rubrics (pre-registered)
- [`runs/`](runs/) — per-run records: time, tokens, tool calls, scoring, notes
- [`report/`](report/) — the full write-up, EN and KO
- [`scripts/`](scripts/) — the harness
- [`EVIDENCE.md`](EVIDENCE.md) — why these sites, and the claims we set out to test
- [`RUNORDER.md`](RUNORDER.md) — fixed arm order and run rules

Raw recordings, transcripts, and issued documents are **not** in the repo —
they contain personal data. The run records carry the measurements; the report
links to edited video.

## Limitations

One run per cell, an arbitrary 15-minute cap (most timeouts were still making
progress), and a reference arm whose token counts are not 1:1 comparable with
the controlled ones. The full list is in the
[report](report/RESULTS.md#limitations).

We publish results regardless of outcome. This one favored Aside in one mode
and not the other; had it gone the other way, it would be here too.

## License

MIT
