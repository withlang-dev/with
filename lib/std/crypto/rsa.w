// RSA PKCS#1 v1.5 signature verification
// Ported from BearSSL src/rsa/rsa_i31_pkcs1_vrfy.c
//
// Only supports SHA-256 digest verification (sufficient for TLS 1.2).

use std.crypto.bigint
use std.crypto.sha256

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
    write_digestinfo_sha256(&raw mut di_prefix[0] as *mut u8)
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
    var m: [u32; I31_MAX_WORDS] = [0u32; I31_MAX_WORDS]
    var x: [u32; I31_MAX_WORDS] = [0u32; I31_MAX_WORDS]
    var t1: [u32; I31_MAX_WORDS] = [0u32; I31_MAX_WORDS]
    var t2: [u32; I31_MAX_WORDS] = [0u32; I31_MAX_WORDS]

    let mp = &raw mut m[0] as *mut u32
    let xp = &raw mut x[0] as *mut u32
    let t1p = &raw mut t1[0] as *mut u32
    let t2p = &raw mut t2[0] as *mut u32

    // Decode modulus
    i31_decode(mp, n, n_len)
    let m0i = i31_ninv31(m[1])

    // Decode signature, reduce mod n
    i31_decode_reduce(xp, sig, sig_len, mp as *const u32)

    // Compute sig^e mod n
    i31_modpow(xp, e, e_len, mp as *const u32, m0i, t1p, t2p)

    // Encode result back to big-endian bytes
    var em: [u8; 512] = [0u8; 512]
    let emp = &raw mut em[0] as *mut u8
    i31_encode(emp, n_len, xp as *const u32)

    // Check PKCS#1 v1.5 padding
    rsa_check_pkcs1_sha256(emp as *const u8, n_len, hash)

// #1052: an RSA-4096 known answer, the PKCS#1 v1.5 SHA-256 signature of
// "abc" under a 4096-bit key (openssl genrsa 4096; e = 65537). The modulus
// is 133 i31 words, past the 80-word temps i31_from_monty once had.
// Returns 0 on pass, 1 if the signature is refused, 2 if a corrupted copy
// is accepted.
const RSA4096_KAT_N: str = "ca861494e679985e6eb4b7ae65aaedeea0c671911ae8ba4aea529382e83029d970159b1edf02df4acbde2c03b39afcb7b770be6f006ae8ba1c583062ded233de361ee8c4113c8dee083a15b0d3c309b7c946891a4d52983165a5f1af69dbadfd8e886d25ff9f6bef3dd7b4c8967de7b248837c2278802d50161d6353143913994a3e8870a2ef7b715daec65a7d22a585be121261aff857357df44ceb18d465f5021e884c0cf5edb4fe8ad34d49456a447b78a5ee59b2c6e2e51133e8b3e4ac6d0e9d8924de6d5c0b318e688f0ca0792958e89743cf310945f27eee51e818f1f4219d2e8f2231e9ce35134dddf6ce53b47bc11570ca2c97d5833c9f04c87ed1033983aa9728d28fc4b4e37db1873168be930aec9cfac750b29fa8399a2a0ee88966b7172b1d4b6b3b2e620e26698f494bd81a3e2db6851b96abcd4c5112c1ac81e7a92f15afce9be63ea90bf427b72f23abd1909cfbfed70cbf59d4961fd8a590f2e9dfff8ac30e251368dd89c81dfefe1067b711c95e36c56ae33a3faf9de45f031a7bf7767312d613a72d6bb8c51a6b6c1b99fa213bba9129ccd9cf3daf5ac966de4087e350f3aa9275acc5f1274788d9797fccf9097d64281455d406b4f06085d8d38217a3c29c20044a7eff8d4c2d14d45e33cfb458595903895440a683aab23c8249df57daaadf2992f0f2a9ce06d7b48e2369c0c79685e7f2b26d65e1ab"
const RSA4096_KAT_SIG: str = "25001acd2360d59db14235cf07607c3e932634ae9522572511ffe9d74ae6e010ac47c3ffc01264377626b2f23ae83af6b26a75637ddce6b56df23525562eb9ebe2f7f3e6cdcbd8543c184b1c6337ab0d8a07fea7a054aa4be89d8ee979209172755ccc0c310c09d91a178a8252189a2fd35d5ba2aacc4d75a655103c24661aabe832d8e398d551f57705ec4d560ef3d524601eebb64d75c9074651f325218e51a9e717bbd7d3299f27fdb3e7cb6420710ce2aa4a3ec153b816cc6dbe03a42357af82abc371616d5a09c2d0390c5a03a9ec4be00c0925d04fe1430b8abc2e3c6b13f817c67c2276d2d64e113bf17d3d0eab59f09ef4f3f4536216f3b442a3ee5d5d1ad4836432ba5b3c49f255327f9e53acab4d222dd4f2cd04f025b4714bde6204cd228948e09e29e7a40d8f08397563fbe3a9aaa4b5d5dd34ea54c35c89123658f4b99327775ecd5d2f265f47447abeff807d9268ed9615c6c2844c2de5b9bbd694ba683613b2f174dc8a338092c90e8f21421d776751e88a62183e917038220f2946e182157981cde17703165ad631abcfdc32fbfc041a13c10524242f32ade21c6d87f535c66a83eec0b47bd2cda5ef2d6032aa233f5b5dcada2ec2eadf7337b5070276137035d72bf3df174753af0a4a5a3a946edea71b6ac2cb1800ed4845fbc32a9b428be5171d577fdaa1d1669bceeb154177a15b6bf139e6955aa414"

fn rsa_kat_nibble(ch: u8) -> i32:
    if ch >= '0' and ch <= '9': return (ch - '0') as i32
    (ch - 'a') as i32 + 10

pub fn rsa4096_pkcs1_sha256_kat() -> i32:
    var n: [u8; 512] = [0u8; 512]
    var sig: [u8; 512] = [0u8; 512]
    for i in 0..512:
        n[i] = (rsa_kat_nibble(RSA4096_KAT_N[2 * i]) * 16 + rsa_kat_nibble(RSA4096_KAT_N[2 * i + 1])) as u8
        sig[i] = (rsa_kat_nibble(RSA4096_KAT_SIG[2 * i]) * 16 + rsa_kat_nibble(RSA4096_KAT_SIG[2 * i + 1])) as u8
    let e: [u8; 3] = [0x01u8, 0x00u8, 0x01u8]
    var hash: [u8; 32] = [0u8; 32]
    sha256_hash_str("abc", &raw mut hash[0] as *mut u8)
    let good = unsafe { rsa_pkcs1_sha256_verify(&n[0] as *const u8, 512, &e[0] as *const u8, 3, &sig[0] as *const u8, 512, &hash[0] as *const u8) }
    if good != 1:
        return 1
    sig[100] = sig[100] ^ 1u8
    let bad = unsafe { rsa_pkcs1_sha256_verify(&n[0] as *const u8, 512, &e[0] as *const u8, 3, &sig[0] as *const u8, 512, &hash[0] as *const u8) }
    if bad != 0:
        return 2
    0
