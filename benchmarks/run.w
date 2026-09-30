// Cross-language benchmark runner: With against Rust, C, Go, and Zig.
//
// For every workload, language, and optimization level this measures:
//
//   compile   wall-clock seconds to build the program, with the toolchain's own
//             caches warm but nothing cached for the program itself
//   size      stripped executable size in bytes
//   run       wall-clock seconds for the whole process, median of N runs
//   inner     the program's own timer around its hot loop, median of N runs
//   rss       peak resident set size, maximum over the runs
//   checksum  the program's result, which must agree across languages
//
// Usage, from the repository root or from benchmarks/:
//   with run benchmarks/run.w                    debug and release levels, every workload
//   with run benchmarks/run.w --full             every optimization level each compiler offers
//   with run benchmarks/run.w -w nbody -w trees  only the named workloads
//   with run benchmarks/run.w -l with -l rust    only the named languages
//   with run benchmarks/run.w -n 5               five timed runs per cell instead of three
//   with run benchmarks/run.w -o results         write results.md, results.csv, results.json
//
// Missing toolchains are skipped, not fatal.
use std.fs
use std.json
use std.os
use std.process
use std.time

// ── Languages ────────────────────────────────────────────────────────

fn language_keys() -> Vec[str]: "with rust c go zig".split(" ")

fn language_name(key: &str) -> str:
    if key == "with": return "With"
    if key == "rust": return "Rust"
    if key == "c": return "C"
    if key == "go": return "Go"
    "Zig"

fn extension(key: &str) -> str:
    if key == "with": return "w"
    if key == "rust": return "rs"
    key.clone()

/// The executable looked up on PATH (C: the compiler that carries a sysroot).
fn compiler(key: &str) -> str:
    if key == "with": return "with"
    if key == "rust": return "rustc"
    if key == "c": return c_compiler()
    key.clone()

// Apple's clang carries the SDK sysroot; a bare LLVM clang on PATH may not.
fn c_compiler() -> str:
    if is_mac() and file_exists("/usr/bin/clang"): return "/usr/bin/clang"
    for name in "cc clang gcc".split(" "):
        if which(name).len() > 0: return which(name)
    "cc"

/// Every level the compiler offers, in order.
fn levels(key: &str) -> Vec[str]:
    if key == "go": return "debug release".split(" ")
    if key == "zig": return "Debug ReleaseSafe ReleaseFast ReleaseSmall".split(" ")
    "O0 O1 O2 O3".split(" ")

/// The (debug, release) pair used without --full.
fn default_levels(key: &str) -> Vec[str]:
    if key == "go": return "debug release".split(" ")
    if key == "zig": return "Debug ReleaseFast".split(" ")
    "O0 O3".split(" ")

fn level_args(key: &str, level: &str) -> Vec[str]:
    var out: Vec[str] = Vec.new()
    if key == "rust": out.push("-Copt-level=" ++ level.slice(1, 2))
    else if key == "go":
        if level == "debug": out.push("-gcflags=all=-N -l")
    else if key == "zig": out.push("-O" ++ level)
    else: out.push("-" ++ level)
    out

fn version_args(key: &str) -> Vec[str]:
    if key == "go" or key == "zig": return "version".split(" ")
    "--version".split(" ")

fn compile_command(key: &str, level: &str, source: &str, output: &str) -> Vec[str]:
    var argv: Vec[str] = Vec.new()
    let extra = level_args(key, level)
    if key == "with":
        argv.push("with")
        argv.push("build")
        argv.push(source.clone())
        for a in extra: argv.push(a.clone())
        argv.push("-o")
        argv.push(output.clone())
    else if key == "rust":
        for a in "rustc --edition 2021".split(" "): argv.push(a.clone())
        for a in extra: argv.push(a.clone())
        for a in "-C incremental=no -o".split(" "): argv.push(a.clone())
        argv.push(output.clone())
        argv.push(source.clone())
    else if key == "c":
        // Contraction off keeps a*b+c from fusing into an FMA, so float
        // results stay bit-identical with the languages that never fuse.
        argv.push(compiler(key))
        for a in extra: argv.push(a.clone())
        for a in "-std=c11 -ffp-contract=off -lm -o".split(" "): argv.push(a.clone())
        argv.push(output.clone())
        argv.push(source.clone())
    else if key == "go":
        argv.push("go")
        argv.push("build")
        for a in extra: argv.push(a.clone())
        argv.push("-o")
        argv.push(output.clone())
        argv.push(source.clone())
    else:
        argv.push("zig")
        argv.push("build-exe")
        argv.push(source.clone())
        for a in extra: argv.push(a.clone())
        argv.push("-lc")
        argv.push("-femit-bin=" ++ output)
        if is_mac():
            argv.push("-target")
            argv.push("native-macos")
    argv

