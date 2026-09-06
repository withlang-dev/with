# Audit: lib/std/compiler.w @ 450733e5 — COMPLETE

Module: `lib/std/compiler.w` (182 lines) — compiler-hook introspection and tool
capabilities: `CompilerHookPhase`/`DeclKind` enums, `SourceLocation`/`ModuleInfo`/
`FunctionInfo`/`TypeInfo`/`ProjectInfo` data types, `Diagnostics`/`SourceEmitter`
capability handles, TSV escape helper, token-gated `__driver_new` constructors.

## Targets traced

- T13 ownership/drop: all handle types are plain aggregates of `str`/`Vec`/scalars,
  no `Drop` impls, no manual memory management — nothing to leak or double-drop.
  `ProjectInfo.add_module/add_function/add_type` are `move fn` whole-`self`
  rebuilders (`var out = self; out.<vec>.push(...); out`); chaining
  `project = project.add_module(...)` verified working in probe A. `location()` /
  `modules()` / `functions()` / `types()` return `&`-views; no owned data escapes
  by reference beyond the borrow. No T13 defect.
- T15 migration fidelity: landed-commit intent confirmed. `839696a7` (HEAD)
  migrated this module per D5/D27 (`Diagnostics.error` observes
  `&SourceLocation`, `compiler_hook_escape` observes `&str`,
  `FunctionInfo/TypeInfo.location` return views); `4f7bd9d2` fixed capability
  helpers to observe `&str`. Current signatures match the driver's generated
  code in `src/compiler/Compilation.w` (`project_info_source` passes owned
  `SourceLocation.new(...)` values to by-value `FunctionInfo.new`/`TypeInfo.new`
  params; `compiler_hook_runner_source` builds `__driver_new` rvalues inline).
  Probe A + hook probe exercise both shapes successfully. No T15 defect.
- T22 spec conformance: no decode/encode/crypto claims in this module (N/A —
  no independent oracle needed). The only wire format is the internal
  Diagnostics TSV (`error\tfile\tstart\tend\tmessage\n`): encoder
  (`compiler_hook_escape`, compiler.w:62-76) escapes `\`→`\\`, TAB→`\t`,
  LF→`\n`, CR→`\r`; driver decoder (`compilation_split_escaped_fields`,
  Compilation.w:192-216) inverts exactly (`\n`→LF, `\t`→TAB, `\r`→CR, else
  literal incl. `\\`→`\`). Symmetry verified by code inspection AND end-to-end
  (probe C: embedded TAB survived the round trip without splitting fields).
  Token gate (`compiler_capability_require`, compiler.w:82-85) requires a
  non-empty `WITH_TOOL_CAPABILITY_TOKEN` match, else `exit(1)`; backstopped by
  a static compiler rule rejecting user-code calls to `__driver_new` (probe B).
  No T22 defect.

## Findings

No defects. (No numbered findings — every candidate below was refuted.)

Refutation attempts (candidates considered, all cleared):
1. `docs_value` always `false` — driver codegen (`project_info_source`) passes
   literal `false` for docs, so `has_docs()` is always false. Refuted as a
   module defect: the module faithfully exposes what the driver provides; any
   docs-detection gap lives driver-side in `src/compiler/Compilation.w`.
2. `Diagnostics.error` read-modify-write (`with_fs_read_file` + append +
   `with_fs_write_file`) — TOCTOU under concurrency. Refuted: the hook runner
   executes hooks sequentially in one process; no concurrent writers exist.
3. `SourceEmitter.emit_source` leading `"\n"` wrapper — harmless whitespace;
   driver splices emitted source after a marker comment (Compilation.w:984).
   Observed, not a defect.
4. Escape coverage (only `\`/TAB/LF/CR escaped) — sufficient because TAB is the
   only field separator and LF the only record separator; the decoder handles
   exactly the encoder's alphabet. Verified symmetric, not a defect.

## Probes run (seed = out/bootstrap/bin/with-stage1)

- Probe A (EXECUTED, pass): `/tmp/audit-compiler/probe_a.w` — `ProjectInfo`
  builder chain, `modules()/functions()/types()` counts, `is_pub/has_docs/
  param_count/return_type/kind` accessors, `location()` view, enum values.
  Output: `modules=1 functions=1 types=1`, `fn pub=true docs=true params=2
  ret=i32`, `loc file=src/mymod.w start=10 end=20`, `type pub=false
  kind=struct`, `phase=after_typecheck declkind=function/type_decl`.
- Probe B (EXECUTED, pass — negative control): `/tmp/audit-compiler/probe_b.w`
  calls `Diagnostics.__driver_new("wrong-token", ...)` from user code. The
  compiler statically rejects it: "tool capability constructor
  'Diagnostics.__driver_new' can only be called by the compiler driver",
  exit=1. Stronger than the runtime token check; runtime gate unreached by
  design (defense in depth, both layers present).
- Probe C (EXECUTED, pass — end-to-end hook): `/tmp/audit-compiler/hookproj/
  main.w` with `@[compiler_hook(after_typecheck)] fn my_hook(project:
  ProjectInfo, diagnostics: Diagnostics)` calling `diagnostics.error(
  &SourceLocation.new(...), f"hook saw {fns.len()} functions A\tB")`.
  `with-stage1 build` surfaced `error: hook saw 231 functions A<TAB>B`,
  proving hook dispatch, `ProjectInfo.functions()`, `&`-temporary arg, and
  TAB escape round-trip. Scratch binaries removed; `main.w` kept under /tmp
  (outside repo).

## Test-file coverage

No `tests/*.w` file references `std.compiler` directly (checked: `tests/` has
no hook/compiler-named files; `tests/test_translate_c.w:206` "compiler
builtins" mention is unrelated). Behavior is pinned only via the driver hook
path exercised above. `docs/handoff.md` references prior hook tests
(`4f7bd9d2` "5 hook tests", `behav_compiler_hook_project_info`), but no such
test files exist in-tree at this commit — historical note, not a module defect.
Do not file issues (per task instructions).

## Verdict: COMPLETE — no defects, all probes pass
