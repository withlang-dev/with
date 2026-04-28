// ChaCha20 stream cipher — RFC 8439

use std.crypto.endian

unsafe fn qr(s: *mut u32, a: i32, b: i32, c: i32, d: i32):
    var sa = *(s + a as u64)
    var sb = *(s + b as u64)
    var sc = *(s + c as u64)
    var sd = *(s + d as u64)
    sa +%= sb
    sd = (sd ^ sa).rotate_left(16)
    sc +%= sd
    sb = (sb ^ sc).rotate_left(12)
    sa +%= sb
    sd = (sd ^ sa).rotate_left(8)
    sc +%= sd
    sb = (sb ^ sc).rotate_left(7)
    *(s + a as u64) = sa
    *(s + b as u64) = sb
    *(s + c as u64) = sc
    *(s + d as u64) = sd

unsafe fn chacha20_block(key: *const u8, nonce: *const u8, counter: u32, out: *mut u8):
    var state: [u32; 16] = [0 as u32; 16]
    let sp = &raw mut state[0] as *mut u32
    // "expand 32-byte k"
    *(sp + 0 as u64) = 0x61707865 as u32
    *(sp + 1 as u64) = 0x3320646e as u32
    *(sp + 2 as u64) = 0x79622d32 as u32
    *(sp + 3 as u64) = 0x6b206574 as u32
    for i in 0..8:
        *(sp + (4 + i) as u64) = u32_from_le(key, i * 4)
    *(sp + 12 as u64) = counter
    for i in 0..3:
        *(sp + (13 + i) as u64) = u32_from_le(nonce, i * 4)

    var working: [u32; 16] = [0 as u32; 16]
    let wp = &raw mut working[0] as *mut u32
    for i in 0..16:
        *(wp + i as u64) = state[i]

    for i in 0..10:
        qr(wp, 0, 4, 8, 12)
        qr(wp, 1, 5, 9, 13)
        qr(wp, 2, 6, 10, 14)
        qr(wp, 3, 7, 11, 15)
        qr(wp, 0, 5, 10, 15)
        qr(wp, 1, 6, 11, 12)
        qr(wp, 2, 7, 8, 13)
        qr(wp, 3, 4, 9, 14)

    for i in 0..16:
        working[i] +%= state[i]

    for i in 0..16:
        u32_to_le(out, i * 4, working[i])

unsafe fn chacha20_crypt(key: *const u8, nonce: *const u8, counter: u32, data: *mut u8, len: i32):
    var ctr = counter
    var off = 0
    while off < len:
        var block: [u8; 64] = [0 as u8; 64]
        let bp = &raw mut block[0] as *mut u8
        chacha20_block(key, nonce, ctr, bp)
        let remaining = len - off
        let chunk = if remaining < 64: remaining else: 64
        for i in 0..chunk:
            *(data + (off + i) as u64) = *(data + (off + i) as u64) ^ block[i]
        ctr +%= 1 as u32
        off = off + 64
