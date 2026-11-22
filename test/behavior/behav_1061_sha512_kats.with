//! expect-stdout: ok
// #1061: SHA-512 and SHA-384 known answers (FIPS 180-4 examples), the
// hash the P-384 chain signatures need. std.crypto had only SHA-256.
use std.crypto.sha512

fn hex_of(digest: *const u8, n: i32) -> str:
    let hex_chars = "0123456789abcdef"
    var result = ""
    for i in 0..n:
        let b = (unsafe *(digest + i as u64)) as i32
        result = result ++ hex_chars.slice(((b >> 4) & 0x0F) as i64, ((b >> 4) & 0x0F) as i64 + 1) ++ hex_chars.slice((b & 0x0F) as i64, (b & 0x0F) as i64 + 1)
    result

fn main:
    var out512: [u8; 64] = [0u8; 64]
    var out384: [u8; 48] = [0u8; 48]
    sha512_hash_str("abc", &raw mut out512[0] as *mut u8)
    sha384_hash_str("abc", &raw mut out384[0] as *mut u8)
    assert(hex_of(&out512[0] as *const u8, 64) == "ddaf35a193617abacc417349ae20413112e6fa4e89a97ea20a9eeee64b55d39a2192992a274fc1a836ba3c23a3feebbd454d4423643ce80e2a9ac94fa54ca49f")
    assert(hex_of(&out384[0] as *const u8, 48) == "cb00753f45a35e8bb5a03d699ac65007272c32ab0eded1631a8b605a43ff5bed8086072ba1e7cc2358baeca134c825a7")

    // The 112-byte FIPS example (crosses the 128-byte block padding edge).
    var out_long: [u8; 64] = [0u8; 64]
    sha512_hash_str("abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu", &raw mut out_long[0] as *mut u8)
    assert(hex_of(&out_long[0] as *const u8, 64) == "8e959b75dae313da8cf4f72814fc143f8f7779c6eb9f7fa17299aeadb6889018501d289e4900f7e4331b99dec4b5433ac7d329eeb6dd26545e96e55b874be909")
    print("ok")
