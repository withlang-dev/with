# Plan: Port BearSSL to With Standard Library

**Status:** Paused — fixing Poly1305 partial-block handling and borrow checker false positives on array element references.

## Context

The With package manager needs HTTPS to download packages from Conan Center. We're implementing TLS in pure With by porting BearSSL — a minimal, self-contained, zero-dependency TLS library (~60K LOC of C). This gives With a native `std.tls` module with no external dependencies.

## What's Done

- **Phase 0 complete:** TCP networking (`lib/std/net.w` + runtime), sysinfo (`lib/std/sysinfo.w`), ConanClient uses dynamic OS/arch detection
- **Phase 1 complete:** SHA-256 — `lib/std/crypto/sha256.w`, passes NIST test vectors (empty string + "abc")
- **Phase 2 complete:** HMAC-SHA256 — `lib/std/crypto/hmac.w`, passes RFC 4231 test cases 1 and 2
- **Phase 3 complete:** AES-128 — `lib/std/crypto/aes.w`, passes NIST ECB test vector
- **Phase 4 complete:** AES-128-GCM — `lib/std/crypto/gcm.w`, passes NIST SP 800-38D test case 2
- **Phase 5 in progress:** ChaCha20-Poly1305 — ChaCha20 passes RFC 8439 §2.3.2, Poly1305 has partial-block bug

## Compiler bugs found and fixed during this work

1. **`&mut x as *mut T` parse precedence** — parsed as `&mut (x as *mut T)` instead of `(&mut x) as *mut T`. Fixed: suppress `as` inside `&`/`&mut` operand, run `parse_postfix` on result.
2. **`u8 as u32` sign-extension** — widening cast from unsigned types sign-extended instead of zero-extending. Fixed: check target type signedness in `RK_CAST` codegen.
3. **`defer` in non-main functions** — `NK_DEFER` not handled in `lower_expr`, only in block statement loop. Fixed: added handler.
4. **`&mut (unsafe: (*ptr).field)` temporary address** — takes address of a loaded COPY, not the field in the struct. Workaround: copy struct fields to stack locals, operate on locals, copy back.

## Known issues blocking Phase 5 completion

- **Poly1305 partial-block handling:** The `final_block` flag controls the hibit (0x01 appended after message bytes). For partial blocks, the hibit position depends on message length, not fixed at bit 128. Current implementation doesn't handle this correctly.
- **Borrow checker false positives on `&mut arr[i]`:** Taking `&mut arr[0] as *mut T` creates a mutable borrow that the checker thinks persists after function calls return. Workaround: grab pointer once into a `let` binding early in the function. This is verbose but functional.

## Blocker (resolved)

~~Fixed-size arrays~~ — implemented. Both `[T; N]` (spec syntax) and `[N]T` (legacy) work. Array fill `[value; N]` works.

## Architecture

```
lib/std/
├── crypto/
│   ├── sha256.w          # SHA-256 hash
│   ├── hmac.w            # HMAC-SHA256
│   ├── aes.w             # AES block cipher (constant-time)
│   ├── gcm.w             # AES-GCM authenticated encryption
│   ├── chacha20.w        # ChaCha20 stream cipher
│   ├── poly1305.w        # Poly1305 MAC
│   ├── chacha20poly1305.w # ChaCha20-Poly1305 AEAD
│   ├── bigint.w          # Big integer arithmetic (i31 variant)
│   ├── rsa.w             # RSA signature verification
│   ├── ec.w              # Elliptic curve operations (P-256)
│   ├── ecdsa.w           # ECDSA signature verification
│   ├── ecdh.w            # ECDHE key exchange
│   └── random.w          # CSPRNG (seeded from OS entropy)
├── tls/
│   ├── engine.w          # TLS record layer engine
│   ├── handshake.w       # TLS 1.2 client handshake
│   ├── record.w          # Record encryption/decryption
│   ├── prf.w             # TLS PRF (key derivation)
│   └── x509.w            # X.509 certificate validation
├── net.w                 # TCP (implemented)
├── http.w                # HTTP/1.1 client (new)
└── sysinfo.w             # OS/arch detection (implemented)
```

## Implementation Phases

