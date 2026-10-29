// ChaCha20-Poly1305 AEAD — RFC 8439

use std.crypto.chacha20
use std.crypto.poly1305
use std.crypto.endian

/// Why a seal or an open was refused.
pub enum AeadError:
    /// The key is not 32 bytes.
    KeyLength
    /// The nonce is not 12 bytes.
    NonceLength
    /// The sealed bytes are shorter than a tag, or the tag does not match:
    /// the ciphertext, the additional data, the key or the nonce differs
    /// from what was sealed.
    Forged

/// `plaintext` encrypted in place under a 32-byte `key` and a 12-byte
/// `nonce`, with `aad` authenticated but not encrypted (RFC 8439 §2.8): the
/// ciphertext, then its 16-byte tag. A nonce is never reused under one key.
pub fn chacha20_poly1305_seal(key: &List[u8], nonce: &List[u8], aad: &List[u8], plaintext: List[u8]) -> Result[List[u8], AeadError]:
    aead_check_lengths(key, nonce)?
    var sealed = plaintext
    unsafe { chacha20_crypt(aead_bytes(key), aead_bytes(nonce), 1 as u32, sealed.ptr as *mut u8, sealed.len()) }
    let tag = aead_tag(key, nonce, aad, aead_bytes(&sealed), sealed.len())
    for b in tag: sealed.push(b)
    sealed

/// The plaintext `chacha20_poly1305_seal` sealed into `sealed` under `key`,
/// `nonce` and `aad`, decrypted in place, or `Forged` when any of them
/// differs. Nothing is decrypted before the tag is checked.
pub fn chacha20_poly1305_open(key: &List[u8], nonce: &List[u8], aad: &List[u8], sealed: List[u8]) -> Result[List[u8], AeadError]:
    aead_check_lengths(key, nonce)?
    if sealed.len() < 16: return Err(.Forged)
    var opened = sealed
    let ct_len = opened.len() - 16
    let tag = aead_tag(key, nonce, aad, aead_bytes(&opened), ct_len)
    // Constant time: every byte is compared whatever the first difference.
    var diff: u8 = 0
    for i in 0..16: diff = diff | (tag[i] ^ opened[ct_len + i])
    if diff != 0: return Err(.Forged)
    for _ in 0..16: opened.pop()
    unsafe { chacha20_crypt(aead_bytes(key), aead_bytes(nonce), 1 as u32, opened.ptr as *mut u8, opened.len()) }
    opened

fn aead_check_lengths(key: &List[u8], nonce: &List[u8]) -> Result[Unit, AeadError]:
    if key.len() != 32: return Err(.KeyLength)
    if nonce.len() != 12: return Err(.NonceLength)

fn aead_bytes(bytes: &List[u8]) -> *const u8: bytes.ptr as *const u8

// The Poly1305 tag over aad, its padding, the ciphertext, its padding and
// both lengths, keyed by ChaCha20 block 0 (RFC 8439 §2.8).
fn aead_tag(key: &List[u8], nonce: &List[u8], aad: &List[u8], ciphertext: *const u8, ct_len: isize) -> [u8; 16]:
    var poly_key: [u8; 64] = [0 as u8; 64]
    let pkp = &raw mut poly_key[0] as *mut u8
    var tag: [u8; 16] = [0 as u8; 16]
    unsafe:
        chacha20_block(aead_bytes(key), aead_bytes(nonce), 0 as u32, pkp)
        var mac = Poly1305.new(pkp as *const u8)
        let mp = &raw mut mac as *mut Poly1305
        aead_mac_padded(mp, aead_bytes(aad), aad.len())
        aead_mac_padded(mp, ciphertext, ct_len)
        var len_block: [u8; 16] = [0 as u8; 16]
        let lbp = &raw mut len_block[0] as *mut u8
        u64_to_le(lbp, 0, aad.len() as u64)
        u64_to_le(lbp, 8, ct_len as u64)
        poly1305_update(mp, lbp as *const u8, 16)
        poly1305_finish(mp, &raw mut tag[0] as *mut u8)
    tag

// The bytes, then zeros to the next 16-byte boundary, as whole blocks:
// poly1305_update closes a short final block (its 0x01 marker) at the end
// of every call, so the bytes' last partial block goes in zero-padded to a
// full one. Passing the zeros in a second call made it a marked short block,
// and the tag was not RFC 8439's.
unsafe fn aead_mac_padded(mp: *mut Poly1305, bytes: *const u8, len: isize):
    let full = len - len % 16
    if full > 0: poly1305_update(mp, bytes, full)
    if full < len:
        var tail: [u8; 16] = [0 as u8; 16]
        for i in full..len: tail[i - full] = *(bytes + i as u64)
        poly1305_update(mp, &tail[0] as *const u8, 16)
