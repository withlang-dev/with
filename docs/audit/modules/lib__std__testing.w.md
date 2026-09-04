# Primary verification — `lib/std/testing.w`

Status: **COMPLETE** (no defects)
Primary verifier: primary (full source read + probe execution)
Source revision: `450733e5`
Source examined: all 26 lines (single complete read)

## Scope examined

`assert` (`:5`, default `msg` + `loc=src()`), `require` (`:9`), `check`
(`:13`), `assert_eq[T: Eq + Debug]` (`:17`), `assert_ne[T: Eq + Debug]`
(`:21`), `assert_matches_failed` (`:25`) — all panic via the module's own
`extern fn with_panic(msg: str, file: str, line: i32) -> Never` (`:3`).
No callers exist anywhere: zero hits for `use std.testing` /
`std.testing.*` outside docs (`docs/requirements.md`,
`docs/with-specification.md` table) and this module itself. The parser's
`assert_matches` desugaring (`src/Parser.w:4674`) and the Sema prelude gate
(`src/Sema.w:1294`) reference the ambient `assert_matches_failed` from
`lib/std/builtins.w:83`, not this module. Sibling duplicates:
`lib/std/builtins.w:56-84` (prelude-ambient, `&str` params,
`with_panic_ref`) and legacy `lib/test/testing.w` (different API,
`exit_code`-based, unrelated).

## Behavioral matrix (all EXECUTED, oracles = source literals + exit codes)

- `docs/audit/probes/testing/pass.w` (whole-module `use std.testing`; all six
  functions on passing inputs): prints `testing-pass-ok`, rc=0. PASS.
- `docs/audit/probes/testing/member_import.w`
  (`use std.testing.assert_eq` / `.assert_ne` / `.assert_matches_failed`;
  passing calls): prints `member-import-ok`, rc=0 — proves `std.testing`'s
  own definitions resolve by explicit member import, not just the prelude
  copies. PASS.
- `docs/audit/probes/testing/fail_assert.w`: `panic at
  docs/audit/probes/testing/fail_assert.w:4:5: probe-assert-msg`, rc=134. PASS.
- `docs/audit/probes/testing/fail_require.w`: `panic at
  .../fail_require.w:4:5: probe-require-msg`, rc=134. PASS.
- `docs/audit/probes/testing/fail_check.w`: `panic at .../fail_check.w:4:5:
  probe-check-msg`, rc=134. PASS.
- `docs/audit/probes/testing/fail_eq.w`: `panic: assertion failed: 1 != 2`,
  rc=134 — byte-exact vs the `:18` f-string. PASS.
- `docs/audit/probes/testing/fail_ne.w`: `panic: assertion failed: 1 == 1`,
  rc=134 — byte-exact vs the `:22` f-string. PASS.
- `docs/audit/probes/testing/fail_matches.w`: `panic: assertion failed: value
  did not match the expected pattern`, rc=134 — byte-exact vs `:26`. PASS.
- `with check lib/std/testing.w` → ok (stage1). PASS.

## Findings

None. In-report notes (not filed):

- `str` vs `&str` duplication: this module's `assert`/`require`/`check`
  take owned `msg: str` and call `with_panic`, while the prelude-ambient
  copies in `builtins.w` take `msg: &str` and call `with_panic_ref`.
  Refutation attempt (is it a defect?): all pass/fail probes behave
  identically to the prelude copies — same messages, same abort (rc=134),
  no duplicate-definition or link error with `use std.testing` in scope —
  so the difference is unobservable at runtime on every executed path; it
  is dead surface (zero callers), not a bug. Revisit if `std.testing` ever
  gains callers that pass borrowed strings.
- Spec table (§18.6.1.35 row, also `docs/with-specification.md:10789`)
  lists `panic, todo, unreachable` under `std.testing`; this module does
  not define them (they resolve via the prelude). Refutation attempt: not
  a behavioral defect — no probe or caller requires them from this module
  path, and whole-module `use std.testing` compiles cleanly. Whether the
  spec row means "in this file" or "reachable alongside it" is a spec
  wording question, out of scope for this audit; no issue filed per
  instructions.
- Callee attribution caveat: whole-module fail probes invoke bare names
  that could resolve to either this module's or the prelude's copy (both
  carry identical message literals, so output cannot distinguish them).
  Attribution to `std.testing`'s own bodies is established by
  `member_import.w` for `assert_eq`/`assert_ne`/`assert_matches_failed`;
  for `assert`/`require`/`check` the two copies are behaviorally identical
  on all executed paths, so the ambiguity has no observable consequence.

Verdict: COMPLETE