// ── Host ─────────────────────────────────────────────────────────────

fn is_mac(): os() == "Macos"

/// The directory holding this runner: the workloads live beside it.
fn here() -> str:
    let marker = "benchmarks/run.w"
    if file_exists(marker): return "benchmarks"
    if file_exists("run.w") and file_exists("workloads"): return "."
    eprint("run.w: run it from the repository root or from benchmarks/ (workloads/ not found)")
    exit_code(1)

/// The absolute path of a program on PATH, or "" when it is not there.
fn which(name: &str) -> str:
    if name.contains("/"): return if file_exists(name): name.clone() else: ""
    for dir in env("PATH").split(":"):
        if dir.len() == 0: continue
        let path = dir ++ "/" ++ name
        if file_exists(path): return path
    ""

fn available(key: &str): which(compiler(key)).len() > 0

/// The first line the compiler prints for its version flag.
fn version(key: &str, scratch: &str) -> str:
    var argv: Vec[str] = Vec.new()
    argv.push(compiler(key))
    for a in version_args(key): argv.push(a.clone())
    let out = scratch ++ "/version.stdout"
    let err = scratch ++ "/version.stderr"
    let _ = run_to_files(&argv, out, err, 60000)
    let stdout = (read_file(out) ?? "").trim()
    let text = if stdout.len() > 0: stdout else: (read_file(err) ?? "").trim()
    let first = text.split("\n")[0].clone()
    if first.len() > 0: first else: compiler(key)

/// Python's `platform.system() platform.machine()` spelling, plus the CPU.
fn host(scratch: &str) -> str:
    let system = if is_mac(): "Darwin" else: os()
    let machine = if is_mac() and arch() == "aarch64": "arm64" else: arch()
    var out = f"{system} {machine}"
    var argv: Vec[str] = Vec.new()
    for a in "sysctl -n machdep.cpu.brand_string".split(" "): argv.push(a.clone())
    let path = scratch ++ "/cpu.stdout"
    let finished = run_to_files(&argv, path, "/dev/null", 60000)
    let cpu = (read_file(path) ?? "").trim()
    if finished.code == 0 and cpu.len() > 0: out = out ++ ", " ++ cpu
    out

// ── Text ─────────────────────────────────────────────────────────────

/// Whitespace-separated words (Python's `str.split()`).
fn words(line: &str) -> Vec[str]:
    var out: Vec[str] = Vec.new()
    var start: i64 = -1
    for i in 0..line.len() + 1:
        let space = i == line.len() or line[i] == ' ' or line[i] == '\t' or line[i] == '\r'
        if space and start >= 0:
            out.push(line.slice(start, i))
            start = -1
        else if not space and start < 0: start = i
    out

/// A decimal like `1582.519` or `-3e2`, or None.
fn parse_decimal(text: &str) -> Option[f64]:
    var i = 0
    var negative = false
    if i < text.len() and (text[i] == '-' or text[i] == '+'):
        negative = text[i] == '-'
        i += 1
    var value = 0.0
    var digits = 0
    while i < text.len() and text[i] >= '0' and text[i] <= '9':
        value = value * 10.0 + (text[i] - '0') as f64
        digits += 1
        i += 1
    if i < text.len() and text[i] == '.':
        i += 1
        var scale = 1.0
        while i < text.len() and text[i] >= '0' and text[i] <= '9':
            scale = scale / 10.0
            value = value + (text[i] - '0') as f64 * scale
            digits += 1
            i += 1
    if digits == 0: return None
    if i < text.len() and (text[i] == 'e' or text[i] == 'E'):
        i += 1
        var exp_negative = false
        if i < text.len() and (text[i] == '-' or text[i] == '+'):
            exp_negative = text[i] == '-'
            i += 1
        var exponent = 0
        var exp_digits = 0
        while i < text.len() and text[i] >= '0' and text[i] <= '9':
            exponent = exponent * 10 + (text[i] - '0') as i32
            exp_digits += 1
            i += 1
        if exp_digits == 0: return None
        for _ in 0..exponent: value = if exp_negative: value / 10.0 else: value * 10.0
    if i != text.len(): return None
    Some(if negative: 0.0 - value else: value)

