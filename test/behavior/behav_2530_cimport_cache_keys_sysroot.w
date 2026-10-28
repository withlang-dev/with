//! skip-on: windows the host C sysroot is not selectable on Windows (host_c_sysroot is empty): the key has one sysroot to name
//! expect-stdout: ok
// #2530: the c_import cache keyed an import by the header's spelling, not by
// the sysroot it was read from. `sqlite3.h` under SDKROOT (the Xcode SDK
// compiles out the load-extension API) was served to a later build on the
// embedded sysroot, where the same call is declared: "undefined variable".
// Two sysroots here give `probe_key.h` different declarations; the second
// import must read its own.
use std.fs
use std.process

fn temp_root() -> str:
    let tmpdir = env("TMPDIR")
    if tmpdir.len() > 0: return tmpdir
    "/tmp"

fn check_with(compiler: &str, base: &str, sysroot: &str, program: &str) -> bool:
    // Each host reads its own: the SDK root on macOS, the sysroot on Linux.
    set_env("WITH_SDKROOT", base ++ "/" ++ sysroot)
    set_env("WITH_LINUX_SYSROOT", base ++ "/" ++ sysroot)
    let ran = run_to_files(&[compiler, "check", base ++ "/" ++ program], base ++ "/out", base ++ "/err", 120000)
    if ran.code != 0:
        print(f"{program} under {sysroot}: code {ran.code} err [{read_file(base ++ "/err") ?? ""}]")
    ran.code == 0

fn main:
    let compiler = env("WITH_TEST_COMPILER")
    assert(compiler.len() > 0)
    let base = temp_root() ++ f"/with-behav-2530-{pid()}"
    remove_tree(base)
    assert(mkdir_p(base ++ "/sa/usr/include") == 0)
    assert(mkdir_p(base ++ "/sb/usr/include") == 0)
    assert(write_file(base ++ "/sa/usr/include/probe_key.h", "int probe_a(void);\n") == 0)
    assert(write_file(base ++ "/sb/usr/include/probe_key.h", "int probe_b(void);\n") == 0)
    assert(write_file(base ++ "/ka.w", "use c_import(\"probe_key.h\")\nfn main:\n    print(probe_a())\n") == 0)
    assert(write_file(base ++ "/kb.w", "use c_import(\"probe_key.h\")\nfn main:\n    print(probe_b())\n") == 0)
    // A fresh epoch: this run's imports share no entry with another run's.
    set_env("WITH_CIMPORT_CACHE_EPOCH", f"behav-2530-{pid()}")
    let a = check_with(compiler, base, "sa", "ka.w")
    let b = check_with(compiler, base, "sb", "kb.w")
    remove_tree(base)
    if a and b: print("ok")
