# Audit: src/compiler/foundation/Ids.w @ 450733e5

- Commit: 450733e5 (workspace HEAD matches; `git show HEAD:...Ids.w` identical to worktree)
- Module size: 49 lines, 8 `pub type` i32 aliases + 32 helper fns (invalid/from_raw/raw/is_valid x8)
- Scope: T13 ownership/drop, T15 migration fidelity, T22 spec conformance

## Probes run (seed: out/bootstrap/bin/with-stage1, verified present via ls)

1. `with-stage1 run test/internals/ids_test.w` -> `ok` (PASS, in-repo spec test)
2. `/tmp/ids_probe.w` (custom edge probe: all 8 sentinels == -1 raw and invalid;
   0 valid / -5 invalid boundaries incl. TypeId; i32::MAX round-trips for
   FileId/TypeId; symbol 0 valid) -> `probe-ok` (PASS)
3. `/tmp/ids_neg.w` (NEGATIVE CONTROL: `assert(file_id_is_valid(file_id_invalid()))`)
   -> `panic at /tmp/ids_neg.w:4:5: assertion failed` (fails as expected;
   note: stage1 exit code stays 0 on panic, so verdicts rely on output text)

## Findings

None. No numbered defects — every candidate below was refuted vs in-repo callers.

- T13 (ownership/drop): module holds only `i32` values; no owned resources
  (no str/Vec/pointer), no `mut self`, nothing to drop. Callers in
  src/compiler/foundation/Arena.w:42,51,62,68,73,78,
  SourceMap.w:32,43,48,50,58, InternPool.w:96,104,111,126,131,136,156,
  Types.w:56,65,74,83,92,93,101,110,111,116,119,122,137,164,165,
  Values.w:57, Span.w:23 pass IDs by value through matching-domain helpers only.
- T15 (migration fidelity): file created new in de5a0af8 (wave1), not a port of a
  legacy module (no legacy src/Ids.w exists). Later f1fbd145 added the three
  TypeId `as` casts (`(-1) as TypeId`, `raw as TypeId`, `id as i32`) to match the
  legacy `distinct i32` flip, although the foundation alias stayed plain
  `pub type TypeId = i32`. Refuted as defect: the casts are identity no-ops on
  plain i32 — probe 2 confirms `type_id_from_raw`/`type_id_raw` round-trip
  exactly (incl. -5 and i32::MAX) and `type_id_invalid` is -1/invalid.
- T22 (spec conformance): docs/completed/with-selfhost-wave1.md:67,148-149 want
  distinct handle types with explicit isolated raw conversions. The module
  documents its bootstrap-stage deviation in its own header (Ids.w:3-4:
  "explicit ID domains even when the runtime representation is i32"), and the
  second rule IS met: every in-repo caller converts via the explicit
  from_raw/raw helpers; a repo-wide regex sweep for cross-domain constructor
  misuse (`<Domain> = <other_domain>_(from_raw|invalid)`) returns zero matches.
  The language supports `distinct i32` (src/Ast.w:31, src/CiIR.w:52,
  src/Mir.w:11), so plain aliases are a conscious trade-off, not a latent bug.
  Helpers cover the used surface (invalid/from_raw/raw/is_valid); equality/order
  fall out of the i32 representation and ids_test.w locks the contract.

## Verdict

COMPLETE