/// The last `n` bytes of a text.
fn tail(text: &str, n: i64) -> str: if text.len() <= n: text.clone() else: text.slice(text.len() - n, text.len())

fn head(text: &str, n: i64) -> str: if text.len() <= n: text.clone() else: text.slice(0, n)

/// Python's repr of a list of strings: `['a', 'b']`.
fn py_list(items: &Vec[str]) -> str:
    var out = "["
    for i in 0..items.len():
        if i > 0: out = out ++ ", "
        out = out ++ "'" ++ items[i] ++ "'"
    out ++ "]"

/// The distinct strings, sorted.
fn sorted_set(items: &Vec[str]) -> Vec[str]:
    var distinct: Vec[str] = Vec.new()
    for item in items:
        if not distinct.contains(item): distinct.push(item.clone())
    // Selection by repeated minimum: the lists are a handful long, and Vec
    // has no sort yet (#960).
    var out: Vec[str] = Vec.new()
    while out.len() < distinct.len():
        var least: i64 = -1
        for i in 0..distinct.len():
            if out.contains(&distinct[i]): continue
            if least < 0 or distinct[i] < distinct[least]: least = i
        out.push(distinct[least].clone())
    out

/// The k-th smallest value (0-based).
fn kth(values: &Vec[f64], k: i64) -> f64:
    for v in values:
        var less: i64 = 0
        var equal: i64 = 0
        for w in values:
            if w < v: less += 1
            else if w == v: equal += 1
        if less <= k and k < less + equal: return v
    0.0

/// The median (Python's `statistics.median`: the mean of the middle two of
/// an even count).
fn median(values: &Vec[f64]) -> f64:
    let n = values.len()
    if n % 2 == 1: kth(values, n / 2) else: (kth(values, n / 2 - 1) + kth(values, n / 2)) / 2.0

/// Seconds (measured in nanoseconds) with no trailing zeros: exact at the
/// clock's resolution, without binary-float noise.
fn exact(value: f64) -> str:
    var text = f"{value:.9f}"
    while text.ends_with("0") and not text.ends_with(".0"): text = text.slice(0, text.len() - 1)
    text

fn seconds(ns: i64): ns as f64 / 1000000000.0

// ── Measurement ──────────────────────────────────────────────────────

type Cell {
    workload: str,
    language: str,
    level: str,
    compile_s: Option[f64],
    size_bytes: Option[i64],
    run_s: Option[f64],
    inner_s: Option[f64],
    rss_bytes: Option[i64],
    checksum: Option[str],
    /// ok | compile-failed | run-failed | timeout | skipped
    status: str,
    detail: str,
}

fn new_cell(workload: &str, language: &str, level: &str) -> Cell:
    Cell {
        workload: workload.clone(), language: language.clone(), level: level.clone(),
        compile_s: None, size_bytes: None, run_s: None, inner_s: None, rss_bytes: None, checksum: None,
        status: "ok", detail: "",
    }

fn basename(path: &str) -> str:
    let parts = path.split("/")
    parts[parts.len() - 1].clone()

fn stem(path: &str) -> str:
    let name = basename(path)
    let parts = name.split(".")
    if parts.len() < 2: return name
    name.slice(0, name.len() - parts[parts.len() - 1].len() - 1)

/// Copy the source with a unique trailing comment so no build cache can
/// return a previous compilation of this exact program.
fn with_unique_comment(source: &str, work: &str) -> str:
    let _ = mkdir_p(work)
    let copied = work ++ "/" ++ basename(source)
    let text = read_file(source) ?? ""
    assert(write_file(copied, f"{text}\n// bench-{now_ns()}\n") == 0)
    copied

type Compiled {
    binary: str,
    elapsed_s: f64,
    message: str,
}

