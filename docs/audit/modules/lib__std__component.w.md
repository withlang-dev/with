# Audit: lib/std/component.w @ 450733e5

- Commit: 450733e5
- Module: lib/std/component.w (6 lines — full content read)
- Targets traced: T13 ownership/drop, T15 migration fidelity, T22 spec conformance
- Module content: comment header + doc comment + `pub trait ComponentId:` with
  single method `fn component_id() -> i64` (lib/std/component.w:1-6).
  No state, no functions, no Drop impl — all behavior lives in the compiler
  derive (`src/ComptimeTransform.w:1486-1494` hash, `:2936-2971` derive
  expansion, `:3031`, `:3170-3178` wiring, `:1827-1843` derive allowlist).

## T13 ownership/drop — N/A, no defect
Trait declaration carries no fields, no values, no `Drop`/`deinit`. Nothing to
move, borrow, or leak. No owned-resource surface.

## T15 migration fidelity — clean
- Introduced in 0d9ce98d ("Add ComponentId derive") with legacy trait-body
  syntax `pub trait ComponentId =`; follow-up 129c4d15 ("Remove legacy equals
  trait bodies") migrated it to `pub trait ComponentId:`. Current `:` form
  matches the post-migration grammar and compiles (behavior test that
  `use std.component`s it passes — see probes).
- No semantic change across the migration (trait shape identical before/after).

## T22 spec conformance — conforms
- Spec §17.6 (docs/with-specification.md:10137-10148) describes ECS component
  registration with "Component ID (compile-time hash of type name)". The
  derive implements exactly that: djb2-x33 seeded at 5381, mod 2147483647,
  zero mapped to 1, over the type-name bytes (ComptimeTransform.w:1486-1494).
- Doc comment (component.w:3-4) correctly names the working spelling
  `@[derive(ComponentId)]`, matching all in-repo callers and the allowlist.
  Observation (not a defect): the spec's illustrative `@[component]` mega-
  annotation (storage + ID + query + serialization) has no `component` entry
  in `ct_supported_derive_target` — only `ComponentId` is implemented. That
  gap belongs to the spec/compiler surface, not to this 6-line trait module,
  which promises only the ID half and delivers it.

## Findings
None. No defects survived refutation.

1. (considered, rejected) Spec-spelling mismatch `@[component]` vs
   `@[derive(ComponentId)]` — component.w:3-4 documents the derive spelling
   that the compiler actually implements and every in-repo caller uses;
   refuted as a module defect (spec-side aspiration only). Severity: n/a.
   Target: T22. Probe status: HELD — no probe; sibling-annotation surface is
   compiler-owned, and `check` on the existing negative-control file confirms
   unknown-trait errors surface correctly.
2. (considered, rejected) Hash collisions (djb2 mod 2^31-1 is not injective)
   — no uniqueness claim in module or spec ("stable identity", i.e.
   determinism); refuted vs landed-commit intent (0d9ce98d test asserts only
   fixed values + inequality of two names). Severity: n/a. Target: T22.
   Probe status: EXECUTED — inequality asserted live (see P1).

## Probes run (seed: out/bootstrap/bin/with-stage1 @ 450733e5)
- P1 EXECUTED — test/behavior/behav_derive_component_id.w via `run`: `ok`.
  File exists (verified). Fixed vectors Position=1156229881,
  Velocity=1019112964 independently reproduced with a Python djb2 oracle
  (never self-derived): Position 1156229881, Velocity 1019112964 match.
- P2 EXECUTED — fresh /tmp probe (Alpha/Beta derive, stability a1==a2,
  distinctness a1!=b, vectors Alpha=215243885, Beta=2088959363 per the same
  independent Python oracle): `probe-ok`. First attempt with a hand-guessed
  Alpha vector failed as it should (assertion fired), then passed with
  oracle-computed vectors — oracle discriminates. Cleaned up (/tmp removed).
- N1 EXECUTED (negative) — err_derive_component_id_generic.w via `check`:
  `error: derive ComponentId requires a concrete struct`. File exists.
- N2 EXECUTED (negative) — err_derive_component_id_requires_trait.w via
  `check`: `error: unknown trait`. File exists.
- No decoding/encoding/crypto claims in module — independent-oracle rule
  applied to the hash vectors above instead.

## Verdict
Verdict: COMPLETE — lib/std/component.w conforms on T13/T15/T22; no defects.
