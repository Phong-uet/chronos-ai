"""
gold_selector.py - Centroid calculation, Euclidean distance, and gold sample selection.
"""

from typing import List, Dict, Any, Tuple
from pathlib import Path
import shutil
import json
import numpy as np


def compute_distances_and_select_gold(
    file_records: List[Dict[str, Any]],
    X_scaled: np.ndarray,
    labels: np.ndarray,
    centroids: np.ndarray,
    interpretations: Dict[int, Dict[str, Any]]
) -> Tuple[List[Dict[str, Any]], List[Dict[str, Any]]]:
    """
    Compute Euclidean distance from each file's scaled vector to its cluster centroid.
    Select the file with minimum distance for each cluster as the Gold Sample.
    Returns: (all_file_distances, gold_samples)
    """
    file_distances = []
    gold_candidates: Dict[int, Dict[str, Any]] = {}

    for i, rec in enumerate(file_records):
        cid = int(labels[i])
        if cid == -1 or cid >= len(centroids):
            continue

        centroid = centroids[cid]
        vec = X_scaled[i]
        dist = float(np.linalg.norm(vec - centroid))

        interp = interpretations.get(cid, {})
        ctype = interp.get("interpreted_type", f"cluster_{cid}")

        rec_dist = {
            "file_path": rec["file_path"],
            "file_name": rec["file_name"],
            "cluster_id": cid,
            "cluster_type": ctype,
            "distance_to_centroid": round(dist, 4),
            "risks": [r["risk"] for r in rec.get("risks", [])]
        }
        file_distances.append(rec_dist)

        # Check if candidate is closer to centroid
        if cid not in gold_candidates or dist < gold_candidates[cid]["distance_to_centroid"]:
            gold_candidates[cid] = rec_dist

    gold_samples = [gold_candidates[cid] for cid in sorted(gold_candidates.keys())]
    return file_distances, gold_samples


def export_gold_samples(
    gold_samples: List[Dict[str, Any]],
    output_dir: Path,
    rename_samples: bool = False
) -> Dict[str, Any]:
    """
    Copy gold sample source files to chronos-gold-samples/ and generate metadata.json.
    """
    output_dir.mkdir(parents=True, exist_ok=True)
    metadata_samples = []

    for sample in gold_samples:
        src_path = Path(sample["file_path"])
        cid = sample["cluster_id"]
        ctype = sample["cluster_type"]

        # Determine target file name
        ext = src_path.suffix
        if rename_samples:
            target_name = f"gold_{ctype}{ext}"
        else:
            target_name = f"cluster_{cid}_{src_path.name}"

        dest_path = output_dir / target_name
        if src_path.exists():
            shutil.copy2(src_path, dest_path)

        meta_entry = {
            "file": target_name,
            "original_file": src_path.name,
            "cluster_id": cid,
            "cluster_type": ctype,
            "distance_to_centroid": sample["distance_to_centroid"],
            "risks": sample["risks"]
        }
        metadata_samples.append(meta_entry)

    metadata_doc = {
        "gold_sample_count": len(metadata_samples),
        "samples": metadata_samples
    }

    metadata_path = output_dir / "metadata.json"
    with open(metadata_path, "w", encoding="utf-8") as f:
        json.dump(metadata_doc, f, indent=2)

    return metadata_doc
