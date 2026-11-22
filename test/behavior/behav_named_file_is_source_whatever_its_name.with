//! expect-stdout: ok
// The extension governs what the toolchain discovers, never what a user
// names (Eric, 2026-11-21). A file named on the command line is With source
// whatever it is called: an unknown extension, none, a path with a slash, a
// script that begins with a `#!` line. A bare word with no dot and no slash
// stays a subcommand lookup, and when a file of that name is there the error
// says how to run it. An output name is the file's name up to its last dot.
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
    let base = temp_root() ++ f"/with-behav-named-file-{pid()}"
    let _clean = remove_tree(base)
    assert(mkdir_p(base) == 0)
    assert(write_file(base ++ "/hello.potato", "print(\"potato\")\n") == 0)
    assert(write_file(base ++ "/plain", "print(\"plain\")\n") == 0)
    assert(write_file(base ++ "/script", "#!/usr/bin/env with\nprint(\"script\")\n") == 0)
    assert(write_file(base ++ "/wrong", "#!/usr/bin/env with\nprint(\"x\")\nlet n: i32 = \"text\"\n") == 0)
    // An unknown extension, under the bare form and every command.
    expect("bare potato", ran(compiler, base, ["hello.potato"]), "0", "potato")
    expect("run potato", ran(compiler, base, ["run", "hello.potato"]), "0", "potato")
    expect("check potato", ran(compiler, base, ["check", "hello.potato"]), "0", "")
    expect("build potato", ran(compiler, base, ["build", "hello.potato"]), "0", "")
    assert(file_exists(base ++ "/out/hello") or file_exists(base ++ "/out/hello.exe"))
    // No extension: a path with a slash is a file; a bare word is not.
    expect("slash plain", ran(compiler, base, ["./plain"]), "0", "plain")
    expect("run plain", ran(compiler, base, ["run", "plain"]), "0", "plain")
    expect("check plain", ran(compiler, base, ["check", "plain"]), "0", "")
    expect("build plain", ran(compiler, base, ["build", "plain"]), "0", "")
    assert(file_exists(base ++ "/out/plain") or file_exists(base ++ "/out/plain.exe"))
    let bare = ran(compiler, base, ["plain"])
    if bare.starts_with("0|") or not bare.contains("unknown command 'plain'") or not bare.contains("run it as `with ./plain` or `with run plain`"):
        print("bare word: " ++ bare)
        exit_code(1)
    // A `#!` first line is not the program's; line numbers stay the file's.
    expect("script", ran(compiler, base, ["./script"]), "0", "script")
    expect("script error line", ran(compiler, base, ["check", "wrong"]), "1", "wrong:3:")
    let _done = remove_tree(base)
    print("ok")
