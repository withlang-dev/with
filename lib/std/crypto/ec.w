// Elliptic curve operations over NIST P-256
// Uses Jacobian coordinates and Montgomery multiplication via bigint i31.
//
// Curve: y² = x³ - 3x + b over F_p
// p = 2^256 - 2^224 + 2^192 + 2^96 - 1

use std.crypto.bigint

// Field element: 256-bit value in i31 format.
// Header (1) + 9 limbs = 10 u32s. Use 12 for safety.
let FE_WORDS: i32 = 12

// Initialize field prime p into dst (i31 format).
unsafe fn p256_load_p(dst: *mut u32):
    var p_bytes: [u8; 32] = [
        0xFFu8, 0xFFu8, 0xFFu8, 0xFFu8, 0x00u8, 0x00u8, 0x00u8, 0x01u8,
        0x00u8, 0x00u8, 0x00u8, 0x00u8, 0x00u8, 0x00u8, 0x00u8, 0x00u8,
        0x00u8, 0x00u8, 0x00u8, 0x00u8, 0xFFu8, 0xFFu8, 0xFFu8, 0xFFu8,
        0xFFu8, 0xFFu8, 0xFFu8, 0xFFu8, 0xFFu8, 0xFFu8, 0xFFu8, 0xFFu8,
    ]
    i31_decode(dst, &p_bytes[0] as *const u8, 32)

// Initialize curve order n into dst (i31 format).
unsafe fn p256_load_n(dst: *mut u32):
    var n_bytes: [u8; 32] = [
        0xFFu8, 0xFFu8, 0xFFu8, 0xFFu8, 0x00u8, 0x00u8, 0x00u8, 0x00u8,
        0xFFu8, 0xFFu8, 0xFFu8, 0xFFu8, 0xFFu8, 0xFFu8, 0xFFu8, 0xFFu8,
        0xBCu8, 0xE6u8, 0xFAu8, 0xADu8, 0xA7u8, 0x17u8, 0x9Eu8, 0x84u8,
        0xF3u8, 0xB9u8, 0xCAu8, 0xC2u8, 0xFCu8, 0x63u8, 0x25u8, 0x51u8,
    ]
    i31_decode(dst, &n_bytes[0] as *const u8, 32)

// Initialize curve parameter b into dst (i31 format, reduced mod p).
unsafe fn p256_load_b(dst: *mut u32, p: *const u32):
    var b_bytes: [u8; 32] = [
        0x5Au8, 0xC6u8, 0x35u8, 0xD8u8, 0xAAu8, 0x3Au8, 0x93u8, 0xE7u8,
        0xB3u8, 0xEBu8, 0xBDu8, 0x55u8, 0x76u8, 0x98u8, 0x86u8, 0xBCu8,
        0x65u8, 0x1Du8, 0x06u8, 0xB0u8, 0xCCu8, 0x53u8, 0xB0u8, 0xF6u8,
        0x3Bu8, 0xCEu8, 0x3Cu8, 0x3Eu8, 0x27u8, 0xD2u8, 0x60u8, 0x4Bu8,
    ]
    i31_decode_reduce(dst, &b_bytes[0] as *const u8, 32, p)

// Load generator point G coordinates.
unsafe fn p256_load_gx(dst: *mut u32, p: *const u32):
    var gx_bytes: [u8; 32] = [
        0x6Bu8, 0x17u8, 0xD1u8, 0xF2u8, 0xE1u8, 0x2Cu8, 0x42u8, 0x47u8,
        0xF8u8, 0xBCu8, 0xE6u8, 0xE5u8, 0x63u8, 0xA4u8, 0x40u8, 0xF2u8,
        0x77u8, 0x03u8, 0x7Du8, 0x81u8, 0x2Du8, 0xEBu8, 0x33u8, 0xA0u8,
        0xF4u8, 0xA1u8, 0x39u8, 0x45u8, 0xD8u8, 0x98u8, 0xC2u8, 0x96u8,
    ]
    i31_decode_reduce(dst, &gx_bytes[0] as *const u8, 32, p)

