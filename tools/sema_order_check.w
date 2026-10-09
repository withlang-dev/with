// Declaration-order independence of type checking (#1941).
//
//   with run tools/sema_order_check.w <with> <out-dir> [source-dir] [allowlist]
//
// Every test/compile_errors fixture is checked twice with <with>: as
// written, and with top-level bodies checked last to first
// (`--sema-body-order-reverse`). A body's facts and diagnostics may depend
// on another body only where the spec orders them (D43: a return type
// inferred from a body declared later is not known at an earlier call);
// those fixtures are named in test/sema_order_allowlist.txt. Exit 1 when
// any other fixture's exit code or output differs. Spawn, timeout and capture
// failures cannot be allowlisted; <out-dir>/report.txt lists every failure.
use std.process
use std.fs

extern fn with_exec_argv_capture_spawn(argv: &str, stdout_path: &str, stderr_path: &str) -> i32
extern fn with_exec_wait(pid: i32, timeout_ms: i32) -> i32

fn spawn_check(with_bin: &str, source: &str, reverse: bool, out: &str) -> i32:
    let argv = if reverse: with_bin ++ "\0check\0--sema-body-order-reverse\0" ++ source ++ "\0" else: with_bin ++ "\0check\0" ++ source ++ "\0"
    unsafe:
        with_exec_argv_capture_spawn(argv, out, out ++ ".err")

fn wait(pid: i32) -> i32:
    if pid <= 0: return -1
    unsafe:
        with_exec_wait(pid, 120000)

fn read(path: &str) -> str:
    read_file(path).unwrap()

fn base_name(path: &str) -> str:
    var start: i64 = 0
    for i in 0..path.len():
        if path[i] == '/':
            start = i + 1
    path.slice(start, path.len())

let argv = args()
if argv.len() < 3:
    print("usage: with run tools/sema_order_check.w <with> <out-dir> [source-dir] [allowlist]")
    exit_code(2)
let with_bin = argv[1].clone()
let out_dir = argv[2].clone()
let source_dir = if argv.len() > 3: argv[3].clone() else: "test/compile_errors"
let allowlist = if argv.len() > 4: argv[4].clone() else: "test/sema_order_allowlist.txt"
assert(mkdir_p(out_dir) == 0)
var allow: List[str] = List.new()
for raw in read(allowlist).split("\n"):
    let line = raw.trim()
    if line.len() > 0 and not line.starts_with("#"):
        allow.push(line.clone())
var sources: List[str] = List.new()
for f in list_files_text(source_dir).split("\n"):
    if f.ends_with(".w"):
        sources.push(if f.starts_with(source_dir ++ "/") or f.starts_with("/"): f.clone() else: source_dir ++ "/" ++ base_name(f))
if sources.len() == 0:
    print("sema-order-check: no fixtures found in " ++ source_dir)
    exit_code(2)
// Sixteen checks in flight.
var pids: List[i32] = List.new()
var codes: List[i32] = List.new()
var next_wait = 0
for source in sources:
    let b = base_name(source)
    pids.push(spawn_check(with_bin, source, false, out_dir ++ "/" ++ b ++ ".fwd"))
    pids.push(spawn_check(with_bin, source, true, out_dir ++ "/" ++ b ++ ".rev"))
    while pids.len() as i32 - next_wait > 16:
        codes.push(wait(pids[next_wait]))
        next_wait = next_wait + 1
while next_wait < pids.len() as i32:
    codes.push(wait(pids[next_wait]))
    next_wait = next_wait + 1
var differing = 0
var unexpected = 0
var runner_failures = 0
var report = ""
for si in 0..sources.len() as i32:
    let source = sources[si]
    let b = base_name(source)
    let p = out_dir ++ "/" ++ b
    let forward_code = codes[si * 2]
    let reverse_code = codes[si * 2 + 1]
    if forward_code < 0 or forward_code > 1 or reverse_code < 0 or reverse_code > 1:
        runner_failures = runner_failures + 1
        report = report ++ f"FAILED {b} child exit forward={forward_code} reverse={reverse_code}\n"
        continue
    if forward_code != reverse_code or read(p ++ ".fwd") != read(p ++ ".rev") or read(p ++ ".fwd.err") != read(p ++ ".rev.err"):
        differing = differing + 1
        var allowed = false
        for a in allow:
            if a == b:
                allowed = true
        if not allowed:
            unexpected = unexpected + 1
        report = report ++ (if allowed: "allowed " else: "DIFFERS ") ++ b ++ f" exit forward={forward_code} reverse={reverse_code}\n"
assert(write_file(out_dir ++ "/report.txt", report) == 0)
print(f"sema-order-check: {differing} of {sources.len()} fixtures differ under reverse body order, {unexpected} outside {allowlist}, {runner_failures} runner failures ({out_dir}/report.txt)")
if unexpected != 0 or runner_failures != 0:
    exit_code(1)
