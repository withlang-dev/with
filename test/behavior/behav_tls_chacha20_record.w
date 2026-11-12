//! expect-stdout: chacha-record=0
// RFC 7905: a TLS 1.2 record under ChaCha20-Poly1305. A server that offers
// no AES-GCM suite (a GNU mirror did, and `with get` could not reach it)
// is spoken to with this one.
use std.tls

fn main:
    print(f"chacha-record={tls_chacha_record_kat()}")
