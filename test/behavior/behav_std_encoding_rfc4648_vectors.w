//! expect-stdout: ok

use std.collections
use std.encoding.base16
use std.string
use std.encoding.base32
use std.encoding.base32hex
use std.encoding.base64
use std.encoding.base64url

fn ascii_bytes(text: &str):
    let out = Vec[u8].with_capacity(text.len())
    var i: i64 = 0
    while i < text.len():
        out.push(text.byte_at(i) as u8)
        i = i + 1
    out

fn assert_bytes_eq(actual: &Vec[u8], expected: &Vec[u8]):
    assert(actual.len() == expected.len())
    var i: i64 = 0
    while i < expected.len():
        assert(actual.get(i) == expected.get(i))
        i = i + 1

fn assert_base16_vector(input: &str, encoded: &str):
    let bytes = ascii_bytes(input)
    assert(base16_encode(bytes) == encoded)
    assert_bytes_eq(&base16_decode(encoded).unwrap(), &bytes)

fn test_base16_vectors:
    assert_base16_vector("", "")
    assert_base16_vector("f", "66")
    assert_base16_vector("fo", "666F")
    assert_base16_vector("foo", "666F6F")
    assert_base16_vector("foob", "666F6F62")
    assert_base16_vector("fooba", "666F6F6261")
    assert_base16_vector("foobar", "666F6F626172")

fn test_base16_alphabet_and_case:
    let alphabet = "0123456789ABCDEF"
    var value: i32 = 0
    while value < 16:
        let input = [(value << 4) as u8]
        assert(base16_encode(input).byte_at(0) == alphabet.byte_at(value as i64))
        let low_input = [value as u8]
        let encoded = base16_encode(low_input)
        assert(encoded.byte_at(0) == 48)
        assert(encoded.byte_at(1) == alphabet.byte_at(value as i64))
        value = value + 1
    assert(base16_decode("aa").unwrap().get(0) == 170 as u8)
    assert(base16_decode("bb").unwrap().get(0) == 187 as u8)
    assert(base16_decode("cc").unwrap().get(0) == 204 as u8)
    assert(base16_decode("dd").unwrap().get(0) == 221 as u8)
    assert(base16_decode("ee").unwrap().get(0) == 238 as u8)
    assert(base16_decode("ff").unwrap().get(0) == 255 as u8)
    let expected = ascii_bytes("foo")
    let decoded = base16_decode("666f6f").unwrap()
    assert_bytes_eq(&decoded, &expected)
    assert(base16_encode(decoded) == "666F6F")

fn test_base16_all_octets:
    var value: i32 = 0
    while value < 256:
        let input = [value as u8]
        let encoded = base16_encode(input)
        let decoded = base16_decode(encoded).unwrap()
        assert(encoded.len() == 2)
        assert(decoded.len() == 1)
        assert(decoded.get(0) == value as u8)
        value = value + 1

fn assert_base32_vector(input: &str, encoded: &str, encoded_hex: &str):
    let bytes = ascii_bytes(input)
    assert(base32_encode(bytes) == encoded)
    assert(base32hex_encode(bytes) == encoded_hex)
    assert_bytes_eq(&base32_decode(encoded).unwrap(), &bytes)
    assert_bytes_eq(&base32hex_decode(encoded_hex).unwrap(), &bytes)

fn ascii_lower(text: &str):
    var out = StringBuilder.with_capacity(text.len())
    var i: i64 = 0
    while i < text.len():
        let byte = text.byte_at(i)
        out.push_byte((if byte >= 65 and byte <= 90: byte + 32 else: byte) as u8)
        i = i + 1
    out.to_str()

fn test_base32_vectors:
    assert_base32_vector("", "", "")
    assert_base32_vector("f", "MY======", "CO======")
    assert_base32_vector("fo", "MZXQ====", "CPNG====")
    assert_base32_vector("foo", "MZXW6===", "CPNMU===")
    assert_base32_vector("foob", "MZXW6YQ=", "CPNMUOG=")
    assert_base32_vector("fooba", "MZXW6YTB", "CPNMUOJ1")
    assert_base32_vector("foobar", "MZXW6YTBOI======", "CPNMUOJ1E8======")

