#!/usr/bin/env python3
"""
classify_legacy_dataset.py
==========================
Phân loại các file code legacy theo các tiêu chí và đường dẫn thư mục:
- Domain Nghiệp vụ:
    + /domain/banking_core/
    + /domain/legacy_crypto/
    + /domain/math_matrix/
- Đặc tính Kỹ thuật:
    + /tech/struct_alignment/
    + /tech/spaghetti_logic/
    + /tech/memory_unsafe/
"""

import os
import sys
import shutil
import json
from pathlib import Path

# Ensure UTF-8 output on Windows console
if sys.stdout.encoding != 'utf-8':
    try:
        sys.stdout.reconfigure(encoding='utf-8')
        sys.stderr.reconfigure(encoding='utf-8')
    except Exception:
        pass

ROOT_DIR = Path(__file__).parent.resolve()
DATASET_DIR = ROOT_DIR / "chronos-legacy-dataset"

CATEGORIES = {
    "domain/banking_core": {
        "title": "Domain Nghiệp vụ: Banking Core",
        "description": "Mã C/COBOL tính toán lãi suất, hạn mức tín dụng, sổ cái tài chính.",
        "criteria": "Mã nguồn COBOL và C phục vụ nghiệp vụ ngân hàng lõi, quản lý tài khoản, giao dịch, sổ cái và các công cụ tính toán lãi suất (lãi đơn, lãi kép, khấu hao dư nợ).",
    },
    "domain/legacy_crypto": {
        "title": "Domain Nghiệp vụ: Legacy Cryptography",
        "description": "Các module băm dữ liệu cổ SHA-1, MD5, mã hóa RSA-1024 / DES.",
        "criteria": "Các module mật mã học cổ điển bao gồm thuật toán băm (SHA-1, MD5) và thuật toán mã hóa khóa công khai/đối xứng (RSA-1024, DES).",
    },
    "domain/math_matrix": {
        "title": "Domain Nghiệp vụ: Math & Matrix Algorithms",
        "description": "Thuật toán ma trận, đại số tuyến tính, tính toán tài chính định lượng.",
        "criteria": "Các giải thuật tính toán ma trận cấp cao (nhân ma trận BLAS dgemm/sgemm, phân rã LU, QR, Cholesky, SVD, trị riêng LAPACK) và thuật toán định lượng.",
    },
    "tech/struct_alignment": {
        "title": "Đặc tính Kỹ thuật: Struct Alignment & Memory Packing",
        "description": "Code chứa C-struct căn chỉnh bộ nhớ 24-bytes thủ công.",
        "criteria": "Các cấu trúc dữ liệu C-struct được thiết kế căn chỉnh bộ nhớ thủ công: logic alignment 24-byte struct, struct header 24 bytes (3 con trỏ/kích thước 8 bytes), bitfields n_args:24, padding bytes thủ công.",
    },
    "tech/spaghetti_logic": {
        "title": "Đặc tính Kỹ thuật: Spaghetti Control Flow",
        "description": "Code rẽ nhánh phức tạp, vòng lặp lồng nhau, switch-case không break.",
        "criteria": "Mã nguồn có độ phức tạp chu trình cao (Cyclomatic Complexity), rẽ nhánh phức tạp, vòng lặp lồng sâu, switch-case fallthrough không có break, hoặc lạm dụng lệnh nhảy goto / GO TO.",
    },
    "tech/memory_unsafe": {
        "title": "Đặc tính Kỹ thuật: Memory Unsafe & Raw Pointers",
        "description": "Code dùng con trỏ thô, cấp phát bộ nhớ động `malloc`/`free`.",
        "criteria": "Mã nguồn sử dụng nhiều con trỏ thô (raw pointers), số học con trỏ (pointer arithmetic), và cấp phát/thu hồi bộ nhớ thủ công qua malloc, calloc, realloc, free.",
    },
}

def ensure_dir(path: Path):
    path.mkdir(parents=True, exist_ok=True)

def copy_file_safe(src: Path, dest_dir: Path, prefix: str = "") -> Path:
    ensure_dir(dest_dir)
    dest_name = f"{prefix}_{src.name}" if prefix else src.name
    dest_path = dest_dir / dest_name
    shutil.copy2(src, dest_path)
    return dest_path

