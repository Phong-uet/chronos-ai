#!/usr/bin/env python3
"""
fetch_legacy_code.py - Legacy Code Mining Pipeline
===================================================
Crawls GitHub for authentic legacy code (COBOL, C89/C99, Fortran, Legacy C++)
and consolidates into a structured dataset for AI transpiler benchmarking.
"""

import os
import sys
import json
import shutil
import subprocess
import urllib.request
import urllib.error
import urllib.parse
import time
import re
import hashlib
from pathlib import Path
from datetime import datetime

# ── Configuration ──────────────────────────────────────────────────────────
BASE_DIR = Path(__file__).parent.resolve()
TEMP_DIR = BASE_DIR / "_temp_clones"
MANIFEST_PATH = BASE_DIR / "MANIFEST.json"
LOG_FILE = BASE_DIR / "mining_log.txt"

# GitHub API (unauthenticated = 60 req/hr; set GITHUB_TOKEN env var for 5000/hr)
GITHUB_TOKEN = os.environ.get("GITHUB_TOKEN", "")
GITHUB_API = "https://api.github.com"

# Source file extensions we want
SOURCE_EXTENSIONS = {
    ".c", ".h", ".cob", ".cbl", ".cpy", ".f", ".f77", ".f90", ".f95",
    ".for", ".fpp", ".cpp", ".cxx", ".cc", ".hpp", ".hxx",
}

# Extensions to explicitly reject
REJECT_EXTENSIONS = {
    ".png", ".jpg", ".jpeg", ".gif", ".bmp", ".ico", ".svg",
    ".pdf", ".doc", ".docx", ".xls", ".xlsx",
    ".exe", ".dll", ".so", ".o", ".obj", ".a", ".lib", ".dylib",
    ".zip", ".tar", ".gz", ".bz2", ".7z", ".rar",
    ".pyc", ".class", ".jar", ".war",
    ".mp3", ".mp4", ".avi", ".mov", ".wav",
    ".wasm", ".bin", ".dat",
}

# Legacy complexity markers per category
LEGACY_MARKERS = {
    "cobol": [
        "PERFORM", "WORKING-STORAGE", "PROCEDURE DIVISION", "PICTURE",
        "COPY", "EVALUATE", "GO TO", "ACCEPT", "DISPLAY",
        "FILE SECTION", "DATA DIVISION", "IDENTIFICATION DIVISION",
        "COMPUTE", "MOVE", "IF", "READ", "WRITE", "REWRITE",
        "OPEN INPUT", "OPEN OUTPUT", "STOP RUN",
    ],
    "c_crypto": [
        "SHA1_Init", "SHA1_Update", "SHA1_Final", "MD5_Init", "MD5_Update",
        "RSA_generate_key", "DES_ecb_encrypt", "EVP_EncryptInit",
        "RAND_bytes", "BN_new", "BN_mod_exp", "AES_set_encrypt_key",
        "SHA256_Init", "HMAC_Init", "EVP_DigestInit", "BIO_new",
        "SSL_CTX_new", "malloc", "free", "memcpy", "memset",
    ],
    "c_financial": [
        "compound", "interest", "amortization", "annuity", "present_value",
        "future_value", "discount", "yield", "bond", "mortgage",
        "malloc", "free", "printf", "scanf", "struct", "typedef",
        "float", "double", "pow", "sqrt", "log",
    ],
    "fortran": [
        "SUBROUTINE", "FUNCTION", "PROGRAM", "COMMON", "DIMENSION",
        "DO ", "CONTINUE", "FORMAT", "WRITE", "READ", "IMPLICIT",
        "REAL*8", "DOUBLE PRECISION", "INTEGER", "COMPLEX",
        "CALL", "RETURN", "END", "DATA", "EQUIVALENCE", "GOTO",
    ],
    "cpp_legacy": [
        "class ", "template", "virtual", "new ", "delete ",
        "malloc", "free", "reinterpret_cast", "static_cast",
        "iostream", "fstream", "printf", "sprintf", "strcpy",
        "goto", "union", "struct", "typedef", "enum",
    ],
}

