//! expect-stdout: ok

// #1362: a user fn named like a bundle interface fn keeps its own signature.
// Every non-generic fn the migrated corpora's defs.w export (std.re,
// std.zl; std.tommyds and std.c_algorithms export the same helper set) is
// declared here with a different signature. The interface declaration of
// the same name used to share the user's flat symbol: analyze audit:all
// reported "finalized source type or LLVM parameter disagrees with FnAbi",
// and codegen failed ("declaration check_match has no finalized FnAbi
// signature"). The interface fn is displaced to its module-qualified
// identity; regex (std.re) and zlib (std.zl) still call their own.
// behav_1362_bundle_interface_collision_audit runs audit:all on this file.
use std.collections.HashMap
use std.zlib

fn is_alpha(ch: u8) -> bool: ch == 1
fn is_digit(ch: u8) -> bool: ch == 2
fn is_space(ch: u8) -> bool: ch == 3
fn is_alnum(ch: u8) -> bool: ch == 4
fn is_upper(ch: u8) -> bool: ch == 5
fn is_lower(ch: u8) -> bool: ch == 6
fn is_xdigit(ch: u8) -> bool: ch == 7
fn is_print(ch: u8) -> bool: ch == 8
fn to_lower(ch: u8) -> u8: ch + 1
fn to_upper(ch: u8) -> u8: ch + 2
fn __ci_unreachable() -> i32: 11
fn u128_mul_would_overflow(a: i32, b: i32) -> i32: a * b
fn stringify(n: i32) -> str: f"<{n}>"
fn Assert(n: i32) -> i32: n + 20
fn Trace(n: i32) -> i32: n + 21
fn Tracev(n: i32) -> i32: n + 22
fn Tracevv(n: i32) -> i32: n + 23
fn Tracec(n: i32) -> i32: n + 24
fn Tracecv(n: i32) -> i32: n + 25
fn check_match(n: i32) -> i32: n + 26

fn bytes_from_str(s: &str) -> Vec[u8]:
    let out: Vec[u8] = Vec.new()
    for i in 0..s.len():
        out.push(s.byte_at(i) as u8)
    out

fn main:
    assert(is_alpha(1) and is_digit(2) and is_space(3) and is_alnum(4))
    assert(is_upper(5) and is_lower(6) and is_xdigit(7) and is_print(8))
    assert(to_lower(1) == 2 and to_upper(1) == 3 and __ci_unreachable() == 11)
    assert(u128_mul_would_overflow(6, 7) == 42 and stringify(3) == "<3>")
    assert(Assert(0) == 20 and Trace(0) == 21 and Tracev(0) == 22 and Tracevv(0) == 23)
    assert(Tracec(0) == 24 and Tracecv(0) == 25 and check_match(0) == 26)
    assert("ab12" =~ /^[a-z]{2}\d{2}$/)
    assert(not ("a!" =~ /^\w+$/))
    let data = bytes_from_str("hello hello hello hello")
    let unpacked = decompress(&compress(&data).unwrap()).unwrap()
    assert(unpacked.len() == data.len())
    var m: HashMap[i32, i32] = HashMap.new()
    m.insert(1, 2)
    assert(m.contains(1))
    print("ok")
