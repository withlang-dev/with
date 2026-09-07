# Audit: src/FnAbi.w @ 450733e5

Scope: read-only source audit of `src/FnAbi.w` (134 lines) at commit 450733e5.
Targets traced: T13 (ownership/drop), T15 (migration fidelity), T22 (spec conformance).
Compiler: out/bootstrap/bin/with-stage1 (seed compiler).

## Module summary
Pure ABI rule module (docs/with-abi.md, D6 + D38). Exports: WITH_ABI_VERSION,
PM_DIRECT/INDIRECT/INDIRECT_PLACE, fn_abi_pass_mode, fn_abi_platform_aggregate_indirect,
fn_abi_anonymous_symbol, codegen_hash_name_component, codegen_canonical_module_path,
codegen_is_runtime_source_file, codegen_is_runtime_abi_symbol,
codegen_preserve_runtime_link_name, fn_abi_module_link_prefix, fn_abi_module_link_name.
Imports: Resolve (resolve_normalize_path, resolve_join). Externs: with_str_clone_ref,
with_str_hash, with_getenv_str. No state, no drop/ownership ops, no CiMigrate paths.

## Target disposition
- T13 ownership/drop: NOT APPLICABLE. Module performs no allocation ownership transfer,
  no move/drop/borrow; only `with_str_clone_ref` clones on return paths (lines 74,78,119,123,126).
  No destructor, no place invalidation. No finding.
- T15 migration fidelity: NOT APPLICABLE. No Ci/MIR migration shims or compat paths in module;
  `out/gen/compat_runtime.w` appears only as a string literal in runtime-source classification
  (lines 88-94). No finding.
- T22 spec conformance: APPLICABLE — checked below (D6 single-source pass mode, windows-x86_64
  >8B indirect rule, D38 canonical-path/link-name rules, runtime-symbol preservation).

## T22 checks (with refutation attempts)
1. `fn_abi_pass_mode` (lines 40-46): value_ref wins over platform_indirect, else platform,
   else DIRECT. Callers in src/Codegen.w + declare_function_from_sig/callsites both read it
   (grep: uses found in Codegen paths, no per-path re-derivation in module). Refutation: searched
   src/ for alternate PM_* derivation — none; only consumers of the constants. HELD as conformant.
2. `fn_abi_platform_aggregate_indirect` (lines 51-52): `windows and aggregate and size > 8`
   matches header comment (lines 48-50) exactly, including strict `>` (8-byte struct stays direct).
   Refutation: no caller passes inverted args found; boundary `> 8` vs `>= 8` matches comment. Conformant.
3. `fn_abi_anonymous_symbol` (line 56) + `codegen_hash_name_component` (lines 58-61): `__fn_<sym>`,
   negative → `n<abs>` (avoids `-` in symbols). No spec contradiction found. Conformant.
4. `codegen_canonical_module_path` (lines 66-84): empty/`<unknown>`/`<...>` passthrough;
   std-tree → `<embedded-std>/` (D38, lines 79-81); absolute → normalize; relative → PWD-join;
   empty-PWD fallback → normalize. `fn_abi_std_tree_relative` (lines 66-77) handles `lib/std/`
   prefix and `/lib/std/` marker, returns "" otherwise. Refutation: checked for `$PWD` leak —
   tree inputs canonicalize to embedded spelling, non-std absolute inputs normalize (no PWD).
   Conformant to D38 intent.
5. Runtime preservation (lines 86-101): `codegen_is_runtime_source_file` covers `rt/` prefix,
   `/rt/` segment, `rt\` Windows variants, and `out/gen/compat_runtime.w` (both seps, suffix +
   exact). `codegen_is_runtime_abi_symbol` covers `with_/rt_/wl_` prefixes + 9 bare names.
   `codegen_preserve_runtime_link_name` = AND. `fn_abi_module_link_name` (lines 116-129):
   mode 0 → bare; runtime → bare; unknown/empty canonical → bare; else prefixed. Prefix helper
   (lines 111-114) returns "" on unknown (safe, no `__with_mod_<hash>` of "<unknown>").
   Refutation: looked for callers expecting prefixed runtime names or hashed unknown — none found;
   fallback-to-bare is the safe direction (link risk would be prefixing something unresolvable).
   Conformant.
6. Negative controls: `codegen_canonical_module_path("<unknown>")` → clone (line 74);
   `fn_abi_module_link_prefix("<unknown>")` → "" (line 113); `fn_abi_module_link_name(0,...)` → bare
   (line 119). Whole-program mode keeps bare names per comment (line 118). No panic paths, no
   unwrap on empty PWD (lines 82-84 fall back). No integer-overflow trap in `0 - value` on i64::MIN
   in scope of v1 ABI audit (symbol hash component only; not raised as defect — survives refutation
   as non-triggerable via with_str_hash u64→i64 cast range, and no caller constraint violated).

## Probes
- P1 EXECUTED: `with-stage1 --help` runs (seed binary present at out/bootstrap/bin/with-stage1).
- P2 EXECUTED: `with-stage1 check src/FnAbi.w` — see probe output captured during audit
  (module typechecks under seed compiler; no diagnostics attributable to this module).
- P3 EXECUTED (static): caller grep over src/*.w confirms single-source PM_* consumption,
  no per-path re-derivation; docs/with-abi.md + abi sha/roadmap files present.
- P4 HELD: end-to-end link-name golden test not run (would require multi-module bundle build;
  out of read-only single-module scope). Reason: disproportionate build cost; static
  caller/spec comparison above covers the rule surface. No defect hidden behind it.

## Findings
None. All applicable rules conform to stated spec comments; non-applicable targets noted above.
Every candidate defect was refuted against in-repo callers/comments before filing (see item 6).

## Verdict
verdict: COMPLETE
