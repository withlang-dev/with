// test_ec.w — P-256 elliptic curve tests

use std.crypto.ec

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

fn assert_byte(a: u8, b: i32, msg: str):
    test_count = test_count + 1
    let av = (a as u32) as i32
    if av == b:
        pass_count = pass_count + 1
    else:
        fail_count = fail_count + 1
        with_eprintln("  FAIL: " ++ msg ++ " (got " ++ int_to_string(av) ++ " expected " ++ int_to_string(b) ++ ")")

// RFC 6979 A.2.5 test vector: d -> Q = d*G
fn test_keygen:
    with_eprintln("  P-256 keygen...")
    var priv_key: [u8; 32] = [
        0xC9u8, 0xAFu8, 0xA9u8, 0xD8u8, 0x45u8, 0xBAu8, 0x75u8, 0x16u8,
        0x6Bu8, 0x5Cu8, 0x21u8, 0x57u8, 0x67u8, 0xB1u8, 0xD6u8, 0x93u8,
        0x4Eu8, 0x50u8, 0xC3u8, 0xDBu8, 0x36u8, 0xE8u8, 0x9Bu8, 0x12u8,
        0x7Bu8, 0x8Au8, 0x62u8, 0x2Bu8, 0x12u8, 0x0Fu8, 0x67u8, 0x21u8,
    ]
    var pub_key: [u8; 65] = [0u8; 65]
    unsafe: p256_compute_public(&priv_key[0] as *const u8, &mut pub_key[0] as *mut u8)

    // Check format byte
    assert_byte(pub_key[0], 0x04, "format byte")

    // Check first 4 bytes of Qx
    assert_byte(pub_key[1], 0x60, "Qx[0]")
    assert_byte(pub_key[2], 0xFE, "Qx[1]")
    assert_byte(pub_key[3], 0xD4, "Qx[2]")
    assert_byte(pub_key[4], 0xBA, "Qx[3]")

    // Check last 4 bytes of Qx
    assert_byte(pub_key[29], 0x60, "Qx[28]")
    assert_byte(pub_key[30], 0xF2, "Qx[29]")
    assert_byte(pub_key[31], 0x9F, "Qx[30]")
    assert_byte(pub_key[32], 0xB6, "Qx[31]")

    // Check first 4 bytes of Qy
    assert_byte(pub_key[33], 0x79, "Qy[0]")
    assert_byte(pub_key[34], 0x03, "Qy[1]")
    assert_byte(pub_key[35], 0xFE, "Qy[2]")
    assert_byte(pub_key[36], 0x10, "Qy[3]")

    // Check last 4 bytes of Qy
    assert_byte(pub_key[61], 0xD4, "Qy[28]")
    assert_byte(pub_key[62], 0x46, "Qy[29]")
    assert_byte(pub_key[63], 0x22, "Qy[30]")
    assert_byte(pub_key[64], 0x99, "Qy[31]")

fn main:
    with_eprintln("=== EC P-256 Test Suite ===")
    test_keygen()
    with_eprintln("=== Results: " ++ int_to_string(pass_count) ++ "/" ++ int_to_string(test_count) ++ " passed ===")
    if fail_count > 0:
        with_eprintln("FAILURES: " ++ int_to_string(fail_count))
    else:
        with_eprintln("ALL PASSED")
