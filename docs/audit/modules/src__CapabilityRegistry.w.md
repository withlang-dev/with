# Audit: src/CapabilityRegistry.w @ 450733e5

- Commit: 450733e5 (verified `git rev-parse --short HEAD`)
- Module size: 64 lines. Pure predicate/map module: 1 enum (`CapabilityKind`, 11 variants),
  8 free functions. No state, no I/O, no comptime, no unsafe.
- Targets: T13 ownership/drop, T15 migration fidelity, T22 spec conformance.

## Verdict: COMPLETE (no findings)

## Target analysis

- T13 ownership/drop: NOT APPLICABLE. All signatures use value types only
  (`i32`, `bool`, `&str` borrows, owned `str` return in `kind_name`). No owned
  resources cross any boundary; nothing to drop. No caller (`SemaCheck.w`,
  `SemaDecl.w`, `ComptimeValue.w`, `ComptimeEval.w`) holds a handle from this module.
- T15 migration fidelity: NOT APPLICABLE. No C-ism, no extern, no ABI surface.
- T22 spec conformance: CONFORMANT. `kind_name` covers all 10 non-none kinds;
  `lookup`/`is_capability`/`lookup_std_build`/`lookup_std_compiler` agree on the
  8 build + 2 compiler names; callers (`tool_capability_kind_for_type`
  SemaCheck.w:215-224, `compiler_hook_param_is_supported` SemaDecl.w:2752-2767,
  `fn_symbol_is_tool_comptime_allowed` SemaCheck.w:9564-9570) use the predicates
  consistently with their gate roles.

## Refuted candidates (checked, NOT reported as defects)

1. `compiler_hook_param_supported` (line 61-64) accepts `ProjectInfo` for the
   compiler path while `lookup_std_compiler` (33-36) has no ProjectInfo arm.
   REFUTED: intentional. Caller error text (SemaDecl.w:2750) explicitly blesses
   "ProjectInfo, Diagnostics, or SourceEmitter from std.compiler"; a hook
   by-value param needs no minted CK_ handle, so no `CK_COMPILER_PROJECT_INFO`
   is required. `kind_name` fallback `"none"` is display-only (ComptimeValue.w:359).
2. `ends_with("/lib/std/build.w")` suffix (lines 17, 20) could match a user path.
   NOT CLAIMED: exploitability depends on `current_module_path` provenance
   (as-passed CLI string vs canonical path), which this module does not control;
   callers resolve via compiler-recorded candidate paths (`named_type_path_for`).
   Recorded as hardening observation only; no in-repo counterexample demonstrates
   misclassification.

## Probes (seed compiler ./out/bootstrap/bin/with-stage1)

- P1 POSITIVE `check lib/std/build.w` -> `ok`, exit 0. EXECUTED.
- P2 POSITIVE `check` trivial `use`-free program -> `ok`, exit 0. EXECUTED.
- P3 NEGATIVE `check` user file declaring same-named `BuildCtx` type in /tmp
  (non-std path) -> accepted as ordinary user type; capability gating is
  path-based so no collision. EXECUTED (initial attempt used invalid `struct`
  keyword and correctly failed to parse; reran with the `type X:` syntax used
  by lib/std/build.w).
- P4 `kind_name` exhaustiveness: verified by inspection (10/10 non-none arms);
  direct unit invocation not possible (internal fn, no REPL hook). HELD: no
  internal-call harness; covered by review + P1 instead.