fn compile_once(key: &str, level: &str, source: &str, work: &str) -> Compiled:
    let output = work ++ "/" ++ stem(source) ++ "-" ++ level
    if file_exists(output): let _ = remove_file(output)
    let argv = compile_command(key, level, source, output)
    let started = now_ns()
    let finished = run_to_files_in(work, &argv, work ++ ".compile.stdout", work ++ ".compile.stderr")
    let elapsed = seconds(now_ns() - started)
    if finished.code != 0 or not file_exists(output):
        let stderr = (read_file(work ++ ".compile.stderr") ?? "").trim()
        let message = if stderr.len() > 0: stderr else: (read_file(work ++ ".compile.stdout") ?? "").trim()
        return Compiled { binary: "", elapsed_s: elapsed, message }
    Compiled { binary: output, elapsed_s: elapsed, message: "" }

fn strip_binary(path: &str) -> i64:
    let stripped = path ++ ".stripped"
    assert(copy_tree(path, stripped) == 0)
    var argv: Vec[str] = Vec.new()
    argv.push("strip")
    argv.push(stripped.clone())
    let _ = run_to_files(&argv, "/dev/null", "/dev/null", 0)
    (read_file(stripped) ?? "").len()

type RunResult {
    /// "" when the run finished and exited 0; else the timeout or failure.
    failure: str,
    wall: f64,
    inner: Option[f64],
    checksum: Option[str],
    rss: Option[i64],
    output: str,
}

/// Run the program once with its output captured; the runtime reaps it and
/// reports its peak RSS, as `/usr/bin/time -l` read it from the same wait.
fn run_once(binary: &str, timeout_ms: i32) -> RunResult:
    var argv: Vec[str] = Vec.new()
    argv.push(binary.clone())
    let out = binary ++ ".stdout"
    let err = binary ++ ".stderr"
    let started = now_ns()
    let finished = run_to_files(&argv, out, err, timeout_ms)
    let elapsed = seconds(now_ns() - started)
    let stdout = read_file(out) ?? ""
    let stderr = read_file(err) ?? ""
    var result = RunResult { failure: "", wall: elapsed, inner: None, checksum: None, rss: None, output: stdout ++ stderr }
    if finished.timed_out:
        result.failure = "timeout"
        return result
    if finished.code != 0:
        let text = if stderr.trim().len() > 0: stderr.trim() else: stdout.trim()
        let detail = if text.len() > 0: tail(text, 400) else: f"exit code {finished.code}"
        result.failure = detail
        return result
    if finished.peak_rss > 0: result.rss = Some(finished.peak_rss)
    for line in stdout.split("\n"):
        let parts = words(line)
        if parts.len() == 2 and parts[0] == "elapsed_ms":
            if let Some(ms) = parse_decimal(parts[1]): result.inner = Some(ms / 1000.0)
        else if parts.len() == 2 and parts[0] == "checksum":
            result.checksum = Some(parts[1].clone())
    result

fn measure(root: &str, workload: &str, key: &str, level: &str, runs: i32, timeout_ms: i32, work_root: &str) -> Cell:
    let source = f"{root}/workloads/{workload}/{workload}.{extension(key)}"
    var cell = new_cell(workload, language_name(key), level)
    if not file_exists(source):
        cell.status = "skipped"
        cell.detail = "no source"
        return cell
    let work = f"{work_root}/{workload}-{key}-{level}"
    let _ = mkdir_p(work)
    let _ = set_env("CARGO_INCREMENTAL", "0")
    let _ = set_env("ZIG_LOCAL_CACHE_DIR", work ++ "/zig-cache")

    // Warm the toolchain (std library caches, first-run setup) on a
    // throwaway copy, then time a genuinely uncached build of the program.
    let warm = with_unique_comment(source, work ++ "/warm")
    let _ = compile_once(key, level, warm, work ++ "/warm")
    let timed = with_unique_comment(source, work ++ "/timed")
    let compiled = compile_once(key, level, timed, work ++ "/timed")
    cell.compile_s = Some(compiled.elapsed_s)
    if compiled.binary.len() == 0:
        cell.status = "compile-failed"
        cell.detail = tail(compiled.message, 400)
        return cell
    cell.size_bytes = Some(strip_binary(compiled.binary))

    var walls: Vec[f64] = Vec.new()
    var inners: Vec[f64] = Vec.new()
    var rsses: Vec[i64] = Vec.new()
    var checksums: Vec[str] = Vec.new()
    for _ in 0..runs:
        let result = run_once(compiled.binary, timeout_ms)
        if result.failure == "timeout":
            cell.status = "timeout"
            cell.detail = "exceeded " ++ exact(timeout_ms as f64 / 1000.0) ++ "s"
            return cell
        if result.failure.len() > 0:
            cell.status = "run-failed"
            cell.detail = result.failure.clone()
            return cell
        walls.push(result.wall)
        if let Some(v) = result.inner: inners.push(v)
        if let Some(v) = result.rss: rsses.push(v)
        if let Some(v) = &result.checksum: checksums.push(v.clone())
        if workload == "hello" and not result.output.contains("Hello, World!"):
            cell.status = "run-failed"
            cell.detail = "wrong output"
            return cell
    cell.run_s = Some(median(&walls))
    if inners.len() > 0: cell.inner_s = Some(median(&inners))
    if rsses.len() > 0:
        var most: i64 = rsses[0]
        for v in rsses: if v > most: most = v
        cell.rss_bytes = Some(most)
    if checksums.len() > 0: cell.checksum = Some(checksums[0].clone())
    else if workload == "hello": cell.checksum = Some("Hello, World!")
    let distinct = sorted_set(&checksums)
    if distinct.len() > 1:
        cell.status = "run-failed"
        cell.detail = "nondeterministic checksum " ++ py_list(&distinct)
    cell

