// test_crypto.w — Tests for crypto primitives against standard test vectors.

use std.crypto.endian
use std.crypto.sha256
use std.crypto.hmac
use std.crypto.aes
use std.crypto.gcm
use std.crypto.chacha20
use std.crypto.poly1305
use std.crypto.chacha20poly1305

extern fn with_eprintln(s: str) -> void

var test_count: i32 = 0
var pass_count: i32 = 0
var fail_count: i32 = 0

fn assert_byte(a: u8, b: i32, msg: str):
    test_count = test_count + 1
    let av = (a as u32) as i32
    if av == b:
        pass_count = pass_count + 1
    else:
        fail_count = fail_count + 1
        unsafe { with_eprintln("  FAIL: " ++ msg ++ " (got " ++ int_to_string(av) ++ " expected " ++ int_to_string(b) ++ ")") }

fn assert_eq(a: i32, b: i32, msg: str):
    test_count = test_count + 1
    if a == b:
        pass_count = pass_count + 1
    else:
        fail_count = fail_count + 1
        unsafe { with_eprintln("  FAIL: " ++ msg ++ " (got " ++ int_to_string(a) ++ " expected " ++ int_to_string(b) ++ ")") }

// ── SHA-256: NIST test vectors ─────────────────────────────────────

fn test_sha256:
    unsafe { with_eprintln("  SHA-256...") }
    var empty: [u8; 1] = [0 as u8; 1]
    var hash: [u8; 32] = [0 as u8; 32]
    let hp = &raw mut hash[0] as *mut u8
    sha256_hash(&empty[0] as *const u8, 0, hp)
    // SHA-256("") = e3b0c44298fc1c14...7852b855
    assert_byte(hash[0], 0xe3, "sha256 empty byte 0")
    assert_byte(hash[1], 0xb0, "sha256 empty byte 1")
    assert_byte(hash[31], 0x55, "sha256 empty byte 31")

    var abc: [u8; 3] = [0x61 as u8, 0x62 as u8, 0x63 as u8]
    sha256_hash(&abc[0] as *const u8, 3, hp)
    // SHA-256("abc") = ba7816bf...f20015ad
    assert_byte(hash[0], 0xba, "sha256 abc byte 0")
    assert_byte(hash[1], 0x78, "sha256 abc byte 1")
    assert_byte(hash[31], 0xad, "sha256 abc byte 31")

    sha256_hash_str("abc", hp)
    assert_byte(hash[0], 0xba, "sha256 str abc byte 0")
    assert_byte(hash[1], 0x78, "sha256 str abc byte 1")
    assert_byte(hash[2], 0x16, "sha256 str abc byte 2")
    assert_byte(hash[31], 0xad, "sha256 str abc byte 31")

// ── HMAC-SHA256: RFC 4231 ──────────────────────────────────────────

fn test_hmac:
    unsafe { with_eprintln("  HMAC-SHA256...") }
    var key1: [u8; 20] = [0x0b as u8; 20]
    var data1: [u8; 8] = [0x48 as u8, 0x69 as u8, 0x20 as u8, 0x54 as u8, 0x68 as u8, 0x65 as u8, 0x72 as u8, 0x65 as u8]
    var mac: [u8; 32] = [0 as u8; 32]
    let mp = &raw mut mac[0] as *mut u8
    hmac_sha256(&key1[0] as *const u8, 20, &data1[0] as *const u8, 8, mp)
    // Expected: b0344c61...2e32cff7
    assert_byte(mac[0], 0xb0, "hmac tc1 byte 0")
    assert_byte(mac[1], 0x34, "hmac tc1 byte 1")
    assert_byte(mac[31], 0xf7, "hmac tc1 byte 31")

    hmac_sha256_str("Jefe", "what do ya want for nothing?", mp)
    // RFC 4231 test case 2:
    // 5bdcc146bf60754e6a042426089575c75a003f089d2739839dec58b964ec3843
    assert_byte(mac[0], 0x5b, "hmac str tc2 byte 0")
    assert_byte(mac[1], 0xdc, "hmac str tc2 byte 1")
    assert_byte(mac[2], 0xc1, "hmac str tc2 byte 2")
    assert_byte(mac[31], 0x43, "hmac str tc2 byte 31")

// ── AES-128: NIST ECB test vector ──────────────────────────────────