unsafe fn p256_load_gy(dst: *mut u32, p: *const u32):
    var gy_bytes: [u8; 32] = [
        0x4Fu8, 0xE3u8, 0x42u8, 0xE2u8, 0xFEu8, 0x1Au8, 0x7Fu8, 0x9Bu8,
        0x8Eu8, 0xE7u8, 0xEBu8, 0x4Au8, 0x7Cu8, 0x0Fu8, 0x9Eu8, 0x16u8,
        0x2Bu8, 0xCEu8, 0x33u8, 0x57u8, 0x6Bu8, 0x31u8, 0x5Eu8, 0xCEu8,
        0xCBu8, 0xB6u8, 0x40u8, 0x68u8, 0x37u8, 0xBFu8, 0x51u8, 0xF5u8,
    ]
    i31_decode_reduce(dst, &gy_bytes[0] as *const u8, 32, p)

// ── Field arithmetic (mod p) ───────────────────────────────────────

// dst = (a + b) mod p
unsafe fn fe_add(dst: *mut u32, a: *const u32, b: *const u32, p: *const u32):
    let mlen = i31_word_count(*(p + 0u64))
    // Copy a to dst
    var i = 0
    while i <= mlen:
        *(dst + i as u64) = *(a + i as u64)
        i = i + 1
    i31_add(dst, b, 0xFFFFFFFFu32)
    // Reduce if >= p
    let mlen2 = i31_word_count(*(dst + 0u64))
    i31_reduce_once(dst, p, mlen2)

// dst = (a - b) mod p
unsafe fn fe_sub(dst: *mut u32, a: *const u32, b: *const u32, p: *const u32):
    let mlen = i31_word_count(*(p + 0u64))
    var i = 0
    while i <= mlen:
        *(dst + i as u64) = *(a + i as u64)
        i = i + 1
    let borrow = i31_sub(dst, b, 0xFFFFFFFFu32)
    // If borrow, add p back
    if borrow != 0u32:
        i31_add(dst, p, 0xFFFFFFFFu32)

// dst = (a * b) mod p (Montgomery multiplication)
unsafe fn fe_mul(dst: *mut u32, a: *const u32, b: *const u32, p: *const u32, p0i: u32):
    i31_montmul(dst, a, b, p, p0i)

// dst = a² mod p
unsafe fn fe_sqr(dst: *mut u32, a: *const u32, p: *const u32, p0i: u32):
    i31_montmul(dst, a, a, p, p0i)

// dst = a^(-1) mod p using Fermat: a^(p-2) mod p
unsafe fn fe_inv(dst: *mut u32, a: *const u32, p: *const u32, p0i: u32):
    // p - 2 in bytes
    var pm2: [u8; 32] = [
        0xFFu8, 0xFFu8, 0xFFu8, 0xFFu8, 0x00u8, 0x00u8, 0x00u8, 0x01u8,
        0x00u8, 0x00u8, 0x00u8, 0x00u8, 0x00u8, 0x00u8, 0x00u8, 0x00u8,
        0x00u8, 0x00u8, 0x00u8, 0x00u8, 0xFFu8, 0xFFu8, 0xFFu8, 0xFFu8,
        0xFFu8, 0xFFu8, 0xFFu8, 0xFFu8, 0xFFu8, 0xFFu8, 0xFFu8, 0xFDu8,
    ]
    let mlen = i31_word_count(*(p + 0u64))
    // Copy a to dst
    var i = 0
    while i <= mlen:
        *(dst + i as u64) = *(a + i as u64)
        i = i + 1
    var t1: [u32; 12] = [0u32; 12]
    var t2: [u32; 12] = [0u32; 12]
    i31_modpow(dst, &pm2[0] as *const u8, 32, p, p0i, &raw mut t1[0] as *mut u32, &raw mut t2[0] as *mut u32)

// Copy field element
unsafe fn fe_copy(dst: *mut u32, src: *const u32):
    var i = 0
    while i < FE_WORDS:
        *(dst + i as u64) = *(src + i as u64)
        i = i + 1

// Set field element to zero (with p's bitlen)
unsafe fn fe_zero(dst: *mut u32, p: *const u32):
    *(dst + 0u64) = *(p + 0u64)
    var i = 1
    while i < FE_WORDS:
        *(dst + i as u64) = 0u32
        i = i + 1

