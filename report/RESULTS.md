# Bside — Benchmarks for Aside: Results

> Independent project. Not affiliated with, endorsed, or sponsored by Aside / at inc.

On 30–31 August 2026 we ran five real Korean-web errands — the kind that are
known to break automation — through three browser-automation setups. Tasks and
rubrics were committed before any run, and the results are published as they
came out.

---

## TL;DR

**The same browser produced opposite outcomes depending on how you use it.**
Aside driven by its own agent went 5-for-5 and was the fastest arm on every
task. The same Aside handed to a coding agent as a CLI went 1-for-5 — worse
than Playwright.

---

## Setup

| Arm | Configuration | Role |
|---|---|---|
| **Playwright** | Claude Code + Opus 5 → `@playwright/cli` → the user's real Chrome | controlled |
| **Aside CLI** | Claude Code + Opus 5 → `aside` CLI → Aside browser | controlled |
| **Aside solo** | Aside's own agent (prompt typed into its browser UI), same Opus 5 | reference |

The first two share harness, model, and prompt; **only the browser backend
differs**. The third changes the harness itself, so it is not a controlled
comparison — it shows what the product does in its intended form.

One run per arm per task, 15-minute cap. Human intervention was limited to
phone-approval auth and CAPTCHA; **all 15 runs needed zero intervention**.
Every run was screen-recorded.

Claude in Chrome was excluded up front: its extension refuses to open
naver.com and coupang.com at all (a built-in policy users cannot change), which
made three of the five tasks impossible to even start. It also refuses to read
such a page that a human has already opened.

---

## Results

| Task | Playwright | Aside CLI | Aside solo |
|---|---|---|---|
| T1 Publish an SEO-structured Naver blog post | ✅ 661s | ⏰ 900s (0/4) | ✅ **475s** |
| T2 Draft a tax invoice on Hometax | ✅ 384s | ✅ 370s | ✅ **176s** |
| T3 Find lunch near a real meeting (Naver Map) | ✅ 760s | ⏰ 899s (1/4) | ✅ **734s** |
| T4 Match government grant programs | ⏰ 903s (1/3) | ⏰ 903s (1/3) | ✅ **296s** |
| T5 Cross-check rental listings on two sites | ⏰ 904s (1/3) | ⏰ 900s (1/3) | ✅ **869s** |
| **Record** | 3–2 | 1–4 | **5–0** |

| Totals across 5 runs | Playwright | Aside CLI | Aside solo |
|---|---|---|---|
| Successes | 3 | 1 | **5** |
| Tokens | 47,621,281 | 30,495,989 | **15,733,845** |
| Tool calls | 295 | 243 | **221** |
| Human interventions | 0 | 0 | 0 |

---

## What actually happened

### T1 — Publishing to Naver Blog under SEO constraints

Six constraints (keyword in title, 1,500–2,000 characters, alternating
text/photo layout, 3+ subheadings, 5 tags, public publish), published for real.

**Playwright (661s) and Aside solo (475s) both published**, and both posts met
every constraint when measured the same way (1,890 and 1,849 characters,
3 photos, 3 and 4 subheadings, 5 tags each).

**Aside CLI died at photo attachment.** Clicking the photo button opened a
macOS native file dialog — an OS-level surface browser automation cannot
reach — and it burned the full 900 seconds unable to escape. It even located
the right API (`prepareForPotentialFileChooser`), but that has to be armed
*before* the dialog appears.

Playwright hit the same wall differently: when the file API
(`DOM.setFileInputFiles`) was blocked in the extension relay, it **never
pressed the button** and dragged the files into the editor instead. File
attachment is blocked for both tools. The difference was whether the agent
looked for a way around.

### T2 — Drafting a Hometax tax invoice (stopping before "issue")

**The only task all three arms completed.** All three cleared the branch-office
selection popup and picked the head office.

More interesting: all three made the same judgment call. Hometax does not
auto-fill the buyer's company name after validating the business number, and
all three **refused to guess values they weren't given** and asked instead. One
said explicitly that a tax invoice is a legal document, so guessing is unsafe;
another first checked whether the counterparty was saved in Hometax's address
book.

Note that the arm that got trapped by a file dialog in T1 handled this modal
without trouble — **an in-page modal and an OS dialog are entirely different
obstacles.**

### T3 — Finding lunch for a real meeting

The author actually had a meeting in Yongin the next day, so the errand was
real.

