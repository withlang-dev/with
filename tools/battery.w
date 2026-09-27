// The seed-driven battery as one command.
//
//   with run tools/battery.w [--fail-fast]
//
// Run it from a worktree's root with the pinned seed at src/main (`with build
// :seed` once per seed.lock bump). It
//   1. refuses a dirty tree: a battery blesses committed sources (D49);
//   2. takes one of two machine-wide battery slots, so a third battery cannot
//      start by accident (a slot whose owner died is reclaimed);
//   3. runs `src/main build :gate` — the release build plus the pre-battery
//      gate (build.w's gate_fixed_targets and every test lane the last
//      battery measured under 60 s); a red gate stops here, since the
//      25-minute checks would only repeat it;
//   4. runs `src/main build :battery-checks` — fixpoint, the drop and move
//      audits, every test target, user-programs-safe, and the green evidence —
//      as ONE survey invocation, so a red reports every failing target at
//      once instead of one per battery. `--fail-fast` stops it at the first
//      red target instead (the repair loop).
// Both steps report live: while the child runs, its log is polled once a
// second and every newly failed target lands in status.txt as `RED: <target>`
// the moment it appears, so a red known at minute 1 is read at minute 1.
// Afterwards the wall times of every target both steps ran are merged into
// out/.build-state/battery-times.tsv, the ledger the gate reads, and the
// evaluated-graph cache is dropped so the next `with build` re-reads it.
// Logs, per-step wall times and out/battery/status.txt land in out/battery/.
use std.fs
use std.process
use std.thread
use std.time

fn sh(cmd: &str): run(&["sh", "-c", cmd.clone()])

fn first_line(path: &str) -> str:
    let text = read_file(path) ?? ""
    for line in text.split("\n"):
        if line.len() > 0: return line.clone()
    ""

fn append(path: &str, line: &str): assert(write_file(path, (read_file(path) ?? "") ++ line ++ "\n") == 0)

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

// The target a driver line reports as failed, or "". The driver has one line
// per kind — `error: build.w target 'x' failed …`, `error: run_corpus_test
// target 'x' failed …`, `error: build.w test target failed: x`, `survey:
// skipping 'x' (dependency …)` — and the closing survey summary repeats each
// as `  failed: x`; any of them names the target as soon as it is written.
fn failed_target(line: &str) -> str:
    if line.starts_with("error: build.w test target failed: "):
        return line.slice(35, line.len()).trim().clone()
    if line.starts_with("  failed: "):
        return line.slice(10, line.len()).trim().clone()
    let quoted_failure = (line.starts_with("error: ") and line.contains(" target '") and line.contains("' failed")) or line.starts_with("survey: skipping '")
    if not quoted_failure: return ""
    let quoted = line.split("'")
    if quoted.len() < 2: return ""
    quoted[1].clone()

// Every target the log reports as failed so far, space-separated, in order
// of first appearance.
fn failed_targets(log: &str) -> str:
    let text = read_file(log) ?? ""
    var out = " "
    for line in text.split("\n"):
        let name = failed_target(line)
        if name.len() > 0 and not out.contains(" " ++ name ++ " "): out = out ++ name ++ " "
    out.trim().clone()

// The child runs on its own OS thread (std.process has no non-blocking
// wait): the worker runs the command and writes its exit code to live_done,
// and the main thread polls the log meanwhile.
// (an implicit-main script has no `global`; the two are process env vars.)
fn live_cmd -> str: env("WITH_BATTERY_LIVE_CMD")
fn live_done -> str: env("WITH_BATTERY_LIVE_DONE")

fn live_worker -> i32:
    let rc = sh(live_cmd())
    assert(write_file(live_done(), f"{rc}\n") == 0)
    rc

