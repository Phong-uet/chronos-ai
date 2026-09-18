import pytest
from analyzer.structs import analyze_structs


def test_struct_alignment_and_padding():
    code = """
    struct Packet {
        char type;
        double timestamp;
        int length;
    };
    """
    res = analyze_structs(code, arch=64)

    assert res["struct_count"] >= 1
    assert res["struct_total_fields"] == 3
    assert res["estimated_padding_bytes"] > 0
    assert res["estimated_struct_size"] >= 24
    assert res["struct_analysis"] == "estimated"