# ── Well-known repositories to clone ──────────────────────────────────────
CLONE_TARGETS = [
    # ── COBOL Banking / Financial ──
    {
        "url": "https://github.com/openmainframeproject/cobol-programming-course.git",
        "category": "cobol_banking",
        "license": "GPL-3.0",
        "description": "Open Mainframe Project COBOL Programming Course - banking examples",
    },
    {
        "url": "https://github.com/OpenCBT/Tutorials.git",
        "category": "cobol_banking",
        "license": "MIT",
        "description": "OpenCBT COBOL Tutorials with banking/financial samples",
    },
    {
        "url": "https://github.com/mf-markchristie/COBOL-Banking-Example.git",
        "category": "cobol_banking",
        "license": "MIT",
        "description": "COBOL Banking Application Example",
    },
    {
        "url": "https://github.com/cicsdev/cics-banking-sample-application-cbsa.git",
        "category": "cobol_banking",
        "license": "Apache-2.0",
        "description": "CICS Banking Sample Application (CBSA) - IBM COBOL banking system",
    },
    {
        "url": "https://github.com/mikerowehl/COBOL-samples.git",
        "category": "cobol_banking",
        "license": "MIT",
        "description": "Collection of COBOL code samples",
    },

    # ── C Legacy Cryptography ──
    {
        "url": "https://github.com/openssl/openssl.git",
        "branch": "OpenSSL_1_0_1-stable",
        "category": "c_legacy_crypto",
        "license": "OpenSSL/Apache-2.0",
        "description": "OpenSSL 1.0.1 - Legacy cryptographic library (SHA-1, MD5, RSA, DES)",
        "subdirs": ["crypto"],
    },
    {
        "url": "https://github.com/B-Con/crypto-algorithms.git",
        "category": "c_legacy_crypto",
        "license": "Public Domain",
        "description": "Basic implementations of standard crypto algorithms (SHA-256, AES, DES, RSA)",
    },
    {
        "url": "https://github.com/kokke/tiny-AES-c.git",
        "category": "c_legacy_crypto",
        "license": "Public Domain",
        "description": "Small portable AES128/192/256 in C",
    },
    {
        "url": "https://github.com/ctz/cifern.git",
        "category": "c_legacy_crypto",
        "license": "MIT",
        "description": "Collection of cipher implementations in C",
    },
    {
        "url": "https://github.com/jb55/sha256.c.git",
        "category": "c_legacy_crypto",
        "license": "MIT",
        "description": "SHA-256 implementation in pure C89",
    },
    {
        "url": "https://github.com/Mbed-TLS/mbedtls.git",
        "branch": "mbedtls-2.16",
        "category": "c_legacy_crypto",
        "license": "Apache-2.0",
        "description": "Mbed TLS 2.16 LTS - portable crypto library (legacy branch)",
        "subdirs": ["library", "include"],
    },

    # ── C Financial / Mathematical ──
    {
        "url": "https://github.com/jgm/cmark.git",
        "category": "c_financial_math",
        "license": "BSD-2-Clause",
        "description": "C reference implementation - complex C89/C99 with manual memory management",
        "subdirs": ["src"],
    },
    {
        "url": "https://github.com/nothings/stb.git",
        "category": "c_financial_math",
        "license": "MIT/Public Domain",
        "description": "Single-file C libraries - heavy pointer math, struct alignment, bit manipulation",
    },
    {
        "url": "https://github.com/benhoyt/inih.git",
        "category": "c_financial_math",
        "license": "BSD-3-Clause",
        "description": "Simple INI file parser in C - classic C89 patterns",
    },
    {
        "url": "https://github.com/attractivechaos/klib.git",
        "category": "c_financial_math",
        "license": "MIT",
        "description": "Lightweight C library - hash tables, sorting, generic containers via macros",
    },
    {
        "url": "https://github.com/antirez/sds.git",
        "category": "c_financial_math",
        "license": "BSD-2-Clause",
        "description": "Simple Dynamic Strings library for C - raw pointer manipulation",
    },
    {
        "url": "https://github.com/clibs/clib.git",
        "category": "c_financial_math",
        "license": "MIT",
        "description": "C package manager - demonstrates legacy C patterns and build systems",
    },

    # ── Fortran Legacy ──
    {
        "url": "https://github.com/Reference-LAPACK/lapack.git",
        "category": "fortran_legacy",
        "license": "BSD-3-Clause",
        "description": "LAPACK - Linear Algebra Package, classic Fortran numerical computation",
        "subdirs": ["SRC", "BLAS/SRC"],
    },
    {
        "url": "https://github.com/jacobwilliams/Fortran-Astrodynamics-Toolkit.git",
        "category": "fortran_legacy",
        "license": "BSD-3-Clause",
        "description": "Fortran Astrodynamics Toolkit - scientific computation in modern & legacy Fortran",
    },
    {
        "url": "https://github.com/certik/fortran-utils.git",
        "category": "fortran_legacy",
        "license": "MIT",
        "description": "Fortran utility library with legacy-style numerical routines",
    },
    {
        "url": "https://github.com/urbanjost/M_strings.git",
        "category": "fortran_legacy",
        "license": "MIT",
        "description": "Fortran string manipulation module",
    },
    {
        "url": "https://github.com/Beliavsky/Fortran-code-on-GitHub.git",
        "category": "fortran_legacy",
        "license": "MIT",
        "description": "Index of Fortran projects on GitHub (contains sample Fortran code)",
    },

    # ── Legacy C++ ──
    {
        "url": "https://github.com/mortennobel/cpp-cheatsheet.git",
        "category": "cpp_legacy",
        "license": "MIT",
        "description": "C++ cheatsheet with legacy patterns (raw pointers, manual memory)",
    },
]

