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
import re
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


def compute_risk_score_v2_legacy(features):
    """Weighted 0-100 risk score (chronos-demo-risk-v2). Kept for comparison.

    Superseded by compute_risk_score_v3, which separates likelihood from impact
    and drops cyclomatic complexity. Retained unchanged so both numbers can be
    shown side by side and older runs stay reproducible.
    """
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


RISK_FORMULA_VERSION_V3 = "chronos-demo-risk-v3"

# OWASP Risk Rating: Risk = Likelihood x Impact, each rated on its own axis.
#
# Likelihood asks "how likely is a real memory-safety failure" and is built
# purely from allocation handling. Impact asks "how bad is it when one happens"
# and is built purely from blast radius - how much pointer surface and how much
# code is in scope.
#
# Cyclomatic complexity is deliberately in neither. Complexity measures how hard
# the code is to read, not how likely it is to fail or how bad the failure is,
# and folding it in is what made v2 punish a modernization for adding defensive
# NULL-checks. It stays a column of its own.
LIKELIHOOD_WEIGHTS = {
    "unguarded_allocation_ratio": 0.7,
    "unpaired_ratio": 0.3,
}

IMPACT_WEIGHTS = {
    "raw_pointer_density": 0.6,
    "size_factor": 0.4,
}

# Pointer density is scaled by 10 before clamping, so 0.1 raw pointers per line
# of code already saturates the density term.
RAW_PTR_DENSITY_SCALE = 10.0
# Blast radius grows with file size and is capped at 1000 LOC.
SIZE_FACTOR_LOC_CAP = 1000.0

# Residual risk floor. Guarding every allocation does not make C memory-safe:
# double-free, use-after-free and races in untouched HAVE_PTHREADS blocks are
# real failure modes this detector does not model. Without a floor, likelihood
# hits exactly 0 and the product wipes out Impact entirely, reporting no risk
# for a file that still carries hundreds of raw pointers.
LIKELIHOOD_FLOOR = 5.0


def compute_risk_score_v3(features, unguarded_allocations):
    """OWASP-style risk: (Likelihood x Impact) / 100, both axes on 0-100.

    Returns (risk_score_v3, likelihood, impact, breakdown). unguarded_allocations
    comes from analyze_allocation_guards(), so this must be called after it.
    """
    alloc_total = _alloc_total(features)
    unpaired = max(0, alloc_total - _free_total(features))
    loc = features.get("code_lines", 0)
    raw_ptrs = features.get("raw_pointer_count", 0)

    unguarded_ratio = unguarded_allocations / max(alloc_total, 1)
    unpaired_ratio = min(unpaired / max(alloc_total, 1), 1.0)
    measured_likelihood = 100.0 * (
        LIKELIHOOD_WEIGHTS["unguarded_allocation_ratio"] * unguarded_ratio
        + LIKELIHOOD_WEIGHTS["unpaired_ratio"] * unpaired_ratio
    )
    likelihood = max(LIKELIHOOD_FLOOR, measured_likelihood)

    raw_ptr_density = raw_ptrs / max(loc, 1)
    density_term = min(raw_ptr_density * RAW_PTR_DENSITY_SCALE, 1.0)
    size_factor = min(loc / SIZE_FACTOR_LOC_CAP, 1.0)
    impact = 100.0 * (
        IMPACT_WEIGHTS["raw_pointer_density"] * density_term
        + IMPACT_WEIGHTS["size_factor"] * size_factor
    )

    score = round((likelihood * impact) / 100.0, 2)
    breakdown = {
        "likelihood": {
            "score": round(likelihood, 2),
            "measured_score": round(measured_likelihood, 2),
            "floor": LIKELIHOOD_FLOOR,
            "floored": measured_likelihood < LIKELIHOOD_FLOOR,
            "unguarded_allocation_ratio": round(unguarded_ratio, 4),
            "unpaired_ratio": round(unpaired_ratio, 4),
            "unguarded_allocations": unguarded_allocations,
            "unpaired_allocations": unpaired,
            "alloc_total": alloc_total,
            "weights": dict(LIKELIHOOD_WEIGHTS),
        },
        "impact": {
            "score": round(impact, 2),
            "raw_pointer_density": round(raw_ptr_density, 4),
            "raw_pointer_density_term": round(density_term, 4),
            "size_factor": round(size_factor, 4),
            "raw_pointer_count": raw_ptrs,
            "loc": loc,
            "weights": dict(IMPACT_WEIGHTS),
        },
    }
    return score, round(likelihood, 2), round(impact, 2), breakdown


