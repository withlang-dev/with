//! compress probe: raw one-shot compressor vs python3 oracle.
//! Oracle: bound formula len+len>>12+len>>14+len>>25+13, plus
//! round-trip and error codes (Z_OK=0, Z_STREAM_ERROR=-2, Z_BUF_ERROR=-5).

use std.zlib.compress
use std.zlib.uncompr
use std.zlib.defs

fn main:
    // compressBound follows the zlib formula exactly
    assert(compressBound(38 as c_ulong) == 51 as c_ulong)
    assert(compressBound(0 as c_ulong) == 13 as c_ulong)
    assert(compressBound(1000 as c_ulong) == 1013 as c_ulong)
    assert(compressBound_z(38 as c_ulong) == 51 as c_ulong)
    print("ok compress bound")

    // 200-byte source pattern
    let src: Vec[u8] = Vec.new()
    var i: i64 = 0
    while i < 200:
        src.push(((i * 31 + 7) % 256) as u8)
        i = i + 1

    // compress2 at default level, then uncompress back byte-exact
    let bound = compressBound(200 as c_ulong)
    let dest = with_alloc(bound as i64) as *mut u8
    assert(dest as i64 != 0)
    var dlen = bound
    let rc = unsafe { compress2(dest, &raw mut dlen as *mut c_ulong, src.ptr as *const u8, 200 as c_ulong, -1 as c_int) }
    assert(rc == 0)
    assert(dlen > 0)
    assert(dlen <= bound)
    print("ok compress deflate")

    let back = with_alloc(200) as *mut u8
    assert(back as i64 != 0)
    var blen = 200 as c_ulong
    let rc2 = unsafe { uncompress(back, &raw mut blen as *mut c_ulong, dest as *const u8, dlen) }
    assert(rc2 == 0)
    assert(blen == 200 as c_ulong)
    i = 0
    while i < 200:
        assert(unsafe { *((back as i64 + i) as *const u8) } == src.get(i))
        i = i + 1
    print("ok compress round-trip")

    // all levels 1..9 produce decodable output
    var level: i32 = 1
    while level <= 9:
        var ll = bound
        let r = unsafe { compress2_z(dest, &raw mut ll as *mut c_ulong, src.ptr as *const u8, 200 as c_ulong, level as c_int) }
        assert(r == 0)
        var bb = 200 as c_ulong
        let r2 = unsafe { uncompress_z(back, &raw mut bb as *mut c_ulong, dest as *const u8, ll) }
        assert(r2 == 0)
        assert(bb == 200 as c_ulong)
        level = level + 1
    print("ok compress levels")

    // invalid level is rejected without touching destLen semantics
    var bad_len = bound
    let rc3 = unsafe { compress2(dest, &raw mut bad_len as *mut c_ulong, src.ptr as *const u8, 200 as c_ulong, 10 as c_int) }
    assert(rc3 == -2)
    print("ok compress bad-level")

    // undersized destination reports Z_BUF_ERROR
    var tiny = 2 as c_ulong
    let rc4 = unsafe { compress2(dest, &raw mut tiny as *mut c_ulong, src.ptr as *const u8, 200 as c_ulong, 6 as c_int) }
    assert(rc4 == -5)
    print("ok compress tiny-dest")

    with_free(dest)
    with_free(back)