# ── GitHub API Search Queries ─────────────────────────────────────────────
SEARCH_QUERIES = [
    {
        "query": "COBOL banking language:COBOL",
        "category": "cobol_banking",
        "max_repos": 10,
    },
    {
        "query": "COBOL financial system language:COBOL",
        "category": "cobol_banking",
        "max_repos": 5,
    },
    {
        "query": "SHA1_Init language:c",
        "category": "c_legacy_crypto",
        "max_repos": 5,
    },
    {
        "query": "MD5 implementation language:c",
        "category": "c_legacy_crypto",
        "max_repos": 5,
    },
    {
        "query": "amortization calculator language:c",
        "category": "c_financial_math",
        "max_repos": 5,
    },
    {
        "query": "compound interest language:c",
        "category": "c_financial_math",
        "max_repos": 5,
    },
    {
        "query": "numerical computation language:fortran",
        "category": "fortran_legacy",
        "max_repos": 5,
    },
    {
        "query": "legacy C++ raw pointer malloc",
        "category": "cpp_legacy",
        "max_repos": 5,
    },
]

# ── Logging ───────────────────────────────────────────────────────────────
manifest_entries = []
stats = {
    "repos_cloned": 0,
    "repos_searched": 0,
    "files_extracted": 0,
    "files_skipped": 0,
    "total_bytes": 0,
    "errors": [],
}


def log(msg):
    ts = datetime.now().strftime("%H:%M:%S")
    line = f"[{ts}] {msg}"
    # Strip non-ASCII for Windows console safety
    safe_line = line.encode("ascii", errors="replace").decode("ascii")
    print(safe_line, flush=True)
    with open(LOG_FILE, "a", encoding="utf-8") as f:
        f.write(line + "\n")


def github_api_get(endpoint, params=None):
    """Make a GET request to GitHub API with optional auth."""
    url = f"{GITHUB_API}{endpoint}"
    if params:
        url += "?" + urllib.parse.urlencode(params)
    req = urllib.request.Request(url)
    req.add_header("Accept", "application/vnd.github.v3+json")
    req.add_header("User-Agent", "ChronosLegacyMiner/1.0")
    if GITHUB_TOKEN:
        req.add_header("Authorization", f"token {GITHUB_TOKEN}")
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        if e.code == 403:
            log(f"  ⚠ Rate limited. Waiting 60s...")
            time.sleep(60)
            return github_api_get(endpoint, params)
        log(f"  ✗ GitHub API error {e.code}: {e.reason}")
        return None
    except Exception as e:
        log(f"  ✗ Request error: {e}")
        return None


