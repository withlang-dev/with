//! expect-stdout: olléh cba []
//! expect-stdout: ok
// #960: `str.reverse()` reverses the characters, as `rev` does, keeping a
// UTF-8 sequence whole; a one-liner sorts a List of lines (coreutils sort),
// its generated header importing std.algorithms. Neither existed: "unknown
// method 'reverse'", and "unknown method 'sort' for type 'List[str]'" in a
// one-liner.
use std.fs
use std.process

fn temp_root() -> str:
    let tmpdir = env("TMPDIR")
    if tmpdir.len() > 0: return tmpdir
    let temp = env("TEMP")
    if temp.len() > 0: return temp
    "/tmp"

fn main:
    print(f"{"héllo".reverse()} {"abc".reverse()} [{"".reverse()}]")
    let compiler = env("WITH_TEST_COMPILER")
    assert(compiler.len() > 0)
    let base = temp_root() ++ f"/with-behav-960-{pid()}"
    let _clean = remove_tree(base)
    assert(mkdir_p(base) == 0)
    let ran = run_to_files(&[compiler, "-e", "var v: List[str] = [\"b\", \"c\", \"a\"]", "-e", "v.sort()", "-e", "print(v.join(\",\"))"], base ++ "/out", base ++ "/err", 120000)
    let raw = read_file(base ++ "/out") ?? ""
    if ran.code != 0 or raw.trim() != "a,b,c":
        print(f"code {ran.code} out [{raw}] err [{read_file(base ++ "/err") ?? ""}]")
        exit_code(1)
    let _done = remove_tree(base)
    print("ok")
