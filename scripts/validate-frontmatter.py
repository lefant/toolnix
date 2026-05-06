#!/usr/bin/env python3
"""Validate parser-safety of markdown YAML frontmatter.

This intentionally checks only silent-corruption hazards that simple YAML
parsers may accept while changing meaning: malformed delimiters, unquoted
inline comments, and unquoted mapping-looking scalar values.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path


FIELD_RE = re.compile(r"^([A-Za-z_][A-Za-z0-9_-]*):(?:\s*(.*))?$")
LIST_ITEM_RE = re.compile(r"^(\s*)-\s+(.*)$")


def is_quoted(value: str) -> bool:
    value = value.strip()
    return len(value) >= 2 and value[0] == value[-1] and value[0] in {'"', "'"}


def has_unquoted_hazard(value: str) -> str | None:
    value = value.strip()
    if not value or is_quoted(value) or value.startswith("[") or value.startswith("{"):
        return None
    if " #" in value:
        return "contains unquoted ' #' which YAML treats as a comment"
    if ": " in value:
        return "contains unquoted ': ' which YAML may treat as a mapping separator"
    return None


def validate(path: Path) -> list[str]:
    text = path.read_text()
    lines = text.splitlines()
    errors: list[str] = []

    if not lines or lines[0] != "---":
        return ["frontmatter must start with an exact '---' delimiter on line 1"]

    end = None
    for i, line in enumerate(lines[1:], start=2):
        if line == "---":
            end = i
            break
        if line.startswith("---") and line != "---":
            errors.append(f"line {i}: malformed frontmatter delimiter {line!r}")

    if end is None:
        errors.append("frontmatter must end with an exact '---' delimiter")
        end = len(lines) + 1

    current_field = None
    for i, line in enumerate(lines[1 : end - 1], start=2):
        if not line.strip() or line.lstrip().startswith("#"):
            continue

        field_match = FIELD_RE.match(line)
        if field_match:
            current_field = field_match.group(1)
            value = field_match.group(2) or ""
            hazard = has_unquoted_hazard(value)
            if hazard:
                errors.append(f"line {i}, field {current_field}: {hazard}")
            continue

        item_match = LIST_ITEM_RE.match(line)
        if item_match:
            value = item_match.group(2)
            hazard = has_unquoted_hazard(value)
            if hazard:
                field = current_field or "<unknown>"
                errors.append(f"line {i}, field {field}: {hazard}")
            continue

    return errors


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: validate-frontmatter.py <markdown-file>", file=sys.stderr)
        return 2

    path = Path(sys.argv[1])
    errors = validate(path)
    if errors:
        for error in errors:
            print(f"{path}: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
