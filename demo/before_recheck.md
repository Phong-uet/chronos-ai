# Measurement: before

- Source directory: `D:\chronos-ai\demo\samples\before`
- Files measured: **7**
- Generated: 2026-09-26 00:59:47
- Risk formula: `chronos-demo-risk-v2`

| File | LOC | Cyclomatic | Raw ptr | Alloc | Free | Risk score |
| --- | --- | --- | --- | --- | --- | --- |
| clib-package.c | 1342 | 325 | 444 | 10 | 49 | 48.69 |
| khmm.c | 360 | 102 | 314 | 12 | 42 | 38.05 |
| kopen.c | 313 | 88 | 149 | 12 | 11 | 28.9 |
| clib-configure.c | 569 | 102 | 134 | 5 | 21 | 25.48 |
| skpfa/skpfa.c | 247 | 59 | 66 | 14 | 18 | 15.65 |
| skpf10/skpf10.c | 251 | 59 | 62 | 14 | 18 | 15.45 |
| sktrd/sktrd.c | 217 | 53 | 60 | 12 | 12 | 13.52 |
| **TOTAL / AVG** | 3299 | 788 | 1229 | 79 | 171 | **26.53** |

> On the TOTAL row the risk score is the **mean** across files; every other column is a sum.

## Extraction problems

| File | Stage | Detail |
| --- | --- | --- |
| clib-configure.c | parse | Tree contains syntax errors (recovered via Tree-sitter error nodes) |
| clib-package.c | parse | Tree contains syntax errors (recovered via Tree-sitter error nodes) |
| skpf10/skpf10.c | parse | Tree contains syntax errors (recovered via Tree-sitter error nodes) |
| skpfa/skpfa.c | parse | Tree contains syntax errors (recovered via Tree-sitter error nodes) |
| sktrd/sktrd.c | parse | Tree contains syntax errors (recovered via Tree-sitter error nodes) |
