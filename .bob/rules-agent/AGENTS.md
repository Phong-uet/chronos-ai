# Project Coding Rules (Non-Obvious Only)

- `FEATURE_NAMES` in `analyzer/features.py` is the single source of truth for vector dimensionality (52 features). Never reorder or insert entries mid-list — JSON/CSV outputs and all tests depend on stable positional indexing.
- When adding a new analyzer metric, add it to both the `features` dict in `extract_file_features()` AND to `FEATURE_NAMES` if it should be part of the clustering vector; otherwise it will silently be excluded from vectors.
- `BINARY_FEATURE_NAMES` controls which columns get ×1.5 weighting in `preprocess_features()`. Add new binary (0/1) features here to give them extra clustering influence.
- Each new `analyzer/*.py` module must expose both `*_ast(tree, code, ...)` and `*_regex(code, ...)` variants. `extract_file_features()` wraps the AST call in `try/except Exception` and falls back automatically — never raise from AST analyzers without catching at the call site.
- `function_complexities` is a nested list in the features dict; it must be excluded (`.pop()`) before any CSV/flat serialization.
- Cluster archetype names are fixed strings: `"legacy_crypto"`, `"memory_unsafe"`, `"business_logic"`, `"noise_unclustered"`. Tests assert exact string membership — don't rename.
