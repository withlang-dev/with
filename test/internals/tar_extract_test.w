//! expect-stdout: ok

use compiler.TarExtract
use compiler.Runtime
use std.zlib

// #1915: `with get` unpacks a package's .tar.gz itself, not with the host's
// tar. A ustar image built here — a directory, a file under the top-level
// directory the extractor strips, one whose name is a pax `path` record,
// and a symlink — is gzipped with std.zlib and unpacked.

fn octal(value: i64, width: i64) -> str:
    var digits = ""
    var v = value
    while v > 0:
        digits = f"{v % 8}" ++ digits
        v = v / 8
    while digits.len() < width - 1: digits = "0" ++ digits
    digits ++ "\0"

fn padded(text: &str, width: i64) -> str:
    var out = text.to_owned()
    while out.len() < width: out = out ++ "\0"
    out

fn header(name: &str, size: i64, kind: &str, link: &str) -> str:
    var h = padded(name, 100) ++ octal(420, 8) ++ octal(0, 8) ++ octal(0, 8) ++ octal(size, 12) ++ octal(0, 12)
    h = h ++ "        " ++ kind ++ padded(link, 100) ++ "ustar\0" ++ "00"
    h = padded(h, 512)
    var sum: i64 = 0
    for i in 0..512: sum = sum + h[i] as i64
    h.slice(0, 148) ++ octal(sum, 7) ++ " " ++ h.slice(156, 512)

fn entry(name: &str, kind: &str, body: &str, link: &str) -> str:
    padded(header(name, body.len(), kind, link) ++ body, 512 + ((body.len() + 511) / 512) * 512)

fn bytes(text: &str) -> List[u8]:
    let out: List[u8] = List.new()
    for i in 0..text.len(): out.push(text[i])
    out

fn text(v: &List[u8]) -> str:
    var out = ""
    for i in 0..v.len() as i32: out = out ++ str_from_byte(v[i] as i32)
    out

extern fn str_from_byte(b: i32) -> str

fn main:
    let long_name = "pkg/include/" ++ "deep/".repeat(30) ++ "header.h"
    // A pax record's length counts its own digits.
    let body = " path=" ++ long_name ++ "\n"
    var total = body.len() + 1
    while f"{total}".len() + body.len() != total: total = f"{total}".len() + body.len()
    let pax = f"{total}" ++ body
    var tar = entry("pkg/", "5", "", "")
    tar = tar ++ entry("pkg/lib/libdemo.a", "0", "archive bytes\n", "")
    tar = tar ++ entry("pkg/PaxHeaders/x", "x", pax, "")
    tar = tar ++ entry("ignored-name", "0", "#define DEMO 1\n", "")
    tar = tar ++ entry("pkg/lib/libdemo.link.a", "2", "", "libdemo.a")
    tar = tar ++ padded("", 1024)
    let tmp = runtime_getenv("TMPDIR") ++ f"/with-tar-extract-{runtime_getpid()}"
    let _clean = runtime_remove_tree(tmp)
    assert(runtime_mkdir_p(tmp) == 0)
    let gz = match compress_gzip(&bytes(tar)):
        .Ok(v) => text(&v)
        .Err(_) => ""
    assert(gz.len() > 0)
    assert(runtime_write_file(tmp ++ "/demo.tar.gz", gz) == 0)
    assert(tar_gz_extract(tmp ++ "/demo.tar.gz", tmp ++ "/out", 1) == "")
    assert(runtime_read_file(tmp ++ "/out/lib/libdemo.a") == "archive bytes\n")
    assert(runtime_read_file(tmp ++ "/out/" ++ long_name.slice(4, long_name.len())) == "#define DEMO 1\n")
    assert(runtime_read_file(tmp ++ "/out/lib/libdemo.link.a") == "archive bytes\n")
    // A name that climbs out of the destination is refused.
    let evil = entry("pkg/../../escape", "0", "x", "") ++ padded("", 1024)
    let evil_gz = match compress_gzip(&bytes(evil)):
        .Ok(v) => text(&v)
        .Err(_) => ""
    assert(runtime_write_file(tmp ++ "/evil.tar.gz", evil_gz) == 0)
    assert(tar_gz_extract(tmp ++ "/evil.tar.gz", tmp ++ "/evil", 1).starts_with("an unsafe path"))
    let _done = runtime_remove_tree(tmp)
    print("ok")
