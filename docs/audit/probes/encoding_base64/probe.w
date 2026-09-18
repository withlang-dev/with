use std.collections
use std.encoding
use std.encoding.base64
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
    print(base64_encode(b))

fn main:
    // RFC 4648 §4 vectors (oracle: python3 base64.b64encode)
    show("")
    show("f")
    show("fo")
    show("foo")
    show("foob")
    show("fooba")
    show("foobar")
    // high-bit vectors incl. +/ alphabet chars
    let full = [20 as u8, 251 as u8, 156 as u8, 3 as u8, 217 as u8, 126 as u8]
    print(base64_encode(full))
    let distinct = [251 as u8, 255 as u8]
    print(base64_encode(distinct))
    let rt = base64_decode("+/8=").unwrap()
    print(base64_encode(rt))
    // strict: url alphabet rejected
    match base64_decode("-_8="):
        Err(.InvalidByte(_, _)) => print("urlchars-InvalidByte")
        _ => print("UNEXPECTED")
    // invalid inputs
    match base64_decode("Zg"):
        Err(.InvalidLength(_)) => print("len-InvalidLength")
        _ => print("UNEXPECTED")
    match base64_decode("A==="):
        Err(.InvalidPadding(_)) => print("pad3-InvalidPadding")
        _ => print("UNEXPECTED")
    match base64_decode("AA=A"):
        Err(.InvalidPadding(_)) => print("padmid-InvalidPadding")
        _ => print("UNEXPECTED")
    match base64_decode("Zh=="):
        Err(.NonCanonicalBits(_)) => print("noncanon-NonCanonicalBits")
        _ => print("UNEXPECTED")
    match base64_decode("Zm9="):
        Err(.NonCanonicalBits(_)) => print("noncanon2-NonCanonicalBits")
        _ => print("UNEXPECTED")
