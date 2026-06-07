#!/usr/bin/env python3
from pathlib import Path
import sys


ROOTS = ("src", "rt", "lib/std")
NEEDLE = "@[c_export("


def count_actual_c_exports(path: Path) -> int:
    count = 0
    try:
        text = path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        text = path.read_text(encoding="utf-8-sig")
    for line in text.splitlines():
        stripped = line.lstrip(" \t")
        if stripped.startswith(NEEDLE):
            count += 1
    return count


def main() -> int:
    root = Path.cwd()
    errors = 0
    for rel in ROOTS:
        base = root / rel
        if not base.exists():
            continue
        for path in base.rglob("*.w"):
            count = count_actual_c_exports(path)
            if count:
                print(f"{path.as_posix()}: compiler-owned source has forbidden @[c_export] attributes", file=sys.stderr)
                errors += 1
    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