// Run `cmd` with its output in `log`, appending `RED: <target>` to `status`
// for each newly failed target while it runs; returns the exit code and
// records `<name> rc=… wall=…s`.
fn step_live(name: &str, cmd: &str, log: &str, status: &str) -> i32:
    assert(set_env("WITH_BATTERY_LIVE_CMD", cmd) == 0)
    assert(set_env("WITH_BATTERY_LIVE_DONE", f"out/battery/{name}.done") == 0)
    let _ = remove_file(live_done())
    let t0 = now()
    let worker = spawn_os(live_worker)
    var reported = " "
    var finished = false
    while not finished:
        finished = file_exists(live_done())
        if not finished: let _ = sleep_secs(1)
        for target in failed_targets(log).split(" "):
            if target.len() == 0 or reported.contains(" " ++ target ++ " "): continue
            reported = reported ++ target ++ " "
            let line = "RED: " ++ target
            print(line)
            append(status, line)
    let rc = join(&worker)
    let line = f"{name} rc={rc} wall={now() - t0}s"
    print(line)
    append(status, line)
    rc

// Merge the driver's per-invocation build-times.tsv into the ledger the gate
// reads: one line per target, the latest measurement wins, sorted by name;
// the header and TOTAL lines are not targets.
fn merge_times(ledger: &str, times: &str):
    if not file_exists(times): return
    var names: Vec[str] = Vec.new()
    var lines: Vec[str] = Vec.new()
    for source in [ledger, times]:
        for line in (read_file(source) ?? "").split("\n"):
            let cols = line.split("\t")
            if cols.len() < 3 or cols[0] == "target" or cols[0] == "TOTAL": continue
            var found = false
            for i in 0..names.len() as i32:
                if names[i] == cols[0]:
                    lines[i] = line.clone()
                    found = true
            if not found:
                names.push(cols[0].clone())
                lines.push(line.clone())
    var text = "target\tseconds\tpeak_rss\n"
    var remaining = lines.len() as i32
    var taken: Vec[i32] = Vec.new()
    for i in 0..names.len() as i32: taken.push(0)
    while remaining > 0:
        var best = -1
        for i in 0..names.len() as i32:
            if taken[i] != 0: continue
            if best < 0 or names[i] < names[best]: best = i
        taken[best] = 1
        remaining = remaining - 1
        text = text ++ lines[best] ++ "\n"
    assert(write_file(ledger, text) == 0)
    // build.w reads the ledger when the graph is evaluated, once per
    // build-source hash; drop the evaluated graph so the next build re-reads.
    let _ = remove_file("out/.build-state/build-graph.cache")

var fail_fast = false
for arg in args():
    if arg == "--fail-fast": fail_fast = true
    else if arg == "--help" or arg == "-h":
        print("usage: with run tools/battery.w [--fail-fast]")
        print("  runs `src/main build :gate`, then `src/main build :battery-checks`, reporting")
        print("  each failed target live in out/battery/status.txt as `RED: <target>`;")
        print("  --fail-fast stops the checks at the first red target (the repair loop).")
        exit_code(0)
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
let ledger = "out/.build-state/battery-times.tsv"
let flags = if fail_fast: " --fail-fast" else: ""
var rc = step_live("gate", "WITH=$PWD/src/main src/main build :gate" ++ flags ++ " > out/battery/gate.log 2>&1", "out/battery/gate.log", status)
merge_times(ledger, "out/.build-state/build-times.tsv")
if rc == 0:
    rc = step_live("battery-checks", "WITH=$PWD/src/main src/main build :battery-checks" ++ flags ++ " > out/battery/checks.log 2>&1", "out/battery/checks.log", status)
    merge_times(ledger, "out/.build-state/build-times.tsv")
    let failed = failed_targets("out/battery/checks.log")
    if failed.len() > 0:
        print("failed: " ++ failed)
        append(status, "failed: " ++ failed)
else:
    let failed = failed_targets("out/battery/gate.log")
    print("RED (gate): " ++ failed)
    append(status, "RED (gate): " ++ failed)
let verdict = if rc == 0: "GREEN" else: "RED"
append(status, verdict ++ "\nBATTERY_DONE")
let _ = remove_file(slot)
print(f"battery: {verdict} ({head}); logs in out/battery/")
exit_code(rc)
