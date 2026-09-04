//! uncompr probe: raw one-shot decompressor vs python3 oracle.
//! Oracle: python3 zlib.compress of the 38-byte fixture (26 bytes),
//! plus error codes (Z_DATA_ERROR=-3, Z_BUF_ERROR=-5).

use std.zlib.uncompr
use std.zlib.defs

fn bytes_from_str(s: str) -> Vec[u8]:
    let out: Vec[u8] = Vec.new()
    var i: i64 = 0
    while i < s.len():
        out.push(s.byte_at(i) as u8)
        i = i + 1
    out

// python3: zlib.compress(b'hello hello hello hello hello with zlib')
fn py_src() -> Vec[u8]:
    let out: Vec[u8] = Vec.new()
    out.push(120 as u8)
    out.push(156 as u8)
    out.push(203 as u8)
    out.push(72 as u8)
    out.push(205 as u8)
    out.push(201 as u8)
    out.push(201 as u8)
    out.push(87 as u8)
    out.push(200 as u8)
    out.push(192 as u8)
    out.push(65 as u8)
    out.push(150 as u8)
    out.push(103 as u8)
    out.push(150 as u8)
    out.push(100 as u8)
    out.push(40 as u8)
    out.push(84 as u8)
    out.push(229 as u8)
    out.push(100 as u8)
    out.push(38 as u8)
    out.push(1 as u8)
    out.push(0 as u8)
    out.push(35 as u8)
    out.push(100 as u8)
    out.push(14 as u8)
    out.push(146 as u8)
    out

fn main:
    let src = py_src()
    let expected = bytes_from_str("hello hello hello hello hello with zlib")

    // python bytes decode to the exact original
    let dest = with_alloc(1024) as *mut u8
    assert(dest as i64 != 0)
    var dlen = 1024 as c_ulong
    let rc = unsafe { uncompress(dest, &raw mut dlen as *mut c_ulong, src.ptr as *const u8, src.len() as c_ulong) }
    assert(rc == 0)
    assert(dlen == 39 as c_ulong)
    var i: i64 = 0
    while i < 39:
        assert(unsafe { *((dest as i64 + i) as *const u8) } == expected.get(i))
        i = i + 1
    print("ok uncompress python-bytes")

    // uncompress2 reports consumed input and produced output lengths
    var dlen2 = 1024 as c_ulong
    var used = src.len() as c_ulong
    let rc2 = unsafe { uncompress2(dest, &raw mut dlen2 as *mut c_ulong, src.ptr as *const u8, &raw mut used as *mut c_ulong) }
    assert(rc2 == 0)
    assert(dlen2 == 39 as c_ulong)
    assert(used == 26 as c_ulong)
    print("ok uncompress2 lens")

    // plain text is not a zlib stream
    var dlen3 = 1024 as c_ulong
    let rc3 = unsafe { uncompress_z(dest, &raw mut dlen3 as *mut c_ulong, expected.ptr as *const u8, expected.len() as c_ulong) }
    assert(rc3 == -3)
    print("ok uncompress garbage")

    // one-byte destination cannot hold 38 bytes of output
    var dlen4 = 1 as c_ulong
    let rc4 = unsafe { uncompress(dest, &raw mut dlen4 as *mut c_ulong, src.ptr as *const u8, src.len() as c_ulong) }
    assert(rc4 == -5)
    print("ok uncompress tiny-dest")

    with_free(dest)