// ── Reporting ────────────────────────────────────────────────────────

fn fmt_seconds(value: &Option[f64]) -> str:
    if let Some(v) = value: f"{v:.3f}s" else: "-"

fn fmt_bytes(value: &Option[i64]) -> str:
    if let Some(v) = value:
        if *v >= 1048576: return f"{*v as f64 / 1048576.0:.1f} MB"
        return f"{*v as f64 / 1024.0:.0f} KB"
    "-"

fn fmt_ratio(value: &Option[f64], best: &Option[f64]) -> str:
    if let Some(v) = value:
        if let Some(b) = best:
            if *b != 0.0: return f" ({*v / *b:.2f}x)"
    ""

fn workload_description(root: &str, workload: &str) -> str:
    let source = f"{root}/workloads/{workload}/{workload}.w"
    if not file_exists(source): return ""
    var lines: Vec[str] = Vec.new()
    for line in (read_file(source) ?? "").split("\n"):
        if line.starts_with("// ") and lines.len() < 2: lines.push(line.slice(3, line.len()))
    var out = ""
    for i in 0..lines.len():
        if i > 0: out = out ++ " "
        out = out ++ lines[i]
    out

fn is_release(c: &Cell): c.status == "ok" and (c.level == "O3" or c.level == "release" or c.level == "ReleaseFast")

/// The smallest nonzero value, or None.
fn best_of(values: &Vec[f64]) -> Option[f64]:
    var best: Option[f64] = None
    for v in values:
        if *v == 0.0: continue
        if best.is_none() or *v < best.unwrap(): best = Some(*v)
    best

type Options {
    workloads: Vec[str],
    languages: Vec[str],
    runs: i32,
    full: bool,
    timeout_ms: i32,
    output: str,
    keep: bool,
}

