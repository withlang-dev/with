# Audit: build/sdk.w @ 450733e5 — INCOMPLETE

- Module: `build/sdk.w` (842 lines), `module build.sdk`
- Commit: 450733e5 ("build: the regex runtime shim compiles pcre2 from source ...")
- Targets traced: T13 (ownership/drop), T15 (migration fidelity), T22 (spec conformance)
- Callers: `build.w` only (`use build.sdk`, build.w:14); all `pub` fns consumed there
  (package/platform/source/ninja/cmake/llvm targets, build.w:765-920, 1587-1601).
- Verdict: INCOMPLETE (findings 1-2 are behavior-affecting; finding 3 is hygiene)

## Finding 1 (T22, severity: medium, probe: static+caller trace, refutation: attempted — survives)
`sdk_host_tag_for_platform` has no `windows-aarch64` branch (build/sdk.w:112-121),
so it returns `"unsupported"` for that platform — while `sdk_current_platform`
(build/sdk.w:108-109) *can* return `"windows-aarch64"` and build.w registers
`package-llvm-sdk-windows-aarch64` via `sdk_default_prefix_for_platform` /
`sdk_default_build_cache_for_platform` (build.w:1591), both derived from the host
tag. Result: prefix `.deps/llvm-<ver>-unsupported`, cache
`.deps/build/llvm-<ver>-unsupported/CMakeCache.txt`, output prefix
`out/sdk/unsupported/...`. Meanwhile build.w's cross consumer hardcodes
`.deps/llvm-<ver>-windows-aarch64-msvc` (build.w:336-337).
Refutation attempt: commit 2ee9f70e's message claims it added the
"windows-aarch64 host tag (-msvc)", but its `build/sdk.w` diff only touched
`sdk_current_platform` + `sdk_validate_cache` — the tag branch was never added.
Callers do pass `"windows-aarch64"` (build.w:1591 and the current-host dispatch),
so this is live, not hypothetical. Fix: add
`if platform == "windows-aarch64": return "windows-aarch64-msvc"`.

## Finding 2 (T22, severity: medium, probe: static+caller trace, refutation: attempted — survives)
Every other platform split special-cases only `"windows-x86_64"`, so
`windows-aarch64` falls into the unix branch and cannot package on its native host:
- `sdk_validate_package_prefix` (build/sdk.w:302,322): else branch requires
  `lib/libclang.a`; a Windows LLVM install provides `lib/libclang.lib` → deterministic fail.
- `sdk_select_package_files` / `sdk_package_tool_selected` (build/sdk.w:365,384,399):
  else-branch tool list is extensionless (`bin/clang`, ...), but on a Windows host
  rels carry `.exe`, so nothing under `bin/` matches → empty selection →
  `run_package_llvm_sdk_action` fails with "SDK package would be empty" (build/sdk.w:488).
- `sdk_package_entries` lld-alias handling (build/sdk.w:427,445): same split.
Refutation attempt: 2ee9f70e deliberately kept the llvm-ml64 MASM assert x86_64-only,
but nothing in the tree documents packaging itself as x86_64-only, and the graph
registers + dispatches the windows-aarch64 package target. `build.w:888` already
treats both windows platforms alike for the sdk-llvm output (`.lib`), confirming intent.

## Finding 3 (hygiene, severity: low, probe: repo-wide grep, refutation: attempted — survives as dead code only)
- `sdk_jobs_arg` (build/sdk.w:592-597): zero callers; every build site uses
  `sdk_append_jobs` (used at 667,730,832). Dead.
- `sdk_optional_tool_exists` (build/sdk.w:351-352): zero callers. Dead.
- Notes (not defects): `sdk_tool` (242) and `sdk_required_tool` (239) have identical
  bodies but both are used — redundancy only; `sdk_llvm_targets_arg` (737) takes an
  unused `ctx` — idiomatic placeholder, no behavior impact.

## Non-findings (checked, no defect)
- T13 ownership/drop: all consumed accumulators use explicit `move`
  (230,233,426,436,667,730,832); pushes copy via `sdk_owned_text`; matches the
  post-d527f299 share-place idiom. `archive_symlink_entry("lld", ...)` arg order
  matches `lib/std/build.w:349` (`target, archive_path, mode`), and `bin/lld` is in
  the selection list, so the alias target exists.
- T15 migration fidelity: 450733e5 does not touch `build/sdk.w` or `build.w`
  SDK paths (it is a pcre2/regex commit); findings 1-2 predate it (2ee9f70e) and are
  not regressions from it. `comp_arch_is_aarch64` adoption (5376b66f) is consistent.
- `sdk_validate_cache` unix-branch rejection of `/usr/bin/cc|gcc|c++` (285-287) and
  `starts_with(key)` cache lookup (251-257) behave correctly (`_LAUNCHER` keys do not
  false-match since the prefix includes the colon).
- Helper source paths `build/https_fetch.w` (525) and `build/zlib_gunzip.w` (540)
  both exist in the tree.

## Probes run
- `with-stage1 check build/sdk.w` → `error: import module not found: 'build.compiler'`.
- Negative controls: `check build/emit_c.w`, `build/package.w`, `build/pcre2.w`,
  `build/clang_resource.w` fail identically (all import `build.compiler`);
  `check build/abi.w`, `build/compiler.w`, `build/seed.w`, `build/https_fetch.w`
  pass. Conclusion: environmental single-file-check limitation, not an sdk.w defect.
- No execution probes feasible: actions require build-graph ctx; full SDK rebuilds
  take hours. No test files reference `sdk` (grep over `tests/` empty) — no test
  coverage is claimed.
- No issues filed (per instructions).

Verdict: INCOMPLETE
