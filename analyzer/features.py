"""
features.py - Feature extraction orchestration and vectorization.
"""

from typing import Dict, Any, List, Tuple
from pathlib import Path
import numpy as np

from analyzer.scanner import read_file_content
from analyzer.parser import parse_code
from analyzer.loc import analyze_loc
from analyzer.complexity import analyze_complexity_ast, analyze_complexity_regex
from analyzer.functions import analyze_functions_ast, analyze_functions_regex, compute_function_metrics
from analyzer.memory import analyze_memory_ast, analyze_memory_regex
from analyzer.casts import analyze_casts
from analyzer.structs import analyze_structs
from analyzer.crypto import analyze_crypto
from analyzer.dsa import analyze_dsa_patterns


# Explicitly defined feature names for numeric vectors to ensure fixed column ordering
FEATURE_NAMES: List[str] = [
    # LOC & Scale
    "code_lines",
    "logical_loc",
    "total_lines",
    # Complexity & Control Flow
    "cyclomatic_complexity",
    "branch_count",
    "loop_count",
    "if_count",
    "switch_count",
    "goto_count",
    # Functions
    "function_count",
    "avg_function_loc",
    "max_function_loc",
    "avg_parameter_count",
    "max_function_complexity",
    "avg_function_complexity",
    # Memory & Pointers
    "raw_pointer_count",
    "pointer_declaration_count",
    "pointer_dereference_count",
    "pointer_arithmetic_count",
    "pointer_member_access_count",
    "void_pointer_count",
    # Dynamic Allocations
    "dynamic_allocation_count",
    "malloc_count",
    "calloc_count",
    "realloc_count",
    "free_count",
    "new_count",
    "delete_count",
    "allocation_free_ratio",
    # Casts & Precision
    "precision_loss_count",
    "double_to_float_count",
    "long_to_int_count",
    "explicit_precision_cast_count",
    # Structs
    "struct_count",
    "struct_total_fields",
    "estimated_struct_size",
    "estimated_padding_bytes",
    "max_struct_padding",
    # Legacy Crypto
    "legacy_crypto_count",
    "sha1_count",
    "md5_count",
    "rsa_count",
    # DSA Patterns
    "static_array_count",
    "linked_list_pattern_count",
    "matrix_pattern_count",
    "tensor_pattern_count",
    "bitwise_operation_count",
    # Binary Features (0 or 1)
    "has_sha1",
    "has_md5",
    "has_legacy_rsa",
    "has_legacy_crypto",
    "has_malloc",
    "has_linked_list",
]

BINARY_FEATURE_NAMES: List[str] = [
    "has_sha1",
    "has_md5",
    "has_legacy_rsa",
    "has_legacy_crypto",
    "has_malloc",
    "has_linked_list",
]


