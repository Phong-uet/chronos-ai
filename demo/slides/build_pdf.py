"""Export the Chronos slide deck (slide-01.html .. slide-12.html) to a single PDF.

Two backends, tried in this order:

  1. Playwright (``pip install playwright && playwright install chromium``)
     -- used automatically if it is importable.
  2. Headless Chrome / Edge via ``--print-to-pdf`` -- needs nothing installed
     beyond a browser you already have. This is the default path in this
     environment, because neither Playwright nor Puppeteer is present.

Both backends first stitch the 12 slide bodies into one temporary deck file
(``_deck.html``, written next to the slides so ``styles.css`` and the image
placeholders resolve), then print it in a single pass. That yields a 12-page
PDF with no PDF-merging dependency at all.

Usage:
    python demo/slides/build_pdf.py
    python demo/slides/build_pdf.py --keep-deck     # leave _deck.html on disk
"""

from __future__ import annotations

import argparse
import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import List, Optional, Tuple

SLIDES_DIR = Path(__file__).resolve().parent
OUT_PDF = SLIDES_DIR / "chronos_pitch_deck.pdf"
DECK_HTML = SLIDES_DIR / "_deck.html"

# Images the deck expects the user to drop in before the final export.
EXPECTED_IMAGES = [
    ("PLACEHOLDER_bob_screenshot.png", "slide 5", "copy of a capture from bob_sessions/"),
    ("PLACEHOLDER_comparison_chart.png", "slide 9", "copy of demo/comparison.png"),
]

BODY_RE = re.compile(r"<body[^>]*>(.*?)</body>", re.DOTALL | re.IGNORECASE)

DECK_HEAD = """<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Chronos - IBM Bob 2.0 Hackathon Pitch Deck</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Poppins:wght@400;500;600;700;800&display=swap" rel="stylesheet">
<link rel="stylesheet" href="styles.css">
<style>
  /* the combined deck prints back-to-back: no screen gutters */
  body { padding: 0; background: #fff; }
  .slide { margin: 0 auto; box-shadow: none; }
</style>
</head>
<body>
"""

DECK_TAIL = """</body>
</html>
"""


def slide_files() -> List[Path]:
    files = sorted(SLIDES_DIR.glob("slide-*.html"))
    if not files:
        sys.exit("[!] No slide-*.html files found in %s" % SLIDES_DIR)
    return files


def check_images() -> None:
    missing = [(n, w, h) for n, w, h in EXPECTED_IMAGES if not (SLIDES_DIR / n).is_file()]
    if not missing:
        print("[*] Both slide images present.")
        return
    print("[!] Missing image(s) -- the PDF will show the placeholder alt text instead:")
    for name, where, hint in missing:
        print("[!]   %-38s (%s) <- %s" % (name, where, hint))


def build_deck(files: List[Path]) -> Path:
    """Concatenate every slide's <body> content into one printable HTML file."""
    parts: List[str] = [DECK_HEAD]
    for path in files:
        html = path.read_text(encoding="utf-8")
        match = BODY_RE.search(html)
        if not match:
            sys.exit("[!] %s has no <body> section" % path.name)
        parts.append("<!-- ===== %s ===== -->\n" % path.name)
        parts.append(match.group(1).strip())
        parts.append("\n\n")
    parts.append(DECK_TAIL)
    DECK_HTML.write_text("".join(parts), encoding="utf-8")
    print("[*] Stitched %d slides into %s" % (len(files), DECK_HTML.name))
    return DECK_HTML


# --------------------------------------------------------------------------
# backend 1: playwright
# --------------------------------------------------------------------------

def export_with_playwright(deck: Path) -> bool:
    try:
        from playwright.sync_api import sync_playwright
    except ImportError:
        return False

    print("[*] Backend: Playwright (Chromium)")
    with sync_playwright() as p:
        browser = p.chromium.launch()
        page = browser.new_page(viewport={"width": 1280, "height": 720})
        page.goto(deck.as_uri(), wait_until="load")
        try:
            page.wait_for_function("document.fonts.ready.then(() => true)", timeout=8000)
        except Exception:
            pass  # web fonts unavailable offline; the CSS fallback stack takes over
        page.pdf(
            path=str(OUT_PDF),
            width="1280px",
            height="720px",
            print_background=True,
            margin={"top": "0", "right": "0", "bottom": "0", "left": "0"},
        )
        browser.close()
    return True


# --------------------------------------------------------------------------
# backend 2: headless Chrome / Edge CLI
# --------------------------------------------------------------------------

def find_browser() -> Optional[Tuple[str, str]]:
    candidates = [
        ("Chrome", r"C:\Program Files\Google\Chrome\Application\chrome.exe"),
        ("Chrome", r"C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"),
        ("Edge", r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"),
        ("Edge", r"C:\Program Files\Microsoft\Edge\Application\msedge.exe"),
    ]
    for name, path in candidates:
        if os.path.isfile(path):
            return name, path
    for name, exe in (("Chrome", "google-chrome"), ("Chrome", "chromium"), ("Edge", "microsoft-edge")):
        found = shutil.which(exe)
        if found:
            return name, found
    return None


def export_with_chrome(deck: Path) -> bool:
    browser = find_browser()
    if browser is None:
        return False
    name, exe = browser
    print("[*] Backend: headless %s (--print-to-pdf)" % name)

    # An isolated profile keeps this from attaching to an already-running browser.
    profile = tempfile.mkdtemp(prefix="chronos-deck-")
    cmd = [
        exe,
        "--headless=new",
        "--disable-gpu",
        "--hide-scrollbars",
        "--user-data-dir=%s" % profile,
        "--no-first-run",
        "--no-default-browser-check",
        "--run-all-compositor-stages-before-draw",
        "--virtual-time-budget=8000",
        "--no-pdf-header-footer",
        "--print-to-pdf=%s" % OUT_PDF,
        deck.as_uri(),
    ]
    try:
        proc = subprocess.run(cmd, capture_output=True, text=True, timeout=180)
    finally:
        shutil.rmtree(profile, ignore_errors=True)

    if not OUT_PDF.is_file():
        print("[!] %s exited %d without producing a PDF" % (name, proc.returncode))
        print((proc.stderr or proc.stdout or "").strip()[:2000])
        return False
    return True


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--keep-deck", action="store_true",
                    help="keep the stitched _deck.html for inspection")
    args = ap.parse_args()

    files = slide_files()
    print("[*] Slides: %s" % ", ".join(f.name for f in files))
    check_images()

    deck = build_deck(files)
    if OUT_PDF.exists():
        OUT_PDF.unlink()

    try:
        ok = export_with_playwright(deck) or export_with_chrome(deck)
    finally:
        if not args.keep_deck:
            DECK_HTML.unlink(missing_ok=True)

    if not ok:
        print("[!] No PDF backend available.")
        print("[!] Install one of:")
        print("[!]   pip install playwright && playwright install chromium")
        print("[!]   or install Google Chrome / Microsoft Edge")
        return 1

    size_kb = OUT_PDF.stat().st_size / 1024
    print("[+] Wrote %s (%d pages expected, %.1f KB)" % (OUT_PDF, len(files), size_kb))
    return 0


if __name__ == "__main__":
    sys.exit(main())
