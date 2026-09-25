#!/usr/bin/env python3
"""Cross-language benchmark runner: With against Rust, C, Go, and Zig.

For every workload, language, and optimization level this measures:

  compile   wall-clock seconds to build the program, with the toolchain's own
            caches warm but nothing cached for the program itself
  size      stripped executable size in bytes
  run       wall-clock seconds for the whole process, median of N runs
  inner     the program's own timer around its hot loop, median of N runs
  rss       peak resident set size, maximum over the runs
  checksum  the program's result, which must agree across languages

Usage:
  ./run.py                    debug and release levels, every workload
  ./run.py --full             every optimization level each compiler offers
  ./run.py -w nbody -w trees  only the named workloads
  ./run.py -l with -l rust    only the named languages
  ./run.py -n 5               five timed runs per cell instead of three
  ./run.py -o results         write results.md, results.csv, results.json

Missing toolchains are skipped, not fatal.
"""

import argparse
import json
import os
import platform
import re
import shutil
import statistics
import subprocess
import sys
import tempfile
import time
from dataclasses import dataclass, field, asdict
from pathlib import Path

HERE = Path(__file__).resolve().parent
WORKLOADS_DIR = HERE / "workloads"
IS_MAC = platform.system() == "Darwin"


# ── Languages ────────────────────────────────────────────────────────


@dataclass
class Language:
    name: str
    extension: str
    compiler: str              # executable looked up on PATH
    levels: dict               # level name -> extra compiler arguments
    default_levels: tuple      # (debug, release) used without --full
    version_args: tuple
    env: dict = field(default_factory=dict)

    def available(self):
        return shutil.which(self.compiler) is not None

    def version(self):
        try:
            out = subprocess.run([self.compiler, *self.version_args], capture_output=True, text=True, timeout=60)
            text = (out.stdout or out.stderr).strip().splitlines()
            return text[0] if text else self.compiler
        except (OSError, subprocess.TimeoutExpired):
            return self.compiler

    def compile_command(self, level, source, output):
        raise NotImplementedError


class With(Language):
    def compile_command(self, level, source, output):
        return ["with", "build", str(source), *self.levels[level], "-o", str(output)]


class Rust(Language):
    def compile_command(self, level, source, output):
        return ["rustc", "--edition", "2021", *self.levels[level], "-C", "incremental=no", "-o", str(output), str(source)]


class C(Language):
    def compile_command(self, level, source, output):
        # Contraction off keeps a*b+c from fusing into an FMA, so float results
        # stay bit-identical with the languages that never fuse.
        return [self.compiler, *self.levels[level], "-std=c11", "-ffp-contract=off", "-lm", "-o", str(output), str(source)]


class Go(Language):
    def compile_command(self, level, source, output):
        return ["go", "build", *self.levels[level], "-o", str(output), str(source)]


class Zig(Language):
    def compile_command(self, level, source, output):
        args = ["zig", "build-exe", str(source), *self.levels[level], "-lc", f"-femit-bin={output}"]
        if IS_MAC:
            args += ["-target", "native-macos"]
        return args


def c_compiler():
    # Apple's clang carries the SDK sysroot; a bare LLVM clang on PATH may not.
    if IS_MAC and Path("/usr/bin/clang").exists():
        return "/usr/bin/clang"
    return shutil.which("cc") or shutil.which("clang") or shutil.which("gcc") or "cc"


LANGUAGES = {
    "with": With("With", "w", "with",
                 {"O0": ["-O0"], "O1": ["-O1"], "O2": ["-O2"], "O3": ["-O3"]},
                 ("O0", "O3"), ("--version",)),
    "rust": Rust("Rust", "rs", "rustc",
                 {"O0": ["-Copt-level=0"], "O1": ["-Copt-level=1"], "O2": ["-Copt-level=2"], "O3": ["-Copt-level=3"]},
                 ("O0", "O3"), ("--version",)),
    "c": C("C", "c", c_compiler(),
           {"O0": ["-O0"], "O1": ["-O1"], "O2": ["-O2"], "O3": ["-O3"]},
           ("O0", "O3"), ("--version",)),
    "go": Go("Go", "go", "go",
             {"debug": ["-gcflags=all=-N -l"], "release": []},
             ("debug", "release"), ("version",)),
    "zig": Zig("Zig", "zig", "zig",
               {"Debug": ["-ODebug"], "ReleaseSafe": ["-OReleaseSafe"],
                "ReleaseFast": ["-OReleaseFast"], "ReleaseSmall": ["-OReleaseSmall"]},
               ("Debug", "ReleaseFast"), ("version",)),
}


