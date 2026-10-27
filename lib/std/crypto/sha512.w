// SHA-512 and SHA-384 — the 64-bit-word member of the SHA-2 family,
// in the same shape as sha256.w. SHA-384 is SHA-512 with its own
// initial state, truncated to 48 bytes. Constant-time, no allocation
// beyond the caller's buffers.

use std.crypto.endian
use std.internal.str_abi

type Sha512  {
    state: [u64; 8],
    buf: [u8; 128],
    count: u64,
}

fn Sha512.new -> Sha512:
    Sha512 {
        state: [
            0x6a09e667f3bcc908 as u64, 0xbb67ae8584caa73b as u64,
            0x3c6ef372fe94f82b as u64, 0xa54ff53a5f1d36f1 as u64,
            0x510e527fade682d1 as u64, 0x9b05688c2b3e6c1f as u64,
            0x1f83d9abfb41bd6b as u64, 0x5be0cd19137e2179 as u64,
        ],
        buf: [0 as u8; 128],
        count: 0 as u64,
    }

fn Sha512.new384 -> Sha512:
    Sha512 {
        state: [
            0xcbbb9d5dc1059ed8 as u64, 0x629a292a367cd507 as u64,
            0x9159015a3070dd17 as u64, 0x152fecd8f70e5939 as u64,
            0x67332667ffc00b31 as u64, 0x8eb44a8768581511 as u64,
            0xdb0c2e0d64f98fa7 as u64, 0x47b5481dbefa4fa4 as u64,
        ],
        buf: [0 as u8; 128],
        count: 0 as u64,
    }

const SHA512_K: [u64; 80] = [
    0x428a2f98d728ae22 as u64, 0x7137449123ef65cd as u64, 0xb5c0fbcfec4d3b2f as u64, 0xe9b5dba58189dbbc as u64,
    0x3956c25bf348b538 as u64, 0x59f111f1b605d019 as u64, 0x923f82a4af194f9b as u64, 0xab1c5ed5da6d8118 as u64,
    0xd807aa98a3030242 as u64, 0x12835b0145706fbe as u64, 0x243185be4ee4b28c as u64, 0x550c7dc3d5ffb4e2 as u64,
    0x72be5d74f27b896f as u64, 0x80deb1fe3b1696b1 as u64, 0x9bdc06a725c71235 as u64, 0xc19bf174cf692694 as u64,
    0xe49b69c19ef14ad2 as u64, 0xefbe4786384f25e3 as u64, 0x0fc19dc68b8cd5b5 as u64, 0x240ca1cc77ac9c65 as u64,
    0x2de92c6f592b0275 as u64, 0x4a7484aa6ea6e483 as u64, 0x5cb0a9dcbd41fbd4 as u64, 0x76f988da831153b5 as u64,
    0x983e5152ee66dfab as u64, 0xa831c66d2db43210 as u64, 0xb00327c898fb213f as u64, 0xbf597fc7beef0ee4 as u64,
    0xc6e00bf33da88fc2 as u64, 0xd5a79147930aa725 as u64, 0x06ca6351e003826f as u64, 0x142929670a0e6e70 as u64,
    0x27b70a8546d22ffc as u64, 0x2e1b21385c26c926 as u64, 0x4d2c6dfc5ac42aed as u64, 0x53380d139d95b3df as u64,
    0x650a73548baf63de as u64, 0x766a0abb3c77b2a8 as u64, 0x81c2c92e47edaee6 as u64, 0x92722c851482353b as u64,
    0xa2bfe8a14cf10364 as u64, 0xa81a664bbc423001 as u64, 0xc24b8b70d0f89791 as u64, 0xc76c51a30654be30 as u64,
    0xd192e819d6ef5218 as u64, 0xd69906245565a910 as u64, 0xf40e35855771202a as u64, 0x106aa07032bbd1b8 as u64,
    0x19a4c116b8d2d0c8 as u64, 0x1e376c085141ab53 as u64, 0x2748774cdf8eeb99 as u64, 0x34b0bcb5e19b48a8 as u64,
    0x391c0cb3c5c95a63 as u64, 0x4ed8aa4ae3418acb as u64, 0x5b9cca4f7763e373 as u64, 0x682e6ff3d6b2b8a3 as u64,
    0x748f82ee5defb2fc as u64, 0x78a5636f43172f60 as u64, 0x84c87814a1f0ab72 as u64, 0x8cc702081a6439ec as u64,
    0x90befffa23631e28 as u64, 0xa4506cebde82bde9 as u64, 0xbef9a3f7b2c67915 as u64, 0xc67178f2e372532b as u64,
    0xca273eceea26619c as u64, 0xd186b8c721c0c207 as u64, 0xeada7dd6cde0eb1e as u64, 0xf57d4f7fee6ed178 as u64,
    0x06f067aa72176fba as u64, 0x0a637dc5a2c898a6 as u64, 0x113f9804bef90dae as u64, 0x1b710b35131c471b as u64,
    0x28db77f523047d84 as u64, 0x32caab7b40c72493 as u64, 0x3c9ebe0a15c9bebc as u64, 0x431d67c49c100d4c as u64,
    0x4cc5d4becb3e42b6 as u64, 0x597f299cfc657e2a as u64, 0x5fcb6fab3ad6faec as u64, 0x6c44198c4a475817 as u64,
]