// Set field element to 1 (in i31 format, NOT Montgomery form)
unsafe fn fe_one(dst: *mut u32, p: *const u32):
    fe_zero(dst, p)
    *(dst + 1u64) = 1u32

// Convert to Montgomery form
unsafe fn fe_to_monty(x: *mut u32, p: *const u32):
    i31_to_monty(x, p)

// Convert from Montgomery form
unsafe fn fe_from_monty(x: *mut u32, p: *const u32, p0i: u32):
    i31_from_monty(x, p, p0i)

// ── Jacobian point operations ──────────────────────────────────────
// Point (X, Y, Z) in Jacobian coordinates.
// Affine (x, y) = (X/Z², Y/Z³).
// Point at infinity: Z = 0.
//
// Each coordinate is FE_WORDS u32s in Montgomery form.
// A point is 3 * FE_WORDS = 36 u32s.

let POINT_WORDS: i32 = 36

unsafe fn point_x(pt: *mut u32) -> *mut u32:
    pt

unsafe fn point_y(pt: *mut u32) -> *mut u32:
    pt + FE_WORDS as u64

unsafe fn point_z(pt: *mut u32) -> *mut u32:
    pt + (2 * FE_WORDS) as u64

unsafe fn point_x_const(pt: *const u32) -> *const u32:
    pt + 0u64

unsafe fn point_y_const(pt: *const u32) -> *const u32:
    pt + FE_WORDS as u64

unsafe fn point_z_const(pt: *const u32) -> *const u32:
    pt + (2 * FE_WORDS) as u64

// Copy point
unsafe fn point_copy(dst: *mut u32, src: *const u32):
    var i = 0
    while i < POINT_WORDS:
        *(dst + i as u64) = *(src + i as u64)
        i = i + 1

// Set point to identity (Z = 0)
unsafe fn point_zero(pt: *mut u32, p: *const u32):
    fe_zero(point_x(pt), p)
    fe_zero(point_y(pt), p)
    fe_zero(point_z(pt), p)

// Check if point is identity (Z == 0)
unsafe fn point_is_zero(pt: *const u32) -> u32:
    i31_is_zero(point_z_const(pt))

// Point doubling: R = 2*P (Jacobian coordinates)
// Algorithm from "Guide to ECC" Algorithm 3.21
unsafe fn point_double(r: *mut u32, pt: *const u32, p: *const u32, p0i: u32):
    var a: [u32; 12] = [0u32; 12]
    var b: [u32; 12] = [0u32; 12]
    var c: [u32; 12] = [0u32; 12]
    var d: [u32; 12] = [0u32; 12]
    var t: [u32; 12] = [0u32; 12]
    let ap = &raw mut a[0] as *mut u32
    let bp = &raw mut b[0] as *mut u32
    let cp = &raw mut c[0] as *mut u32
    let dp = &raw mut d[0] as *mut u32
    let tp = &raw mut t[0] as *mut u32

    let px = point_x_const(pt)
    let py = point_y_const(pt)
    let pz = point_z_const(pt)
    let rx = point_x(r)
    let ry = point_y(r)
    let rz = point_z(r)

    fe_sqr(tp, pz, p, p0i)
    fe_sub(ap, px, tp as *const u32, p)
    fe_add(bp, px, tp as *const u32, p)
    fe_mul(cp, ap as *const u32, bp as *const u32, p, p0i)
    fe_add(ap, cp as *const u32, cp as *const u32, p)
    fe_add(ap, ap as *const u32, cp as *const u32, p)

    fe_sqr(bp, py, p, p0i)

    fe_mul(dp, px, bp as *const u32, p, p0i)
    fe_add(dp, dp as *const u32, dp as *const u32, p)
    fe_add(dp, dp as *const u32, dp as *const u32, p)

    fe_sqr(rx, ap as *const u32, p, p0i)
    fe_sub(rx, rx as *const u32, dp as *const u32, p)
    fe_sub(rx, rx as *const u32, dp as *const u32, p)

    fe_mul(rz, py, pz, p, p0i)
    fe_add(rz, rz as *const u32, rz as *const u32, p)

    fe_sub(tp, dp as *const u32, rx as *const u32, p)
    fe_mul(ry, ap as *const u32, tp as *const u32, p, p0i)
    fe_sqr(tp, bp as *const u32, p, p0i)
    fe_add(tp, tp as *const u32, tp as *const u32, p)
    fe_add(tp, tp as *const u32, tp as *const u32, p)
    fe_add(tp, tp as *const u32, tp as *const u32, p)
    fe_sub(ry, ry as *const u32, tp as *const u32, p)

