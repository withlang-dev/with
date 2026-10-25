//! expect-stdout: ok
// #1048: a fixture that runs in-process applies only the header args that
// path knows (optimization, std, runtime, prelude, overflow). Any other was
// dropped without a word, so a fixture naming --emit-c passed without the C
// backend ever running. Such an arg now fails the fixture.
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
    let base = temp_root() ++ f"/with-behav-1048-{pid()}"
    let _clean = remove_tree(base)
    assert(mkdir_p(base) == 0)
    let fixture = base ++ "/behav_args_probe.w"
    assert(write_file(fixture, "//! expect-stdout: hi\n//! args: --no-such-flag-1048\nfn main:\n    print(\"hi\")\n") == 0)
    let ran = run_to_files(&[compiler, "test", fixture], base ++ "/stdout", base ++ "/stderr", 120000)
    let said = (read_file(base ++ "/stdout") ?? "") ++ (read_file(base ++ "/stderr") ?? "")
    if ran.code == 0 or not said.contains("--no-such-flag-1048"):
        print(f"code {ran.code}: {said}")
        exit_code(1)
    let _done = remove_tree(base)
    print("ok")
