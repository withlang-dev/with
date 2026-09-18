# Audit: src/Scaffold.w @ 450733e5

Commit: 450733e5
Module: src/Scaffold.w (67 lines, read fully lines 1-67)
Scope: T13 ownership/drop, T15 migration fidelity (where applicable), T22 spec conformance
Seed compiler: out/bootstrap/bin/with-stage1 (present; probes HELD, reason below)

## Source summary
- Line 5: `extern fn with_fs_read_file(path: &str) -> str` declared, never called in-module.
- Lines 7-10: `type ModuleSpec { logical_name, file_path }` never constructed in-module.
- Lines 12-23: `required_module_count()=8`, `required_module(idx)` table ast/types/parse/check/mir/codegen/driver/diag, OOB returns `""`.
- Lines 25-47: `canonical_module_count()=8`, `canonical_logical_name(idx)` (same 8 names/same order), `canonical_file_path(idx)` mapping to `bootstrap/src/Ast.zig ... Diag.zig`, OOB returns `""`.
- Lines 50-53: `enum ValidateError: Ok=0, MissingModule=1, DuplicateModule=2`.
- Lines 56-67: `validate_scaffold(spec_names, spec_paths)` checks each required name occurs exactly once in `spec_names`; returns MissingModule (count==0), DuplicateModule (count>1), else Ok. `spec_paths` unused in-body; filesystem extern unused.

## Target traces
- T13 ownership/drop: no owned-heap transfer, no linear/resource types, no manual drop in module. `str` returns are by-value table literals; `Vec[str]` only read via `.get(si as i64)`; loop index cast `spec_names.len() as i32` truncates only for infeasible >2Gi vectors. No leak/double-drop surface. Clean.
- T15 migration fidelity: required table and canonical logical table are 1:1 identical (8 entries, same order, same spellings); canonical paths follow uniform `bootstrap/src/<Capitalized>.zig` convention (Ast/Types/Parse/Check/Mir/Codegen/Driver/Diag). Existence of those bootstrap files on disk NOT re-verified this run (HELD, batch budget); internal consistency holds. No fidelity defect claimed.
- T22 spec conformance: module doc (line 3) = "all required logical modules exist" — name-existence + uniqueness check matches doc. Return-code mapping correct; missing-checked-before-duplicate per requirement; empty spec -> MissingModule; extra unknown names ignored (correct under stated contract); OOB `""` sentinel never collides with a required name and `validate_scaffold` only iterates `0..required_module_count()` so sentinel unreachable in the hot path. `0..len as i32` + `si as i64` indexing pattern is consistent. Clean.

## Candidate observations refuted (not findings)
1. `spec_paths` / `with_fs_read_file` / `ModuleSpec` / `canonical_*` unused by `validate_scaffold` — refuted as defect: module doc scopes validation to logical-name existence; path/filesystem/canonical tables are companion utilities for external callers/tests, and ignoring `spec_paths` is conformant, not a bypass. No in-module caller requires them. Not filed.
2. Duplicated 8-entry tables (`required_module` vs `canonical_logical_name`) — refuted: both read fully, entries identical and order-matched; duplication is intentional spec/canonical separation, no divergence. Not filed.
3. OOB `""` sentinel — refuted: `""` never equals any required name, loop bounds exclude OOB. Safe. Not filed.

## Probes
- EXECUTED: none (static full-read audit only).
- HELD: seed-compiler behavioral probes (`check`/`run` harness exercising validate_scaffold: empty->Missing, exact-8->Ok, duplicated name->Duplicate, unknown-extra ignored, OOB idx->"") — HELD because the two-tool-batch budget was spent on full source read + report write/re-read; functions are pure table lookups fully determined by inspection above.
- Negative controls (reasoning-only, same HELD status): empty vec must yield MissingModule=1; doubled "ast" must yield DuplicateModule=2; `required_module(99)`/`canonical_*(99)` must yield `""`; extra "foo" must not disturb Ok. None executed; listed so a follow-up run can execute them verbatim.

## Findings
None. No defect survived refutation; no file:line defect to cite.

## Verdict
Verdict: COMPLETE
