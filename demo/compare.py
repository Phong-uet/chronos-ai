#!/usr/bin/env python3
"""
compare.py - Turn two measure.py results into the before/after story.

    python demo/compare.py --before demo/before.json --after demo/after.json \
        --output demo/comparison.json --markdown demo/comparison.md \
        --chart demo/comparison.png

Files are matched by their path relative to each measured root, so the
modernized tree only has to keep the same layout (and may change extensions,
e.g. kopen.c -> kopen.cpp, which is matched by stem as a fallback).
"""

import argparse
import json
import sys
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

# Metrics shown in the table and the chart. Every one of them is "lower is
# better", so a positive reduction percentage always means an improvement.
METRICS = [
    ("loc", "LOC"),
    ("cyclomatic_complexity", "Cyclomatic complexity"),
    ("raw_pointer_count", "Raw pointer count"),
    ("malloc_count", "Alloc calls"),
    ("free_count", "Free calls"),
    ("unpaired_allocations", "Unpaired allocations"),
    ("risk_score", "Risk score"),
]

CHART_METRICS = [
    ("risk_score", "Risk\nscore"),
    ("cyclomatic_complexity", "Cyclomatic"),
    ("raw_pointer_count", "Raw\npointers"),
    ("malloc_count", "Alloc\ncalls"),
    ("unpaired_allocations", "Unpaired\nallocs"),
    ("loc", "LOC"),
]

COLOR_BEFORE = "#B04A3F"   # legacy / risk
COLOR_AFTER = "#2E7D63"    # modernized


def pct_reduction(before, after):
    """Percent decrease from before to after. None when before is 0."""
    if before == 0:
        return None
    return round((before - after) / before * 100.0, 2)


def load(path):
    p = Path(path)
    if not p.is_file():
        print("[!] Not a file: {}".format(p), file=sys.stderr)
        sys.exit(1)
    with open(p, "r", encoding="utf-8") as f:
        data = json.load(f)
    if "files" not in data or "totals" not in data:
        print("[!] {} does not look like a measure.py result".format(p), file=sys.stderr)
        sys.exit(1)
    return data


def index_files(payload):
    """Index rows three ways, from strictest to loosest match.

    Bob may keep the staged layout (skpfa/skpfa.c), flatten it (skpfa.c), or
    change the extension (skpfa.cpp), so matching falls back:
      1. exact relative path
      2. relative path without extension  -> tolerates .c -> .cpp
      3. bare file stem                   -> tolerates a moved/flattened file
    The bare-stem index only keeps names that are unique in the tree, so a
    collision can never silently pair the wrong two files.
    """
    by_path = {}
    by_stem_path = {}
    stem_counts = {}
    for r in payload["files"]:
        by_path[r["file"]] = r
        by_stem_path.setdefault(Path(r["file"]).with_suffix("").as_posix(), r)
        name = Path(r["file"]).stem
        stem_counts[name] = stem_counts.get(name, 0) + 1

    by_name = {}
    for r in payload["files"]:
        name = Path(r["file"]).stem
        if stem_counts[name] == 1:
            by_name[name] = r
    return by_path, by_stem_path, by_name


def pair_files(before, after):
    """Match before rows to after rows. Returns (pairs, only_before, only_after)."""
    b_path, _, _ = index_files(before)
    a_path, a_stem_path, a_name = index_files(after)

    pairs = []
    matched_after = set()
    only_before = []

    for rel, b in b_path.items():
        a = a_path.get(rel)
        how = "path"
        if a is None:
            a = a_stem_path.get(Path(rel).with_suffix("").as_posix())
            how = "path-without-extension"
        if a is None:
            a = a_name.get(Path(rel).stem)
            how = "file-name"
        if a is None:
            only_before.append(rel)
            continue
        matched_after.add(a["file"])
        pairs.append((rel, b, a, how))

    only_after = [rel for rel in a_path if rel not in matched_after]
    return pairs, only_before, only_after


