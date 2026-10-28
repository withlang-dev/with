// ECDSA signature verification over P-256 and P-384
// RFC 6979 / FIPS 186-4. One core, parameterized by field byte width;
// the per-curve wrappers load that curve's constants.

use std.crypto.bigint
use std.crypto.ec

// Verify an ECDSA signature on the curve whose constants are loaded.
// `width` is the field byte width (32 or 48); the message integer z is
// the leftmost min(hash_len, width) bytes of `hash` (FIPS 186-4: a
// longer digest truncates, a shorter one is used whole — TLS signs
// P-384 keys with SHA-256); `gx`/`gy` are the generator's field
// elements in normal (non-Montgomery) form.
// Returns 1 if valid, 0 if invalid.
unsafe fn ecdsa_verify_impl(
    pub_x: *const u8, pub_y: *const u8,
    hash: *const u8, hash_len: i32,
    sig_r: *const u8, sig_s: *const u8,
    width: i32, p: *const u32, n: *const u32,
    pm2: *const u8, nm2: *const u8,
    gx: *const u32, gy: *const u32,
) -> i32:
    if hash_len <= 0:
        return 0
    let z_len = if hash_len < width: hash_len else: width
    let n0i = i31_ninv31(*(n + 1u64))
    let p0i = i31_ninv31(*(p + 1u64))

    // Decode r and s, check 0 < r < n and 0 < s < n
    var r: [u32; 16] = [0u32; 16]
    var s: [u32; 16] = [0u32; 16]
    i31_decode_reduce(&raw mut r[0] as *mut u32, sig_r, width, n)
    i31_decode_reduce(&raw mut s[0] as *mut u32, sig_s, width, n)
    if i31_is_zero(&r[0] as *const u32) != 0u32:
        return 0
    if i31_is_zero(&s[0] as *const u32) != 0u32:
        return 0

    // w = s^(-1) mod n (via modpow: s^(n-2) mod n)
    var w: [u32; 16] = [0u32; 16]
    fe_copy(&raw mut w[0] as *mut u32, &s[0] as *const u32)
    var wt1: [u32; 16] = [0u32; 16]
    var wt2: [u32; 16] = [0u32; 16]
    i31_modpow(&raw mut w[0] as *mut u32, nm2, width, n, n0i, &raw mut wt1[0] as *mut u32, &raw mut wt2[0] as *mut u32)

    // u1 = hash * w mod n
    var z: [u32; 16] = [0u32; 16]
    i31_decode_reduce(&raw mut z[0] as *mut u32, hash, z_len, n)
    var u1: [u32; 16] = [0u32; 16]
    var z_m: [u32; 16] = [0u32; 16]
    var w_m: [u32; 16] = [0u32; 16]
    fe_copy(&raw mut z_m[0] as *mut u32, &z[0] as *const u32)
    fe_copy(&raw mut w_m[0] as *mut u32, &w[0] as *const u32)
    i31_to_monty(&raw mut z_m[0] as *mut u32, n)
    i31_to_monty(&raw mut w_m[0] as *mut u32, n)
    i31_montmul(&raw mut u1[0] as *mut u32, &z_m[0] as *const u32, &w_m[0] as *const u32, n, n0i)
    i31_from_monty(&raw mut u1[0] as *mut u32, n, n0i)

    // u2 = r * w mod n
    var u2: [u32; 16] = [0u32; 16]
    var r_m: [u32; 16] = [0u32; 16]
    fe_copy(&raw mut r_m[0] as *mut u32, &r[0] as *const u32)
    i31_to_monty(&raw mut r_m[0] as *mut u32, n)
    i31_montmul(&raw mut u2[0] as *mut u32, &r_m[0] as *const u32, &w_m[0] as *const u32, n, n0i)
    i31_from_monty(&raw mut u2[0] as *mut u32, n, n0i)

    // Encode u1, u2 back to bytes for point_mul
    var u1_bytes: [u8; 48] = [0u8; 48]
    var u2_bytes: [u8; 48] = [0u8; 48]
    i31_encode(&raw mut u1_bytes[0] as *mut u8, width, &u1[0] as *const u32)
    i31_encode(&raw mut u2_bytes[0] as *mut u8, width, &u2[0] as *const u32)

    // Load generator G in Jacobian Montgomery form
    var g_pt: [u32; 48] = [0u32; 48]
    fe_copy(&raw mut g_pt[0] as *mut u32, gx)
    fe_copy(&raw mut g_pt[16] as *mut u32, gy)
    fe_one(&raw mut g_pt[32] as *mut u32, p)
    fe_to_monty(&raw mut g_pt[0] as *mut u32, p)
    fe_to_monty(&raw mut g_pt[16] as *mut u32, p)
    fe_to_monty(&raw mut g_pt[32] as *mut u32, p)

    // Load public key Q in Jacobian Montgomery form
    var q_pt: [u32; 48] = [0u32; 48]
    i31_decode_reduce(&raw mut q_pt[0] as *mut u32, pub_x, width, p)
    i31_decode_reduce(&raw mut q_pt[16] as *mut u32, pub_y, width, p)
    fe_one(&raw mut q_pt[32] as *mut u32, p)
    fe_to_monty(&raw mut q_pt[0] as *mut u32, p)
    fe_to_monty(&raw mut q_pt[16] as *mut u32, p)
    fe_to_monty(&raw mut q_pt[32] as *mut u32, p)

    // Compute R = u1*G + u2*Q
    var r1_pt: [u32; 48] = [0u32; 48]
    var r2_pt: [u32; 48] = [0u32; 48]
    var result_pt: [u32; 48] = [0u32; 48]
    point_mul(&raw mut r1_pt[0] as *mut u32, &u1_bytes[0] as *const u8, width, &g_pt[0] as *const u32, p, p0i)
    point_mul(&raw mut r2_pt[0] as *mut u32, &u2_bytes[0] as *const u8, width, &q_pt[0] as *const u32, p, p0i)
    point_add(&raw mut result_pt[0] as *mut u32, &r1_pt[0] as *const u32, &r2_pt[0] as *const u32, p, p0i)

    // If R is identity, verification fails
    if point_is_zero(&result_pt[0] as *const u32) != 0u32:
        return 0

    // Convert R to affine, get x-coordinate
    var rx_bytes: [u8; 48] = [0u8; 48]
    var ry_bytes: [u8; 48] = [0u8; 48]
    point_to_affine(&raw mut rx_bytes[0] as *mut u8, &raw mut ry_bytes[0] as *mut u8, &result_pt[0] as *const u32, p, p0i, width, pm2, width)

    // v = R.x mod n
    var v: [u32; 16] = [0u32; 16]
    i31_decode_reduce(&raw mut v[0] as *mut u32, &rx_bytes[0] as *const u8, width, n)

    // Check v == r
    var v_bytes: [u8; 48] = [0u8; 48]
    var r_bytes: [u8; 48] = [0u8; 48]
    i31_encode(&raw mut v_bytes[0] as *mut u8, width, &v[0] as *const u32)
    i31_encode(&raw mut r_bytes[0] as *mut u8, width, &r[0] as *const u32)

    var match_val: i32 = 1
    var ci = 0
    while ci < width:
        if v_bytes[ci] != r_bytes[ci]:
            match_val = 0
        ci = ci + 1

    match_val

