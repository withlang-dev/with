# Wave 1 Redirect — Replace Root Modules (No Adapters)

## Decision

- Do **not** write root-module adapters/facades.
- Do **not** maintain two parallel implementations.
- Replace root modules directly with Wave 1 foundation implementations.
- Update all callers to the new API shapes as part of each migration step.

## Scope

Root modules to replace:

1. `src/Span.w`
2. `src/Source.w`
3. `src/InternPool.w`
4. `src/Diagnostic.w`

Foundation sources of truth:

- `src/compiler/foundation/Span.w`
- `src/compiler/foundation/Source.w`
- `src/compiler/foundation/InternPool.w`
- `src/compiler/foundation/Diagnostic.w`
- `src/compiler/foundation/DiagnosticRender.w`

---

## Preflight

- [x] Record a clean baseline test run before migration.
- [x] Confirm the “full suite” command set used for this effort:
  - `./scripts/run_wave1_unit_tests.sh`
  - `./bootstrap/zig-out/bin/with test test/cases/`
  - `./bootstrap/zig-out/bin/with test bootstrap/test/cases/`
  - `./scripts/rebuild_selfhost.sh stage2`
- [x] Save baseline logs/artifacts for comparison.
  Note: both `with test .../cases/` commands currently return `error: no tests matched filter` in this tree; practical gating used was `run_wave1_unit_tests.sh`, `rebuild_selfhost.sh stage2`, and `with-stage1 check src/main.w`.

---

## Commit Plan (One Module Per Commit)

## Commit 1 — Replace `Span`

- [x] Replace `src/Span.w` with foundation-aligned implementation.
- [x] Update all callsites that depend on old `Span` API/behavior.
- [x] Handle any bootstrap codegen edge-case patterns encountered (targeted fixes only).
- [x] Run full suite.
- [ ] Commit with message:
  - `wave1: replace root Span with foundation implementation`

## Commit 2 — Replace `Source`

- [x] Replace `src/Source.w` with foundation-aligned implementation.
- [x] Update callsites for field/API shape changes (`name/path`, location helpers, etc.).
- [x] Keep behavior deterministic for diagnostics/path reporting.
- [x] Run full suite.
- [ ] Commit with message:
  - `wave1: replace root Source with foundation implementation`

## Commit 3 — Replace `InternPool`

- [x] Replace `src/InternPool.w` with foundation-aligned implementation.
- [x] Update parser/sema/codegen/front-end callsites to new interning API.
- [x] Ensure symbol behavior remains stable where string-only callers exist.
- [x] Run full suite.
- [ ] Commit with message:
  - `wave1: replace root InternPool with foundation implementation`

## Commit 4 — Replace `Diagnostic`

- [x] Replace `src/Diagnostic.w` with foundation model + rendering integration.
- [x] Integrate `DiagnosticRender` where old in-module render paths were used.
- [x] Update callsites across parser/sema/driver/frontend for new diagnostic APIs.
- [x] Run full suite.
- [ ] Commit with message:
  - `wave1: replace root Diagnostic with foundation implementation`

---

## Cross-Cutting Checks (Run During Each Commit)

- [x] No adapter layer introduced.
- [x] No duplicate root/foundation logic added.
- [x] Any breakage is fixed in migrated codepaths (not worked around by fallback to legacy modules).
- [x] Wave 1 unit tests stay green.
- [x] Stage2 rebuild stays green.

---

## Finalization

- [x] Verify there is only one implementation per concern (foundation-backed root modules).
- [x] Remove any temporary migration scaffolding if introduced.
  Removed `lib/compiler -> ../src/compiler` symlink by adding `src/` fallback import resolution in bootstrap `Driver.resolveModulePath`.
- [x] Update Wave 1 docs/checklists to mark root-module replacement complete.
- [ ] Squash/fix commit messages if needed only by explicit request (default: keep 4 commits).
- [ ] Push branch and capture final validation summary.

---

## Exit Criteria

- [x] All four root modules are replaced by foundation implementations.
- [x] Full suite passes after each of the four commits.
- [x] No adapters/facades remain.
- [x] No parallel duplicate implementations remain in active use.
