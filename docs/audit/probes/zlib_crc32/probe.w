//! crc32 probe: checksums vs python3-zlib oracle.
//! Oracle: crc32(b'hello')=907060870, crc32(b'123456789')=3421780262
//! (standard check value), crc 200-pattern=315481199,
//! crc 6000-pattern=4134842720, crc32(b'hello world')=222957957
//! with parts (3984718326, 980881731).

use std.zlib.crc32
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
    let c = unsafe { crc32_z(0 as c_ulong, hello.ptr as *const u8, hello.len() as c_ulong) }
    assert(c == 907060870 as c_ulong)
    print("ok crc32 hello")

    // thin c_uint wrapper forwards to crc32_z
    let c_wrap = unsafe { crc32(0 as c_ulong, hello.ptr as *const u8, hello.len() as c_uint) }
    assert(c_wrap == 907060870 as c_ulong)
    print("ok crc32 wrapper")

    // null buffer returns 0
    let n = unsafe { crc32_z(0 as c_ulong, 0 as *const u8, 5 as c_ulong) }
    assert(n == 0 as c_ulong)
    print("ok crc32 null")

    // standard check value "123456789"
    let digits = bytes_from_str("123456789")
    let chk = unsafe { crc32_z(0 as c_ulong, digits.ptr as *const u8, 9 as c_ulong) }
    assert(chk == 3421780262 as c_ulong)
    print("ok crc32 check-value")

    // streaming continuation: crc("hello ") extended with "world"
    let world = bytes_from_str("world")
    let cont = unsafe { crc32_z(3984718326 as c_ulong, world.ptr as *const u8, 5 as c_ulong) }
    assert(cont == 222957957 as c_ulong)
    print("ok crc32 streaming")

    // combine: join of checksummed parts equals whole checksum
    assert(crc32_combine(3984718326 as c_ulong, 980881731 as c_ulong, 5 as c_longlong) == 222957957 as c_ulong)
    assert(crc32_combine64(3984718326 as c_ulong, 980881731 as c_ulong, 5 as c_longlong) == 222957957 as c_ulong)
    // gen/combine round trip through an op token
    let op = crc32_combine_gen(5 as c_longlong)
    assert(crc32_combine_op(3984718326 as c_ulong, 980881731 as c_ulong, op) == 222957957 as c_ulong)
    print("ok crc32 combine")

    // table accessor: crc_table[1] is the polynomial residue
    let t1 = unsafe { get_crc_table()[1] }
    assert(t1 == 1996959894 as c_uint)
    print("ok crc32 table")

    // 200-byte pattern (i*31+7)%256 — exercises the 5-way braid fast path
    let p200: Vec[u8] = Vec.new()
    var i: i64 = 0
    while i < 200:
        p200.push(((i * 31 + 7) % 256) as u8)
        i = i + 1
    let c200 = unsafe { crc32_z(0 as c_ulong, p200.ptr as *const u8, 200 as c_ulong) }
    assert(c200 == 315481199 as c_ulong)
    print("ok crc32 200B")

    // 6000-byte i%256 pattern — multi-block braid path
    let p6000: Vec[u8] = Vec.new()
    i = 0
    while i < 6000:
        p6000.push((i % 256) as u8)
        i = i + 1
    let c6000 = unsafe { crc32_z(0 as c_ulong, p6000.ptr as *const u8, 6000 as c_ulong) }
    assert(c6000 == 4134842720 as c_ulong)
    print("ok crc32 6000B")
