# Audit: src/compiler/foundation/InternPool.w @ 450733e5

Scope: read-only source audit of foundation InternPool (168 lines).
Reference twin: src/InternPool.w (188 lines). Commit verified: 450733e5.
Seed probe binary: out/bootstrap/bin/with-stage1 (exists, 114690576 bytes, Sep 3).

Targets: T13 ownership/drop, T15 migration fidelity, T22 spec conformance.

## Verdict: INCOMPLETE

## Findings

1. src/compiler/foundation/InternPool.w:98-105 — T15 fidelity divergence, severity LOW, probe PASS.
   Reintroduces linear-scan fallback with `foundation_intern_text_eq` on every
   `symbol_map` miss, plus map repair via `existing_text.clone()`. The twin
   (src/InternPool.w:124-126) explicitly documents this fallback as removed
   ("No linear-scan fallback — it never matched over a full compile").
   Refutation attempt: ran test/internals/intern_pool_stress_test.w (6000 unique
   + duplicate storm x4 rounds, cross-pool determinism asserts) via with-stage1:
   `ok`, exit 0. Behavior-equivalent when the map is content-consistent; cost is
   O(n) per cold insert only. Not a correctness defect on current evidence, but a
   deliberate twin divergence that re-adds a path the root module deleted, and
   contradicts the "no duplicate logic" migration check. Retain only with a
   comment justifying why the foundation needs a backstop the root dropped.

2. src/compiler/foundation/InternPool.w:1-168 (whole module) — T15 missing legacy
   entrypoints, severity MEDIUM, probe PASS (current tree) / BLOCKS documented goal.
   Foundation lacks `InternPool.new`, `deinit`, `intern`, `resolve`, all present on
   the twin (src/InternPool.w:111-112,115-116,184-188). In-repo callers use the
   short names pervasively (`self.intern.intern(...)`, `self.intern.resolve(...)`
   across Parser/Codegen/MirLower/ComptimeTransform/Frontend/render/Lsp; e.g.
   src/Codegen.w:560-650, src/render.w:27). All such callers today resolve
   `use InternPool` to the ROOT module; only Mod.w + 2 internals tests import the
   foundation copy. Refutation attempt: `with-stage1 run` of both internals tests
   passes, so nothing in-tree is broken today — but docs/completed/
   with-selfhost-wave1-replace-root-modules.md Commit 3 ("Replace src/InternPool.w
   with foundation-aligned implementation", "Update parser/sema/codegen/front-end
   callsites to new interning API") cannot land without either adding the shims or
   renaming hundreds of callsites. Either the plan is stale or the migration is
   pending; INCOMPLETE until reconciled.

3. Parallel implementations vs "one implementation per concern" — T15, severity
   MEDIUM, probe N/A (structural).
   The same plan doc's exit criteria require "only one implementation per concern"
   and "no parallel duplicate implementations remain in active use", with root
   modules as "thin forwarding layers" (docs/completed/with-selfhost-wave1.md:112).
   At 450733e5 both src/InternPool.w and src/compiler/foundation/InternPool.w are
   full independent implementations (separate arenas, separate map helpers,
   divergent intern_str bodies) and the root is NOT a forwarder. Refutation
   attempt considered: header comment in foundation ("same fix as src/InternPool.w")
   acknowledges the twin. No evidence of forwarding. Migration fidelity cannot be
   claimed complete while the "replace root" commit it cites has not taken effect.

4. T13 ownership/drop — NO DEFECT, probe PASS.
   `InternPool.init` (foundation :76-90) mirrors twin (:92-109): `with_alloc(256)`
   for a 7-field state, `Copy` handle sharing state, arena pages never freed so
   interned pointers are stable. Twin's `deinit` is an explicit no-op; foundation
   omits it, which is equivalent (nothing to free by design; worker-exit reclaims).
   Consistent with docs/memory-model.md program-lifetime-pool status quo and the
   handle-type precedent (docs/completed/handle-type-conversion-plan.md). No
   double-free, no use-after-free, no undersized-alloc evidence; alloc size matches
   the MirSuspendCheck.w:51 / CodegenDispatch.w:627 "256 for a 7-field state" note.

5. T22 spec conformance — NO DEFECT on observed behavior, probes PASS.
   Content-stable identity holds: intern_pool_test.w (`ok`, exit 0) covers
   symbol/type/value dedup, Wave 5 forms (ref/fn/trait-object/generic/tuplen),
   counts; stress test covers 6000-entry growth + cross-pool determinism; negative
   control (/tmp/intern_neg.w: invalid/0/huge symbol resolves to "", empty-string
   interning stable, invalid type resolve) prints `neg-ok`, exit 0. Matches
   phase-d-design softened requirement (public symbol identity content-stable).
   Minor: `resolve_symbol` validity path differs in form
   (`symbol_is_valid` + `raw <= 0` vs twin `sym <= 0`) but is exactly equivalent
   for all i32 inputs (Ids.w:48 `id >= 0`); `type_id_from_raw` is `raw as TypeId`,
   identical to twin casts. `intern_debug_init` observability hook dropped —
   cosmetic only, no caller depends on it.

## Probes run

- `out/bootstrap/bin/with-stage1 run test/internals/intern_pool_test.w` → `ok`, exit 0.
- `out/bootstrap/bin/with-stage1 run test/internals/intern_pool_stress_test.w` → `ok`, exit 0.
- Negative control /tmp/intern_neg.w (invalid/0/99999 symbol, "" stability, invalid
  type) → `neg-ok`, exit 0.
- Caller searches (REGEX mode): `InternPool|intern_str|...` over src/ (hundreds of
  root-pool users; foundation imported only by Mod.w + 2 tests);
  `\.intern\(|\.resolve\(|InternPool\.new|pool\.deinit` confirms short-name API is
  load-bearing on the root module; `FndInternStringArena|foundation_new_map|
  foundation_intern_text_eq` confined to foundation module.

## Negative controls

- Invalid/empty inputs resolve safely (see probe 3); no panic path observed.
- Twin-comparison refutation applied to every candidate defect; items 4–5 were
  refuted to NO DEFECT, items 1–3 survived.

No issues filed (per instructions).

## Close-out (primary, 2026-09-04)

- F2/F3 REFUTED as defects. `git show de5a0af8` ("wave1: replace root modules
  and integrate foundation diagnostics"): the landed design explicitly keeps
  the root as a full implementation — "Root `InternPool` now follows the
  foundation layout while preserving historical string-only entrypoints used
  across existing compiler code." Renaming hundreds of callsites was
  deliberately rejected at landing time. The parallel implementations are
  maintainer-chosen convergent evolution, not an unfinished migration.
- Surviving observation (not filed): the archived plan doc
  `docs/completed/with-selfhost-wave1-replace-root-modules.md` still carries
  checked exit criteria ("only one implementation per concern", "no parallel
  duplicate implementations") that contradict the landed design. Stale plan
  text; no product impact, no caller affected.
- F1 (linear-scan fallback) HELD as a hygiene note only: behavior-equivalent
  per stress probes, perf-only on cold insert, zero live callers. Not a defect.

Verdict: COMPLETE (0 defects; F2/F3 refuted by landed-commit intent, F1 held as note)
