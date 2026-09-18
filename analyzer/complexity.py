"""
complexity.py - Cyclomatic complexity and branching analysis (Tree-sitter & Regex fallback).
"""

from typing import Dict, Any, List, Optional
import re


BRANCH_KEYWORDS = {
    "if": "if_count",
    "switch": "switch_count",
    "case": "case_count",
    "goto": "goto_count",
}


def _strip_comments_and_strings(code: str) -> str:
    """Remove comments and string literals to prevent false positives in regex."""
    # Remove block comments
    c = re.sub(r"/\*.*?\*/", " ", code, flags=re.DOTALL)
    # Remove line comments
    c = re.sub(r"//.*", " ", c)
    # Remove string literals
    c = re.sub(r'"(\\.|[^"\\])*"', '""', c)
    # Remove char literals
    c = re.sub(r"'(\\.|[^'\\])*'", "''", c)
    return c


def analyze_complexity_ast(tree: Any, code_bytes: bytes) -> Dict[str, Any]:
    """Calculate complexity metrics using Tree-sitter AST."""
    if_count = 0
    loop_count = 0
    switch_count = 0
    case_count = 0
    goto_count = 0
    catch_count = 0
    logical_op_count = 0
    ternary_count = 0

    def visit(node):
        nonlocal if_count, loop_count, switch_count, case_count
        nonlocal goto_count, catch_count, logical_op_count, ternary_count

        ntype = node.type

        if ntype == "if_statement":
            if_count += 1
        elif ntype in ("for_statement", "while_statement", "do_statement", "for_range_loop"):
            loop_count += 1
        elif ntype == "switch_statement":
            switch_count += 1
        elif ntype in ("case_statement", "switch_case"):
            case_count += 1
        elif ntype == "goto_statement":
            goto_count += 1
        elif ntype in ("catch_clause", "try_statement"):
            if ntype == "catch_clause":
                catch_count += 1
        elif ntype == "conditional_expression":  # Ternary ? :
            ternary_count += 1
        elif ntype == "binary_expression":
            # Check for && and ||
            for child in node.children:
                if child.type in ("&&", "||"):
                    logical_op_count += 1

        for child in node.children:
            visit(child)

    visit(tree.root_node)

    branch_count = if_count + case_count + ternary_count + goto_count
    # Standard McCabe complexity: base 1 + decision points
    cyclomatic = 1 + if_count + loop_count + case_count + ternary_count + logical_op_count + catch_count + goto_count

    return {
        "cyclomatic_complexity": cyclomatic,
        "branch_count": branch_count,
        "loop_count": loop_count,
        "if_count": if_count,
        "switch_count": switch_count,
        "case_count": case_count,
        "goto_count": goto_count,
        "catch_count": catch_count,
        "logical_op_count": logical_op_count,
        "ternary_count": ternary_count,
    }


def analyze_complexity_regex(code: str) -> Dict[str, Any]:
    """Fallback regex complexity analysis."""
    cleaned = _strip_comments_and_strings(code)

    if_matches = len(re.findall(r"\bif\b", cleaned))
    for_matches = len(re.findall(r"\bfor\b", cleaned))
    while_matches = len(re.findall(r"\bwhile\b", cleaned))
    do_matches = len(re.findall(r"\bdo\b\s*\{", cleaned))
    switch_matches = len(re.findall(r"\bswitch\b", cleaned))
    case_matches = len(re.findall(r"\bcase\b", cleaned))
    goto_matches = len(re.findall(r"\bgoto\b", cleaned))
    catch_matches = len(re.findall(r"\bcatch\b", cleaned))
    and_matches = len(re.findall(r"&&", cleaned))
    or_matches = len(re.findall(r"\|\|", cleaned))
    ternary_matches = len(re.findall(r"\?", cleaned))

    loop_count = for_matches + while_matches + do_matches
    logical_ops = and_matches + or_matches
    branch_count = if_matches + case_matches + ternary_matches + goto_matches

    cyclomatic = 1 + if_matches + loop_count + case_matches + ternary_matches + logical_ops + catch_matches + goto_matches

    return {
        "cyclomatic_complexity": cyclomatic,
        "branch_count": branch_count,
        "loop_count": loop_count,
        "if_count": if_matches,
        "switch_count": switch_matches,
        "case_count": case_matches,
        "goto_count": goto_matches,
        "catch_count": catch_matches,
        "logical_op_count": logical_ops,
        "ternary_count": ternary_matches,
    }


def compute_function_complexity(fn_code: str, fn_tree_node: Optional[Any] = None) -> int:
    """Compute cyclomatic complexity for an isolated function block."""
    if fn_tree_node is not None:
        count = 1
        def visit(n):
            nonlocal count
            if n.type in ("if_statement", "for_statement", "while_statement", "do_statement",
                          "case_statement", "switch_case", "conditional_expression",
                          "catch_clause", "goto_statement"):
                count += 1
            elif n.type == "binary_expression":
                for child in n.children:
                    if child.type in ("&&", "||"):
                        count += 1
            for c in n.children:
                visit(c)
        visit(fn_tree_node)
        return count
    else:
        res = analyze_complexity_regex(fn_code)
        return res["cyclomatic_complexity"]
