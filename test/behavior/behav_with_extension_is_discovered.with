//! expect-stdout: ok
// With source files are named `.with` (Eric, 2026-11-21). Where the
// toolchain finds files itself it finds `name.with`, and during the change
// of extension `name.w` too: a module from `use`, the tests in a directory.
// A directory holding both spellings of one module is an error, since an
// edit to one of them would go unread. A file the user names is source
// whatever it is called, so the importing file here is `main.potato`.
use std.fs
use std.process

fn temp_root() -> str:
    let tmpdir = env("TMPDIR")
    if tmpdir.len() > 0: return tmpdir
    let temp = env("TEMP")
    if temp.len() > 0: return temp
    "/tmp"

fn ran(compiler: &str, base: &str, args: &List[str]) -> str:
    let argv = [compiler.to_owned()]
    for a in args: argv.push(a.to_owned())
    let done = run_to_files_in(base, &argv, base ++ "/stdout", base ++ "/stderr")
    f"{done.code}|" ++ (read_file(base ++ "/stdout") ?? "") ++ (read_file(base ++ "/stderr") ?? "")

fn expect(what: &str, got: &str, code: &str, text: &str):
    if not got.starts_with(code ++ "|") or not got.contains(text):
        print(what ++ ": " ++ got)
        exit_code(1)

fn main:
    let compiler = env("WITH_TEST_COMPILER")
    assert(compiler.len() > 0)
    let base = temp_root() ++ f"/with-behav-ext-discovery-{pid()}"
    let _clean = remove_tree(base)
    assert(mkdir_p(base ++ "/tests") == 0)
    assert(write_file(base ++ "/newer.with", "pub fn newer() -> str: \"from newer.with\"\n") == 0)
    assert(write_file(base ++ "/older.w", "pub fn older() -> str: \"from older.w\"\n") == 0)
    assert(write_file(base ++ "/main.potato", "use newer\nuse older\nprint(newer())\nprint(older())\n") == 0)
    let both = ran(compiler, base, ["main.potato"])
    expect("use finds .with", both, "0", "from newer.with")
    expect("use finds .w", both, "0", "from older.w")
    // The tests in a directory: both spellings are found.
    assert(write_file(base ++ "/tests/first.with", "//! expect-stdout: one\nprint(\"one\")\n") == 0)
    assert(write_file(base ++ "/tests/second.w", "//! expect-stdout: two\nprint(\"two\")\n") == 0)
    assert(write_file(base ++ "/tests/notes.txt", "not a test\n") == 0)
    expect("test directory", ran(compiler, base, ["test", "tests"]), "0", "2 files ok")
    // One module, one file.
    assert(write_file(base ++ "/newer.w", "pub fn newer() -> str: \"stale\"\n") == 0)
    let clash = ran(compiler, base, ["main.potato"])
    if clash.starts_with("0|") or not clash.contains("module 'newer' is both") or not clash.contains("newer.with") or not clash.contains("newer.w'"):
        print("both spellings: " ++ clash)
        exit_code(1)
    let _done = remove_tree(base)
    print("ok")
