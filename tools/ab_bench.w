// A/B wall-clock measurement of two compilers on one workload (D120's
// merge gate: self-host compile time and the corpus suites within 5%,
// D120 Amendment 1).
//
//   with run tools/ab_bench.w <baseline-with> <candidate-with> <rounds> -- <cmd...>
//
// `{with}` in <cmd...> is replaced by the compiler under measurement. Each
// round runs the baseline then the candidate (interleaved, A B A B …), the
// wall is the clock around the whole command, and the report gives each
// side's median, the ratio candidate/baseline, and the spread (min..max)
// of the per-round ratios, which is what the verdict is judged on: a
// regression counts only when every round's ratio exceeds 1.05.
use std.process
use std.time
use std.string.parse

fn wall_of(with_path: &str, cmd: &List[str]) -> f64:
    var argv: List[str] = List.new()
    for a in cmd: argv.push(a.replace("{with}", with_path))
    let t0 = now_ns()
    let rc = run(argv)
    let t1 = now_ns()
    if rc != 0:
        eprint(f"ab_bench: `{argv[0]}` exited {rc}")
        exit_code(2)
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
    if argv.len() < 6 or argv[4] != "--":
        eprint("usage: with run tools/ab_bench.w <baseline-with> <candidate-with> <rounds> -- <cmd...> ({with} = the compiler)")
        exit_code(2)
    let baseline = argv[1]
    let candidate = argv[2]
    let rounds: i32 = parse(argv[3])
    var cmd: List[str] = List.new()
    for i in 5..argv.len(): cmd.push(argv[i])
    var a: List[f64] = List.new()
    var b: List[f64] = List.new()
    var ratios: List[f64] = List.new()
    print("round\tbaseline s\tcandidate s\tratio")
    for r in 0..rounds:
        let ta = wall_of(baseline, cmd)
        let tb = wall_of(candidate, cmd)
        a.push(ta)
        b.push(tb)
        let ratio = tb / ta
        ratios.push(ratio)
        print(f"{r + 1}\t{ta:.2}\t{tb:.2}\t{ratio:.4}")
    var lo: f64 = ratios[0]
    var hi: f64 = ratios[0]
    for x in ratios:
        if x < lo: lo = x
        if x > hi: hi = x
    let ma = median(a)
    let mb = median(b)
    print(f"median\t{ma:.2}\t{mb:.2}\t{mb / ma:.4}")
    print(f"ratio spread {lo:.4}..{hi:.4}; regression counts only when every round exceeds 1.05: " ++ (if lo > 1.05: "REGRESSION" else: "within the gate or noise"))
