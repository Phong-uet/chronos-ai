"""
memory.py - Pointer operations, arithmetic, dynamic memory allocation tracking.
"""

from typing import Dict, Any, List, Optional
import re


def analyze_memory_ast(tree: Any, code: str, functions: Optional[List[Dict[str, Any]]] = None) -> Dict[str, Any]:
    """Analyze memory features using Tree-sitter AST."""
    code_bytes = code.encode("utf-8", errors="replace")

    pointer_declaration_count = 0
    pointer_dereference_count = 0
    pointer_arithmetic_count = 0
    pointer_member_access_count = 0
    void_pointer_count = 0

    malloc_count = 0
    calloc_count = 0
    realloc_count = 0
    free_count = 0
    new_count = 0
    delete_count = 0

    alloc_events: List[Dict[str, Any]] = []
    free_events: List[Dict[str, Any]] = []

    def get_node_text(node):
        return code_bytes[node.start_byte:node.end_byte].decode("utf-8", errors="replace")

    def visit(node):
        nonlocal pointer_declaration_count, pointer_dereference_count
        nonlocal pointer_arithmetic_count, pointer_member_access_count, void_pointer_count
        nonlocal malloc_count, calloc_count, realloc_count, free_count, new_count, delete_count

        ntype = node.type

        # Pointer declarations: pointer_declarator
        if ntype == "pointer_declarator":
            pointer_declaration_count += 1
            # Check if type is void
            parent = node.parent
            while parent and parent.type not in ("declaration", "parameter_declaration", "field_declaration"):
                parent = parent.parent
            if parent:
                parent_text = get_node_text(parent)
                if re.search(r"\bvoid\s*\*", parent_text):
                    void_pointer_count += 1

        # Pointer dereference: pointer_expression (*ptr)
        elif ntype == "pointer_expression":
            pointer_dereference_count += 1

        # Pointer member access: field_expression with ->
        elif ntype == "field_expression":
            for child in node.children:
                if child.type == "->":
                    pointer_member_access_count += 1
                    break

        # Pointer arithmetic: ptr++, ++ptr, ptr--, --ptr, ptr + offset
        elif ntype == "update_expression":
            # ++ or --
            pointer_arithmetic_count += 1
        elif ntype == "binary_expression":
            # Check for ptr + 1 or ptr - 1
            op = None
            for child in node.children:
                if child.type in ("+", "-"):
                    op = child.type
                    break
            if op:
                text = get_node_text(node)
                # heuristic: identifier + number or identifier - number
                if re.search(r"\b(ptr|buf|buffer|p|pVal|data|pData|cur|head|tail|idx|offset)\s*[+-]\s*\d+", text, re.IGNORECASE):
                    pointer_arithmetic_count += 1

        # Function calls: malloc, calloc, realloc, free
        elif ntype == "call_expression":
            fn_node = node.child_by_field_name("function")
            if fn_node:
                fn_name = get_node_text(fn_node).strip()
                line_no = node.start_point[0] + 1
                snippet = get_node_text(node)
                if fn_name == "malloc":
                    malloc_count += 1
                    alloc_events.append({"type": "malloc", "line": line_no, "code": snippet})
                elif fn_name == "calloc":
                    calloc_count += 1
                    alloc_events.append({"type": "calloc", "line": line_no, "code": snippet})
                elif fn_name == "realloc":
                    realloc_count += 1
                    alloc_events.append({"type": "realloc", "line": line_no, "code": snippet})
                elif fn_name == "free":
                    free_count += 1
                    free_events.append({"type": "free", "line": line_no, "code": snippet})

        # C++ new / delete
        elif ntype == "new_expression":
            new_count += 1
            alloc_events.append({"type": "new", "line": node.start_point[0] + 1, "code": get_node_text(node)})
        elif ntype == "delete_expression":
            delete_count += 1
            free_events.append({"type": "delete", "line": node.start_point[0] + 1, "code": get_node_text(node)})

        for child in node.children:
            visit(child)

    visit(tree.root_node)

    raw_pointer_count = pointer_declaration_count + pointer_dereference_count + pointer_member_access_count
    dynamic_allocation_count = malloc_count + calloc_count + realloc_count + new_count
    total_frees = free_count + delete_count
    allocation_free_ratio = round(dynamic_allocation_count / max(total_frees, 1), 2)

    return {
        "pointer_declaration_count": pointer_declaration_count,
        "pointer_dereference_count": pointer_dereference_count,
        "pointer_arithmetic_count": pointer_arithmetic_count,
        "pointer_member_access_count": pointer_member_access_count,
        "raw_pointer_count": raw_pointer_count,
        "void_pointer_count": void_pointer_count,
        "malloc_count": malloc_count,
        "calloc_count": calloc_count,
        "realloc_count": realloc_count,
        "free_count": free_count,
        "new_count": new_count,
        "delete_count": delete_count,
        "dynamic_allocation_count": dynamic_allocation_count,
        "total_frees": total_frees,
        "allocation_free_ratio": allocation_free_ratio,
        "alloc_events": alloc_events,
        "free_events": free_events,
    }