# ---------------------------------------------------------------------------
# Allocation guard analysis (additive - feeds no existing risk component)
# ---------------------------------------------------------------------------
# An "unguarded allocation" is a malloc/calloc/realloc whose result is stored in
# a variable that is NOT NULL-checked on the following line. This reads the
# source file directly rather than trusting alloc_event["code"], because that
# field is not comparable across parse paths: analyze_memory_ast() stores only
# the call expression text (`malloc(L + 1)` - no assignment target), while
# analyze_memory_regex() stores the whole source line. Re-reading by line number
# gives the same answer on both paths.
GUARD_ALLOC_TYPES = ("malloc", "calloc", "realloc")

_MAX_STATEMENT_LINES = 20  # give up rather than run away on a pathological file

# How far past an allocation to look for the check. Bounded so an unchecked
# allocation cannot be excused by a guard hundreds of lines downstream.
_GUARD_LOOKAHEAD_LINES = 6

# Assignment target: an identifier plus any chain of ->x / .x / [i] suffixes, so
# `hd->seq = (char*)malloc(L + 1)` attributes to `hd->seq`, not `hd`.
_LVALUE = r"[A-Za-z_]\w*(?:\s*(?:->|\.)\s*[A-Za-z_]\w*|\s*\[[^\]]*\])*"

_ASSIGN_RE = re.compile(
    r"(?P<var>" + _LVALUE + r")"
    r"\s*=\s*"
    r"(?:\(\s*[^()]*\)\s*)?"                  # optional cast: (FLOAT*)
    r"(?:malloc|calloc|realloc)\s*\("
)


def _strip_line_comments(line):
    """Drop // tails and self-contained /* */ spans so `;` detection is honest."""
    line = re.sub(r"/\*.*?\*/", " ", line)
    pos = line.find("//")
    if pos != -1:
        line = line[:pos]
    return line


def _is_skippable(line):
    """Blank / comment-only lines are not the 'next line' for guard purposes."""
    s = line.strip()
    if not s:
        return True
    return s.startswith(("//", "/*", "*/", "*"))


def _statement_text(lines, idx):
    """Return (text, last_index) for the statement starting at 0-based idx.

    Scans forward while the accumulated text has no `;`, so a call split across
    lines is treated as one statement and the guard is looked for after it.
    """
    parts = []
    last = idx
    for i in range(idx, min(idx + _MAX_STATEMENT_LINES, len(lines))):
        parts.append(_strip_line_comments(lines[i]))
        last = i
        if ";" in parts[-1]:
            break
    return " ".join(parts), last


def _in_condition(stmt, assign_start):
    """True if the assignment at assign_start sits inside an if/while condition.

    This is the `if ((p = malloc(n)) == NULL)` / `if (!(p = malloc(n)))` form,
    where the allocation is tested by the statement that performs it. Paren depth
    is what separates it from `if (x) p = malloc(n);`, where the assignment is in
    the body and is not checked at all.
    """
    for m in re.finditer(r"\b(?:if|while)\s*\(", stmt):
        open_paren = m.end() - 1
        if open_paren >= assign_start:
            continue
        depth = 0
        for ch in stmt[open_paren:assign_start]:
            if ch == "(":
                depth += 1
            elif ch == ")":
                depth -= 1
        if depth >= 1:
            return True
    return False


def _var_pattern(var):
    """Regex source matching `var` allowing whitespace around -> and . links."""
    return re.escape(var).replace(r"\ ", r"\s*").replace(r"\-\>", r"\s*->\s*")


