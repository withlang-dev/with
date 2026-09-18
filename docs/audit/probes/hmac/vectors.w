// Internal stdlib bridge helpers for byte-oriented routines.
//
// Use this only when stdlib code must pass a str's bytes to a raw pointer API.
// A str is an aggregate value; casting the str itself to *const u8 points at
// the aggregate, not at the payload.

extern fn with_alloc(size: i64) -> *mut u8
extern fn with_free(ptr: *mut u8) -> Unit

pub unsafe fn str_copy_bytes(s: &str) -> *mut u8:
    let out = with_alloc(s.len() + 1)
    let data = **(&s as *const *const *const u8)
    var i: i64 = 0
    while i < s.len():
        *((out as i64 + i) as *mut u8) = data[i]
        i = i + 1
    *((out as i64 + s.len()) as *mut u8) = 0
    out

pub unsafe fn str_free_bytes(p: *mut u8) -> Unit:
    with_free(p)

// Byte-order encode/decode utilities for crypto and network code.
// These should eventually be compiler intrinsics on integer types
// (u32.from_be, etc.), but for now they are standalone functions.

fn u16_from_be(buf: *const u8, off: i32) -> u16:
    let b0 = (unsafe *(buf + off as u64)) as u16
    let b1 = (unsafe *(buf + (off + 1) as u64)) as u16
    (b0 << 8 as u16) | b1

fn u16_from_le(buf: *const u8, off: i32) -> u16:
    let b0 = (unsafe *(buf + off as u64)) as u16
    let b1 = (unsafe *(buf + (off + 1) as u64)) as u16
    b0 | (b1 << 8 as u16)

fn u32_from_be(buf: *const u8, off: i32) -> u32:
    let b0 = (unsafe *(buf + off as u64)) as u32
    let b1 = (unsafe *(buf + (off + 1) as u64)) as u32
    let b2 = (unsafe *(buf + (off + 2) as u64)) as u32
    let b3 = (unsafe *(buf + (off + 3) as u64)) as u32
    (b0 << 24 as u32) | (b1 << 16 as u32) | (b2 << 8 as u32) | b3

fn u32_from_le(buf: *const u8, off: i32) -> u32:
    let b0 = (unsafe *(buf + off as u64)) as u32
    let b1 = (unsafe *(buf + (off + 1) as u64)) as u32
    let b2 = (unsafe *(buf + (off + 2) as u64)) as u32
    let b3 = (unsafe *(buf + (off + 3) as u64)) as u32
    b0 | (b1 << 8 as u32) | (b2 << 16 as u32) | (b3 << 24 as u32)

fn u64_from_be(buf: *const u8, off: i32) -> u64:
    let hi = u32_from_be(buf, off) as u64
    let lo = u32_from_be(buf, off + 4) as u64
    (hi << 32 as u64) | lo

fn u64_from_le(buf: *const u8, off: i32) -> u64:
    let lo = u32_from_le(buf, off) as u64
    let hi = u32_from_le(buf, off + 4) as u64
    (hi << 32 as u64) | lo

fn u16_to_be(buf: *mut u8, off: i32, val: u16):
    unsafe *(buf + off as u64) = (val >> 8 as u16) as u8
    unsafe *(buf + (off + 1) as u64) = val as u8

fn u16_to_le(buf: *mut u8, off: i32, val: u16):
    unsafe *(buf + off as u64) = val as u8
    unsafe *(buf + (off + 1) as u64) = (val >> 8 as u16) as u8

fn u32_to_be(buf: *mut u8, off: i32, val: u32):
    unsafe *(buf + off as u64) = (val >> 24 as u32) as u8
    unsafe *(buf + (off + 1) as u64) = (val >> 16 as u32) as u8
    unsafe *(buf + (off + 2) as u64) = (val >> 8 as u32) as u8
    unsafe *(buf + (off + 3) as u64) = val as u8

fn u32_to_le(buf: *mut u8, off: i32, val: u32):
    unsafe *(buf + off as u64) = val as u8
    unsafe *(buf + (off + 1) as u64) = (val >> 8 as u32) as u8
    unsafe *(buf + (off + 2) as u64) = (val >> 16 as u32) as u8
    unsafe *(buf + (off + 3) as u64) = (val >> 24 as u32) as u8