def analyze_memory_regex(code: str) -> Dict[str, Any]:
    """Fallback regex memory analysis."""
    lines = code.splitlines()

    # Strip comments and strings
    from analyzer.complexity import _strip_comments_and_strings
    cleaned = _strip_comments_and_strings(code)

    # Pointer declaration: type *var; or type* var;
    ptr_decl_pattern = re.compile(
        r'\b(?:int|char|void|float|double|short|long|unsigned|struct\s+[a-zA-Z0-9_]+|[a-zA-Z0-9_]+_t)\s*\*\s*([a-zA-Z_][a-zA-Z0-9_]*)'
    )
    pointer_declaration_count = len(ptr_decl_pattern.findall(cleaned))

    # Void pointer
    void_pointer_count = len(re.findall(r'\bvoid\s*\*\s*[a-zA-Z_]', cleaned))

    # Pointer dereference: *ptr (excluding * in multiplications or declarations)
    ptr_deref_pattern = re.compile(r'(?:[=(,;+\-!]\s*|\breturn\s+|\bif\s*\()\s*\*\s*([a-zA-Z_][a-zA-Z0-9_]*)')
    pointer_dereference_count = len(ptr_deref_pattern.findall(cleaned))

    # Pointer member access: ->
    pointer_member_access_count = len(re.findall(r'->', cleaned))

    # Pointer arithmetic: ptr++, ++ptr, ptr--, --ptr, ptr +=, ptr -=
    pointer_arithmetic_count = len(re.findall(r'(?:\+\+\s*[a-zA-Z_][a-zA-Z0-9_]*|[a-zA-Z_][a-zA-Z0-9_]*\s*\+\+|--\s*[a-zA-Z_][a-zA-Z0-9_]*|[a-zA-Z_][a-zA-Z0-9_]*\s*--|[a-zA-Z_][a-zA-Z0-9_]*\s*[+-]=\s*\d+)', cleaned))

    # Dynamic allocations
    alloc_events = []
    free_events = []

    malloc_matches = list(re.finditer(r'\bmalloc\s*\(', code))
    calloc_matches = list(re.finditer(r'\bcalloc\s*\(', code))
    realloc_matches = list(re.finditer(r'\brealloc\s*\(', code))
    free_matches = list(re.finditer(r'\bfree\s*\(', code))
    new_matches = list(re.finditer(r'\bnew\s+(?:\[[^\]]*\]\s*)?[a-zA-Z_]', code))
    delete_matches = list(re.finditer(r'\bdelete\s*(?:\[\])?\s*[a-zA-Z_]', code))

    for m in malloc_matches:
        line = code[:m.start()].count("\n") + 1
        alloc_events.append({"type": "malloc", "line": line, "code": lines[line-1].strip()})
    for m in calloc_matches:
        line = code[:m.start()].count("\n") + 1
        alloc_events.append({"type": "calloc", "line": line, "code": lines[line-1].strip()})
    for m in realloc_matches:
        line = code[:m.start()].count("\n") + 1
        alloc_events.append({"type": "realloc", "line": line, "code": lines[line-1].strip()})
    for m in free_matches:
        line = code[:m.start()].count("\n") + 1
        free_events.append({"type": "free", "line": line, "code": lines[line-1].strip()})
    for m in new_matches:
        line = code[:m.start()].count("\n") + 1
        alloc_events.append({"type": "new", "line": line, "code": lines[line-1].strip()})
    for m in delete_matches:
        line = code[:m.start()].count("\n") + 1
        free_events.append({"type": "delete", "line": line, "code": lines[line-1].strip()})

    malloc_count = len(malloc_matches)
    calloc_count = len(calloc_matches)
    realloc_count = len(realloc_matches)
    free_count = len(free_matches)
    new_count = len(new_matches)
    delete_count = len(delete_matches)

    raw_pointer_count = pointer_declaration_count + pointer_dereference_count + pointer_member_access_count
    dynamic_allocation_count = malloc_count + calloc_count + realloc_count + new_count
    total_frees = free_count + delete_count
    allocation_free_ratio = round(dynamic_allocation_count / max(total_frees, 1), 2)

    return {
        "pointer_declaration_count": pointer_declaration_count,
        "pointer_dereference_count": pointer_dereference_count,
        "pointer_arithmetic_count": pointer_arithmetic_count,
        "pointer_member_access_count": pointer_member_access_count,
        "raw_pointer_count": raw_pointer_count,
        "void_pointer_count": void_pointer_count,
        "malloc_count": malloc_count,
        "calloc_count": calloc_count,
        "realloc_count": realloc_count,
        "free_count": free_count,
        "new_count": new_count,
        "delete_count": delete_count,
        "dynamic_allocation_count": dynamic_allocation_count,
        "total_frees": total_frees,
        "allocation_free_ratio": allocation_free_ratio,
        "alloc_events": alloc_events,
        "free_events": free_events,
    }