def _references(text, var):
    """True if text mentions var as a whole token."""
    return bool(re.search(r"(?<![A-Za-z0-9_])" + _var_pattern(var) + r"(?![A-Za-z0-9_])", text))


def _negative_check(text, var):
    """A check that fails the allocation: == NULL / != NULL / !var, either operand order.

    The reversed form matters: clib-package.c guards with `if (0 == fetch)`,
    which a var-first-only pattern silently misses and reports as unguarded.
    """
    v = _var_pattern(var)
    null = r"(?:NULL|nullptr|0)"
    return bool(
        re.search(r"(?<![A-Za-z0-9_])" + v + r"\s*(?:==|!=)\s*" + null + r"\b", text)
        or re.search(r"\b" + null + r"\s*(?:==|!=)\s*" + v + r"(?![A-Za-z0-9_])", text)
        or re.search(r"!\s*" + v + r"(?![A-Za-z0-9_])", text)
    )


def _positive_wrap(text, var):
    """`if (var) {` - usage is wrapped in the success branch rather than bailing out.

    This is as safe as an early return, just structured the other way round, so
    it counts as guarded. Kept separate from _negative_check so the JSON can
    distinguish the two styles.
    """
    return bool(re.match(r"\s*(?:\}\s*)?(?:else\s+)?if\s*\(\s*" + _var_pattern(var) + r"\s*\)", text))


def analyze_allocation_guards(file_path, alloc_events):
    """Count malloc/calloc/realloc sites whose result is never NULL-checked.

    Returns unguarded_allocations, unattributable_allocations,
    guarded_allocation_ratio and a per-site `sites` list. Each site carries a
    guard_style of "negative_check", "positive_wrap", "inline_condition" or
    "none". Events of type "new"/"delete" are filtered out explicitly rather
    than assumed absent.
    """
    considered = [e for e in alloc_events if e.get("type") in GUARD_ALLOC_TYPES]
    result = {
        "unguarded_allocations": 0,
        "unattributable_allocations": 0,
        "guarded_allocation_ratio": None,
        "considered_allocations": len(considered),
        "sites": [],
    }
    if not considered:
        return result

    try:
        lines = Path(file_path).read_text(encoding="utf-8", errors="replace").splitlines()
    except OSError:
        # Cannot re-read the file: attribute nothing rather than guess.
        result["unattributable_allocations"] = len(considered)
        return result

    def record(ev, var, status, style):
        result["sites"].append({
            "line": ev.get("line", 0),
            "type": ev["type"],
            "var": var,
            "status": status,
            "guard_style": style,
        })

    for ev in considered:
        line_no = ev.get("line", 0)
        idx = line_no - 1
        if idx < 0 or idx >= len(lines):
            result["unattributable_allocations"] += 1
            continue

        stmt, last_idx = _statement_text(lines, idx)
        m = _ASSIGN_RE.search(stmt)
        if not m:
            # malloc() result passed straight into a call, or a form we do not
            # recognise. Not guarded, not unguarded - just unattributable.
            result["unattributable_allocations"] += 1
            record(ev, None, "unattributable", "none")
            continue

        var = re.sub(r"\s+", "", m.group("var"))

        # `if ((p = malloc(n)) == NULL)` folds the check into the assignment,
        # so the site is guarded by construction - no later line to inspect.
        if _in_condition(stmt, m.start()):
            record(ev, var, "guarded", "inline_condition")
            continue

        # Walk forward to the first line that actually mentions var. Lines in
        # between (`int rc = 0;`, an unrelated assignment) are neither a check
        # nor a use, so stepping over them finds guards that do not sit on the
        # immediately following line, while stopping at the first mention still
        # catches a use-before-check.
        nxt = None
        for j in range(last_idx + 1, min(last_idx + 1 + _GUARD_LOOKAHEAD_LINES, len(lines))):
            if _is_skippable(lines[j]):
                continue
            text = _strip_line_comments(lines[j])
            if _references(text, var):
                nxt = text
                break

        if nxt is None:
            result["unguarded_allocations"] += 1
            record(ev, var, "unguarded", "none")
        elif re.search(r"\bif\s*\(", nxt) and _negative_check(nxt, var):
            record(ev, var, "guarded", "negative_check")
        elif _positive_wrap(nxt, var):
            record(ev, var, "guarded", "positive_wrap")
        else:
            result["unguarded_allocations"] += 1
            record(ev, var, "unguarded", "none")

    total = len(considered)
    result["guarded_allocation_ratio"] = round(
        (total - result["unguarded_allocations"]) / total, 4) if total > 0 else None
    return result

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
        score, breakdown = compute_risk_score_v2_legacy(f)
        guards = analyze_allocation_guards(
            rec["file_path"], rec.get("evidence", {}).get("alloc_events", []))
        score_v3, likelihood, impact, breakdown_v3 = compute_risk_score_v3(
            f, guards["unguarded_allocations"])

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
            "unguarded_allocations": guards["unguarded_allocations"],
            "unattributable_allocations": guards["unattributable_allocations"],
            "guarded_allocation_ratio": guards["guarded_allocation_ratio"],
            "allocation_guard_sites": guards["sites"],
            "function_count": f.get("function_count", 0),
            "goto_count": f.get("goto_count", 0),
            "risk_score": score,
            "risk_breakdown": breakdown,
            "likelihood_score": likelihood,
            "impact_score": impact,
            "risk_score_v3": score_v3,
            "risk_breakdown_v3": breakdown_v3,
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
    ("unguarded_allocations", "Unguarded"),
    ("likelihood_score", "Likelihood"),
    ("impact_score", "Impact"),
    ("risk_score", "Risk v2"),
    ("risk_score_v3", "Risk v3"),
]

