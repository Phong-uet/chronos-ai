Phase 1 Results (Known Repos) ✅
Category	Repo	Files
cobol_banking	cobol-programming-course	7
c_legacy_crypto	OpenSSL 1.0.1	828
c_legacy_crypto	crypto-algorithms	30
c_legacy_crypto	tiny-AES-c	4
c_legacy_crypto	sha256.c	6
c_financial_math	cmark	33
c_financial_math	stb	86
c_financial_math	klib	74
c_financial_math	clib	130
c_financial_math	sds, inih	17
fortran_legacy	LAPACK/BLAS	2,310
fortran_legacy	Astrodynamics Toolkit	58
fortran_legacy	fortran-utils, M_strings	214
Phase 2 (API Search) — In Progress 🔄
COBOL banking searches: ~130 more files from 15 additional repos
C crypto (MD5/SHA): 9 more files
C financial math: 16 more files
Fortran numerical: Currently cloning...
Still running through the last search queries. I'll wait for completion.

Pipeline is actively cloning Fortran numerical repos now. Will report final results shortly.

Execute mining pipeline finished
Temp cleanup finished
🎯 Mining Complete — Final Results
Category	Files	Size	Highlight
COBOL Banking	160	1.07 MB	15 repos — banking systems, ledgers, transaction processors
C Legacy Crypto	877	9.52 MB	OpenSSL 1.0.1 SHA-1/MD5/RSA/DES, AES, crypto-algorithms
C Financial Math	356	5.21 MB	stb, klib, cmark, amortization calculators, compound interest
Fortran Legacy	2,707	32.89 MB	LAPACK/BLAS (2,310 files), astrodynamics, pfapack
C++ Legacy	1	0.02 MB	C++ cheatsheet patterns
TOTAL	4,101	48.72 MB	49 repos cloned
Key deliverables:



chronos-legacy-dataset/
 — Full dataset directory


MANIFEST.json
 — 4,101-entry metadata (file paths, licenses, language versions, legacy feature tags, SHA-256 hashes)


fetch_legacy_code.py
 — Reproducible mining script
The cpp_legacy category is thin (1 file). If you'd like, I can run a targeted expansion to pull more legacy C++ codebases (e.g., early Boost modules, legacy Qt, old game engines).