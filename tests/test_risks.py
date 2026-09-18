import pytest
from analyzer.risks import evaluate_file_risks


def test_risk_evaluation():
    file_record = {
        "features": {
            "precision_loss_count": 2,
            "explicit_precision_cast_count": 1,
            "dynamic_allocation_count": 3,
            "total_frees": 0,
            "allocation_free_ratio": 3.0,
            "has_sha1": 1,
            "has_legacy_rsa": 1,
            "has_md5": 0,
            "estimated_padding_bytes": 12,
            "struct_count": 1,
            "max_struct_padding": 8
        },
        "evidence": {
            "precision_loss_events": [{"line": 10, "code": "float x = d;"}],
            "alloc_events": [{"line": 15, "code": "malloc(10);"}],
            "crypto_evidence": [{"line": 20, "symbol": "SHA1_Init", "algorithm": "SHA1"}],
            "struct_details": [{"name": "Header", "estimated_padding": 12, "fields": []}]
        }
    }

    risks = evaluate_file_risks(file_record)
    risk_names = [r["risk"] for r in risks]

    assert "RISK_FLOAT_PRECISION" in risk_names
    assert "RISK_MEMORY_LEAK" in risk_names
    assert "RISK_QUANTUM_VULNERABLE" in risk_names
    assert "RISK_STRUCT_OFFSET" in risk_names

    # Check recommendations & evidence presence
    for r in risks:
        assert len(r["evidence"]) > 0
        assert "recommendation" in r