fn test_base32_alphabets:
    let alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
    let alphabet_hex = "0123456789ABCDEFGHIJKLMNOPQRSTUV"
    var value: i32 = 0
    while value < 32:
        let input = [(value << 3) as u8]
        let encoded = base32_encode(input)
        let encoded_hex = base32hex_encode(input)
        let lower = ascii_lower(encoded)
        let lower_hex = ascii_lower(encoded_hex)
        assert(encoded.byte_at(0) == alphabet.byte_at(value as i64))
        assert(encoded_hex.byte_at(0) == alphabet_hex.byte_at(value as i64))
        assert(base32_decode(lower).unwrap().get(0) == input[0])
        assert(base32hex_decode(lower_hex).unwrap().get(0) == input[0])
        value = value + 1

fn test_base32_terminal_quanta_and_case:
    let one = ascii_bytes("f")
    let two = ascii_bytes("fo")
    let three = ascii_bytes("foo")
    let four = ascii_bytes("foob")
    let five = ascii_bytes("fooba")
    assert(base32_encode(one).ends_with("======"))
    assert(base32_encode(two).ends_with("===="))
    assert(base32_encode(three).ends_with("==="))
    assert(base32_encode(four).ends_with("="))
    assert(not base32_encode(five).contains("="))
    assert_bytes_eq(&base32_decode("mzxw6===").unwrap(), &three)
    assert_bytes_eq(&base32hex_decode("cpnmu===").unwrap(), &three)
    let decoded = base32_decode("mzxw6===").unwrap()
    let decoded_hex = base32hex_decode("cpnmu===").unwrap()
    assert(base32_encode(decoded) == "MZXW6===")
    assert(base32hex_encode(decoded_hex) == "CPNMU===")

fn assert_base64_vector(input: &str, encoded: &str):
    let bytes = ascii_bytes(input)
    assert(base64_encode(bytes) == encoded)
    assert(base64url_encode(bytes) == encoded)
    assert_bytes_eq(&base64_decode(encoded).unwrap(), &bytes)
    assert_bytes_eq(&base64url_decode(encoded).unwrap(), &bytes)

fn test_base64_vectors:
    assert_base64_vector("", "")
    assert_base64_vector("f", "Zg==")
    assert_base64_vector("fo", "Zm8=")
    assert_base64_vector("foo", "Zm9v")
    assert_base64_vector("foob", "Zm9vYg==")
    assert_base64_vector("fooba", "Zm9vYmE=")
    assert_base64_vector("foobar", "Zm9vYmFy")

fn test_base64_alphabets:
    let alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    let alphabet_url = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"
    var value: i32 = 0
    while value < 64:
        let input = [(value << 2) as u8]
        assert(base64_encode(input).byte_at(0) == alphabet.byte_at(value as i64))
        assert(base64url_encode(input).byte_at(0) == alphabet_url.byte_at(value as i64))
        value = value + 1

fn test_base64_terminal_quanta_and_examples:
    let one = ascii_bytes("f")
    let two = ascii_bytes("fo")
    let three = ascii_bytes("foo")
    assert(base64_encode(one).ends_with("=="))
    assert(base64url_encode(one).ends_with("=="))
    assert(base64_encode(two).ends_with("="))
    assert(base64url_encode(two).ends_with("="))
    assert(not base64_encode(three).contains("="))
    assert(not base64url_encode(three).contains("="))

    let full = [20 as u8, 251 as u8, 156 as u8, 3 as u8, 217 as u8, 126 as u8]
    let tail_two = [20 as u8, 251 as u8, 156 as u8, 3 as u8, 217 as u8]
    let tail_one = [20 as u8, 251 as u8, 156 as u8, 3 as u8]
    assert(base64_encode(full) == "FPucA9l+")
    assert(base64_encode(tail_two) == "FPucA9k=")
    assert(base64_encode(tail_one) == "FPucAw==")

    let distinct = [251 as u8, 255 as u8]
    assert(base64_encode(distinct) == "+/8=")
    assert(base64url_encode(distinct) == "-_8=")
    let decoded = base64_decode("+/8=").unwrap()
    let decoded_url = base64url_decode("-_8=").unwrap()
    assert(decoded.len() == 2)
    assert(decoded_url.len() == 2)
    assert(decoded.get(0) == 251 as u8)
    assert(decoded.get(1) == 255 as u8)
    assert(decoded_url.get(0) == 251 as u8)
    assert(decoded_url.get(1) == 255 as u8)

fn main:
    test_base16_vectors()
    test_base16_alphabet_and_case()
    test_base16_all_octets()
    test_base32_vectors()
    test_base32_alphabets()
    test_base32_terminal_quanta_and_case()
    test_base64_vectors()
    test_base64_alphabets()
    test_base64_terminal_quanta_and_examples()
    print("ok")