def detect_language_version(filepath, content):
    """Heuristic language version detection."""
    ext = filepath.suffix.lower()
    if ext in (".cob", ".cbl", ".cpy"):
        if "IDENTIFICATION DIVISION" in content:
            if "OBJECT-ORIENTED" in content or "METHOD-ID" in content:
                return "COBOL-2002"
            elif "EVALUATE" in content or "END-IF" in content:
                return "COBOL-85"
            return "COBOL-74"
        return "COBOL-85"
    elif ext in (".c", ".h"):
        if "///" in content or "inline " in content or "restrict " in content:
            return "C99"
        if "_Bool" in content or "stdbool.h" in content:
            return "C99"
        return "C89/C90"
    elif ext in (".f", ".f77", ".for"):
        return "Fortran-77"
    elif ext in (".f90",):
        return "Fortran-90"
    elif ext in (".f95",):
        return "Fortran-95"
    elif ext in (".cpp", ".cxx", ".cc", ".hpp", ".hxx"):
        if "auto " in content and "nullptr" in content:
            return "C++11"
        if "template" in content or "namespace" in content:
            return "C++98/03"
        return "C++98"
    return "Unknown"


def detect_legacy_features(content, category):
    """Identify specific legacy/technical-debt features in code."""
    features = []
    cat_key = None
    if "cobol" in category:
        cat_key = "cobol"
    elif "crypto" in category:
        cat_key = "c_crypto"
    elif "financial" in category or "math" in category:
        cat_key = "c_financial"
    elif "fortran" in category:
        cat_key = "fortran"
    elif "cpp" in category:
        cat_key = "cpp_legacy"

    # Universal C/C++ legacy patterns
    if category.startswith("c_") or category.startswith("cpp"):
        if "malloc(" in content or "calloc(" in content:
            features.append("Manual memory allocation (malloc/calloc)")
        if "free(" in content:
            features.append("Manual memory deallocation (free)")
        if "goto " in content:
            features.append("goto statement usage")
        if "sprintf(" in content or "vsprintf(" in content:
            features.append("Unsafe sprintf (buffer overflow risk)")
        if "strcpy(" in content or "strcat(" in content:
            features.append("Unsafe string operations (strcpy/strcat)")
        if re.search(r'\bgets\s*\(', content):
            features.append("Dangerous gets() function")
        if "reinterpret_cast" in content or "(void*)" in content or "(char*)" in content:
            features.append("Raw pointer casting")
        if re.search(r'<<\s*\d+|>>\s*\d+|&\s*0x|\|\s*0x|\^\s*0x', content):
            features.append("Bitwise operations")
        if "union " in content:
            features.append("Union type (type punning)")
        if "__attribute__" in content or "#pragma pack" in content:
            features.append("Struct alignment / packing directives")
        if "SHA1" in content or "sha1" in content:
            features.append("Uses SHA-1 (deprecated)")
        if "MD5" in content or "md5" in content:
            features.append("Uses MD5 (cryptographically broken)")
        if "DES_" in content or "des_" in content:
            features.append("Uses DES (weak cipher)")
        if "RSA_generate_key(" in content:
            features.append("Legacy RSA key generation")
        if "(float)" in content or "(double)" in content:
            features.append("Implicit/explicit float casting")
        if "switch" in content and "case " in content:
            features.append("Switch-case control flow")

    # COBOL-specific
    if cat_key == "cobol":
        if "GO TO" in content or "GOTO" in content:
            features.append("GO TO statement (spaghetti flow)")
        if "PERFORM" in content:
            features.append("PERFORM loop/paragraph calls")
        if "COPY " in content:
            features.append("COPY statement (include mechanism)")
        if "REDEFINES" in content:
            features.append("REDEFINES (memory aliasing)")
        if "COMP-3" in content or "PACKED-DECIMAL" in content:
            features.append("Packed decimal arithmetic (COMP-3)")
        if "EVALUATE" in content:
            features.append("EVALUATE (switch equivalent)")

    # Fortran-specific
    if cat_key == "fortran":
        if "COMMON" in content:
            features.append("COMMON blocks (global state)")
        if "EQUIVALENCE" in content:
            features.append("EQUIVALENCE (memory aliasing)")
        if "GOTO" in content or "GO TO" in content:
            features.append("GOTO statement")
        if "IMPLICIT NONE" not in content and "implicit none" not in content:
            features.append("Implicit typing (no IMPLICIT NONE)")

    return features if features else ["Standard legacy code patterns"]


