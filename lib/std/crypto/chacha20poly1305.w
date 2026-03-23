// ChaCha20-Poly1305 AEAD — RFC 8439
// Combines ChaCha20 stream cipher with Poly1305 MAC.

use std.crypto.chacha20
use std.crypto.poly1305

// Encrypt and authenticate
// key: 32 bytes, nonce: 12 bytes
// Produces ciphertext (same length as plaintext) + 16-byte tag
fn chacha20_poly1305_encrypt(
    key: *const u8,
    nonce: *const u8,
    aad: *const u8,
    aad_len: i32,
    plaintext: *const u8,
    pt_len: i32,
    ciphertext: *mut u8,
    tag: *mut u8,
):
    // Generate Poly1305 key: first 32 bytes of ChaCha20 with counter=0
    var poly_key: [u8; 64] = [0 as u8; 64]
    let pkp = &mut poly_key[0] as *mut u8
    chacha20_block(key, nonce, 0 as u32, pkp)

    // Encrypt with ChaCha20 (counter starts at 1)
    // Copy plaintext to ciphertext first, then encrypt in-place
    for i in 0..pt_len:
        unsafe: *(ciphertext + i as u64) = unsafe: *(plaintext + i as u64)
    chacha20_crypt(key, nonce, 1 as u32, ciphertext, pt_len)

    // Compute Poly1305 tag over: AAD || pad || ciphertext || pad || lengths
    var mac = Poly1305.new(pkp as *const u8)
    let mp = &mut mac as *mut Poly1305

    // Process AAD in 16-byte blocks
    var off = 0
    while off + 16 <= aad_len:
        Poly1305.block(mp, unsafe: (aad + off as u64) as *const u8, false)
        off = off + 16
    if off < aad_len:
        var pad_block: [u8; 16] = [0 as u8; 16]
        let pbp = &mut pad_block[0] as *mut u8
        for i in 0..(aad_len - off):
            unsafe: *(pbp + i as u64) = unsafe: *(aad + (off + i) as u64)
        Poly1305.block(mp, pbp as *const u8, false)

    // Process ciphertext in 16-byte blocks
    off = 0
    while off + 16 <= pt_len:
        Poly1305.block(mp, unsafe: (ciphertext + off as u64) as *const u8, false)
        off = off + 16
    if off < pt_len:
        var pad_block2: [u8; 16] = [0 as u8; 16]
        let pbp2 = &mut pad_block2[0] as *mut u8
        for i in 0..(pt_len - off):
            unsafe: *(pbp2 + i as u64) = unsafe: *(ciphertext + (off + i) as u64)
        Poly1305.block(mp, pbp2 as *const u8, false)

    // Process lengths block: aad_len (8 bytes LE) || ct_len (8 bytes LE)
    var len_block: [u8; 16] = [0 as u8; 16]
    let lbp = &mut len_block[0] as *mut u8
    store32le_cp(lbp, 0, aad_len as u32)
    store32le_cp(lbp, 4, 0 as u32)
    store32le_cp(lbp, 8, pt_len as u32)
    store32le_cp(lbp, 12, 0 as u32)
    Poly1305.block(mp, lbp as *const u8, true)

    Poly1305.finish(mp, tag)

fn store32le_cp(p: *mut u8, off: i32, val: u32):
    unsafe: *(p + off as u64) = val as u8
    unsafe: *(p + (off + 1) as u64) = (val >> 8 as u32) as u8
    unsafe: *(p + (off + 2) as u64) = (val >> 16 as u32) as u8
    unsafe: *(p + (off + 3) as u64) = (val >> 24 as u32) as u8
