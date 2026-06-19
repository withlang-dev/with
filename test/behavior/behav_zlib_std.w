//! expect-stdout: ok

use std.zlib

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

fn test_round_trip:
    let original = bytes_from_str("hello hello hello hello hello with zlib")
    let compressed = compress(&original).unwrap()
    assert(compressed.len() > 0)
    assert(compressed.len() < original.len())
    let restored = decompress(&compressed).unwrap()
    assert_bytes_eq(&restored, &original)

fn test_levels_and_errors:
    let original = bytes_from_str("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")
    let fast = compress_level(&original, 1).unwrap()
    let best = compress_level(&original, 9).unwrap()
    assert(decompress(&fast).unwrap().len() == original.len())
    assert(decompress(&best).unwrap().len() == original.len())

    assert(compress_level(&original, 10).is_err())
    assert(decompress_with_limit(&fast, 1).is_err())
    assert(decompress(&original).is_err())

fn main:
    test_round_trip()
    test_levels_and_errors()
    print("ok")
