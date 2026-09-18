import pytest
from analyzer.parser import parse_code
from analyzer.memory import analyze_memory_ast, analyze_memory_regex


def test_memory_pointers_and_alloc():
    code = """
    #include <stdlib.h>

    int calculate(double value) {
        float x = value;

        int *ptr = malloc(sizeof(int));
        *ptr = 10;

        if (x > 5) {
            return *ptr;
        }

        free(ptr);
        return 0;
    }
    """
    tree, _, _ = parse_code(code)
    if tree:
        res = analyze_memory_ast(tree, code)
    else:
        res = analyze_memory_regex(code)

    assert res["malloc_count"] >= 1
    assert res["free_count"] >= 1
    assert res["raw_pointer_count"] >= 1
    assert res["dynamic_allocation_count"] >= 1
