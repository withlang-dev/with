//! expect-stdout: sealed ok
//! expect-stdout: opened ok
//! expect-stdout: tampered ciphertext: forged
//! expect-stdout: other aad: forged
//! expect-stdout: short: forged
//! expect-stdout: short key: key length
//! expect-stdout: short nonce: nonce length

use std.crypto.chacha20poly1305

// #1054: the ChaCha20-Poly1305 AEAD had no entry point a program could
// call (a private raw-pointer fn). RFC 8439 §2.8.2's vector, both ways.

fn hex(text: &str) -> List[u8]:
    var out: List[u8] = List.new()
    var i = 0
    while i + 1 < text.len():
        out.push((hex_digit(text[i]) * 16 + hex_digit(text[i + 1])) as u8)
        i += 2
    out

fn hex_digit(c: u8) -> i32:
    if c >= '0' and c <= '9': return (c - '0') as i32
    (c - 'a') as i32 + 10

fn bytes_of(text: &str) -> List[u8]:
    var out: List[u8] = List.new()
    for i in 0..text.len(): out.push(text[i])
    out

const TEXT = "Ladies and Gentlemen of the class of '99: If I could offer you only one tip for the future, sunscreen would be it."

fn key(): hex("808182838485868788898a8b8c8d8e8f909192939495969798999a9b9c9d9e9f")
fn nonce(): hex("070000004041424344454647")
fn aad(): hex("50515253c0c1c2c3c4c5c6c7")
fn sealed(): chacha20_poly1305_seal(&key(), &nonce(), &aad(), bytes_of(TEXT)).unwrap()

fn main:
    let expected = hex("d31a8d34648e60db7b86afbc53ef7ec2a4aded51296e08fea9e2b5a736ee62d63dbea45e8ca9671282fafb69da92728b1a71de0a9e060b2905d6a5b67ecd3b3692ddbd7f2d778b8c9803aee328091b58fab324e4fad675945585808b4831d7bc3ff4def08e4b7a9de576d26586cec64b6116" ++ "1ae10b594f09e26a7e902ecbd0600691")
    assert(sealed() == expected)
    print("sealed ok")

    let opened = chacha20_poly1305_open(&key(), &nonce(), &aad(), sealed()).unwrap()
    assert(opened == bytes_of(TEXT))
    print("opened ok")

    var tampered = sealed()
    tampered[0] = tampered[0] ^ 1
    print(f"tampered ciphertext: {verdict(chacha20_poly1305_open(&key(), &nonce(), &aad(), tampered))}")
    print(f"other aad: {verdict(chacha20_poly1305_open(&key(), &nonce(), &hex(\"50515253c0c1c2c3c4c5c6c8\"), sealed()))}")
    print(f"short: {verdict(chacha20_poly1305_open(&key(), &nonce(), &aad(), hex(\"0001\")))}")
    print(f"short key: {verdict(chacha20_poly1305_seal(&hex(\"00\"), &nonce(), &aad(), bytes_of(TEXT)))}")
    print(f"short nonce: {verdict(chacha20_poly1305_seal(&key(), &hex(\"00\"), &aad(), bytes_of(TEXT)))}")

fn verdict(r: Result[List[u8], AeadError]) -> str:
    match r:
        Ok(_) => "accepted"
        Err(.KeyLength) => "key length"
        Err(.NonceLength) => "nonce length"
        Err(.Forged) => "forged"
