# Primary verification — `lib/std/fmt.w`

Status: **COMPLETE** (no defects)
Primary verifier: primary (full source read + probe execution)
Source revision: `450733e5`
Source examined: all 25 lines (single complete read)

## Scope examined

Four thin pub wrappers over runtime externs: `fmt_int` (`:12`,
`with_fmt_i32`), `fmt_int64` (`:16`, `with_fmt_i64`), `fmt_float`
(`:20`, `with_fmt_f64`), `fmt_bool` (`:24`, `with_fmt_bool`).
All four extern targets verified present in `rt/rt_core.w`
(`with_fmt_i32` `:1607`, `with_fmt_i64` `:1612`,
`with_fmt_bool` `:1627`, `with_fmt_f64` `:1652`).
No c_import. Callers: none in-repo (no `use std.fmt` outside the
probe; `src/CCodegen.w` and `src/CodegenDispatch.w` call the
`with_fmt_*` runtime fns directly, not via these wrappers).
Not re-exported by any prelude. No fmt test files.

## Behavioral matrix (all EXECUTED, oracles independent)

- `docs/audit/probes/fmt/basic.w` (`with-stage1 run`, exit 0): 10/10
  self-checking pins PASS against literals fixed before the run
  from `python3 str()` — `fmt_int(0)=="0"`,
  `fmt_int(-42)=="-42"`, `fmt_int(2147483647)`,
  `fmt_int(-2147483648)`, `fmt_int64(9223372036854775807)`,
  `fmt_int64(-9223372036854775808)` (via
  `(-9223372036854775807) - 1`; bare literal is rejected by the
  compiler). Bool pins check documented values
  (`fmt_bool(true)=="true"`, `fmt_bool(false)=="false"` —
  python `str(True)=="True"` is NOT the oracle here; the doc
  comment `:23` plus `rt_core.w:1627` is). Float pins
  `fmt_float(1.5)=="1.5"`, `fmt_float(-0.5)=="-0.5"` match
  python `str()`. PASS.
- Observation pins (no exact oracle claimed, recorded verbatim):
  `fmt_float(0.0) = 0`, `fmt_float(3.14159) = 3.14159`
  (shortest-round-trip style, consistent with `rt_f64_to_buf`).
- Probe compiled clean under stage1 (implicit `with check`
  via `run`).

## Findings

None. In-report notes (not filed):

- `fmt_int64` covers the full i64 range, but the i64-min value is
  not spellable as a literal (compiler rejects the bare
  `9223372036854775808`); reached it via arithmetic. Library
  behavior correct; literal-spelling limit is pre-existing
  compiler surface, out of scope for this module.
- Module is currently uncalled by any shipped code; the live
  formatting path is `with_fmt_int_spec`/`with_fmt_f64_spec`
  (`rt_core.w:1793/1866`) reached from f-strings via codegen.

Verdict: COMPLETE
