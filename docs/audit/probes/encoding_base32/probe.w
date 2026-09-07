use std.collections
use std.encoding
use std.encoding.base32
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
    print(base32_encode(b))

fn show_decoded(text: &str):
    let d = base32_decode(text).unwrap()
    print(base32_encode(d))

fn main:
    // RFC 4648 §6 vectors (oracle: python3 base64.b32encode)
    show("")
    show("f")
    show("fo")
    show("foo")
    show("foob")
    show("fooba")
    show("foobar")
    // lowercase decode (casefold) round-trips to canonical upper
    show_decoded("mzxw6===")
    show_decoded("mzxw6ytboi======")
    // invalid inputs
    match base32_decode("MY"):
        Err(.InvalidLength(_)) => print("len-InvalidLength")
        _ => print("UNEXPECTED")
    match base32_decode("M0======"):
        Err(.InvalidByte(_, _)) => print("digit0-InvalidByte")
        _ => print("UNEXPECTED")
    match base32_decode("A======="):
        Err(.InvalidPadding(_)) => print("padpos-InvalidPadding")
        _ => print("UNEXPECTED")
    match base32_decode("AA====A="):
        Err(.InvalidPadding(_)) => print("padorder-InvalidPadding")
        _ => print("UNEXPECTED")
    match base32_decode("MZ======"):
        Err(.NonCanonicalBits(_)) => print("noncanon-NonCanonicalBits")
        _ => print("UNEXPECTED")
    match base32_decode("MZXW7==="):
        Err(.NonCanonicalBits(_)) => print("noncanon2-NonCanonicalBits")
        _ => print("UNEXPECTED")
