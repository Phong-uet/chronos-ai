# Measurement: after

- Source directory: `D:\chronos-ai\demo\samples\after`
- Files measured: **7**
- Generated: 2026-09-26 09:35:50
- Risk formula: `chronos-demo-risk-v3` (legacy `chronos-demo-risk-v2` retained as the Risk v2 column)

| File | LOC | Cyclomatic | Raw ptr | Alloc | Free | Unguarded | Likelihood | Impact | Risk v2 | Risk v3 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| clib/clib-package.c | 1360 | 331 | 444 | 10 | 53 | 0 | 5.0 | 100.0 | 49.28 | 5.0 |
| khmm/khmm.c | 420 | 142 | 370 | 12 | 93 | 0 | 5.0 | 76.8 | 44.27 | 3.84 |
| kopen/kopen.c | 343 | 108 | 151 | 12 | 27 | 0 | 5.0 | 73.72 | 29.05 | 3.69 |
| clib/clib-configure.c | 607 | 117 | 137 | 5 | 21 | 0 | 5.0 | 84.28 | 27.37 | 4.21 |
| skpfa/skpfa.c | 263 | 69 | 66 | 14 | 18 | 0 | 5.0 | 70.52 | 16.19 | 3.53 |
| skpf10/skpf10.c | 267 | 69 | 62 | 14 | 18 | 0 | 5.0 | 70.68 | 16.0 | 3.53 |
| sktrd/sktrd.c | 229 | 57 | 60 | 12 | 12 | 0 | 5.0 | 69.16 | 13.75 | 3.46 |
| **TOTAL / AVG** | 3489 | 893 | 1290 | 79 | 242 | 0 | 5.0 | 77.88 | 27.99 | **3.89** |

> On the TOTAL row Likelihood, Impact and both risk scores are the **mean** across files; every other column is a sum.
>
> `Risk v3` is OWASP-style `Likelihood x Impact / 100`. Cyclomatic complexity feeds neither axis - it is reported on its own, because complexity measures readability, not the chance or the cost of a memory-safety failure. `Risk v2` is the older additive score, which did include complexity and therefore rises when defensive NULL-checks are added.

## Extraction problems

| File | Stage | Detail |
| --- | --- | --- |
| clib/clib-configure.c | parse | Tree contains syntax errors (recovered via Tree-sitter error nodes) |
| clib/clib-package.c | parse | Tree contains syntax errors (recovered via Tree-sitter error nodes) |
| skpf10/skpf10.c | parse | Tree contains syntax errors (recovered via Tree-sitter error nodes) |
| skpfa/skpfa.c | parse | Tree contains syntax errors (recovered via Tree-sitter error nodes) |
| sktrd/sktrd.c | parse | Tree contains syntax errors (recovered via Tree-sitter error nodes) |