fn markdown_report(root: &str, cells: &Vec[Cell], toolchains: &Vec[str], versions: &Vec[str], options: &Options, host_line: &str) -> str:
    var out: Vec[str] = Vec.new()
    out.push("# Benchmark results\n")
    out.push(f"Host: {host_line}  ")
    out.push(f"Runs per cell: {options.runs} (median for times, max for memory)  ")
    let levels_text = if options.full: "every level" else: "debug and release"
    out.push(f"Levels: {levels_text}\n")
    out.push("## Toolchains\n")
    for i in 0..toolchains.len(): out.push(f"- {toolchains[i]}: {versions[i]}")
    out.push("")
    var workloads: Vec[str] = Vec.new()
    for c in cells:
        if not workloads.contains(&c.workload): workloads.push(c.workload.clone())
    for workload in workloads:
        out.push(f"## {workload}\n")
        let description = workload_description(root, workload)
        if description.len() > 0: out.push(description ++ "\n")
        var release_runs: Vec[f64] = Vec.new()
        var release_inners: Vec[f64] = Vec.new()
        var compiles: Vec[f64] = Vec.new()
        for c in cells:
            if c.workload != *workload: continue
            if is_release(c):
                if let Some(v) = c.run_s: release_runs.push(v)
                if let Some(v) = c.inner_s: release_inners.push(v)
            if c.status == "ok":
                if let Some(v) = c.compile_s: compiles.push(v)
        let best_run = best_of(&release_runs)
        let best_inner = best_of(&release_inners)
        let best_compile = best_of(&compiles)
        if workload == "hello":
            out.push("| Language | Level | Compile | Size | Output |")
            out.push("|---|---|---:|---:|---|")
            for c in cells:
                if c.workload != *workload: continue
                if c.status != "ok":
                    out.push(f"| {c.language} | {c.level} | {c.status} | | {head(c.detail, 60)} |")
                    continue
                out.push(f"| {c.language} | {c.level} | {fmt_seconds(&c.compile_s)}{fmt_ratio(&c.compile_s, &best_compile)} | {fmt_bytes(&c.size_bytes)} | ok |")
        else:
            out.push("| Language | Level | Compile | Size | Run (wall) | Hot loop | Peak RSS | Checksum |")
            out.push("|---|---|---:|---:|---:|---:|---:|---|")
            var checksums: Vec[str] = Vec.new()
            for c in cells:
                if c.workload != *workload: continue
                if c.status != "ok":
                    out.push(f"| {c.language} | {c.level} | {c.status} | | | | | {head(c.detail, 60)} |")
                    continue
                let ratio_run = if is_release(c): fmt_ratio(&c.run_s, &best_run) else: ""
                let ratio_inner = if is_release(c): fmt_ratio(&c.inner_s, &best_inner) else: ""
                let checksum = if let Some(v) = &c.checksum: v.clone() else: "-"
                if let Some(v) = &c.checksum: checksums.push(v.clone())
                out.push(f"| {c.language} | {c.level} | {fmt_seconds(&c.compile_s)}{fmt_ratio(&c.compile_s, &best_compile)} | {fmt_bytes(&c.size_bytes)} | {fmt_seconds(&c.run_s)}{ratio_run} | {fmt_seconds(&c.inner_s)}{ratio_inner} | {fmt_bytes(&c.rss_bytes)} | {checksum} |")
            let distinct = sorted_set(&checksums)
            if distinct.len() > 1:
                out.push(f"\n**Checksums disagree** across implementations: {py_list(&distinct)}. Treat the timings as comparable only once every language computes the same result.")
        out.push("")
    out.push("Ratios are relative to the best release-level cell in the same column. Compile time is a cold build of the program with the toolchain's caches already warm. Hot loop is the program's own timer around its core work; Run is the whole process.")
    var text = ""
    for i in 0..out.len():
        if i > 0: text = text ++ "\n"
        text = text ++ out[i]
    text ++ "\n"

fn opt_f64(value: &Option[f64]) -> str: if let Some(v) = value: exact(*v) else: ""

fn opt_i64(value: &Option[i64]) -> str: if let Some(v) = value: f"{*v}" else: ""

/// One CSV field (RFC 4180): quoted when it holds a comma, quote or newline.
fn csv_field(value: &str) -> str:
    if value.contains(",") or value.contains("\"") or value.contains("\n"): return "\"" ++ value.replace("\"", "\"\"") ++ "\""
    value.clone()

fn csv_report(cells: &Vec[Cell]) -> str:
    var text = "workload,language,level,status,compile_s,size_bytes,run_s,inner_s,rss_bytes,checksum\n"
    for c in cells:
        let checksum = if let Some(v) = &c.checksum: v.clone() else: ""
        var fields: Vec[str] = Vec.new()
        fields.push(c.workload.clone())
        fields.push(c.language.clone())
        fields.push(c.level.clone())
        fields.push(c.status.clone())
        fields.push(opt_f64(&c.compile_s))
        fields.push(opt_i64(&c.size_bytes))
        fields.push(opt_f64(&c.run_s))
        fields.push(opt_f64(&c.inner_s))
        fields.push(opt_i64(&c.rss_bytes))
        fields.push(checksum)
        for i in 0..fields.len():
            if i > 0: text = text ++ ","
            text = text ++ csv_field(fields[i])
        text = text ++ "\n"
    text

fn json_f64(value: &Option[f64]) -> str: if let Some(v) = value: exact(*v) else: "null"

fn json_i64(value: &Option[i64]) -> str: if let Some(v) = value: f"{*v}" else: "null"

