# Primary verification — `lib/std/crypto/bigint.w`

Status: **Incomplete** (1 High finding + stale in-repo coverage)
Primary verifier: workflow child (full source read + oracle cross-checks + probe execution)
Source revision: `450733e5`
Source SHA-256: `7db6f0d3260139cbb269f4c750edc4dfa31a3b7e456205636e965bd89b14fd88`
Source examined: all 284 lines (single complete read)

## Scope examined

BearSSL i31 port (31-bit limbs): `i31_word_count` (`:10-12`),
`i31_zero` (`:14-20`), `i31_decode` (`:22-69`),
`i31_decode_reduce` (`:71-88`), `i31_reduce_once` (`:90-102`),
`i31_encode` (`:104-127`), `i31_add`/`i31_sub` (`:129-155`),
`i31_ninv31` (`:157-163`), `i31_montmul` (`:165-196`),
`i31_to_monty` (`:198-211`), `i31_from_monty` (`:213-226`),
`i31_modpow` (`:227-261`), `i31_gte` (`:263-274`),
`i31_is_zero` (`:276-284`).

Applicable audit targets examined: 13 (ownership/drop — raw-pointer
exclusivity, no owned/drop types in module), 15 (migration fidelity —
BearSSL port faithfulness, `&raw mut` migration 309ed3c5, fixed-temp
sizing), 22 (spec conformance — arithmetic against independent oracles,
caller-contract agreement).
(Task labels "T13 ownership/drop, T15 migration fidelity" do not match
any docs/ track numbering found in-repo; behavior traced per the task
definitions: T13 = ownership/drop soundness, T15 = migration fidelity,
T22 = spec conformance.)

## Behavioral matrix

Independent oracles (all EXECUTED, python3 `pow`/bit-ops — never
self-derived): `ninv31(7)=1227133513` matches `tests/test_bigint.w:40`
exactly; `x*ninv & 0x7FFFFFFF == 0x7FFFFFFF` holds for 7/13/997;
`0xDEADBEEF & 0x7FFFFFFF = 1588444911`, `>> 31 = 1` match `:57-58`;
`pow(3,7,13)=3`, `pow(100,3,997)=9`, `pow(17,65537,3233)=908 (0x38C)`
match `:92`, `:111-112`, `:131-132`; word-count table
512->17 / 1024->34 / 2048->67 / 2449->79 / 3072->100 / 4096->133
confirms the Finding 1 bound. Every numeric expectation in the stale
in-repo test matches the independent oracle — the VALUES are right,
only executability is lost (Finding 2).

`with check` EXECUTED (seed toolchain at 450733e5), all rc=0:
`lib/std/crypto/bigint.w` itself, and all four in-repo callers
`lib/std/crypto/rsa.w` (`ok`), `lib/std/crypto/ec.w` (`ok`),
`lib/std/crypto/ecdsa.w` (`ok`), `lib/std/crypto/x509.w` (`ok`) —
call-site arity/types agree with this module.

Direct behavioral probes in `docs/audit/probes/bigint/` — all HELD, sole
cause module privacy (every `check` diagnostic is
`symbol 'i31_*' is private to module .../bigint.w`; zero syntax errors
remain after current-syntax `unsafe { }` / `&raw mut` authoring):
`bigint_pure.w` (9 privacy diags), `bigint_codec.w` (4),
`bigint_modpow.w` (15), `bigint_edge.w` (11). All i31 symbols are
non-`pub` (`:10-:276`, no `pub` in file); sibling `std` modules link,
external files cannot. Reason is language-level, not probe error.
Oracle that would have run: python3 values above.

Negative control EXECUTED: `docs/audit/probes/bigint/bigint_oob_control.w`
(`var a: [u32; 80]`, `a[100] = 1`) via `with run` prints
`panic: index out of bounds` — indexed OOB fails closed, so Finding 1's
danger is specifically the RAW-pointer writes (`*(d + j)`), which
bypass that check, with corruption preceding the indexed `d[ci]` panic.

In-repo coverage (files verified to exist; NONE executable at commit):
`tests/test_bigint.w` (exists, 146 lines), `tests/test_rsa.w`,
`tests/test_crypto.w`, `tests/test_ec.w`, `tests/test_ecdsa.w` —
see Finding 2.

## Findings