// Point addition: R = P + Q (Jacobian, both inputs Jacobian)
// Uses Algorithm 3.22 from "Guide to ECC" (modified for a=-3)
unsafe fn point_add(r: *mut u32, pt1: *const u32, pt2: *const u32, p: *const u32, p0i: u32):
    if point_is_zero(pt1) != 0u32:
        point_copy(r, pt2)
        return
    if point_is_zero(pt2) != 0u32:
        point_copy(r, pt1)
        return

    var u1: [u32; 12] = [0u32; 12]
    var u2: [u32; 12] = [0u32; 12]
    var s1: [u32; 12] = [0u32; 12]
    var s2: [u32; 12] = [0u32; 12]
    var h: [u32; 12] = [0u32; 12]
    var rr: [u32; 12] = [0u32; 12]
    var t: [u32; 12] = [0u32; 12]
    var t2v: [u32; 12] = [0u32; 12]
    let u1p = &raw mut u1[0] as *mut u32
    let u2p = &raw mut u2[0] as *mut u32
    let s1p = &raw mut s1[0] as *mut u32
    let s2p = &raw mut s2[0] as *mut u32
    let hp = &raw mut h[0] as *mut u32
    let rrp = &raw mut rr[0] as *mut u32
    let tp = &raw mut t[0] as *mut u32
    let t2p = &raw mut t2v[0] as *mut u32

    let p1x = point_x_const(pt1)
    let p1y = point_y_const(pt1)
    let p1z = point_z_const(pt1)
    let p2x = point_x_const(pt2)
    let p2y = point_y_const(pt2)
    let p2z = point_z_const(pt2)

    // U1 = X1*Z2², U2 = X2*Z1²
    fe_sqr(tp, p2z, p, p0i)
    fe_mul(u1p, p1x, tp as *const u32, p, p0i)
    fe_sqr(t2p, p1z, p, p0i)
    fe_mul(u2p, p2x, t2p as *const u32, p, p0i)

    // S1 = Y1*Z2³, S2 = Y2*Z1³ (separate buffers to avoid montmul aliasing)
    var z2_cubed: [u32; 12] = [0u32; 12]
    var z1_cubed: [u32; 12] = [0u32; 12]
    fe_mul(&raw mut z2_cubed[0] as *mut u32, tp as *const u32, p2z, p, p0i)
    fe_mul(s1p, p1y, &z2_cubed[0] as *const u32, p, p0i)
    fe_mul(&raw mut z1_cubed[0] as *mut u32, t2p as *const u32, p1z, p, p0i)
    fe_mul(s2p, p2y, &z1_cubed[0] as *const u32, p, p0i)

    fe_sub(hp, u2p as *const u32, u1p as *const u32, p)
    fe_sub(rrp, s2p as *const u32, s1p as *const u32, p)

    if i31_is_zero(hp as *const u32) != 0u32:
        if i31_is_zero(rrp as *const u32) != 0u32:
            point_double(r, pt1, p, p0i)
            return
        else:
            point_zero(r, p)
            return

    let rx = point_x(r)
    let ry = point_y(r)
    let rz = point_z(r)

    fe_sqr(tp, hp as *const u32, p, p0i)
    fe_mul(t2p, tp as *const u32, hp as *const u32, p, p0i)

    // u1h2 = U1*H² (separate buffer to avoid aliasing u1p as both dst and src)
    var u1h2: [u32; 12] = [0u32; 12]
    fe_mul(&raw mut u1h2[0] as *mut u32, u1p as *const u32, tp as *const u32, p, p0i)
    fe_sqr(rx, rrp as *const u32, p, p0i)
    fe_sub(rx, rx as *const u32, t2p as *const u32, p)
    fe_sub(rx, rx as *const u32, &u1h2[0] as *const u32, p)
    fe_sub(rx, rx as *const u32, &u1h2[0] as *const u32, p)

    fe_sub(tp, &u1h2[0] as *const u32, rx as *const u32, p)
    fe_mul(ry, rrp as *const u32, tp as *const u32, p, p0i)
    fe_mul(tp, s1p as *const u32, t2p as *const u32, p, p0i)
    fe_sub(ry, ry as *const u32, tp as *const u32, p)

    // z1z2 = Z1*Z2 (separate buffer to avoid aliasing rz as both dst and src in next mul)
    var z1z2: [u32; 12] = [0u32; 12]
    fe_mul(&raw mut z1z2[0] as *mut u32, p1z, p2z, p, p0i)
    fe_mul(rz, &z1z2[0] as *const u32, hp as *const u32, p, p0i)

