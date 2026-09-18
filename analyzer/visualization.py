"""
visualization.py - PCA 2D scatter visualization and risk distribution plots.
"""

from typing import List, Dict, Any
from pathlib import Path
import matplotlib
matplotlib.use("Agg")  # Non-interactive headless backend
import matplotlib.pyplot as plt
import numpy as np
from sklearn.decomposition import PCA


def generate_cluster_visualization(
    X_scaled: np.ndarray,
    labels: np.ndarray,
    file_records: List[Dict[str, Any]],
    interpretations: Dict[int, Dict[str, Any]],
    output_path: Path
) -> None:
    """
    Project feature vectors to 2D using PCA and render cluster scatter plot.
    """
    n_samples = X_scaled.shape[0]
    output_path.parent.mkdir(parents=True, exist_ok=True)

    if n_samples < 2:
        # Create a simple placeholder figure if fewer than 2 samples
        fig, ax = plt.subplots(figsize=(8, 6))
        ax.text(0.5, 0.5, "Insufficient samples (<2) for PCA visualization",
                horizontalalignment='center', verticalalignment='center')
        fig.savefig(output_path, dpi=150)
        plt.close(fig)
        return

    pca = PCA(n_components=2, random_state=42)
    coords_2d = pca.fit_transform(X_scaled)

    fig, ax = plt.subplots(figsize=(10, 7), dpi=150)
    fig.patch.set_facecolor("#1e1e2f")
    ax.set_facecolor("#252538")

    # Distinct color palette
    palette = ["#4ade80", "#38bdf8", "#f43f5e", "#fbbf24", "#a855f7", "#ec4899"]

    unique_labels = sorted(list(set(labels)))
    for label in unique_labels:
        mask = (labels == label)
        points = coords_2d[mask]
        interp = interpretations.get(label, {})
        ctype = interp.get("interpreted_type", f"Cluster {label}")
        color = "#94a3b8" if label == -1 else palette[label % len(palette)]

        ax.scatter(
            points[:, 0], points[:, 1],
            c=color,
            label=f"Cluster {label}: {ctype} (n={len(points)})",
            s=90, alpha=0.85, edgecolors="#ffffff", linewidths=0.8
        )

        # Annotate filenames with subtle offsets
        file_indices = np.where(mask)[0]
        for idx in file_indices:
            fname = file_records[idx]["file_name"]
            ax.annotate(
                fname,
                (coords_2d[idx, 0], coords_2d[idx, 1]),
                xytext=(6, 6), textcoords="offset points",
                fontsize=8, color="#e2e8f0", alpha=0.9
            )

    ax.set_title("Legacy C/C++ Code Clusters (2D PCA Projection)", fontsize=13, color="#f8fafc", weight="bold", pad=12)
    ax.set_xlabel(f"PCA Component 1 ({pca.explained_variance_ratio_[0]*100:.1f}% var)", color="#cbd5e1", fontsize=10)
    ax.set_ylabel(f"PCA Component 2 ({pca.explained_variance_ratio_[1]*100:.1f}% var)", color="#cbd5e1", fontsize=10)
    ax.grid(True, linestyle="--", alpha=0.2, color="#94a3b8")
    ax.tick_params(colors="#cbd5e1")
    for spine in ax.spines.values():
        spine.set_color("#475569")

    legend = ax.legend(facecolor="#1e1e2f", edgecolor="#475569", fontsize=9)
    for text in legend.get_texts():
        text.set_color("#f8fafc")

    plt.tight_layout()
    fig.savefig(output_path, dpi=150)
    plt.close(fig)


def generate_risk_distribution(
    all_risks: List[Dict[str, Any]],
    output_path: Path
) -> None:
    """
    Render bar chart showing the frequency and severity of detected risks.
    """
    output_path.parent.mkdir(parents=True, exist_ok=True)

    risk_counts: Dict[str, int] = {
        "RISK_FLOAT_PRECISION": 0,
        "RISK_MEMORY_LEAK": 0,
        "RISK_QUANTUM_VULNERABLE": 0,
        "RISK_STRUCT_OFFSET": 0,
    }

    for r in all_risks:
        rname = r.get("risk")
        if rname in risk_counts:
            risk_counts[rname] += 1
        else:
            risk_counts[rname] = 1

    fig, ax = plt.subplots(figsize=(9, 5), dpi=150)
    fig.patch.set_facecolor("#1e1e2f")
    ax.set_facecolor("#252538")

    categories = list(risk_counts.keys())
    counts = [risk_counts[c] for c in categories]
    colors = ["#38bdf8", "#f43f5e", "#fbbf24", "#a855f7"]

    bars = ax.bar(categories, counts, color=colors, edgecolor="#ffffff", linewidth=0.7, width=0.55)

    for bar in bars:
        h = bar.get_height()
        ax.annotate(f"{h}",
                    xy=(bar.get_x() + bar.get_width() / 2, h),
                    xytext=(0, 4), textcoords="offset points",
                    ha="center", va="bottom", fontsize=10, color="#f8fafc", weight="bold")

    ax.set_title("Technical Risk Distribution Across Analyzed Codebase", fontsize=13, color="#f8fafc", weight="bold", pad=12)
    ax.set_ylabel("Occurrence Count", color="#cbd5e1", fontsize=10)
    ax.grid(axis="y", linestyle="--", alpha=0.2, color="#94a3b8")
    ax.tick_params(colors="#cbd5e1", axis="x", rotation=10)
    ax.tick_params(colors="#cbd5e1", axis="y")
    for spine in ax.spines.values():
        spine.set_color("#475569")

    plt.tight_layout()
    fig.savefig(output_path, dpi=150)
    plt.close(fig)
