use std.collections
use std.encoding
use std.encoding.base16
use std.string

fn ascii_bytes(text: &str):
    let out = Vec[u8].with_capacity(text.len())
    var i: i64 = 0
    while i < text.len():
        out.push(text.byte_at(i) as u8)
        i = i + 1
    out

fn show(text: &str):
    let b = ascii_bytes(text)
    print(base16_encode(b))

fn show_decoded(text: &str):
    let d = base16_decode(text).unwrap()
    print(base16_encode(d))

fn main:
    // RFC 4648 §8 vectors (oracle: python3 binascii.hexlify, upper)
    show("")
    show("f")
    show("fo")
    show("foo")
    show("foob")
    show("fooba")
    show("foobar")
    // lowercase decode canonicalizes to uppercase on re-encode
    show_decoded("666f6f")
    show_decoded("ff")
    // all-256-octet round trip
    var n: i32 = 0
    var ok_count: i32 = 0
    while n < 256:
        let one = [n as u8]
        let enc = base16_encode(one)
        let dec = base16_decode(enc).unwrap()
        if enc.len() == 2 and dec.get(0) == n as u8:
            ok_count = ok_count + 1
        n = n + 1
    if ok_count == 256: print("roundtrip-256-ok") else: print("roundtrip-FAIL")
    // invalid inputs
    match base16_decode("0"):
        Err(.InvalidLength(_)) => print("odd-len-InvalidLength")
        _ => print("UNEXPECTED")
    match base16_decode("GG"):
        Err(.InvalidByte(_, _)) => print("badbyte-InvalidByte")
        _ => print("UNEXPECTED")
    match base16_decode("=="):
        Err(.InvalidByte(_, _)) => print("pad-InvalidByte")
        _ => print("UNEXPECTED")
    match base16_decode("ZZ"):
        Err(.InvalidByte(_, _)) => print("zz-InvalidByte")
        _ => print("UNEXPECTED")