def classify():
    print("🚀 Bắt đầu quá trình phân loại mã nguồn legacy...")
    
    classification_manifest = {
        "generated_at": "2026-09-17",
        "total_classified_categories": len(CATEGORIES),
        "categories": {}
    }

    # 1. DOMAIN: banking_core
    # Sources: cobol_banking repos + c_financial_math interest/amortization calculators
    dest_banking = ROOT_DIR / "domain" / "banking_core"
    ensure_dir(dest_banking)
    banking_files = []
    
    # 1.1 COBOL banking
    cobol_dir = DATASET_DIR / "cobol_banking"
    for p in cobol_dir.rglob("*.*"):
        if p.is_file() and p.suffix.lower() in [".cob", ".cbl", ".cpy"]:
            rel = p.relative_to(cobol_dir)
            target = dest_banking / "cobol" / rel
            ensure_dir(target.parent)
            shutil.copy2(p, target)
            banking_files.append({
                "source": str(p.relative_to(ROOT_DIR)),
                "classified_path": str(target.relative_to(ROOT_DIR)),
                "type": "COBOL Core Banking / Ledger",
                "size_bytes": p.stat().st_size
            })
            
    # 1.2 C Financial Calculators (Interest, Amortization, Loans)
    c_fin_dir = DATASET_DIR / "c_financial_math"
    for p in c_fin_dir.rglob("*.[ch]"):
        p_str = str(p).lower()
        if any(k in p_str for k in ["amortization", "interest", "compound"]):
            rel = p.relative_to(c_fin_dir)
            target = dest_banking / "c_calculators" / rel
            ensure_dir(target.parent)
            shutil.copy2(p, target)
            banking_files.append({
                "source": str(p.relative_to(ROOT_DIR)),
                "classified_path": str(target.relative_to(ROOT_DIR)),
                "type": "C Interest & Loan Payment Calculator",
                "size_bytes": p.stat().st_size
            })

    # 2. DOMAIN: legacy_crypto
    # Sources: SHA-1, MD5, RSA-1024, DES modules
    dest_crypto = ROOT_DIR / "domain" / "legacy_crypto"
    ensure_dir(dest_crypto)
    crypto_files = []
    crypto_dir = DATASET_DIR / "c_legacy_crypto"
    
    for p in crypto_dir.rglob("*.[ch]"):
        p_str = str(p).lower()
        name = p.name.lower()
        
        algo = None
        if "sha1" in name or "sha1" in p_str or name in ["sha.h", "sha_locl.h", "sha_dgst.c"]:
            algo = "sha1"
        elif "md5" in name or "md5" in p_str:
            algo = "md5"
        elif any(k in name for k in ["rsa_gen", "rsa_sign", "rsa_ssl", "rsa_pk1", "rsa_oaep", "rsa_saos", "rsa_pmeth", "rsa_lib", "rsa_eay"]) or (name == "rsa.h" and "crypto/rsa" in p_str.replace("\\", "/")):
            algo = "rsa1024"
        elif ("des" in name or "set_key.c" in name or "fcrypt.c" in name or "ecb_enc.c" in name or "cbc_enc.c" in name) and "crypto/des" in p_str.replace("\\", "/"):
            algo = "des"
        elif "crypto-algorithms" in p_str and any(k in name for k in ["sha1", "md5", "des"]):
            algo = "algorithms_suite"

        if algo:
            target = dest_crypto / algo / p.name
            # If collision, prefix with parent dir
            if target.exists():
                target = dest_crypto / algo / f"{p.parent.name}_{p.name}"
            ensure_dir(target.parent)
            shutil.copy2(p, target)
            crypto_files.append({
                "source": str(p.relative_to(ROOT_DIR)),
                "classified_path": str(target.relative_to(ROOT_DIR)),
                "algorithm": algo,
                "size_bytes": p.stat().st_size
            })

    # 3. DOMAIN: math_matrix
    # Sources: Fortran LAPACK/BLAS matrix routines + C quantitative matrix modules
    dest_matrix = ROOT_DIR / "domain" / "math_matrix"
    ensure_dir(dest_matrix)
    matrix_files = []
    
    # 3.1 BLAS & LAPACK core matrix routines
    fortran_dir = DATASET_DIR / "fortran_legacy"
    matrix_prefixes = (
        "dgemm", "sgemm", "zgemm", "cgemm",
        "dgemv", "sgemv", "zgemv", "cgemv",
        "dtrmm", "strmm", "dsyrk", "ssyrk",
        "dsymm", "ssymm", "dtrsm", "strsm",
        "dgetrf", "sgetrf", "dgetrs", "sgetrs",
        "dgesv", "sgesv", "dpotrf", "spotrf",
        "dpotrs", "spotrs", "dsyev", "ssyev",
        "dgesvd", "sgesvd"
    )
    for p in fortran_dir.rglob("*.*"):
        if p.is_file() and p.suffix.lower() in [".f", ".f90", ".f77", ".for"]:
            stem = p.stem.lower()
            if any(stem == prefix for prefix in matrix_prefixes):
                subfolder = "blas" if any(stem.endswith(x) for x in ["gemm", "gemv", "trmm", "syrk", "symm", "trsm"]) else "lapack"
                target = dest_matrix / subfolder / p.name
                ensure_dir(target.parent)
                shutil.copy2(p, target)
                matrix_files.append({
                    "source": str(p.relative_to(ROOT_DIR)),
                    "classified_path": str(target.relative_to(ROOT_DIR)),
                    "module": subfolder.upper(),
                    "size_bytes": p.stat().st_size
                })
                
    # 3.2 C Quantitative matrix routines (pfapack C-interface, khmm)
    c_matrix_targets = [
        DATASET_DIR / "fortran_legacy" / "pfapack" / "original_source" / "c_interface" / "skpf10.c",
        DATASET_DIR / "fortran_legacy" / "pfapack" / "original_source" / "c_interface" / "skpfa.c",
        DATASET_DIR / "fortran_legacy" / "pfapack" / "original_source" / "c_interface" / "sktrd.c",
        DATASET_DIR / "fortran_legacy" / "pfapack" / "original_source" / "c_interface" / "skbtrd.c",
        DATASET_DIR / "fortran_legacy" / "pfapack" / "original_source" / "c_interface" / "c_interface.h",
        DATASET_DIR / "c_financial_math" / "klib" / "khmm.c",
    ]
    for p in c_matrix_targets:
        if p.exists():
            target = dest_matrix / "c_quantitative" / p.name
            ensure_dir(target.parent)
            shutil.copy2(p, target)
            matrix_files.append({
                "source": str(p.relative_to(ROOT_DIR)),
                "classified_path": str(target.relative_to(ROOT_DIR)),
                "module": "C Quantitative Matrix / Linear Algebra",
                "size_bytes": p.stat().st_size
            })

    # 4. TECH: struct_alignment
    # Sources: C files with manual 24-byte alignment, 24-byte structs, bitfields n_args:24, manual padding
    dest_struct = ROOT_DIR / "tech" / "struct_alignment"
    ensure_dir(dest_struct)
    struct_files = []
    
    struct_targets = [
        (DATASET_DIR / "c_financial_math" / "stb" / "deprecated" / "stb.h", "24-byte struct alignment logic (malloc_base, line 2910)"),
        (DATASET_DIR / "c_financial_math" / "klib" / "kexpr.c", "Bitfield packed 24-byte operator struct (n_args:24, ke1_s)"),
        (DATASET_DIR / "c_financial_math" / "klib" / "kstring.h", "24-byte struct header layout (size_t l, m; char *s)"),
        (DATASET_DIR / "c_financial_math" / "klib" / "kvec.h", "24-byte dynamic vector header (size_t n, m; type *a)"),
        (DATASET_DIR / "c_legacy_crypto" / "openssl" / "crypto" / "des" / "des_old.h", "Manual struct padding for 8/24-byte alignment (DES_LONG pad[2])"),
        (DATASET_DIR / "c_legacy_crypto" / "openssl" / "crypto" / "ec" / "ec_curve.c", "Manual 24-byte coordinate buffer packing for elliptic curve data"),
        (DATASET_DIR / "c_financial_math" / "stb" / "stb_truetype.h", "Manual struct packing & padding (stbtt_pack_context, stbtt_vertex)"),
        (DATASET_DIR / "c_financial_math" / "stb" / "tests" / "prerelease" / "stb_lib.h", "Manual multiple of 16/24 padding in struct header"),
        (DATASET_DIR / "c_financial_math" / "stb" / "tests" / "caveview" / "cave_render.c", "Manual cache alignment struct padding (int padding[13])"),
    ]
    for p, note in struct_targets:
        if p.exists():
            target = dest_struct / p.name
            if target.exists():
                target = dest_struct / f"{p.parent.name}_{p.name}"
            shutil.copy2(p, target)
            struct_files.append({
                "source": str(p.relative_to(ROOT_DIR)),
                "classified_path": str(target.relative_to(ROOT_DIR)),
                "alignment_characteristic": note,
                "size_bytes": p.stat().st_size
            })

    # 5. TECH: spaghetti_logic
    # Sources: Heavy gotos, switch fallthroughs without break, nested loops
    dest_spaghetti = ROOT_DIR / "tech" / "spaghetti_logic"
    ensure_dir(dest_spaghetti)
    spaghetti_files = []
    
    spaghetti_targets = [
        (DATASET_DIR / "c_financial_math" / "cmark" / "src" / "scanners.c", "cmark_scanners.c", "Complex state machine: 3,069 goto jumps, 50 switch fallthroughs"),
        (DATASET_DIR / "c_financial_math" / "clib" / "deps" / "gumbo-parser" / "tokenizer.c", "gumbo_tokenizer.c", "Dense tokenizer: 89 switch-case fallthroughs without break"),
        (DATASET_DIR / "c_financial_math" / "cmark" / "src" / "node.c", "cmark_node.c", "Nested control flow: 20 switch fallthroughs"),
        (DATASET_DIR / "c_legacy_crypto" / "openssl" / "crypto" / "asn1" / "tasn_dec.c", "openssl_tasn_dec.c", "ASN.1 decoder engine: 47 gotos, 10 switch fallthroughs"),
        (DATASET_DIR / "c_legacy_crypto" / "openssl" / "crypto" / "bn" / "bn_mul.c", "openssl_bn_mul.c", "Multiprecision multiplication: 19 gotos, deeply nested loops"),
        (DATASET_DIR / "cobol_banking" / "cobol-legacy-ledger" / "COBOL-BANKING" / "payroll" / "src" / "MERCHANT.cob", "MERCHANT.cob", "COBOL spaghetti: 40 GO TO statements"),
        (DATASET_DIR / "cobol_banking" / "cobol-legacy-ledger" / "COBOL-BANKING" / "payroll" / "src" / "PAYROLL.cob", "PAYROLL.cob", "COBOL spaghetti: 28 GO TO statements, nested PERFORM"),
        (DATASET_DIR / "cobol_banking" / "cobol-legacy-ledger" / "COBOL-BANKING" / "payroll" / "src" / "DISPUTE.cob", "DISPUTE.cob", "COBOL spaghetti: 19 GO TO statements, 33 PERFORM loops"),
        (DATASET_DIR / "cobol_banking" / "banking-batch-cobol-2016" / "PROGRAMS" / "BATCHPROC.CBL", "BATCHPROC.CBL", "COBOL batch processor: 19 GO TO statements, complex branching"),
    ]
    for p, out_name, note in spaghetti_targets:
        if p.exists():
            target = dest_spaghetti / out_name
            shutil.copy2(p, target)
            spaghetti_files.append({
                "source": str(p.relative_to(ROOT_DIR)),
                "classified_path": str(target.relative_to(ROOT_DIR)),
                "spaghetti_pattern": note,
                "size_bytes": p.stat().st_size
            })

    # 6. TECH: memory_unsafe
    # Sources: Heavy raw pointers, malloc/free, pointer arithmetic, custom allocators
    dest_memory = ROOT_DIR / "tech" / "memory_unsafe"
    ensure_dir(dest_memory)
    memory_files = []
    
    memory_targets = [
        (DATASET_DIR / "c_financial_math" / "stb" / "deprecated" / "stb.h", "stb.h", "112 malloc/realloc calls, 102 free calls, manual block allocators"),
        (DATASET_DIR / "c_financial_math" / "stb" / "stb_image.h", "stb_image.h", "11 malloc, 14 free calls, raw pointer buffer walking"),
        (DATASET_DIR / "c_financial_math" / "sds" / "sds.c", "sds.c", "Raw pointer tricks (s[-1] header offset), malloc/realloc/free"),
        (DATASET_DIR / "c_financial_math" / "clib" / "src" / "common" / "clib-package.c", "clib-package.c", "Dynamic struct management: 10 mallocs, 53 frees, raw pointers"),
        (DATASET_DIR / "c_financial_math" / "clib" / "src" / "clib-configure.c", "clib-configure.c", "5 mallocs, 21 frees with manual memory lifecycle"),
        (DATASET_DIR / "c_financial_math" / "klib" / "khmm.c", "khmm.c", "2D dynamic matrix allocation (double **), 12 mallocs, 43 frees"),
        (DATASET_DIR / "c_financial_math" / "klib" / "kopen.c", "kopen.c", "Low-level buffer allocation: 12 mallocs, 11 frees"),
        (DATASET_DIR / "fortran_legacy" / "pfapack" / "original_source" / "c_interface" / "skpf10.c", "skpf10.c", "Raw pointer interface array allocation: 14 mallocs, 18 frees"),
        (DATASET_DIR / "fortran_legacy" / "pfapack" / "original_source" / "c_interface" / "skpfa.c", "skpfa.c", "Raw pointer interface array allocation: 14 mallocs, 18 frees"),
        (DATASET_DIR / "fortran_legacy" / "pfapack" / "original_source" / "c_interface" / "sktrd.c", "sktrd.c", "Raw pointer matrix transforms: 12 mallocs, 12 frees"),
    ]
    for p, out_name, note in memory_targets:
        if p.exists():
            target = dest_memory / out_name
            shutil.copy2(p, target)
            memory_files.append({
                "source": str(p.relative_to(ROOT_DIR)),
                "classified_path": str(target.relative_to(ROOT_DIR)),
                "memory_pattern": note,
                "size_bytes": p.stat().st_size
            })

    # Save to manifest
    classification_manifest["categories"]["domain/banking_core"] = {
        "description": CATEGORIES["domain/banking_core"]["description"],
        "total_files": len(banking_files),
        "files": banking_files
    }
    classification_manifest["categories"]["domain/legacy_crypto"] = {
        "description": CATEGORIES["domain/legacy_crypto"]["description"],
        "total_files": len(crypto_files),
        "files": crypto_files
    }
    classification_manifest["categories"]["domain/math_matrix"] = {
        "description": CATEGORIES["domain/math_matrix"]["description"],
        "total_files": len(matrix_files),
        "files": matrix_files
    }
    classification_manifest["categories"]["tech/struct_alignment"] = {
        "description": CATEGORIES["tech/struct_alignment"]["description"],
        "total_files": len(struct_files),
        "files": struct_files
    }
    classification_manifest["categories"]["tech/spaghetti_logic"] = {
        "description": CATEGORIES["tech/spaghetti_logic"]["description"],
        "total_files": len(spaghetti_files),
        "files": spaghetti_files
    }
    classification_manifest["categories"]["tech/memory_unsafe"] = {
        "description": CATEGORIES["tech/memory_unsafe"]["description"],
        "total_files": len(memory_files),
        "files": memory_files
    }

    # Write README.md in each classified directory
    for cat_dir_str, meta in CATEGORIES.items():
        cat_path = ROOT_DIR / cat_dir_str
        readme_path = cat_path / "README.md"
        cat_info = classification_manifest["categories"][cat_dir_str]
        
        lines = [
            f"# {meta['title']}",
            "",
            f"**Đường dẫn thư mục**: `/{cat_dir_str}/`",
            "",
            f"## Tiêu chuẩn mã nguồn (Theo yêu cầu)",
            f"> {meta['description']}",
            "",
            f"### Chi tiết tiêu chí",
            f"{meta['criteria']}",
            "",
            f"## Thống kê",
            f"- **Tổng số file phân loại**: {cat_info['total_files']} files",
            "",
            f"## Danh sách file mẫu tiêu biểu",
            "| Tên File | Phân loại / Đặc điểm | Kích thước (bytes) |",
            "| :--- | :--- | :--- |",
        ]
        
        sample_files = cat_info["files"][:25]
        for f in sample_files:
            file_name = Path(f["classified_path"]).name
            detail = f.get("type") or f.get("algorithm") or f.get("module") or f.get("alignment_characteristic") or f.get("spaghetti_pattern") or f.get("memory_pattern") or "Legacy module"
            size = f["size_bytes"]
            lines.append(f"| `{file_name}` | {detail} | {size:,} |")
            
        if len(cat_info["files"]) > 25:
            lines.append(f"| *... và {len(cat_info['files']) - 25} file khác ...* | | |")
            
        lines.append("")
        readme_path.write_text("\n".join(lines), encoding="utf-8")

    # Write Root Master Report
    report_path = ROOT_DIR / "CLASSIFICATION_REPORT.md"
    report_lines = [
        "# Báo cáo Phân loại Tập dữ liệu Mã nguồn Legacy (Chronos AI Dataset)",
        "",
        "Báo cáo này tổng hợp kết quả phân loại các file mã nguồn legacy trong dự án theo đúng bảng tiêu chuẩn đường dẫn và đặc điểm lưu trữ.",
        "",
        "## Bảng Tổng hợp Phân loại",
        "| Tiêu chí | Đường dẫn thư mục | Đặc điểm mã nguồn lưu trữ | Số lượng file |",
        "| :--- | :--- | :--- | :--- |",
        f"| **Domain Nghiệp vụ** | [`/domain/banking_core/`](file:///c:/Phong/chronos-ai/domain/banking_core) | Mã C/COBOL tính toán lãi suất, hạn mức tín dụng, sổ cái tài chính. | {len(banking_files)} |",
        f"| **Domain Nghiệp vụ** | [`/domain/legacy_crypto/`](file:///c:/Phong/chronos-ai/domain/legacy_crypto) | Các module băm dữ liệu cổ SHA-1, MD5, mã hóa RSA-1024 / DES. | {len(crypto_files)} |",
        f"| **Domain Nghiệp vụ** | [`/domain/math_matrix/`](file:///c:/Phong/chronos-ai/domain/math_matrix) | Thuật toán ma trận, đại số tuyến tính, tính toán tài chính định lượng. | {len(matrix_files)} |",
        f"| **Đặc tính Kỹ thuật** | [`/tech/struct_alignment/`](file:///c:/Phong/chronos-ai/tech/struct_alignment) | Code chứa C-struct căn chỉnh bộ nhớ 24-bytes thủ công. | {len(struct_files)} |",
        f"| **Đặc tính Kỹ thuật** | [`/tech/spaghetti_logic/`](file:///c:/Phong/chronos-ai/tech/spaghetti_logic) | Code rẽ nhánh phức tạp, vòng lặp lồng nhau, switch-case không break. | {len(spaghetti_files)} |",
        f"| **Đặc tính Kỹ thuật** | [`/tech/memory_unsafe/`](file:///c:/Phong/chronos-ai/tech/memory_unsafe) | Code dùng con trỏ thô, cấp phát bộ nhớ động `malloc`/`free`. | {len(memory_files)} |",
        "",
        f"**Tổng số file đã được lập danh mục và phân loại:** {len(banking_files) + len(crypto_files) + len(matrix_files) + len(struct_files) + len(spaghetti_files) + len(memory_files)} files.",
        "",
        "## Cấu trúc Cây thư mục",
        "```",
        "chronos-ai/",
        "├── domain/",
        f"│   ├── banking_core/          # {len(banking_files)} files (COBOL core banking + C interest/amortization)",
        f"│   ├── legacy_crypto/         # {len(crypto_files)} files (SHA-1, MD5, RSA-1024, DES)",
        f"│   └── math_matrix/           # {len(matrix_files)} files (BLAS matrix multiply, LAPACK decomposition, C matrix)",
        "└── tech/",
        f"    ├── struct_alignment/      # {len(struct_files)} files (24-byte struct alignment, bitfields, manual padding)",
        f"    ├── spaghetti_logic/       # {len(spaghetti_files)} files (3000+ gotos, 89 switch fallthroughs, COBOL GO TOs)",
        f"    └── memory_unsafe/         # {len(memory_files)} files (malloc/realloc/free, raw pointer arithmetic)",
        "```",
    ]
    report_path.write_text("\n".join(report_lines), encoding="utf-8")

    # Save manifest json
    manifest_out = ROOT_DIR / "classification_manifest.json"
    manifest_out.write_text(json.dumps(classification_manifest, indent=2, ensure_ascii=False), encoding="utf-8")

    print("✅ Hoàn thành phân loại thành công!")
    print(f"- domain/banking_core: {len(banking_files)} files")
    print(f"- domain/legacy_crypto: {len(crypto_files)} files")
    print(f"- domain/math_matrix: {len(matrix_files)} files")
    print(f"- tech/struct_alignment: {len(struct_files)} files")
    print(f"- tech/spaghetti_logic: {len(spaghetti_files)} files")
    print(f"- tech/memory_unsafe: {len(memory_files)} files")
    print(f"- Báo cáo tổng hợp: {report_path}")

if __name__ == "__main__":
    classify()
