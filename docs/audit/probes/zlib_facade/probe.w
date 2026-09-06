//! Facade probe: std.zlib safe API vs python3-zlib oracle.
//! Oracle: python3 -c zlib.compress / compressobj(wbits=31) of the 38-byte
//! string below, plus error-contract checks.

use std.zlib
use std.builtins.print_i64

fn bytes_from_str(s: str) -> Vec[u8]:
    let out: Vec[u8] = Vec.new()
    var i: i64 = 0
    while i < s.len():
        out.push(s.byte_at(i) as u8)
        i = i + 1
    out

fn assert_bytes_eq(actual: &Vec[u8], expected: &Vec[u8]):
    assert(actual.len() == expected.len())
    var i: i64 = 0
    while i < expected.len():
        assert(actual.get(i) == expected.get(i))
        i = i + 1

fn fixture_text() -> Vec[u8]:
    bytes_from_str("hello hello hello hello hello with zlib")

// python3: zlib.compress(fixture_text()) — 26 bytes, level 6
fn py_zlib_fixture() -> Vec[u8]:
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

// python3: compressobj(6, DEFLATED, 31).compress(t)+flush() — 38 bytes gzip
fn py_gzip_fixture() -> Vec[u8]:
    let out: Vec[u8] = Vec.new()
    out.push(31 as u8)
    out.push(139 as u8)
    out.push(8 as u8)
    out.push(0 as u8)
    out.push(0 as u8)
    out.push(0 as u8)
    out.push(0 as u8)
    out.push(0 as u8)
    out.push(0 as u8)
    out.push(3 as u8)
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
    out.push(118 as u8)
    out.push(0 as u8)
    out.push(186 as u8)
    out.push(255 as u8)
    out.push(39 as u8)
    out.push(0 as u8)
    out.push(0 as u8)
    out.push(0 as u8)
    out

fn dump_bytes(tag: str, data: &Vec[u8]):
    print(tag)
    var i: i64 = 0
    while i < data.len():
        print_i64(data.get(i) as i64)
        i = i + 1
    print("END")

fn main:
    let original = fixture_text()
    assert(original.len() == 39)

    // zlib round trip through the facade
    let compressed = compress(&original).unwrap()
    assert(compressed.len() > 0)
    assert(compressed.len() < original.len())
    let restored = decompress(&compressed).unwrap()
    assert_bytes_eq(&restored, &original)
    print("ok facade round-trip")

    // python-produced zlib stream must decode here (format interop)
    let py_restored = decompress(&py_zlib_fixture()).unwrap()
    assert_bytes_eq(&py_restored, &original)
    print("ok facade python-zlib interop")

    // gzip round trip + magic bytes
    let gz = compress_gzip(&original).unwrap()
    assert(gz.get(0) == 31 as u8)
    assert(gz.get(1) == 139 as u8)
    assert_bytes_eq(&decompress_gzip(&gz).unwrap(), &original)
    print("ok facade gzip round-trip")

    // python-produced gzip stream must decode here
    assert_bytes_eq(&decompress_gzip(&py_gzip_fixture()).unwrap(), &original)
    print("ok facade python-gzip interop")

    // levels
    let fast = compress_level(&original, 1).unwrap()
    let best = compress_level(&original, 9).unwrap()
    assert(decompress(&fast).unwrap().len() == 39)
    assert(decompress(&best).unwrap().len() == 39)
    print("ok facade levels")

    // empty input compresses to a valid stream and back
    let empty: Vec[u8] = Vec.new()
    let empty_rt = decompress(&compress(&empty).unwrap()).unwrap()
    assert(empty_rt.len() == 0)
    print("ok facade empty")

    // error contract
    assert(compress_level(&original, 10).is_err())
    assert(compress_level(&original, -2).is_err())
    assert(decompress(&original).is_err())
    assert(decompress(&empty).is_err())
    assert(decompress_with_limit(&fast, 1).is_err())
    assert(decompress_with_limit(&fast, -1).is_err())
    assert(decompress_gzip(&compressed).is_err())
    assert(decompress(&gz).is_err())
    print("ok facade errors")

    // raw bytes for the reverse direction (shell feeds these to python3)
    dump_bytes("ZLIB-BYTES", &compressed)
    dump_bytes("GZIP-BYTES", &gz)
