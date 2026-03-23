// test_tls.w — TLS record layer and PRF tests

use std.tls

extern fn with_eprintln(s: str) -> void
extern fn int_to_string(n: i32) -> str

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

fn test_prf:
    with_eprintln("  TLS PRF...")
    // RFC 5246 test: PRF with known inputs
    // Use simple test: PRF("secret", "label", "seed") should produce deterministic output
    var secret: [u8; 6] = [0x73u8, 0x65u8, 0x63u8, 0x72u8, 0x65u8, 0x74u8]  // "secret"
    var label: [u8; 5] = [0x6Cu8, 0x61u8, 0x62u8, 0x65u8, 0x6Cu8]  // "label"
    var seed: [u8; 4] = [0x73u8, 0x65u8, 0x65u8, 0x64u8]  // "seed"
    var output: [u8; 32] = [0u8; 32]
    unsafe: tls_prf_sha256(
        &secret[0] as *const u8, 6,
        &label[0] as *const u8, 5,
        &seed[0] as *const u8, 4,
        &mut output[0] as *mut u8, 32,
    )
    // Output should be non-zero and deterministic
    assert_true(output[0] != 0u8 or output[1] != 0u8, "PRF output non-zero")

    // Run again to verify determinism
    var output2: [u8; 32] = [0u8; 32]
    unsafe: tls_prf_sha256(
        &secret[0] as *const u8, 6,
        &label[0] as *const u8, 5,
        &seed[0] as *const u8, 4,
        &mut output2[0] as *mut u8, 32,
    )
    var match_val = 1
    var i = 0
    while i < 32:
        if output[i] != output2[i]:
            match_val = 0
        i = i + 1
    assert_true(match_val == 1, "PRF deterministic")

fn test_conn_init:
    with_eprintln("  TLS conn init...")
    var conn = TlsConn.new(-1)
    assert_eq(conn.fd, -1, "fd = -1")
    assert_eq(conn.cipher_active, 0, "cipher not active")
    assert_true(conn.client_seq == 0u64, "client seq = 0")
    assert_true(conn.server_seq == 0u64, "server seq = 0")

fn main:
    with_eprintln("=== TLS Test Suite ===")
    test_prf()
    test_conn_init()
    with_eprintln("=== Results: " ++ int_to_string(pass_count) ++ "/" ++ int_to_string(test_count) ++ " passed ===")
    if fail_count > 0:
        with_eprintln("FAILURES: " ++ int_to_string(fail_count))
    else:
        with_eprintln("ALL PASSED")
