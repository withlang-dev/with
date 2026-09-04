// RFC 4648 Base32 extended hex. Encoding is representation, not confidentiality.

use std.collections
use std.result
use std.string
use std.encoding

const BASE32HEX_ALPHABET = "0123456789ABCDEFGHIJKLMNOPQRSTUV"

fn base32hex_value(byte: i32):
    if byte >= 48 and byte <= 57:
        return byte - 48
    if byte >= 65 and byte <= 86:
        return byte - 65 + 10
    if byte >= 97 and byte <= 118:
        return byte - 97 + 10
    -1

fn base32hex_encoded_len(length: i64):
    let full = length / 5
    let tail = if length % 5 == 0: 0 else: 8
    full * 8 + tail

fn base32hex_validate(text: &str) -> Result[i64, DecodeError]:
    if text.len() % 8 != 0:
        return Err(.InvalidLength(text.len()))
    var first_pad: i64 = -1
    var i: i64 = 0
    while i < text.len():
        let byte = text[i]
        if byte == 61:
            if first_pad < 0:
                let remaining = text.len() - i
                if remaining != 1 and remaining != 3 and remaining != 4 and remaining != 6:
                    return Err(.InvalidPadding(i))
                first_pad = i
        else:
            if first_pad >= 0:
                return Err(.InvalidPadding(i))
            if base32hex_value(byte) < 0:
                return Err(.InvalidByte(i, byte as u8))
        i = i + 1
    let padding = if first_pad < 0: 0 else: text.len() - first_pad
    if padding > 0:
        let offset = first_pad - 1
        let value = base32hex_value(text[offset])
        let mask = if padding == 6: 3 else if padding == 4: 15 else if padding == 3: 1 else: 7
        if value & mask != 0:
            return Err(.NonCanonicalBits(offset))
    padding

/// Encode bytes as canonical uppercase, padded RFC 4648 Base32hex.
pub fn base32hex_encode(data: []u8) -> str:
    var out = StringBuilder.with_capacity(base32hex_encoded_len(data.len()))
    var offset: i64 = 0
    while offset < data.len():
        let remaining = data.len() - offset
        let count = if remaining >= 5: 5 else: remaining
        let b0 = data[offset] as i32
        let b1 = if count > 1: data[offset + 1] as i32 else: 0
        let b2 = if count > 2: data[offset + 2] as i32 else: 0
        let b3 = if count > 3: data[offset + 3] as i32 else: 0
        let b4 = if count > 4: data[offset + 4] as i32 else: 0
        let symbols = if count == 1: 2 else if count == 2: 4 else if count == 3: 5 else if count == 4: 7 else: 8
        let v0 = b0 >> 3
        let v1 = ((b0 & 7) << 2) | (b1 >> 6)
        let v2 = (b1 >> 1) & 31
        let v3 = ((b1 & 1) << 4) | (b2 >> 4)
        let v4 = ((b2 & 15) << 1) | (b3 >> 7)
        let v5 = (b3 >> 2) & 31
        let v6 = ((b3 & 3) << 3) | (b4 >> 5)
        let v7 = b4 & 31
        out.push_byte(BASE32HEX_ALPHABET[v0] as u8)
        out.push_byte(BASE32HEX_ALPHABET[v1] as u8)
        if symbols > 2: out.push_byte(BASE32HEX_ALPHABET[v2] as u8) else: out.push_byte(61 as u8)
        if symbols > 3: out.push_byte(BASE32HEX_ALPHABET[v3] as u8) else: out.push_byte(61 as u8)
        if symbols > 4: out.push_byte(BASE32HEX_ALPHABET[v4] as u8) else: out.push_byte(61 as u8)
        if symbols > 5: out.push_byte(BASE32HEX_ALPHABET[v5] as u8) else: out.push_byte(61 as u8)
        if symbols > 6: out.push_byte(BASE32HEX_ALPHABET[v6] as u8) else: out.push_byte(61 as u8)
        if symbols > 7: out.push_byte(BASE32HEX_ALPHABET[v7] as u8) else: out.push_byte(61 as u8)
        offset = offset + count
    out.to_str()

/// Decode padded RFC 4648 Base32hex, accepting ASCII letter case variants.
pub fn base32hex_decode(text: &str) -> Result[Vec[u8], DecodeError]:
    let padding = base32hex_validate(text)?
    let removed = if padding == 6: 4 else if padding == 4: 3 else if padding == 3: 2 else if padding == 1: 1 else: 0
    let out = Vec[u8].with_capacity((text.len() / 8) * 5 - removed)
    var offset: i64 = 0
    while offset < text.len():
        let final_quantum = offset + 8 == text.len()
        let symbols = if final_quantum: 8 - padding else: 8
        let v0 = base32hex_value(text[offset])
        let v1 = base32hex_value(text[offset + 1])
        let v2 = if symbols > 2: base32hex_value(text[offset + 2]) else: 0
        let v3 = if symbols > 3: base32hex_value(text[offset + 3]) else: 0
        let v4 = if symbols > 4: base32hex_value(text[offset + 4]) else: 0
        let v5 = if symbols > 5: base32hex_value(text[offset + 5]) else: 0
        let v6 = if symbols > 6: base32hex_value(text[offset + 6]) else: 0
        let v7 = if symbols > 7: base32hex_value(text[offset + 7]) else: 0
        out.push(((v0 << 3) | (v1 >> 2)) as u8)
        if symbols >= 4: out.push((((v1 & 3) << 6) | (v2 << 1) | (v3 >> 4)) as u8)
        if symbols >= 5: out.push((((v3 & 15) << 4) | (v4 >> 1)) as u8)
        if symbols >= 7: out.push((((v4 & 1) << 7) | (v5 << 2) | (v6 >> 3)) as u8)
        if symbols == 8: out.push((((v6 & 7) << 5) | v7) as u8)
        offset = offset + 8
    out
