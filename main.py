#!/usr/bin/env python3
"""
main.py - Entry point for Chronos Legacy C/C++ Code Profiling, Clustering & Gold Sample Selection.
"""

import argparse
import sys
import json
import time
from pathlib import Path
import pandas as pd
import numpy as np

from analyzer.scanner import scan_source_files
from analyzer.features import extract_file_features, FEATURE_NAMES
from analyzer.clustering import preprocess_features, run_clustering, interpret_clusters
from analyzer.risks import evaluate_file_risks
from analyzer.gold_selector import compute_distances_and_select_gold, export_gold_samples
from analyzer.visualization import generate_cluster_visualization, generate_risk_distribution
from analyzer.report import generate_text_summary, generate_html_report


def parse_args():
    parser = argparse.ArgumentParser(
        description="Chronos Legacy C/C++ Code Profiling, Clustering & Gold Sample Selection Pipeline"
    )
    parser.add_argument(
        "--input", "-i",
        type=str,
        default="./source-code",
        help="Input directory containing C/C++ source code (*.c, *.cpp, *.h)"
    )
    parser.add_argument(
        "--output", "-o",
        type=str,
        default="./output",
        help="Output directory for generated reports, vectors, visualizations"
    )
    parser.add_argument(
        "--gold-dir",
        type=str,
        default="./chronos-gold-samples",
        help="Directory to save selected gold benchmark samples"
    )
    parser.add_argument(
        "--clusters", "-k",
        type=int,
        default=3,
        help="Number of clusters for K-Means (default: 3)"
    )
    parser.add_argument(
        "--algorithm",
        type=str,
        choices=["kmeans", "dbscan"],
        default="kmeans",
        help="Clustering algorithm: 'kmeans' or 'dbscan' (default: kmeans)"
    )
    parser.add_argument(
        "--select-gold",
        action="store_true",
        default=True,
        help="Select gold sample files nearest to cluster centroids (default: True)"
    )
    parser.add_argument(
        "--copy-gold",
        action="store_true",
        default=True,
        help="Copy gold samples to gold samples directory (default: True)"
    )
    parser.add_argument(
        "--rename-gold-samples",
        action="store_true",
        default=False,
        help="Rename gold samples according to interpreted cluster type (e.g. gold_business_logic.c)"
    )
    parser.add_argument(
        "--arch",
        type=int,
        choices=[32, 64],
        default=64,
        help="Target architecture bitness for struct padding estimation (default: 64)"
    )
    parser.add_argument(
        "--seed",
        type=int,
        default=42,
        help="Random seed for clustering reproducibility (default: 42)"
    )
    return parser.parse_args()


