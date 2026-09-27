# Chronos pitch deck

12-slide deck for the IBM Bob 2.0 Hackathon submission. Each slide is a
standalone HTML file on a fixed 1280x720 (16:9) canvas; all of them share
[`styles.css`](styles.css).

## Files

| File | Slide |
| --- | --- |
| `slide-01.html` | Cover |
| `slide-02.html` | The Problem |
| `slide-03.html` | Our Approach (5-step loop) |
| `slide-04.html` | Architecture |
| `slide-05.html` | Bob in Action *(image)* |
| `slide-06.html` | Bug Catch #1 — clib-package.c NULL deref |
| `slide-07.html` | Bug Catch #2 — kopen.c heap overflow |
| `slide-08.html` | The Headline Number (30 → 0) |
| `slide-09.html` | Full Before/After *(image)* |
| `slide-10.html` | Why not one risk number |
| `slide-11.html` | Business Value & Roadmap |
| `slide-12.html` | Thank You / Team |

Output: **`chronos_pitch_deck.pdf`** — 12 pages, 960x540 pt each (exactly
16:9, i.e. 1280x720 px at 96 dpi).

## Images

Two files are referenced by name and must live in this directory:

| Expected filename | Used by | Frame | Currently holds |
| --- | --- | --- | --- |
| `PLACEHOLDER_bob_screenshot.png` | slide 5 | ~740x430 (1.7:1) | crop of `bob_sessions/chronos_clib_package_final.png` (the "Report on all 7 sites" audit table) |
| `PLACEHOLDER_comparison_chart.png` | slide 9 | ~740x400 (1.85:1) | copy of `demo/comparison.png` |

Both are stand-ins copied straight from the repo so the deck exports complete.
The slide-5 image is deliberately *not* the kopen.c capture used on slide 7 —
reusing the same file two slides in a row would repeat the same topic; the
7-sites audit table instead shows the breadth of the review (ties to the
"rigorous methodology" message on slide 10). It's a crop, not the raw
screenshot, since the raw capture is a near-square full-app window (928x982)
that would letterbox badly in the landscape frame:

```python
from PIL import Image
im = Image.open("bob_sessions/chronos_clib_package_final.png")
im.crop((0, 295, 928, 940)).save("demo/slides/PLACEHOLDER_bob_screenshot.png")
```

Overwrite either placeholder and re-run the build:

```powershell
copy bob_sessions\chronos_task03_clib_summary.png demo\slides\PLACEHOLDER_bob_screenshot.png
copy demo\comparison.png                          demo\slides\PLACEHOLDER_comparison_chart.png
python demo\slides\build_pdf.py
```

Landscape crops around 1.7:1 fill the frames best. If a file is missing, the
slide renders its `alt` text — a visible `[ PLACE ... HERE ]` marker — instead
of failing. Each `<img>` is preceded by an HTML comment naming the exact path.

## Building the PDF

```bash
python demo/slides/build_pdf.py
python demo/slides/build_pdf.py --keep-deck   # also leaves _deck.html for inspection
```

The script stitches the 12 slide bodies into a temporary `_deck.html` and
prints it in one pass, so no PDF-merging library is needed. It picks a backend
automatically:

1. **Playwright**, if importable — not installed here.
2. **Headless Chrome/Edge** via `--print-to-pdf` — the path used in this repo.
   Requires only an installed browser.

Page geometry comes from `@page { size: 1280px 720px; margin: 0 }` in
`styles.css`; `print-color-adjust: exact` keeps the dark slides dark.

## Design notes

- Palette: `--purple #765186`, `--ink #1a1420` (cover / headline-number /
  closing slides), `--paper #f7f5f9` (content slides), single accent
  `--accent #4ECDC4`. `--accent-ink #0f7a72` is the same accent at text
  contrast on light backgrounds; `--warn #FF6B6B` is reserved for "before"
  diff lines only.
- Type: Poppins via Google Fonts CDN, with a `Segoe UI` fallback stack so the
  export still works offline. Titles 44–56px/800, body ≥22px.
- Icons are inline SVG rather than a Font Awesome CDN link, so the PDF export
  never depends on network availability at print time.
- The three background blobs are placed identically on every slide
  (`.blob--tr`, `.blob--bl`, `.blob--mid`) — that repetition is the template's
  signature.
- Code blocks use VS Code Dark+ token colors at 19–20px, capped at 8 lines.
