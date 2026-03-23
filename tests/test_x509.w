// test_x509.w — X.509 certificate parsing and verification test

use std.crypto.x509

extern fn with_eprintln(s: str) -> void
extern fn int_to_string(n: i32) -> str
extern fn with_fs_read_file(path: str) -> str

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

fn test_der_parser:
    with_eprintln("  DER parser...")
    // SEQUENCE { INTEGER 42, NULL } = 30 05 02 01 2A 05 00
    var buf: [u8; 7] = [0x30u8, 0x05u8, 0x02u8, 0x01u8, 0x2Au8, 0x05u8, 0x00u8]
    var tag: u8 = 0u8
    var cs: i32 = 0
    var cl: i32 = 0

    unsafe: der_read_tl(&buf[0] as *const u8, 7, 0, &mut tag as *mut u8, &mut cs as *mut i32, &mut cl as *mut i32)
    assert_eq(tag as i32, 0x30, "SEQUENCE tag")
    assert_eq(cs, 2, "SEQUENCE content start")
    assert_eq(cl, 5, "SEQUENCE content length")

    unsafe: der_read_tl(&buf[0] as *const u8, 7, 2, &mut tag as *mut u8, &mut cs as *mut i32, &mut cl as *mut i32)
    assert_eq(tag as i32, 0x02, "INTEGER tag")
    assert_eq(cs, 4, "INTEGER content start")
    assert_eq(cl, 1, "INTEGER content length")

    // Long-form length: 0x82 0x01 0x00 = 256
    var buf2: [u8; 4] = [0x30u8, 0x82u8, 0x01u8, 0x00u8]
    unsafe: der_read_tl(&buf2[0] as *const u8, 4, 0, &mut tag as *mut u8, &mut cs as *mut i32, &mut cl as *mut i32)
    assert_eq(cl, 256, "long-form length")

    let skip_pos = unsafe: der_skip(&buf[0] as *const u8, 7, 2)
    assert_eq(skip_pos, 5, "skip INTEGER")

fn test_oid_matching:
    with_eprintln("  OID matching...")
    var oid: [u8; 8] = [0x2Au8, 0x86u8, 0x48u8, 0xCEu8, 0x3Du8, 0x04u8, 0x03u8, 0x02u8]
    var expected: [u8; 8] = [0u8; 8]
    unsafe: oid_ecdsa_sha256(&mut expected[0] as *mut u8)
    let m = unsafe: oid_match(&oid[0] as *const u8, 0, 8, &expected[0] as *const u8, 8)
    assert_eq(m, 1, "ECDSA-SHA256 OID match")
    oid[7] = 0x03u8
    let m2 = unsafe: oid_match(&oid[0] as *const u8, 0, 8, &expected[0] as *const u8, 8)
    assert_eq(m2, 0, "wrong OID rejected")

fn test_parse_real_cert:
    with_eprintln("  parse real cert...")
    // Load DER cert from file
    let cert_data = with_fs_read_file("/tmp/ec_cert.der")
    if cert_data.len() == 0:
        with_eprintln("  SKIP: /tmp/ec_cert.der not found (run: openssl req -new -x509 -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 -keyout /dev/null -nodes -out /tmp/ec_cert.pem -days 1 -subj '/CN=test' -sha256 && openssl x509 -in /tmp/ec_cert.pem -outform DER -out /tmp/ec_cert.der)")
        return

    let cert_buf = cert_data as *const u8
    let cert_len = cert_data.len() as i32
    with_eprintln("  cert size: " ++ int_to_string(cert_len))

    var cert = X509Cert.new()
    let ok = unsafe: x509_parse(&mut cert as *mut X509Cert, cert_buf, cert_len)
    assert_eq(ok, 1, "parse success")
    assert_eq(cert.sig_alg, 2, "sig_alg = ECDSA-SHA256")
    assert_eq(cert.key_type, 2, "key_type = EC")
    assert_eq(cert.key_point_len, 65, "EC point = 65 bytes")
    assert_true(cert.tbs_len > 0, "tbs_len > 0")
    assert_true(cert.sig_len > 0, "sig_len > 0")

    // Self-signed: verify signature using own key
    let verify_ok = unsafe: x509_verify_signature(cert_buf, &cert as *const X509Cert, cert_buf, &cert as *const X509Cert)
    assert_eq(verify_ok, 1, "self-signed ECDSA verify")

fn main:
    with_eprintln("=== X.509 Test Suite ===")
    test_der_parser()
    test_oid_matching()
    test_parse_real_cert()
    with_eprintln("=== Results: " ++ int_to_string(pass_count) ++ "/" ++ int_to_string(test_count) ++ " passed ===")
    if fail_count > 0:
        with_eprintln("FAILURES: " ++ int_to_string(fail_count))
    else:
        with_eprintln("ALL PASSED")