fn json_report(cells: &Vec[Cell], toolchains: &Vec[str], versions: &Vec[str]) -> str:
    var text = "{\n  \"toolchains\": {"
    for i in 0..toolchains.len():
        text = text ++ (if i > 0: "," else: "") ++ "\n    " ++ json_quote(toolchains[i]) ++ ": " ++ json_quote(versions[i])
    text = text ++ (if toolchains.len() > 0: "\n  }" else: "}") ++ ",\n  \"cells\": ["
    for i in 0..cells.len():
        let c = &cells[i]
        let checksum = if let Some(v) = &c.checksum: json_quote(v) else: "null"
        text = text ++ (if i > 0: "," else: "") ++ "\n    {"
        text = text ++ "\n      \"workload\": " ++ json_quote(c.workload) ++ ","
        text = text ++ "\n      \"language\": " ++ json_quote(c.language) ++ ","
        text = text ++ "\n      \"level\": " ++ json_quote(c.level) ++ ","
        text = text ++ "\n      \"compile_s\": " ++ json_f64(&c.compile_s) ++ ","
        text = text ++ "\n      \"size_bytes\": " ++ json_i64(&c.size_bytes) ++ ","
        text = text ++ "\n      \"run_s\": " ++ json_f64(&c.run_s) ++ ","
        text = text ++ "\n      \"inner_s\": " ++ json_f64(&c.inner_s) ++ ","
        text = text ++ "\n      \"rss_bytes\": " ++ json_i64(&c.rss_bytes) ++ ","
        text = text ++ "\n      \"checksum\": " ++ checksum ++ ","
        text = text ++ "\n      \"status\": " ++ json_quote(c.status) ++ ","
        text = text ++ "\n      \"detail\": " ++ json_quote(c.detail)
        text = text ++ "\n    }"
    text ++ (if cells.len() > 0: "\n  ]" else: "]") ++ "\n}"

/// The path with its last suffix replaced (Python's `Path.with_suffix`).
fn with_suffix(path: &str, suffix: &str) -> str:
    let name = basename(path)
    let dir = path.slice(0, path.len() - name.len())
    let parts = name.split(".")
    if parts.len() < 2 or name.starts_with(".") and parts.len() == 2: return path ++ suffix
    dir ++ name.slice(0, name.len() - parts[parts.len() - 1].len() - 1) ++ suffix

// ── Main ─────────────────────────────────────────────────────────────

fn usage() -> str:
    "usage: with run benchmarks/run.w [-h] [-w WORKLOAD] [-l {c,go,rust,with,zig}] [-n RUNS] [--full] [--timeout TIMEOUT] [-o OUTPUT] [--keep]\n\n" ++
    "Cross-language benchmark runner: With against Rust, C, Go, and Zig.\n\n" ++
    "options:\n" ++
    "  -h, --help            show this help message and exit\n" ++
    "  -w, --workload WORKLOAD\n                        workload to run (repeatable)\n" ++
    "  -l, --language {c,go,rust,with,zig}\n                        language to run (repeatable)\n" ++
    "  -n, --runs RUNS       timed runs per cell (default 3)\n" ++
    "  --full                every optimization level, not just debug and release\n" ++
    "  --timeout TIMEOUT     seconds allowed per run (default 120)\n" ++
    "  -o, --output OUTPUT   basename for results.md/.csv/.json (default: print markdown only)\n" ++
    "  --keep                keep the temporary build directory\n\n" ++
    "Missing toolchains are skipped, not fatal."

fn usage_error(message: &str) -> Never:
    eprint(f"usage: with run benchmarks/run.w [-h] [-w WORKLOAD] [-l {{c,go,rust,with,zig}}] [-n RUNS] [--full] [--timeout TIMEOUT] [-o OUTPUT] [--keep]\nrun.w: error: {message}")
    exit_code(2)