fn test_aes128:
    unsafe { with_eprintln("  AES-128...") }
    var key: [u8; 16] = [0x2b as u8, 0x7e as u8, 0x15 as u8, 0x16 as u8, 0x28 as u8, 0xae as u8, 0xd2 as u8, 0xa6 as u8, 0xab as u8, 0xf7 as u8, 0x15 as u8, 0x88 as u8, 0x09 as u8, 0xcf as u8, 0x4f as u8, 0x3c as u8]
    let ctx = Aes128.new(&key[0] as *const u8)
    var block: [u8; 16] = [0x32 as u8, 0x43 as u8, 0xf6 as u8, 0xa8 as u8, 0x88 as u8, 0x5a as u8, 0x30 as u8, 0x8d as u8, 0x31 as u8, 0x31 as u8, 0x98 as u8, 0xa2 as u8, 0xe0 as u8, 0x37 as u8, 0x07 as u8, 0x34 as u8]
    Aes128.encrypt_block(&ctx as *const Aes128, &raw mut block[0] as *mut u8)
    // Expected: 3925841d02dc09fbdc118597196a0b32
    assert_byte(block[0], 0x39, "aes128 byte 0")
    assert_byte(block[1], 0x25, "aes128 byte 1")
    assert_byte(block[15], 0x32, "aes128 byte 15")

// ── AES-128-GCM: NIST SP 800-38D test case 2 ──────────────────────

fn test_aesgcm:
    unsafe { with_eprintln("  AES-128-GCM...") }
    var key: [u8; 16] = [0 as u8; 16]
    var iv: [u8; 12] = [0 as u8; 12]
    var pt: [u8; 16] = [0 as u8; 16]
    var ct: [u8; 16] = [0 as u8; 16]
    var tag: [u8; 16] = [0 as u8; 16]
    var ctx = AesGcm.new(&key[0] as *const u8, &iv[0] as *const u8, 12)
    AesGcm.encrypt(&raw mut ctx as *mut AesGcm, &pt[0] as *const u8, &raw mut ct[0] as *mut u8, 16)
    AesGcm.tag(&raw mut ctx as *mut AesGcm, &raw mut tag[0] as *mut u8)
    // Expected CT: 0388dace60b6a392f328c2b971b2fe78
    assert_byte(ct[0], 0x03, "aesgcm ct byte 0")
    assert_byte(ct[1], 0x88, "aesgcm ct byte 1")
    // Expected tag: ab6e47d42cec13bdf53a67b21257bddf
    assert_byte(tag[0], 0xab, "aesgcm tag byte 0")
    assert_byte(tag[15], 0xdf, "aesgcm tag byte 15")

// ── ChaCha20: RFC 8439 §2.3.2 ─────────────────────────────────────

fn test_chacha20:
    unsafe { with_eprintln("  ChaCha20...") }
    var key: [u8; 32] = [0 as u8; 32]
    for i in 0..32:
        key[i] = i as u8
    var nonce: [u8; 12] = [0 as u8; 12]
    nonce[3] = 0x09 as u8
    nonce[7] = 0x4a as u8
    var block: [u8; 64] = [0 as u8; 64]
    unsafe:
        chacha20_block(&key[0] as *const u8, &nonce[0] as *const u8, 1 as u32, &raw mut block[0] as *mut u8)
    // Expected first 4 bytes: 10 f1 e7 e4
    assert_byte(block[0], 0x10, "chacha20 byte 0")
    assert_byte(block[1], 0xf1, "chacha20 byte 1")
    assert_byte(block[2], 0xe7, "chacha20 byte 2")
    assert_byte(block[3], 0xe4, "chacha20 byte 3")

// ── Poly1305: RFC 8439 §2.5.2 ─────────────────────────────────────

