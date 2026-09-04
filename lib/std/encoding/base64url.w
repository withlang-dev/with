// RFC 4648 Base64URL. Encoding is representation, not confidentiality.

use std.collections
use std.result
use std.string
use std.encoding

const BASE64URL_ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"

fn base64url_value(byte: i32):
    if byte >= 65 and byte <= 90:
        return byte - 65
    if byte >= 97 and byte <= 122:
        return byte - 97 + 26
    if byte >= 48 and byte <= 57:
        return byte - 48 + 52
    if byte == 45:
        return 62
    if byte == 95:
        return 63
    -1

fn base64url_encoded_len(length: i64):
    let full = length / 3
    let tail = if length % 3 == 0: 0 else: 4
    full * 4 + tail

fn base64url_validate(text: &str) -> Result[i64, DecodeError]:
    if text.len() % 4 != 0:
        return Err(.InvalidLength(text.len()))
    var first_pad: i64 = -1
    var i: i64 = 0
    while i < text.len():
        let byte = text[i]
        if byte == 61:
            if first_pad < 0:
                if text.len() - i > 2:
                    return Err(.InvalidPadding(i))
                first_pad = i
        else:
            if first_pad >= 0:
                return Err(.InvalidPadding(i))
            if base64url_value(byte) < 0:
                return Err(.InvalidByte(i, byte as u8))
        i = i + 1
    let padding = if first_pad < 0: 0 else: text.len() - first_pad
    if padding > 0:
        let offset = first_pad - 1
        let value = base64url_value(text[offset])
        let mask = if padding == 2: 15 else: 3
        if value & mask != 0:
            return Err(.NonCanonicalBits(offset))
    padding

/// Encode bytes as canonical padded RFC 4648 Base64URL.
pub fn base64url_encode(data: []u8) -> str:
    var out = StringBuilder.with_capacity(base64url_encoded_len(data.len()))
    var offset: i64 = 0
    while offset < data.len():
        let remaining = data.len() - offset
        let count = if remaining >= 3: 3 else: remaining
        let b0 = data[offset] as i32
        let b1 = if count > 1: data[offset + 1] as i32 else: 0
        let b2 = if count > 2: data[offset + 2] as i32 else: 0
        let v0 = b0 >> 2
        let v1 = ((b0 & 3) << 4) | (b1 >> 4)
        let v2 = ((b1 & 15) << 2) | (b2 >> 6)
        let v3 = b2 & 63
        out.push_byte(BASE64URL_ALPHABET[v0] as u8)
        out.push_byte(BASE64URL_ALPHABET[v1] as u8)
        if count > 1: out.push_byte(BASE64URL_ALPHABET[v2] as u8) else: out.push_byte(61 as u8)
        if count > 2: out.push_byte(BASE64URL_ALPHABET[v3] as u8) else: out.push_byte(61 as u8)
        offset = offset + count
    out.to_str()

/// Decode padded RFC 4648 Base64URL with strict alphabet and unused-bit checks.
pub fn base64url_decode(text: &str) -> Result[Vec[u8], DecodeError]:
    let padding = base64url_validate(text)?
    let out = Vec[u8].with_capacity((text.len() / 4) * 3 - padding)
    var offset: i64 = 0
    while offset < text.len():
        let final_quantum = offset + 4 == text.len()
        let symbols = if final_quantum: 4 - padding else: 4
        let v0 = base64url_value(text[offset])
        let v1 = base64url_value(text[offset + 1])
        let v2 = if symbols > 2: base64url_value(text[offset + 2]) else: 0
        let v3 = if symbols > 3: base64url_value(text[offset + 3]) else: 0
        out.push(((v0 << 2) | (v1 >> 4)) as u8)
        if symbols >= 3: out.push((((v1 & 15) << 4) | (v2 >> 2)) as u8)
        if symbols == 4: out.push((((v2 & 3) << 6) | v3) as u8)
        offset = offset + 4
    out