# ── Measurement ──────────────────────────────────────────────────────


@dataclass
class Cell:
    workload: str
    language: str
    level: str
    compile_s: float = None
    size_bytes: int = None
    run_s: float = None
    inner_s: float = None
    rss_bytes: int = None
    checksum: str = None
    status: str = "ok"          # ok | compile-failed | run-failed | timeout | skipped
    detail: str = ""


def with_unique_comment(source: Path, work: Path):
    """Copy the source with a unique trailing comment so no build cache can
    return a previous compilation of this exact program."""
    work.mkdir(parents=True, exist_ok=True)
    copy = work / source.name
    text = source.read_text()
    marker = f"bench-{time.time_ns()}"
    copy.write_text(f"{text}\n// {marker}\n")
    return copy


def compile_once(lang, level, source, work, env):
    output = work / f"{source.stem}-{level}"
    if output.exists():
        output.unlink()
    command = lang.compile_command(level, source, output)
    started = time.perf_counter()
    proc = subprocess.run(command, cwd=work, env=env, capture_output=True, text=True)
    elapsed = time.perf_counter() - started
    if proc.returncode != 0 or not output.exists():
        return None, elapsed, (proc.stderr or proc.stdout).strip()
    return output, elapsed, ""


def strip_binary(path):
    stripped = path.with_name(path.name + ".stripped")
    shutil.copy2(path, stripped)
    subprocess.run(["strip", str(stripped)], capture_output=True)
    return stripped.stat().st_size


def run_once(binary, timeout):
    """Run the program under the system time command to read peak memory."""
    if IS_MAC:
        command = ["/usr/bin/time", "-l", str(binary)]
    else:
        command = ["/usr/bin/time", "-v", str(binary)]
    started = time.perf_counter()
    try:
        proc = subprocess.run(command, capture_output=True, text=True, timeout=timeout)
    except subprocess.TimeoutExpired:
        return None
    elapsed = time.perf_counter() - started
    if proc.returncode != 0:
        return {"error": (proc.stderr or proc.stdout).strip()[-400:]}
    rss = None
    for line in proc.stderr.splitlines():
        if "maximum resident set size" in line:
            rss = int(re.search(r"(\d+)", line).group(1))
            if not IS_MAC:
                rss *= 1024
    inner = None
    checksum = None
    for line in proc.stdout.splitlines():
        parts = line.split()
        if len(parts) == 2 and parts[0] == "elapsed_ms":
            inner = float(parts[1]) / 1000.0
        elif len(parts) == 2 and parts[0] == "checksum":
            checksum = parts[1]
    return {"wall": elapsed, "inner": inner, "checksum": checksum, "rss": rss, "stdout": proc.stdout, "stderr": proc.stderr}


def measure(workload, lang_key, level, runs, timeout, work_root):
    lang = LANGUAGES[lang_key]
    source = WORKLOADS_DIR / workload / f"{workload}.{lang.extension}"
    cell = Cell(workload, lang.name, level)
    if not source.exists():
        cell.status, cell.detail = "skipped", "no source"
        return cell
    work = work_root / f"{workload}-{lang_key}-{level}"
    work.mkdir(parents=True)
    env = dict(os.environ)
    env.update(lang.env)
    env["CARGO_INCREMENTAL"] = "0"
    env["ZIG_LOCAL_CACHE_DIR"] = str(work / "zig-cache")

    # Warm the toolchain (std library caches, first-run setup) on a throwaway
    # copy, then time a genuinely uncached build of the program.
    warm = with_unique_comment(source, work / "warm")
    compile_once(lang, level, warm, work / "warm", env)
    timed = with_unique_comment(source, work / "timed")
    binary, elapsed, error = compile_once(lang, level, timed, work / "timed", env)
    cell.compile_s = elapsed
    if binary is None:
        cell.status, cell.detail = "compile-failed", error[-400:]
        return cell
    cell.size_bytes = strip_binary(binary)

    walls, inners, rsses, checksums = [], [], [], []
    for _ in range(runs):
        result = run_once(binary, timeout)
        if result is None:
            cell.status, cell.detail = "timeout", f"exceeded {timeout}s"
            return cell
        if "error" in result:
            cell.status, cell.detail = "run-failed", result["error"]
            return cell
        walls.append(result["wall"])
        if result["inner"] is not None:
            inners.append(result["inner"])
        if result["rss"] is not None:
            rsses.append(result["rss"])
        if result["checksum"] is not None:
            checksums.append(result["checksum"])
        if workload == "hello" and "Hello, World!" not in result["stdout"] + result["stderr"]:
            cell.status, cell.detail = "run-failed", "wrong output"
            return cell
    cell.run_s = statistics.median(walls)
    cell.inner_s = statistics.median(inners) if inners else None
    cell.rss_bytes = max(rsses) if rsses else None
    cell.checksum = checksums[0] if checksums else ("Hello, World!" if workload == "hello" else None)
    if len(set(checksums)) > 1:
        cell.status, cell.detail = "run-failed", f"nondeterministic checksum {sorted(set(checksums))}"
    return cell


