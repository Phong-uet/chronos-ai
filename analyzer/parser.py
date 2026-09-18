"""
parser.py - Tree-sitter AST parser setup with fallback handling.
"""

from typing import Optional, Tuple, Any
from pathlib import Path

# Try importing tree_sitter
TREE_SITTER_AVAILABLE = False
_c_parser = None
_cpp_parser = None

try:
    import tree_sitter
    import tree_sitter_c
    import tree_sitter_cpp
    from tree_sitter import Language, Parser

    _c_language = Language(tree_sitter_c.language())
    _cpp_language = Language(tree_sitter_cpp.language())

    _c_parser = Parser(_c_language)
    _cpp_parser = Parser(_cpp_language)
    TREE_SITTER_AVAILABLE = True
except Exception:
    TREE_SITTER_AVAILABLE = False


def parse_code(code: str, file_path: Optional[Path] = None) -> Tuple[Any, str, Optional[str]]:
    """
    Parse C/C++ code.
    Returns: (tree_or_none, parser_type, warning_if_any)
    parser_type is either 'tree_sitter' or 'regex_fallback'.
    """
    if not TREE_SITTER_AVAILABLE:
        return None, "regex_fallback", "Tree-sitter not available, using regex fallback"

    # Select parser based on extension
    is_cpp = False
    if file_path:
        ext = file_path.suffix.lower()
        if ext in {".cpp", ".cc", ".cxx", ".hpp", ".hxx"}:
            is_cpp = True

    parser = _cpp_parser if is_cpp else _c_parser
    if parser is None:
        return None, "regex_fallback", "Tree-sitter parser failed to initialize"

    try:
        code_bytes = code.encode("utf-8", errors="replace")
        tree = parser.parse(code_bytes)
        
        # Check if root node contains severe parse errors throughout
        if tree.root_node.has_error:
            # We still return the tree because tree-sitter error-recovery usually
            # parses surrounding valid nodes effectively, but we record warning.
            warning = "Tree contains syntax errors (recovered via Tree-sitter error nodes)"
            return tree, "tree_sitter", warning

        return tree, "tree_sitter", None
    except Exception as e:
        return None, "regex_fallback", f"Tree-sitter parsing exception: {e}"


def is_node_error(node: Any) -> bool:
    """Check if node is an ERROR or MISSING node in Tree-sitter AST."""
    if node is None:
        return False
    return node.type in ("ERROR", "MISSING")