// Verify an ECDSA-P256 signature over a SHA-256 digest.
// pub_x, pub_y, sig_r, sig_s: 32 bytes each, big-endian. 1 = valid.
unsafe fn ecdsa_p256_verify(
    pub_x: *const u8, pub_y: *const u8,
    hash: *const u8,
    sig_r: *const u8, sig_s: *const u8,
) -> i32:
    var n: [u32; 16] = [0u32; 16]
    var p: [u32; 16] = [0u32; 16]
    var gx: [u32; 16] = [0u32; 16]
    var gy: [u32; 16] = [0u32; 16]
    p256_load_n(&raw mut n[0] as *mut u32)
    p256_load_p(&raw mut p[0] as *mut u32)
    p256_load_gx(&raw mut gx[0] as *mut u32, &p[0] as *const u32)
    p256_load_gy(&raw mut gy[0] as *mut u32, &p[0] as *const u32)
    // n - 2 for the inversion exponent
    var nm2: [u8; 32] = [
        0xFFu8, 0xFFu8, 0xFFu8, 0xFFu8, 0x00u8, 0x00u8, 0x00u8, 0x00u8,
        0xFFu8, 0xFFu8, 0xFFu8, 0xFFu8, 0xFFu8, 0xFFu8, 0xFFu8, 0xFFu8,
        0xBCu8, 0xE6u8, 0xFAu8, 0xADu8, 0xA7u8, 0x17u8, 0x9Eu8, 0x84u8,
        0xF3u8, 0xB9u8, 0xCAu8, 0xC2u8, 0xFCu8, 0x63u8, 0x25u8, 0x4Fu8,
    ]
    ecdsa_verify_impl(pub_x, pub_y, hash, 32, sig_r, sig_s, 32, &p[0] as *const u32, &n[0] as *const u32, &P256_PM2[0] as *const u8, &nm2[0] as *const u8, &gx[0] as *const u32, &gy[0] as *const u32)

// Verify an ECDSA-P384 signature over a digest of at least 48 bytes.
// pub_x, pub_y, sig_r, sig_s: 48 bytes each, big-endian. 1 = valid.
unsafe fn ecdsa_p384_verify(
    pub_x: *const u8, pub_y: *const u8,
    hash: *const u8, hash_len: i32,
    sig_r: *const u8, sig_s: *const u8,
) -> i32:
    var n: [u32; 16] = [0u32; 16]
    var p: [u32; 16] = [0u32; 16]
    var gx: [u32; 16] = [0u32; 16]
    var gy: [u32; 16] = [0u32; 16]
    p384_load_n(&raw mut n[0] as *mut u32)
    p384_load_p(&raw mut p[0] as *mut u32)
    p384_load_gx(&raw mut gx[0] as *mut u32, &p[0] as *const u32)
    p384_load_gy(&raw mut gy[0] as *mut u32, &p[0] as *const u32)
    // n - 2 for the inversion exponent
    var nm2: [u8; 48] = [
        0xFFu8, 0xFFu8, 0xFFu8, 0xFFu8, 0xFFu8, 0xFFu8, 0xFFu8, 0xFFu8,
        0xFFu8, 0xFFu8, 0xFFu8, 0xFFu8, 0xFFu8, 0xFFu8, 0xFFu8, 0xFFu8,
        0xFFu8, 0xFFu8, 0xFFu8, 0xFFu8, 0xFFu8, 0xFFu8, 0xFFu8, 0xFFu8,
        0xC7u8, 0x63u8, 0x4Du8, 0x81u8, 0xF4u8, 0x37u8, 0x2Du8, 0xDFu8,
        0x58u8, 0x1Au8, 0x0Du8, 0xB2u8, 0x48u8, 0xB0u8, 0xA7u8, 0x7Au8,
        0xECu8, 0xECu8, 0x19u8, 0x6Au8, 0xCCu8, 0xC5u8, 0x29u8, 0x71u8,
    ]
    ecdsa_verify_impl(pub_x, pub_y, hash, hash_len, sig_r, sig_s, 48, &p[0] as *const u32, &n[0] as *const u32, &P384_PM2[0] as *const u8, &nm2[0] as *const u8, &gx[0] as *const u32, &gy[0] as *const u32)
