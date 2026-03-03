class JSDocError(Exception):
    """Base exception for jsdoc parsing/serialization errors."""


class JSDocParseError(JSDocError):
    """Raised when jsdoc syntax is invalid before JSON decoding."""
