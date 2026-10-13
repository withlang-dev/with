// Run from repository root: with run -O1 benchmarks/goose/run.w smoke all 3
// Size: smoke/small/medium/large. Selector: all or comma-separated names.
// Requires the pinned .reference/goose checkout. GOOSE_EXE enables Goose rows.
use std.fs
use std.process
use std.time
use std.string.StringBuilder
use std.string.string_to_int

const ROOT: str = "benchmarks/goose"
const REF: str = ".reference/goose/bench"
const OUT: str = "out/benchmarks/goose"

fn load(path: &str) -> str: read_file(path).unwrap()

fn save(path: &str, text: &str):
    if write_file(path, text) != 0: panic(f"cannot write {path}")

fn sized(source: &str, n: i64, language: &str) -> str:
    var out = StringBuilder.new()
    var markers: i32 = 0
    for line in source.split("\n"):
        if line.contains("// BENCH_N"):
            markers += 1
            let pieces = line.split("=")
            let prefix = pieces[0]
            out.push_str(prefix)
            out.push_str(f"= {n}")
            if language != "with": out.push_byte(59)
            out.push_str(" // BENCH_N")
        else: out.push_str(line)
        out.push_byte(10)
    if markers != 1: panic(f"expected one BENCH_N marker, found {markers}")
    out.to_str()

fn compile(argv: &Vec[str], tag: &str) -> bool:
    let result = run_to_files(argv, OUT ++ "/" ++ tag ++ ".build.out", OUT ++ "/" ++ tag ++ ".build.err", 120000)
    result.code == 0 and not result.timed_out

fn identity(argv: Vec[str], tag: &str) -> str:
    let output = OUT ++ "/" ++ tag ++ ".identity"
    let result = run_to_files(argv, output, OUT ++ "/" ++ tag ++ ".identity.err", 10000)
    if result.code != 0: return "unavailable"
    load(output).trim().clone()

type Measurement { ok: bool, ns: i64, rss: i64, output: str, reason: str }

fn measure(exe: &str, tag: &str, reps: i32) -> Measurement:
    var argv: Vec[str] = Vec.new()
    argv.push(exe.clone())
    let stdout = OUT ++ "/" ++ tag ++ ".stdout"
    let stderr = OUT ++ "/" ++ tag ++ ".stderr"
    var expected = ""
    var best: i64 = 9223372036854775807
    var peak: i64 = 0
    for pass in 0..reps + 2:
        let start = now_ns()
        let result = run_to_files(argv, stdout, stderr, 600000)
        let elapsed = now_ns() - start
        if result.code != 0 or result.timed_out:
            return Measurement { ok: false, ns: 0, rss: 0, output: "", reason: f"run failed: exit={result.code}, timeout={result.timed_out}; see {stderr}" }
        let output = load(stdout)
        if pass == 0: expected = output
        else if output != expected:
            return Measurement { ok: false, ns: 0, rss: 0, output: output, reason: "stdout varies across repetitions" }
        if pass >= 2:
            if elapsed < best: best = elapsed
            if result.peak_rss > peak: peak = result.peak_rss
    Measurement { ok: true, ns: best, rss: peak, output: expected, reason: "" }

type Report { rows: StringBuilder, failures: i32, pending: i32, expected: str, reference: str }

impl Report:
    mut fn failed(bench: &str, label: &str, reason: &str):
        print(f"FAIL {bench} {label}: {reason}")
        self.rows.push_str(f"| {bench} | {label} | FAIL | | | {reason} |\n")
        self.failures += 1

    mut fn pending_row(bench: &str, label: &str, reason: &str):
        self.rows.push_str(f"| {bench} | {label} | PENDING | | | {reason} |\n")
        self.pending += 1

    mut fn run(bench: &str, label: &str, tag: &str, argv: Vec[str], reps: i32):
        let exe = OUT ++ "/" ++ tag
        if not compile(argv, tag):
            self.failed(bench, label, f"compile failed; see {tag}.build.err")
            return
        let result = measure(exe, tag, reps)
        if not result.ok:
            self.failed(bench, label, result.reason)
            return
        if self.reference.len() == 0:
            self.expected = result.output.clone()
            self.reference = label.clone()
        else if result.output != self.expected:
            self.failed(bench, label, f"stdout differs from {self.reference}; see {tag}.stdout")
            return
        print(f"OK {bench} {label}: {result.ns} ns, {result.rss} bytes RSS")
        self.rows.push_str(f"| {bench} | {label} | MATCH | {result.ns} | {result.rss} | |\n")

