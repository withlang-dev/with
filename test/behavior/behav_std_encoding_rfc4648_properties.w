//! expect-stdout: ok

use std.collections
use std.string
use std.encoding.base16
use std.encoding.base32
use std.encoding.base32hex
use std.encoding.base64
use std.encoding.base64url

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

fn assert_base64_round_trips(data: Vec[u8]):
    let encoded = base64_encode(data)
    let encoded_url = base64url_encode(data)
    assert(encoded.len() == ((data.len() + 2) / 3) * 4)
    assert(encoded_url.len() == encoded.len())
    assert_bytes_eq(&base64_decode(encoded).unwrap(), &data)
    assert_bytes_eq(&base64url_decode(encoded_url).unwrap(), &data)

fn test_base64_boundary_round_trips:
    var length: i64 = 0
    while length <= 257:
        assert_base64_round_trips(corpus(length))
        length = length + 1
    assert_base64_round_trips(corpus(65536))

fn test_base64_exhaustive_short_inputs:
    var value = 0
    while value < 256:
        let input = [value as u8]
        let encoded = base64_encode(input)
        let encoded_url = base64url_encode(input)
        let decoded = base64_decode(encoded).unwrap()
        let decoded_url = base64url_decode(encoded_url).unwrap()
        assert(decoded.len() == 1)
        assert(decoded_url.len() == 1)
        assert(decoded.get(0) == input[0])
        assert(decoded_url.get(0) == input[0])
        value = value + 1
    value = 0
    while value < 65536:
        let input = [(value >> 8) as u8, (value & 255) as u8]
        let encoded = base64_encode(input)
        let encoded_url = base64url_encode(input)
        let decoded = base64_decode(encoded).unwrap()
        let decoded_url = base64url_decode(encoded_url).unwrap()
        assert(decoded.len() == 2)
        assert(decoded_url.len() == 2)
        assert(decoded.get(0) == input[0])
        assert(decoded.get(1) == input[1])
        assert(decoded_url.get(0) == input[0])
        assert(decoded_url.get(1) == input[1])
        value = value + 1

fn test_base64_borrowed_inputs:
    let fixed = [1 as u8, 2 as u8, 3 as u8]
    let values = corpus(3)
    assert(base64_encode(fixed) == "AQID")
    assert(base64url_encode(fixed) == "AQID")
    assert(fixed[0] == 1 as u8)
    assert(base64_encode(values) == "aLH6")
    assert(base64url_encode(values) == "aLH6")
    assert(values.len() == 3)

fn main:
    test_base16_boundaries()
    test_base16_borrowed_inputs()
    test_base32_boundary_round_trips()
    test_base32hex_ordering()
    test_base32_all_single_octets()
    test_base32_borrowed_inputs()
    test_base64_boundary_round_trips()
    test_base64_exhaustive_short_inputs()
    test_base64_borrowed_inputs()
    print("ok")
