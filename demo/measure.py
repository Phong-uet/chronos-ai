#!/usr/bin/env python3
"""
measure.py - Standalone before/after measurement for the Chronos modernization demo.

Point it at ANY directory of C/C++ code, it re-runs the existing analyzer/ feature
extraction on every file it finds and emits a comparison table as JSON + Markdown.

    python demo/measure.py --input demo/samples/before --label before \
        --output demo/before.json --markdown demo/before.md

The script deliberately skips the clustering step and the HTML report: it only
needs analyzer.scanner + analyzer.features, so it stays usable on whatever
directory IBM Bob writes its modernized output into.
"""

import argparse
import json
import math
import sys
import time
from pathlib import Path

# Make the repo root importable when this script is run from anywhere.
REPO_ROOT = Path(__file__).resolve().parent.parent
if str(REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(REPO_ROOT))

from analyzer.scanner import scan_source_files
from analyzer.features import extract_file_features


# ---------------------------------------------------------------------------
# Risk score
# ---------------------------------------------------------------------------
# The core analyzer emits categorical risks (risks.py) but no single number, so
# the demo defines one here. Every component saturates via 1 - exp(-v/scale):
# monotonic, bounded to [0, 100], and it keeps differences visible instead of
# hard-clipping large legacy files to an identical value.
#
# Keep this table frozen between the before and after runs - the whole point of
# the demo is that both sides are scored by the identical formula.
RISK_WEIGHTS = {
    # component name      -> (weight, saturation scale)
    "unpaired_allocations": (0.20, 5.0),
    "manual_allocations":   (0.15, 40.0),
    "raw_pointer_count":    (0.18, 300.0),
    "pointer_arithmetic":   (0.12, 50.0),
    "void_pointers":        (0.08, 20.0),
    "cyclomatic":           (0.15, 200.0),
    "goto_count":           (0.05, 10.0),
    "legacy_crypto":        (0.04, 5.0),
    "precision_loss":       (0.03, 20.0),
}

RISK_FORMULA_VERSION = "chronos-demo-risk-v2"


def _alloc_total(f):
    return (f.get("malloc_count", 0) + f.get("calloc_count", 0)
            + f.get("realloc_count", 0) + f.get("new_count", 0))


def _free_total(f):
    return f.get("free_count", 0) + f.get("delete_count", 0)


def risk_components(features):
    """Raw (pre-weighting) input value for each risk component."""
    return {
        # Allocations with no matching free in the same file: the leak signal.
        "unpaired_allocations": max(0, _alloc_total(features) - _free_total(features)),
        # Every manual alloc/free call site, paired or not. This is the surface
        # a modernization actually removes (RAII, smart pointers, containers),
        # so without it a file that drops 14 mallocs to 4 would score the same.
        "manual_allocations": _alloc_total(features) + _free_total(features),
        "raw_pointer_count": features.get("raw_pointer_count", 0),
        "pointer_arithmetic": features.get("pointer_arithmetic_count", 0),
        "void_pointers": features.get("void_pointer_count", 0),
        "cyclomatic": features.get("cyclomatic_complexity", 0),
        "goto_count": features.get("goto_count", 0),
        "legacy_crypto": features.get("legacy_crypto_count", 0),
        "precision_loss": features.get("precision_loss_count", 0),
    }


def compute_risk_score(features):
    """Weighted 0-100 risk score. Higher = more legacy / memory-unsafe."""
    raw = risk_components(features)
    score = 0.0
    breakdown = {}
    for name, (weight, scale) in RISK_WEIGHTS.items():
        value = float(raw[name])
        sub = 100.0 * (1.0 - math.exp(-value / scale))
        breakdown[name] = {
            "value": value,
            "subscore": round(sub, 2),
            "weight": weight,
            "contribution": round(weight * sub, 2),
        }
        score += weight * sub
    return round(score, 2), breakdown


# ---------------------------------------------------------------------------
# Measurement
# ---------------------------------------------------------------------------
SOURCE_EXTENSIONS = {".c", ".cpp", ".cc", ".cxx"}


def measure_directory(input_dir, arch=64, sources_only=False):
    """Run feature extraction over every C/C++ file under input_dir.

    sources_only drops headers from the scan. The compile-check staging puts
    third-party companion headers (commondefs.h and friends) next to the gold
    samples so each one builds on its own; those headers are build scaffolding,
    not modernization targets, and would otherwise inflate the baseline.
    """
    root = Path(input_dir).resolve()
    source_files = scan_source_files(root)
    if sources_only:
        source_files = [p for p in source_files if p.suffix.lower() in SOURCE_EXTENSIONS]

    rows = []
    problems = []

    for fpath in source_files:
        rel = fpath.relative_to(root).as_posix()
        try:
            rec = extract_file_features(fpath, arch=arch)
        except Exception as exc:  # never let one bad file kill the whole run
            problems.append({
                "file": rel,
                "stage": "extract_file_features",
                "error": "{}: {}".format(type(exc).__name__, exc),
            })
            continue

        f = rec["features"]
        score, breakdown = compute_risk_score(f)

        for w in rec.get("warnings", []):
            problems.append({"file": rel, "stage": "parse", "error": w})

        rows.append({
            "file": rel,
            "file_name": rec["file_name"],
            "abs_path": rec["file_path"],
            "parser_type": rec["parser_type"],
            "loc": f.get("code_lines", 0),
            "total_lines": f.get("total_lines", 0),
            "cyclomatic_complexity": f.get("cyclomatic_complexity", 0),
            "raw_pointer_count": f.get("raw_pointer_count", 0),
            "pointer_arithmetic_count": f.get("pointer_arithmetic_count", 0),
            "void_pointer_count": f.get("void_pointer_count", 0),
            "malloc_count": _alloc_total(f),
            "free_count": _free_total(f),
            "unpaired_allocations": max(0, _alloc_total(f) - _free_total(f)),
            "function_count": f.get("function_count", 0),
            "goto_count": f.get("goto_count", 0),
            "risk_score": score,
            "risk_breakdown": breakdown,
        })

    rows.sort(key=lambda r: r["risk_score"], reverse=True)
    return rows, problems


