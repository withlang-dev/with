# Audit: src/compiler/DriverOptions.w @ 450733e5

- Commit: 450733e5 (verified `git rev-parse --short HEAD`)
- Scope: full module (539 lines), targets T13 (ownership/drop), T15 (migration fidelity), T22 (spec conformance)
- Callers (REGEX search): `src/main.w:788` (build parse), `:835,:844-845,:865,:921-925` (ir/analyze/check link-bundle + corpus), `:1397` (runner clone), `:1825` (tool-eval clone), `:1952` (graph-target clone), `:2520` (target_default kind), `:2937` (set_link_bundles); `src/TargetSpec.w:4` (numbering cross-ref); `src/Overflow.w:17,27` (valid/parse); `src/Compilation.w:605,623`, `src/ComptimeEval.w:1891`

## T13 ownership/drop — reviewed, no defect
- `build_command_options_clone` (:159-185) deep-clones every owned field: all 5 Vecs via `driver_clone_str_vec`, all 4 bundle strs via `with_str_clone_ref`. In-repo callers move or mutate only the clone (`main.w:1397` mutates `runner_options.opt_level`; `:1825` moves into `configure_options`; `:1952` rebuilds per-target vecs), so base is never aliased-mutated. No drop/double-free observed (valid `--emit-c` builds succeed).
- `parse_build_command_options` (:443-539) stores `with_arg_at` refs directly into `source_path/output_path/link_*` without cloning. Refutation: argv storage outlives the single `move _sp_build` into `run_build_command` (`main.w:788-793`); secondary uses all go through the cloning clone-fn above. No use-after-free evidence; probes all succeed.
- `move target.error_msg` (:479) is the idiomatic move-out of a struct field before `target` is dropped; matches sibling `move` usage in `main.w`.
- Minor asymmetry (not a finding): `driver_clone_str` (:148-151) guards empty before `with_str_clone_ref`, while clone (:180-183) calls `with_str_clone_ref` unconditionally on possibly-empty bundle paths. No failure observed (empty-string clone round-trips fine in every probe); no change requested.

## T15 migration fidelity — N/A, no defect
- Module is native With (no `migrate` output markers, no transliterated C idioms); `MigrateCommandOptions` (:86-105) is a plain options struct with a complete default ctor (:197-217). No gotoStructuring/block-style logic lives here. Nothing to fidelity-check.

## T22 spec conformance — conforms
- Target triples (:313-328) implement the §18.5 set exactly with the shared 0-6 numbering (`TargetSpec.w:3-6` cross-ref, `std.build.BuildTarget`): native/2 linux/2 darwin/2 windows spellings + legacy `linux_x86_64`-style aliases. `driver_parse_build_target` (:337-363) handles `--target X` and `--target=X`, last-wins, `-1` → explicit error naming §18.5. `driver_target_triple_kind(cfg.target_default)` reuse at `main.w:2520` is consistent.
- Prelude (:405-427) / overflow (:429-441) parsers accept exactly the documented value sets, return typed errors naming expected values; defaults (Full / env `WITH_INTERNAL_OVERFLOW_MODE` w/ `-1` fallback) match `Compilation.w:605,623` consumption (`valid ? mode : -1/panic`).
- Mutual-exclusion/gating errors (:486-527): `--emit-c`×`--emit-obj`, `--emit-bundle-manifest`→`--emit-obj`, `--emit-bundle-interface`→`--emit-obj`, corpus-required rule. All fire as documented; `check`-side `--bundle-fingerprint`+corpus rule (`main.w:926-929`) mirrors the build-side corpus rule.
- Graph survey default (:537 `not --fail-fast`, `--survey` no-op) matches the 2026-08-15 ruling comment. `driver_build_source_arg` skip-list (:265-284) covers all build value-flags (`-o/--output/--output=/--filter/-f/--explain/--target/--link-*/--emit-bundle-*/--bundle-*`) plus `-`-prefix and `:selector` guards.

## Probes run (seed out/bootstrap/bin/with-stage1 exists; `seed/` dir absent — not needed)
1. `build --emit-c --emit-obj` → `error: --emit-c and --emit-obj are mutually exclusive` (matches :489-494).
2. `build --prelude=bogus` → `error: invalid --prelude value 'bogus' (expected full|alloc|core|none)` (matches :459).
3. `build --target bogus-triple` → `error: unsupported target triple 'bogus-triple'; see §18.5` (matches :360).
4. `build --overflow=bogus` → `error: invalid --overflow value 'bogus' (expected panic|wrap|saturate)` (matches :469).
5. `build --emit-obj --emit-bundle-manifest /tmp/m.manifest` (no corpus) → corpus-required error (matches :522-526).
6. `build --emit-obj --emit-bundle-manifest ... --bundle-corpus std/re` → reaches bundle pipeline (`no module under corpus` / interface-spelling errors), proving the gate passed correctly.
7. `build --target=x86_64-unknown-linux-gnu --emit-c` → `emitted C`, proving `=` form + valid triple path.

## Negative controls (valid paths still work)
- N1: plain `build --emit-c -o` → `emitted C`, 175KB output — valid builds unaffected by error gates.
- N2: `build --target` (missing value) → `--target requires a target triple argument` (matches :347), not a crash/empty-source misparse.
- N3: `check --bundle-fingerprint /tmp/fp` (no corpus) → `--bundle-fingerprint requires --bundle-corpus <rel>` via `main.w` check path — corpus rule enforced on both commands.

## Findings
None — every candidate defect was refuted against in-repo callers and live `with-stage1` probes above. No issues filed per instructions.

## Verdict: COMPLETE
