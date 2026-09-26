# AGENTS.md

This file provides guidance to agents when working with code in this repository.

## Project
Python pipeline that parses C/C++ source files via **tree-sitter**, extracts ~52 named features, clusters them with K-Means/DBSCAN, and selects "gold" representative samples. README is in Vietnamese.

## Commands
```bash
# Run all tests
pytest tests/

# Run a single test file
pytest tests/test_clustering.py

# Run a single test function
pytest tests/test_clustering.py::test_clustering_and_interpretation

# Run the full pipeline
python main.py --input ./source-code --output ./output --gold-dir ./chronos-gold-samples
```

## Critical Architecture Notes

- **Feature vector order is fixed** — `FEATURE_NAMES` list in [`analyzer/features.py`](analyzer/features.py) defines the exact 52-element vector column order. Vectors are constructed with `[float(features[name]) for name in FEATURE_NAMES]`. Adding/removing/reordering entries breaks all downstream clustering and serialized JSON outputs.
- **Binary features get 1.5× weight** — `preprocess_features()` in [`analyzer/clustering.py`](analyzer/clustering.py) multiplies the 6 `BINARY_FEATURE_NAMES` columns by 1.5 after `StandardScaler`. This is intentional for clustering signal.
- **Cluster interpretation is score-based, not index-based** — cluster IDs 0/1/2 are NOT fixed to archetype types. `interpret_clusters()` assigns `legacy_crypto`, `memory_unsafe`, `business_logic` by comparing per-cluster feature averages each run.
- **Dual parsing strategy** — every analyzer module exposes both `*_ast()` (tree-sitter) and `*_regex()` (fallback) variants. `extract_file_features()` silently falls back to regex on any `Exception`. Tests must handle both paths (see `test_memory.py` pattern: `if tree: ... else: ...`).
- **`features` dict has more keys than `FEATURE_NAMES`** — the full features dict includes extras like `blank_lines`, `comment_lines`, `function_complexities` (a nested list), etc. Only the 52 `FEATURE_NAMES` entries go into the numeric vector. `function_complexities` must be `pop()`ed before CSV export.
- **`parser_type`** field in records is either `"tree_sitter"` or `"regex_fallback"` — useful for debugging analysis quality.

## Code Style
- Type hints on all public functions using `typing` imports (`Dict`, `Any`, `List`, `Tuple` from `typing`, not built-ins).
- Module-level docstrings on every file in `analyzer/`.
- Analyzer functions return plain `dict` (not dataclasses), with consistent key naming matching `FEATURE_NAMES`.
- Print statements in `main.py` use `[*]` prefix for info, `[!]` for errors, `[+]` for completion.

## Test Patterns
- Tests use `pytest` with no fixtures — synthetic C code strings are constructed inline.
- Tests that call `analyze_memory_ast` / `analyze_memory_regex` must check `if tree:` because tree-sitter availability depends on the environment.
- Gold sample tests assert `len(gold_samples) == n_clusters` (one gold file per cluster).

## Hackathon-specific constraint
Do NOT modify anything under analyzer/ or main.py during memory-safety modernization
tasks on demo/samples/ files — those are the fixed baseline measurement tool, not part
of the code being modernized. Only touch files explicitly mentioned in each task prompt.
