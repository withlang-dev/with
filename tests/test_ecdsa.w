// test_ecdsa.w — ECDSA P-256 verification test (RFC 6979 A.2.5)

use std.crypto.ecdsa

extern fn with_eprintln(s: str) -> void
extern fn int_to_string(n: i32) -> str

var test_count: i32 = 0
var pass_count: i32 = 0
var fail_count: i32 = 0

fn assert_true(cond: bool, msg: str):
    test_count = test_count + 1
    if cond:
        pass_count = pass_count + 1
    else:
        fail_count = fail_count + 1
        with_eprintln("  FAIL: " ++ msg)

fn test_ecdsa_verify:
    with_eprintln("  ECDSA-P256-SHA256 verify (RFC 6979)...")
    // Public key from RFC 6979 A.2.5
    var qx: [u8; 32] = [
        0x60u8, 0xFEu8, 0xD4u8, 0xBAu8, 0x25u8, 0x5Au8, 0x9Du8, 0x31u8,
        0xC9u8, 0x61u8, 0xEBu8, 0x74u8, 0xC6u8, 0x35u8, 0x6Du8, 0x68u8,
        0xC0u8, 0x49u8, 0xB8u8, 0x92u8, 0x3Bu8, 0x61u8, 0xFAu8, 0x6Cu8,
        0xE6u8, 0x69u8, 0x62u8, 0x2Eu8, 0x60u8, 0xF2u8, 0x9Fu8, 0xB6u8,
    ]
    var qy: [u8; 32] = [
        0x79u8, 0x03u8, 0xFEu8, 0x10u8, 0x08u8, 0xB8u8, 0xBCu8, 0x99u8,
        0xA4u8, 0x1Au8, 0xE9u8, 0xE9u8, 0x56u8, 0x28u8, 0xBCu8, 0x64u8,
        0xF2u8, 0xF1u8, 0xB2u8, 0x0Cu8, 0x2Du8, 0x7Eu8, 0x9Fu8, 0x51u8,
        0x77u8, 0xA3u8, 0xC2u8, 0x94u8, 0xD4u8, 0x46u8, 0x22u8, 0x99u8,
    ]
    // SHA-256("sample")
    var hash: [u8; 32] = [
        0xAFu8, 0x2Bu8, 0xDBu8, 0xE1u8, 0xAAu8, 0x9Bu8, 0x6Eu8, 0xC1u8,
        0xE2u8, 0xADu8, 0xE1u8, 0xD6u8, 0x94u8, 0xF4u8, 0x1Fu8, 0xC7u8,
        0x1Au8, 0x83u8, 0x1Du8, 0x02u8, 0x68u8, 0xE9u8, 0x89u8, 0x15u8,
        0x62u8, 0x11u8, 0x3Du8, 0x8Au8, 0x62u8, 0xADu8, 0xD1u8, 0xBFu8,
    ]
    // Signature (r, s) from RFC 6979 A.2.5 with SHA-256
    var sig_r: [u8; 32] = [
        0xEFu8, 0xD4u8, 0x8Bu8, 0x2Au8, 0xACu8, 0xB6u8, 0xA8u8, 0xFDu8,
        0x11u8, 0x40u8, 0xDDu8, 0x9Cu8, 0xD4u8, 0x5Eu8, 0x81u8, 0xD6u8,
        0x9Du8, 0x2Cu8, 0x87u8, 0x7Bu8, 0x56u8, 0xAAu8, 0xF9u8, 0x91u8,
        0xC3u8, 0x4Du8, 0x0Eu8, 0xA8u8, 0x4Eu8, 0xAFu8, 0x37u8, 0x16u8,
    ]
    var sig_s: [u8; 32] = [
        0xF7u8, 0xCBu8, 0x1Cu8, 0x94u8, 0x2Du8, 0x65u8, 0x7Cu8, 0x41u8,
        0xD4u8, 0x36u8, 0xC7u8, 0xA1u8, 0xB6u8, 0xE2u8, 0x9Fu8, 0x65u8,
        0xF3u8, 0xE9u8, 0x00u8, 0xDBu8, 0xB9u8, 0xAFu8, 0xF4u8, 0x06u8,
        0x4Du8, 0xC4u8, 0xABu8, 0x2Fu8, 0x84u8, 0x3Au8, 0xCDu8, 0xA8u8,
    ]

    let ok = unsafe: ecdsa_p256_verify(
        &qx[0] as *const u8, &qy[0] as *const u8,
        &hash[0] as *const u8,
        &sig_r[0] as *const u8, &sig_s[0] as *const u8,
    )
    assert_true(ok == 1, "valid ECDSA sig accepted")

    // Corrupt r → should fail
    sig_r[0] = sig_r[0] ^ 0x01u8
    let ok2 = unsafe: ecdsa_p256_verify(
        &qx[0] as *const u8, &qy[0] as *const u8,
        &hash[0] as *const u8,
        &sig_r[0] as *const u8, &sig_s[0] as *const u8,
    )
    assert_true(ok2 == 0, "corrupted r rejected")

    // Corrupt hash → should fail
    sig_r[0] = sig_r[0] ^ 0x01u8  // restore r
    hash[0] = hash[0] ^ 0x01u8
    let ok3 = unsafe: ecdsa_p256_verify(
        &qx[0] as *const u8, &qy[0] as *const u8,
        &hash[0] as *const u8,
        &sig_r[0] as *const u8, &sig_s[0] as *const u8,
    )
    assert_true(ok3 == 0, "corrupted hash rejected")

fn main:
    with_eprintln("=== ECDSA Test Suite ===")
    test_ecdsa_verify()
    with_eprintln("=== Results: " ++ int_to_string(pass_count) ++ "/" ++ int_to_string(test_count) ++ " passed ===")
    if fail_count > 0:
        with_eprintln("FAILURES: " ++ int_to_string(fail_count))
    else:
        with_eprintln("ALL PASSED")