def clone_repo(target):
    """Clone a repo (shallow) and extract source files."""
    url = target["url"]
    category = target["category"]
    branch = target.get("branch", None)
    subdirs = target.get("subdirs", None)
    license_info = target.get("license", "Unknown")
    description = target.get("description", "")

    repo_name = url.rstrip("/").rstrip(".git").split("/")[-1]
    clone_dir = TEMP_DIR / repo_name
    dest_dir = BASE_DIR / category / repo_name

    log(f"📦 Cloning {repo_name} → {category}/")

    # Clone with depth=1
    cmd = ["git", "clone", "--depth", "1"]
    if branch:
        cmd.extend(["--branch", branch])
    cmd.extend([url, str(clone_dir)])

    try:
        result = subprocess.run(
            cmd, capture_output=True, text=True, timeout=300,
            cwd=str(BASE_DIR)
        )
        if result.returncode != 0:
            log(f"  ✗ Clone failed: {result.stderr[:200]}")
            stats["errors"].append(f"Clone failed: {repo_name}: {result.stderr[:100]}")
            return 0
    except subprocess.TimeoutExpired:
        log(f"  ✗ Clone timed out for {repo_name}")
        stats["errors"].append(f"Clone timeout: {repo_name}")
        return 0
    except Exception as e:
        log(f"  ✗ Clone error: {e}")
        stats["errors"].append(f"Clone error: {repo_name}: {str(e)[:100]}")
        return 0

    stats["repos_cloned"] += 1

    # Determine which dirs to scan
    scan_dirs = []
    if subdirs:
        for sd in subdirs:
            sd_path = clone_dir / sd
            if sd_path.exists():
                scan_dirs.append(sd_path)
        if not scan_dirs:
            scan_dirs = [clone_dir]
    else:
        scan_dirs = [clone_dir]

    # Extract source files
    os.makedirs(dest_dir, exist_ok=True)
    count = 0
    for scan_dir in scan_dirs:
        for root, dirs, files in os.walk(scan_dir):
            # Skip .git and build directories
            dirs[:] = [d for d in dirs if d not in {".git", "build", "node_modules", "__pycache__", ".github"}]
            for fname in files:
                fpath = Path(root) / fname
                ext = fpath.suffix.lower()

                if ext not in SOURCE_EXTENSIONS:
                    stats["files_skipped"] += 1
                    continue

                # Skip very large files (> 500KB) - likely generated
                try:
                    fsize = fpath.stat().st_size
                except OSError:
                    continue
                if fsize > 500_000:
                    stats["files_skipped"] += 1
                    continue
                if fsize < 50:  # Skip trivially small files
                    stats["files_skipped"] += 1
                    continue

                # Read content
                try:
                    content = fpath.read_text(encoding="utf-8", errors="replace")
                except Exception:
                    stats["files_skipped"] += 1
                    continue

                # Build relative output path preserving some structure
                rel = fpath.relative_to(clone_dir)
                out_path = dest_dir / rel
                os.makedirs(out_path.parent, exist_ok=True)

                # Copy file
                shutil.copy2(fpath, out_path)
                count += 1
                stats["files_extracted"] += 1
                stats["total_bytes"] += fsize

                # Generate manifest entry
                lang_version = detect_language_version(fpath, content)
                legacy_features = detect_legacy_features(content, category)
                manifest_entries.append({
                    "file_path": str(out_path.relative_to(BASE_DIR)),
                    "source_repository": url,
                    "license": license_info,
                    "description": description,
                    "language_version": lang_version,
                    "file_size_bytes": fsize,
                    "line_count": content.count("\n") + 1,
                    "legacy_features": legacy_features,
                    "sha256": hashlib.sha256(content.encode("utf-8")).hexdigest()[:16],
                })

    log(f"  ✓ Extracted {count} source files from {repo_name}")

    # Cleanup clone
    try:
        shutil.rmtree(clone_dir, ignore_errors=True)
    except Exception:
        pass

    return count


