# Audit: build/release_uat_fixtures/raylib_spiral_main.w @ 450733e5 — COMPLETE

Module: `build/release_uat_fixtures/raylib_spiral_main.w` (70 lines) — release-UAT
probe program for the `release-raylib-spiral-uat` build gate. Draws an animated
HSV spiral via raylib for 10 frames, screenshots it, and asserts bright-spiral
pixel coverage (`samples >= 4000`, `colored >= 120`). Exits 0 on pass, 1 on
either failure. No `mod` declaration (fixture main, like all 6 siblings).
Single caller: `build/release_uat.w:394` (`run_release_raylib_spiral_uat_action`
reads the fixture, writes it to `out/release-uat/raylib-spiral-project/src/main.w`,
then gates on `check` → `ok`, `run` → rc 0 + stdout contains
`"raylib spiral UAT passed:"`). Build wiring: `build.w:2730-2738` declares the
`release-raylib-spiral-uat` target with this fixture as an `.input`, so editing
the probe re-runs the gate; `release-uat` group deps it (`build.w:2758`).
No other callers. File at HEAD is byte-identical to commit `450733e5`
(`git diff 450733e5 -- <file>` empty).

## Targets traced
- T13 ownership/drop: no `move`, borrow, or clone idiom in the fixture — all
  locals are Copy scalars (`f64`/`i32`/`bool`); `Color` struct is passed by value
  to `is_spiral_sample(c: Color)` (line 17) and constructed inline (line 27).
  Resource cleanup precedes both early returns: `UnloadImage` (line 59) and
  `CloseWindow` (line 60) run before the `return 1` failure paths (lines 64,
  67). No live-value drop, no leak on failure. Clean.
- T15 migration fidelity: fixture was extracted byte-identical from the old
  escaped-string builder in `7b39ff0f` (commit message claims byte-identical).
  Spot-verified against the pre-extraction builder `7b39ff0f^:build/release_uat.w`:
  `ColorFromHSV(hue, 0.86 as f32, 1.0 as f32)` (old line 553), `DrawCircle(...)`
  (old line 554), `fn is_spiral_sample` (old line 555),
  `is_spiral_sample(GetImageColor(image, x, y))` (old line 587),
  `raylib spiral UAT passed:` assertion string (old lines 599/632) all present
  with matching content. No drift since extraction (`git log --follow` shows a
  single commit; `git diff 450733e5` empty). Clean.
- T22 spec conformance: `use c_import("raylib.h")` + `extern fn sin/cos`
  (lines 1-4) is the sibling-fixture C-interop idiom (`zlib_main.w:1` identical
  shape); nullary `fn main:` with trailing `0` / `return 1` exit codes matches
  the harness contract (`ruat_expect_success` + stdout-contains assertion,
  `build/release_uat.w:404-410`). Threshold logic (`samples < 4000`,
  `colored < 120`) is deterministic for fixed `t = 1.25`, 10 frames. Clean.

## Probes run (seed out/bootstrap/bin/with-stage1)
- P1 `tokens <fixture>` → rc=0, first tokens `use c_import ( "raylib.h" )` correct. PASS
- P2 `ast <fixture>` → rc=0, full AST prints: all 3 fns (`draw_spiral`,
  `is_spiral_sample`, `main`), loop/nesting structure intact. PASS (parse conformance)
- P3 `check <fixture>` → rc=1, sole error `failed to compile C header snippet:
  raylib.h: 'raylib.h' file not found` (5-line log). Expected: fixture requires
  the `c.raylib` package (`with get c.raylib`, `build/release_uat.w:390`) that
  only exists in the UAT sandbox, not the audit checkout. No semantic errors
  reported. PASS by environmental-failure-only (no spec defect).
- P4 `fmt <fixture> | diff - <fixture>` → differs only in canonical spacing
  (`c_import (` vs `c_import(`, `0 .. 180` vs `0..180`, `{r:` vs `{ r:`, blank
  lines). Sibling `zlib_main.w:1` uses the same non-canonical
  `use c_import("zlib.h")` style, and the gate enforces `check`+`run`, never
  `fmt`. See finding 1. PASS with noted style delta.

## Negative controls
- N1 no test files under `tests/ test/ tools/ scripts/` reference the fixture
  (`grep spiral` empty) — coverage is the `release-raylib-spiral-uat` build gate
  itself; no broader coverage claimed. All 6 fixture files exist in tree.
- N2 `check` failure (P3) refuted as defect: failure is at C-header snippet
  compilation, before/without any With semantic error; the UAT provides the
  header via `with get c.raylib`. Same expected-failure shape as any c_import
  fixture checked outside its package sandbox.
- N3 `fmt` delta (P4) refuted as defect: repo-wide fixture style, gate does not
  enforce `fmt --check`.

## Findings
1. build/release_uat_fixtures/raylib_spiral_main.w:1,7,27 — severity info, T22 —
   fixture style differs from `fmt` canonical output (spacing/blank lines).
   Probe status: P4 executed, diff recorded. Refutation attempt: sibling
   fixtures share the style and the gate never runs `fmt`; cosmetic only, not
   a conformance defect. Observation only, no action.

Verdict: COMPLETE (0 defects, 1 info-level style observation, no blocking issues).
