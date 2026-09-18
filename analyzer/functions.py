"""
functions.py - Function definition extraction and function-level metrics.
"""

from typing import Dict, Any, List, Optional
import re
from analyzer.complexity import compute_function_complexity


def _extract_function_name_node(declarator_node: Any, code_bytes: bytes) -> str:
    """Recursively unpack declarator node to find the function identifier."""
    if declarator_node is None:
        return "anonymous"
    if declarator_node.type == "identifier":
        return code_bytes[declarator_node.start_byte:declarator_node.end_byte].decode("utf-8", errors="replace")
    if declarator_node.type == "function_declarator":
        for child in declarator_node.children:
            if child.type in ("identifier", "field_identifier", "destructor_name", "operator_name", "qualified_identifier"):
                return code_bytes[child.start_byte:child.end_byte].decode("utf-8", errors="replace")
            if child.type in ("pointer_declarator", "parenthesized_declarator"):
                return _extract_function_name_node(child, code_bytes)
    for child in declarator_node.children:
        if child.type == "identifier":
            return code_bytes[child.start_byte:child.end_byte].decode("utf-8", errors="replace")
        if "declarator" in child.type:
            res = _extract_function_name_node(child, code_bytes)
            if res != "anonymous":
                return res
    return "anonymous"


def _count_parameters_node(declarator_node: Any) -> int:
    """Count parameter_declaration nodes within parameter_list."""
    param_list = None
    if declarator_node is None:
        return 0
    if declarator_node.type == "function_declarator":
        for child in declarator_node.children:
            if child.type == "parameter_list":
                param_list = child
                break
    else:
        # Search recursively for parameter_list
        def find_param_list(n):
            nonlocal param_list
            if n.type == "parameter_list":
                param_list = n
                return
            for c in n.children:
                find_param_list(c)
        find_param_list(declarator_node)

    if param_list is None:
        return 0

    count = 0
    for child in param_list.children:
        if child.type in ("parameter_declaration", "optional_parameter_declaration"):
            # Exclude void (e.g. int foo(void))
            child_text = child.text.decode("utf-8", errors="replace").strip() if hasattr(child, "text") else ""
            if child_text == "void":
                continue
            count += 1
    return count


def analyze_functions_ast(tree: Any, code: str) -> List[Dict[str, Any]]:
    """Extract all function definitions from Tree-sitter AST."""
    code_bytes = code.encode("utf-8", errors="replace")
    functions: List[Dict[str, Any]] = []

    def visit(node):
        if node.type == "function_definition":
            # Extract declarator
            declarator = None
            body = None
            for child in node.children:
                if "declarator" in child.type:
                    declarator = child
                elif child.type == "compound_statement":
                    body = child

            fn_name = _extract_function_name_node(declarator, code_bytes)
            param_count = _count_parameters_node(declarator)
            start_line = node.start_point[0] + 1
            end_line = node.end_point[0] + 1
            loc = end_line - start_line + 1
            complexity = compute_function_complexity("", node)

            functions.append({
                "function_name": fn_name,
                "line_start": start_line,
                "line_end": end_line,
                "function_loc": loc,
                "parameter_count": param_count,
                "cyclomatic_complexity": complexity,
                "node": node
            })

        for child in node.children:
            visit(child)

    visit(tree.root_node)
    return functions


def analyze_functions_regex(code: str) -> List[Dict[str, Any]]:
    """Fallback regex function definition scanner."""
    functions: List[Dict[str, Any]] = []
    lines = code.splitlines()

    # Pattern for return_type fn_name(params) {
    pattern = re.compile(
        r'^[ \t]*(?:[a-zA-Z_][a-zA-Z0-9_* \t&]*?[ \t*&]+)'
        r'([a-zA-Z_][a-zA-Z0-9_]*)'
        r'[ \t]*\(([^)]*)\)[ \t]*(?:const)?[ \t]*\{',
        re.MULTILINE
    )

    for match in pattern.finditer(code):
        fn_name = match.group(1)
        if fn_name in ("if", "while", "for", "switch", "catch"):
            continue

        raw_params = match.group(2).strip()
        if not raw_params or raw_params == "void":
            param_count = 0
        else:
            param_count = len([p for p in raw_params.split(",") if p.strip()])

        start_idx = match.start()
        start_line = code[:start_idx].count("\n") + 1

        # Match curly braces to find function end
        open_braces = 0
        end_line = start_line
        found_start = False
        fn_lines = []

        for i in range(start_line - 1, len(lines)):
            line = lines[i]
            fn_lines.append(line)
            open_braces += line.count("{") - line.count("}")
            if "{" in line:
                found_start = True
            if found_start and open_braces <= 0:
                end_line = i + 1
                break

        fn_loc = end_line - start_line + 1
        fn_code = "\n".join(fn_lines)
        complexity = compute_function_complexity(fn_code)

        functions.append({
            "function_name": fn_name,
            "line_start": start_line,
            "line_end": end_line,
            "function_loc": fn_loc,
            "parameter_count": param_count,
            "cyclomatic_complexity": complexity,
            "node": None
        })

    return functions


def compute_function_metrics(functions: List[Dict[str, Any]]) -> Dict[str, Any]:
    """Aggregate file-level function metrics."""
    fn_count = len(functions)
    if fn_count == 0:
        return {
            "function_count": 0,
            "avg_function_loc": 0.0,
            "max_function_loc": 0,
            "min_function_loc": 0,
            "avg_parameter_count": 0.0,
            "max_parameter_count": 0,
            "function_complexities": [],
            "max_function_complexity": 0,
            "avg_function_complexity": 0.0,
        }

    locs = [f["function_loc"] for f in functions]
    params = [f["parameter_count"] for f in functions]
    complexities = [f["cyclomatic_complexity"] for f in functions]

    return {
        "function_count": fn_count,
        "avg_function_loc": round(sum(locs) / fn_count, 2),
        "max_function_loc": max(locs),
        "min_function_loc": min(locs),
        "avg_parameter_count": round(sum(params) / fn_count, 2),
        "max_parameter_count": max(params),
        "function_complexities": complexities,
        "max_function_complexity": max(complexities),
        "avg_function_complexity": round(sum(complexities) / fn_count, 2),
    }