# ── Reporting ────────────────────────────────────────────────────────


def fmt_seconds(value):
    return "-" if value is None else f"{value:.3f}s"


def fmt_bytes(value):
    if value is None:
        return "-"
    if value >= 1 << 20:
        return f"{value / (1 << 20):.1f} MB"
    return f"{value / 1024:.0f} KB"


def fmt_ratio(value, best):
    if value is None or best is None or best == 0:
        return ""
    return f" ({value / best:.2f}x)"


def workload_description(workload):
    source = WORKLOADS_DIR / workload / f"{workload}.w"
    if not source.exists():
        return ""
    lines = [l[3:] for l in source.read_text().splitlines() if l.startswith("// ")]
    return " ".join(lines[:2])


def markdown_report(cells, versions, args):
    out = []
    host = f"{platform.system()} {platform.machine()}"
    try:
        cpu = subprocess.run(["sysctl", "-n", "machdep.cpu.brand_string"], capture_output=True, text=True).stdout.strip()
        if cpu:
            host += f", {cpu}"
    except OSError:
        pass
    out.append("# Benchmark results\n")
    out.append(f"Host: {host}  ")
    out.append(f"Runs per cell: {args.runs} (median for times, max for memory)  ")
    out.append(f"Levels: {'every level' if args.full else 'debug and release'}\n")
    out.append("## Toolchains\n")
    for name, version in versions.items():
        out.append(f"- {name}: {version}")
    out.append("")
    workloads = []
    for cell in cells:
        if cell.workload not in workloads:
            workloads.append(cell.workload)
    for workload in workloads:
        rows = [c for c in cells if c.workload == workload]
        out.append(f"## {workload}\n")
        description = workload_description(workload)
        if description:
            out.append(description + "\n")
        release = [c for c in rows if c.status == "ok" and c.level in ("O3", "release", "ReleaseFast")]
        best_run = min((c.run_s for c in release if c.run_s), default=None)
        best_inner = min((c.inner_s for c in release if c.inner_s), default=None)
        best_compile = min((c.compile_s for c in rows if c.status == "ok" and c.compile_s), default=None)
        if workload == "hello":
            out.append("| Language | Level | Compile | Size | Output |")
            out.append("|---|---|---:|---:|---|")
            for c in rows:
                if c.status != "ok":
                    out.append(f"| {c.language} | {c.level} | {c.status} | | {c.detail[:60]} |")
                    continue
                out.append(f"| {c.language} | {c.level} | {fmt_seconds(c.compile_s)}{fmt_ratio(c.compile_s, best_compile)} | {fmt_bytes(c.size_bytes)} | ok |")
        else:
            out.append("| Language | Level | Compile | Size | Run (wall) | Hot loop | Peak RSS | Checksum |")
            out.append("|---|---|---:|---:|---:|---:|---:|---|")
            for c in rows:
                if c.status != "ok":
                    out.append(f"| {c.language} | {c.level} | {c.status} | | | | | {c.detail[:60]} |")
                    continue
                ratio_run = fmt_ratio(c.run_s, best_run) if c in release else ""
                ratio_inner = fmt_ratio(c.inner_s, best_inner) if c in release else ""
                out.append(f"| {c.language} | {c.level} | {fmt_seconds(c.compile_s)}{fmt_ratio(c.compile_s, best_compile)} | {fmt_bytes(c.size_bytes)} | {fmt_seconds(c.run_s)}{ratio_run} | {fmt_seconds(c.inner_s)}{ratio_inner} | {fmt_bytes(c.rss_bytes)} | {c.checksum or '-'} |")
            checksums = {c.checksum for c in rows if c.status == "ok" and c.checksum}
            if len(checksums) > 1:
                out.append(f"\n**Checksums disagree** across implementations: {sorted(checksums)}. Treat the timings as comparable only once every language computes the same result.")
        out.append("")
    out.append("Ratios are relative to the best release-level cell in the same column. "
               "Compile time is a cold build of the program with the toolchain's caches already warm. "
               "Hot loop is the program's own timer around its core work; Run is the whole process.")
    return "\n".join(out) + "\n"


