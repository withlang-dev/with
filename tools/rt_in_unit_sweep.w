// D30 R2c lane sweep: run every test/behavior/*.w under WITH_RT_IN_UNIT=1 and
// survey the failures. `with test <dir>` stops at the first red, and
// `with build :test --survey` cannot be used — the lane env poisons build.w's
// own evaluation through the seed's embedded stdlib.
//
//   with run tools/rt_in_unit_sweep.w <fail-list-out> [1|0]   # 0 = baseline (no lane)
use std.process
use std.fs

fn owned(s: &str): s ++ ""     // #762: .clone() on a &str view

fn arg_or(argv: &Vec[str], i: i32, fallback: &str) -> str:
    if argv.len() as i32 > i:
        return owned(argv.get(i as i64))
    owned(fallback)

let ROOT = "test/behavior/"

fn in_glob(path: &str) -> bool:
    // The build target globs test/behavior/*.w — companion modules under
    // lib/ and fixture dirs like foo/ are not tests.
    if not path.ends_with(".w") or not path.starts_with(ROOT): return false
    not path.slice(ROOT.len(), path.len()).contains("/")

fn sweep(out_path: &str) -> i32:
    var fails: Vec[str] = Vec.new()
    var ran = 0
    for line in list_files_text("test/behavior").split("\n"):
        if not in_glob(line): continue
        var cmd: Vec[str] = Vec.new()
        cmd.push("with")
        cmd.push("test")
        cmd.push("--quiet")
        cmd.push(owned(line))
        let rc = run(&cmd)
        ran = ran + 1
        if rc != 0:
            fails.push(owned(line))
    var out = ""
    for i in 0..fails.len() as i32:
        out = out ++ fails.get(i as i64) ++ "\n"
    let _ = write_file(out_path, out)
    eprint(f"lane_sweep: ran={ran} failed={fails.len()} -> {out_path}\n")
    if fails.len() > 0: 1 else: 0

let argv = args()
let out_path = arg_or(&argv, 1, "lane-fails.txt")
let lane = arg_or(&argv, 2, "1")
let _ = if lane == "1": set_env("WITH_RT_IN_UNIT", "1") else: 0
exit_code(sweep(out_path))