fn u64_to_be(buf: *mut u8, off: i32, val: u64):
    u32_to_be(buf, off, (val >> 32 as u64) as u32)
    u32_to_be(buf, off + 4, val as u32)

fn u64_to_le(buf: *mut u8, off: i32, val: u64):
    u32_to_le(buf, off, val as u32)
    u32_to_le(buf, off + 4, (val >> 32 as u64) as u32)

// SHA-256 implementation — ported from BearSSL src/hash/sha2small.c
// Constant-time, no dynamic allocation.


type Sha256  {
    state: [u32; 8],
    buf: [u8; 64],
    count: u64,
}

fn Sha256.new -> Sha256:
    Sha256 {
        state: [
            0x6a09e667 as u32, 0xbb67ae85 as u32,
            0x3c6ef372 as u32, 0xa54ff53a as u32,
            0x510e527f as u32, 0x9b05688c as u32,
            0x1f83d9ab as u32, 0x5be0cd19 as u32,
        ],
        buf: [0 as u8; 64],
        count: 0 as u64,
    }

// Round constants
fn sha256_k(i: i32) -> u32:
    let k = [
        0x428a2f98 as u32, 0x71374491 as u32, 0xb5c0fbcf as u32, 0xe9b5dba5 as u32,
        0x3956c25b as u32, 0x59f111f1 as u32, 0x923f82a4 as u32, 0xab1c5ed5 as u32,
        0xd807aa98 as u32, 0x12835b01 as u32, 0x243185be as u32, 0x550c7dc3 as u32,
        0x72be5d74 as u32, 0x80deb1fe as u32, 0x9bdc06a7 as u32, 0xc19bf174 as u32,
        0xe49b69c1 as u32, 0xefbe4786 as u32, 0x0fc19dc6 as u32, 0x240ca1cc as u32,
        0x2de92c6f as u32, 0x4a7484aa as u32, 0x5cb0a9dc as u32, 0x76f988da as u32,
        0x983e5152 as u32, 0xa831c66d as u32, 0xb00327c8 as u32, 0xbf597fc7 as u32,
        0xc6e00bf3 as u32, 0xd5a79147 as u32, 0x06ca6351 as u32, 0x14292967 as u32,
        0x27b70a85 as u32, 0x2e1b2138 as u32, 0x4d2c6dfc as u32, 0x53380d13 as u32,
        0x650a7354 as u32, 0x766a0abb as u32, 0x81c2c92e as u32, 0x92722c85 as u32,
        0xa2bfe8a1 as u32, 0xa81a664b as u32, 0xc24b8b70 as u32, 0xc76c51a3 as u32,
        0xd192e819 as u32, 0xd6990624 as u32, 0xf40e3585 as u32, 0x106aa070 as u32,
        0x19a4c116 as u32, 0x1e376c08 as u32, 0x2748774c as u32, 0x34b0bcb5 as u32,
        0x391c0cb3 as u32, 0x4ed8aa4a as u32, 0x5b9cca4f as u32, 0x682e6ff3 as u32,
        0x748f82ee as u32, 0x78a5636f as u32, 0x84c87814 as u32, 0x8cc70208 as u32,
        0x90befffa as u32, 0xa4506ceb as u32, 0xbef9a3f7 as u32, 0xc67178f2 as u32,
    ]
    k[i]

fn ch(e: u32, f: u32, g: u32) -> u32:
    (e & f) ^ ((~e) & g)

fn maj(a: u32, b: u32, c: u32) -> u32:
    (a & b) ^ (a & c) ^ (b & c)

fn sigma0(x: u32) -> u32:
    x.rotate_right(2) ^ x.rotate_right(13) ^ x.rotate_right(22)

fn sigma1(x: u32) -> u32:
    x.rotate_right(6) ^ x.rotate_right(11) ^ x.rotate_right(25)

fn ssig0(x: u32) -> u32:
    x.rotate_right(7) ^ x.rotate_right(18) ^ (x >> 3 as u32)

fn ssig1(x: u32) -> u32:
    x.rotate_right(17) ^ x.rotate_right(19) ^ (x >> 10 as u32)

