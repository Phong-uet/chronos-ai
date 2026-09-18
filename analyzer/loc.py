"""
loc.py - Lines of Code (LOC) and Logical LOC analysis.
"""

from typing import Dict, Any, Optional
import re


def analyze_loc(code: str, tree: Optional[Any] = None) -> Dict[str, int]:
    """
    Calculate LOC metrics:
    - total_lines
    - blank_lines
    - comment_lines
    - code_lines
    - logical_loc
    """
    lines = code.splitlines()
    total_lines = len(lines)
    if total_lines == 0 and len(code) > 0:
        total_lines = 1

    blank_lines = 0
    comment_lines = 0
    code_lines = 0

    in_multiline_comment = False

    for line in lines:
        stripped = line.strip()
        if not stripped:
            if in_multiline_comment:
                comment_lines += 1
            else:
                blank_lines += 1
            continue

        # Check multi-line comment state
        has_code = False
        has_comment = False

        idx = 0
        n = len(stripped)

        while idx < n:
            if in_multiline_comment:
                end_pos = stripped.find("*/", idx)
                if end_pos != -1:
                    in_multiline_comment = False
                    idx = end_pos + 2
                    has_comment = True
                else:
                    # Rest of line is inside comment
                    has_comment = True
                    idx = n
            else:
                # Check for single-line comment start
                if idx + 1 < n and stripped[idx:idx+2] == "//":
                    has_comment = True
                    idx = n
                elif idx + 1 < n and stripped[idx:idx+2] == "/*":
                    in_multiline_comment = True
                    has_comment = True
                    idx += 2
                elif not stripped[idx].isspace():
                    has_code = True
                    idx += 1
                else:
                    idx += 1

        if has_code:
            code_lines += 1
        elif has_comment:
            comment_lines += 1
        else:
            blank_lines += 1

    # Logical LOC calculation
    logical_loc = 0
    if tree is not None:
        # Traverse tree nodes to count statements
        statement_types = {
            "expression_statement",
            "declaration",
            "return_statement",
            "if_statement",
            "for_statement",
            "while_statement",
            "do_statement",
            "switch_statement",
            "case_statement",
            "break_statement",
            "continue_statement",
            "goto_statement",
            "compound_statement",
        }

        def count_statements(node):
            nonlocal logical_loc
            if node.type in statement_types and node.type != "compound_statement":
                logical_loc += 1
            for child in node.children:
                count_statements(child)

        try:
            count_statements(tree.root_node)
        except Exception:
            logical_loc = 0

    if logical_loc == 0:
        # Regex / text fallback for logical LOC
        # Strip comments and strings first
        cleaned = re.sub(r"/\*.*?\*/", " ", code, flags=re.DOTALL)
        cleaned = re.sub(r"//.*", " ", cleaned)
        cleaned = re.sub(r'"(\\.|[^"\\])*"', '""', cleaned)
        # Semicolons + preprocessor + control headers
        semicolons = len(re.findall(r";", cleaned))
        preproc = len(re.findall(r"^\s*#\s*\w+", cleaned, flags=re.MULTILINE))
        control = len(re.findall(r"\b(if|for|while|switch|case|default|catch)\b", cleaned))
        logical_loc = semicolons + preproc + control

    return {
        "total_lines": total_lines,
        "blank_lines": blank_lines,
        "comment_lines": comment_lines,
        "code_lines": code_lines,
        "logical_loc": max(logical_loc, 1 if code_lines > 0 else 0)
    }
