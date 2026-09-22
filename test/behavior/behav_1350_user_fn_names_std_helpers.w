//! expect-stdout: ok

// #1350: a user top-level fn never changes a stdlib module's own
// resolution. Every name below is also declared by std.string and by the
// migrated bundle corpora (std.re, std.zl, std.tommyds, std.c_algorithms
// defs.w) and called by their own bodies. The flat merge used to DROP the
// std declaration for the user's, so std's calls bound the user's fn:
// std.string's is_alnum(33) called this is_digit and returned true, and a
// compiler that compiles std.re in-unit (stage1, --emit-c) rejected
// defs.w's own `is_digit(c)` as "not visible from this module".
use std.regex.Regex
use std.zlib

fn is_alpha(ch: u8) -> bool: ch > 1
fn is_digit(ch: u8) -> bool: ch > 1
fn is_space(ch: u8) -> bool: ch > 1
fn is_upper(ch: u8) -> bool: ch > 1
fn is_lower(ch: u8) -> bool: ch > 1
fn is_xdigit(ch: u8) -> bool: ch > 1
fn is_print(ch: u8) -> bool: ch > 1
fn to_lower(ch: u8) -> u8: ch
fn to_upper(ch: u8) -> u8: ch

fn bytes_from_str(s: str) -> Vec[u8]:
    let out: Vec[u8] = Vec.new()
    for i in 0..s.len():
        out.push(s.byte_at(i) as u8)
    out

fn main:
    // The user's declarations bind at user sites.
    assert(is_digit(5) and is_alpha(5) and to_lower(65) == 65)
    // std.string's is_alnum calls its own is_alpha/is_digit.
    assert(not is_alnum(33) and is_alnum(55) and is_alnum(97))
    // std.regex over std.re.
    assert("ab12" =~ /^[a-z]{2}\d{2}$/)
    assert(not ("a!" =~ /^\w+$/))
    let re = Regex.compile("^(\\w+)\\s+(\\d+)$").unwrap()
    assert(re.is_match("key 42") and not re.is_match("key x"))
    // std.zlib over std.zl.
    let data = bytes_from_str("hello hello hello hello")
    let packed = compress(&data).unwrap()
    let unpacked = decompress(&packed).unwrap()
    assert(unpacked.len() == data.len())
    print("ok")
