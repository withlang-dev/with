# Primary verification — `lib/std/os.w`

Status: **COMPLETE** (no defects)
Primary verifier: primary (full source read + probe execution)
Source revision: `450733e5`
Source examined: all 88 lines (single complete read)

## Scope examined

Layer-1 platform wrappers: `os` (`:31`), `os_kind` (`:35`),
`arch` (`:46`), `arch_kind` (`:50`), `hostname` (`:59`),
`process_id` (`:63`), `posix_process_id` (`:67`, via
`c_import("int getpid(void); int isatty(int);")`), 
`posix_fd_is_terminal` (`:71`), `env` (`:75`), `set_env` (`:79`),
`has_env` (`:83`), `path_exists` (`:87`), plus `OsKind`/`ArchKind`
(`:19`/`:25`). Backends: `with_sysinfo_os/arch/hostname`,
`with_getpid`, `with_getenv_str/with_setenv_str`,
`with_fs_file_exists` (all `rt/rt_core.w` + `rt/compat_runtime.w`).
In-repo `use std.os` callers: only `test/behavior/behav_std_os.w:3`;
no `lib/` module depends on it (layer-2 `std.process`/`std.sysinfo`
re-declare the same externs directly). `src/Sema.w:1345-1360`
classifies the `std.os` path alongside fs/net/sync/channel/task/
thread/process/signal/sysinfo/time in a path-gating predicate (1 =
gated class). No os test files besides `behav_std_os.w`.

## Behavioral matrix (all EXECUTED, oracles independent)

- `docs/audit/probes/os/probe.w` (via `out/bootstrap/bin/with-stage1
  run`, stdin `/dev/null`): printed `os()`/`arch()`/`hostname()`
  then `notty` then `ok`; asserted `os_kind/arch_kind != Unknown`,
  `process_id() > 0`, `process_id() == posix_process_id()`,
  `set_env` round-trip (`== 0`, `has_env`, `env == "probe-ok"`),
  unset-var `env == ""` + `has_env == false`, `path_exists` true
  (`lib/std/os.w`) and false (missing name). PASS.
- Independent oracle (`python3`: `platform.system()`,
  `platform.machine()`, `socket.gethostname()`, `os.isatty(1)` under
  the same stdin redirect): `Linux x86_64 shawn-beast`, `notty` /
  `isatty1= False` — byte-exact agreement with every probe-printed
  value including the `notty` branch. PASS.
- `with check lib/std/os.w` → ok (stage1).
- Existing `test/behavior/behav_std_os.w` (expect-stdout `ok`):
  same surface; read, not re-run (HELD — suite-owned).

## Findings

None. In-report notes (not filed):

- `has_env` is true only for present *and non-empty* vars
  (`with_str_len(...) > 0`, `:84`); a var explicitly set to `""`
  reads as absent. Refutation attempt: the docstring (`:82`)
  states exactly that contract, and the probe confirms `env`
  still returns `""` for both unset and empty — no contradiction
  between the two functions.
- `os_kind`/`arch_kind` return `Unknown` for unlisted names rather
  than failing loudly. Refutation attempt: the enums are closed
  tags for platform switches with an explicit `Unknown` arm, the
  probe confirms this host maps to known arms, and no caller
  branches on exhaustiveness in-repo — a total function, not a
  silent fallback.

Verdict: COMPLETE
