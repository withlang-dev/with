// ChaCha20 stream cipher — RFC 8439
// Ported from BearSSL src/symcipher/chacha20_ct.c

// Quarter-round on state array
fn qr(s: *mut u32, a: i32, b: i32, c: i32, d: i32):
    var sa = unsafe: *(s + a as u64)
    var sb = unsafe: *(s + b as u64)
    var sc = unsafe: *(s + c as u64)
    var sd = unsafe: *(s + d as u64)
    sa = sa +% sb
    sd = rotl32(sd ^ sa, 16)
    sc = sc +% sd
    sb = rotl32(sb ^ sc, 12)
    sa = sa +% sb
    sd = rotl32(sd ^ sa, 8)
    sc = sc +% sd
    sb = rotl32(sb ^ sc, 7)
    unsafe: *(s + a as u64) = sa
    unsafe: *(s + b as u64) = sb
    unsafe: *(s + c as u64) = sc
    unsafe: *(s + d as u64) = sd

fn rotl32(x: u32, n: i32) -> u32:
    (x << n as u32) | (x >> (32 - n) as u32)

// Load 32-bit little-endian
fn load32le(p: *const u8, off: i32) -> u32:
    let b0 = (unsafe: *(p + off as u64)) as u32
    let b1 = (unsafe: *(p + (off + 1) as u64)) as u32
    let b2 = (unsafe: *(p + (off + 2) as u64)) as u32
    let b3 = (unsafe: *(p + (off + 3) as u64)) as u32
    b0 | (b1 << 8 as u32) | (b2 << 16 as u32) | (b3 << 24 as u32)

// Store 32-bit little-endian
fn store32le(p: *mut u8, off: i32, val: u32):
    unsafe: *(p + off as u64) = val as u8
    unsafe: *(p + (off + 1) as u64) = (val >> 8 as u32) as u8
    unsafe: *(p + (off + 2) as u64) = (val >> 16 as u32) as u8
    unsafe: *(p + (off + 3) as u64) = (val >> 24 as u32) as u8

// Generate 64-byte keystream block for given counter
fn chacha20_block(key: *const u8, nonce: *const u8, counter: u32, out: *mut u8):
    var state: [u32; 16] = [0 as u32; 16]
    let sp = &mut state[0] as *mut u32
    // "expand 32-byte k" constants
    unsafe: *(sp + 0 as u64) = 0x61707865 as u32
    unsafe: *(sp + 1 as u64) = 0x3320646e as u32
    unsafe: *(sp + 2 as u64) = 0x79622d32 as u32
    unsafe: *(sp + 3 as u64) = 0x6b206574 as u32
    // Key
    for i in 0..8:
        unsafe: *(sp + (4 + i) as u64) = load32le(key, i * 4)
    // Counter
    unsafe: *(sp + 12 as u64) = counter
    // Nonce
    for i in 0..3:
        unsafe: *(sp + (13 + i) as u64) = load32le(nonce, i * 4)

    // Copy initial state
    var working: [u32; 16] = [0 as u32; 16]
    let wp = &mut working[0] as *mut u32
    for i in 0..16:
        unsafe: *(wp + i as u64) = unsafe: *(sp + i as u64)

    // 20 rounds (10 double-rounds)
    for i in 0..10:
        // Column rounds
        qr(wp, 0, 4, 8, 12)
        qr(wp, 1, 5, 9, 13)
        qr(wp, 2, 6, 10, 14)
        qr(wp, 3, 7, 11, 15)
        // Diagonal rounds
        qr(wp, 0, 5, 10, 15)
        qr(wp, 1, 6, 11, 12)
        qr(wp, 2, 7, 8, 13)
        qr(wp, 3, 4, 9, 14)

    // Add initial state
    for i in 0..16:
        unsafe: *(wp + i as u64) = (unsafe: *(wp + i as u64)) +% (unsafe: *(sp + i as u64))

    // Serialize to bytes (little-endian)
    for i in 0..16:
        store32le(out, i * 4, unsafe: *(wp + i as u64))

// Encrypt/decrypt data with ChaCha20 (XOR with keystream)
fn chacha20_crypt(key: *const u8, nonce: *const u8, counter: u32, data: *mut u8, len: i32):
    var ctr = counter
    var off = 0
    while off < len:
        var block: [u8; 64] = [0 as u8; 64]
        let bp = &mut block[0] as *mut u8
        chacha20_block(key, nonce, ctr, bp)
        let remaining = len - off
        let chunk = if remaining < 64: remaining else: 64
        for i in 0..chunk:
            unsafe: *(data + (off + i) as u64) = (unsafe: *(data + (off + i) as u64)) ^ block[i]
        ctr = ctr +% 1 as u32
        off = off + 64
