# Audit: src/compiler/BundleInterfaceEmit.w @ 450733e5 (1058 lines)

Scope: full module read (lines 1-1058 via wc+cat/sed), targets T13 / T15 / T22.
Callers traced: `src/compiler/Compilation.w:23` (`use compiler.BundleInterfaceEmit`),
`src/compiler/BundleFingerprint.w:15` (`use`), `src/SemaCheck.w:2454` (comment: declared-effect rule shared).
Consumers: `bundle_interface_build` -> `BundleInterfaceModel{ok: errors.empty}`, `bundle_interface_render` (+ errors vec).

## Verdict: COMPLETE

No surviving defect. Every candidate below was refuted against in-repo callers/semantics.

## Findings

1. `src/compiler/BundleInterfaceEmit.w:emit_impls_of` error gate (`if self.errors.len() > 0 and self.failed: continue`) — SUSPECT skipped-impl masking. Severity: low. Target: T22. Probe status: code-read + caller-contract check (no build needed). Refutation: gate only decides whether to push this impl export; global failure is sticky via `em.errors` -> `bundle_interface_build: ok = em.errors.len() == 0`, so any refused method still fails the run. Partial impl body is never accepted as ok. NOT A DEFECT.
2. `src/compiler/BundleInterfaceEmit.w:fn_text` unsigned/negative const guard in `emit_let` (`spelling.starts_with("u") and value.starts_with("-")` refuse) — SUSPECT over-refusal. Severity: info. Target: T22. Probe status: code-read. Refutation: With int literals fold to i64 (`literal_text` NK_INT_LIT path); a negative value for a `u*` type cannot be re-spelled faithfully, and header contract demands loud refusal over wrong text. Conservative refusal is spec-correct. NOT A DEFECT.
3. `src/compiler/BundleInterfaceEmit.w:bx_module_export_order` (`for kind in 0..7`) range-boundary question (does kind 6 BX_NOTE render?). Severity: info. Target: T22. Probe status: code-read. Refutation: either range convention (0..7 exclusive = 0-6, inclusive = 0-7 with empty kind 7) covers all defined kinds 0-6; BX_NOTE exports are pushed with kind 6 and rendered in module sections like any export. No orphan kind. NOT A DEFECT.
4. T13 ownership/clone discipline — checked `bx_new_emitter`, `push_export`, `note_named_type`, `bx_sorted_strings`, all `with_str_clone_ref` call sites, `move em.exports/errors/warnings/omitted` in `bundle_interface_build`. Every owned `str`/`Vec[str]` crossing a struct boundary is cloned; temporaries (`mod_path`, `name`, `spelling`, `row`) are cloned at push. `bx_sorted_strings` rebuilds with clones and drops the old vec by reassignment. No observed missing-clone, double-move, or unmoved-out alias. Probe status: code-read (no runtime probe; ownership is a compile-time property, stage1 build not required to refute). NOT A DEFECT.
5. T15 migration fidelity — module is new D39 `.wi` emitter (no migrated predecessor; header cites docs/wo_bundles.md + decisions D39, D38 for unlowered globals, abi_roadmap.md for Level 0). No legacy-behavior divergence surface; D38/D39 cross-references in comments match sibling `BundleInterfaces.w`/`BundleFingerprint.w` usage. Probe status: code-read + caller grep. NOT A DEFECT (N/A, no drift).

## Probes run

- `wc -l + full cat (lines 1-~400) + sed -n 400,1058p`: full 1058-line module read. OK.
- `grep -rn BundleInterfaceEmit|BundleInterfaceModel|bundle_interface|bx_ src --include=*.w -l`: caller/consumer set listed above. OK.
- `ls out/bootstrap/bin/`: `with-stage1` present (seed probe feasible path confirmed; full bundle-corpus build not run — read-only audit, failure-free verdict does not depend on it).
- Negative controls: grep for source-text passthrough/placeholder emission — none (all paths go through `spell`/`literal_text` or `refuse`); grep for bare struct-field moves without `with_str_clone_ref`/`move` — none; `emit_impls_of` Copy-skip matches `emit_type` copy_line emission (no double/missing Copy impl).

## Negative controls

- Selector imports, async/gen/comptime, variadic fns, entry/test/panic-handler attrs, c_export/callconv attrs, multi-clause fns, pattern params, default/implicit params, explicit self outside impl, ambiguous view origin, extension methods/blocks, generic decls/impls, assoc-type binding, trait decls, c_import, extern var, ephemeral types, non-Copy derives, drop types, droppable mutable globals, Range/trait-obj/error type kinds — every one has an explicit `refuse` (loud failure) or spec'd `omit_generic_fn`/BX_NOTE path. No silent skip to ok=true.
- Fingerprint rows use Sema's declared-effect rule (`declared_param_effect`/`declared_view_origin`), warnings only on consume-without-consume bodies; raw-ptr params exempted; matches `SemaCheck.w:2454` contract.

## Commit

450733e5 build: the regex runtime shim compiles pcre2 from source under any compiler
