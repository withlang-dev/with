# Audit: src/compiler/Runtime.w @ 450733e5

- Module: `src/compiler/Runtime.w` (105 lines)
- Commit: `450733e5`
- Targets: T13 (ownership/drop), T15 (migration fidelity), T22 (spec conformance)
- Verdict: COMPLETE

## Summary

Thin compiler runtime boundary: 25 `extern fn with_*` declarations (lines 4–28)
each with a same-signature `pub fn runtime_*` passthrough wrapper (lines 30–105).
No logic, no branching, no allocation, no drop/move sites. All declarations
verified against their definitions; the module type-checks under stage1.

## Probes run

- P1 — `out/bootstrap/bin/with-stage1 check src/compiler/Runtime.w` → `ok`, exit 0.
  (Binary confirmed present via `ls out/bootstrap/bin/`; no `seed/` dir exists,
  so the `seed`-prefixed probe path in the request was adapted to `out/`.)
- P2 — extern↔definition cross-check (REGEX-mode repo searches + `grep rt/*.w`):
  all 25 externs resolve with matching `&str`/scalar signatures —
  `with_eprint`, `with_str_clone_ref`, `with_str_hash (-> u64)`, `with_getenv_str`,
  `with_arg_at`, `with_fs_read_file`, `with_fs_write_file`, `with_fs_file_exists`,
  `with_fs_is_dir`, `with_fs_mkdir_p`, `with_fs_remove_file`, `with_fs_rename_file`,
  `with_fs_remove_tree`, `with_fs_list_files`, `with_clock_nanos`, `with_nanosleep`,
  `with_getpid`, `with_sysinfo_os`, `with_sysinfo_arch` in `rt/rt_core.w`;
  `with_setenv_str`, `with_exec_binary`, `with_exec_argv`, `with_exec_argv_cwd`,
  `with_exec_argv_capture` in `rt/compat_runtime.w`; `with_fs_remove_dir` in
  `rt/rt_core.w:3393`.
- P3 — rename-atomicity comment check (lines 75–76): confirmed —
  `MoveFileExW(..., MOVEFILE_REPLACE_EXISTING)` in `rt/windows_aarch64.w:485`
  and `rt/windows_x86_64.w:480`.
- P4 — wrapper caller coverage (REGEX search `runtime_[a-z_]+` over `src/`):
  24/25 wrappers have in-repo callers (heavy users: `Compilation.w`, `Link.w`,
  `Frontend.w`, `ConanClient.w`, `ProjectConfig.w`, `Zcu.w`).
- N1 (negative control) — search-method validation: `runtime_list_files` search
  returns known callers (`Link.w:257`, `ConanClient.w:524/1019`), proving the
  method finds callers when they exist.

## Findings (all refuted — zero confirmed defects)

1. `src/compiler/Runtime.w:66` (`runtime_remove_dir`) — severity: info —
   target T22 — probe status: P4 — zero in-repo callers (only the declaration
   itself matches). Refutation attempt: SUCCEEDS as a defect — a boundary module
   exposing the full fs surface needs no per-wrapper caller; the extern resolves
   (`rt/rt_core.w:3393`) and the wrapper is a correct passthrough. Observation only.
2. `src/compiler/Runtime.w:95-96` (`with_str_hash -> u64`, wrapper narrows
   `as i64`) — severity: info — target T22 — probe status: P2. Refutation
   attempt: SUCCEEDS — deliberate per `17b54dc3` ("u64 like the rt def; i64 pinned
   at the formatting sites (D30 R2c, #761)"); every in-repo consumer
   (`Frontend.w:109,537,549,609,643`) only formats/compares the value, and the
   bit-identical cast preserves equality. (Side note, out of module scope:
   `runtime/with_runtime.h:211` declares `int64_t with_str_hash` vs the `u64`
   `rt_core.w:2320` def — this module correctly matches the authoritative `.w` def.)
3. Module header (lines 1–2) says compiler modules "should depend on these typed
   wrappers instead of redeclaring externs", yet siblings redeclare covered
   externs directly (e.g. `Compilation.w:33-36`, `DriverOptions.w:3-8`,
   `ClangBridge.w:24-28`, `CodegenUnits.w:27`, `LlvmBridge.w:14`) —
   severity: info — target T22 — probe status: P4. Refutation attempt: SUCCEEDS —
   per-module extern redeclaration is the repo-wide style and "should" is
   advisory; non-adoption by callers is not a defect in this module.

## Target trace

- T13 ownership/drop: COMPLETE — pure passthroughs; `str`-returning wrappers
  (`runtime_read_file`, `runtime_getenv`, `runtime_arg_at`, `runtime_list_files`,
  `runtime_sysinfo_os/arch`, `runtime_str_clone`) hand ownership to the caller
  under normal semantics; no `move`/drop sites exist in the module.
- T15 migration fidelity: COMPLETE — 25/25 extern params use `&str`, matching
  the #747 borrow migration; history shows targeted follow-ups (`7d8d085e`,
  `a69e77e0`, `17b54dc3`); no stale plain-`str` params remain.
- T22 spec conformance: COMPLETE — all externs resolve to same-signature rt
  definitions; platform comments verified; stage1 `check` passes.

Verdict: COMPLETE
