"""
clustering.py - Feature scaling, K-Means / DBSCAN clustering, and dynamic cluster profile interpretation.
"""

from typing import List, Dict, Any, Tuple
import numpy as np
from sklearn.preprocessing import StandardScaler
from sklearn.cluster import KMeans, DBSCAN

from analyzer.features import FEATURE_NAMES, BINARY_FEATURE_NAMES


def preprocess_features(vectors: List[List[float]]) -> Tuple[np.ndarray, StandardScaler]:
    """
    Scale features:
    StandardScaler across all features, but ensuring zero variance columns
    do not cause NaNs and binary indicator features retain appropriate weight.
    """
    X = np.array(vectors, dtype=float)
    if X.shape[0] <= 1:
        return X, None

    scaler = StandardScaler()
    X_scaled = scaler.fit_transform(X)

    # For zero variance columns (e.g. constant 0), StandardScaler might set them to 0
    X_scaled = np.nan_to_num(X_scaled, nan=0.0)

    # Boost binary crypto & memory indicators slightly if needed so strong signals cluster clearly
    for binary_name in BINARY_FEATURE_NAMES:
        if binary_name in FEATURE_NAMES:
            idx = FEATURE_NAMES.index(binary_name)
            # Give high-signal binary indicators 1.5x weight in Euclidean distance space
            X_scaled[:, idx] *= 1.5

    return X_scaled, scaler


def run_clustering(
    X_scaled: np.ndarray,
    n_clusters: int = 3,
    algorithm: str = "kmeans",
    random_seed: int = 42
) -> Tuple[np.ndarray, np.ndarray]:
    """
    Run clustering on preprocessed feature vectors.
    Returns: (labels, centroids)
    For DBSCAN, centroids are calculated per cluster label.
    """
    n_samples = X_scaled.shape[0]

    if algorithm.lower() == "dbscan":
        # DBSCAN clustering
        eps = 1.5
        min_samples = max(2, min(3, n_samples // 3))
        clusterer = DBSCAN(eps=eps, min_samples=min_samples)
        labels = clusterer.fit_predict(X_scaled)
        
        # Calculate centroids manually for non-noise clusters
        unique_labels = [l for l in np.unique(labels) if l != -1]
        if not unique_labels:
            # Fallback to KMeans if DBSCAN marks all as noise
            kmeans = KMeans(n_clusters=min(n_clusters, n_samples), random_state=random_seed, n_init=10)
            labels = kmeans.fit_predict(X_scaled)
            centroids = kmeans.cluster_centers_
        else:
            centroids = np.array([X_scaled[labels == l].mean(axis=0) for l in unique_labels])
    else:
        # Default K-Means
        actual_k = min(n_clusters, n_samples)
        kmeans = KMeans(n_clusters=actual_k, random_state=random_seed, n_init=10)
        labels = kmeans.fit_predict(X_scaled)
        centroids = kmeans.cluster_centers_

    return labels, centroids


def interpret_clusters(
    cluster_records: Dict[int, List[Dict[str, Any]]],
    centroids: np.ndarray
) -> Dict[int, Dict[str, Any]]:
    """
    Dynamically interpret cluster types from the feature profiles of files within each cluster.
    Never assumes cluster 0 = business, 1 = crypto, 2 = memory.
    Archetypes:
    - business_logic: high LOC, cyclomatic complexity, branch_count, function_complexity
    - legacy_crypto: high legacy_crypto_count, has_sha1, has_md5, rsa_count
    - memory_unsafe: high pointer_count, dynamic_allocation_count, struct_count, pointer_arithmetic
    """
    interpretations: Dict[int, Dict[str, Any]] = {}

    cluster_scores: Dict[int, Dict[str, float]] = {}

    for cid, files in cluster_records.items():
        if cid == -1:
            interpretations[-1] = {
                "cluster_id": -1,
                "interpreted_type": "noise_unclustered",
                "confidence": 0.50,
                "dominant_features": ["outlier", "noise"]
            }
            continue

        if not files:
            continue

        # Compute cluster averages for key indicative traits
        avg_crypto = np.mean([f["features"]["legacy_crypto_count"] + 5 * f["features"]["has_legacy_crypto"] for f in files])
        avg_memory = np.mean([
            f["features"]["raw_pointer_count"] +
            3 * f["features"]["dynamic_allocation_count"] +
            2 * f["features"]["pointer_arithmetic_count"] +
            f["features"]["struct_count"]
            for f in files
        ])
        avg_business = np.mean([
            f["features"]["cyclomatic_complexity"] * 1.5 +
            f["features"]["branch_count"] +
            (f["features"]["code_lines"] / 10.0)
            for f in files
        ])

        cluster_scores[cid] = {
            "legacy_crypto": float(avg_crypto),
            "memory_unsafe": float(avg_memory),
            "business_logic": float(avg_business)
        }

    # Archetype assignments by optimal matching
    assigned_types = set()
    archetypes = ["legacy_crypto", "memory_unsafe", "business_logic"]

    # Sort cluster candidates to find strongest match first
    # For example, identify the cluster with the highest legacy_crypto score first
    crypto_best = max(cluster_scores.keys(), key=lambda c: cluster_scores[c]["legacy_crypto"], default=None)
    if crypto_best is not None and cluster_scores[crypto_best]["legacy_crypto"] > 0.1:
        interpretations[crypto_best] = {
            "cluster_id": crypto_best,
            "interpreted_type": "legacy_crypto",
            "confidence": min(0.98, round(0.70 + 0.05 * cluster_scores[crypto_best]["legacy_crypto"], 2)),
            "dominant_features": ["legacy_crypto_count", "has_sha1", "has_md5", "rsa_count"]
        }
        assigned_types.add("legacy_crypto")

    remaining_clusters = [c for c in cluster_scores.keys() if c not in interpretations]

    # Next, memory unsafe
    if remaining_clusters:
        mem_best = max(remaining_clusters, key=lambda c: cluster_scores[c]["memory_unsafe"])
        interpretations[mem_best] = {
            "cluster_id": mem_best,
            "interpreted_type": "memory_unsafe",
            "confidence": min(0.96, round(0.70 + 0.02 * cluster_scores[mem_best]["memory_unsafe"], 2)),
            "dominant_features": ["raw_pointer_count", "dynamic_allocation_count", "pointer_arithmetic"]
        }
        assigned_types.add("memory_unsafe")

    # Remaining cluster(s) -> business_logic / other
    for cid in cluster_scores.keys():
        if cid not in interpretations:
            interpretations[cid] = {
                "cluster_id": cid,
                "interpreted_type": "business_logic",
                "confidence": 0.88,
                "dominant_features": ["cyclomatic_complexity", "code_lines", "branch_count"]
            }

    return interpretations
