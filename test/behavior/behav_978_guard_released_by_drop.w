//! expect-stdout: ok
// #978: a lock guard releases its lock when it is dropped. The guards had no
// Drop, so a guard whose scope ended without `exit` held the lock forever and
// the next `enter` spun. Builds the program, then runs it as a child with a
// timeout, so a regression fails here instead of hanging the suite; the
// build has no limit, so a loaded machine cannot time it out.
use std.fs
use std.os
use std.process

fn temp_root() -> str:
    let tmpdir = env("TMPDIR")
    if tmpdir.len() > 0: return tmpdir
    let temp = env("TEMP")
    if temp.len() > 0: return temp
    "/tmp"

const PROGRAM: str = "use std.sync\n\nfn peek(m: &Mutex[i32]) -> i32:\n    let g = m.enter()\n    5\n\nfn bump(rw: &RwLock[i32]) -> i32:\n    let r = rw.enter()\n    let w = 0\n    w + 1\n\nfn main:\n    let m = Mutex.new(5)\n    let a = peek(&m)\n    let b = peek(&m)\n    let g = m.enter_mut()\n    let v = g.exit()\n    let rw = RwLock.new(7)\n    let c = bump(&rw)\n    let w = rw.enter_mut()\n    print(f\"{a} {b} {v} {c} {w.exit()}\")\n"

fn main:
    let compiler = env("WITH_TEST_COMPILER")
    assert(compiler.len() > 0)
    let base = temp_root() ++ f"/with-behav-978-{pid()}"
    let _clean = remove_tree(base)
    assert(mkdir_p(base) == 0)
    assert(write_file(base ++ "/main.w", PROGRAM) == 0)
    let exe = base ++ (if os() == "Windows": "/main.exe" else: "/main")
    let built = run_to_files_in(base, &[compiler, "build", base ++ "/main.w", "-o", exe], base ++ "/build.out", base ++ "/build.err")
    if built.code != 0:
        print(f"build failed {built.code}: {read_file(base ++ "/build.err") ?? ""}")
        exit_code(1)
    let ran = run_to_files(&[exe], base ++ "/run.out", base ++ "/run.err", 20000)
    let raw = read_file(base ++ "/run.out") ?? ""
    if ran.timed_out or ran.code != 0 or raw.trim() != "5 5 5 1 7":
        print(f"timed out {ran.timed_out} code {ran.code} out [{raw}] err [{read_file(base ++ "/run.err") ?? ""}]")
        exit_code(1)
    let _done = remove_tree(base)
    print("ok")
