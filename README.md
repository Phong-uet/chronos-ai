# Chronos AI

Chronos AI is a Python pipeline that profiles legacy C/C++ source trees, clusters the files
by their code characteristics, flags the risks worth modernizing, and picks one
representative "gold" sample per cluster for benchmarking.

It was built for the IBM Bob 2.0 hackathon, together with a mined legacy-code dataset
(`chronos-legacy-dataset/`) and a before/after measurement track (`demo/`) that shows what
an AI modernization run actually changed.

## What it does

- Scans a directory for C/C++ sources and headers (`.c .cpp .cc .cxx .h .hpp .hxx`).
- Extracts a fixed 53-feature vector per file: LOC, complexity, functions, pointers, memory
  allocation, casts, struct layout, legacy crypto and DSA patterns.
- Clusters the files with K-Means or DBSCAN and labels each cluster from its feature profile
  (`legacy_crypto`, `memory_unsafe`, `business_logic`).
- Reports concrete risks: float precision loss, potential memory leaks, quantum-vulnerable
  crypto (SHA-1/MD5/RSA) and struct alignment padding.
- Copies the file closest to each cluster centroid into a gold-sample directory, and writes
  JSON/CSV artifacts, PCA and risk plots and an HTML report.

Parsing runs on Tree-sitter and falls back to regex, so unparsable legacy code is still
analyzed instead of aborting the run.

## Install

```bash
pip install -r requirements.txt
```

## Run

```bash
python main.py --input ./source-code --output ./output --gold-dir ./chronos-gold-samples
```

Useful options: `--clusters/-k` (default 3), `--algorithm kmeans|dbscan`, `--arch 32|64`,
`--seed` (default 42). Results land in `output/` and `chronos-gold-samples/`.

## Layout

```text
analyzer/                        Feature extraction, clustering, risks, reporting
main.py                          Pipeline entry point
tests/                           pytest suite
source-code/                     Small demo input tree
output/, chronos-gold-samples/   Generated artifacts
domain/, tech/                   Dataset classified by domain and by technical trait
chronos-legacy-dataset/          Mined corpus + MANIFEST.json + mining script
demo/                            Before/after measurement (measure.py, compare.py)
```

## Tests

```bash
pytest tests/
```

## More documentation

- `CLASSIFICATION_REPORT.md` - dataset classification report
- `demo/README.md` - before/after measurement workflow
- `AGENTS.md` - architecture notes and contribution rules

Built for the IBM Bob 2.0 hackathon.
