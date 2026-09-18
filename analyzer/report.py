"""
report.py - Generation of HTML and text summary reports for the pipeline.
"""

from typing import List, Dict, Any
from pathlib import Path
import json


def generate_text_summary(
    file_records: List[Dict[str, Any]],
    cluster_records: Dict[int, List[Dict[str, Any]]],
    interpretations: Dict[int, Dict[str, Any]],
    all_risks: List[Dict[str, Any]],
    gold_samples: List[Dict[str, Any]]
) -> str:
    """Generate CLI text summary report."""
    total_files = len(file_records)
    total_loc = sum(f["features"]["code_lines"] for f in file_records)
    avg_loc = round(total_loc / max(total_files, 1), 1)
    total_comp = sum(f["features"]["cyclomatic_complexity"] for f in file_records)
    avg_comp = round(total_comp / max(total_files, 1), 1)

    lines = [
        "===========================================================",
        "   CHRONOS LEGACY CODE PROFILING & CLUSTERING REPORT       ",
        "===========================================================",
        f"Total files analyzed: {total_files}",
        f"Total LOC:            {total_loc}",
        f"Average LOC:          {avg_loc}",
        f"Average complexity:   {avg_comp}",
        "",
        "--- CLUSTER PROFILES ---"
    ]

    for cid in sorted(cluster_records.keys()):
        interp = interpretations.get(cid, {})
        ctype = interp.get("interpreted_type", f"Cluster {cid}")
        conf = interp.get("confidence", 0.0)
        dom = ", ".join(interp.get("dominant_features", []))
        files = [f["file_name"] for f in cluster_records[cid]]
        lines.append(f"Cluster {cid} [{ctype}] (confidence: {conf*100:.0f}%):")
        lines.append(f"    File count:        {len(files)}")
        lines.append(f"    Files:             {', '.join(files[:6])}{'...' if len(files) > 6 else ''}")
        lines.append(f"    Dominant features: {dom}")
        lines.append("")

    risk_counts = {}
    for r in all_risks:
        risk_name = r.get("risk")
        risk_counts[risk_name] = risk_counts.get(risk_name, 0) + 1

    lines.append("--- RISK SUMMARY ---")
    for rname, count in sorted(risk_counts.items()):
        lines.append(f"    {rname:<26}: {count} occurrences")
    lines.append("")

    lines.append("--- GOLD SAMPLES SELECTED ---")
    for sample in gold_samples:
        lines.append(f"    Cluster {sample['cluster_id']} ({sample['cluster_type']}):")
        lines.append(f"        File: {sample['file_name']}")
        lines.append(f"        Centroid Distance: {sample['distance_to_centroid']}")
        lines.append(f"        Risks: {', '.join(sample['risks']) or 'None'}")

    lines.append("===========================================================")
    return "\n".join(lines)


