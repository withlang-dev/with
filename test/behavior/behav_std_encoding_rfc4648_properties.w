//! expect-stdout: ok

use std.collections
use std.encoding.base16

fn corpus(length: i64):
    let out = Vec[u8].with_capacity(length)
    var i: i64 = 0
    while i < length:
        out.push(((i * 73 + length * 29 + 17) % 256) as u8)
        i = i + 1
    out

fn assert_bytes_eq(actual: &Vec[u8], expected: &Vec[u8]):
    assert(actual.len() == expected.len())
    var i: i64 = 0
    while i < expected.len():
        assert(actual.get(i) == expected.get(i))
        i = i + 1

fn assert_base16_round_trip(data: Vec[u8]):
    let encoded = base16_encode(data)
    assert(encoded.len() == data.len() * 2)
    assert_bytes_eq(&base16_decode(encoded).unwrap(), &data)

fn test_base16_boundaries:
    var length: i64 = 0
    while length <= 257:
        assert_base16_round_trip(corpus(length))
        length = length + 1
    assert_base16_round_trip(corpus(65536))

fn test_base16_borrowed_inputs:
    let fixed = [1 as u8, 2 as u8, 3 as u8]
    let values = corpus(3)
    assert(base16_encode(fixed) == "010203")
    assert(fixed[0] == 1 as u8)
    assert(base16_encode(values) == "68B1FA")
    assert(values.len() == 3)

fn main:
    test_base16_boundaries()
    test_base16_borrowed_inputs()
    print("ok")
