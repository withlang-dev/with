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


var em: [u8; 128] = [0u8; 128]
em[0] = 0x00u8
em[1] = 0x01u8
var k = 2
while k < 75:
    em[k] = 0xFFu8
    k = k + 1
em[75] = 0x00u8
var di: [u8; 19] = [0u8; 19]
unsafe: write_digestinfo_sha256(&raw mut di[0] as *mut u8)
k = 0
while k < 19:
    em[76 + k] = di[k]
    k = k + 1
var h: [u8; 32] = [1u8; 32]
k = 0
while k < 32:
    em[96 + k] = h[k]
    k = k + 1
let r1 = unsafe: rsa_check_pkcs1_sha256(&em[0] as *const u8, 128, &h[0] as *const u8)
print_i32(r1)
em[127] = 0x00u8
let r2 = unsafe: rsa_check_pkcs1_sha256(&em[0] as *const u8, 128, &h[0] as *const u8)
print_i32(r2)