1. `lib/std/crypto/bigint.w:215,219` — HIGH — T15/T22 — stack buffer
   overflow for moduli above ~2449 bits. `i31_from_monty` uses fixed
   `var one: [u32; 80]` / `var d: [u32; 80]`, but `i31_montmul` writes
   `d[0..mlen]` (`:169-194`) and reads `y[1..mlen]` (`:186`), where
   `mlen = (bitlen+30)/31`. RSA-3072 needs indices `0..100` (101
   words), RSA-4096 needs `0..133` (134 words): 21–54 words past the
   array via unchecked raw-pointer writes, then the indexed copy
   `d[ci]` (`:224`) panics only after corruption. Refutation attempt:
   SURVIVES — `lib/std/crypto/rsa.w:108-109` explicitly admits
   `n_len` up to 512 bytes (4096 bits); `lib/std/crypto/x509.w:359-377`
   forwards arbitrary issuer moduli with no size cap (DER prefix strip
   `:293-298` removes at most 1 byte). P-256 paths (`ec.w`, `ecdsa.w`,
   12-word buffers for 9-word values) and RSA <= 2048 (68 words) are
   unaffected — bound is real but partial. Landed intent (613be156:
   "RSA-1024 test vector", 80-word temp sized for <=2048-bit keys)
   never covered larger keys. Probe status: HELD (module-private
   symbols, see matrix) + EXECUTED arithmetic oracle + EXECUTED OOB
   fail-closed control. Not filed per instructions.
2. `tests/test_bigint.w` (whole file; same staleness in
   `tests/test_rsa.w`, `tests/test_crypto.w`) — MEDIUM — T22 — zero
   executable coverage of this module at 450733e5. `with test
   tests/test_bigint.w` fails: `unsafe:` statement prefix rejected at
   every call site (`:55`, `:60`, `:68`, `:72`, `:85`, `:89`, `:91`,
   `:99-110`, `:119-130`, "requires a newline and indented block"),
   and the same suite uses `-> void` (`tests/test_crypto.w:12`,
   "unknown type 'void'"). Refutation attempt: SURVIVES as a coverage
   gap — values spot-checked against python3 all match (module likely
   correct where sized), but no test in the repo can execute ANY i31
   path at this commit, so Finding 1 has no executable backstop.
   Pre-existing staleness (syntax drift since 613be156), not caused by
   this module. Probe status: EXECUTED (`with test` failures observed
   this session). Not filed per instructions.

## Notes (no finding — analyzed, refuted, not filed)

- `i31_decode` (`:60-65`) inner flush loop has no `word_idx <= n`
  guard: 7+ leading zero bytes on a small value would emit zero words
  past the value (arithmetically confirmed: 8-byte input, 7 leading
  zeros, value `0xFF` emits 3 words for n=1). REFUTED vs in-repo
  callers: `x509.w:293-298` strips at most the 1-byte DER sign prefix,
  `ec.w:21,31` use fixed 32-byte curve constants, `rsa.w:123` takes a
  full-length modulus — none can supply 7 leading zeros; shape matches
  the BearSSL caller-sizes-buffer contract, so no migration defect is
  established (no BearSSL source vendored to claim otherwise).
- `i31_ninv31` even input is unspecified, but all callers pass odd
  moduli (`m[1]` of odd `m`); odd-input property EXECUTED via python3.
- T13: module owns no heap, defines no `Drop`, takes only
  caller-owned `*mut`/`*const` plus stack arrays; `d`/`one` are
  distinct raw borrows, `montmul(t2, t1, t1, ...)` aliases only the
  two read ends — exclusivity holds, nothing to drop or leak.
- T15 mechanical migration 309ed3c5 (`&mut` -> `&raw mut`, 2 sites in
  this file: `:216`, `:220`) is spelling-only; `with check` confirms.

Verdict: INCOMPLETE

## Close-out (primary, 2026-09-04)

Monty probe matrix executed (`out/bootstrap/bin/with-stage1 run`):
s64/s256/s512/s576 PASS; s610/s640/s768/m610/1024/2048/b2449 FAIL;
2480/2450/b2450 `panic: index out of bounds`. Boundary exactly mlen=20
(bitlen >= 590); s610/b2449 `want` vectors oracle-confirmed via python3
`pow`. Root cause of the silent-FAIL band: #1049 (only `one/d[0..19]`
zeroed; `montmul` reads garbage `y[20..mlen]`).
- Filed #1051 ([crypto] from_monty wrong >= 590 bits via #1049).
- Filed #1052 ([crypto] fixed [u32;80] temps overflow > 2449 bits).
- Filed #1053 ([tests] bigint/rsa/crypto suites stale, unexecutable).
