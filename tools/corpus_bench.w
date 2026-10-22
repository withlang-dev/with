// D119 step 3: each migrated corpus against its C, before and after the
// migrator's List rule (with-migrate-spec.md "Arrays"). For every corpus
// this builds upstream's harness program three ways — from the C reference
// tree with the host clang at -O2, from the promoted modules (`before`,
// lib/std/<corpus>) and from a fresh migration (`after`, out/<name>_migrated)
// with the With compiler, as the corpus test lanes build it — and times the
// same workload on each, the median of N runs.
//
//   with run tools/corpus_bench.w                       every corpus, 5 runs
//   with run tools/corpus_bench.w --corpus zlib -n 9    one corpus, 9 runs
//   with run tools/corpus_bench.w --after none          the promoted tree only
//   with run tools/corpus_bench.w --with out/release/bin/with
//
// The reference trees come from the corpus pipeline (`with build
// :<stem>-prepare-reference`, or any migrate target); the `after` tree from
// `with build :<stem>-migrate`. Workloads: zlib compresses and decompresses
// a 32 MiB text with minigzip; pcre2 runs pcre2test over testinput1 and
// testinput4; tommyds runs upstream's check; c-algorithms runs its test
// programs. Results print as a table and land in out/corpus_bench/results.md.
use std.fs
use std.process
use std.time

fn arg_value(argv: &List[str], flag: &str, default: &str) -> str:
    for i in 0..argv.len():
        if argv[i] == flag and i + 1 < argv.len(): return argv[i + 1]
    default

fn arg_values(argv: &List[str], flag: &str) -> List[str]:
    var out: List[str] = List.new()
    for i in 0..argv.len():
        if argv[i] == flag and i + 1 < argv.len(): out.push(argv[i + 1])
    out

fn seconds(ns: i64): ns as f64 / 1000000000.0

/// A decimal count from the command line; anything else is the default.
fn parse_count(text: &str, default: i32) -> i32:
    if text.len() == 0: return default
    var n = 0
    for i in 0..text.len():
        let c = text[i]
        if c < '0' or c > '9': return default
        n = n * 10 + (c - '0') as i32
    if n < 1: default else: n

fn median(values: List[f64]) -> f64:
    var sorted = values
    let n = sorted.len()
    for i in 0..n:
        var least = i
        for j in i + 1..n:
            if sorted[j] < sorted[least]: least = j
        let held: f64 = sorted[i]
        sorted[i] = sorted[least]
        sorted[least] = held
    if n == 0: return 0.0
    if n % 2 == 1: sorted[n / 2] else: (sorted[n / 2 - 1] + sorted[n / 2]) / 2.0

fn fail(message: &str) -> Never:
    eprint("corpus_bench: " ++ message)
    exit_code(1)

fn ensure_dir(path: &str):
    if mkdir_p(path) != 0: fail("cannot create " ++ path)

fn reset_dir(path: &str):
    if file_exists(path) and remove_tree(path) != 0: fail("cannot remove " ++ path)
    ensure_dir(path)

/// The entries of a directory as absolute paths (list_files_text prints one
/// per line, with or without the directory).
fn entries(dir: &str) -> List[str]:
    var out: List[str] = List.new()
    for line in list_files_text(dir).split("\n"):
        let name = line.trim()
        if name.len() == 0: continue
        out.push(if name.contains("/"): name else: dir ++ "/" ++ name)
    out

fn basename(path: &str) -> str:
    let parts = path.split("/")
    parts[parts.len() - 1]

fn copy_w_files(src_dir: &str, dst_dir: &str):
    ensure_dir(dst_dir)
    var copied = 0
    for path in entries(src_dir):
        if not path.ends_with(".w"): continue
        if copy_tree(path, dst_dir ++ "/" ++ basename(path)) != 0: fail("cannot copy " ++ path)
        copied += 1
    if copied == 0: fail("no modules under " ++ src_dir)

/// Run a command in a directory with its output captured; "" on success,
/// else the failure with the captured stderr.
fn run_in(cwd: &str, argv: &List[str], log: &str) -> str:
    let finished = run_to_files_in(cwd, argv, log ++ ".stdout", log ++ ".stderr")
    if finished.code == 0: return ""
    let stderr = (read_file(log ++ ".stderr") ?? "").trim()
    f"exit code {finished.code}: " ++ stderr.slice(0, if stderr.len() < 800: stderr.len() else: 800)

