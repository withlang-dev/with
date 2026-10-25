//! expect-stdout: rsa4096=0
// #1052: RSA-4096 verification (std.crypto.rsa known answer). A 4096-bit
// modulus is 133 i31 words; i31_from_monty's 80-word temps ran past their
// end for any modulus above 2449 bits.
use std.crypto.rsa

fn main:
    print(f"rsa4096={rsa4096_pkcs1_sha256_kat()}")
