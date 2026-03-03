import json
import re

from .errors import JSDocError, JSDocParseError

try:
    from ._cython_backend import preprocess as _preprocess
    USING_CYTHON_BACKEND = True
except Exception:
    from ._python_backend import preprocess as _preprocess
    USING_CYTHON_BACKEND = False

__all__ = [
    "JSDocError",
    "JSDocParseError",
    "USING_CYTHON_BACKEND",
    "load",
    "loads",
    "dump",
    "dumps",
]

_PREPROCESS_MARKERS = ("\"\"\"", "//", "/*")


def loads(text, *, preserve_newlines=False, **kwargs):
    """Parse a jsdoc string. Extra kwargs pass through to json.loads."""
    if any(marker in text for marker in _PREPROCESS_MARKERS):
        return json.loads(_preprocess(text, preserve_newlines), **kwargs)
    try:
        return json.loads(text, **kwargs)
    except json.JSONDecodeError:
        return json.loads(_preprocess(text, preserve_newlines), **kwargs)


def load(path, *, preserve_newlines=False, encoding="utf-8", **kwargs):
    """Load and parse a .jsdoc file."""
    with open(path, "r", encoding=encoding) as f:
        return loads(f.read(), preserve_newlines=preserve_newlines, **kwargs)


# --- Dump back to .jsdoc ---

def _needs_triple_quote(value, threshold=80):
    return len(value) > threshold or "<" in value


def dumps(data, *, indent=2, threshold=80):
    """Serialize a dict back to jsdoc format."""
    normal_json = json.dumps(data, indent=indent, ensure_ascii=False)

    def upgrade(match):
        raw = match.group(0)
        try:
            value = json.loads(raw)
        except (json.JSONDecodeError, TypeError):
            return raw
        if not isinstance(value, str):
            return raw
        if not _needs_triple_quote(value, threshold):
            return raw
        return '"""\n      ' + value + '\n    """'

    return re.sub(r'"(?:[^"\\]|\\.)*"', upgrade, normal_json)


def dump(data, path, *, indent=2, threshold=80, encoding="utf-8"):
    """Write a dict to a .jsdoc file."""
    with open(path, "w", encoding=encoding) as f:
        f.write(dumps(data, indent=indent, threshold=threshold))


if __name__ == "__main__":
    import sys

    if len(sys.argv) < 2:
        print("Usage: python jsdoc.py <file.jsdoc>")
        sys.exit(1)
    data = load(sys.argv[1])
    print(json.dumps(data, indent=2, ensure_ascii=False))
