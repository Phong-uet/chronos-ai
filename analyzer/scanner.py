"""
scanner.py - Recursive discovery of C/C++ source files and robust reading.
"""

from pathlib import Path
from typing import List, Dict, Any, Optional
import os


SUPPORTED_EXTENSIONS = {".c", ".cpp", ".cc", ".cxx", ".h", ".hpp", ".hxx"}


def scan_source_files(root_dir: str | Path) -> List[Path]:
    """
    Recursively scan a directory for C/C++ source and header files.
    """
    root = Path(root_dir).resolve()
    if not root.exists():
        raise FileNotFoundError(f"Input directory does not exist: {root}")

    matched_files: List[Path] = []
    for path in root.rglob("*"):
        if path.is_file() and path.suffix.lower() in SUPPORTED_EXTENSIONS:
            matched_files.append(path)

    # Sort for deterministic processing
    matched_files.sort(key=lambda p: str(p).lower())
    return matched_files


def read_file_content(file_path: Path) -> tuple[str, Optional[str]]:
    """
    Read file contents using multiple encodings with fallback.
    Returns (content, warning_if_any).
    """
    encodings = ["utf-8", "utf-8-sig", "latin-1", "cp1252", "iso-8859-1"]
    warning = None

    for enc in encodings:
        try:
            with open(file_path, "r", encoding=enc) as f:
                return f.read(), warning
        except (UnicodeDecodeError, LookupError):
            continue

    # Fallback with replacement
    try:
        with open(file_path, "r", encoding="utf-8", errors="replace") as f:
            warning = f"File {file_path.name} read with UTF-8 replacement chars due to encoding errors"
            return f.read(), warning
    except Exception as e:
        warning = f"Failed to read {file_path.name}: {str(e)}"
        return "", warning