fn cc(cwd: &str, args: &List[str], output: &str):
    var argv: List[str] = ["/usr/bin/clang", "-O2", "-w"]
    for a in args: argv.push(a)
    argv.push("-o")
    argv.push(output)
    let failure = run_in(cwd, &argv, output ++ ".build")
    if failure.len() > 0: fail("C build of " ++ output ++ " failed: " ++ failure)

/// Build a corpus harness with With exactly as its test lane does: the
/// modules at lib/std/<rel> under a scratch tree, read from source
/// (`--bundle-corpus`), the prelude off.
fn with_build(compiler: &str, tree: &str, harness: &str, corpus_rel: &str, extra: &List[str], output: &str):
    var argv: List[str] = [compiler, "build", harness, "--bundle-corpus", corpus_rel, "--no-prelude"]
    for a in extra: argv.push(a)
    argv.push("-o")
    argv.push(output)
    let failure = run_in(tree, &argv, output ++ ".build")
    if failure.len() > 0: fail("With build of " ++ harness ++ " failed: " ++ failure)

/// The median wall time of `runs` runs of a command, each checked to exit 0.
fn time_runs(cwd: &str, argv: &List[str], log: &str, runs: i32) -> f64:
    var walls: List[f64] = List.new()
    for r in 0..runs:
        let started = now_ns()
        let finished = run_to_files_in(cwd, argv, log ++ ".stdout", log ++ ".stderr")
        let wall = seconds(now_ns() - started)
        if finished.code != 0:
            let stderr = (read_file(log ++ ".stderr") ?? "").trim()
            fail(f"run {r} of " ++ argv[0] ++ f" exited {finished.code}: " ++ stderr.slice(0, if stderr.len() < 400: stderr.len() else: 400))
        walls.push(wall)
    median(walls)

type Row {
    corpus: str,
    workload: str,
    c: f64,
    before: f64,
    after: f64,
}

fn ratio(a: f64, b: f64) -> str: if b <= 0.0 or a <= 0.0: "-" else: f"{a / b:.2f}"

fn cell(v: f64) -> str: if v <= 0.0: "-" else: f"{v:.3f}"

fn row_text(r: &Row) -> str:
    "| " ++ r.corpus ++ " | " ++ r.workload ++ " | " ++ cell(r.c) ++ " | " ++ cell(r.before) ++ " | " ++ cell(r.after) ++ " | " ++ ratio(r.before, r.c) ++ " | " ++ ratio(r.after, r.c) ++ " | " ++ ratio(r.after, r.before) ++ " |"

/// The three binaries of one harness: C from the reference tree, With from
/// the promoted modules, With from the fresh migration ("" when skipped).
type Built {
    c: str,
    before: str,
    after: str,
}

fn build_with_pair(compiler: &str, work: &str, corpus_rel: &str, before_dir: &str, after_dir: &str, harness: &str, extra: &List[str]) -> (str, str):
    let rel = "lib/std/" ++ corpus_rel.slice(4, corpus_rel.len())
    var before = ""
    if before_dir.len() > 0:
        let tree = work ++ "/before"
        reset_dir(tree)
        copy_w_files(before_dir, tree ++ "/" ++ rel)
        before = work ++ "/before_bin"
        with_build(compiler, tree, rel ++ "/" ++ harness, corpus_rel, extra, before)
    var after = ""
    if after_dir.len() > 0:
        let tree = work ++ "/after"
        reset_dir(tree)
        copy_w_files(after_dir, tree ++ "/" ++ rel)
        after = work ++ "/after_bin"
        with_build(compiler, tree, rel ++ "/" ++ harness, corpus_rel, extra, after)
    (before, after)

// ── zlib: minigzip over a 32 MiB text ────────────────────────────────

fn zlib_text() -> str:
    let vocabulary = ["the", "quick", "brown", "fox", "jumps", "over", "lazy", "dog", "zlib", "deflate", "inflate", "window", "stream", "huffman", "table", "block", "length", "distance", "code", "literal"]
    var lines: List[str] = List.new()
    var state: i64 = 12345
    var size: i64 = 0
    while size < 1048576:
        var words: List[str] = List.new()
        for k in 0..12:
            state = (state * 1103515245 + 12345) % 2147483648
            words.push(vocabulary[(state / 65536) % vocabulary.len()])
            if k % 4 == 3: words.push(f"{state % 1000}")
        let line = words.join(" ")
        size += line.len() + 1
        lines.push(line)
    var text = lines.join("\n") ++ "\n"
    for _ in 0..5: text = text ++ text
    text