def extract_file_features(file_path: Path, arch: int = 64) -> Dict[str, Any]:
    """
    Extract all metrics from a single source file.
    Returns complete dictionary including raw metrics, sub-reports, and evidence.
    """
    code, read_warning = read_file_content(file_path)
    tree, parser_type, parse_warning = parse_code(code, file_path)

    warnings = []
    if read_warning:
        warnings.append(read_warning)
    if parse_warning:
        warnings.append(parse_warning)

    # 1. LOC
    loc_res = analyze_loc(code, tree)

    # 2. Functions
    if tree is not None:
        try:
            functions = analyze_functions_ast(tree, code)
        except Exception:
            functions = analyze_functions_regex(code)
    else:
        functions = analyze_functions_regex(code)
    fn_metrics = compute_function_metrics(functions)

    # 3. Complexity
    if tree is not None:
        try:
            comp_res = analyze_complexity_ast(tree, code.encode("utf-8", errors="replace"))
        except Exception:
            comp_res = analyze_complexity_regex(code)
    else:
        comp_res = analyze_complexity_regex(code)

    # 4. Memory
    if tree is not None:
        try:
            mem_res = analyze_memory_ast(tree, code, functions)
        except Exception:
            mem_res = analyze_memory_regex(code)
    else:
        mem_res = analyze_memory_regex(code)

    # 5. Casts
    casts_res = analyze_casts(code, tree)

    # 6. Structs
    structs_res = analyze_structs(code, arch=arch)

    # 7. Crypto
    crypto_res = analyze_crypto(code)

    # 8. DSA Patterns
    dsa_res = analyze_dsa_patterns(code, tree)

    # Derived flags
    has_malloc = 1 if mem_res["dynamic_allocation_count"] > 0 else 0

    # Build flat raw feature dictionary
    features: Dict[str, Any] = {
        # LOC
        "code_lines": loc_res["code_lines"],
        "logical_loc": loc_res["logical_loc"],
        "total_lines": loc_res["total_lines"],
        "blank_lines": loc_res["blank_lines"],
        "comment_lines": loc_res["comment_lines"],
        # Complexity
        "cyclomatic_complexity": comp_res["cyclomatic_complexity"],
        "branch_count": comp_res["branch_count"],
        "loop_count": comp_res["loop_count"],
        "if_count": comp_res["if_count"],
        "switch_count": comp_res["switch_count"],
        "case_count": comp_res["case_count"],
        "goto_count": comp_res["goto_count"],
        # Functions
        "function_count": fn_metrics["function_count"],
        "avg_function_loc": fn_metrics["avg_function_loc"],
        "max_function_loc": fn_metrics["max_function_loc"],
        "min_function_loc": fn_metrics["min_function_loc"],
        "avg_parameter_count": fn_metrics["avg_parameter_count"],
        "max_parameter_count": fn_metrics["max_parameter_count"],
        "function_complexities": fn_metrics["function_complexities"],
        "max_function_complexity": fn_metrics["max_function_complexity"],
        "avg_function_complexity": fn_metrics["avg_function_complexity"],
        # Memory & Pointers
        "raw_pointer_count": mem_res["raw_pointer_count"],
        "pointer_declaration_count": mem_res["pointer_declaration_count"],
        "pointer_dereference_count": mem_res["pointer_dereference_count"],
        "pointer_arithmetic_count": mem_res["pointer_arithmetic_count"],
        "pointer_member_access_count": mem_res["pointer_member_access_count"],
        "void_pointer_count": mem_res["void_pointer_count"],
        # Dynamic Allocations
        "dynamic_allocation_count": mem_res["dynamic_allocation_count"],
        "malloc_count": mem_res["malloc_count"],
        "calloc_count": mem_res["calloc_count"],
        "realloc_count": mem_res["realloc_count"],
        "free_count": mem_res["free_count"],
        "new_count": mem_res["new_count"],
        "delete_count": mem_res["delete_count"],
        "allocation_free_ratio": mem_res["allocation_free_ratio"],
        # Casts
        "precision_loss_count": casts_res["precision_loss_count"],
        "double_to_float_count": casts_res["double_to_float_count"],
        "long_to_int_count": casts_res["long_to_int_count"],
        "long_long_to_int_count": casts_res["long_long_to_int_count"],
        "size_t_to_int_count": casts_res["size_t_to_int_count"],
        "explicit_precision_cast_count": casts_res["explicit_precision_cast_count"],
        # Structs
        "struct_analysis": structs_res["struct_analysis"],
        "struct_count": structs_res["struct_count"],
        "struct_total_fields": structs_res["struct_total_fields"],
        "estimated_struct_size": structs_res["estimated_struct_size"],
        "estimated_padding_bytes": structs_res["estimated_padding_bytes"],
        "max_struct_padding": structs_res["max_struct_padding"],
        # Crypto
        "has_sha1": crypto_res["has_sha1"],
        "sha1_count": crypto_res["sha1_count"],
        "has_md5": crypto_res["has_md5"],
        "md5_count": crypto_res["md5_count"],
        "has_legacy_rsa": crypto_res["has_legacy_rsa"],
        "rsa_count": crypto_res["rsa_count"],
        "has_legacy_crypto": crypto_res["has_legacy_crypto"],
        "legacy_crypto_count": crypto_res["legacy_crypto_count"],
        "crypto_algorithms_detected": crypto_res["crypto_algorithms_detected"],
        # DSA
        "static_array_count": dsa_res["static_array_count"],
        "linked_list_pattern_count": dsa_res["linked_list_pattern_count"],
        "has_linked_list": dsa_res["has_linked_list"],
        "matrix_pattern_count": dsa_res["matrix_pattern_count"],
        "tensor_pattern_count": dsa_res["tensor_pattern_count"],
        "bitwise_operation_count": dsa_res["bitwise_operation_count"],
        # Binary
        "has_malloc": has_malloc,
    }

    # Construct numeric vector
    vector = [float(features[name]) for name in FEATURE_NAMES]

    return {
        "file_path": str(file_path),
        "file_name": file_path.name,
        "parser_type": parser_type,
        "warnings": warnings,
        "features": features,
        "vector": vector,
        "evidence": {
            "functions": functions,
            "alloc_events": mem_res["alloc_events"],
            "free_events": mem_res["free_events"],
            "precision_loss_events": casts_res["precision_loss_events"],
            "struct_details": structs_res["struct_details"],
            "crypto_evidence": crypto_res["crypto_evidence"],
        }
    }