| Phase | What | Lines | Status |
|-------|------|-------|--------|
| 0 | TCP + sysinfo | 100 | **Done** |
| 1 | SHA-256 | 200 | **Done** — passes NIST vectors |
| 2 | HMAC-SHA256 | 100 | **Done** — passes RFC 4231 |
| 3 | AES-128 | 300 | **Done** — passes NIST ECB vector |
| 4 | AES-GCM | 200 | **Done** — passes NIST SP 800-38D |
| 5 | ChaCha20-Poly1305 | 250 | **In progress** — ChaCha20 ✓, Poly1305 partial-block bug |
| 6 | Big integer | 500 | |
| 7 | RSA verify | 300 | |
| 8 | EC P-256 | 400 | |
| 9 | ECDSA + ECDH | 200 | |
| 10 | X.509 | 400 | |
| 11 | TLS record layer | 300 | |
| 12 | TLS handshake | 500 | |
| 13 | HTTP client | 150 | |
| 14 | ConanClient wire-up | 20 | |

**Total: ~3,920 lines of With**

## Key BearSSL Source Files

| With module | BearSSL source | LOC |
|-------------|---------------|-----|
| crypto/sha256.w | src/hash/sha2small.c | 299 |
| crypto/hmac.w | src/mac/hmac.c | 52 |
| crypto/aes.w | src/symcipher/aes_ct.c | 255 |
| crypto/gcm.w | src/aead/gcm.c | 176 |
| crypto/chacha20.w | src/symcipher/chacha20_ct.c | 138 |
| crypto/poly1305.w | src/mac/poly1305_ctmul.c | 199 |
| crypto/bigint.w | src/int/i31_*.c | ~2000 |
| crypto/rsa.w | src/rsa/rsa_i31_pkcs1_vrfy.c | 127 |
| crypto/ec.w | src/ec/ec_p256_m31.c | 1096 |
| crypto/ecdsa.w | src/ec/ecdsa_i31_vrfy_*.c | 88 |
| tls/engine.w | src/ssl/ssl_engine.c | 1584 |
| tls/handshake.w | src/ssl/ssl_hs_client.c | 1915 |
| tls/x509.w | src/x509/x509_minimal.c | 1722 |

## BearSSL Design Notes (for when we resume)

- **No malloc/free** — all contexts are caller-allocated structs
- **Callback I/O** — caller provides `sock_read`/`sock_write` functions
- **Virtual method tables** — crypto algorithms selected via function pointer structs (maps to With traits)
- **Multiple implementations** — e.g. AES has ct, ct64, big, pwr8 variants. We port `ct` (constant-time, safest)
- **T0 compiler** — handshake logic generated from `.t0` DSL files. Strategy: port the GENERATED C, not the T0 source
- **Big integer: i31 variant** — uses 31-bit limbs with 32-bit multiplies. Simplest to port.

## SHA-256 Algorithm Summary (ready to port)

Core function: `br_sha2small_round(buf, val)` — 64 rounds of:
1. Message schedule expansion: `w[i] = σ1(w[i-2]) + w[i-7] + σ0(w[i-15]) + w[i-16]`
2. Compression: `T1 = h + Σ1(e) + Ch(e,f,g) + K[i] + w[i]`, `T2 = Σ0(a) + Maj(a,b,c)`
3. State update: shift registers, `d += T1`, `h = T1 + T2`

Helper functions needed:
- `rotr(x: u32, n: i32) -> u32` — right rotate
- `dec32be(buf, offset) -> u32` — big-endian decode
- `enc32be(buf, offset, val)` — big-endian encode

State: `[8]u32` (a,b,c,d,e,f,g,h), Buffer: `[64]u8`, Count: `u64`

Constants: 64-entry `K` table, 8-entry IV.

## Trust Anchors

For HTTPS, need root CA certificates. Options:
1. Embed Mozilla's root CA bundle (~200KB)
2. Read from system trust store (macOS: Security.framework, Linux: /etc/ssl/certs/)
3. Minimal: embed only CAs for Conan Center (~2KB)

Recommended: Option 3 initially, option 2 for general use.

## What NOT to Port

- TLS server mode
- TLS 1.3 (TLS 1.2 sufficient for Conan Center)
- Session resumption, client certificates
- 3DES, DES, RC4
- Assembly optimizations (AES-NI, NEON)
- T0 compiler itself
