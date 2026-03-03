import re

from .errors import JSDocParseError

cdef object _TRIPLE_QUOTE_RE = re.compile(r'(?<!")"{3}(.*?)"{3}(?!")', re.DOTALL)
cdef object _BARE_KEY_RE = re.compile(r'(?<=[{,])\s*([A-Za-z_$][A-Za-z0-9_$]*)\s*(?=:)')


def _count_consecutive_quotes(str text, int start):
    cdef int end = start
    cdef int length = len(text)
    while end < length and text[end] == '"':
        end += 1
    return end - start


def _validate_triple_quote_delimiters(str raw):
    cdef int i = 0
    cdef int length = len(raw)
    cdef bint in_string = False
    cdef bint in_line_comment = False
    cdef bint in_block_comment = False
    cdef bint in_triple_quote = False
    cdef int quote_count
    cdef int delimiter_groups

    while i < length:
        if in_line_comment:
            if raw[i] == '\n':
                in_line_comment = False
            i += 1
            continue

        if in_block_comment:
            if i + 1 < length and raw[i] == '*' and raw[i + 1] == '/':
                in_block_comment = False
                i += 2
            else:
                i += 1
            continue

        if in_triple_quote:
            if i + 2 < length and raw[i:i + 3] == '"""':
                quote_count = _count_consecutive_quotes(raw, i)
                if quote_count % 3 != 0:
                    raise JSDocParseError(
                        f"Invalid triple-quote delimiter length ({quote_count}) at index {i}. "
                        "Triple-quoted strings must use balanced groups of exactly three quotes."
                    )

                delimiter_groups = quote_count // 3
                if delimiter_groups % 2 == 1:
                    in_triple_quote = False

                i += quote_count
            else:
                i += 1
            continue

        if in_string:
            if raw[i] == '\\' and i + 1 < length:
                i += 2
            elif raw[i] == '"':
                in_string = False
                i += 1
            else:
                i += 1
            continue

        if i + 1 < length and raw[i] == '/' and raw[i + 1] == '/':
            in_line_comment = True
            i += 2
            continue

        if i + 1 < length and raw[i] == '/' and raw[i + 1] == '*':
            in_block_comment = True
            i += 2
            continue

        if i + 2 < length and raw[i:i + 3] == '"""':
            quote_count = _count_consecutive_quotes(raw, i)
            if quote_count % 3 != 0:
                raise JSDocParseError(
                    f"Invalid triple-quote delimiter length ({quote_count}) at index {i}. "
                    "Triple-quoted strings must use balanced groups of exactly three quotes."
                )

            delimiter_groups = quote_count // 3
            if delimiter_groups % 2 == 1:
                in_triple_quote = True

            i += quote_count
            continue

        if raw[i] == '"':
            in_string = True
            i += 1
            continue

        i += 1

    if in_triple_quote:
        raise JSDocParseError("Unclosed triple-quoted string in jsdoc input.")


def _extract_triple_quotes(str raw, bint preserve_newlines=False):
    cdef list replacements = []
    cdef str inner
    cdef str escaped
    _validate_triple_quote_delimiters(raw)

    def replacer(match):
        inner = match.group(1)
        inner = inner.strip('"')
        if preserve_newlines:
            inner2 = inner.strip()
        else:
            inner2 = " ".join(inner.split())

        escaped2 = inner2
        escaped2 = escaped2.replace('\\', '\\\\')
        escaped2 = escaped2.replace('"', '\\"')
        escaped2 = escaped2.replace('\n', '\\n')
        escaped2 = escaped2.replace('\r', '\\r')
        escaped2 = escaped2.replace('\t', '\\t')

        placeholder = f'__JSDOC_TQ_{len(replacements)}__'
        replacements.append('"' + escaped2 + '"')
        return placeholder

    text = _TRIPLE_QUOTE_RE.sub(replacer, raw)
    return text, replacements


def _restore_triple_quotes(str text, list replacements):
    cdef int i
    cdef object value
    for i, value in enumerate(replacements):
        text = text.replace(f'__JSDOC_TQ_{i}__', value)
    return text


def _strip_comments(str text):
    cdef list result = []
    cdef int i = 0
    cdef int length = len(text)

    while i < length:
        if text[i] == '"':
            result.append('"')
            i += 1
            while i < length:
                if text[i] == '\\' and i + 1 < length:
                    result.append(text[i:i + 2])
                    i += 2
                elif text[i] == '"':
                    result.append('"')
                    i += 1
                    break
                else:
                    result.append(text[i])
                    i += 1
        elif text[i] == '/' and i + 1 < length and text[i + 1] == '/':
            i += 2
            while i < length and text[i] != '\n':
                i += 1
        elif text[i] == '/' and i + 1 < length and text[i + 1] == '*':
            i += 2
            while i + 1 < length and not (text[i] == '*' and text[i + 1] == '/'):
                i += 1
            i += 2
        else:
            result.append(text[i])
            i += 1

    return ''.join(result)


def _quote_bare_keys(str text):
    return _BARE_KEY_RE.sub(lambda m: f' "{m.group(1)}" ', text)


def preprocess(str raw, bint preserve_newlines=False):
    text, replacements = _extract_triple_quotes(raw, preserve_newlines)
    text = _strip_comments(text)
    text = _quote_bare_keys(text)
    text = _restore_triple_quotes(text, replacements)
    return text
