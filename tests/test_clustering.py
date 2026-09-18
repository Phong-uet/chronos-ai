import pytest
import numpy as np
from analyzer.clustering import preprocess_features, run_clustering, interpret_clusters
from analyzer.gold_selector import compute_distances_and_select_gold


def test_clustering_and_interpretation():
    # Construct synthetic feature vectors for 3 distinct archetypes
    # Archetype 1: Business (high LOC, high branch/complexity, 0 crypto)
    # Archetype 2: Crypto (high crypto count, has_sha1, has_md5, low LOC)
    # Archetype 3: Memory (high raw pointer count, high mallocs, 0 crypto)
    records = [
        # Business
        {
            "file_path": "bank1.c", "file_name": "bank1.c",
            "features": {
                "code_lines": 500, "cyclomatic_complexity": 35, "branch_count": 30,
                "legacy_crypto_count": 0, "has_legacy_crypto": 0, "has_sha1": 0, "has_md5": 0,
                "raw_pointer_count": 1, "dynamic_allocation_count": 0, "pointer_arithmetic_count": 0, "struct_count": 0
            },
            "vector": [500.0, 35.0, 30.0] + [0.0] * 49
        },
        {
            "file_path": "bank2.c", "file_name": "bank2.c",
            "features": {
                "code_lines": 450, "cyclomatic_complexity": 30, "branch_count": 28,
                "legacy_crypto_count": 0, "has_legacy_crypto": 0, "has_sha1": 0, "has_md5": 0,
                "raw_pointer_count": 2, "dynamic_allocation_count": 0, "pointer_arithmetic_count": 0, "struct_count": 0
            },
            "vector": [450.0, 30.0, 28.0] + [0.0] * 49
        },
        # Crypto
        {
            "file_path": "hash.c", "file_name": "hash.c",
            "features": {
                "code_lines": 80, "cyclomatic_complexity": 4, "branch_count": 3,
                "legacy_crypto_count": 6, "has_legacy_crypto": 1, "has_sha1": 1, "has_md5": 1,
                "raw_pointer_count": 2, "dynamic_allocation_count": 0, "pointer_arithmetic_count": 0, "struct_count": 1
            },
            "vector": [80.0, 4.0, 3.0] + [0.0] * 49
        },
        {
            "file_path": "rsa.c", "file_name": "rsa.c",
            "features": {
                "code_lines": 90, "cyclomatic_complexity": 5, "branch_count": 4,
                "legacy_crypto_count": 8, "has_legacy_crypto": 1, "has_sha1": 0, "has_md5": 0,
                "raw_pointer_count": 3, "dynamic_allocation_count": 0, "pointer_arithmetic_count": 0, "struct_count": 0
            },
            "vector": [90.0, 5.0, 4.0] + [0.0] * 49
        },
        # Memory
        {
            "file_path": "buffer.c", "file_name": "buffer.c",
            "features": {
                "code_lines": 100, "cyclomatic_complexity": 6, "branch_count": 5,
                "legacy_crypto_count": 0, "has_legacy_crypto": 0, "has_sha1": 0, "has_md5": 0,
                "raw_pointer_count": 25, "dynamic_allocation_count": 10, "pointer_arithmetic_count": 12, "struct_count": 4
            },
            "vector": [100.0, 6.0, 5.0] + [0.0] * 49
        },
        {
            "file_path": "pool.c", "file_name": "pool.c",
            "features": {
                "code_lines": 110, "cyclomatic_complexity": 7, "branch_count": 6,
                "legacy_crypto_count": 0, "has_legacy_crypto": 0, "has_sha1": 0, "has_md5": 0,
                "raw_pointer_count": 22, "dynamic_allocation_count": 8, "pointer_arithmetic_count": 10, "struct_count": 3
            },
            "vector": [110.0, 7.0, 6.0] + [0.0] * 49
        }
    ]

    vectors = [r["vector"] for r in records]
    X_scaled, scaler = preprocess_features(vectors)
    labels, centroids = run_clustering(X_scaled, n_clusters=3, algorithm="kmeans", random_seed=42)

    assert len(labels) == 6
    assert len(centroids) == 3

    cluster_records = {}
    for i, rec in enumerate(records):
        cid = int(labels[i])
        rec["cluster_id"] = cid
        cluster_records.setdefault(cid, []).append(rec)

    interpretations = interpret_clusters(cluster_records, centroids)
    assert len(interpretations) == 3

    interpreted_types = {interp["interpreted_type"] for interp in interpretations.values()}
    assert "legacy_crypto" in interpreted_types
    assert "memory_unsafe" in interpreted_types
    assert "business_logic" in interpreted_types

    file_distances, gold_samples = compute_distances_and_select_gold(
        records, X_scaled, labels, centroids, interpretations
    )
    assert len(gold_samples) == 3
