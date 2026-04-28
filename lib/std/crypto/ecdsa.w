// ECDSA signature verification over P-256 with SHA-256
// RFC 6979 / FIPS 186-4

use std.crypto.bigint
use std.crypto.ec

// Verify an ECDSA-P256-SHA256 signature.
//
// pub_x, pub_y: public key coordinates (32 bytes each, big-endian)
// hash: SHA-256 digest of message (32 bytes)
// sig_r, sig_s: signature components (32 bytes each, big-endian)
//
// Returns 1 if valid, 0 if invalid.
unsafe fn ecdsa_p256_verify(
    pub_x: *const u8, pub_y: *const u8,
    hash: *const u8,
    sig_r: *const u8, sig_s: *const u8,
) -> i32:
    // Load curve order n and field prime p
    var n: [u32; 12] = [0u32; 12]
    var p: [u32; 12] = [0u32; 12]
    p256_load_n(&raw mut n[0] as *mut u32)
    p256_load_p(&raw mut p[0] as *mut u32)
    let np = &n[0] as *const u32
    let pp = &p[0] as *const u32
    let n0i = i31_ninv31(n[1])
    let p0i = i31_ninv31(p[1])

    // Decode r and s, check 0 < r < n and 0 < s < n
    var r: [u32; 12] = [0u32; 12]
    var s: [u32; 12] = [0u32; 12]
    i31_decode_reduce(&raw mut r[0] as *mut u32, sig_r, 32, np)
    i31_decode_reduce(&raw mut s[0] as *mut u32, sig_s, 32, np)
    if i31_is_zero(&r[0] as *const u32) != 0u32:
        return 0
    if i31_is_zero(&s[0] as *const u32) != 0u32:
        return 0

    // w = s^(-1) mod n (via modpow: s^(n-2) mod n)
    var w: [u32; 12] = [0u32; 12]
    var nm2: [u8; 32] = [
        0xFFu8, 0xFFu8, 0xFFu8, 0xFFu8, 0x00u8, 0x00u8, 0x00u8, 0x00u8,
        0xFFu8, 0xFFu8, 0xFFu8, 0xFFu8, 0xFFu8, 0xFFu8, 0xFFu8, 0xFFu8,
        0xBCu8, 0xE6u8, 0xFAu8, 0xADu8, 0xA7u8, 0x17u8, 0x9Eu8, 0x84u8,
        0xF3u8, 0xB9u8, 0xCAu8, 0xC2u8, 0xFCu8, 0x63u8, 0x25u8, 0x4Fu8,
    ]
    fe_copy(&raw mut w[0] as *mut u32, &s[0] as *const u32)
    var wt1: [u32; 12] = [0u32; 12]
    var wt2: [u32; 12] = [0u32; 12]
    i31_modpow(&raw mut w[0] as *mut u32, &nm2[0] as *const u8, 32, np, n0i, &raw mut wt1[0] as *mut u32, &raw mut wt2[0] as *mut u32)

    // u1 = hash * w mod n
    var z: [u32; 12] = [0u32; 12]
    i31_decode_reduce(&raw mut z[0] as *mut u32, hash, 32, np)
    // u1 = montmul(z_monty, w_monty) needs Montgomery. Use modular multiply via montmul.
    var u1: [u32; 12] = [0u32; 12]
    var z_m: [u32; 12] = [0u32; 12]
    var w_m: [u32; 12] = [0u32; 12]
    fe_copy(&raw mut z_m[0] as *mut u32, &z[0] as *const u32)
    fe_copy(&raw mut w_m[0] as *mut u32, &w[0] as *const u32)
    i31_to_monty(&raw mut z_m[0] as *mut u32, np)
    i31_to_monty(&raw mut w_m[0] as *mut u32, np)
    i31_montmul(&raw mut u1[0] as *mut u32, &z_m[0] as *const u32, &w_m[0] as *const u32, np, n0i)
    i31_from_monty(&raw mut u1[0] as *mut u32, np, n0i)

    // u2 = r * w mod n
    var u2: [u32; 12] = [0u32; 12]
    var r_m: [u32; 12] = [0u32; 12]
    fe_copy(&raw mut r_m[0] as *mut u32, &r[0] as *const u32)
    i31_to_monty(&raw mut r_m[0] as *mut u32, np)
    i31_montmul(&raw mut u2[0] as *mut u32, &r_m[0] as *const u32, &w_m[0] as *const u32, np, n0i)
    i31_from_monty(&raw mut u2[0] as *mut u32, np, n0i)

    // Encode u1, u2 back to bytes for point_mul
    var u1_bytes: [u8; 32] = [0u8; 32]
    var u2_bytes: [u8; 32] = [0u8; 32]
    i31_encode(&raw mut u1_bytes[0] as *mut u8, 32, &u1[0] as *const u32)
    i31_encode(&raw mut u2_bytes[0] as *mut u8, 32, &u2[0] as *const u32)

    // Load generator G in Jacobian Montgomery form
    var gx: [u32; 12] = [0u32; 12]
    var gy: [u32; 12] = [0u32; 12]
    var gz: [u32; 12] = [0u32; 12]
    p256_load_gx(&raw mut gx[0] as *mut u32, pp)
    p256_load_gy(&raw mut gy[0] as *mut u32, pp)
    fe_one(&raw mut gz[0] as *mut u32, pp)
    fe_to_monty(&raw mut gx[0] as *mut u32, pp)
    fe_to_monty(&raw mut gy[0] as *mut u32, pp)
    fe_to_monty(&raw mut gz[0] as *mut u32, pp)
    var g_pt: [u32; 36] = [0u32; 36]
    fe_copy(&raw mut g_pt[0] as *mut u32, &gx[0] as *const u32)
    fe_copy(&raw mut g_pt[12] as *mut u32, &gy[0] as *const u32)
    fe_copy(&raw mut g_pt[24] as *mut u32, &gz[0] as *const u32)

    // Load public key Q in Jacobian Montgomery form
    var qx: [u32; 12] = [0u32; 12]
    var qy: [u32; 12] = [0u32; 12]
    var qz: [u32; 12] = [0u32; 12]
    i31_decode_reduce(&raw mut qx[0] as *mut u32, pub_x, 32, pp)
    i31_decode_reduce(&raw mut qy[0] as *mut u32, pub_y, 32, pp)
    fe_one(&raw mut qz[0] as *mut u32, pp)
    fe_to_monty(&raw mut qx[0] as *mut u32, pp)
    fe_to_monty(&raw mut qy[0] as *mut u32, pp)
    fe_to_monty(&raw mut qz[0] as *mut u32, pp)
    var q_pt: [u32; 36] = [0u32; 36]
    fe_copy(&raw mut q_pt[0] as *mut u32, &qx[0] as *const u32)
    fe_copy(&raw mut q_pt[12] as *mut u32, &qy[0] as *const u32)
    fe_copy(&raw mut q_pt[24] as *mut u32, &qz[0] as *const u32)

    // Compute R = u1*G + u2*Q
    var r1_pt: [u32; 36] = [0u32; 36]
    var r2_pt: [u32; 36] = [0u32; 36]
    var result_pt: [u32; 36] = [0u32; 36]
    point_mul(&raw mut r1_pt[0] as *mut u32, &u1_bytes[0] as *const u8, &g_pt[0] as *const u32, pp, p0i)
    point_mul(&raw mut r2_pt[0] as *mut u32, &u2_bytes[0] as *const u8, &q_pt[0] as *const u32, pp, p0i)
    point_add(&raw mut result_pt[0] as *mut u32, &r1_pt[0] as *const u32, &r2_pt[0] as *const u32, pp, p0i)

    // If R is identity, verification fails
    if point_is_zero(&result_pt[0] as *const u32) != 0u32:
        return 0

    // Convert R to affine, get x-coordinate
    var rx_bytes: [u8; 32] = [0u8; 32]
    var ry_bytes: [u8; 32] = [0u8; 32]
    point_to_affine(&raw mut rx_bytes[0] as *mut u8, &raw mut ry_bytes[0] as *mut u8, &result_pt[0] as *const u32, pp, p0i)

    // v = R.x mod n
    var v: [u32; 12] = [0u32; 12]
    i31_decode_reduce(&raw mut v[0] as *mut u32, &rx_bytes[0] as *const u8, 32, np)

    // Check v == r
    // Compare by encoding both and comparing bytes
    var v_bytes: [u8; 32] = [0u8; 32]
    var r_bytes: [u8; 32] = [0u8; 32]
    i31_encode(&raw mut v_bytes[0] as *mut u8, 32, &v[0] as *const u32)
    i31_encode(&raw mut r_bytes[0] as *mut u8, 32, &r[0] as *const u32)

    var match_val = 1
    var ci = 0
    while ci < 32:
        if v_bytes[ci] != r_bytes[ci]:
            match_val = 0
        ci = ci + 1

    match_val