fn bench_zlib(root: &str, compiler: &str, before_dir: &str, after_dir: &str, runs: i32) -> List[Row]:
    var rows: List[Row] = List.new()
    let reference = root ++ "/out/zlib_reference/zlib-1.3.2"
    if not file_exists(reference ++ "/zlib.h"): fail("no zlib reference tree at " ++ reference ++ " (run `with build :zlib-prepare-reference`)")
    let work = root ++ "/out/corpus_bench/zlib"
    reset_dir(work)
    var c_args: List[str] = ["-I" ++ reference, "-DHAVE_UNISTD_H", "-DHAVE_STDARG_H"]
    for unit in ["adler32", "compress", "crc32", "deflate", "gzclose", "gzlib", "gzread", "gzwrite", "infback", "inffast", "inflate", "inftrees", "trees", "uncompr", "zutil"]:
        c_args.push(reference ++ "/" ++ unit ++ ".c")
    c_args.push(reference ++ "/test/minigzip.c")
    let c_bin = work ++ "/c_bin"
    cc(work, &c_args, c_bin)
    let (before, after) = build_with_pair(compiler, work, "std/engines/zlib", before_dir, after_dir, "minigzip.w", &List.new())
    let input = work ++ "/input.txt"
    if write_file(input, zlib_text()) != 0: fail("cannot write " ++ input)
    var compress = Row { corpus: "zlib", workload: "minigzip compress 32 MiB", c: 0.0, before: 0.0, after: 0.0 }
    var decompress = Row { corpus: "zlib", workload: "minigzip decompress", c: 0.0, before: 0.0, after: 0.0 }
    for (label, bin) in [("c", c_bin), ("before", before), ("after", after)]:
        if bin.len() == 0: continue
        let gz = work ++ "/" ++ label ++ ".gz"
        // `-c` writes the compressed stream to stdout, captured as the .gz.
        let c_wall = time_runs(work, &[bin, "-c", input], gz.slice(0, gz.len() - 3), runs)
        if copy_tree(gz.slice(0, gz.len() - 3) ++ ".stdout", gz) != 0: fail("cannot keep " ++ gz)
        let d_wall = time_runs(work, &[bin, "-d", "-c", gz], work ++ "/" ++ label ++ "_decompress", runs)
        if label == "c":
            compress.c = c_wall
            decompress.c = d_wall
        else if label == "before":
            compress.before = c_wall
            decompress.before = d_wall
        else:
            compress.after = c_wall
            decompress.after = d_wall
    rows.push(compress)
    rows.push(decompress)
    rows

// ── pcre2: pcre2test over the main test inputs ───────────────────────

fn bench_pcre2(root: &str, compiler: &str, before_dir: &str, after_dir: &str, runs: i32) -> List[Row]:
    var rows: List[Row] = List.new()
    let reference = root ++ "/out/pcre2_reference/pcre2-10.47"
    let src = reference ++ "/src"
    if not file_exists(src ++ "/config.h"): fail("no prepared pcre2 reference tree at " ++ reference ++ " (run `with build :pcre2-prepare-reference`)")
    let work = root ++ "/out/corpus_bench/pcre2"
    reset_dir(work)
    // The library at width 8 (pcre2posix included) in one object, pcre2test
    // without a width (it defines its own, as upstream's Makefile builds it).
    var objects: List[str] = List.new()
    for path in entries(src):
        let name = basename(path)
        if not name.ends_with(".c") or not name.starts_with("pcre2"): continue
        if name == "pcre2test.c" or name == "pcre2_jit_test.c" or name == "pcre2posix_test.c" or name == "pcre2_dftables.c" or name == "pcre2_fuzzsupport.c" or name == "pcre2grep.c" or name == "pcre2demo.c": continue
        var unit_args: List[str] = ["-c", "-I" ++ src, "-DHAVE_CONFIG_H", "-DPCRE2_CODE_UNIT_WIDTH=8"]
        unit_args.push(path)
        let object = work ++ "/" ++ name.slice(0, name.len() - 2) ++ ".o"
        cc(work, &unit_args, object)
        objects.push(object)
    let test_object = work ++ "/pcre2test.o"
    cc(work, &["-c", "-I" ++ src, "-DHAVE_CONFIG_H", src ++ "/pcre2test.c"], test_object)
    objects.push(test_object)
    let c_bin = work ++ "/c_bin"
    cc(work, &objects, c_bin)
    let (before, after) = build_with_pair(compiler, work, "std/engines/pcre2", before_dir, after_dir, "pcre2test.w", &List.new())
    for input in ["testinput1", "testinput4"]:
        var row = Row { corpus: "pcre2", workload: "pcre2test " ++ input, c: 0.0, before: 0.0, after: 0.0 }
        let data = reference ++ "/testdata/" ++ input
        for (label, bin) in [("c", c_bin), ("before", before), ("after", after)]:
            if bin.len() == 0: continue
            let wall = time_runs(work, &[bin, "-q", data, work ++ "/" ++ label ++ "_" ++ input ++ ".out"], work ++ "/" ++ label ++ "_" ++ input, runs)
            if label == "c": row.c = wall
            else if label == "before": row.before = wall
            else: row.after = wall
        rows.push(row)
    rows