// Process one 64-byte block
unsafe fn sha256_compress(ctx: *mut Sha256):
    var w: [u32; 64] = [0 as u32; 64]
    for i in 0..16:
        w[i] = u32_from_be(&ctx.buf[0] as *const u8, i * 4)
    for i in 16..64:
        w[i] = ssig1(w[i - 2]) +% w[i - 7] +% ssig0(w[i - 15]) +% w[i - 16]

    var a: u32 = ctx.state[0]
    var b: u32 = ctx.state[1]
    var c: u32 = ctx.state[2]
    var d: u32 = ctx.state[3]
    var e: u32 = ctx.state[4]
    var f: u32 = ctx.state[5]
    var g: u32 = ctx.state[6]
    var h: u32 = ctx.state[7]

    for i in 0..64:
        let t1 = h +% sigma1(e) +% ch(e, f, g) +% sha256_k(i) +% w[i]
        let t2 = sigma0(a) +% maj(a, b, c)
        h = g
        g = f
        f = e
        e = d +% t1
        d = c
        c = b
        b = a
        a = t1 +% t2

    ctx.state[0] +%= a
    ctx.state[1] +%= b
    ctx.state[2] +%= c
    ctx.state[3] +%= d
    ctx.state[4] +%= e
    ctx.state[5] +%= f
    ctx.state[6] +%= g
    ctx.state[7] +%= h

// Update hash with input data
unsafe fn sha256_update(ctx: *mut Sha256, data: *const u8, len: i32):
    var off = 0
    var bp = (ctx.count % 64 as u64) as i32
    ctx.count = ctx.count + len as u64
    while off < len:
        ctx.buf[bp] = *(data + off as u64)
        bp = bp + 1
        off = off + 1
        if bp == 64:
            sha256_compress(ctx)
            bp = 0

// Finalize and produce 32-byte digest
unsafe fn sha256_finish(ctx: *mut Sha256, out: *mut u8):
    let total_bits = ctx.count * 8 as u64

    // Padding: append 0x80 byte
    var pad: [u8; 1] = [0x80 as u8]
    sha256_update(ctx, &pad[0] as *const u8, 1)

    // Pad with zeros until 56 mod 64
    pad[0] = 0 as u8
    var zeros_needed = 56 - (ctx.count % 64 as u64) as i32
    if zeros_needed < 0:
        zeros_needed = zeros_needed + 64
    for i in 0..zeros_needed:
        sha256_update(ctx, &pad[0] as *const u8, 1)

    // Append length in bits (big-endian, 8 bytes)
    var len_buf: [u8; 8] = [0 as u8; 8]
    u64_to_be(&raw mut len_buf[0] as *mut u8, 0, total_bits)
    sha256_update(ctx, &len_buf[0] as *const u8, 8)

    // Output digest (big-endian)
    for i in 0..8:
        u32_to_be(out, i * 4, ctx.state[i])

// Convenience: hash a byte buffer and return 32-byte digest
pub fn sha256_hash(data: *const u8, len: i32, out: *mut u8) -> Unit:
    var ctx = Sha256.new()
    let p = &raw mut ctx as *mut Sha256
    unsafe { sha256_update(p, data, len) }
    unsafe { sha256_finish(p, out) }

// Convenience: hash a string (observer — reads, never retains; D5)
pub fn sha256_hash_str(s: &str, out: *mut u8) -> Unit:
    unsafe:
        let bytes = str_copy_bytes(s)
        sha256_hash(bytes as *const u8, s.len() as i32, out)
        str_free_bytes(bytes)

// Hash the concatenation a ++ b without materializing it. Digest-identical to
// sha256_hash_str(a ++ b) — callers with a large payload use this so the
// payload never enters a `++` chain.
pub fn sha256_hash_str_pair(a: &str, b: &str, out: *mut u8) -> Unit:
    var ctx = Sha256.new()
    let p = &raw mut ctx as *mut Sha256
    unsafe:
        let ab = str_copy_bytes(a)
        sha256_update(p, ab as *const u8, a.len() as i32)
        str_free_bytes(ab)
        let bb = str_copy_bytes(b)
        sha256_update(p, bb as *const u8, b.len() as i32)
        str_free_bytes(bb)
        sha256_finish(p, out)

