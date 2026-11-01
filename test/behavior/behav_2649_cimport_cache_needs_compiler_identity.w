//! expect-stdout: ok
//! skip-on: windows the c_import cache lives under $HOME, which a Windows shell need not set
// #2649: a compiler that names itself (its stamped self id, or its image) uses
// the c_import cache; one that cannot name itself translates without it. The
// key took "" when argv[0] did not resolve, so every compiler in that state
// shared one translation.
use std.fs
use std.process

fn main:
    let compiler = env("WITH_TEST_COMPILER")
    assert(compiler.len() > 0)
    let tmp = env("TMPDIR")
    let base = (if tmp.len() > 0: tmp else: "/tmp") ++ f"/with-behav-2649-{pid()}"
    let _clean = remove_tree(base)
    assert(mkdir_p(base ++ "/home") == 0)
    assert(write_file(base ++ "/k.h", "#define ANSWER 42\n") == 0)
    assert(write_file(base ++ "/main.w", "use c_import(\"" ++ base ++ "/k.h\")\nfn main:\n    print(ANSWER)\n") == 0)
    let _home = set_env("HOME", base ++ "/home")
    let ran = run_to_files(&[compiler, "check", base ++ "/main.w"], base ++ "/run.out", base ++ "/run.err", 1800000)
    // A failure says what the compiler said: the lane's capture is all a
    // release runner leaves behind (the check failed on the linux-x86_64 and
    // linux-aarch64 release lanes with nothing but the assertion, v0.16.0.4).
    if ran.code != 0:
        eprint(f"check exited {ran.code}; stderr:\n" ++ (read_file(base ++ "/run.err") ?? ""))
    assert(ran.code == 0)
    let cached = list_files_text(base ++ "/home/.cache/with/c_import")
    if not cached.contains(".w"):
        eprint("no translation under " ++ base ++ "/home/.cache/with/c_import; entries: " ++ cached)
    assert(cached.contains(".w"))
    let _done = remove_tree(base)
    print("ok")
