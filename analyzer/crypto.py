"""
crypto.py - Legacy cryptography detection (SHA-1, MD5, RSA, DES, RC4, etc.).
"""

from typing import Dict, Any, List, Optional
import re


CRYPTO_PATTERNS = {
    "SHA1": [
        r'\bSHA1_Init\b',
        r'\bSHA1_Update\b',
        r'\bSHA1_Final\b',
        r'\bSHA1\b',
        r'\bsha1_transform\b',
        r'\bSHA_CTX\b',
    ],
    "MD5": [
        r'\bMD5_Init\b',
        r'\bMD5_Update\b',
        r'\bMD5_Final\b',
        r'\bMD5\b',
        r'\bmd5_transform\b',
        r'\bMD5_CTX\b',
    ],
    "RSA": [
        r'\bRSA_generate_key\b',
        r'\bRSA_generate_key_ex\b',
        r'\bRSA_private_encrypt\b',
        r'\bRSA_public_encrypt\b',
        r'\bRSA_new\b',
        r'\bRSA_check_key\b',
        r'\bRSA_size\b',
    ],
    "DES": [
        r'\bDES_ecb_encrypt\b',
        r'\bDES_set_key\b',
        r'\bDES_cbc_encrypt\b',
        r'\bDES_key_schedule\b',
    ],
    "RC4": [
        r'\bRC4_set_key\b',
        r'\bRC4\b',
    ],
    "DSA": [
        r'\bDSA_generate_parameters\b',
        r'\bDSA_sign\b',
        r'\bDSA_verify\b',
    ]
}


def analyze_crypto(code: str) -> Dict[str, Any]:
    """Analyze presence and frequency of legacy cryptographic symbols."""
    lines = code.splitlines()

    sha1_count = 0
    md5_count = 0
    rsa_count = 0
    other_crypto_count = 0

    crypto_algorithms_detected = []
    crypto_evidence: List[Dict[str, Any]] = []

    for algo, patterns in CRYPTO_PATTERNS.items():
        algo_matches = 0
        for pattern in patterns:
            for m in re.finditer(pattern, code):
                algo_matches += 1
                line_no = code[:m.start()].count("\n") + 1
                matched_symbol = m.group(0)
                crypto_evidence.append({
                    "algorithm": algo,
                    "symbol": matched_symbol,
                    "line": line_no,
                    "code": lines[line_no - 1].strip(),
                    "reason": f"Legacy cryptographic primitive '{matched_symbol}' ({algo}) detected"
                })

        if algo_matches > 0:
            crypto_algorithms_detected.append(algo)

        if algo == "SHA1":
            sha1_count = algo_matches
        elif algo == "MD5":
            md5_count = algo_matches
        elif algo == "RSA":
            rsa_count = algo_matches
        else:
            other_crypto_count += algo_matches

    has_sha1 = 1 if sha1_count > 0 else 0
    has_md5 = 1 if md5_count > 0 else 0
    has_legacy_rsa = 1 if rsa_count > 0 else 0
    legacy_crypto_count = sha1_count + md5_count + rsa_count + other_crypto_count
    has_legacy_crypto = 1 if legacy_crypto_count > 0 else 0

    return {
        "has_sha1": has_sha1,
        "sha1_count": sha1_count,
        "has_md5": has_md5,
        "md5_count": md5_count,
        "has_legacy_rsa": has_legacy_rsa,
        "rsa_count": rsa_count,
        "has_legacy_crypto": has_legacy_crypto,
        "legacy_crypto_count": legacy_crypto_count,
        "crypto_algorithms_detected": sorted(crypto_algorithms_detected),
        "crypto_evidence": crypto_evidence,
    }
