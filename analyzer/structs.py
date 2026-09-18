"""
structs.py - Struct alignment, packing, and padding estimation.
"""

from typing import Dict, Any, List, Optional
import re


# Base primitive type sizes and alignments
def get_type_specs(arch: int = 64) -> Dict[str, tuple[int, int]]:
    """
    Returns mapping from type_name to (size_bytes, alignment_bytes).
    Default 64-bit (LP64/standard C ABI model).
    """
    ptr_size = 8 if arch == 64 else 4
    long_size = 8 if arch == 64 else 4

    return {
        "char": (1, 1),
        "signed char": (1, 1),
        "unsigned char": (1, 1),
        "uint8_t": (1, 1),
        "int8_t": (1, 1),
        "bool": (1, 1),
        "_Bool": (1, 1),
        "short": (2, 2),
        "short int": (2, 2),
        "unsigned short": (2, 2),
        "uint16_t": (2, 2),
        "int16_t": (2, 2),
        "int": (4, 4),
        "signed int": (4, 4),
        "unsigned int": (4, 4),
        "uint32_t": (4, 4),
        "int32_t": (4, 4),
        "float": (4, 4),
        "long": (long_size, long_size),
        "unsigned long": (long_size, long_size),
        "long int": (long_size, long_size),
        "long long": (8, 8),
        "unsigned long long": (8, 8),
        "uint64_t": (8, 8),
        "int64_t": (8, 8),
        "double": (8, 8),
        "long double": (16 if arch == 64 else 8, 16 if arch == 64 else 8),
        "pointer": (ptr_size, ptr_size),
        "size_t": (ptr_size, ptr_size),
    }


def parse_field_spec(field_str: str, type_specs: Dict[str, tuple[int, int]]) -> Optional[tuple[str, int, int]]:
    """
    Parse a single struct field string like 'char a;' or 'int arr[10];' or 'void *ptr;'.
    Returns (field_name, size, alignment).
    """
    f = field_str.strip()
    if not f or f.startswith("//") or f.startswith("/*"):
        return None

    # Check for array: e.g. char buf[1024];
    array_match = re.search(r'\[\s*([0-9]+)\s*\]', f)
    array_len = 1
    if array_match:
        array_len = int(array_match.group(1))

    # Check for pointer: *
    if "*" in f:
        ptr_size, ptr_align = type_specs["pointer"]
        # extract field name
        name_match = re.search(r'\*\s*([a-zA-Z_][a-zA-Z0-9_]*)', f)
        name = name_match.group(1) if name_match else "ptr_field"
        return (name, ptr_size * array_len, ptr_align)

    # Primitive types
    for type_name in sorted(type_specs.keys(), key=lambda k: len(k), reverse=True):
        pattern = rf'\b{re.escape(type_name)}\b(?:\s+([a-zA-Z_][a-zA-Z0-9_]*))?'
        m = re.search(pattern, f)
        if m:
            size, align = type_specs[type_name]
            name = m.group(1) or "field"
            return (name, size * array_len, align)

    # Default fallback for custom struct or unknown type
    ptr_size, ptr_align = type_specs["pointer"]
    return ("unknown_field", ptr_size * array_len, ptr_align)


def analyze_structs(code: str, arch: int = 64) -> Dict[str, Any]:
    """
    Find struct declarations and calculate estimated size and padding.
    """
    type_specs = get_type_specs(arch)

    # Match struct [Name] { ... };
    struct_pattern = re.compile(
        r'struct\s+([a-zA-Z_][a-zA-Z0-9_]*)?\s*\{([^}]+)\}',
        re.MULTILINE | re.DOTALL
    )

    struct_count = 0
    struct_total_fields = 0
    total_estimated_size = 0
    total_padding_bytes = 0
    max_struct_padding = 0

    struct_details: List[Dict[str, Any]] = []

    for match in struct_pattern.finditer(code):
        struct_count += 1
        struct_name = match.group(1) or f"AnonymousStruct_{struct_count}"
        body = match.group(2)
        line_no = code[:match.start()].count("\n") + 1

        fields_raw = [f.strip() for f in body.split(";") if f.strip()]
        parsed_fields = []

        current_offset = 0
        current_padding = 0
        max_align = 1

        for raw_f in fields_raw:
            parsed = parse_field_spec(raw_f, type_specs)
            if parsed is None:
                continue

            fname, fsize, falign = parsed
            struct_total_fields += 1
            max_align = max(max_align, falign)

            # Calculate padding before this field to satisfy alignment
            remainder = current_offset % falign
            padding_needed = (falign - remainder) % falign
            current_padding += padding_needed
            current_offset += padding_needed + fsize

            parsed_fields.append({
                "name": fname,
                "size": fsize,
                "align": falign,
                "offset": current_offset - fsize,
                "padding_before": padding_needed
            })

        # Tail padding to align struct size to multiple of max_align
        remainder = current_offset % max_align
        tail_padding = (max_align - remainder) % max_align
        current_padding += tail_padding
        total_struct_size = current_offset + tail_padding

        total_estimated_size += total_struct_size
        total_padding_bytes += current_padding
        if current_padding > max_struct_padding:
            max_struct_padding = current_padding

        struct_details.append({
            "name": struct_name,
            "line": line_no,
            "fields": parsed_fields,
            "estimated_size": total_struct_size,
            "estimated_padding": current_padding,
            "field_count": len(parsed_fields)
        })

    return {
        "struct_analysis": "estimated",
        "struct_count": struct_count,
        "struct_total_fields": struct_total_fields,
        "estimated_struct_size": total_estimated_size,
        "estimated_padding_bytes": total_padding_bytes,
        "max_struct_padding": max_struct_padding,
        "struct_details": struct_details
    }
