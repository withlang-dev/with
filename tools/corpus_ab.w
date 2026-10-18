// A/B wall-clock measurement of two compilers on a corpus test suite (the
// second half of D120's merge gate: the pcre2 and zlib suites within 5%,
// D120 Amendment 1; `tools/ab_bench.w` measures the self-host check).
//
//   with run tools/corpus_ab.w <baseline-with> <candidate-with> <rounds> pcre2|zlib
//
// Each compiler builds the suite's programs once (the promoted corpus under
// lib/std, the same sources the corpus lanes test), into
// out/corpus-ab/<side>/. Then the suite runs <rounds> times, baseline then
// candidate each round (A B A B …), the wall is the clock around the suite
// alone, never the build, and the report is ab_bench's: each side's median,
// the ratio candidate/baseline, and the spread of the per-round ratios. A
// regression counts only when every round's ratio exceeds 1.05.
//
// pcre2: lib/std/re/pcre2test.w over upstream's RunTest (-8 0-29, the same
// run as the pcre2-test lane, over the pinned release the lane prepares in
// out/pcre2_reference).
// zlib: lib/std/zl/minigzip.w compressing and decompressing a 16 MB text
// (the lane's round trip is 14 bytes, which times process start, not zlib).
use std.fs
use std.process
use std.time
use std.string.parse
use std.string.StringBuilder

fn fail(msg: &str):
    eprint("corpus_ab: " ++ msg)
    exit_code(2)

fn build_program(with_path: &str, src: &str, bin: &str):
    var argv: List[str] = List.new()
    argv.push(with_path)
    argv.push("build")
    argv.push(src)
    argv.push("-o")
    argv.push(bin)
    let rc = run(argv)
    if rc != 0: fail(f"`{with_path} build {src}` exited {rc}")
    if not file_exists(bin): fail("no binary at " ++ bin)

fn run_in(cwd: &str, argv: &List[str], log: &str) -> i32:
    let fin = run_to_files_in(cwd, argv, log ++ ".stdout", log ++ ".stderr")
    fin.code

fn abs_path(p: &str) -> str:
    if p.starts_with("/"): p else: env("PWD") ++ "/" ++ p

// pcre2: RunTest -8 0-29 with pcre2test pointed at the side's binary.
fn pcre2_wall(side_dir: &str) -> f64:
    let run_dir = side_dir ++ "/run"
    if file_exists(run_dir): remove_tree(run_dir)
    mkdir_p(run_dir)
    set_env("srcdir", abs_path("out/pcre2_reference/pcre2-10.47"))
    set_env("pcre2test", abs_path(side_dir ++ "/pcre2test"))
    var argv: List[str] = List.new()
    argv.push("/bin/bash")
    argv.push(abs_path("out/pcre2_reference/pcre2-10.47/RunTest"))
    argv.push("-8")
    argv.push("0-29")
    let t0 = now_ns()
    let rc = run_in(abs_path(run_dir), argv, abs_path(run_dir ++ "/runtest"))
    let t1 = now_ns()
    if rc != 0: fail(f"RunTest exited {rc} in {run_dir}")
    (t1 - t0) as f64 / 1000000000.0

// zlib: minigzip round trip of a 16 MB text that compresses like prose.
fn zlib_input(path: &str):
    if file_exists(path): return
    var sb = StringBuilder.new()
    var seed: i64 = 12345
    while sb.len() < 16 * 1024 * 1024:
        seed = (seed * 1103515245 + 12345) % 2147483648
        sb.push_str("line " ++ seed.to_str() ++ " the quick brown fox jumps over the lazy dog ")
        if seed % 7 == 0: sb.push_str("\n")
    write_file(path, sb.to_str())

fn zlib_input_text() -> str:
    match read_file("out/corpus-ab/zlib-input.txt"):
        Ok(t) => t
        Err(_) => panic("zlib input missing")

