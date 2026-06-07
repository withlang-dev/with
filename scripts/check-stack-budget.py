#!/usr/bin/env python3
"""Check native binary stack-frame metadata against a budget.

Windows PE binaries are inspected with `llvm-readobj --unwind`.
ELF binaries are inspected with `readelf --debug-dump=frames`.
Mach-O binaries are inspected with `llvm-dwarfdump --eh-frame` when available.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
from dataclasses import dataclass


@dataclass
class StackReport:
    path: str
    format: str
    frame_count: int
    max_frame: int
    ge_16k: int
    ge_64k: int
    ge_128k: int
    ge_256k: int


def run_tool(argv: list[str]) -> str:
    proc = subprocess.run(argv, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    if proc.returncode != 0:
        raise RuntimeError(f"{argv[0]} failed with exit code {proc.returncode}: {proc.stderr.strip()}")
    return proc.stdout


def find_tool(*names: str) -> str | None:
    for name in names:
        found = shutil.which(name)
        if found:
            return found
    for root in (
        r"C:\Program Files\LLVM\bin",
        r"C:\Program Files (x86)\LLVM\bin",
    ):
        for name in names:
            candidate = os.path.join(root, name)
            if os.path.exists(candidate):
                return candidate
    return None


def classify(path: str) -> str:
    with open(path, "rb") as f:
        head = f.read(4)
    if head[:2] == b"MZ":
        return "pe"
    if head == b"\x7fELF":
        return "elf"
    if head in (b"\xfe\xed\xfa\xcf", b"\xcf\xfa\xed\xfe", b"\xca\xfe\xba\xbe", b"\xbe\xba\xfe\xca"):
        return "macho"
    return "unknown"


def summarize(path: str, fmt: str, sizes: list[int]) -> StackReport:
    return StackReport(
        path=path,
        format=fmt,
        frame_count=len(sizes),
        max_frame=max(sizes) if sizes else 0,
        ge_16k=sum(1 for n in sizes if n >= 16 * 1024),
        ge_64k=sum(1 for n in sizes if n >= 64 * 1024),
        ge_128k=sum(1 for n in sizes if n >= 128 * 1024),
        ge_256k=sum(1 for n in sizes if n >= 256 * 1024),
    )


def pe_report(path: str) -> StackReport:
    tool = find_tool("llvm-readobj", "llvm-readobj.exe")
    if not tool:
        raise RuntimeError("llvm-readobj is required for PE stack budget checks")
    text = run_tool([tool, "--unwind", path])
    sizes = [int(m.group(1)) for m in re.finditer(r"ALLOC_(?:SMALL|LARGE) size=(\d+)", text)]
    return summarize(path, "pe", sizes)


def elf_report(path: str) -> StackReport:
    tool = find_tool("readelf")
    if not tool:
        raise RuntimeError("readelf is required for ELF stack budget checks")
    text = run_tool([tool, "--debug-dump=frames", path])
    sizes = [int(m.group(1)) for m in re.finditer(r"DW_CFA_def_cfa_offset:\s*(\d+)", text)]
    return summarize(path, "elf", sizes)


def macho_report(path: str) -> StackReport:
    tool = find_tool("llvm-dwarfdump", "llvm-dwarfdump.exe")
    if not tool:
        raise RuntimeError("llvm-dwarfdump is required for Mach-O stack budget checks")
    text = run_tool([tool, "--eh-frame", path])
    sizes = [int(m.group(1)) for m in re.finditer(r"DW_CFA_def_cfa_offset:\s*(\d+)", text)]
    return summarize(path, "macho", sizes)


def print_text(report: StackReport, max_frame: int) -> None:
    print(f"path: {report.path}")
    print(f"format: {report.format}")
    print(f"frame_count: {report.frame_count}")
    print(f"max_frame: {report.max_frame}")
    print(f"frames_ge_16k: {report.ge_16k}")
    print(f"frames_ge_64k: {report.ge_64k}")
    print(f"frames_ge_128k: {report.ge_128k}")
    print(f"frames_ge_256k: {report.ge_256k}")
    print(f"max_frame_budget: {max_frame}")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("binary")
    parser.add_argument("--max-frame", type=int, default=64 * 1024)
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    path = os.path.abspath(args.binary)
    fmt = classify(path)
    if fmt == "pe":
        report = pe_report(path)
    elif fmt == "elf":
        report = elf_report(path)
    elif fmt == "macho":
        report = macho_report(path)
    else:
        raise RuntimeError(f"unsupported binary format: {path}")

    if args.json:
        print(json.dumps(report.__dict__, indent=2, sort_keys=True))
    else:
        print_text(report, args.max_frame)

    if report.max_frame > args.max_frame:
        print(
            f"error: max frame {report.max_frame} exceeds budget {args.max_frame}",
            file=sys.stderr,
        )
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
