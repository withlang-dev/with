use std.crypto.rsa
var em: [u8; 128] = [0u8; 128]
var hash: [u8; 32] = [0u8; 32]
fn main:
    let r = unsafe: rsa_check_pkcs1_sha256(&em[0] as *const u8, 128, &hash[0] as *const u8)
    print_i32(r)