fn zlib_wall(side_dir: &str) -> f64:
    let run_dir = side_dir ++ "/run"
    if file_exists(run_dir): remove_tree(run_dir)
    mkdir_p(run_dir)
    let input = run_dir ++ "/input.txt"
    zlib_input("out/corpus-ab/zlib-input.txt")
    write_file(input, zlib_input_text())
    let minigzip = abs_path(side_dir ++ "/minigzip")
    var gz: List[str] = List.new()
    gz.push(minigzip)
    gz.push("input.txt")
    var gunzip: List[str] = List.new()
    gunzip.push(minigzip)
    gunzip.push("-d")
    gunzip.push("input.txt.gz")
    let t0 = now_ns()
    if run_in(abs_path(run_dir), gz, abs_path(run_dir ++ "/gz")) != 0: fail("minigzip compress failed in " ++ run_dir)
    if run_in(abs_path(run_dir), gunzip, abs_path(run_dir ++ "/gunzip")) != 0: fail("minigzip decompress failed in " ++ run_dir)
    let t1 = now_ns()
    let back: str = match read_file(input):
        Ok(t) => t
        Err(_) => ""
    if back != zlib_input_text(): fail("minigzip round trip changed the input in " ++ run_dir)
    (t1 - t0) as f64 / 1000000000.0

fn median(xs: &List[f64]) -> f64:
    var s: List[f64] = List.new()
    for x in xs: s.push(x)
    for i in 1..s.len():
        var j = i
        while j > 0 and s[j - 1] > s[j]:
            let t: f64 = s[j]
            s[j] = s[j - 1]
            s[j - 1] = t
            j = j - 1
    let n = s.len()
    if n == 0: return 0.0
    if n % 2 == 1: s[n / 2] else: (s[n / 2 - 1] + s[n / 2]) / 2.0

fn main:
    let argv = args()
    if argv.len() != 5 or (argv[4] != "pcre2" and argv[4] != "zlib"):
        fail("usage: with run tools/corpus_ab.w <baseline-with> <candidate-with> <rounds> pcre2|zlib")
    let baseline = argv[1]
    let candidate = argv[2]
    let rounds: i32 = parse(argv[3])
    let suite = argv[4]
    let base_dir = "out/corpus-ab/" ++ suite ++ "/baseline"
    let cand_dir = "out/corpus-ab/" ++ suite ++ "/candidate"
    mkdir_p(base_dir)
    mkdir_p(cand_dir)
    if suite == "pcre2":
        if not file_exists("out/pcre2_reference/pcre2-10.47/RunTest"): fail("no out/pcre2_reference/pcre2-10.47/RunTest; run `src/main build :pcre2-prepare-reference` first")
        build_program(baseline, "lib/std/re/pcre2test.w", base_dir ++ "/pcre2test")
        build_program(candidate, "lib/std/re/pcre2test.w", cand_dir ++ "/pcre2test")
    else:
        build_program(baseline, "lib/std/zl/minigzip.w", base_dir ++ "/minigzip")
        build_program(candidate, "lib/std/zl/minigzip.w", cand_dir ++ "/minigzip")
    var a: List[f64] = List.new()
    var b: List[f64] = List.new()
    var ratios: List[f64] = List.new()
    print(suite ++ "\tround\tbaseline s\tcandidate s\tratio")
    for r in 0..rounds:
        let ta = if suite == "pcre2": pcre2_wall(base_dir) else: zlib_wall(base_dir)
        let tb = if suite == "pcre2": pcre2_wall(cand_dir) else: zlib_wall(cand_dir)
        a.push(ta)
        b.push(tb)
        let ratio = tb / ta
        ratios.push(ratio)
        print(f"{suite}\t{r + 1}\t{ta:.2}\t{tb:.2}\t{ratio:.4}")
    var lo: f64 = ratios[0]
    var hi: f64 = ratios[0]
    for x in ratios:
        if x < lo: lo = x
        if x > hi: hi = x
    let ma = median(a)
    let mb = median(b)
    print(f"{suite}\tmedian\t{ma:.2}\t{mb:.2}\t{mb / ma:.4}")
    print(f"ratio spread {lo:.4}..{hi:.4}; regression counts only when every round exceeds 1.05: " ++ (if lo > 1.05: "REGRESSION" else: "within the gate or noise"))
