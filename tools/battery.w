// The seed-driven battery as one command.
//
//   with run tools/battery.w
//
// Run it from a worktree's root with the pinned seed at src/main (`with build
// :seed` once per seed.lock bump). It
//   1. refuses a dirty tree: a battery blesses committed sources (D49);
//   2. takes one of two machine-wide battery slots, so a third battery cannot
//      start by accident (a slot whose owner died is reclaimed);
//   3. runs `src/main build`; a red build stops here, since nothing else can
//      run without a compiler;
//   4. runs `src/main build :battery-checks` — fixpoint, the drop and move
//      audits, every test target, user-programs-safe, and the green evidence —
//      as ONE survey invocation, so a red reports every failing target at
//      once instead of one per battery.
// Logs, per-step wall times and out/battery/status.txt land in out/battery/.
use std.fs
use std.process
use std.time

fn sh(cmd: &str): run(&["sh", "-c", cmd.clone()])

fn first_line(path: &str) -> str:
    let text = read_file(path) ?? ""
    for line in text.split("\n"):
        if line.len() > 0: return line.clone()
    ""

// The same rule as build/retention.w's ret_worktree_is_clean: a tracked change
// dirties the tree; an untracked path dirties it only if it could be a build
// input (docs/, examples/ and top-level *.md are not).
fn tree_is_clean -> bool:
    if sh("git status --porcelain > out/battery/git-status.txt") != 0: return false
    let text = read_file("out/battery/git-status.txt") ?? ""
    for line in text.split("\n"):
        if line.len() == 0: continue
        if not line.starts_with("?? "): return false
        let path = line.slice(3, line.len())
        let not_input = path.starts_with("examples/") or path.starts_with("docs/") or (path.ends_with(".md") and not path.contains("/"))
        if not not_input: return false
    true

fn slot_dir -> str: env("HOME") ++ "/.local/with-green/battery-slots"

fn slot_owner_alive(path: &str) -> bool:
    let owner = first_line(path)
    if owner.len() == 0: return false
    let owner_pid = owner.split("\t")[0].clone()
    sh("kill -0 " ++ owner_pid ++ " 2>/dev/null") == 0

// A free slot's path, or "" when both are held by live batteries.
fn take_slot(record: &str) -> str:
    assert(mkdir_p(slot_dir()) == 0)
    for i in 0..2:
        let path = slot_dir() ++ f"/{i}"
        if file_exists(path) and slot_owner_alive(path): continue
        assert(write_file(path, record) == 0)
        return path
    ""

// Every target the runner reports as failed: its per-target error line
// (`error: build.w target 'x' failed …`, `error: build.w test target 'x'
// failed …`) names it even when the closing survey summary is absent.
fn failed_targets(log: &str) -> str:
    let text = read_file(log) ?? ""
    var out = " "
    for line in text.split("\n"):
        if not line.starts_with("error: build.w ") or not line.contains("' failed"): continue
        let quoted = line.split("'")
        if quoted.len() < 2: continue
        let name = quoted[1].clone()
        if not out.contains(" " ++ name ++ " "): out = out ++ name ++ " "
    out.trim().clone()

fn step(name: &str, cmd: &str, status: &str) -> i32:
    let t0 = now()
    let rc = sh(cmd)
    let secs = now() - t0
    let line = f"{name} rc={rc} wall={secs}s"
    print(line)
    assert(write_file(status, (read_file(status) ?? "") ++ line ++ "\n") == 0)
    rc

assert(mkdir_p("out/battery") == 0)
if not file_exists("src/main"):
    eprint("battery: no pinned seed at src/main; run `with build :seed` first")
    exit_code(1)
if not tree_is_clean():
    eprint("battery: the worktree is not clean (out/battery/git-status.txt); commit first — a battery blesses committed sources")
    exit_code(1)
assert(sh("git rev-parse --short HEAD > out/battery/head.txt") == 0)
let head = first_line("out/battery/head.txt")
let cwd = env("PWD")
let slot = take_slot(f"{pid()}\t{cwd}\t{head}\n")
if slot.len() == 0:
    eprint("battery: two batteries are already running:")
    for i in 0..2: eprint("  " ++ first_line(slot_dir() ++ f"/{i}"))
    exit_code(1)
let status = "out/battery/status.txt"
assert(write_file(status, f"{head} {cwd}\n") == 0)
print(f"battery: {head} in {cwd}")
var rc = step("build", "WITH=$PWD/src/main src/main build > out/battery/build.log 2>&1", status)
if rc == 0:
    rc = step("battery-checks", "WITH=$PWD/src/main src/main build :battery-checks > out/battery/checks.log 2>&1", status)
    let failed = failed_targets("out/battery/checks.log")
    if failed.len() > 0:
        print("failed: " ++ failed)
        assert(write_file(status, (read_file(status) ?? "") ++ "failed: " ++ failed ++ "\n") == 0)
else:
    print("failed: " ++ failed_targets("out/battery/build.log"))
let verdict = if rc == 0: "GREEN" else: "RED"
assert(write_file(status, (read_file(status) ?? "") ++ verdict ++ "\nBATTERY_DONE\n") == 0)
let _ = remove_file(slot)
print(f"battery: {verdict} ({head}); logs in out/battery/")
exit_code(rc)