def search_and_clone_repos(query_config):
    """Search GitHub API for repos and clone the top results."""
    query = query_config["query"]
    category = query_config["category"]
    max_repos = query_config.get("max_repos", 5)

    log(f"🔍 Searching GitHub: '{query}' → {category}/")

    data = github_api_get("/search/repositories", {
        "q": query,
        "sort": "stars",
        "order": "desc",
        "per_page": min(max_repos, 10),
    })

    if not data or "items" not in data:
        log(f"  ✗ No results for query: {query}")
        return 0

    stats["repos_searched"] += 1
    total = 0

    for item in data["items"][:max_repos]:
        clone_url = item.get("clone_url", "")
        repo_name = item.get("full_name", "unknown")
        license_info = "Unknown"
        if item.get("license") and item["license"].get("spdx_id"):
            license_info = item["license"]["spdx_id"]

        # Skip if already cloned
        dest_check = BASE_DIR / category / repo_name.split("/")[-1]
        if dest_check.exists():
            log(f"  ⏭ Skipping {repo_name} (already exists)")
            continue

        if not clone_url:
            continue

        target = {
            "url": clone_url,
            "category": category,
            "license": license_info,
            "description": item.get("description", "")[:200] if item.get("description") else "",
        }
        count = clone_repo(target)
        total += count

        # Brief pause to be nice to GitHub
        time.sleep(2)

    return total


def download_raw_files():
    """Download specific raw files from known URLs as fallback."""
    raw_files = [
        # ── Additional COBOL samples from raw URLs ──
        {
            "url": "https://raw.githubusercontent.com/openmainframeproject/cobol-programming-course/master/COBOL%20Programming%20Course%20%231%20-%20Getting%20Started/Labs/cbl/CBL0001.cobol",
            "dest": "cobol_banking/_raw_samples/CBL0001.cobol",
            "license": "GPL-3.0",
            "source": "openmainframeproject/cobol-programming-course",
        },
        {
            "url": "https://raw.githubusercontent.com/openmainframeproject/cobol-programming-course/master/COBOL%20Programming%20Course%20%231%20-%20Getting%20Started/Labs/cbl/CBL0002.cobol",
            "dest": "cobol_banking/_raw_samples/CBL0002.cobol",
            "license": "GPL-3.0",
            "source": "openmainframeproject/cobol-programming-course",
        },
    ]

    log("📥 Downloading additional raw source files...")
    count = 0
    for item in raw_files:
        dest = BASE_DIR / item["dest"]
        os.makedirs(dest.parent, exist_ok=True)
        try:
            req = urllib.request.Request(item["url"])
            req.add_header("User-Agent", "ChronosLegacyMiner/1.0")
            with urllib.request.urlopen(req, timeout=30) as resp:
                content = resp.read().decode("utf-8", errors="replace")
            dest.write_text(content, encoding="utf-8")
            count += 1
            stats["files_extracted"] += 1
            stats["total_bytes"] += len(content)

            ext = dest.suffix.lower()
            fake_path = Path(dest.name)
            lang_version = detect_language_version(fake_path, content)
            legacy_features = detect_legacy_features(content, item.get("category", "cobol_banking"))

            manifest_entries.append({
                "file_path": item["dest"],
                "source_repository": item["source"],
                "license": item["license"],
                "language_version": lang_version,
                "file_size_bytes": len(content),
                "line_count": content.count("\n") + 1,
                "legacy_features": legacy_features,
                "sha256": hashlib.sha256(content.encode("utf-8")).hexdigest()[:16],
            })
            log(f"  ✓ {dest.name}")
        except Exception as e:
            log(f"  ✗ Failed to download {item['url']}: {e}")
            stats["errors"].append(f"Download failed: {item['url']}: {str(e)[:100]}")

    return count