// ── tommyds: upstream's check program ────────────────────────────────

fn bench_tommyds(root: &str, compiler: &str, before_dir: &str, after_dir: &str, runs: i32) -> List[Row]:
    var rows: List[Row] = List.new()
    let reference = root ++ "/out/tommyds_reference/extracted/tommyds-1f3727fc89174902c48e3933ac4610cb7fb13f4a"
    if not file_exists(reference ++ "/check.c"): fail("no tommyds reference tree at " ++ reference ++ " (run `with build :tommyds-prepare-reference`)")
    let work = root ++ "/out/corpus_bench/tommyds"
    reset_dir(work)
    // tommy.c is the amalgamation of every unit; compiling the units beside
    // it defines each symbol twice.
    let c_bin = work ++ "/c_bin"
    cc(work, &["-I" ++ reference, reference ++ "/check.c", reference ++ "/tommyds/tommy.c"], c_bin)
    let (before, after) = build_with_pair(compiler, work, "std/engines/tommyds", before_dir, after_dir, "check_.w", &["-O1"])
    var row = Row { corpus: "tommyds", workload: "check", c: 0.0, before: 0.0, after: 0.0 }
    for (label, bin) in [("c", c_bin), ("before", before), ("after", after)]:
        if bin.len() == 0: continue
        let wall = time_runs(work, &[bin], work ++ "/" ++ label ++ "_check", runs)
        if label == "c": row.c = wall
        else if label == "before": row.before = wall
        else: row.after = wall
    rows.push(row)
    rows

// ── c-algorithms: the test programs ──────────────────────────────────

fn calg_tests() -> List[str]:
    ["alloc-testing", "arraylist", "avl-tree", "binary-heap", "binomial-heap",
     "bloom-filter", "cpp", "list", "slist", "queue", "compare-functions",
     "hash-functions", "hash-table", "rb-tree", "set", "trie", "sortedarray"]

