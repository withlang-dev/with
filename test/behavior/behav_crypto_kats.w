//! expect-stdout: gcm=0 sha256_abc=ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad
// Crypto known-answer tests. Guards #883: the AES-128-GCM GHASH multiply
// (NIST SP 800-38D test case 2) and SHA-256("abc").
use std.crypto.gcm
use std.crypto.sha256
fn main:
    let g = aes128_gcm_kat()
    var d: [u8; 32] = [0u8; 32]
    sha256_hash_str("abc", &raw mut d[0] as *mut u8)
    let h = sha256_hex(&d[0] as *const u8)
    print(f"gcm={g} sha256_abc={h}")
