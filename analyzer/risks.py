"""
risks.py - Risk engine detecting precision loss, potential leaks, quantum vulnerability, and struct offset issues.
"""

from typing import Dict, Any, List


def evaluate_file_risks(file_record: Dict[str, Any]) -> List[Dict[str, Any]]:
    """
    Evaluate technical risks for a single file with concrete evidence.
    Returns list of risk objects:
    {
        "risk": "RISK_NAME",
        "severity": "low" | "medium" | "high",
        "description": "...",
        "recommendation": "...",
        "evidence": [...]
    }
    """
    features = file_record["features"]
    evidence_store = file_record.get("evidence", {})
    risks: List[Dict[str, Any]] = []

    # 1. RISK_FLOAT_PRECISION
    prec_count = features.get("precision_loss_count", 0)
    explicit_cast_count = features.get("explicit_precision_cast_count", 0)
    if prec_count > 0 or explicit_cast_count > 0:
        prec_evidence = evidence_store.get("precision_loss_events", [])
        if not prec_evidence:
            prec_evidence = [
                {"reason": f"Observed {prec_count} implicit precision conversions or casts."}
            ]
        risks.append({
            "risk": "RISK_FLOAT_PRECISION",
            "severity": "medium",
            "description": "Potential precision loss detected in floating-point or integer conversions.",
            "recommendation": "Review implicit type demotions and cast bounds to avoid arithmetic truncation.",
            "evidence": prec_evidence
        })

    # 2. RISK_MEMORY_LEAK (potential memory leak)
    alloc_count = features.get("dynamic_allocation_count", 0)
    free_count = features.get("free_count", 0)
    alloc_ratio = features.get("allocation_free_ratio", 0.0)

    if alloc_count > 0 and (alloc_count > free_count or alloc_ratio > 1.0):
        alloc_events = evidence_store.get("alloc_events", [])
        evidence_list = []
        for ev in alloc_events[:5]:  # show up to 5 examples
            evidence_list.append({
                "line": ev.get("line"),
                "code": ev.get("code"),
                "reason": "Dynamic allocation with possible lack of local free/release in current scope"
            })
        if not evidence_list:
            evidence_list.append({
                "reason": f"Allocations ({alloc_count}) exceed deallocations ({free_count}), ratio: {alloc_ratio}"
            })

        risks.append({
            "risk": "RISK_MEMORY_LEAK",
            "severity": "medium" if alloc_count <= 2 else "high",
            "description": "Potential memory leak: dynamic allocations exceed frees in file analysis.",
            "recommendation": "Ensure all allocated heap buffers have corresponding deallocation routines across all execution branches.",
            "evidence": evidence_list
        })

    # 3. RISK_QUANTUM_VULNERABLE
    has_sha1 = features.get("has_sha1", 0)
    has_rsa = features.get("has_legacy_rsa", 0)
    has_md5 = features.get("has_md5", 0)

    if has_sha1 or has_rsa or has_md5:
        crypto_evidence = evidence_store.get("crypto_evidence", [])
        evidence_list = []
        for ev in crypto_evidence:
            evidence_list.append({
                "line": ev.get("line"),
                "code": ev.get("code"),
                "algorithm": ev.get("algorithm"),
                "reason": f"Legacy cryptographic primitive {ev.get('symbol')} detected at line {ev.get('line')}"
            })

        risks.append({
            "risk": "RISK_QUANTUM_VULNERABLE",
            "severity": "high",
            "description": "Legacy cryptographic primitive detected (SHA-1/MD5/RSA) vulnerable to collision or quantum attacks.",
            "recommendation": "Consider migration to modern cryptographic primitives (e.g. SHA-256, SHA-3) and post-quantum cryptography (PQC) standards where appropriate.",
            "evidence": evidence_list
        })

    # 4. RISK_STRUCT_OFFSET
    padding_bytes = features.get("estimated_padding_bytes", 0)
    struct_count = features.get("struct_count", 0)

    if padding_bytes > 0 or (struct_count > 0 and features.get("max_struct_padding", 0) > 0):
        struct_details = evidence_store.get("struct_details", [])
        evidence_list = []
        for s in struct_details:
            if s.get("estimated_padding", 0) > 0:
                field_names = [f["name"] for f in s.get("fields", [])]
                evidence_list.append({
                    "struct_name": s.get("name"),
                    "line": s.get("line"),
                    "estimated_size": s.get("estimated_size"),
                    "estimated_padding": s.get("estimated_padding"),
                    "field_order": field_names,
                    "reason": f"Struct '{s.get('name')}' contains estimated {s.get('estimated_padding')} bytes of alignment padding."
                })

        risks.append({
            "risk": "RISK_STRUCT_OFFSET",
            "severity": "low" if padding_bytes < 16 else "medium",
            "description": f"Estimated struct alignment padding ({padding_bytes} bytes total) may cause serialization or memory layout discrepancies.",
            "recommendation": "Reorder struct fields from largest alignment to smallest, or verify compiler packing directives (#pragma pack).",
            "evidence": evidence_list
        })

    return risks
