// HMAC-SHA256 — ported from BearSSL src/mac/hmac.c
// RFC 2104 HMAC using SHA-256 as the underlying hash.

use std.crypto.sha256

// HMAC-SHA256 context
type HmacSha256 = {
    inner: Sha256,
    outer_key: [u8; 64],
}

fn HmacSha256.new(key: *const u8, key_len: i32) -> HmacSha256:
    // Prepare padded key
    var padded_key: [u8; 64] = [0 as u8; 64]
    if key_len > 64:
        var key_hash: [u8; 32] = [0 as u8; 32]
        sha256_hash(key, key_len, &mut key_hash[0] as *mut u8)
        for i in 0..32:
            padded_key[i] = key_hash[i]
    else:
        for i in 0..key_len:
            padded_key[i] = unsafe: *(key + i as u64)

    // Compute ipad_key and outer_key
    var ipad_key: [u8; 64] = [0 as u8; 64]
    var outer_key: [u8; 64] = [0 as u8; 64]
    for i in 0..64:
        ipad_key[i] = padded_key[i] ^ (0x36 as u8)
        outer_key[i] = padded_key[i] ^ (0x5C as u8)

    // Start inner hash with ipad_key
    var inner = Sha256.new()
    let inner_ptr = &mut inner as *mut Sha256
    Sha256.update(inner_ptr, &ipad_key[0] as *const u8, 64)

    HmacSha256 { inner, outer_key }

// Update HMAC with message data
fn HmacSha256.update(self: *mut HmacSha256, data: *const u8, len: i32):
    // Copy inner state out, update, copy back
    var inner = unsafe: (*self).inner
    let inner_ptr = &mut inner as *mut Sha256
    Sha256.update(inner_ptr, data, len)
    unsafe: (*self).inner = inner

// Finalize HMAC and produce 32-byte MAC
fn HmacSha256.finish(self: *mut HmacSha256, out: *mut u8):
    // Finish inner hash
    var inner = unsafe: (*self).inner
    let inner_ptr = &mut inner as *mut Sha256
    var inner_digest: [u8; 32] = [0 as u8; 32]
    let id_ptr = &mut inner_digest[0] as *mut u8
    Sha256.finish(inner_ptr, id_ptr)

    // Copy outer_key to stack
    var ok: [u8; 64] = [0 as u8; 64]
    for i in 0..64:
        ok[i] = unsafe: (*self).outer_key[i]

    // Outer hash: SHA-256(outer_key ++ inner_digest)
    var outer = Sha256.new()
    let outer_ptr = &mut outer as *mut Sha256
    Sha256.update(outer_ptr, &ok[0] as *const u8, 64)
    Sha256.update(outer_ptr, id_ptr as *const u8, 32)
    Sha256.finish(outer_ptr, out)

// Convenience: compute HMAC-SHA256 in one call
fn hmac_sha256(key: *const u8, key_len: i32, data: *const u8, data_len: i32, out: *mut u8):
    var ctx = HmacSha256.new(key, key_len)
    let ctx_ptr = &mut ctx as *mut HmacSha256
    HmacSha256.update(ctx_ptr, data, data_len)
    HmacSha256.finish(ctx_ptr, out)

// Convenience: HMAC with string key and data
fn hmac_sha256_str(key: str, data: str, out: *mut u8):
    hmac_sha256(key as *const u8, key.len() as i32, data as *const u8, data.len() as i32, out)