// Scalar multiplication: R = k * P
// k is a 32-byte big-endian scalar.
unsafe fn point_mul(r: *mut u32, k: *const u8, pt: *const u32, p: *const u32, p0i: u32):
    point_zero(r, p)

    var tmp: [u32; 36] = [0u32; 36]
    let tmpp = &raw mut tmp[0] as *mut u32

    // Double-and-add, MSB first
    var bi = 0
    while bi < 32:
        let raw = *(k + bi as u64)
        let byte = raw as u32
        var bj = 0
        while bj < 8:
            let bit = (byte >> (7 - bj) as u32) & 1u32

            // R = 2*R
            point_double(tmpp, r as *const u32, p, p0i)
            point_copy(r, tmpp as *const u32)

            // If bit == 1: R = R + P
            if bit != 0u32:
                point_add(tmpp, r as *const u32, pt, p, p0i)
                point_copy(r, tmpp as *const u32)

            bj = bj + 1
        bi = bi + 1

// Convert Jacobian point to affine coordinates (X/Z², Y/Z³) and encode.
// Output: 32 bytes for x, 32 bytes for y.
unsafe fn point_to_affine(x_out: *mut u8, y_out: *mut u8, pt: *const u32, p: *const u32, p0i: u32):
    var z_copy: [u32; 12] = [0u32; 12]
    var z_inv: [u32; 12] = [0u32; 12]
    var z_inv2: [u32; 12] = [0u32; 12]
    var z_inv3: [u32; 12] = [0u32; 12]
    var ax: [u32; 12] = [0u32; 12]
    var ay: [u32; 12] = [0u32; 12]

    let zcp = &raw mut z_copy[0] as *mut u32
    let zip = &raw mut z_inv[0] as *mut u32
    let zi2p = &raw mut z_inv2[0] as *mut u32
    let zi3p = &raw mut z_inv3[0] as *mut u32
    let axp = &raw mut ax[0] as *mut u32
    let ayp = &raw mut ay[0] as *mut u32

    let pz = point_z_const(pt)
    let px = point_x_const(pt)
    let py = point_y_const(pt)

    // Z is in Montgomery form. Convert to normal for fe_inv (which uses modpow).
    fe_copy(zcp, pz)
    fe_from_monty(zcp, p, p0i)

    // z_inv = Z^(-1) (normal form)
    fe_inv(zip, zcp as *const u32, p, p0i)

    // Convert z_inv to Montgomery for subsequent multiplications
    fe_to_monty(zip, p)

    // z_inv2 = Z^(-2), z_inv3 = Z^(-3) (all Montgomery)
    fe_sqr(zi2p, zip as *const u32, p, p0i)
    fe_mul(zi3p, zi2p as *const u32, zip as *const u32, p, p0i)

    // ax = X * Z^(-2), ay = Y * Z^(-3) (Montgomery)
    fe_mul(axp, px, zi2p as *const u32, p, p0i)
    fe_mul(ayp, py, zi3p as *const u32, p, p0i)

    // Convert from Montgomery form to normal
    fe_from_monty(axp, p, p0i)
    fe_from_monty(ayp, p, p0i)

    // Encode to big-endian bytes
    i31_encode(x_out, 32, axp as *const u32)
    i31_encode(y_out, 32, ayp as *const u32)