def build_comparison(before, after):
    pairs, only_before, only_after = pair_files(before, after)

    per_file = []
    for rel, b, a, how in pairs:
        entry = {
            "file": rel,
            "after_file": a["file"],
            "matched_by": how,
            "before": {k: b[k] for k, _ in METRICS},
            "after": {k: a[k] for k, _ in METRICS},
            "reduction_pct": {k: pct_reduction(b[k], a[k]) for k, _ in METRICS},
        }
        per_file.append(entry)

    # Totals are recomputed from the matched pairs only, so files that failed to
    # modernize cannot silently inflate or deflate the headline number.
    def agg(side_key, row_key):
        vals = [p[side_key][row_key] for p in per_file]
        if not vals:
            return 0
        if row_key == "risk_score":
            return round(sum(vals) / len(vals), 2)
        return sum(vals)

    totals = {}
    for k, _ in METRICS:
        b_val = agg("before", k)
        a_val = agg("after", k)
        totals[k] = {
            "before": b_val,
            "after": a_val,
            "delta": round(a_val - b_val, 2),
            "reduction_pct": pct_reduction(b_val, a_val),
        }

    return {
        "before_label": before.get("label"),
        "after_label": after.get("label"),
        "before_dir": before.get("input_dir"),
        "after_dir": after.get("input_dir"),
        "risk_formula_before": before.get("risk_formula_version"),
        "risk_formula_after": after.get("risk_formula_version"),
        "matched_file_count": len(per_file),
        "totals": totals,
        "files": per_file,
        "unmatched_before": only_before,
        "unmatched_after": only_after,
    }


def fmt_pct(v):
    if v is None:
        return "n/a"
    if v == 0:
        return "0.0%"
    # v > 0 is a reduction (good); v < 0 means the metric grew.
    return "-{:.1f}%".format(v) if v > 0 else "+{:.1f}%".format(-v)


def render_markdown(cmp_data):
    t = cmp_data["totals"]
    lines = [
        "# Before / After: {} -> {}".format(cmp_data["before_label"], cmp_data["after_label"]),
        "",
        "- Files matched: **{}**".format(cmp_data["matched_file_count"]),
        "- Before: `{}`".format(cmp_data["before_dir"]),
        "- After:  `{}`".format(cmp_data["after_dir"]),
        "",
        "## Aggregate",
        "",
        "| Metric | Before | After | Reduction |",
        "| --- | ---: | ---: | ---: |",
    ]
    for key, title in METRICS:
        row = t[key]
        lines.append("| {} | {} | {} | **{}** |".format(
            title, row["before"], row["after"], fmt_pct(row["reduction_pct"])))

    lines += ["", "## Per file", "",
              "| File | Risk before | Risk after | Risk red. | Cyclo red. | Raw ptr red. | Alloc red. |",
              "| --- | ---: | ---: | ---: | ---: | ---: | ---: |"]
    for p in cmp_data["files"]:
        lines.append("| {} | {} | {} | {} | {} | {} | {} |".format(
            p["file"],
            p["before"]["risk_score"], p["after"]["risk_score"],
            fmt_pct(p["reduction_pct"]["risk_score"]),
            fmt_pct(p["reduction_pct"]["cyclomatic_complexity"]),
            fmt_pct(p["reduction_pct"]["raw_pointer_count"]),
            fmt_pct(p["reduction_pct"]["malloc_count"]),
        ))

    if cmp_data["unmatched_before"] or cmp_data["unmatched_after"]:
        lines += ["", "## Unmatched files", ""]
        for rel in cmp_data["unmatched_before"]:
            lines.append("- Only in before: `{}`".format(rel))
        for rel in cmp_data["unmatched_after"]:
            lines.append("- Only in after: `{}`".format(rel))

    if cmp_data["risk_formula_before"] != cmp_data["risk_formula_after"]:
        lines += ["", "> **Warning:** the two runs used different risk formula versions "
                      "({} vs {}); the risk-score comparison is not valid.".format(
                          cmp_data["risk_formula_before"], cmp_data["risk_formula_after"])]

    return "\n".join(lines) + "\n"


