//! expect-stdout: ok

use std.collections
use std.result
use std.string
use std.encoding
use std.encoding.base16

fn raw_text(bytes: []u8):
    var out = StringBuilder.with_capacity(bytes.len())
    var i: i64 = 0
    while i < bytes.len():
        out.push_byte(bytes[i])
        i = i + 1
    out.to_str()

fn expect_invalid_length(result: Result[Vec[u8], DecodeError], length: i64):
    match result:
        Err(.InvalidLength(actual)) => assert(actual == length)
        _ => assert(false)

fn expect_invalid_byte(result: Result[Vec[u8], DecodeError], offset: i64, byte: u8):
    match result:
        Err(.InvalidByte(actual_offset, actual_byte)) =>
            assert(actual_offset == offset)
            assert(actual_byte == byte)
        _ => assert(false)

fn test_base16_rejection:
    expect_invalid_length(base16_decode("0"), 1)
    expect_invalid_length(base16_decode("G"), 1)
    expect_invalid_byte(base16_decode("GG"), 0, 71 as u8)
    expect_invalid_byte(base16_decode("=="), 0, 61 as u8)
    expect_invalid_byte(base16_decode("66\nF"), 2, 10 as u8)
    let nul = [54 as u8, 54 as u8, 0 as u8, 70 as u8]
    expect_invalid_byte(base16_decode(raw_text(nul)), 2, 0 as u8)
    let non_ascii = [54 as u8, 54 as u8, 255 as u8, 70 as u8]
    expect_invalid_byte(base16_decode(raw_text(non_ascii)), 2, 255 as u8)

fn main:
    test_base16_rejection()
    print("ok")
