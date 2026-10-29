//! expect-stdout: ok
// #809: the root module's declarations carry the path as the command line
// spelled it, so the import graph must hold the root under that spelling.
// Registered under Resolve's normalized path, `sub/./prog.w`, `sub//prog.w`
// and Windows' `tools\battery.w` named a module with no imports: under
// `use std.thread`, "'spawn_os' requires an explicit import". Normalizing
// the declarations' paths instead lost the spelling where it is the
// program's: `__FILE__` and panic sites print it byte for byte (#1953), and
// an `--emit-obj` of the root compared those paths with the spelling and
// defined none of its functions. Every spelling of the same file checks,
// runs and emits alike.
use std.fs
use std.process

fn temp_root() -> str:
    let tmpdir = env("TMPDIR")
    if tmpdir.len() > 0: return tmpdir
    let temp = env("TEMP")
    if temp.len() > 0: return temp
    "/tmp"

fn main:
    let compiler = env("WITH_TEST_COMPILER")
    assert(compiler.len() > 0)
    let base = temp_root() ++ f"/with-behav-809-root-{pid()}"
    remove_tree(base)
    assert(mkdir_p(base ++ "/sub") == 0)
    assert(write_file(base ++ "/sub/prog.w", "use std.thread\nfn w() -> i32: 7\nlet h = spawn_os(w)\nprint(__FILE__)\nprint(join(&h))\n") == 0)
    var failed = 0
    for spelling in [base ++ "/sub/prog.w", base ++ "/sub/./prog.w", base ++ "/sub//prog.w"]:
        let ran = run_to_files(&[compiler, "run", spelling], base ++ "/out", base ++ "/err", 120000)
        let out = read_file(base ++ "/out") ?? ""
        if ran.code != 0 or out != spelling ++ "\n7\n":
            print(f"run {spelling}: code {ran.code} out [{out}] err [{read_file(base ++ "/err") ?? ""}]")
            failed = failed + 1
        let obj = base ++ "/prog.o"
        remove_file(obj)
        let emitted = run_to_files(&[compiler, "build", spelling, "--emit-obj", "-o", obj], base ++ "/out", base ++ "/err", 120000)
        if emitted.code != 0 or not (read_file(obj) ?? "").contains("main\0"):
            print(f"emit-obj {spelling}: code {emitted.code}, the object defines no main")
            failed = failed + 1
    remove_tree(base)
    if failed == 0: print("ok")
