// test_bigint.w — Tests for big integer arithmetic (i31 format)

use std.crypto.bigint

extern fn with_eprintln(s: str) -> void
extern fn int_to_string(n: i32) -> str
extern fn i64_to_string(n: i64) -> str

var test_count: i32 = 0
var pass_count: i32 = 0
var fail_count: i32 = 0

fn assert_eq(a: i32, b: i32, msg: str):
    test_count = test_count + 1
    if a == b:
        pass_count = pass_count + 1
    else:
        fail_count = fail_count + 1
        with_eprintln("  FAIL: " ++ msg ++ " (got " ++ int_to_string(a) ++ " expected " ++ int_to_string(b) ++ ")")

fn assert_true(cond: bool, msg: str):
    test_count = test_count + 1
    if cond:
        pass_count = pass_count + 1
    else:
        fail_count = fail_count + 1
        with_eprintln("  FAIL: " ++ msg)

// ── Word count ─────────────────────────────────────────────────────

fn test_word_count:
    with_eprintln("  word count...")
    assert_eq(i31_word_count(0 as u32), 0, "wc(0)")
    assert_eq(i31_word_count(1 as u32), 1, "wc(1)")
    assert_eq(i31_word_count(31 as u32), 1, "wc(31)")
    assert_eq(i31_word_count(32 as u32), 2, "wc(32)")
    assert_eq(i31_word_count(62 as u32), 2, "wc(62)")
    assert_eq(i31_word_count(63 as u32), 3, "wc(63)")

// ── ninv31 ─────────────────────────────────────────────────────────

fn test_ninv31:
    with_eprintln("  ninv31...")
    // ninv31(7) = 1227133513
    let n7 = i31_ninv31(7 as u32)
    assert_true(n7 == 1227133513 as u32, "ninv31(7)")
    // Verify: 7 * ninv31(7) mod 2^31 should be 0x7FFFFFFF
    let check7 = (7 as u32) *% n7
    assert_true((check7 & 0x7FFFFFFF as u32) == 0x7FFFFFFF as u32, "ninv31(7) verify")

    // ninv31(13)
    let n13 = i31_ninv31(13 as u32)
    let check13 = (13 as u32) *% n13
    assert_true((check13 & 0x7FFFFFFF as u32) == 0x7FFFFFFF as u32, "ninv31(13) verify")

    // ninv31(997)
    let n997 = i31_ninv31(997 as u32)
    let check997 = (997 as u32) *% n997
    assert_true((check997 & 0x7FFFFFFF as u32) == 0x7FFFFFFF as u32, "ninv31(997) verify")

// ── Decode/Encode roundtrip ────────────────────────────────────────

fn test_decode_encode:
    with_eprintln("  decode/encode...")
    // Encode 0xDEADBEEF as 4 big-endian bytes, decode, verify limbs, re-encode
    var src: [u8; 4] = [0xDE as u8, 0xAD as u8, 0xBE as u8, 0xEF as u8]
    var x: [u32; 4] = [0 as u32; 4]
    let xp = &mut x[0] as *mut u32
    unsafe: i31_decode(xp, &src[0] as *const u8, 4)

    // bitlen should be 32
    assert_eq(x[0] as i32, 32, "decode bitlen")
    // Limb 0 = 0xDEADBEEF & 0x7FFFFFFF = 0x5EADBEEF = 1588444911
    assert_true(x[1] == 1588444911 as u32, "decode limb 0")
    // Limb 1 = 0xDEADBEEF >> 31 = 1
    assert_true(x[2] == 1 as u32, "decode limb 1")

    // Re-encode to 4 bytes
    var dst: [u8; 4] = [0 as u8; 4]
    unsafe: i31_encode(&mut dst[0] as *mut u8, 4, xp as *const u32)
    assert_true((dst[0] as u32) == 0xDE as u32, "encode byte 0")
    assert_true((dst[1] as u32) == 0xAD as u32, "encode byte 1")
    assert_true((dst[2] as u32) == 0xBE as u32, "encode byte 2")
    assert_true((dst[3] as u32) == 0xEF as u32, "encode byte 3")

    // Test with a single byte
    var src2: [u8; 1] = [42 as u8]
    var x2: [u32; 4] = [0 as u32; 4]
    let x2p = &mut x2[0] as *mut u32
    unsafe: i31_decode(x2p, &src2[0] as *const u8, 1)
    assert_eq(x2[0] as i32, 6, "decode single bitlen") // 42 = 101010, 6 bits
    assert_true(x2[1] == 42 as u32, "decode single limb")

    var dst2: [u8; 1] = [0 as u8]
    unsafe: i31_encode(&mut dst2[0] as *mut u8, 1, x2p as *const u32)
    assert_true((dst2[0] as u32) == 42 as u32, "encode single byte")

// ── Modular exponentiation ─────────────────────────────────────────

