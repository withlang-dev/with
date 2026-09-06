use std.collections
use std.encoding
use std.encoding.base32hex
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
    print(base32hex_encode(b))

fn show_decoded(text: &str):
    let d = base32hex_decode(text).unwrap()
    print(base32hex_encode(d))

fn main:
    // RFC 4648 §7 vectors (oracle: python3 b32encode translated to ext-hex alphabet)
    show("")
    show("f")
    show("fo")
    show("foo")
    show("foob")
    show("fooba")
    show("foobar")
    // lowercase decode round-trips to canonical upper
    show_decoded("cpnmu===")
    // invalid inputs
    match base32hex_decode("CO"):
        Err(.InvalidLength(_)) => print("len-InvalidLength")
        _ => print("UNEXPECTED")
    match base32hex_decode("CW======"):
        Err(.InvalidByte(_, _)) => print("w-InvalidByte")
        _ => print("UNEXPECTED")
    match base32hex_decode("0======="):
        Err(.InvalidPadding(_)) => print("padpos-InvalidPadding")
        _ => print("UNEXPECTED")
    match base32hex_decode("00====0="):
        Err(.InvalidPadding(_)) => print("padorder-InvalidPadding")
        _ => print("UNEXPECTED")
    match base32hex_decode("CP======"):
        Err(.NonCanonicalBits(_)) => print("noncanon-NonCanonicalBits")
        _ => print("UNEXPECTED")
    match base32hex_decode("CPNMV==="):
        Err(.NonCanonicalBits(_)) => print("noncanon2-NonCanonicalBits")
        _ => print("UNEXPECTED")