def generate_html_report(
    file_records: List[Dict[str, Any]],
    cluster_records: Dict[int, List[Dict[str, Any]]],
    interpretations: Dict[int, Dict[str, Any]],
    all_risks: List[Dict[str, Any]],
    gold_samples: List[Dict[str, Any]],
    output_path: Path
) -> None:
    """Generate rich, modern standalone HTML report."""
    output_path.parent.mkdir(parents=True, exist_ok=True)

    total_files = len(file_records)
    total_loc = sum(f["features"]["code_lines"] for f in file_records)
    avg_loc = round(total_loc / max(total_files, 1), 1)
    total_comp = sum(f["features"]["cyclomatic_complexity"] for f in file_records)
    avg_comp = round(total_comp / max(total_files, 1), 1)

    # Count risks
    risk_counts = {
        "RISK_FLOAT_PRECISION": 0,
        "RISK_MEMORY_LEAK": 0,
        "RISK_QUANTUM_VULNERABLE": 0,
        "RISK_STRUCT_OFFSET": 0,
    }
    for r in all_risks:
        rname = r.get("risk")
        risk_counts[rname] = risk_counts.get(rname, 0) + 1

    html = f"""<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Chronos Legacy Code Profiling & Gold Sample Report</title>
    <style>
        :root {{
            --bg-primary: #0f172a;
            --bg-card: #1e293b;
            --bg-card-hover: #334155;
            --text-primary: #f8fafc;
            --text-secondary: #94a3b8;
            --accent-cyan: #38bdf8;
            --accent-green: #4ade80;
            --accent-red: #f43f5e;
            --accent-amber: #fbbf24;
            --accent-purple: #a855f7;
            --border: #334155;
        }}
        * {{ box-sizing: border-box; margin: 0; padding: 0; }}
        body {{
            background-color: var(--bg-primary);
            color: var(--text-primary);
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
            padding: 32px 24px;
            line-height: 1.6;
        }}
        .container {{ max-width: 1200px; margin: 0 auto; }}
        header {{
            border-bottom: 1px solid var(--border);
            padding-bottom: 24px;
            margin-bottom: 32px;
        }}
        h1 {{
            font-size: 2rem;
            color: var(--accent-cyan);
            margin-bottom: 8px;
            font-weight: 700;
        }}
        .subtitle {{ color: var(--text-secondary); font-size: 1rem; }}
        
        .kpi-grid {{
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
            gap: 20px;
            margin-bottom: 32px;
        }}
        .kpi-card {{
            background-color: var(--bg-card);
            border: 1px solid var(--border);
            border-radius: 12px;
            padding: 20px;
            text-align: center;
        }}
        .kpi-value {{
            font-size: 2rem;
            font-weight: 700;
            color: var(--accent-green);
            margin-top: 4px;
        }}
        .kpi-label {{ color: var(--text-secondary); font-size: 0.875rem; text-transform: uppercase; letter-spacing: 0.05em; }}

        .section-title {{
            font-size: 1.35rem;
            margin-bottom: 16px;
            margin-top: 32px;
            color: var(--text-primary);
            display: flex;
            align-items: center;
            gap: 8px;
        }}
        .section-title::before {{
            content: "";
            display: inline-block;
            width: 4px;
            height: 20px;
            background-color: var(--accent-cyan);
            border-radius: 2px;
        }}

        .cards-grid {{
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(340px, 1fr));
            gap: 20px;
            margin-bottom: 32px;
        }}
        .gold-card {{
            background: linear-gradient(145deg, #1e293b, #172033);
            border: 1px solid #3b82f6;
            border-radius: 12px;
            padding: 24px;
            position: relative;
            overflow: hidden;
        }}
        .gold-badge {{
            position: absolute;
            top: 16px;
            right: 16px;
            background: rgba(251, 191, 36, 0.15);
            color: var(--accent-amber);
            border: 1px solid var(--accent-amber);
            padding: 4px 10px;
            border-radius: 20px;
            font-size: 0.75rem;
            font-weight: 600;
            text-transform: uppercase;
        }}
        .gold-title {{ font-size: 1.2rem; font-weight: 600; color: #ffffff; margin-bottom: 8px; word-break: break-all; }}
        .gold-meta {{ color: var(--text-secondary); font-size: 0.875rem; margin-bottom: 12px; }}
        .badge-list {{ display: flex; flex-wrap: wrap; gap: 6px; margin-top: 12px; }}
        .badge {{
            background: rgba(56, 189, 248, 0.12);
            color: var(--accent-cyan);
            border: 1px solid rgba(56, 189, 248, 0.3);
            padding: 3px 8px;
            border-radius: 6px;
            font-size: 0.75rem;
        }}
        .badge-risk {{
            background: rgba(244, 63, 94, 0.12);
            color: var(--accent-red);
            border: 1px solid rgba(244, 63, 94, 0.3);
        }}

        table {{
            width: 100%;
            border-collapse: collapse;
            background-color: var(--bg-card);
            border-radius: 12px;
            overflow: hidden;
            margin-bottom: 32px;
            border: 1px solid var(--border);
        }}
        th, td {{
            padding: 12px 16px;
            text-align: left;
            border-bottom: 1px solid var(--border);
            font-size: 0.875rem;
        }}
        th {{
            background-color: #182234;
            color: var(--text-secondary);
            font-weight: 600;
            text-transform: uppercase;
            font-size: 0.75rem;
            letter-spacing: 0.05em;
        }}
        tr:hover td {{ background-color: var(--bg-card-hover); }}

        .viz-container {{
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(450px, 1fr));
            gap: 24px;
            margin-bottom: 32px;
        }}
        .viz-box {{
            background-color: var(--bg-card);
            border: 1px solid var(--border);
            border-radius: 12px;
            padding: 16px;
            text-align: center;
        }}
        .viz-box img {{
            max-width: 100%;
            height: auto;
            border-radius: 8px;
        }}
    </style>
</head>
<body>
<div class="container">
    <header>
        <h1>Chronos Legacy C/C++ Code Profiling Pipeline</h1>
        <div class="subtitle">Automated static analysis, multi-dimensional feature clustering, and gold sample selection</div>
    </header>

    <div class="kpi-grid">
        <div class="kpi-card">
            <div class="kpi-label">Analyzed Files</div>
            <div class="kpi-value">{total_files}</div>
        </div>
        <div class="kpi-card">
            <div class="kpi-label">Total LOC</div>
            <div class="kpi-value">{total_loc}</div>
        </div>
        <div class="kpi-card">
            <div class="kpi-label">Avg LOC / File</div>
            <div class="kpi-value">{avg_loc}</div>
        </div>
        <div class="kpi-card">
            <div class="kpi-label">Avg Complexity</div>
            <div class="kpi-value">{avg_comp}</div>
        </div>
    </div>

    <h2 class="section-title">Selected Gold Benchmark Samples</h2>
    <div class="cards-grid">
"""

    for g in gold_samples:
        risks_badges = "".join([f'<span class="badge badge-risk">{r}</span>' for r in g["risks"]]) or '<span class="badge">No High Risks</span>'
        html += f"""
        <div class="gold-card">
            <div class="gold-badge">Cluster {g['cluster_id']}</div>
            <div class="gold-title">{g['file_name']}</div>
            <div class="gold-meta">Interpreted Archetype: <strong>{g['cluster_type']}</strong></div>
            <div class="gold-meta">Distance to Centroid: <strong>{g['distance_to_centroid']}</strong></div>
            <div class="badge-list">
                {risks_badges}
            </div>
        </div>
        """

    html += f"""
    </div>

    <h2 class="section-title">Cluster Visualizations & Risk Distribution</h2>
    <div class="viz-container">
        <div class="viz-box">
            <img src="cluster_visualization.png" alt="PCA Cluster Visualization">
        </div>
        <div class="viz-box">
            <img src="risk_distribution.png" alt="Risk Distribution">
        </div>
    </div>

    <h2 class="section-title">Analyzed Files Manifest</h2>
    <table>
        <thead>
            <tr>
                <th>File Name</th>
                <th>Cluster</th>
                <th>LOC</th>
                <th>Complexity</th>
                <th>Pointers</th>
                <th>Mallocs</th>
                <th>Crypto</th>
                <th>Risks Detected</th>
            </tr>
        </thead>
        <tbody>
    """

    for f in file_records:
        feat = f["features"]
        cid = f.get("cluster_id", 0)
        ctype = f.get("cluster_type", "unassigned")
        f_risks = [r["risk"] for r in f.get("risks", [])]
        f_risks_str = ", ".join(f_risks) if f_risks else "None"
        html += f"""
            <tr>
                <td><strong>{f['file_name']}</strong></td>
                <td><span class="badge">C{cid}: {ctype}</span></td>
                <td>{feat['code_lines']}</td>
                <td>{feat['cyclomatic_complexity']}</td>
                <td>{feat['raw_pointer_count']}</td>
                <td>{feat['malloc_count']}</td>
                <td>{feat['legacy_crypto_count']}</td>
                <td>{f_risks_str}</td>
            </tr>
        """

    html += """
        </tbody>
    </table>
</div>
</body>
</html>
"""
    with open(output_path, "w", encoding="utf-8") as out_f:
        out_f.write(html)
