// ChaCha20-Poly1305 AEAD — RFC 8439

use std.crypto.chacha20
use std.crypto.poly1305
use std.crypto.endian

unsafe fn chacha20_poly1305_encrypt(key: *const u8, nonce: *const u8, aad: *const u8, aad_len: i32, plaintext: *const u8, pt_len: i32, ciphertext: *mut u8, tag: *mut u8):
    // Generate Poly1305 key from ChaCha20 block 0
    var poly_key: [u8; 64] = [0 as u8; 64]
    let pkp = &raw mut poly_key[0] as *mut u8
    chacha20_block(key, nonce, 0 as u32, pkp)

    // Encrypt with ChaCha20 (counter starts at 1)
    for i in 0..pt_len:
        *(ciphertext + i as u64) = *(plaintext + i as u64)
    chacha20_crypt(key, nonce, 1 as u32, ciphertext, pt_len)

    // Poly1305 MAC over: AAD || pad || ciphertext || pad || lengths
    var mac = Poly1305.new(pkp as *const u8)
    let mp = &raw mut mac as *mut Poly1305

    // Process AAD
    if aad_len > 0:
        poly1305_update(mp, aad, aad_len)
        // Pad to 16-byte boundary
        let aad_pad = (16 - (aad_len % 16)) % 16
        if aad_pad > 0:
            var zeros: [u8; 16] = [0 as u8; 16]
            poly1305_update(mp, &zeros[0] as *const u8, aad_pad)

    // Process ciphertext
    if pt_len > 0:
        poly1305_update(mp, ciphertext as *const u8, pt_len)
        let ct_pad = (16 - (pt_len % 16)) % 16
        if ct_pad > 0:
            var zeros: [u8; 16] = [0 as u8; 16]
            poly1305_update(mp, &zeros[0] as *const u8, ct_pad)

    // Lengths block (8 bytes each, little-endian)
    var len_block: [u8; 16] = [0 as u8; 16]
    let lbp = &raw mut len_block[0] as *mut u8
    u64_to_le(lbp, 0, aad_len as u64)
    u64_to_le(lbp, 8, pt_len as u64)
    poly1305_update(mp, lbp as *const u8, 16)

    poly1305_finish(mp, tag)
