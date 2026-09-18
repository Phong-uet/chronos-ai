"""
dsa.py - Data structures and algorithmic pattern detection.
"""

from typing import Dict, Any, Optional
import re
from analyzer.complexity import _strip_comments_and_strings


def analyze_dsa_patterns(code: str, tree: Optional[Any] = None) -> Dict[str, Any]:
    """
    Detect DSA patterns:
    - Static arrays (e.g. int arr[100])
    - Linked list self-referential pointer patterns
    - Matrix (arr[i][j]) and Tensor (arr[i][j][k]) indexing
    - Bitwise operations (&, |, ^, <<, >>, ~)
    """
    cleaned = _strip_comments_and_strings(code)

    # 1. Static Array declarations: type name[size];
    static_array_pattern = re.compile(
        r'\b(?:int|char|float|double|short|long|unsigned|uint\d+_t|int\d+_t|size_t|[a-zA-Z_][a-zA-Z0-9_]*_t)\s+[a-zA-Z_][a-zA-Z0-9_]*\s*\[\s*[0-9A-Z_]+\s*\]'
    )
    static_array_count = len(static_array_pattern.findall(cleaned))

    # 2. Linked list pattern: struct Node *next; or Node *next;
    linked_list_pattern = re.compile(
        r'(?:struct\s+)?([a-zA-Z_][a-zA-Z0-9_]*)\s*\*\s*(next|prev|head|tail|node|link)\b',
        re.IGNORECASE
    )
    linked_list_matches = linked_list_pattern.findall(cleaned)
    linked_list_pattern_count = len(linked_list_matches)
    has_linked_list = 1 if linked_list_pattern_count > 0 else 0

    # 3. Matrix & Tensor accesses: [..][..] and [..][..][..]
    # Matrix: e.g. a[i][j]
    matrix_pattern = re.compile(r'\[\s*[^\]]+\s*\]\[\s*[^\]]+\s*\]')
    # Tensor: e.g. a[i][j][k]
    tensor_pattern = re.compile(r'\[\s*[^\]]+\s*\]\[\s*[^\]]+\s*\]\[\s*[^\]]+\s*\]')

    tensor_matches = tensor_pattern.findall(cleaned)
    matrix_matches = matrix_pattern.findall(cleaned)

    tensor_count = len(tensor_matches)
    matrix_count = len(matrix_matches) - tensor_count  # Exclude tensor matches from 2D count
    if matrix_count < 0:
        matrix_count = len(matrix_matches)

    # 4. Bitwise operators: &, |, ^, <<, >>, ~
    # Be careful not to count && or ||, or pointer &
    shift_matches = len(re.findall(r'<<|>>', cleaned))
    xor_matches = len(re.findall(r'\^', cleaned))
    not_matches = len(re.findall(r'~', cleaned))

    # Single | (not ||)
    single_or = len(re.findall(r'(?<!\|)\|(?!\|)', cleaned))

    # Single & (not && and preferably binary e.g. "a & b" or "val &= mask")
    single_and = len(re.findall(r'(?<!&)&(?!&)', cleaned))
    # Filter heuristic for address-of (e.g. &var at start of expression or argument)
    bitwise_and = len(re.findall(r'(?:[a-zA-Z0-9_)]\s*&\s*[a-zA-Z0-9_(]|&=)', cleaned))

    bitwise_operation_count = shift_matches + xor_matches + not_matches + single_or + bitwise_and

    return {
        "static_array_count": static_array_count,
        "linked_list_pattern_count": linked_list_pattern_count,
        "has_linked_list": has_linked_list,
        "matrix_pattern_count": matrix_count,
        "tensor_pattern_count": tensor_count,
        "bitwise_operation_count": bitwise_operation_count,
    }