def render_chart(cmp_data, out_path):
    """Grouped bar chart: before vs after for each headline metric."""
    t = cmp_data["totals"]
    labels = [title for key, title in CHART_METRICS]
    before_vals = [t[key]["before"] for key, _ in CHART_METRICS]
    after_vals = [t[key]["after"] for key, _ in CHART_METRICS]

    # Metrics live on wildly different scales (LOC in thousands, risk score
    # 0-100), so bars are normalized to the before value and the real numbers
    # are printed on top. Every bar therefore starts at 100%.
    norm_before = [100.0 for _ in before_vals]
    norm_after = [(a / b * 100.0) if b else 0.0 for b, a in zip(before_vals, after_vals)]

    # A metric that got worse can shoot far past 100% (e.g. 1 unpaired alloc
    # becoming 9 is 900%) and would flatten every other bar. Clip the drawn
    # height and keep the true number in the label instead.
    display_cap = 120.0
    drawn_after = [min(v, display_cap) for v in norm_after]

    x = range(len(labels))
    width = 0.38

    fig, ax = plt.subplots(figsize=(11, 6.4))
    bars_b = ax.bar([i - width / 2 for i in x], norm_before, width,
                    label="Before (legacy)", color=COLOR_BEFORE)
    bars_a = ax.bar([i + width / 2 for i in x], drawn_after, width,
                    label="After (IBM Bob modernized)", color=COLOR_AFTER)

    for bar, raw in zip(bars_b, before_vals):
        ax.annotate("{:g}".format(raw),
                    xy=(bar.get_x() + bar.get_width() / 2, bar.get_height()),
                    xytext=(0, 5), textcoords="offset points",
                    ha="center", va="bottom", fontsize=9)

    for bar, raw, pct in zip(bars_a, after_vals, norm_after):
        clipped = pct > display_cap
        text = "{:g}\n({:.0f}%)".format(raw, pct)
        if clipped:
            text = "^ " + text.replace("\n", " ")
        ax.annotate(text,
                    xy=(bar.get_x() + bar.get_width() / 2, bar.get_height()),
                    xytext=(0, 5), textcoords="offset points",
                    ha="center", va="bottom", fontsize=9,
                    color="#B04A3F" if pct > 100 else "#333333",
                    fontweight="bold" if clipped else "normal")

    ax.set_xticks(list(x))
    ax.set_xticklabels(labels, fontsize=10)
    ax.set_ylabel("Relative to legacy baseline (%)")
    ax.set_title("Chronos AI - legacy C modernization impact\n{} files, tech_risk = memory_unsafe".format(
        cmp_data["matched_file_count"]), fontsize=13, pad=38)
    ax.set_ylim(0, 142)
    ax.axhline(100, color="#999999", linewidth=0.8, linestyle="--", zorder=0)
    ax.legend(loc="lower center", bbox_to_anchor=(0.5, 1.005), ncol=2, frameon=False, fontsize=10)
    ax.spines["top"].set_visible(False)
    ax.spines["right"].set_visible(False)
    ax.grid(axis="y", alpha=0.25, zorder=0)

    risk = t["risk_score"]
    if risk["reduction_pct"] is not None:
        fig.text(0.01, 0.01,
                 "Risk score {} -> {}  ({})".format(
                     risk["before"], risk["after"], fmt_pct(risk["reduction_pct"])),
                 fontsize=10, color="#444444")

    fig.tight_layout()
    out_path = Path(out_path)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(out_path, dpi=160)
    plt.close(fig)
    return out_path


def parse_args():
    demo_dir = Path(__file__).resolve().parent
    ap = argparse.ArgumentParser(description="Compare two measure.py results and plot the delta.")
    ap.add_argument("--before", "-b", required=True, help="JSON produced by measure.py for the legacy tree")
    ap.add_argument("--after", "-a", required=True, help="JSON produced by measure.py for the modernized tree")
    ap.add_argument("--output", "-o", default=str(demo_dir / "comparison.json"), help="Path for the comparison JSON")
    ap.add_argument("--markdown", "-m", default=str(demo_dir / "comparison.md"), help="Path for the Markdown table")
    ap.add_argument("--chart", "-c", default=str(demo_dir / "comparison.png"), help="Path for the bar chart PNG")
    return ap.parse_args()


def main():
    args = parse_args()
    before = load(args.before)
    after = load(args.after)

    if before.get("risk_formula_version") != after.get("risk_formula_version"):
        print("[!] Risk formula versions differ ({} vs {}) - risk comparison is not valid".format(
            before.get("risk_formula_version"), after.get("risk_formula_version")), file=sys.stderr)

    cmp_data = build_comparison(before, after)
    if cmp_data["matched_file_count"] == 0:
        print("[!] No files matched between the two runs - check the directory layouts", file=sys.stderr)
        sys.exit(1)

    out_json = Path(args.output)
    out_json.parent.mkdir(parents=True, exist_ok=True)
    out_json.write_text(json.dumps(cmp_data, indent=2), encoding="utf-8")

    md = render_markdown(cmp_data)
    Path(args.markdown).write_text(md, encoding="utf-8")

    chart_path = render_chart(cmp_data, args.chart)

    print("[+] Comparison JSON -> {}".format(out_json))
    print("[+] Markdown table  -> {}".format(args.markdown))
    print("[+] Bar chart       -> {}".format(chart_path))
    if cmp_data["unmatched_before"]:
        print("[!] {} file(s) present only in the before run".format(len(cmp_data["unmatched_before"])))
    if cmp_data["unmatched_after"]:
        print("[!] {} file(s) present only in the after run".format(len(cmp_data["unmatched_after"])))
    print()
    print(md)


if __name__ == "__main__":
    main()
