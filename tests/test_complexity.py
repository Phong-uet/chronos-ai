import pytest
from analyzer.parser import parse_code
from analyzer.complexity import analyze_complexity_ast, analyze_complexity_regex


def test_complexity_ast_and_regex():
    code = """
    int check(int x, int y) {
        if (x > 0 && y > 0) {
            for (int i = 0; i < 10; i++) {
                if (i == 5) goto done;
            }
        } else if (x < 0) {
            switch (y) {
                case 1: break;
                case 2: break;
                default: break;
            }
        }
    done:
        return x > y ? x : y;
    }
    """
    tree, ptype, _ = parse_code(code)
    if tree:
        res = analyze_complexity_ast(tree, code.encode("utf-8"))
    else:
        res = analyze_complexity_regex(code)

    assert res["if_count"] >= 2
    assert res["loop_count"] >= 1
    assert res["case_count"] >= 2
    assert res["goto_count"] >= 1
    assert res["cyclomatic_complexity"] >= 6
    assert res["branch_count"] >= 4
