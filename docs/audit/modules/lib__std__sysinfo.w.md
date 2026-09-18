# Primary verification — `lib/std/sysinfo.w`

Status: **COMPLETE** (no defects)
Primary verifier: primary (full source read + probe execution)
Source revision: `450733e5`
Source examined: all 25 lines (single complete read)

## Scope examined

`os()` (`:12`), `arch()` (`:20`), `hostname()` (`:24`) — thin wrappers over
the `with_sysinfo_os` / `with_sysinfo_arch` / `with_sysinfo_hostname`
runtime exports (implemented in `rt/rt_core.w:3754-3766`, backed per-platform
by `rt_sysinfo_os`/`rt_sysinfo_arch` in `rt/linux_x86_64.w`,
`rt/linux_aarch64.w`, `rt/darwin_aarch64.w`, `rt/windows_*`). Deps: none.
Callers of `use std.sysinfo`: `test/behavior/behav_sysinfo_contract.w`,
`test/behavior/behav_action_capability_process.w`,
`test/behavior/behav_std_process_command.w`,
`test/behavior/lib/pre_d_build_runner.w`, `build/selfhost.w`,
`build/wo.w`, `build/sdk.w`, `build/retention.w`, `build/package.w`,
`build/compiler.w`, `build/emit_c.w`, `build/release_uat.w`. (The
`with_sysinfo_*` externs are separately redeclared by compiler sources —
`src/TargetSpec.w`, `src/BuildGraphTools.w`, `src/main.w`, etc. — which do
not go through this module.)

## Behavioral matrix (EXECUTED unless marked HELD, oracles independent)

- `docs/audit/probes/sysinfo/values.w` (`use std.sysinfo`, print all three):
  output `Linux` / `x86_64` / `shawn-beast`, rc=0. Cross-checked against
  three independent oracles — `uname -s -m` (`Linux x86_64`), `hostname`
  (`shawn-beast`), `python3 platform`
  (`Linux x86_64 shawn-beast`) — all byte-exact. PASS (EXECUTED).
- `with check lib/std/sysinfo.w` → ok (stage1). PASS (EXECUTED).
- `test/behavior/behav_sysinfo_contract.w` (existing repo test) asserts the
  same spelling contract (`Macos`/`Linux`/`Windows`,
  `aarch64`/`x86_64`, non-empty hostname). Consistent, not re-run (HELD —
  covered by the probe above on this host).
- `Macos`/`Windows`/`aarch64` spellings: HELD (single Linux-x86_64 host;
  no Mac/Windows machine or cross-target run available in this audit).

## Findings

None. In-report notes (not filed):

- `hostname()` falls back to `"unknown"` when `rt_libc_gethostname`
  fails (`rt/rt_core.w:3763-3764`). Never triggered here (hostname
  returned `shawn-beast`); fault injection would be needed to execute the
  fallback, and the fallback value itself would fail the
  `behav_sysinfo_contract` non-empty check only if empty — `"unknown"` is
  non-empty, so no contradiction. Refutation attempt: none possible
  without a failing gethostname; the branch is three lines and obviously
  correct by inspection.
- Doc comment (`:11`) promises `"Macos"` on macOS; `rt/darwin_aarch64.w:898`
  returns that spelling by source read, but not executed on this host.
  Refutation attempt: `grep` of all four backends confirms exactly one
  spelling per platform; no second spelling exists to diverge.

Verdict: COMPLETE