fn test_modpow_small:
    with_eprintln("  modpow (small)...")
    // Test: 3^7 mod 13 = 3
    // base = 3: bytes [0x03]
    // exponent = 7: bytes [0x07]
    // modulus = 13: bytes [0x0D]

    // Encode modulus
    var m_bytes: [u8; 1] = [13 as u8]
    var m: [u32; 4] = [0 as u32; 4]
    let mp = &mut m[0] as *mut u32
    unsafe: i31_decode(mp, &m_bytes[0] as *const u8, 1)

    let m0i = i31_ninv31(m[1])

    // Encode base, reduce mod m
    var x_bytes: [u8; 1] = [3 as u8]
    var x: [u32; 4] = [0 as u32; 4]
    let xp = &mut x[0] as *mut u32
    unsafe: i31_decode_reduce(xp, &x_bytes[0] as *const u8, 1, mp as *const u32)

    // Exponent
    var e: [u8; 1] = [7 as u8]

    // Temporaries
    var t1: [u32; 4] = [0 as u32; 4]
    var t2: [u32; 4] = [0 as u32; 4]

    unsafe: i31_modpow(
        xp,
        &e[0] as *const u8, 1,
        mp as *const u32, m0i,
        &mut t1[0] as *mut u32,
        &mut t2[0] as *mut u32,
    )

    // Re-encode result
    var result: [u8; 1] = [0 as u8]
    unsafe: i31_encode(&mut result[0] as *mut u8, 1, xp as *const u32)
    assert_true((result[0] as u32) == 3 as u32, "3^7 mod 13 = 3")

fn test_modpow_medium:
    with_eprintln("  modpow (medium)...")
    // Test: 100^3 mod 997 = 9
    // modulus 997: bytes [0x03, 0xE5]
    var m_bytes: [u8; 2] = [0x03 as u8, 0xE5 as u8]
    var m: [u32; 4] = [0 as u32; 4]
    let mp = &mut m[0] as *mut u32
    unsafe: i31_decode(mp, &m_bytes[0] as *const u8, 2)

    let m0i = i31_ninv31(m[1])

    // base = 100: bytes [0x64]
    var x_bytes: [u8; 1] = [0x64 as u8]
    var x: [u32; 4] = [0 as u32; 4]
    let xp = &mut x[0] as *mut u32
    unsafe: i31_decode_reduce(xp, &x_bytes[0] as *const u8, 1, mp as *const u32)

    // exponent = 3
    var e: [u8; 1] = [3 as u8]

    var t1: [u32; 4] = [0 as u32; 4]
    var t2: [u32; 4] = [0 as u32; 4]

    unsafe: i31_modpow(
        xp,
        &e[0] as *const u8, 1,
        mp as *const u32, m0i,
        &mut t1[0] as *mut u32,
        &mut t2[0] as *mut u32,
    )

    var result: [u8; 2] = [0 as u8; 2]
    unsafe: i31_encode(&mut result[0] as *mut u8, 2, xp as *const u32)
    // 9 = 0x0009
    assert_true((result[0] as u32) == 0 as u32, "100^3 mod 997 hi byte")
    assert_true((result[1] as u32) == 9 as u32, "100^3 mod 997 lo byte")

fn test_modpow_rsa_like:
    with_eprintln("  modpow (RSA-like)...")
    // Test: 17^65537 mod 3233 = 908
    // 3233 = 0x0CA1
    var m_bytes: [u8; 2] = [0x0C as u8, 0xA1 as u8]
    var m: [u32; 4] = [0 as u32; 4]
    let mp = &mut m[0] as *mut u32
    unsafe: i31_decode(mp, &m_bytes[0] as *const u8, 2)

    let m0i = i31_ninv31(m[1])

    // base = 17 = 0x11
    var x_bytes: [u8; 1] = [0x11 as u8]
    var x: [u32; 4] = [0 as u32; 4]
    let xp = &mut x[0] as *mut u32
    unsafe: i31_decode_reduce(xp, &x_bytes[0] as *const u8, 1, mp as *const u32)

    // exponent = 65537 = 0x010001
    var e: [u8; 3] = [0x01 as u8, 0x00 as u8, 0x01 as u8]

    var t1: [u32; 4] = [0 as u32; 4]
    var t2: [u32; 4] = [0 as u32; 4]

    unsafe: i31_modpow(
        xp,
        &e[0] as *const u8, 3,
        mp as *const u32, m0i,
        &mut t1[0] as *mut u32,
        &mut t2[0] as *mut u32,
    )

    var result: [u8; 2] = [0 as u8; 2]
    unsafe: i31_encode(&mut result[0] as *mut u8, 2, xp as *const u32)
    // 908 = 0x038C
    assert_true((result[0] as u32) == 0x03 as u32, "17^65537 mod 3233 hi")
    assert_true((result[1] as u32) == 0x8C as u32, "17^65537 mod 3233 lo")

// ── Main ───────────────────────────────────────────────────────────

fn main:
    with_eprintln("=== BigInt Test Suite ===")
    test_word_count()
    test_ninv31()
    test_decode_encode()
    test_modpow_small()
    test_modpow_medium()
    test_modpow_rsa_like()
    with_eprintln("=== Results: " ++ int_to_string(pass_count) ++ "/" ++ int_to_string(test_count) ++ " passed ===")
    if fail_count > 0:
        with_eprintln("FAILURES: " ++ int_to_string(fail_count))
    else:
        with_eprintln("ALL PASSED")
