//! expect-stdout: ok
// #809: the root module's declarations were seeded with the path as the
// command line spelled it, while the import graph holds Resolve's
// normalized path. `sub/./prog.w`, `sub//prog.w` and Windows'
// `tools\battery.w` then named a module with no imports: under
// `use std.thread`, "'spawn_os' requires an explicit import". Every
// spelling of the same file checks alike.
use std.fs
use std.process

fn temp_root() -> str:
    let tmpdir = env("TMPDIR")
    if tmpdir.len() > 0: return tmpdir
    "/tmp"

fn main:
    let compiler = env("WITH_TEST_COMPILER")
    assert(compiler.len() > 0)
    let base = temp_root() ++ f"/with-behav-809-root-{pid()}"
    remove_tree(base)
    assert(mkdir_p(base ++ "/sub") == 0)
    assert(write_file(base ++ "/sub/prog.w", "use std.thread\nfn w() -> i32: 7\nlet h = spawn_os(w)\nprint(join(&h))\n") == 0)
    var failed = 0
    for spelling in [base ++ "/sub/prog.w", base ++ "/sub/./prog.w", base ++ "/sub//prog.w"]:
        let ran = run_to_files(&[compiler, "check", spelling], base ++ "/out", base ++ "/err", 120000)
        if ran.code != 0:
            print(f"{spelling}: code {ran.code} err [{read_file(base ++ "/err") ?? ""}]")
            failed = failed + 1
    remove_tree(base)
    if failed == 0: print("ok")