fn test_poly1305:
    unsafe { with_eprintln("  Poly1305...") }
    // Key: 85d6be7857556d337f4452fe42d506a8 0103808afb0db2fd4abff6af4149f51b
    var key: [u8; 32] = [0 as u8; 32]
    let kp = &raw mut key[0] as *mut u8
    unsafe:
        *(kp + 0 as u64) = 0x85 as u8
        *(kp + 1 as u64) = 0xd6 as u8
        *(kp + 2 as u64) = 0xbe as u8
        *(kp + 3 as u64) = 0x78 as u8
        *(kp + 4 as u64) = 0x57 as u8
        *(kp + 5 as u64) = 0x55 as u8
        *(kp + 6 as u64) = 0x6d as u8
        *(kp + 7 as u64) = 0x33 as u8
        *(kp + 8 as u64) = 0x7f as u8
        *(kp + 9 as u64) = 0x44 as u8
        *(kp + 10 as u64) = 0x52 as u8
        *(kp + 11 as u64) = 0xfe as u8
        *(kp + 12 as u64) = 0x42 as u8
        *(kp + 13 as u64) = 0xd5 as u8
        *(kp + 14 as u64) = 0x06 as u8
        *(kp + 15 as u64) = 0xa8 as u8
        *(kp + 16 as u64) = 0x01 as u8
        *(kp + 17 as u64) = 0x03 as u8
        *(kp + 18 as u64) = 0x80 as u8
        *(kp + 19 as u64) = 0x8a as u8
        *(kp + 20 as u64) = 0xfb as u8
        *(kp + 21 as u64) = 0x0d as u8
        *(kp + 22 as u64) = 0xb2 as u8
        *(kp + 23 as u64) = 0xfd as u8
        *(kp + 24 as u64) = 0x4a as u8
        *(kp + 25 as u64) = 0xbf as u8
        *(kp + 26 as u64) = 0xf6 as u8
        *(kp + 27 as u64) = 0xaf as u8
        *(kp + 28 as u64) = 0x41 as u8
        *(kp + 29 as u64) = 0x49 as u8
        *(kp + 30 as u64) = 0xf5 as u8
        *(kp + 31 as u64) = 0x1b as u8
    // Message: "Cryptographic Forum Research Group" (34 bytes)
    var msg: [u8; 34] = [0 as u8; 34]
    let mp = &raw mut msg[0] as *mut u8
    unsafe:
        *(mp + 0 as u64) = 0x43 as u8
        *(mp + 1 as u64) = 0x72 as u8
        *(mp + 2 as u64) = 0x79 as u8
        *(mp + 3 as u64) = 0x70 as u8
        *(mp + 4 as u64) = 0x74 as u8
        *(mp + 5 as u64) = 0x6f as u8
        *(mp + 6 as u64) = 0x67 as u8
        *(mp + 7 as u64) = 0x72 as u8
        *(mp + 8 as u64) = 0x61 as u8
        *(mp + 9 as u64) = 0x70 as u8
        *(mp + 10 as u64) = 0x68 as u8
        *(mp + 11 as u64) = 0x69 as u8
        *(mp + 12 as u64) = 0x63 as u8
        *(mp + 13 as u64) = 0x20 as u8
        *(mp + 14 as u64) = 0x46 as u8
        *(mp + 15 as u64) = 0x6f as u8
        *(mp + 16 as u64) = 0x72 as u8
        *(mp + 17 as u64) = 0x75 as u8
        *(mp + 18 as u64) = 0x6d as u8
        *(mp + 19 as u64) = 0x20 as u8
        *(mp + 20 as u64) = 0x52 as u8
        *(mp + 21 as u64) = 0x65 as u8
        *(mp + 22 as u64) = 0x73 as u8
        *(mp + 23 as u64) = 0x65 as u8
        *(mp + 24 as u64) = 0x61 as u8
        *(mp + 25 as u64) = 0x72 as u8
        *(mp + 26 as u64) = 0x63 as u8
        *(mp + 27 as u64) = 0x68 as u8
        *(mp + 28 as u64) = 0x20 as u8
        *(mp + 29 as u64) = 0x47 as u8
        *(mp + 30 as u64) = 0x72 as u8
        *(mp + 31 as u64) = 0x6f as u8
        *(mp + 32 as u64) = 0x75 as u8
        *(mp + 33 as u64) = 0x70 as u8
    var mac = Poly1305.new(kp as *const u8)
    unsafe:
        poly1305_update(&raw mut mac as *mut Poly1305, mp as *const u8, 34)
    var tag: [u8; 16] = [0 as u8; 16]
    unsafe:
        poly1305_finish(&raw mut mac as *mut Poly1305, &raw mut tag[0] as *mut u8)
    // Expected: a8061dc1305136c6c22b8baf0c0127a9
    assert_byte(tag[0], 0xa8, "poly1305 byte 0")
    assert_byte(tag[1], 0x06, "poly1305 byte 1")
    assert_byte(tag[2], 0x1d, "poly1305 byte 2")
    assert_byte(tag[3], 0xc1, "poly1305 byte 3")
    assert_byte(tag[4], 0x30, "poly1305 byte 4")
    assert_byte(tag[5], 0x51, "poly1305 byte 5")
    assert_byte(tag[6], 0x36, "poly1305 byte 6")
    assert_byte(tag[7], 0xc6, "poly1305 byte 7")
    assert_byte(tag[8], 0xc2, "poly1305 byte 8")
    assert_byte(tag[9], 0x2b, "poly1305 byte 9")
    assert_byte(tag[10], 0x8b, "poly1305 byte 10")
    assert_byte(tag[11], 0xaf, "poly1305 byte 11")
    assert_byte(tag[12], 0x0c, "poly1305 byte 12")
    assert_byte(tag[13], 0x01, "poly1305 byte 13")
    assert_byte(tag[14], 0x27, "poly1305 byte 14")
    assert_byte(tag[15], 0xa9, "poly1305 byte 15")

// ── Main ───────────────────────────────────────────────────────────

fn main:
    unsafe { with_eprintln("=== Crypto Test Suite ===") }
    test_sha256()
    test_hmac()
    test_aes128()
    test_aesgcm()
    test_chacha20()
    test_poly1305()
    unsafe { with_eprintln("=== Results: " ++ int_to_string(pass_count) ++ "/" ++ int_to_string(test_count) ++ " passed ===") }
    if fail_count > 0:
        unsafe { with_eprintln("FAILURES: " ++ int_to_string(fail_count)) }
    else:
        unsafe { with_eprintln("ALL PASSED") }