fn parse_options() -> Options:
    let argv = args()
    var options = Options { workloads: Vec.new(), languages: Vec.new(), runs: 3, full: false, timeout_ms: 120000, output: "", keep: false }
    var i = 1
    while i < argv.len():
        var flag = argv[i].clone()
        var value = ""
        var has_value = false
        if flag.starts_with("--") and flag.contains("="):
            let eq = flag.split("=")[0].len()
            value = flag.slice(eq + 1, flag.len())
            flag = flag.slice(0, eq)
            has_value = true
        i += 1
        if flag == "-h" or flag == "--help":
            print(usage())
            exit_code(0)
        if flag == "--full":
            options.full = true
            continue
        if flag == "--keep":
            options.keep = true
            continue
        let takes = flag == "-w" or flag == "--workload" or flag == "-l" or flag == "--language" or flag == "-n" or flag == "--runs" or flag == "--timeout" or flag == "-o" or flag == "--output"
        if not takes: usage_error(f"unrecognized arguments: {flag}")
        if not has_value:
            if i >= argv.len(): usage_error(f"argument {flag}: expected one argument")
            value = argv[i].clone()
            i += 1
        if flag == "-w" or flag == "--workload": options.workloads.push(value)
        else if flag == "-l" or flag == "--language":
            if not language_keys().contains(&value): usage_error(f"argument -l/--language: invalid choice: '{value}' (choose from 'c', 'go', 'rust', 'with', 'zig')")
            options.languages.push(value)
        else if flag == "-n" or flag == "--runs":
            let n = parse_decimal(value)
            if n.is_none() or value.contains(".") or n.unwrap() < 1.0: usage_error(f"argument -n/--runs: invalid int value: '{value}'")
            options.runs = n.unwrap() as i32
        else if flag == "--timeout":
            let t = parse_decimal(value)
            if t.is_none() or t.unwrap() <= 0.0: usage_error(f"argument --timeout: invalid float value: '{value}'")
            options.timeout_ms = (t.unwrap() * 1000.0) as i32
        else: options.output = value
    options

let root = here()
var options = parse_options()

var all_workloads: Vec[str] = Vec.new()
for path in list_files_text(root ++ "/workloads").split("\n"):
    // workloads/<name>/<file>: the directory names, sorted.
    let parts = path.split("/")
    if parts.len() < 3: continue
    let name = parts[parts.len() - 2].clone()
    if not all_workloads.contains(&name): all_workloads.push(name)
all_workloads = sorted_set(&all_workloads)
if options.workloads.len() == 0: options.workloads = sorted_set(&all_workloads)
for w in options.workloads:
    if not all_workloads.contains(w):
        var available = ""
        for i in 0..all_workloads.len(): available = available ++ (if i > 0: ", " else: "") ++ all_workloads[i]
        eprint(f"unknown workload '{w}'; available: {available}")
        exit_code(1)
if options.languages.len() == 0: options.languages = language_keys()

let tmp_base = if env("TMPDIR").len() > 0: env("TMPDIR") else: "/tmp"
let work_root = (if tmp_base.ends_with("/"): tmp_base else: tmp_base ++ "/") ++ f"with-bench-{pid()}-{now_ns()}"
assert(mkdir_p(work_root) == 0)

var toolchains: Vec[str] = Vec.new()
var versions: Vec[str] = Vec.new()
var active: Vec[str] = Vec.new()
for key in options.languages:
    if available(key):
        toolchains.push(language_name(key))
        versions.push(version(key, work_root))
        active.push(key.clone())
    else:
        eprint(f"skipping {language_name(key)}: '{compiler(key)}' not found on PATH")
if active.len() == 0:
    eprint("no toolchains available")
    let _ = remove_tree(work_root)
    exit_code(1)

var cells: Vec[Cell] = Vec.new()
var total = 0
for key in active: total += if options.full: levels(key).len() as i32 else: 2
total = total * options.workloads.len() as i32
var done = 0
for workload in options.workloads:
    for key in active:
        let cell_levels = if options.full: levels(key) else: default_levels(key)
        for level in cell_levels:
            done += 1
            ewrite(f"[{done}/{total}] {workload} {language_name(key)} {level} ... ")
            let runs = if *workload == "hello": 1 else: options.runs
            let cell = measure(root, workload, key, level, runs, options.timeout_ms, work_root)
            if cell.status == "ok": eprint(f"compile {fmt_seconds(&cell.compile_s)}, run {fmt_seconds(&cell.run_s)}")
            else: eprint(f"{cell.status}: {head(cell.detail, 80)}")
            cells.push(cell)

let report = markdown_report(root, &cells, &toolchains, &versions, &options, host(work_root))
if options.output.len() > 0:
    let md = with_suffix(options.output, ".md")
    let csv = with_suffix(options.output, ".csv")
    let json = with_suffix(options.output, ".json")
    assert(write_file(md, report) == 0)
    assert(write_file(csv, csv_report(&cells)) == 0)
    assert(write_file(json, json_report(&cells, &toolchains, &versions)) == 0)
    eprint(f"wrote {md}, {csv}, {json}")
print(report)
if options.keep: eprint(f"build directory kept: {work_root}")
else: let _ = remove_tree(work_root)