def main():
    args = parse_args()

    input_dir = Path(args.input).resolve()
    output_dir = Path(args.output).resolve()
    gold_dir = Path(args.gold_dir).resolve()

    output_dir.mkdir(parents=True, exist_ok=True)

    print(f"[*] Scanning C/C++ source files in: {input_dir}")
    source_files = scan_source_files(input_dir)
    if not source_files:
        print(f"[!] No C/C++ files found (*.c, *.cpp, *.h) in {input_dir}")
        sys.exit(1)

    print(f"[*] Found {len(source_files)} source files. Extracting features...")

    file_records = []
    warnings_list = []
    all_risks = []

    for fpath in source_files:
        rec = extract_file_features(fpath, arch=args.arch)
        # Evaluate risks
        risks = evaluate_file_risks(rec)
        rec["risks"] = risks
        for r in risks:
            all_risks.append({
                "file": rec["file_name"],
                "file_path": rec["file_path"],
                **r
            })

        if rec["warnings"]:
            for w in rec["warnings"]:
                warnings_list.append({"file": rec["file_name"], "warning": w})

        file_records.append(rec)

    # Preprocessing
    raw_vectors = [rec["vector"] for rec in file_records]
    X_scaled, scaler = preprocess_features(raw_vectors)

    # Clustering
    print(f"[*] Running {args.algorithm.upper()} clustering (k={args.clusters}, seed={args.seed})...")
    labels, centroids = run_clustering(
        X_scaled,
        n_clusters=args.clusters,
        algorithm=args.algorithm,
        random_seed=args.seed
    )

    # Group records by cluster
    cluster_records: dict[int, list] = {}
    for i, rec in enumerate(file_records):
        cid = int(labels[i])
        rec["cluster_id"] = cid
        if cid not in cluster_records:
            cluster_records[cid] = []
        cluster_records[cid].append(rec)

    # Cluster Interpretation
    interpretations = interpret_clusters(cluster_records, centroids)
    for rec in file_records:
        cid = rec["cluster_id"]
        interp = interpretations.get(cid, {})
        rec["cluster_type"] = interp.get("interpreted_type", f"cluster_{cid}")

    # Gold Sample Selection
    file_distances, gold_samples = compute_distances_and_select_gold(
        file_records, X_scaled, labels, centroids, interpretations
    )

    if args.copy_gold:
        print(f"[*] Exporting gold samples to: {gold_dir}")
        export_gold_samples(gold_samples, gold_dir, rename_samples=args.rename_gold_samples)

    # Output Artifacts
    print(f"[*] Writing pipeline outputs to: {output_dir}")

    # 1. features.json
    features_export = [
        {
            "file": rec["file_name"],
            "file_path": rec["file_path"],
            "cluster_id": rec["cluster_id"],
            "cluster_type": rec["cluster_type"],
            "parser_type": rec["parser_type"],
            "features": rec["features"],
            "vector": rec["vector"],
        }
        for rec in file_records
    ]
    with open(output_dir / "features.json", "w", encoding="utf-8") as f:
        json.dump(features_export, f, indent=2)

    # 2. features.csv
    csv_rows = []
    for rec in file_records:
        row = {
            "file": rec["file_name"],
            "cluster_id": rec["cluster_id"],
            "cluster_type": rec["cluster_type"],
            "parser_type": rec["parser_type"],
            **rec["features"]
        }
        # Remove nested list before CSV export
        row.pop("function_complexities", None)
        csv_rows.append(row)
    pd.DataFrame(csv_rows).to_csv(output_dir / "features.csv", index=False)

    # 3. clusters.json
    clusters_export = {
        "metadata": {
            "timestamp": time.strftime("%Y-%m-%d %H:%M:%S"),
            "python_version": sys.version.split()[0],
            "algorithm": args.algorithm,
            "clusters": args.clusters,
            "random_seed": args.seed,
            "feature_count": len(FEATURE_NAMES),
            "feature_names": FEATURE_NAMES,
        },
        "interpretations": interpretations,
        "clusters": {
            cid: [
                {
                    "file": f["file_name"],
                    "file_path": f["file_path"],
                    "code_lines": f["features"]["code_lines"],
                    "complexity": f["features"]["cyclomatic_complexity"]
                }
                for f in cluster_records[cid]
            ]
            for cid in sorted(cluster_records.keys())
        }
    }
    with open(output_dir / "clusters.json", "w", encoding="utf-8") as f:
        json.dump(clusters_export, f, indent=2)

    # 4. risks.json
    with open(output_dir / "risks.json", "w", encoding="utf-8") as f:
        json.dump(all_risks, f, indent=2)

    # 5. centroids.json
    centroids_export = {
        "feature_names": FEATURE_NAMES,
        "centroids": {
            cid: centroids[cid].tolist() if cid < len(centroids) else []
            for cid in range(len(centroids))
        }
    }
    with open(output_dir / "centroids.json", "w", encoding="utf-8") as f:
        json.dump(centroids_export, f, indent=2)

    # 6. gold_samples.json
    with open(output_dir / "gold_samples.json", "w", encoding="utf-8") as f:
        json.dump(gold_samples, f, indent=2)

    # 7. warnings.json
    with open(output_dir / "warnings.json", "w", encoding="utf-8") as f:
        json.dump(warnings_list, f, indent=2)

    # 8. Visualizations
    viz_png = output_dir / "cluster_visualization.png"
    risk_png = output_dir / "risk_distribution.png"
    generate_cluster_visualization(X_scaled, labels, file_records, interpretations, viz_png)
    generate_risk_distribution(all_risks, risk_png)

    # 9. Reports
    report_html = output_dir / "report.html"
    generate_html_report(file_records, cluster_records, interpretations, all_risks, gold_samples, report_html)

    summary_text = generate_text_summary(file_records, cluster_records, interpretations, all_risks, gold_samples)
    print("\n" + summary_text)
    print(f"\n[+] Processing complete! View HTML report at: file://{report_html.as_posix()}")


if __name__ == "__main__":
    main()
