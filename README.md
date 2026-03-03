# jsdoc

`jsdoc` is a Python parser for **JSON with comments and docstrings**.

It lets you keep human-friendly documentation directly inside JSON-like files while still loading data into normal Python dictionaries and lists.

## Why jsdoc?

Standard JSON is strict and does not allow comments or multiline doc-style strings. `jsdoc` extends JSON with practical authoring features:

- JavaScript-style comments (`//` and `/* ... */`)
- Bare keys (unquoted identifiers)
- Triple-quoted docstrings (`""" ... """`) for multiline text

After preprocessing, the content is parsed with Python’s built-in `json` parser.

## Installation

```bash
pip install jsdoc
```

## Quick Start

### Parse from a string

```python
import jsdoc

text = """
{
  // Display settings
  title: "Campaign Handbook",

  description: """
    A player-facing handbook.
    Includes lore, rules, and examples.
  """,

  page_count: 128
}
"""

data = jsdoc.loads(text)
print(data["title"])
print(data["description"])
```

### Parse from a file

```python
import jsdoc

data = jsdoc.load("config.jsdoc")
print(data)
```

### Dump data back to .jsdoc

```python
import jsdoc

data = {
    "name": "Field Manual",
    "notes": "This is a long block of descriptive text.",
}

jsdoc.dump(data, "output.jsdoc")
```

## Comment and Docstring Behavior

- Comments are removed before JSON parsing.
- Triple-quoted values are converted into JSON strings.
- By default, whitespace inside triple-quoted blocks is normalized.
- Use `preserve_newlines=True` to keep line breaks.

```python
import jsdoc

value = jsdoc.loads(
    '{ text: """line 1\nline 2\nline 3""" }',
    preserve_newlines=True,
)

print(value["text"])
```

## Error Handling

`jsdoc` raises custom parse errors for malformed jsdoc syntax such as uneven or unclosed triple-quote delimiters.

```python
import jsdoc

try:
    jsdoc.loads('{ bad: """"" }')
except jsdoc.JSDocParseError as exc:
    print(f"Invalid jsdoc: {exc}")
```

For standard JSON syntax problems (for example trailing commas), Python’s `json.JSONDecodeError` is raised.

## API

- `jsdoc.loads(text, *, preserve_newlines=False, **kwargs)`
- `jsdoc.load(path, *, preserve_newlines=False, encoding="utf-8", **kwargs)`
- `jsdoc.dumps(data, *, indent=2, threshold=80)`
- `jsdoc.dump(data, path, *, indent=2, threshold=80, encoding="utf-8")`

## Use Cases

- Config files with inline explanations
- Content databases with rich multiline descriptions
- Human-authored JSON-like files that need documentation context

## License

MIT