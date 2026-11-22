//! expect-stdout: ok

use compiler.Link
use std.fs
use std.process
use std.string

// #2316: a package's static library built for macOS 13.0, linked into a
// program the link targeted at 11.0, made ld64.lld warn once per object.
// The link's deployment target is the newest macOS any input was built for;
// the archives `-l` names resolve to are inputs, read member by member.

fn u32le(values: List[i64]) -> str:
    var b = StringBuilder.new()
    for value in values:
        var v = value
        for _ in 0..4:
            b.push_byte((v % 256) as u8)
            v = v / 256
    b.to_str()

fn field(text: &str, width: isize) -> str:
    var out = text.to_owned()
    while out.len() < width: out = out ++ " "
    out

// A 64-bit Mach-O object whose one load command is LC_BUILD_VERSION for
// macOS (platform 1) at `minos`.
fn macho(minos: i64): u32le([0xfeedfacf, 0x0100000c, 0, 1, 1, 24, 0, 0, 0x32, 24, 1, minos, minos, 0])

// A BSD archive member: `#1/<n>` puts the n name bytes first in the body.
fn member(name: &str, body: &str) -> str:
    let size = name.len() + body.len()
    let pad = if size % 2 == 1: "\n" else: ""
    field(f"#1/{name.len()}", 16) ++ field("0", 12) ++ field("0", 6) ++ field("0", 6) ++ field("100644", 8) ++ field(f"{size}", 10) ++ "`\n" ++ name ++ body ++ pad

fn main:
    let tmp = env("TMPDIR")
    let base = (if tmp.len() > 0: tmp else: "/tmp") ++ f"/with-link-minos-{pid()}"
    let _clean = remove_tree(base)
    assert(mkdir_p(base) == 0)
    let ar = "!<arch>\n" ++ member("__.SYMDEF", "") ++ member("threads.c.o", macho(13 * 65536)) ++ member("tree.c.o", macho(12 * 65536))
    assert(write_file(base ++ "/libpkg.a", ar) == 0)
    assert(write_file(base ++ "/prog.o", macho(11 * 65536)) == 0)
    let none: List[str] = List.new()
    var libs: List[str] = List.new()
    libs.push("pkg")
    var args: List[str] = List.new()
    args.push("-L" ++ base)
    assert(link_stage_darwin_platform_version(base ++ "/prog.o", &none, &libs, &args) == "13.0")
    // Without the archive the program's own 11.0 stands.
    assert(link_stage_darwin_platform_version(base ++ "/prog.o", &none, &none, &none) == "11.0")
    let _done = remove_tree(base)
    print("ok")