TABLE_COLUMNS = [
    ("file", "File"),
    ("loc", "LOC"),
    ("cyclomatic_complexity", "Cyclomatic"),
    ("raw_pointer_count", "Raw ptr"),
    ("malloc_count", "Alloc"),
    ("free_count", "Free"),
    ("risk_score", "Risk score"),
]

SUM_KEYS = [
    "loc", "total_lines", "cyclomatic_complexity", "raw_pointer_count",
    "pointer_arithmetic_count", "void_pointer_count", "malloc_count",
    "free_count", "unpaired_allocations", "function_count", "goto_count",
]


def totals_of(rows):
    """Aggregate row used as the headline number in the comparison."""
    agg = {k: sum(r[k] for r in rows) for k in SUM_KEYS}
    agg["file_count"] = len(rows)
    # Risk score is bounded 0-100 per file, so the fleet-level number is a mean.
    agg["risk_score"] = round(sum(r["risk_score"] for r in rows) / len(rows), 2) if rows else 0.0
    return agg


def render_markdown(payload):
    rows = payload["files"]
    t = payload["totals"]
    lines = [
        "# Measurement: {}".format(payload["label"]),
        "",
        "- Source directory: `{}`".format(payload["input_dir"]),
        "- Files measured: **{}**".format(len(rows)),
        "- Generated: {}".format(payload["generated_at"]),
        "- Risk formula: `{}`".format(payload["risk_formula_version"]),
        "",
        "| " + " | ".join(h for _, h in TABLE_COLUMNS) + " |",
        "| " + " | ".join("---" for _ in TABLE_COLUMNS) + " |",
    ]
    for r in rows:
        lines.append("| " + " | ".join(str(r[k]) for k, _ in TABLE_COLUMNS) + " |")

    lines.append("| **TOTAL / AVG** | " + " | ".join([
        str(t["loc"]),
        str(t["cyclomatic_complexity"]),
        str(t["raw_pointer_count"]),
        str(t["malloc_count"]),
        str(t["free_count"]),
        "**{}**".format(t["risk_score"]),
    ]) + " |")
    lines.append("")
    lines.append("> On the TOTAL row the risk score is the **mean** across files; "
                 "every other column is a sum.")

    if payload["problems"]:
        lines += ["", "## Extraction problems", "", "| File | Stage | Detail |", "| --- | --- | --- |"]
        for p in payload["problems"]:
            lines.append("| {} | {} | {} |".format(p["file"], p["stage"], p["error"]))

    return "\n".join(lines) + "\n"


def parse_args():
    ap = argparse.ArgumentParser(
        description="Measure legacy-risk metrics for any directory of C/C++ code."
    )
    ap.add_argument("--input", "-i", required=True,
                    help="Directory of C/C++ code to measure (the before or after tree)")
    ap.add_argument("--output", "-o", default=None,
                    help="Path for the JSON result (default: demo/<label>.json)")
    ap.add_argument("--markdown", "-m", default=None,
                    help="Path for the Markdown table (default: alongside the JSON)")
    ap.add_argument("--label", "-l", default=None,
                    help="Label for this measurement, e.g. 'before' or 'after'")
    ap.add_argument("--arch", type=int, choices=[32, 64], default=64,
                    help="Arch bitness for struct padding estimation (default: 64)")
    ap.add_argument("--sources-only", action="store_true",
                    help="Measure only .c/.cpp/.cc/.cxx and skip headers, so companion "
                         "headers staged for the compile check do not enter the baseline")
    return ap.parse_args()


def main():
    args = parse_args()
    input_dir = Path(args.input).resolve()
    if not input_dir.is_dir():
        print("[!] Not a directory: {}".format(input_dir), file=sys.stderr)
        sys.exit(1)

    label = args.label or input_dir.name
    out_json = Path(args.output) if args.output else Path(__file__).resolve().parent / "{}.json".format(label)
    out_md = Path(args.markdown) if args.markdown else out_json.with_suffix(".md")

    print("[*] Measuring '{}' in: {}".format(label, input_dir))
    rows, problems = measure_directory(input_dir, arch=args.arch, sources_only=args.sources_only)
    if not rows:
        print("[!] No C/C++ files found under {}".format(input_dir), file=sys.stderr)
        sys.exit(1)

    payload = {
        "label": label,
        "input_dir": str(input_dir),
        "generated_at": time.strftime("%Y-%m-%d %H:%M:%S"),
        "sources_only": args.sources_only,
        "risk_formula_version": RISK_FORMULA_VERSION,
        "risk_weights": {k: {"weight": w, "scale": s} for k, (w, s) in RISK_WEIGHTS.items()},
        "totals": totals_of(rows),
        "files": rows,
        "problems": problems,
    }

    out_json.parent.mkdir(parents=True, exist_ok=True)
    out_json.write_text(json.dumps(payload, indent=2), encoding="utf-8")
    out_md.write_text(render_markdown(payload), encoding="utf-8")

    print("[+] {} files measured -> {}".format(len(rows), out_json))
    print("[+] Markdown table       -> {}".format(out_md))
    if problems:
        print("[!] {} extraction problem(s) recorded in the JSON 'problems' field".format(len(problems)))
    print()
    print(render_markdown(payload))


if __name__ == "__main__":
    main()
