#!/usr/bin/env python3
from pathlib import Path
import sys


REQUIREMENTS = Path("docs/requirements.md")


def main() -> int:
    text = REQUIREMENTS.read_text(encoding="utf-8")
    lines = text.splitlines()
    errors: list[str] = []

    if "Section 30 is explicitly informative" not in text:
        errors.append("traceability model must state that Section 30 is informative")

    start = None
    for idx, line in enumerate(lines, start=1):
        if line.startswith("## 30."):
            start = idx
            break
    if start is None:
        errors.append("missing Section 30 informative trace block")
    else:
        section_lines = lines[start - 1 :]
        if not any("Informative trace:" in line for line in section_lines):
            errors.append("Section 30 entries must be informative traces")
        for offset, line in enumerate(section_lines, start=start):
            if "  - Requirement:" in line:
                errors.append(f"line {offset}: Section 30 must not contain normative Requirement rows")

    for error in errors:
        print(f"{REQUIREMENTS}: {error}", file=sys.stderr)
    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