def generate_manifest():
    """Write the MANIFEST.json with all collected metadata."""
    manifest = {
        "dataset_name": "Chronos Legacy Code Dataset",
        "version": "1.0.0",
        "generated_at": datetime.now().isoformat(),
        "purpose": "AI Transpiler Benchmarking (IBM Bob 2.0)",
        "statistics": {
            "total_files": stats["files_extracted"],
            "total_bytes": stats["total_bytes"],
            "total_size_mb": round(stats["total_bytes"] / (1024 * 1024), 2),
            "repos_cloned": stats["repos_cloned"],
            "repos_searched_via_api": stats["repos_searched"],
            "files_skipped": stats["files_skipped"],
            "errors": len(stats["errors"]),
        },
        "categories": {
            "cobol_banking": {
                "description": "COBOL banking/financial legacy systems",
                "target_versions": ["COBOL-74", "COBOL-85", "COBOL-2002"],
            },
            "c_legacy_crypto": {
                "description": "C89/C99 legacy cryptographic routines (SHA-1, MD5, RSA, DES)",
                "target_versions": ["C89/C90", "C99"],
            },
            "c_financial_math": {
                "description": "C financial math, struct-heavy libraries, manual memory management",
                "target_versions": ["C89/C90", "C99"],
            },
            "fortran_legacy": {
                "description": "Fortran 77/90/95 numerical computation and scientific code",
                "target_versions": ["Fortran-77", "Fortran-90", "Fortran-95"],
            },
            "cpp_legacy": {
                "description": "Legacy C++ with raw pointers, manual memory, C-style patterns",
                "target_versions": ["C++98", "C++03", "C++11"],
            },
        },
        "files": sorted(manifest_entries, key=lambda x: x["file_path"]),
    }

    with open(MANIFEST_PATH, "w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=2, ensure_ascii=False)

    log(f"📋 Manifest written: {MANIFEST_PATH} ({len(manifest_entries)} entries)")


def print_summary():
    """Print final statistics."""
    log("=" * 60)
    log("📊 MINING COMPLETE - SUMMARY")
    log("=" * 60)
    log(f"  Repositories cloned:     {stats['repos_cloned']}")
    log(f"  API searches executed:   {stats['repos_searched']}")
    log(f"  Source files extracted:   {stats['files_extracted']}")
    log(f"  Files skipped:           {stats['files_skipped']}")
    log(f"  Total dataset size:      {stats['total_bytes'] / (1024*1024):.2f} MB")
    log(f"  Errors:                  {len(stats['errors'])}")
    if stats["errors"]:
        log("  Error details:")
        for err in stats["errors"][:10]:
            log(f"    - {err}")
    log("=" * 60)


# ── Main Pipeline ─────────────────────────────────────────────────────────
def main():
    log("=" * 60)
    log("🚀 CHRONOS LEGACY CODE MINING PIPELINE v1.0")
    log(f"   Base directory: {BASE_DIR}")
    log(f"   GitHub Token:   {'Set ✓' if GITHUB_TOKEN else 'Not set (60 req/hr limit)'}")
    log("=" * 60)

    # Create temp dir
    os.makedirs(TEMP_DIR, exist_ok=True)

    # Phase 1: Clone well-known repos
    log("\n" + "─" * 40)
    log("PHASE 1: Cloning Known Legacy Repositories")
    log("─" * 40)
    for target in CLONE_TARGETS:
        try:
            clone_repo(target)
        except Exception as e:
            log(f"  ✗ Unexpected error: {e}")
            stats["errors"].append(str(e)[:200])
        time.sleep(1)

    # Phase 2: GitHub API search for additional repos
    log("\n" + "─" * 40)
    log("PHASE 2: GitHub API Search & Clone")
    log("─" * 40)
    for query_config in SEARCH_QUERIES:
        try:
            search_and_clone_repos(query_config)
        except Exception as e:
            log(f"  ✗ Search error: {e}")
            stats["errors"].append(str(e)[:200])
        time.sleep(3)  # Rate limit courtesy

    # Phase 3: Download specific raw files
    log("\n" + "─" * 40)
    log("PHASE 3: Direct Raw File Downloads")
    log("─" * 40)
    download_raw_files()

    # Phase 4: Generate manifest
    log("\n" + "─" * 40)
    log("PHASE 4: Generating Manifest")
    log("─" * 40)
    generate_manifest()

    # Cleanup temp directory
    try:
        shutil.rmtree(TEMP_DIR, ignore_errors=True)
    except Exception:
        pass

    # Summary
    print_summary()

    return 0


if __name__ == "__main__":
    sys.exit(main())
