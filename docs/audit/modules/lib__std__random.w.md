# Primary verification — `lib/std/random.w`

Status: **COMPLETE** (1 Low finding, filed)
Primary verifier: primary (full source read + probe execution)
Source revision: `450733e5`
Source examined: all 59 lines (single complete read)

## Scope examined

Seeded xorshift64 PRNG: `ensure_seeded` (runtime entropy → clock →
1 fallback chain), `xorshift64` (13/7/17 shifts on i64 state),
pub `seed`/`seed_now`/`next_i32`/`range_i32`/`chance`. No in-repo
callers. No test files.

## Behavioral matrix (all EXECUTED)

- `docs/audit/probes/random/main.w`: `seed(42)` then 5× `next_i32()`
  == independent signed-semantics python xorshift oracle exactly
  (5/5; first attempt with a logical-shift oracle matched 4/5,
  corrected — module uses arithmetic `>>` on i64 state, a
  self-consistent PRNG variant).
- Edges: `range_i32(5,5)==5`, `range_i32(10,5)==10`,
  `chance(0)==false`, `chance(100)==true`; 100× `range_i32(0,10)`
  all in range. All PASS.

## Findings

1. LOW — `range_i32` (`:48`) / `chance` (`:55`) compute
   `0 - v` with checked subtraction; a draw of exactly INT32_MIN
   (2^-32 per call; distribution covers it) aborts with
   `panic: integer overflow: i32 subtraction out of range`
   (confirmed by direct probe). Filed #1058.

Verdict: COMPLETE
