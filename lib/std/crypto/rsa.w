// RSA PKCS#1 v1.5 signature verification
// Ported from BearSSL src/rsa/rsa_i31_pkcs1_vrfy.c
//
// Only supports SHA-256 digest verification (sufficient for TLS 1.2).

use std.crypto.bigint

// DigestInfo prefix for SHA-256 (DER-encoded AlgorithmIdentifier + OCTET STRING header)
// 30 31 30 0d 06 09 60 86 48 01 65 03 04 02 01 05 00 04 20
let DIGESTINFO_SHA256_LEN: i32 = 19

unsafe fn write_digestinfo_sha256(dst: *mut u8):
    *(dst + 0u64) = 0x30u8
    *(dst + 1u64) = 0x31u8
    *(dst + 2u64) = 0x30u8
    *(dst + 3u64) = 0x0Du8
    *(dst + 4u64) = 0x06u8
    *(dst + 5u64) = 0x09u8
    *(dst + 6u64) = 0x60u8
    *(dst + 7u64) = 0x86u8
    *(dst + 8u64) = 0x48u8
    *(dst + 9u64) = 0x01u8
    *(dst + 10u64) = 0x65u8
    *(dst + 11u64) = 0x03u8
    *(dst + 12u64) = 0x04u8
    *(dst + 13u64) = 0x02u8
    *(dst + 14u64) = 0x01u8
    *(dst + 15u64) = 0x05u8
    *(dst + 16u64) = 0x00u8
    *(dst + 17u64) = 0x04u8
    *(dst + 18u64) = 0x20u8

// Check PKCS#1 v1.5 padding structure of a decrypted EM block.
// em: the decrypted block (em_len bytes, big-endian)
// hash: expected SHA-256 digest (32 bytes)
// Returns 1 if valid, 0 if invalid.
unsafe fn rsa_check_pkcs1_sha256(em: *const u8, em_len: i32, hash: *const u8) -> i32:
    // Save pointer params to locals (workaround for codegen pointer-in-loop bug)
    let em_p = em
    let hash_p = hash

    // Structure: 0x00 0x01 [0xFF padding >= 8 bytes] 0x00 [DigestInfo] [hash]
    if em_len < 11 + DIGESTINFO_SHA256_LEN + 32:
        return 0
    let b0 = *(em_p + 0u64)
    if b0 != 0x00u8:
        return 0
    let b1 = *(em_p + 1u64)
    if b1 != 0x01u8:
        return 0

    let t_len = DIGESTINFO_SHA256_LEN + 32
    let ps_len = em_len - 3 - t_len
    if ps_len < 8:
        return 0

    // Check PS bytes are all 0xFF
    var i = 2
    while i < 2 + ps_len:
        let b = *(em_p + i as u64)
        if b != 0xFFu8:
            return 0
        i = i + 1

    // Check separator byte
    let sep = *(em_p + (2 + ps_len) as u64)
    if sep != 0x00u8:
        return 0

    // Check DigestInfo prefix
    var di_prefix: [u8; 19] = [0u8; 19]
    write_digestinfo_sha256(&mut di_prefix[0] as *mut u8)
    let t_start = 3 + ps_len
    i = 0
    while i < DIGESTINFO_SHA256_LEN:
        let em_b = *(em_p + (t_start + i) as u64)
        if em_b != di_prefix[i]:
            return 0
        i = i + 1

    // Check hash matches
    let hash_start = t_start + DIGESTINFO_SHA256_LEN
    i = 0
    while i < 32:
        let em_b = *(em_p + (hash_start + i) as u64)
        let h_b = *(hash_p + i as u64)
        if em_b != h_b:
            return 0
        i = i + 1

    1

// Verify an RSA PKCS#1 v1.5 signature with SHA-256.
//
// n, e: public key (big-endian bytes)
// sig: signature (big-endian bytes, must be same length as n)
// hash: expected SHA-256 digest (32 bytes)
//
// Returns 1 on success, 0 on failure.
unsafe fn rsa_pkcs1_sha256_verify(
    n: *const u8, n_len: i32,
    e: *const u8, e_len: i32,
    sig: *const u8, sig_len: i32,
    hash: *const u8,
) -> i32:
    if sig_len != n_len:
        return 0
    if n_len < 64 or n_len > 512:
        return 0

    // Max limb count for 4096-bit key: (4096+30)/31 = 133 words + 1 header = 134
    var m: [u32; 140] = [0u32; 140]
    var x: [u32; 140] = [0u32; 140]
    var t1: [u32; 140] = [0u32; 140]
    var t2: [u32; 140] = [0u32; 140]

    let mp = &mut m[0] as *mut u32
    let xp = &mut x[0] as *mut u32
    let t1p = &mut t1[0] as *mut u32
    let t2p = &mut t2[0] as *mut u32

    // Decode modulus
    i31_decode(mp, n, n_len)
    let m0i = i31_ninv31(m[1])

    // Decode signature, reduce mod n
    i31_decode_reduce(xp, sig, sig_len, mp as *const u32)

    // Compute sig^e mod n
    i31_modpow(xp, e, e_len, mp as *const u32, m0i, t1p, t2p)

    // Encode result back to big-endian bytes
    var em: [u8; 512] = [0u8; 512]
    let emp = &mut em[0] as *mut u8
    i31_encode(emp, n_len, xp as *const u32)

    // Check PKCS#1 v1.5 padding
    rsa_check_pkcs1_sha256(emp as *const u8, n_len, hash)
