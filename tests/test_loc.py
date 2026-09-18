import pytest
from analyzer.loc import analyze_loc


def test_loc_simple():
    code = """
    // Single line comment
    int x = 10; // Inline comment

    /*
       Multiline
       comment
    */
    int y = 20;
    """
    res = analyze_loc(code)
    assert res["total_lines"] > 0
    assert res["code_lines"] == 2
    assert res["comment_lines"] >= 4
    assert res["blank_lines"] >= 2
    assert res["logical_loc"] >= 2


def test_loc_empty():
    res = analyze_loc("")
    assert res["total_lines"] == 0
    assert res["code_lines"] == 0
    assert res["blank_lines"] == 0
