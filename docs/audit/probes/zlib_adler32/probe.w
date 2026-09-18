//! adler32 probe: checksums vs python3-zlib oracle.
//! Oracle: adler32(b'hello')=103547413, adler32(b'A')=4325442,
//! adler32 200-pattern=720986941, adler32 6000-pattern=1525910894,
//! adler32(b'hello world')=436929629 with parts (140575285, 111542825).

use std.zlib.adler32
use std.zlib.defs

fn bytes_from_str(s: str) -> Vec[u8]:
    let out: Vec[u8] = Vec.new()
    var i: i64 = 0
    while i < s.len():
        out.push(s.byte_at(i) as u8)
        i = i + 1
    out

fn main:
    let hello = bytes_from_str("hello")
    let a = unsafe { adler32_z(1 as c_ulong, hello.ptr as *const u8, hello.len() as c_ulong) }
    assert(a == 103547413 as c_ulong)
    print("ok adler32 hello")

    // thin c_uint wrapper forwards to adler32_z
    let a_wrap = unsafe { adler32(1 as c_ulong, hello.ptr as *const u8, hello.len() as c_uint) }
    assert(a_wrap == 103547413 as c_ulong)
    print("ok adler32 wrapper")

    // single-byte early path (len == 1, no mod deferral)
    let one = bytes_from_str("A")
    let a1 = unsafe { adler32_z(1 as c_ulong, one.ptr as *const u8, 1 as c_ulong) }
    assert(a1 == 4325442 as c_ulong)
    print("ok adler32 single-byte")

    // null buffer returns the initial value 1
    let n = unsafe { adler32_z(1 as c_ulong, 0 as *const u8, 0 as c_ulong) }
    assert(n == 1 as c_ulong)
    print("ok adler32 null")

    // streaming continuation: adler("hello ") extended with "world"
    let world = bytes_from_str("world")
    let cont = unsafe { adler32_z(140575285 as c_ulong, world.ptr as *const u8, 5 as c_ulong) }
    assert(cont == 436929629 as c_ulong)
    print("ok adler32 streaming")

    // combine: join of checksummed parts equals whole checksum
    assert(adler32_combine(140575285 as c_ulong, 111542825 as c_ulong, 5 as c_longlong) == 436929629 as c_ulong)
    assert(adler32_combine64(140575285 as c_ulong, 111542825 as c_ulong, 5 as c_longlong) == 436929629 as c_ulong)
    // negative len2 is rejected with 0xffffffff
    assert(adler32_combine(1 as c_ulong, 1 as c_ulong, -1 as c_longlong) == 4294967295 as c_ulong)
    print("ok adler32 combine")

    // 200-byte pattern (i*31+7)%256 — short-block path
    let p200: Vec[u8] = Vec.new()
    var i: i64 = 0
    while i < 200:
        p200.push(((i * 31 + 7) % 256) as u8)
        i = i + 1
    let a200 = unsafe { adler32_z(1 as c_ulong, p200.ptr as *const u8, 200 as c_ulong) }
    assert(a200 == 720986941 as c_ulong)
    print("ok adler32 200B")

    // 6000-byte i%256 pattern — forces the NMAX=5552 unrolled loop
    let p6000: Vec[u8] = Vec.new()
    i = 0
    while i < 6000:
        p6000.push((i % 256) as u8)
        i = i + 1
    let a6000 = unsafe { adler32_z(1 as c_ulong, p6000.ptr as *const u8, 6000 as c_ulong) }
    assert(a6000 == 1525910894 as c_ulong)
    print("ok adler32 6000B")
