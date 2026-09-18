# Audit: src/Migrate.w @ 450733e5

Commit: 450733e5 | Module: src/Migrate.w (21 lines) | Date: 2026-09-04
Scope: full module source + T13 ownership/drop, T15 migration fidelity, T22 spec conformance.
Seed compiler: out/bootstrap/bin/with-stage1 (check/run).

## Source summary
Stub translator `rust/zig/swift -> With`: `MigrateLang`/`MigrateMode` enums plus
`fn run(lang: &str, path: &str, mode: i32) -> i32` that prints
"migrate: not yet implemented in self-hosted compiler" via `with_eprint` and returns 1.

## Targets traced
- T13 ownership/drop: `run` takes two `&str` borrows, creates no owned values,
  drops nothing. Extern `with_eprint(&str)` borrow-only. No alloc/drop paths exist.
  No finding.
- T15 migration fidelity: header claims "Direct port of bootstrap/src/Migrate.zig",
  but no `bootstrap/` tree exists in this workspace and no `*Migrate*` counterpart
  file exists outside `src/Migrate.w`, `src/CiMigrate.w` (unrelated C-importer),
  `src/ReceiverMigration.w`, and docs specs. No reference implementation to diff
  against; stub makes no fidelity claim beyond the header comment. No finding
  (observation only, see O1).
- T22 spec conformance: specs exist (`docs/with-migrate-*-spec.md`,
  `docs/with-migrate-spec.md`) but the stub claims no conformance — it honestly
  reports unimplemented and returns nonzero (1), so no false-success path.
  No in-repo callers (`use Migrate` / `MigrateLang` / `MigrateMode` referenced
  nowhere outside src/Migrate.w itself). Dead code, zero behavioral surface.
  No finding.

## Probes run
- P1 (EXECUTED): seed compiler sanity `with-stage1 check` on trivial
  `fn main() -> i32: 0` → `ok`, exit 0. Toolchain functional.
- P2 (HELD): direct `check`/`run` of src/Migrate.w not attempted — module has no
  `main` and `run` requires driver wiring plus `with_eprint` host binding;
  executing it standalone would test harness, not module. Reason recorded.
- Negative control (EXECUTED): `grep -rn "use Migrate|MigrateLang|MigrateMode"
  src/` returns only src/Migrate.w self-hits; `find -iname "*migrat*"` shows no
  bootstrap counterpart; `grep migrate src/Main.w src/Cli.w` — files do not exist
  (no CLI wires this module). Confirms zero-caller / no-counterpart claims above.

## Refutation attempts
- Candidate "stub returns error unconditionally = defect": refuted — documented
  stub behavior, nonzero exit is the correct contract for unimplemented, and no
  caller depends on success.
- Candidate "stale bootstrap/src/Migrate.zig reference = defect": refuted as a
  finding — comment-only, no behavioral effect; recorded as observation O1.

## Observations (non-findings)
- O1: header comment references `bootstrap/src/Migrate.zig`, which does not exist
  in this workspace (no `bootstrap/` dir). Stale path after repo restructure.
  Comment-only; no severity, no fix demanded.

## Verdict
COMPLETE (no findings)
