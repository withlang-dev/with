# Audit: lib/std/builtins.w @ 450733e5

Scope: read-only source audit of `lib/std/builtins.w` (124 lines) at commit 450733e5.
Targets traced: T13 (ownership/drop), T15 (migration fidelity), T22 (spec conformance).
Compiler: out/bootstrap/bin/with-stage1 (seed compiler).

## Module summary
Ambient user-facing prelude names: `c_void` opaque type; extern print/write/panic/fmt
shims (`with_*`, lines 11-25); thin wrappers `print`, `eprint`, `write`, `ewrite`,
`print_i32/i64/bool` (28-53); `assert`/`require`/`check` with `src()` default loc
(56-68); generic `assert_eq`/`assert_ne` with `{:?}` formatting (72-79);
`assert_matches_failed` (83-84); `panic`/`todo`/`unreachable` returning `Never`
(87-96); no-op generic `drop[T]` (99-100); `ToString` trait + impls for
i32/i64/u32/u64/bool (104-120); `int_to_string(i64)` (123-124).
Wired into all preludes via `use std.builtins` (prelude.w:4, prelude_alloc.w:4,
prelude_core.w:3). Sibling `lib/std/testing.w` re-declares `assert/require/check/
assert_eq/assert_ne/assert_matches_failed` with `with_panic` (by-value `str`) instead
of `with_panic_ref` (by-ref `&str`); separate module, no import conflict unless a
file imports both unqualified.

## Target disposition
- T13 ownership/drop: CONFORMANT (see probes). All wrappers take `&str`/by-value
  scalars and forward to externs; no allocation, no manual memory ops. `drop[T]`
  body `()` is the intended explicit-drop point (landed intent: commit 193743ff
  "Implement prelude drop"); probe_drop runs clean and use-after-drop is a compile
  error by construction. Refutation attempt (claim: `drop` leaks owned strings):
  refuted — drop glue is compiler-owned; no in-repo caller depends on a runtime
  body (grep `drop(` in std hits only trait-dtor definitions, not this free fn).
- T15 migration fidelity: CONFORMANT. `git log --follow` shows incremental landed
  intent (630b47cf src() loc, 193743ff drop, 45dec498 generic assert_eq/ne,
  e5644acf assert_matches desugar, f7a420eb todo/unreachable panic, 706b6cfd Unit,
  7d8d085e &str extern ABI, 2d9759b2 self-less surface). No forked/duplicated logic
  remains: the `testing.w` near-duplicate is a stable-helper alias with a different
  extern signature (`with_panic` by value vs `with_panic_ref`), not a migration
  leftover; `assert_eq` in `lib/test/testing.w` is the legacy `void`-ABI harness,
  untouched by this module. No divergent behavior introduced.
- T22 spec conformance: CONFORMANT (see probes). No encoding/crypto/decode claims
  in this module — independent-oracle rule NOT APPLICABLE (no byte/format vectors
  to check). Observable behavior matches surface contract per probes below.

## Probes (all EXECUTED via `out/bootstrap/bin/with-stage1 run`)
- probe_pass (docs/audit/probes/builtins/probe_pass.w): print/print_i32/print_i64/
  print_bool/assert/require/check/assert_eq/assert_ne/ToString(i32,bool,u32)/
  int_to_string — output `hello-builtins,-42,1234567890123,true,42,true,99,7`,
  exit 0. PASS.
- probe_fail (probe_fail.w): `assert_eq(1,2)` — `panic: assertion failed: 1 != 2`,
  exit 134 (SIGABRT). PASS (negative control: failure path panics, nonzero exit).
- probe_drop (probe_drop.w): `drop(s)` then `print("after-drop")` — `after-drop`,
  exit 0. PASS (explicit drop is a safe no-op point).
- probe_neg (probe_neg.w): `int_to_string(-7)`, `(-2147483648).to_string()`,
  `(false).to_string()` — `-7,-2147483648,false`, exit 0. PASS (i32::MIN edge).
- probe_panic (probe_panic.w): `write/ewrite/eprint` emit `w1e1e2` without
  newlines, `todo("not-here")` — `panic at probe_panic.w:11:5: not-here`, exit 134.
  PASS (Never-returning panic + loc threading via `src()` default).

## Findings
None — no defects survived refutation. No numbered findings.
(1) Checked: duplicate `assert*` definitions in `std.testing` — NOT a defect:
separate module, distinct extern (`with_panic` vs `with_panic_ref`), no ambiguous-
import in-repo caller; both typecheck. (2) Checked: `with_panic` (by-value) vs
`with_panic_ref` (by-ref) split in assert_eq vs assert — NOT a defect: matches
landed `&str`-ABI migration (7d8d085e); probes show identical panic output/exit.

## Coverage check
Claimed test-file coverage verified by existence: tests/test_spec.w,
tests/test_operators.w (drop/overloading), tests/test_ml_features.w (drop LIFO),
tests/test_types.w + tests/test_cimport.w (local int_to_string shims, not this fn)
all exist. Generic prelude `assert_eq` exercised across the suite via prelude.

Verdict: COMPLETE
