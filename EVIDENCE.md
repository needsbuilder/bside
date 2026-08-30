# Evidence: why these tasks

## The debate (Aug 2026, Korean Threads)

This benchmark exists to answer a live, unresolved debate in the Korean dev
community about whether the Aside browser meaningfully outperforms existing
browser-automation setups.

| Thread | Core claim / question | Engagement |
|--------|----------------------|------------|
| [joshproductletter](https://www.threads.com/@joshproductletter/post/DcgXZ7YiY84) | "claude-in-chrome과 Aside의 브라우저 자동화가 그렇게 큰 차이가 많이 나나요? (직접 보면 그렇게 잘 모르겠던데)" — *"Is the gap between claude-in-chrome and Aside really that big? I can't tell from using them."* Replies float rumors: Aside uses fewer tokens, feels faster. | 32 replies |
| [lilmgenius](https://www.threads.com/@lilmgenius/post/DcdirDzCd9S) | "익스텐션이나 개발자 도구는 매번 페이지 전체를 복사해서 넘겨받는 스냅샷 방식... Aside는 그 몇 초 사이에 변경돼도 바로 취소해서 다시 읽습니다" — *"Extensions/devtools are snapshot-based; Aside reacts to DOM changes in real time, and can judge occlusion before compositing."* | 49 likes, 26 replies |
| chris.jp.kim (2026-08-20, Threads) | "이미 claude랑 gpt 크롬익스텐션으로 다 되던거 아닌가요..? 개인적으로는 에이전트한테 cli로 쥐어줄때 playwright보다 훨씬 만족" — *"Wasn't all this already possible with Chrome extensions? Though handing the CLI to an agent beats Playwright in my experience."* | 38 likes, 32 replies |

Two commenters explicitly asked for this exact artifact:

> "숫자로 나오는 벤치 말고, 실 사례로 비교해서 누가 더 빠른가 동영상으로 올려주면 한 방에 오... 나올 거 같은데" — *"Not abstract benchmark numbers — compare real cases on video and everyone will instantly get it."* (korean_money_printer)

> "실제 반복 작업으로 비교해보고 싶네요" — *"I'd like to see them compared on real repetitive tasks."* (jaeminyx_dev)

## Unverified claims we test

| # | Claim | Source | Tested by |
|---|-------|--------|-----------|
| 1 | Aside uses fewer tokens than alternatives | rumor in joshproductletter replies (hearsay, two commenters) | token metric (CLI arms) |
| 2 | Aside feels faster | joshproductletter replies (subjective) | wall-clock metric, all tasks |
| 3 | "Works where Playwright / extensions fail" (hard sites) | lilmgenius ("안티봇 패턴을 뚫어주는 문제해결 능력이 해자"), multiple replies | T1–T3 |
| 4 | Aside standalone is worth installing at all | chris.jp.kim thread's core question | `aside-solo` reference arm |

## Site selection evidence

Sites were not chosen at whim — each has public, independent reports of
breaking conventional automation:

| Task | Site | Public failure evidence |
|------|------|------------------------|
| T1 | Naver Blog (SmartEditor) | Editor built on Naver's deprecated Jindo JS framework ([namu.wiki](https://namu.wiki/w/%EC%8A%A4%EB%A7%88%ED%8A%B8%EC%97%90%EB%94%94%ED%84%B0)); iframe handling issues ([naver/smarteditor2#226](https://github.com/naver/smarteditor2/issues/226)) |
| T2 | Hometax (홈택스) | Legacy popup-driven UI plus mandatory security software; Korea's tax portal is a long-standing automation graveyard for exactly these reasons. Login is done by a human before the run — credential entry is never automated in this benchmark. |
| T3 | Naver Map/Place | Dual-iframe structure (searchIframe/entryIframe) trips Selenium ([Inflearn Q&A](https://www.inflearn.com/community/questions/665581)); Naver runs an in-house bot-blocking system with irregular enforcement ([hashscraper](https://blog.hashscraper.com/posts/reasons-why-naver-crawling-is-blocked-and-solutions?locale=ko)) |

T3 is a real errand: the author actually travels to this meeting the next day,
and the lunch recommendation is used as-is.

## Method

- The three controlled arms run under Claude Code with the same model (Opus 5)
  and the identical prompt block from `tasks/`. Only the browser backend
  differs. A fourth **reference arm** (`aside-solo`) runs Aside's own agent
  loop on the same model and prompt — not a controlled comparison, but the
  product's intended form; its token use is not measurable from outside.
- Each arm is confined to its own tool: the other arms' CLIs are denied at the
  harness level, so a run cannot silently escape into another arm's tooling.
- Every run is screen-recorded. Before the run, recording permission is
  verified with a probe capture; after the run, the recording's duration is
  checked against the wall clock. **A run without a valid recording does not
  count and is re-run** — except when the arm is blocked before any page loads,
  in which case nothing appears on screen and the session transcript stands as
  the evidence. Such runs are marked in `runs/**/metrics.json` with
  `recording.valid: false` and the reason.
- One run per arm per task. Only infrastructure failures (tool crash, network)
  may be retried, and retries are recorded.

## Ground rules

- All accounts are our own; runs are small-scale, read-heavy, and stop before
  payment/booking confirmation. Mass actions are never performed.
- Getting blocked **is** a data point. We do not research, apply, or document
  anti-bot circumvention techniques.
- Personal information is blurred in all published video/screenshots; issued
  documents are never published.

## Commitment

We publish results **regardless of outcome** — whether Aside wins, loses, or
it's a wash. Task definitions and rubrics are committed before any run; the git
history of this repository is the proof.