fn main:
    let cli = args()
    let size = if cli.len() > 1: cli[1].clone() else: "smoke"
    let only = if cli.len() > 2: cli[2].clone() else: "all"
    let reps = if cli.len() > 3: string_to_int(cli[3]) as i32 else: 3
    if reps < 1: panic("repetitions must be positive")
    let column = if size == "smoke": 1 else if size == "small": 2 else if size == "medium": 3 else if size == "large": 4 else: 0
    if column == 0: panic("size must be smoke, small, medium or large")
    if mkdir_p(OUT) != 0: panic("cannot create output directory")
    save(OUT ++ "/common.w", load(ROOT ++ "/common.w"))
    save(OUT ++ "/bench.rs", load(REF ++ "/rust/bench.rs"))
    save(OUT ++ "/rng.goose", load(REF ++ "/goose/rng.goose"))
    let goose = env("GOOSE_EXE")
    let requested_compiler = env("WITH")
    let compiler = if requested_compiler.len() > 0: requested_compiler.clone() else: identity(["which", "with"], "with-path")
    if compiler == "unavailable": panic("With compiler unavailable")
    var metadata = StringBuilder.new()
    metadata.push_str("\n```text\n")
    metadata.push_str(identity(["uname", "-sm"], "host"))
    metadata.push_str("\nWorkspace revision: " ++ identity(["git", "rev-parse", "HEAD"], "revision"))
    metadata.push_str("\nGoose revision: " ++ identity(["git", "-C", ".reference/goose", "rev-parse", "HEAD"], "goose-revision"))
    metadata.push_str("\nWith compiler executable: " ++ compiler)
    metadata.push_str("\n" ++ identity([compiler.clone(), "version"], "with"))
    metadata.push_str("\nWith compiler SHA-256: " ++ identity(["shasum", "-a", "256", compiler.clone()], "with-sha256"))
    metadata.push_str("\n" ++ identity(["clang++", "--version"], "clang"))
    metadata.push_str("\n" ++ identity(["rustc", "--version"], "rust"))
    metadata.push_str("\nGoose executable: " ++ goose ++ "\n```\n")
    var report = Report { rows: StringBuilder.new(), failures: 0, pending: 0, expected: "", reference: "" }
    var selected: i32 = 0
    for line in load(ROOT ++ "/suite.manifest").split("\n"):
        if line.len() == 0 or line.starts_with("#"): continue
        let fields = line.split("|")
        let name = fields[0]
        if only != "all" and not ("," ++ only ++ ",").contains("," ++ name ++ ","): continue
        selected += 1
        let n = string_to_int(fields[column])
        report.expected = ""
        report.reference = ""
        print(f"{name}: {size}={n}")
        // C++ first provides an independently implemented reference checksum.
        for variant in fields[5].split(","):
            let parts = variant.split(":")
            let tag = name ++ "_" ++ size ++ "_cpp" ++ parts[0]
            let label = "C++ " ++ parts[1] ++ " variant=" ++ parts[0]
            var argv: Vec[str] = ["clang++", "-std=c++20", "-O2", "-DBENCH_N=" ++ f"{n}", "-DVARIANT=" ++ parts[0], REF ++ "/cpp/" ++ name ++ ".cpp", "-o", OUT ++ "/" ++ tag]
            report.run(name, label, tag, argv, reps)
        for file in fields[6].split(","):
            let tag = name ++ "_" ++ size ++ "_rust_" ++ file
            let path = OUT ++ "/" ++ tag ++ ".rs"
            save(path, sized(load(REF ++ "/rust/" ++ file ++ ".rs"), n, "rust"))
            var argv: Vec[str] = ["rustc", "-O", "-C", "codegen-units=1", path, "-o", OUT ++ "/" ++ tag]
            report.run(name, "Rust " ++ file, tag, argv, reps)
        let tag = name ++ "_" ++ size ++ "_with"
        let path = OUT ++ "/" ++ tag ++ ".w"
        save(path, sized(load(ROOT ++ "/" ++ name ++ ".w"), n, "with"))
        var argv: Vec[str] = [compiler.clone(), "build", "-O1", path, "-o", OUT ++ "/" ++ tag]
        report.run(name, "With", tag, argv, reps)
        for file in fields[7].split(","):
            if goose.len() == 0:
                report.pending_row(name, "Goose " ++ file, "GOOSE_EXE unset")
                continue
            let gtag = name ++ "_" ++ size ++ "_goose_" ++ file
            let gpath = OUT ++ "/" ++ gtag ++ ".goose"
            let cpath = OUT ++ "/" ++ gtag ++ ".c"
            save(gpath, sized(load(REF ++ "/goose/" ++ file ++ ".goose"), n, "goose"))
            var generate: Vec[str] = [goose.clone(), "-O2", "--standalone", "--stdlib", ".reference/goose/stdlib", "-o", cpath.clone(), gpath]
            if not compile(generate, gtag ++ "_generate"):
                report.failed(name, "Goose " ++ file, "C generation failed")
                continue
            var cc: Vec[str] = ["clang", "-O2", "-DGS_STACK_RESERVE=2147483648ull", cpath, "-o", OUT ++ "/" ++ gtag]
            report.run(name, "Goose " ++ file, gtag, cc, reps)
    if selected == 0: panic("selector matched no benchmarks")
    var text = StringBuilder.new()
    text.push_str(f"# Goose benchmark port: {size}\n\n{selected} workloads; {reps} measured runs after two warmups. Whole-process best wall time and worst measured peak RSS, including input generation and destruction. With -O1; C++/Goose C -O2; Rust -O with one codegen unit. Raw times include process startup. MATCH means complete stdout equals the first successful C++/Rust reference, not equivalent storage semantics.\n\n")
    text.push_str(metadata.to_str())
    text.push_str("| workload | implementation | status | best ns | peak RSS bytes | note |\n|---|---|---|---:|---:|---|\n")
    text.push_str(report.rows.to_str())
    text.push_str(f"\nFailures: {report.failures}. Pending Goose rows: {report.pending}. No ratios are reported; inspect representation notes before comparing timings.\n")
    save(OUT ++ "/results-" ++ size ++ ".md", text.to_str())
    print(f"Failures: {report.failures}; pending: {report.pending}")
    if report.failures > 0: exit_code(1)
    if report.pending > 0: exit_code(2)
