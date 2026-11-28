# D248 — Fixed-size and offset-derived buffer contracts (`buffer param P len|capacity <N>` and `capacity param L +/- <N>`) (delegated)

**Date:** 2026-11-27. **Status:** delegated under D237 (mission-settled; Eric vetoes by revert).

**Laws:** Law 1 (*The compiler never asks for what it already knows*), Law 4 (*A fact is inferred only when being wrong cannot create unsafety*), Law 5 (*Observing is not owning; transport is not duplication*), Law 10 (*The mission is tested, not described*), Law 12 (*The programmer has the last word on what the compiler cannot see*).

---

## Question

Cryptographic and protocol C libraries routinely pass fixed-size byte buffers with no separate length parameter, and output buffers whose required minimum size is an input length plus or minus a fixed tag/header overhead:

- `crypto_secretbox_easy(unsigned char *c, const unsigned char *m, unsigned long long mlen, const unsigned char *n, const unsigned char *k)` (`c.libsodium`, #3142) — `n` is 24 bytes, `k` is 32 bytes, `c` requires at least `mlen + 16` bytes.
- `crypto_secretbox_open_easy(unsigned char *m, const unsigned char *c, unsigned long long clen, const unsigned char *n, const unsigned char *k)` — `m` requires at least `clen - 16` bytes when `clen >= 16`.
- `crypto_box_keypair(unsigned char *pk, unsigned char *sk)` — `pk` and `sk` are each 32 bytes.
- `crypto_box_seal` / `crypto_box_seal_open` — `c` is `mlen + 48`, `m` is `clen - 48`, `pk`/`sk` are 32 bytes.
- `crypto_sign_detached` / `crypto_sign_verify_detached` — `sig` is 64 bytes, `sk` is 64 bytes, `pk` is 32 bytes.
- `crypto_pwhash` — `salt` is 16 bytes.
- `XML_SetHashSalt16Bytes(XML_Parser parser, const uint8_t entropy[16])` (`c.expat`, #3148) — `entropy` is 16 bytes.

Should WCL extend `buffer param` with fixed-size (`len <N>`, `capacity <N>`) and offset-derived capacity (`capacity param <L> + <N>`, `capacity param <L> - <N>`) forms?

## Mission fit

- **Law 1:** *Test: does this make the programmer state something the compiler can establish, or something with no consequence?* Without fixed-size and derived-capacity buffer clauses, nearly every `libsodium` and OpenSSL crypto primitive stays raw and forces application code into `unsafe`.
- **Law 4:** *Test: what happens if this inference is wrong?* Nothing is inferred; the contract cites the header macro/prototype for each size, and the generated bridge runtime-checks slice length before calling C so a short slice panics loudly instead of overflowing memory.
- **Law 5:** *Test: does this operation create an owner the type system does not know about?* No; slices are borrowed for the call.
- **Law 10:** *Test: what program would fail if this rule were quietly lost?* `test/behavior/behav_d248_fixed_and_derived_buffers.with` and `uat/libsodium.uat`.
- **Law 12:** The contract author states the size contract; the compiler honors and runtime-enforces it.

## Decision

Extend `buffer param` (§16.2b.8) with four forms:

- `buffer param P len <N> [elements]`: presents `[]T` (`[]u8` by default), checking `P.len() >= N` before calling C.
- `buffer param P capacity <N> [elements]`: presents `[]mut T`, checking `P.len() >= N` before calling C.
- `buffer param P capacity param L + <N> [elements]`: presents `[]mut T` without claiming `L`, checking `P.len() >= L_len + N` before calling C.
- `buffer param P capacity param L - <N> [elements]`: presents `[]mut T` without claiming `L`, checking `L_len < N or P.len() >= L_len - N` before calling C (allowing C to reject truncated input with its error return while preventing any buffer overrun).