# Bounded 0-100 per file, so these aggregate as a mean rather than a sum.
MEAN_KEYS = ["risk_score", "likelihood_score", "impact_score", "risk_score_v3"]

SUM_KEYS = [
    "loc", "total_lines", "cyclomatic_complexity", "raw_pointer_count",
    "pointer_arithmetic_count", "void_pointer_count", "malloc_count",
    "free_count", "unpaired_allocations", "function_count", "goto_count",
    "unguarded_allocations", "unattributable_allocations",
]


def totals_of(rows):
    """Aggregate row used as the headline number in the comparison."""
    agg = {k: sum(r[k] for r in rows) for k in SUM_KEYS}
    agg["file_count"] = len(rows)
    # Risk score is bounded 0-100 per file, so the fleet-level number is a mean.
    for key in MEAN_KEYS:
        agg[key] = round(sum(r[key] for r in rows) / len(rows), 2) if rows else 0.0
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
        "- Risk formula: `{}` (legacy `{}` retained as the Risk v2 column)".format(
            payload["risk_formula_version"], payload.get("risk_formula_version_v2")),
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
        str(t["unguarded_allocations"]),
        str(t["likelihood_score"]),
        str(t["impact_score"]),
        str(t["risk_score"]),
        "**{}**".format(t["risk_score_v3"]),
    ]) + " |")
    lines.append("")
    lines.append("> On the TOTAL row Likelihood, Impact and both risk scores are the "
                 "**mean** across files; every other column is a sum.")
    lines.append(">")
    lines.append("> `Risk v3` is OWASP-style `Likelihood x Impact / 100`. Cyclomatic "
                 "complexity feeds neither axis - it is reported on its own, because "
                 "complexity measures readability, not the chance or the cost of a "
                 "memory-safety failure. `Risk v2` is the older additive score, which "
                 "did include complexity and therefore rises when defensive "
                 "NULL-checks are added.")

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
        "risk_formula_version": RISK_FORMULA_VERSION_V3,
        "risk_formula_version_v2": RISK_FORMULA_VERSION,
        "risk_weights": {k: {"weight": w, "scale": s} for k, (w, s) in RISK_WEIGHTS.items()},
        "likelihood_weights": dict(LIKELIHOOD_WEIGHTS),
        "impact_weights": dict(IMPACT_WEIGHTS),
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
