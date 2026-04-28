// HMAC-SHA256 — RFC 2104 using SHA-256.
// Ported from BearSSL src/mac/hmac.c

use std.crypto.sha256

type HmacSha256  {
    inner: Sha256,
    outer_key: [u8; 64],
}

fn HmacSha256.new(key: *const u8, key_len: i32) -> HmacSha256:
    var padded_key: [u8; 64] = [0 as u8; 64]
    if key_len > 64:
        var key_hash: [u8; 32] = [0 as u8; 32]
        sha256_hash(key, key_len, &raw mut key_hash[0] as *mut u8)
        for i in 0..32:
            padded_key[i] = key_hash[i]
    else:
        for i in 0..key_len:
            padded_key[i] = unsafe: *(key + i as u64)

    var ipad_key: [u8; 64] = [0 as u8; 64]
    var outer_key: [u8; 64] = [0 as u8; 64]
    for i in 0..64:
        ipad_key[i] = padded_key[i] ^ (0x36 as u8)
        outer_key[i] = padded_key[i] ^ (0x5C as u8)

    var inner = Sha256.new()
    let ip = &raw mut inner as *mut Sha256
    unsafe: sha256_update(ip, &ipad_key[0] as *const u8, 64)

    HmacSha256 { inner, outer_key }

unsafe fn hmac_update(ctx: *mut HmacSha256, data: *const u8, len: i32):
    // Copy inner state, update, copy back
    var inner = ctx.inner
    let ip = &raw mut inner as *mut Sha256
    sha256_update(ip, data, len)
    ctx.inner = inner

unsafe fn hmac_finish(ctx: *mut HmacSha256, out: *mut u8):
    // Finish inner hash
    var inner = ctx.inner
    let ip = &raw mut inner as *mut Sha256
    var inner_digest: [u8; 32] = [0 as u8; 32]
    let idp = &raw mut inner_digest[0] as *mut u8
    sha256_finish(ip, idp)

    // Copy outer_key to stack
    var ok: [u8; 64] = [0 as u8; 64]
    for i in 0..64:
        ok[i] = ctx.outer_key[i]

    // Outer hash: SHA-256(outer_key ++ inner_digest)
    var outer = Sha256.new()
    let op = &raw mut outer as *mut Sha256
    sha256_update(op, &ok[0] as *const u8, 64)
    sha256_update(op, idp as *const u8, 32)
    sha256_finish(op, out)

fn hmac_sha256(key: *const u8, key_len: i32, data: *const u8, data_len: i32, out: *mut u8):
    var ctx = HmacSha256.new(key, key_len)
    let p = &raw mut ctx as *mut HmacSha256
    unsafe: hmac_update(p, data, data_len)
    unsafe: hmac_finish(p, out)

fn hmac_sha256_str(key: str, data: str, out: *mut u8):
    hmac_sha256(key as *const u8, key.len() as i32, data as *const u8, data.len() as i32, out)
