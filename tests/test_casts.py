import pytest
from analyzer.casts import analyze_casts


def test_precision_casts():
    code = """
    void calculate() {
        double value = 123.456;
        float result = value;

        long timestamp = 9999999;
        int x = timestamp;

        float explicit_cast = (float)value;
    }
    """
    res = analyze_casts(code)

    assert res["double_to_float_count"] >= 1
    assert res["long_to_int_count"] >= 1
    assert res["explicit_precision_cast_count"] >= 1
    assert res["precision_loss_count"] >= 2
