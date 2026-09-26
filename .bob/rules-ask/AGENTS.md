# Project Documentation Rules (Non-Obvious Only)

- README is in Vietnamese — don't assume English documentation elsewhere covers all nuances.
- `domain/` contains example C/C++ input domains (`banking_core/`, `legacy_crypto/`, `math_matrix/`) — these are sample inputs for the pipeline, not Python source.
- `chronos-gold-samples/` and `output/` are pipeline-generated artifact directories, not curated source code.
- `analyzer/` is the entire analysis library — there is no `src/` directory.
- `classify_legacy_dataset.py` and `tmp_legacy_analysis.py` in root are standalone scripts, separate from the main pipeline in `main.py`.
- `CLASSIFICATION_REPORT.md` is a generated report artifact, not project documentation.
- Tree-sitter grammar packages (`tree-sitter-c`, `tree-sitter-cpp`) must match the `tree-sitter` core version in `requirements.txt` (>=0.22.0 / >=0.21.0) — version mismatches cause silent fallback to regex across all files.
