//! expect-stdout: found true
//! expect-stdout: regex true

// #1663: c_import renders <string.h>'s `memchr` as a safe wrapper over its
// byte buffer (`memchr(__s: []u8, __c)`, CImport #379), and std.re.defs
// declares `memchr` as an extern of its own, which pcre2_match calls with a
// pointer and a length. Both reach one program through the prelude's
// std.regex; the flat function table kept the wrapper, and std.re's calls
// were checked against it ("function 'memchr' expects 2 argument(s), found
// 3" in lib/std/re/pcre2_match.w) wherever std.re compiles from source. Each
// module's call binds to its own declaration: this module's to the wrapper,
// pcre2's to its extern (a literal first code unit makes pcre2 scan with it).
use c_import("string.h")
use std.regex

fn main:
    let bytes = [1u8, 2u8, 3u8]
    let hit = memchr(bytes, 3)
    print(f"found {hit != null}")
    print(f"regex {Regex.compile("xyz").unwrap().is_match("abcxyz")}")
