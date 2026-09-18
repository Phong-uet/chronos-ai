"""
casts.py - Implicit cast and precision loss detection.
"""

from typing import Dict, Any, List, Optional
import re


def analyze_casts(code: str, tree: Optional[Any] = None) -> Dict[str, Any]:
    """
    Detect implicit and explicit casts with precision loss risk:
    - double -> float
    - long / long long -> int
    - size_t / unsigned long -> int
    """
    lines = code.splitlines()

    double_to_float_count = 0
    long_to_int_count = 0
    long_long_to_int_count = 0
    size_t_to_int_count = 0
    explicit_precision_cast_count = 0
    precision_loss_events: List[Dict[str, Any]] = []

    # 1. Detect explicit casts: (float)double_var, (int)long_var, etc.
    explicit_pattern = re.compile(
        r'\(\s*(float|int|short|char)\s*\)\s*([a-zA-Z_][a-zA-Z0-9_]*)'
    )
    for m in explicit_pattern.finditer(code):
        target_type = m.group(1)
        var_name = m.group(2)
        line_no = code[:m.start()].count("\n") + 1
        explicit_precision_cast_count += 1
        precision_loss_events.append({
            "line": line_no,
            "type": "explicit_cast",
            "target": target_type,
            "code": lines[line_no - 1].strip(),
            "reason": f"Explicit cast to '{target_type}' may truncate precision"
        })

    # 2. Track variable types declared in code to detect assignments:
    # e.g.: double d; float f = d;
    var_types: Dict[str, str] = {}
    decl_pattern = re.compile(
        r'\b(double|float|long\s+long|long|size_t|unsigned\s+long|int)\s+([a-zA-Z_][a-zA-Z0-9_]*)\b'
    )
    for m in decl_pattern.finditer(code):
        var_type = " ".join(m.group(1).split())
        var_name = m.group(2)
        var_types[var_name] = var_type

    # 3. Detect assignments like: float_var = double_var; or int_var = long_var;
    assign_pattern = re.compile(
        r'\b([a-zA-Z_][a-zA-Z0-9_]*)\s*=\s*([a-zA-Z_][a-zA-Z0-9_]*)\s*;'
    )
    for m in assign_pattern.finditer(code):
        lhs = m.group(1)
        rhs = m.group(2)
        lhs_type = var_types.get(lhs)
        rhs_type = var_types.get(rhs)

        if lhs_type and rhs_type:
            line_no = code[:m.start()].count("\n") + 1
            if lhs_type == "float" and rhs_type == "double":
                double_to_float_count += 1
                precision_loss_events.append({
                    "line": line_no,
                    "type": "implicit_double_to_float",
                    "code": lines[line_no - 1].strip(),
                    "reason": f"Implicit assignment from double '{rhs}' to float '{lhs}'"
                })
            elif lhs_type == "int" and rhs_type == "long":
                long_to_int_count += 1
                precision_loss_events.append({
                    "line": line_no,
                    "type": "implicit_long_to_int",
                    "code": lines[line_no - 1].strip(),
                    "reason": f"Implicit assignment from long '{rhs}' to int '{lhs}'"
                })
            elif lhs_type == "int" and rhs_type == "long long":
                long_long_to_int_count += 1
                precision_loss_events.append({
                    "line": line_no,
                    "type": "implicit_long_long_to_int",
                    "code": lines[line_no - 1].strip(),
                    "reason": f"Implicit assignment from long long '{rhs}' to int '{lhs}'"
                })
            elif lhs_type == "int" and rhs_type in ("size_t", "unsigned long"):
                size_t_to_int_count += 1
                precision_loss_events.append({
                    "line": line_no,
                    "type": "implicit_size_t_to_int",
                    "code": lines[line_no - 1].strip(),
                    "reason": f"Implicit assignment from {rhs_type} '{rhs}' to int '{lhs}'"
                })

    # 4. Also scan initializations: float f = double_var; int i = size_t_var;
    init_pattern = re.compile(
        r'\b(float|int)\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*=\s*([a-zA-Z_][a-zA-Z0-9_]*)\s*;'
    )
    for m in init_pattern.finditer(code):
        lhs_type = m.group(1)
        lhs = m.group(2)
        rhs = m.group(3)
        rhs_type = var_types.get(rhs)
        if rhs_type:
            line_no = code[:m.start()].count("\n") + 1
            if lhs_type == "float" and rhs_type == "double":
                double_to_float_count += 1
                precision_loss_events.append({
                    "line": line_no,
                    "type": "implicit_double_to_float",
                    "code": lines[line_no - 1].strip(),
                    "reason": f"Initialization of float '{lhs}' from double '{rhs}'"
                })
            elif lhs_type == "int" and rhs_type in ("long", "long long", "size_t", "unsigned long"):
                if rhs_type == "long":
                    long_to_int_count += 1
                elif rhs_type == "long long":
                    long_long_to_int_count += 1
                else:
                    size_t_to_int_count += 1
                precision_loss_events.append({
                    "line": line_no,
                    "type": f"implicit_{rhs_type}_to_int",
                    "code": lines[line_no - 1].strip(),
                    "reason": f"Initialization of int '{lhs}' from {rhs_type} '{rhs}'"
                })

    precision_loss_count = double_to_float_count + long_to_int_count + long_long_to_int_count + size_t_to_int_count

    return {
        "double_to_float_count": double_to_float_count,
        "long_to_int_count": long_to_int_count,
        "long_long_to_int_count": long_long_to_int_count,
        "size_t_to_int_count": size_t_to_int_count,
        "precision_loss_count": precision_loss_count,
        "explicit_precision_cast_count": explicit_precision_cast_count,
        "precision_loss_events": precision_loss_events,
    }