def csv_report(cells):
    lines = ["workload,language,level,status,compile_s,size_bytes,run_s,inner_s,rss_bytes,checksum"]
    for c in cells:
        lines.append(",".join(str(v if v is not None else "") for v in
                              [c.workload, c.language, c.level, c.status, c.compile_s, c.size_bytes,
                               c.run_s, c.inner_s, c.rss_bytes, c.checksum]))
    return "\n".join(lines) + "\n"


# ── Main ─────────────────────────────────────────────────────────────


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("-w", "--workload", action="append", help="workload to run (repeatable)")
    parser.add_argument("-l", "--language", action="append", choices=sorted(LANGUAGES), help="language to run (repeatable)")
    parser.add_argument("-n", "--runs", type=int, default=3, help="timed runs per cell (default 3)")
    parser.add_argument("--full", action="store_true", help="every optimization level, not just debug and release")
    parser.add_argument("--timeout", type=float, default=120.0, help="seconds allowed per run (default 120)")
    parser.add_argument("-o", "--output", help="basename for results.md/.csv/.json (default: print markdown only)")
    parser.add_argument("--keep", action="store_true", help="keep the temporary build directory")
    args = parser.parse_args()

    all_workloads = sorted(p.name for p in WORKLOADS_DIR.iterdir() if p.is_dir())
    workloads = args.workload or all_workloads
    for w in workloads:
        if w not in all_workloads:
            sys.exit(f"unknown workload {w!r}; available: {', '.join(all_workloads)}")
    languages = args.language or ["with", "rust", "c", "go", "zig"]

    versions = {}
    active = []
    for key in languages:
        lang = LANGUAGES[key]
        if lang.available():
            versions[lang.name] = lang.version()
            active.append(key)
        else:
            print(f"skipping {lang.name}: {lang.compiler!r} not found on PATH", file=sys.stderr)
    if not active:
        sys.exit("no toolchains available")

    work_root = Path(tempfile.mkdtemp(prefix="with-bench-"))
    cells = []
    total = sum(len(LANGUAGES[k].levels) if args.full else 2 for k in active) * len(workloads)
    done = 0
    for workload in workloads:
        for key in active:
            lang = LANGUAGES[key]
            levels = list(lang.levels) if args.full else list(lang.default_levels)
            for level in levels:
                done += 1
                print(f"[{done}/{total}] {workload} {lang.name} {level} ...", end=" ", flush=True, file=sys.stderr)
                cell = measure(workload, key, level, 1 if workload == "hello" else args.runs, args.timeout, work_root)
                cells.append(cell)
                if cell.status == "ok":
                    print(f"compile {fmt_seconds(cell.compile_s)}, run {fmt_seconds(cell.run_s)}", file=sys.stderr)
                else:
                    print(f"{cell.status}: {cell.detail[:80]}", file=sys.stderr)

    report = markdown_report(cells, versions, args)
    if args.output:
        base = Path(args.output)
        base.with_suffix(".md").write_text(report)
        base.with_suffix(".csv").write_text(csv_report(cells))
        base.with_suffix(".json").write_text(json.dumps({"toolchains": versions, "cells": [asdict(c) for c in cells]}, indent=2))
        print(f"wrote {base.with_suffix('.md')}, {base.with_suffix('.csv')}, {base.with_suffix('.json')}", file=sys.stderr)
    print(report)
    if args.keep:
        print(f"build directory kept: {work_root}", file=sys.stderr)
    else:
        shutil.rmtree(work_root, ignore_errors=True)


if __name__ == "__main__":
    main()