// Format digest as hex string
pub fn sha256_hex(digest: *const u8) -> str:
    let hex_chars = "0123456789abcdef"
    var result = ""
    for i in 0..32:
        let b = (unsafe *(digest + i as u64)) as i32
        let hi = (b >> 4) & 0x0F
        let lo = b & 0x0F
        result = result ++ hex_chars.slice(hi as i64, (hi + 1) as i64) ++ hex_chars.slice(lo as i64, (lo + 1) as i64)
    result

// HMAC-SHA256 — RFC 2104 using SHA-256.
// Ported from BearSSL src/mac/hmac.c


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
            padded_key[i] = unsafe *(key + i as u64)

    var ipad_key: [u8; 64] = [0 as u8; 64]
    var outer_key: [u8; 64] = [0 as u8; 64]
    for i in 0..64:
        ipad_key[i] = padded_key[i] ^ (0x36 as u8)
        outer_key[i] = padded_key[i] ^ (0x5C as u8)

    var inner = Sha256.new()
    let ip = &raw mut inner as *mut Sha256
    unsafe { sha256_update(ip, &ipad_key[0] as *const u8, 64) }

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
    unsafe { hmac_update(p, data, data_len) }
    unsafe { hmac_finish(p, out) }

fn hmac_sha256_str(key: str, data: str, out: *mut u8):
    unsafe:
        let key_bytes = str_copy_bytes(key)
        let data_bytes = str_copy_bytes(data)
        hmac_sha256(key_bytes as *const u8, key.len() as i32, data_bytes as *const u8, data.len() as i32, out)
        str_free_bytes(data_bytes)
        str_free_bytes(key_bytes)