fn ch512(e: u64, f: u64, g: u64) -> u64:
    (e & f) ^ ((~e) & g)

fn maj512(a: u64, b: u64, c: u64) -> u64:
    (a & b) ^ (a & c) ^ (b & c)

fn big_sigma0(x: u64) -> u64:
    x.rotate_right(28) ^ x.rotate_right(34) ^ x.rotate_right(39)

fn big_sigma1(x: u64) -> u64:
    x.rotate_right(14) ^ x.rotate_right(18) ^ x.rotate_right(41)

fn small_sigma0(x: u64) -> u64:
    x.rotate_right(1) ^ x.rotate_right(8) ^ (x >> 7 as u64)

fn small_sigma1(x: u64) -> u64:
    x.rotate_right(19) ^ x.rotate_right(61) ^ (x >> 6 as u64)

// Process one 128-byte block
unsafe fn sha512_compress(ctx: *mut Sha512):
    var w: [u64; 80] = [0 as u64; 80]
    for i in 0..16:
        w[i] = u64_from_be(&ctx.buf[0] as *const u8, i * 8)
    for i in 16..80:
        w[i] = small_sigma1(w[i - 2]) +% w[i - 7] +% small_sigma0(w[i - 15]) +% w[i - 16]

    var a: u64 = ctx.state[0]
    var b: u64 = ctx.state[1]
    var c: u64 = ctx.state[2]
    var d: u64 = ctx.state[3]
    var e: u64 = ctx.state[4]
    var f: u64 = ctx.state[5]
    var g: u64 = ctx.state[6]
    var h: u64 = ctx.state[7]

    for i in 0..80:
        let t1 = h +% big_sigma1(e) +% ch512(e, f, g) +% SHA512_K[i] +% w[i]
        let t2 = big_sigma0(a) +% maj512(a, b, c)
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

unsafe fn sha512_update(ctx: *mut Sha512, data: *const u8, len: i32):
    var off = 0
    var bp = (ctx.count % 128 as u64) as i32
    ctx.count = ctx.count + len as u64
    while off < len:
        ctx.buf[bp] = *(data + off as u64)
        bp = bp + 1
        off = off + 1
        if bp == 128:
            sha512_compress(ctx)
            bp = 0

// Finalize and produce the 64-byte digest (callers truncate for SHA-384)
unsafe fn sha512_finish(ctx: *mut Sha512, out: *mut u8):
    let total_bits = ctx.count * 8 as u64

    var pad: [u8; 1] = [0x80 as u8]
    sha512_update(ctx, &pad[0] as *const u8, 1)

    pad[0] = 0 as u8
    var zeros_needed = 112 - (ctx.count % 128 as u64) as i32
    if zeros_needed < 0:
        zeros_needed = zeros_needed + 128
    for i in 0..zeros_needed:
        sha512_update(ctx, &pad[0] as *const u8, 1)

    // 128-bit length: high half zero for any input hashed here.
    var len_buf: [u8; 16] = [0 as u8; 16]
    u64_to_be(&raw mut len_buf[0] as *mut u8, 8, total_bits)
    sha512_update(ctx, &len_buf[0] as *const u8, 16)

    for i in 0..8:
        u64_to_be(out, i * 8, ctx.state[i])

// Convenience: hash a byte buffer, 64-byte digest
pub fn sha512_hash(data: *const u8, len: i32, out: *mut u8):
    var ctx = Sha512.new()
    let p = &raw mut ctx as *mut Sha512
    unsafe { sha512_update(p, data, len) }
    unsafe { sha512_finish(p, out) }

// Convenience: hash a byte buffer, 48-byte SHA-384 digest
pub fn sha384_hash(data: *const u8, len: i32, out: *mut u8):
    var ctx = Sha512.new384()
    let p = &raw mut ctx as *mut Sha512
    unsafe { sha512_update(p, data, len) }
    unsafe { sha512_finish(p, out) }

// Convenience: hash a string (observer — reads, never retains; D5)
pub fn sha512_hash_str(s: &str, out: *mut u8):
    unsafe:
        let bytes = str_copy_bytes(s)
        let n = s.len()
        sha512_hash(bytes as *const u8, n as i32, out)
        str_free_bytes(bytes)

pub fn sha384_hash_str(s: &str, out: *mut u8):
    unsafe:
        let bytes = str_copy_bytes(s)
        let n = s.len()
        sha384_hash(bytes as *const u8, n as i32, out)
        str_free_bytes(bytes)
