//! expect-debug-alloc: leak count=0
//! expect-stdout: 12
//! expect-stdout: 0
//! expect-stdout: 5

// `??` decomposes its subject the way `?` does (#605/#606): on the success
// path the payload moves out and the Result/Option temporary must not reach
// its scope-exit drop, or the enum's variant-aware drop glue frees the str the
// result now owns. That was a double free in std.build's generated gunzip
// helper (`read_file(p) ?? ""` then `bytes_from_str(input)`): the payload's
// buffer was freed by the Result drop, reused by a Vec, freed by the dangling
// str, and freed again by the Vec. On the default path nothing moved out, so
// the subject (an Err payload, or nothing) is dropped there, once.
use std.fs
use std.builtins.print_i64

fn bytes_from_str(data: str) -> Vec[u8]:
    let out: Vec[u8] = Vec.new()
    var i: i64 = 0
    while i < data.len():
        out.push(data[i])
        i = i + 1
    out

fn main:
    let path = "out/tmp/da_coalesce_result_payload_owned.txt"
    let _mk = mkdir_p("out/tmp")
    let _w = write_file(path, "file content")
    // Ok path: the payload moves into `input`, then into the callee.
    let input = read_file(path) ?? ""
    let bytes = bytes_from_str(input)
    print_i64(bytes.len())
    // Err path: the IoError payload drops on the default path, once.
    let missing = read_file("out/tmp/does-not-exist.txt") ?? ""
    print_i64(missing.len())
    // Option subject with an owned payload.
    let some: Option[str] = Some("hello" ++ "")
    let word = some ?? ""
    print_i64(word.len())
    let _rm = remove_file(path)
