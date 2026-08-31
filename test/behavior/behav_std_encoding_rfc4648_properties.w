//! expect-stdout: ok

use std.collections
use std.string
use std.encoding.base16
use std.encoding.base32
use std.encoding.base32hex

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

fn assert_base32_round_trips(data: Vec[u8]):
    let encoded = base32_encode(data)
    let encoded_hex = base32hex_encode(data)
    assert(encoded.len() == ((data.len() + 4) / 5) * 8)
    assert(encoded_hex.len() == encoded.len())
    assert_bytes_eq(&base32_decode(encoded).unwrap(), &data)
    assert_bytes_eq(&base32hex_decode(encoded_hex).unwrap(), &data)

fn test_base32_boundary_round_trips:
    var length: i64 = 0
    while length <= 257:
        assert_base32_round_trips(corpus(length))
        length = length + 1
    assert_base32_round_trips(corpus(65536))

fn test_base32hex_ordering:
    var previous = ""
    var value = 0
    while value < 65536:
        let bytes = [(value >> 8) as u8, (value & 255) as u8]
        let current = base32hex_encode(bytes)
        let standard = base32_encode(bytes)
        let decoded = base32_decode(standard).unwrap()
        let decoded_hex = base32hex_decode(current).unwrap()
        assert(decoded.len() == 2)
        assert(decoded_hex.len() == 2)
        assert(decoded.get(0) == bytes[0])
        assert(decoded.get(1) == bytes[1])
        assert(decoded_hex.get(0) == bytes[0])
        assert(decoded_hex.get(1) == bytes[1])
        if value > 0:
            assert(string_cmp(previous, current) < 0)
        previous = current
        value = value + 1

fn test_base32_all_single_octets:
    var value = 0
    while value < 256:
        let input = [value as u8]
        let encoded = base32_encode(input)
        let encoded_hex = base32hex_encode(input)
        let decoded = base32_decode(encoded).unwrap()
        let decoded_hex = base32hex_decode(encoded_hex).unwrap()
        assert(decoded.len() == 1)
        assert(decoded_hex.len() == 1)
        assert(decoded.get(0) == value as u8)
        assert(decoded_hex.get(0) == value as u8)
        value = value + 1

fn test_base32_borrowed_inputs:
    let fixed = [1 as u8, 2 as u8, 3 as u8, 4 as u8, 5 as u8]
    let values = corpus(5)
    assert(base32_encode(fixed).len() == 8)
    assert(base32hex_encode(fixed).len() == 8)
    assert(fixed[0] == 1 as u8)
    assert(base32_encode(values).len() == 8)
    assert(base32hex_encode(values).len() == 8)
    assert(values.len() == 5)

fn main:
    test_base16_boundaries()
    test_base16_borrowed_inputs()
    test_base32_boundary_round_trips()
    test_base32hex_ordering()
    test_base32_all_single_octets()
    test_base32_borrowed_inputs()
    print("ok")
