// SHA-256 implementation — ported from BearSSL src/hash/sha2small.c
// Constant-time, no dynamic allocation.

use std.crypto.endian
use std.internal.str_abi

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

    var a = ctx.state[0]
    var b = ctx.state[1]
    var c = ctx.state[2]
    var d = ctx.state[3]
    var e = ctx.state[4]
    var f = ctx.state[5]
    var g = ctx.state[6]
    var h = ctx.state[7]

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

// Convenience: hash a string
pub fn sha256_hash_str(s: str, out: *mut u8) -> Unit:
    unsafe:
        let bytes = str_copy_bytes(s)
        sha256_hash(bytes as *const u8, s.len() as i32, out)
        str_free_bytes(bytes)

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
