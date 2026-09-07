# Primary verification — `lib/std/internal/str_abi.w`

Status: **INCOMPLETE** (compiles; behavior unexecuted)
Primary verifier: primary (full source read)
Source revision: `450733e5`
Source examined: all 26 lines (single complete read)

## Scope examined

Two bridge helpers: `str_copy_bytes(s: &str) -> *mut u8` (`:10`,
`with_alloc(len+1)`, copies payload bytes + NUL), `str_free_bytes`
(`:20`, `with_free`). Callers: `hmac_sha256_str` (`hmac.w:68-74`),
`sha256_hash_str`/`_pair` (`sha256.w:149-168`). No test files.

## Behavioral matrix

- Read in full: copy loop `while i < s.len()` writes
  `out[0..len]` + NUL at `out[len]` into a `len+1` alloc — bounds
  exact; `**(&s as *const *const *const u8)` payload projection
  matches the documented str aggregate layout in the header comment.
- Compiled (not merely read): vendored into
  `docs/audit/probes/hmac/vectors.w`, which builds clean — both symbols
  resolve and typecheck at 450733e5.
- Behavior HELD: no probe calls either function (hmac vectors
  exercise the bytes entry points; the `_str` wrappers that call
  these were not executed). An `_str` round-trip probe would close
  this.

## Findings

None (no defect observed; coverage gap only, recorded above).

Verdict: INCOMPLETE
