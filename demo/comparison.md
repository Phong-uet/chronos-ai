# Before / After: before -> after

- Files matched: **7**
- Before: `D:\chronos-ai\demo\samples\before`
- After:  `D:\chronos-ai\demo\samples\after`

## Aggregate

| Metric | Before | After | Reduction |
| --- | ---: | ---: | ---: |
| LOC | 3299 | 3489 | **+5.8%** |
| Unguarded allocations | 30 | 0 | **-100.0%** |
| Unpaired allocations | 1 | 0 | **-100.0%** |
| Cyclomatic complexity | 788 | 893 | **+13.3%** |
| Raw pointer count | 1229 | 1290 | **+5.0%** |
| Alloc calls | 79 | 79 | **0.0%** |
| Free calls | 171 | 242 | **+41.5%** |
| Risk score (v2) | 26.53 | 27.99 | **+5.5%** |
| Risk score (v3) | 25.72 | 3.89 | **-84.9%** |

> Note: Risk score (v2) includes cyclomatic complexity, which can increase when defensive NULL-checks are added - so it can rise even as the code gets safer. Risk score (v3) is OWASP-style Likelihood x Impact and excludes complexity; read it together with the unguarded/unpaired allocation metrics above for the safety signal.

## Per file

| File | Unguarded before | Unguarded after | Unguarded red. | Risk before | Risk after | Risk red. | Cyclo red. | Raw ptr red. | Alloc red. |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| clib-package.c | 1 | 0 | -100.0% | 48.69 | 49.28 | +1.2% | +1.9% | 0.0% | 0.0% |
| khmm.c | 12 | 0 | -100.0% | 38.05 | 44.27 | +16.4% | +39.2% | +17.8% | 0.0% |
| kopen.c | 12 | 0 | -100.0% | 28.9 | 29.05 | +0.5% | +22.7% | +1.3% | 0.0% |
| clib-configure.c | 5 | 0 | -100.0% | 25.48 | 27.37 | +7.4% | +14.7% | +2.2% | 0.0% |
| skpfa/skpfa.c | 0 | 0 | n/a | 15.65 | 16.19 | +3.5% | +16.9% | 0.0% | 0.0% |
| skpf10/skpf10.c | 0 | 0 | n/a | 15.45 | 16.0 | +3.6% | +16.9% | 0.0% | 0.0% |
| sktrd/sktrd.c | 0 | 0 | n/a | 13.52 | 13.75 | +1.7% | +7.5% | 0.0% | 0.0% |
