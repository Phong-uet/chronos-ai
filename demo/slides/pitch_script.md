# Chronos — Pitch Video Script

12 slides, ~3:45–4:00 total. Read straight through when recording; no ad-libbing needed.

**General delivery notes:** speak ~10-15% slower than normal conversation — this is a
recording, viewers can't ask you to repeat. Keep an even pace, and land on the numbers
(30 → 0, 25.72 → 3.89, r ≈ 0.30). Slide 8 is the one moment that needs real silence — see
below.

---

### Slide 1 — Cover (0:00–0:05)
> "Hi everyone — this is Chronos, a project that uses IBM Bob to modernize legacy C code
> for memory safety."

*(No need to say the team name out loud — it's already on the slide.)*

---

### Slide 2 — The Problem (0:05–0:20)
> "A lot of financial and scientific-computing systems still run on C code that's decades
> old. Manual security audits can't keep up at a scale of millions of lines. And because
> nobody wants to risk breaking logic that already works, teams often just... don't touch
> it. We call that 'modernization paralysis.'"

---

### Slide 3 — Our Approach (0:20–0:40)
> "Our approach is a closed measurement loop with five steps: measure a baseline with
> tree-sitter, target the highest-risk files, let IBM Bob modernize them under strict
> scope constraints, re-measure with the exact same tool, and compare the impact. This
> isn't 'trust the AI' — it's proof, in numbers, before and after."

---

### Slide 4 — Architecture (0:40–0:55)
> "The whole pipeline is six stages: from the legacy codebase, through a tree-sitter
> static analyzer that extracts 52 features per file, domain classification and risk
> scoring, selecting the highest-risk files, IBM Bob modernizing them, and re-analyzing
> to close the loop. None of it depends on subjective judgment."

---

### Slide 5 — Bob in Action (0:55–1:10)
> "In practice, Bob modernized 7 files — but always inside a tightly scoped boundary:
> only touch the files it was given, never the analyzer, never the measurement baseline.
> This screenshot is from a real session, where Bob audited all 7 allocation sites in
> clib-package.c."

---

### Slide 6 — Bug Catch #1 (1:10–1:30)
> "Here's a concrete example: in clib-package.c, Bob found a bug that would guarantee a
> crash on any network failure. The original code read `res->data` before checking
> whether `res` was NULL — so every failed request would crash the program. Bob moved
> the NULL check ahead of the read, and the bug disappeared."

---

### Slide 7 — Bug Catch #2 (1:30–1:55)
> "But here's the more important part: this next bug wasn't in our original request at
> all — Bob found it on its own. In kopen.c, the loop reading the HTTP header wrote into
> a 64-kilobyte buffer with no upper bound — a malicious server could make it write one
> byte past the allocation. Bob added the missing bounds check, without being asked."

---

### Slide 8 — The Headline Number (1:55–2:10)
**⏸ Pause for 3–4 seconds the moment this slide appears — say nothing, let the number
land.**
> "Thirty unguarded allocation sites. Down to zero. Completely, across all 7 files."

*(This is the "mic drop" moment of the whole video — don't cut to the next slide right
after this line. Hold it for another second or two.)*

---

### Slide 9 — Full Before/After (2:10–2:30)
> "Re-measuring everything with the exact same analyzer: both unguarded and unpaired
> allocations dropped 100%. The overall risk score — a Likelihood-times-Impact model —
> fell from 25.72 to 3.89, almost down to zero, while the code only grew by 5.8%."

---

### Slide 10 — Why Not One Risk Number (2:30–2:55)
> "So why not just use one risk number? Because adding defensive NULL checks actually
> increases cyclomatic complexity — and Shin and Williams' 2010 study found complexity
> only weakly correlates with real vulnerabilities, at about r equals 0.30. So instead of
> blending everything into one score, we split Likelihood — from unguarded allocation
> counts — from Impact — from pointer density and code scope."

---

### Slide 11 — Business Value & Roadmap (2:55–3:10)
> "Who benefits from this? Banks, fintech companies, and scientific-computing teams
> maintaining legacy C. Our next steps are closing the remaining gap in
> clib-package.c, scaling this to the full mined dataset, and integrating it as a CI
> gate."

---

### Slide 12 — Thank You (3:10–3:20)
> "Thanks for watching. This is Chronos — team bubududu, built with IBM Bob."

*(Hold the repo link on screen for another 2-3 seconds after this line before cutting,
so viewers have time to grab it.)*

---

**Total speaking time:** ~3:20, plus the slide-8 pause and lead-in/out → the finished
video should land around **3:45–4:00**.