// ── Public API ─────────────────────────────────────────────────────

// Compute public key from private key: Q = k * G
// private_key: 32 bytes (big-endian scalar)
// public_key: 65 bytes output (0x04 || X || Y, uncompressed)
unsafe fn p256_compute_public(private_key: *const u8, public_key: *mut u8):
    var p: [u32; 12] = [0u32; 12]
    p256_load_p(&raw mut p[0] as *mut u32)
    let pp = &p[0] as *const u32
    let p0i = i31_ninv31(p[1])

    // Load generator G in Montgomery form
    var gx: [u32; 12] = [0u32; 12]
    var gy: [u32; 12] = [0u32; 12]
    var gz: [u32; 12] = [0u32; 12]
    p256_load_gx(&raw mut gx[0] as *mut u32, pp)
    p256_load_gy(&raw mut gy[0] as *mut u32, pp)
    fe_one(&raw mut gz[0] as *mut u32, pp)
    fe_to_monty(&raw mut gx[0] as *mut u32, pp)
    fe_to_monty(&raw mut gy[0] as *mut u32, pp)
    fe_to_monty(&raw mut gz[0] as *mut u32, pp)

    // Pack into point
    var g_pt: [u32; 36] = [0u32; 36]
    let gp = &raw mut g_pt[0] as *mut u32
    fe_copy(point_x(gp), &gx[0] as *const u32)
    fe_copy(point_y(gp), &gy[0] as *const u32)
    fe_copy(point_z(gp), &gz[0] as *const u32)

    // R = k * G
    var r_pt: [u32; 36] = [0u32; 36]
    let rp = &raw mut r_pt[0] as *mut u32
    point_mul(rp, private_key, gp as *const u32, pp, p0i)

    // Convert to affine and output
    *(public_key + 0u64) = 0x04u8
    point_to_affine(public_key + 1u64, public_key + 33u64, rp as *const u32, pp, p0i)

// ECDH: compute shared secret from private key and peer's public key.
// private_key: 32 bytes
// peer_public: 65 bytes (0x04 || X || Y)
// secret: 32 bytes output (x-coordinate of k * peer_public)
unsafe fn p256_ecdh(private_key: *const u8, peer_public: *const u8, secret: *mut u8):
    var p: [u32; 12] = [0u32; 12]
    p256_load_p(&raw mut p[0] as *mut u32)
    let pp = &p[0] as *const u32
    let p0i = i31_ninv31(p[1])

    // Decode peer public key
    var qx: [u32; 12] = [0u32; 12]
    var qy: [u32; 12] = [0u32; 12]
    var qz: [u32; 12] = [0u32; 12]
    i31_decode_reduce(&raw mut qx[0] as *mut u32, peer_public + 1u64, 32, pp)
    i31_decode_reduce(&raw mut qy[0] as *mut u32, peer_public + 33u64, 32, pp)
    fe_one(&raw mut qz[0] as *mut u32, pp)
    fe_to_monty(&raw mut qx[0] as *mut u32, pp)
    fe_to_monty(&raw mut qy[0] as *mut u32, pp)
    fe_to_monty(&raw mut qz[0] as *mut u32, pp)

    var q_pt: [u32; 36] = [0u32; 36]
    let qp = &raw mut q_pt[0] as *mut u32
    fe_copy(point_x(qp), &qx[0] as *const u32)
    fe_copy(point_y(qp), &qy[0] as *const u32)
    fe_copy(point_z(qp), &qz[0] as *const u32)

    // R = k * Q
    var r_pt: [u32; 36] = [0u32; 36]
    let rp = &raw mut r_pt[0] as *mut u32
    point_mul(rp, private_key, qp as *const u32, pp, p0i)

    // Output x-coordinate
    var y_dummy: [u8; 32] = [0u8; 32]
    point_to_affine(secret, &raw mut y_dummy[0] as *mut u8, rp as *const u32, pp, p0i)
