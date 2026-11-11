//! expect-stdout: hmac=0 modpow=0 prf=0 p256=0 ecdsa=0

// #1053, #1063: known answers for std.crypto.hmac (RFC 4231 case 2),
// std.crypto.bigint's modular exponentiation and std.tls's P_SHA256 PRF.
// #1055: P-256's base point and an RFC 6979 ECDSA signature.
// None had a test that ran: the suites under tests/ were written in a
// syntax the compiler stopped reading.
use std.crypto.hmac
use std.crypto.bigint
use std.tls
use std.crypto.ec
use std.crypto.ecdsa

fn main:
    print(f"hmac={hmac_sha256_kat()} modpow={i31_modpow_kat()} prf={tls_prf_sha256_kat()} p256={p256_public_kat()} ecdsa={ecdsa_p256_kat()}")
