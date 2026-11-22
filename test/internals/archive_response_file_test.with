//! expect-stdout: ok

use Archive
use std.fs

// #2084: `with __ar qc libSDL3.a @CMakeFiles\SDL3-static.rsp` — CMake writes
// an archive's members to a response file when the command line would be too
// long (SDL's 268 objects on Windows). The archiver read `@…rsp` as a member
// and failed "cannot read member"; it now reads the members the file names,
// by the host's quoting as llvm-ar does.

fn eq(got: &List[str], want: &List[str]) -> bool:
    if got.len() != want.len(): return false
    for i in 0..got.len() as i32:
        if got[i] != want[i]: return false
    true

fn main:
    // Whitespace of every kind separates; quotes group and are dropped.
    let plain = ar_tokenize_response("a.o  b.o\n\"c d.o\"\r\n\te.o\n", false)
    assert(eq(&plain, &["a.o", "b.o", "c d.o", "e.o"]))

    // GNU: a backslash escapes the next character; single quotes quote.
    let gnu = ar_tokenize_response("dir\\ with\\ space/a.o 'b c.o' \"q\\\"x.o\"", false)
    assert(eq(&gnu, &["dir with space/a.o", "b c.o", "q\"x.o"]))

    // Windows: a backslash is a path character, and escapes only a quote.
    let win = ar_tokenize_response("CMakeFiles\\SDL3-static.dir\\src\\SDL_error.c.obj \"C:\\Program Files\\x.obj\" it's.obj", true)
    assert(eq(&win, &["CMakeFiles\\SDL3-static.dir\\src\\SDL_error.c.obj", "C:\\Program Files\\x.obj", "it's.obj"]))

    // An @file argument is replaced, in place, by what the file holds.
    let dir = "out/test-scratch/archive_response_file"
    assert(mkdir_p(dir) == 0)
    assert(write_file(dir ++ "/members.rsp", "one.o two.o\nthree.o\n") == 0)
    let expanded = ar_expand_response_args(&["first.o", "@" ++ dir ++ "/members.rsp", "last.o"], false, 0)
    assert(expanded.ok)
    assert(eq(&expanded.args, &["first.o", "one.o", "two.o", "three.o", "last.o"]))

    // A response file that cannot be read is an error, never a member.
    let missing = ar_expand_response_args(&["@" ++ dir ++ "/absent.rsp"], false, 0)
    assert(not missing.ok)
    print("ok")
