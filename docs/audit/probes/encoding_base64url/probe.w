use std.collections
use std.encoding
use std.encoding.base64url
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
    print(base64url_encode(b))

fn main:
    // RFC 4648 §5 vectors coincide with base64 here (oracle: python3 urlsafe_b64encode)
    show("")
    show("f")
    show("fo")
    show("foo")
    show("foob")
    show("fooba")
    show("foobar")
    // url-distinct alphabet chars
    let distinct = [251 as u8, 255 as u8]
    print(base64url_encode(distinct))
    let rt = base64url_decode("-_8=").unwrap()
    print(base64url_encode(rt))
    // strict: standard alphabet +/ rejected
    match base64url_decode("+/8="):
        Err(.InvalidByte(_, _)) => print("stdchars-InvalidByte")
        _ => print("UNEXPECTED")
    // invalid inputs mirror base64
    match base64url_decode("Zg"):
        Err(.InvalidLength(_)) => print("len-InvalidLength")
        _ => print("UNEXPECTED")
    match base64url_decode("A==="):
        Err(.InvalidPadding(_)) => print("pad3-InvalidPadding")
        _ => print("UNEXPECTED")
    match base64url_decode("AA=A"):
        Err(.InvalidPadding(_)) => print("padmid-InvalidPadding")
        _ => print("UNEXPECTED")
    match base64url_decode("Zh=="):
        Err(.NonCanonicalBits(_)) => print("noncanon-NonCanonicalBits")
        _ => print("UNEXPECTED")
    match base64url_decode("Zm9="):
        Err(.NonCanonicalBits(_)) => print("noncanon2-NonCanonicalBits")
        _ => print("UNEXPECTED")
