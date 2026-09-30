// Declaration-order independence of type checking (#1941).
//
//   with run tools/sema_order_check.w <with> <out-dir>
//
// Every test/compile_errors fixture is checked twice with <with>: as
// written, and with top-level bodies checked last to first
// (`--sema-body-order-reverse`). A body's facts and diagnostics may depend
// on another body only where the spec orders them (D43: a return type
// inferred from a body declared later is not known at an earlier call);
// those fixtures are named in test/sema_order_allowlist.txt. Exit 1 when
// any other fixture's output differs; <out-dir>/report.txt lists them.
use std.process
use std.fs

extern fn with_exec_argv_capture_spawn(argv: &str, stdout_path: &str, stderr_path: &str) -> i32
extern fn with_exec_wait(pid: i32, timeout_ms: i32) -> i32
extern fn with_fs_read_file(path: &str) -> str
extern fn with_fs_write_file(path: &str, data: &str) -> i32
extern fn with_fs_mkdir_p(path: &str) -> i32

fn spawn_check(with_bin: &str, source: &str, reverse: bool, out: &str) -> i32:
    let argv = if reverse: with_bin ++ "\0check\0--sema-body-order-reverse\0" ++ source ++ "\0" else: with_bin ++ "\0check\0" ++ source ++ "\0"
    unsafe:
        with_exec_argv_capture_spawn(argv, out, out ++ ".err")

fn wait(pid: i32):
    unsafe:
        let _ = with_exec_wait(pid, 120000)

fn read(path: &str) -> str:
    unsafe:
        with_fs_read_file(path)

fn base_name(path: &str) -> str:
    var start: i64 = 0
    for i in 0..path.len():
        if path[i] == '/':
            start = i + 1
    path.slice(start, path.len())

let argv = args()
if argv.len() < 3:
    print("usage: with run tools/sema_order_check.w <with> <out-dir>")
    exit_code(2)
let with_bin = argv[1].clone()
let out_dir = argv[2].clone()
unsafe:
    let _ = with_fs_mkdir_p(out_dir)
var allow: Vec[str] = Vec.new()
for raw in read("test/sema_order_allowlist.txt").split("\n"):
    let line = raw.trim()
    if line.len() > 0 and not line.starts_with("#"):
        allow.push(line.clone())
var sources: Vec[str] = Vec.new()
for f in list_files_text("test/compile_errors").split("\n"):
    if f.ends_with(".w"):
        sources.push(if f.starts_with("test/"): f.clone() else: "test/compile_errors/" ++ base_name(f))
// Sixteen checks in flight.
var pids: Vec[i32] = Vec.new()
var next_wait = 0
for source in sources:
    let b = base_name(source)
    pids.push(spawn_check(with_bin, source, false, out_dir ++ "/" ++ b ++ ".fwd"))
    pids.push(spawn_check(with_bin, source, true, out_dir ++ "/" ++ b ++ ".rev"))
    while pids.len() as i32 - next_wait > 16:
        wait(pids[next_wait])
        next_wait = next_wait + 1
while next_wait < pids.len() as i32:
    wait(pids[next_wait])
    next_wait = next_wait + 1
var differing = 0
var unexpected = 0
var report = ""
for source in sources:
    let b = base_name(source)
    let p = out_dir ++ "/" ++ b
    if read(p ++ ".fwd") ++ read(p ++ ".fwd.err") != read(p ++ ".rev") ++ read(p ++ ".rev.err"):
        differing = differing + 1
        var allowed = false
        for a in allow:
            if a == b:
                allowed = true
        if not allowed:
            unexpected = unexpected + 1
        report = report ++ (if allowed: "allowed " else: "DIFFERS ") ++ b ++ "\n"
unsafe:
    let _ = with_fs_write_file(out_dir ++ "/report.txt", report)
print(f"sema-order-check: {differing} of {sources.len()} fixtures differ under reverse body order, {unexpected} outside test/sema_order_allowlist.txt ({out_dir}/report.txt)")
if unexpected != 0:
    exit_code(1)
