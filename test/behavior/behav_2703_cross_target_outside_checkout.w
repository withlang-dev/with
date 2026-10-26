//! expect-stdout: ok
// #2703: a cross-target build outside a checkout finds the standard
// library's engines for that target: the compiler carries each corpus
// bundle for every target it builds for, as it carries the runtime. It
// carried them for the host and wasm32 only, so `print(1)` failed for linux
// or windows: "import module not found: 'std.engines.mlib.defs'".
use std.fs
use std.process

fn main:
    let compiler = env("WITH_TEST_COMPILER")
    assert(compiler.len() > 0)
    let tmp = env("TMPDIR")
    let base = (if tmp.len() > 0: tmp else: "/tmp") ++ f"/with-behav-2703-{pid()}"
    let _clean = remove_tree(base)
    assert(mkdir_p(base ++ "/bin") == 0)
    // A copy outside any checkout: a compiler inside one falls back to the
    // tree's lib/std sources and would pass without its embedded bundles.
    let exe = base ++ "/bin/" ++ (if compiler.ends_with(".exe"): "with.exe" else: "with")
    assert(write_file(exe, read_file(compiler) ?? "") == 0)
    assert(chmod(exe, 0o755) == 0)
    assert(write_file(base ++ "/main.w", "fn main:\n    let xs = [3, 1, 2]\n    print(xs.len())\n") == 0)
    for target in ["linux_x86_64", "linux_aarch64", "windows_x86_64", "windows_aarch64"]:
        let ran = run_to_files_in(base, &[exe, "check", "main.w", f"--target={target}"], base ++ "/run.out", base ++ "/run.err")
        if ran.code != 0:
            print(f"{target}: {read_file(base ++ \"/run.err\") ?? \"\"}")
            exit_code(1)
    let _done = remove_tree(base)
    print("ok")
