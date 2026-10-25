//! expect-stdout: ok
// #991: a channel's queue is shared by every worker. With
// fiber_worker_count = 4 two workers ran send and recv at once on plain i32
// fields, and a producer's 20000 numbers summed short (191353235 for
// 199990000). Builds a project that runs four workers and checks the sum
// three times.
use std.fs
use std.process

fn temp_root() -> str:
    let tmpdir = env("TMPDIR")
    if tmpdir.len() > 0: return tmpdir
    let temp = env("TEMP")
    if temp.len() > 0: return temp
    "/tmp"

const PROGRAM: str = "use std.channel\n\nasync fn produce(tx: Sender[i64]) -> i64:\n    for i in 0..20000: tx.send(i)\n    tx.close()\n    0\n\nasync fn consume(rx: Receiver[i64]) -> i64:\n    var sum: i64 = 0\n    while true:\n        match rx.recv():\n            Some(v) => sum = sum + v\n            None => break\n    sum\n\nasync fn main:\n    let (tx, rx) = chan[i64](64)\n    let p = produce(move tx)\n    let c = consume(move rx)\n    let sum = c.await\n    let _ = p.await\n    print(sum)\n"

fn main:
    let compiler = env("WITH_TEST_COMPILER")
    assert(compiler.len() > 0)
    let base = temp_root() ++ f"/with-behav-991-{pid()}"
    let _clean = remove_tree(base)
    assert(mkdir_p(base ++ "/src") == 0)
    assert(write_file(base ++ "/with.toml", "[package]\nname = \"chan991\"\nversion = \"0.1.0\"\n\n[runtime]\nfiber_worker_count = 4\n") == 0)
    assert(write_file(base ++ "/src/main.w", PROGRAM) == 0)
    let built = run_to_files_in(base, &[compiler, "build", "src/main.w", "-o", base ++ "/chan.bin"], base ++ "/build.out", base ++ "/build.err")
    if built.code != 0:
        print(f"build failed: {read_file(base ++ "/build.err") ?? ""}")
        exit_code(1)
    for _ in 0..3:
        let ran = run_to_files(&[base ++ "/chan.bin"], base ++ "/run.out", base ++ "/run.err", 60000)
        // Bound first: a view through `??` loses its temporary (#2659).
        let raw = read_file(base ++ "/run.out") ?? ""
        let out = raw.trim()
        if ran.code != 0 or out != "199990000":
            print(f"code {ran.code} sum {out}")
            exit_code(1)
    let _done = remove_tree(base)
    print("ok")
