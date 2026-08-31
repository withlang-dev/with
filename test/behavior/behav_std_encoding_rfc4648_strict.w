//! expect-stdout: ok

use std.collections
use std.result
use std.string
use std.encoding
use std.encoding.base16
use std.encoding.base32
use std.encoding.base32hex

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

fn expect_invalid_padding(result: Result[Vec[u8], DecodeError], offset: i64):
    match result:
        Err(.InvalidPadding(actual)) => assert(actual == offset)
        _ => assert(false)

fn expect_noncanonical(result: Result[Vec[u8], DecodeError], offset: i64):
    match result:
        Err(.NonCanonicalBits(actual)) => assert(actual == offset)
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

fn test_base32_rejection:
    expect_invalid_length(base32_decode("MY"), 2)
    expect_invalid_length(base32hex_decode("CO"), 2)
    expect_invalid_byte(base32_decode("M0======"), 1, 48 as u8)
    expect_invalid_byte(base32_decode("M1======"), 1, 49 as u8)
    expect_invalid_byte(base32hex_decode("CW======"), 1, 87 as u8)
    expect_invalid_byte(base32_decode("M?======"), 1, 63 as u8)
    expect_invalid_byte(base32_decode("M\n======"), 1, 10 as u8)
    let nul = [77 as u8, 0 as u8, 61 as u8, 61 as u8, 61 as u8, 61 as u8, 61 as u8, 61 as u8]
    expect_invalid_byte(base32_decode(raw_text(nul)), 1, 0 as u8)
    let non_ascii = [77 as u8, 255 as u8, 61 as u8, 61 as u8, 61 as u8, 61 as u8, 61 as u8, 61 as u8]
    expect_invalid_byte(base32_decode(raw_text(non_ascii)), 1, 255 as u8)
    expect_invalid_byte(base32hex_decode("0?======"), 1, 63 as u8)
    expect_invalid_byte(base32hex_decode("0\n======"), 1, 10 as u8)
    let hex_nul = [48 as u8, 0 as u8, 61 as u8, 61 as u8, 61 as u8, 61 as u8, 61 as u8, 61 as u8]
    expect_invalid_byte(base32hex_decode(raw_text(hex_nul)), 1, 0 as u8)
    let hex_non_ascii = [48 as u8, 255 as u8, 61 as u8, 61 as u8, 61 as u8, 61 as u8, 61 as u8, 61 as u8]
    expect_invalid_byte(base32hex_decode(raw_text(hex_non_ascii)), 1, 255 as u8)

fn test_base32_padding:
    expect_invalid_padding(base32_decode("A======="), 1)
    expect_invalid_padding(base32_decode("AAAAAA=="), 6)
    expect_invalid_padding(base32_decode("AA====A="), 6)
    expect_invalid_padding(base32_decode("MZ====A="), 6)
    expect_invalid_padding(base32hex_decode("0======="), 1)
    expect_invalid_padding(base32hex_decode("000000=="), 6)
    expect_invalid_padding(base32hex_decode("00====0="), 6)

fn test_base32_noncanonical_bits:
    expect_noncanonical(base32_decode("MZ======"), 1)
    expect_noncanonical(base32_decode("MZXR===="), 3)
    expect_noncanonical(base32_decode("MZXW7==="), 4)
    expect_noncanonical(base32_decode("MZXW6YR="), 6)
    expect_noncanonical(base32hex_decode("CP======"), 1)
    expect_noncanonical(base32hex_decode("CPNH===="), 3)
    expect_noncanonical(base32hex_decode("CPNMV==="), 4)
    expect_noncanonical(base32hex_decode("CPNMUOH="), 6)

fn main:
    test_base16_rejection()
    test_base32_rejection()
    test_base32_padding()
    test_base32_noncanonical_bits()
    print("ok")
