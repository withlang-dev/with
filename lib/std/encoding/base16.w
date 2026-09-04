// RFC 4648 Base16. Encoding is representation, not confidentiality.

use std.collections
use std.result
use std.string
use std.encoding

const BASE16_ALPHABET = "0123456789ABCDEF"

fn base16_value(byte: i32):
    if byte >= 48 and byte <= 57:
        return byte - 48
    if byte >= 65 and byte <= 70:
        return byte - 65 + 10
    if byte >= 97 and byte <= 102:
        return byte - 97 + 10
    -1

/// Encode bytes as canonical uppercase RFC 4648 Base16.
pub fn base16_encode(data: []u8) -> str:
    var out = StringBuilder.with_capacity(data.len() * 2)
    var i: i64 = 0
    while i < data.len():
        let byte = data[i] as i32
        out.push_byte(BASE16_ALPHABET[(byte >> 4)] as u8)
        out.push_byte(BASE16_ALPHABET[(byte & 15)] as u8)
        i = i + 1
    out.to_str()

/// Decode case-insensitive RFC 4648 Base16, rejecting every non-alphabet byte.
pub fn base16_decode(text: &str) -> Result[Vec[u8], DecodeError]:
    if text.len() % 2 != 0:
        return Err(.InvalidLength(text.len()))
    var validate_i: i64 = 0
    while validate_i < text.len():
        let byte = text[validate_i]
        if base16_value(byte) < 0:
            return Err(.InvalidByte(validate_i, byte as u8))
        validate_i = validate_i + 1
    let out = Vec[u8].with_capacity(text.len() / 2)
    var i: i64 = 0
    while i < text.len():
        let high = base16_value(text[i])
        let low = base16_value(text[i + 1])
        out.push(((high << 4) | low) as u8)
        i = i + 2
    out