fn bench_c_algorithms(root: &str, compiler: &str, before_dir: &str, after_dir: &str, runs: i32) -> List[Row]:
    var rows: List[Row] = List.new()
    let reference = root ++ "/out/c_algorithms_reference/extracted/c-algorithms-23d453792ed89a28ed7d2c8d4311a4d9f7822edd"
    if not file_exists(reference ++ "/src/libcalg.h"): fail("no c-algorithms reference tree at " ++ reference ++ " (run `with build :c-algorithms-prepare-reference`)")
    let work = root ++ "/out/corpus_bench/c_algorithms"
    reset_dir(work)
    let tests_dir = root ++ "/test/corpora/c_algorithms"
    let package_dir = "lib/std/calg_testing"
    var row = Row { corpus: "c-algorithms", workload: "17 test programs", c: 0.0, before: 0.0, after: 0.0 }
    for name in calg_tests():
        let program = work ++ "/" ++ name
        ensure_dir(program)
        var c_args: List[str] = ["-x", "c", "-DALLOC_TESTING", "-I" ++ reference ++ "/src", "-I" ++ reference ++ "/test"]
        for path in entries(reference ++ "/src"):
            if path.ends_with(".c"): c_args.push(path)
        c_args.push(reference ++ "/test/alloc-testing.c")
        c_args.push(reference ++ "/test/framework.c")
        c_args.push(reference ++ "/test/test-" ++ name ++ (if name == "cpp": ".cpp" else: ".c"))
        let c_bin = program ++ "/c_bin"
        cc(program, &c_args, c_bin)
        row.c += time_runs(program, &[c_bin], program ++ "/c_run", runs)
        let module_name = "test_" ++ name.replace("-", "_") ++ ".w"
        for (label, source) in [("before", before_dir), ("after", after_dir)]:
            if source.len() == 0: continue
            let tree = program ++ "/" ++ label
            reset_dir(tree ++ "/" ++ package_dir)
            if label == "before":
                copy_w_files(tests_dir ++ "/engine", tree ++ "/" ++ package_dir)
                copy_w_files(tests_dir ++ "/programs/" ++ name, tree ++ "/" ++ package_dir)
            else:
                copy_w_files(source ++ "/tests/" ++ name, tree ++ "/" ++ package_dir)
            let bin = program ++ "/" ++ label ++ "_bin"
            let failure = run_in(tree, &[compiler, "build", "--no-prelude", "-O1", package_dir ++ "/" ++ module_name, "-o", bin], bin ++ ".build")
            if failure.len() > 0: fail("With build of test-" ++ name ++ " (" ++ label ++ ") failed: " ++ failure)
            let wall = time_runs(program, &[bin], program ++ "/" ++ label ++ "_run", runs)
            if label == "before": row.before += wall
            else: row.after += wall
    rows.push(row)
    rows

// ── main ─────────────────────────────────────────────────────────────

let argv = args()
// Builds and runs happen in work directories, so the root and a relative
// compiler path are made absolute first.
let root_arg = arg_value(&argv, "--root", ".")
let root = if root_arg == ".": env("PWD") else: root_arg
let compiler_arg = arg_value(&argv, "--with", "with")
let compiler = if compiler_arg.contains("/") and not compiler_arg.starts_with("/"): root ++ "/" ++ compiler_arg else: compiler_arg
let runs = parse_count(arg_value(&argv, "-n", "5"), 5)
let after_mode = arg_value(&argv, "--after", "")
var corpora = arg_values(&argv, "--corpus")
if corpora.len() == 0: corpora = ["zlib", "pcre2", "tommyds", "c_algorithms"]
ensure_dir(root ++ "/out/corpus_bench")
var rows: List[Row] = List.new()
for name in corpora:
    let promoted = "lib/std/engines/" ++ name
    let before_dir = root ++ "/" ++ arg_value(&argv, "--before", promoted)
    // c-algorithms' fresh test programs are migrated whole, each under
    // out/c_algorithms_tests_migrated/tests/<name> (build/c_algorithms.w).
    let fresh_default = if name == "c_algorithms": "c_algorithms_tests_migrated" else: name ++ "_migrated"
    let after_dir = if after_mode == "none": "" else if after_mode.len() > 0: root ++ "/" ++ after_mode else: root ++ "/out/" ++ fresh_default
    let after = if after_dir.len() > 0 and file_exists(after_dir): after_dir else: ""
    if after_dir.len() > 0 and after.len() == 0: eprint("corpus_bench: no fresh migration at " ++ after_dir ++ ", measuring C and before only")
    let measured = if name == "zlib": bench_zlib(root, compiler, before_dir, after, runs)
        else if name == "pcre2": bench_pcre2(root, compiler, before_dir, after, runs)
        else if name == "tommyds": bench_tommyds(root, compiler, before_dir, after, runs)
        else if name == "c_algorithms": bench_c_algorithms(root, compiler, before_dir, after, runs)
        else: fail("unknown corpus " ++ name)
    rows ++= measured
var table = "| corpus | workload | C (s) | With before (s) | With after (s) | before/C | after/C | after/before |\n|---|---|---|---|---|---|---|---|\n"
for r in rows: table = table ++ row_text(r) ++ "\n"
print(table)
if write_file(root ++ "/out/corpus_bench/results.md", f"Median of {runs} runs, host clang -O2 against the With compiler as the corpus test lanes build each harness.\n\n" ++ table) != 0: fail("cannot write results.md")