use std.builtins.print_i32
fn main -> i32:
    var k0: [u8; 20] = [0u8; 20]
    k0[0] = 11u8
    k0[1] = 11u8
    k0[2] = 11u8
    k0[3] = 11u8
    k0[4] = 11u8
    k0[5] = 11u8
    k0[6] = 11u8
    k0[7] = 11u8
    k0[8] = 11u8
    k0[9] = 11u8
    k0[10] = 11u8
    k0[11] = 11u8
    k0[12] = 11u8
    k0[13] = 11u8
    k0[14] = 11u8
    k0[15] = 11u8
    k0[16] = 11u8
    k0[17] = 11u8
    k0[18] = 11u8
    k0[19] = 11u8
    var d0: [u8; 8] = [0u8; 8]
    d0[0] = 72u8
    d0[1] = 105u8
    d0[2] = 32u8
    d0[3] = 84u8
    d0[4] = 104u8
    d0[5] = 101u8
    d0[6] = 114u8
    d0[7] = 101u8
    var t0: [u8; 32] = [0u8; 32]
    hmac_sha256(&k0[0] as *const u8, 20, &d0[0] as *const u8, 8, &raw mut t0[0] as *mut u8)
    var q0 = 0
    while q0 < 32:
        print_i32(t0[q0] as i32)
        q0 = q0 + 1
    var k1: [u8; 4] = [0u8; 4]
    k1[0] = 74u8
    k1[1] = 101u8
    k1[2] = 102u8
    k1[3] = 101u8
    var d1: [u8; 28] = [0u8; 28]
    d1[0] = 119u8
    d1[1] = 104u8
    d1[2] = 97u8
    d1[3] = 116u8
    d1[4] = 32u8
    d1[5] = 100u8
    d1[6] = 111u8
    d1[7] = 32u8
    d1[8] = 121u8
    d1[9] = 97u8
    d1[10] = 32u8
    d1[11] = 119u8
    d1[12] = 97u8
    d1[13] = 110u8
    d1[14] = 116u8
    d1[15] = 32u8
    d1[16] = 102u8
    d1[17] = 111u8
    d1[18] = 114u8
    d1[19] = 32u8
    d1[20] = 110u8
    d1[21] = 111u8
    d1[22] = 116u8
    d1[23] = 104u8
    d1[24] = 105u8
    d1[25] = 110u8
    d1[26] = 103u8
    d1[27] = 63u8
    var t1: [u8; 32] = [0u8; 32]
    hmac_sha256(&k1[0] as *const u8, 4, &d1[0] as *const u8, 28, &raw mut t1[0] as *mut u8)
    var q1 = 0
    while q1 < 32:
        print_i32(t1[q1] as i32)
        q1 = q1 + 1
    var k2: [u8; 80] = [0u8; 80]
    k2[0] = 0u8
    k2[1] = 1u8
    k2[2] = 2u8
    k2[3] = 3u8
    k2[4] = 4u8
    k2[5] = 5u8
    k2[6] = 6u8
    k2[7] = 7u8
    k2[8] = 8u8
    k2[9] = 9u8
    k2[10] = 10u8
    k2[11] = 11u8
    k2[12] = 12u8
    k2[13] = 13u8
    k2[14] = 14u8
    k2[15] = 15u8
    k2[16] = 16u8
    k2[17] = 17u8
    k2[18] = 18u8
    k2[19] = 19u8
    k2[20] = 20u8
    k2[21] = 21u8
    k2[22] = 22u8
    k2[23] = 23u8
    k2[24] = 24u8
    k2[25] = 25u8
    k2[26] = 26u8
    k2[27] = 27u8
    k2[28] = 28u8
    k2[29] = 29u8
    k2[30] = 30u8
    k2[31] = 31u8
    k2[32] = 32u8
    k2[33] = 33u8
    k2[34] = 34u8
    k2[35] = 35u8
    k2[36] = 36u8
    k2[37] = 37u8
    k2[38] = 38u8
    k2[39] = 39u8
    k2[40] = 40u8
    k2[41] = 41u8
    k2[42] = 42u8
    k2[43] = 43u8
    k2[44] = 44u8
    k2[45] = 45u8
    k2[46] = 46u8
    k2[47] = 47u8
    k2[48] = 48u8
    k2[49] = 49u8
    k2[50] = 50u8
    k2[51] = 51u8
    k2[52] = 52u8
    k2[53] = 53u8
    k2[54] = 54u8
    k2[55] = 55u8
    k2[56] = 56u8
    k2[57] = 57u8
    k2[58] = 58u8
    k2[59] = 59u8
    k2[60] = 60u8
    k2[61] = 61u8
    k2[62] = 62u8
    k2[63] = 63u8
    k2[64] = 64u8
    k2[65] = 65u8
    k2[66] = 66u8
    k2[67] = 67u8
    k2[68] = 68u8
    k2[69] = 69u8
    k2[70] = 70u8
    k2[71] = 71u8
    k2[72] = 72u8
    k2[73] = 73u8
    k2[74] = 74u8
    k2[75] = 75u8
    k2[76] = 76u8
    k2[77] = 77u8
    k2[78] = 78u8
    k2[79] = 79u8
    var d2: [u8; 3] = [0u8; 3]
    d2[0] = 97u8
    d2[1] = 98u8
    d2[2] = 99u8
    var t2: [u8; 32] = [0u8; 32]
    hmac_sha256(&k2[0] as *const u8, 80, &d2[0] as *const u8, 3, &raw mut t2[0] as *mut u8)
    var q2 = 0
    while q2 < 32:
        print_i32(t2[q2] as i32)
        q2 = q2 + 1
    var k3: [u8; 3] = [0u8; 3]
    k3[0] = 107u8
    k3[1] = 101u8
    k3[2] = 121u8
    var d3: [u8; 1] = [0u8; 1]
    var t3: [u8; 32] = [0u8; 32]
    hmac_sha256(&k3[0] as *const u8, 3, &d3[0] as *const u8, 0, &raw mut t3[0] as *mut u8)
    var q3 = 0
    while q3 < 32:
        print_i32(t3[q3] as i32)
        q3 = q3 + 1
    var k4: [u8; 1] = [0u8; 1]
    var d4: [u8; 4] = [0u8; 4]
    d4[0] = 100u8
    d4[1] = 97u8
    d4[2] = 116u8
    d4[3] = 97u8
    var t4: [u8; 32] = [0u8; 32]
    hmac_sha256(&k4[0] as *const u8, 0, &d4[0] as *const u8, 4, &raw mut t4[0] as *mut u8)
    var q4 = 0
    while q4 < 32:
        print_i32(t4[q4] as i32)
        q4 = q4 + 1
    0
