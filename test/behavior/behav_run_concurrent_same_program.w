//! skip-on: windows issue #802: core-language behavior fails on native Windows (needs root-cause)
//! expect-stdout: ok

use pre_d_build_runner
use std.fs
use std.process
use std.thread

extern fn with_exec_argv_capture_cwd(args: &str, stdout_path: &str, stderr_path: &str, timeout_ms: i32, cwd: &str) -> i32

// #1374: `with run prog.w` named its binary, object and the object's nm
// report after the source alone (out/prog, out/prog.o, out/prog.o.undef), so
// concurrent runs of one program in one directory rewrote and deleted each
// other's files mid-link. A link that read another run's emptied report saw no
// undefined symbols and linked no runtime ("_with_vec_push" undefined); a run
// whose binary another run had deleted exited 127. Each run now builds in a
// directory of its own.
fn case_dir -> str: p7_case_dir("run_concurrent_same_program")

fn run_once(i: i32) -> i32:
    let dir = case_dir()
    unsafe { with_exec_argv_capture_cwd(p7_compiler_path() ++ "\0run\0prog.w\0", p7_join(dir, f"r{i}.out"), p7_join(dir, f"r{i}.err"), 300000, dir) }

fn main:
    let dir = p7_prepare_case("run_concurrent_same_program", "runconcurrent")
    p7_write(dir, "prog.w", "fn main:\n    let v: Vec[i32] = Vec.new()\n    v.push(7)\n    print(f\"ran {v[0]}\")\n")
    let previous_out = env("WITH_OUT_DIR").clone()
    assert(set_env("WITH_OUT_DIR", p7_join(dir, "out")) == 0)
    // One closure site per run: a closure made in a loop captures the loop's
    // Copy local by place, so every thread saw the last index (#1471).
    var handles: Vec[JoinHandle] = Vec.new()
    handles.push(spawn_os(() => run_once(0)))
    handles.push(spawn_os(() => run_once(1)))
    handles.push(spawn_os(() => run_once(2)))
    handles.push(spawn_os(() => run_once(3)))
    handles.push(spawn_os(() => run_once(4)))
    handles.push(spawn_os(() => run_once(5)))
    handles.push(spawn_os(() => run_once(6)))
    handles.push(spawn_os(() => run_once(7)))
    var failed = 0
    for i in 0..8:
        let rc = join(&handles[i])
        let out = read_file(p7_join(dir, f"r{i}.out")).unwrap()
        if rc != 0 or out != "ran 7\n":
            failed = failed + 1
            eprint(f"run {i}: rc={rc} stdout={out}")
            eprint(read_file(p7_join(dir, f"r{i}.err")).unwrap())
    assert(set_env("WITH_OUT_DIR", previous_out) == 0)
    assert(failed == 0)
    // Every run removed its own directory: binary, object and report. (The
    // extracted runtime objects under out/tmp/with_runtime stay.)
    let out_dir = p7_join(dir, "out")
    for path in list_files_text(out_dir).split("\n"):
        if path.starts_with(out_dir): assert(not path.slice(out_dir.len(), path.len()).contains("prog"))
    print("ok")
