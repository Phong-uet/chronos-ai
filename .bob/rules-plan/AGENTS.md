# Project Architecture Rules (Non-Obvious Only)

- **Pipeline is single-pass, stateless** — each file is analyzed independently; there is no cross-file or incremental state. The only shared state is the fitted `StandardScaler` returned from `preprocess_features()`.
- **Cluster ID → archetype mapping is computed fresh each run** — cluster integer IDs are not stable across runs with different seeds or input sets. Never hard-code "cluster 0 = business_logic".
- **Gold sample selection** is strictly "file nearest to centroid in scaled space" (one per cluster). DBSCAN noise points (`label == -1`) are excluded from gold selection entirely.
- **DBSCAN fallback**: if DBSCAN labels all samples as noise, the code silently falls back to K-Means. Downstream code must not assume DBSCAN was used even when `--algorithm dbscan` was specified.
- **`preprocess_features()` returns `(X, None)` when input has ≤1 sample** — callers must handle `scaler is None`.
- **Output artifacts**: `features.json` includes full per-file feature dicts; `centroids.json` stores scaled-space centroids (not original-space). Comparing centroids to raw feature values requires inverse-transform via the saved scaler (which is not currently serialized to disk).
- **Tree-sitter parsers are module-level singletons** in `analyzer/parser.py` — instantiated once at import time. Import failures disable AST parsing globally for the process.