Playwright (760s) and Aside solo (734s) both finished and **independently
picked the same restaurant** (one minute's walk from the meeting), which makes
each a check on the other. Playwright computed walking distance down to step
counts and crossings; Aside solo attached screenshots of the route and the
place page as evidence.

Aside CLI got through Naver Map's nested iframes and opened detail pages, but
ran out of time extracting data. It wasn't blocked — it was slow.

### T4 — Matching government grant programs

**Both controlled arms failed here.** Each searched both portals and shortlisted
candidates, then spent the remaining time **downloading PDF and HWP attachments
and extracting text** to pin down exact funding amounts. The bottleneck was
document parsing, not browser work.

Aside solo finished the same task in **296 seconds**. It resolved the amounts
from the announcement pages instead of descending into attachments, filled all
seven columns for five programs, and ranked them with reasons — including why
it excluded four others (requires a referral letter from a national research
university, closed-invitation program, restricted to another municipality,
sector-limited).

### T5 — Cross-checking rental listings

**Our task design was wrong.** With a ₩10M deposit and ₩2M monthly cap, no
three-month two-room officetel exists near Gangnam Station; the cheapest we
found was ₩2.5M/mo on Naver and ₩2.6M/mo on Zigbang. The rubric item requiring
"five listings that meet the conditions" was therefore unachievable for every
arm and is **excluded from scoring**. That's our error, not the agents'.

Both controlled arms timed out before completing the table — Playwright while
working out that Zigbang's short-stay service is priced weekly, Aside CLI while
reverse-engineering Zigbang's internal API.

Only Aside solo (869s) finished, and it did two things worth noting. It
**confirmed that nothing meets the criteria** and marked each listing's failing
field rather than inventing qualifying results. And it caught **the same unit
listed on both sites at different prices** (₩4.5M/₩3.8M on Naver vs
₩4.0M/₩3.6M on Zigbang), advising which side to contact.

---

## The claims we set out to test

| Claim | Source | Verdict |
|---|---|---|
| Aside uses fewer tokens | hearsay in thread replies | **Conditionally true.** Solo used 15.7M across five runs vs Playwright's 47.6M — over 10× on some tasks. But the harness differs, so it is not a controlled comparison. Between the controlled arms (Aside CLI 30.5M vs Playwright 47.6M) the gap narrows to 1.6×. |
| Aside is faster | subjective reports | **True for solo mode.** Fastest arm on all five tasks. Not true for CLI mode, which led only on the one task it completed. |
| It works where existing tools fail | "breaking anti-bot patterns is the moat" | **Not observed here.** Zero CAPTCHA or bot-block encounters across 15 runs. What separated the arms was file dialogs, document parsing, and crossing structurally different sites — not anti-bot defenses. |
| Is Aside worth using standalone | the core question of the debate | **In this scope, yes** — and handing it to a coding agent as a CLI actively hurt. |

---

## Limitations

Stated plainly.

- **One run per cell.** Agent runs vary a lot, and several results clustered
  right at the timeout (899–904s) could flip on a re-run.
- **The 15-minute cap is arbitrary.** Most timeouts were still making progress,
  not stuck. A 30-minute cap would likely change the record.
- **Aside solo is not a controlled comparison.** Different harness means
  different system prompt and context construction, so token counts are not
  1:1 comparable.
- **Aside's memory effect was not measured.** To keep runs independent, Aside's
  local memory was wiped before every Aside run (cold start). Whether repeated
  use improves results needs a separate experiment.
- **We designed the tasks, and some flaws surfaced during the runs** — T5's
  price cap, T2's first design (a business cannot invoice itself). Every
  amendment and its reason is in the commit history.
- **One recording is incomplete.** In T3 Aside solo, display sleep cut the
  recording at 61% (cause since fixed). That run's evidence is its session
  transcript and the screenshots the agent saved.
- **The T4 Aside CLI run delegated to `aside exec` mid-way.** Tokens spent
  inside that delegation are not captured in the Claude Code transcript, so
  that cell's token count may be undercounted.

---

## Reproducing

- Task definitions and rubrics: [`tasks/`](../tasks/) — committed before any run (see git history)
- Fixed arm order: [`RUNORDER.md`](../RUNORDER.md)
- Per-run records: [`runs/`](../runs/) — time, tokens, tool calls, scoring, notes
- Harness: [`scripts/`](../scripts/)
- Site selection evidence and method: [`EVIDENCE.md`](../EVIDENCE.md)
