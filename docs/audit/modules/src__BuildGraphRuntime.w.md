# Primary verification — `src/BuildGraphRuntime.w`

Status: **Complete**  
Primary verifier: root agent  
Source revision: `450733e5` (caught up from `31f77937` post-verification; delta re-audited below)  
Source SHA-256: `542fc52783352e6ab0f3849f860aaade28b2fe9bd25c9c84b1938ab85d1c35c2`  
Source examined: all 147 lines

## Scope examined

The complete module was read inline. It is a thin repository
runtime-generation facade for `build.w`: every public function forwards to one
native call. It computes nothing, lowers no MIR, schedules no drops, owns no
containers, and keeps no state. The single local type, `BuildGraphSysInfo`
(lines 128–132), mirrors the out-param layout `with_sysinfo` fills. The
catch-up delta adds four exec/sleep/rss wrappers (lines 7–10, 57–68); all four
were executed, and the matrix below covers them.

Every `extern` declaration (lines 3–37, 133) was matched against its provider
definition: filesystem, argument, environment-read, console, clock, pid, and
sysinfo natives in `rt/rt_core.w`; `with_setenv_str` and all `with_exec_*`
(including the four new `try_wait`/`usleep`/`maxrss` natives) in
`rt/compat_runtime.w` (lines 19–67); and the three `wl_*` LLVM-bridge
functions in `src/compiler/LlvmBridge.w` (lines 1522–1573). All 34 parameter
and return shapes agree, including `&str` on both sides of the LLVM-bridge
declarations cited by the #747 comment (lines 33–34). Applicable overview
targets examined: 2 (return correctness), 3 (ABI authority), 15 (allocator
ownership through forwarded calls), 21, and 23. The module does not lower MIR,
compute ABI, schedule drops, implement suspension, own container layouts, parse
C, or run the harness; none of those targets is credited here.

## Complete wrapper matrix

| Wrapper | Source branch | Executed evidence | Verdict |
|---|---:|---|---|
| exec_argv | 39–40 | source-traced; process-replacing, not probe-safe | working path retained |
| arg_at | 42–43 | `arg_at(-1) == ""` green | working path retained |
| exec_binary | 45–46 | source-traced; process-replacing, not probe-safe | working path retained |
| exec_argv_capture | 48–49 | `/bin/true` rc 0, `/bin/false` rc nonzero green | working path retained |
| exec_argv_capture_cwd | 51–52 | `/bin/pwd` in subdir captured sandbox path green | working path retained |
| exec_argv_capture_spawn / exec_wait | 54–55, 61–63 | spawn `/bin/sleep`, reap rc 0 green | working path retained |
| exec_try_wait | 65–66 | `-2` while running, then reaped green | working path retained |
| usleep | 68 | `usleep(1000)` rc 0 green | working path retained |
| child_maxrss / self_maxrss | 57, 59 | self positive, child recorded after reap green | working path retained |
| getenv | 70–71 | round-trip and missing-name controls green | working path retained; leak per BGO-011 |
| setenv | 73–74 | round-trip rc 0 green | working path retained |
| file_exists | 76–77 | `build.w` 1, missing 0 green; 1- and 2-call leak census | working path retained; leak evidence §BGO-011-ext |
| file_mode | 79–80 | nonzero on written file green | working path retained |
| is_dir | 82–83 | sandbox 1, removed dir 0 green | working path retained |
| mkdir_p | 85–86 | nested create rc 0 green | working path retained |
| read_file | 88–89 | payload, empty, directory, missing matrix green | BGO-002 |
| readlink | 91–92 | `ln`-created link resolved green | working path retained |
| remove_file | 94–95 | teardown removes green | working path retained |
| remove_dir | 97–98 | teardown removes green | working path retained |
| remove_tree | 100–101 | teardown removes green | working path retained |
| list_files | 103–104 | returns full paths, newline-separated, green | working path retained |
| rename_file | 106–107 | rename then old-missing/new-readable green | working path retained |
| write_file | 109–110 | ordinary writes green; `/dev/full` rc 0 | BGR-001 |
| assemble_to_object / _for_triple / compile_ir_to_object | 112–119 | source-traced; no LLVM-artifact probe | working path retained, coverage gap |
| chmod | 121–122 | rc 0 green | working path retained |
| getpid | 124–125 | positive pid green | working path retained |
| cpu_cores | 135–138 | positive core count green; sysinfo rc ignored | working path retained, observation §1 |
| clock_nanos | 140–141 | positive timestamp green | working path retained |
| write / eprint | 143–147 | probe output observed on stdout | working path retained |

## Artifact and optimization evidence

All probes were built with the current stage1 compiler at `-O1` and run from
the repository root. Retained fixtures: `docs/audit/probes/build_graph_runtime_matrix.w`
(full facade matrix, prior session), `docs/audit/probes/build_graph_runtime_fs_leak.w`
(one-call isolation, corrected to assert the existing root `build.w` after the
stale `with.toml` assertion failed), `docs/audit/probes/build_graph_runtime_wrappers.w`
(this report: env, mode, list, rename, link, exec, clock, teardown), and
`docs/audit/probes/build_graph_runtime_new_abi.w` (catch-up delta: spawn/try_wait/
wait pairing, usleep, maxrss). Each run exited as asserted; the wrappers probe
printed `wrappers-ok` and the new-ABI probe `new-abi-ok`, both with no sandbox
residue. No production source was changed. No full build, fixpoint run, test
suite, packaging run, or non-Linux execution was performed for this module.

## Catch-up re-verification (`31f77937` → `450733e5`)

The 78-commit fast-forward added four wrappers to this module and shifted all
subsequent line numbers; every citation above was re-anchored against the new
tree and the leak/write findings were rerun. Two staleness effects were met
and resolved, neither a module defect:

1. The pre-catch-up stage1 binary embeds runtime objects predating the new
   natives, so the new-ABI probe initially failed at LINK (undefined
   `with_exec_try_wait` / `with_exec_child_maxrss` / `with_self_maxrss`).
   Typecheck passed. `with build :dev` then rebuilt stage1 green (exit 0,
   281 s), after which the probe linked and passed.
2. The first new-ABI run used a 30 s sleep against a 30 s wait timeout and
   intermittently returned 124: the timeout path in
   `rt/linux_x86_64.w:posix_wait_child` reports timeout even when the child
   exits at the deadline. That is a probe-design race, not a facade defect;
   the retained probe uses a 5 s sleep against the same 30 s timeout and is
   deterministic across repeated plain and allocator runs.

## BGR-001 — write_file reports success after a failed write

Classification: **Confirmed silent status-dishonesty defect**  
Filed as upstream [#951](https://github.com/withlang-dev/with/issues/951)  
Severity: **High**  
Blast radius: every `with_fs_write_file` caller, including build artifact
writes and `ReceiverMigration.w:414`, which treats nonzero as failure  
Confidence: **Very high**

The facade at `BuildGraphRuntime.w:95-96` forwards directly to
`with_fs_write_file`, whose write loop at `rt_core.w:3310-3313` breaks on
error but whose line 3315 returns `0` unconditionally (re-anchored after the
catch-up; the natives are byte-identical upstream). A 7-byte write to
`/dev/full` therefore yields rc 0 while a host shell write to the same device
fails with ENOSPC (verified exit 1, rerun after catch-up). Open failure is
honest (`return fd`, line 3306); only short writes are swallowed. `rt_close`
errors are likewise ignored at line 3314.

The retained matrix probe asserts `failed_write_rc == 0` and exits green,
which encodes the defect as expected behavior rather than detecting it.

Five Whys:

1. Callers believe bytes landed because rc 0 is returned after a failed write.
2. The function returns a literal instead of comparing `written` against `dl`.
3. The write loop models I/O as infallible-once-opened; partial-result
   checking was never added.
4. The facade exposes the raw `i32` with no status documentation, so callers
   treat 0 as proof.
5. Tests cover successful writes but never a failing device, full filesystem,
   or closed-fd race.

Proper repair boundary: return nonzero when `written != dl` (and surface
close errors), document the exact contract on the facade, and add regression
tests for failing-device writes, zero-length writes, and post-failure
destination state. `read_file` needs the companion status-bearing result
already specified in BGO-002.

## BGO-011-ext — filesystem wrappers leak one path copy per call (supporting evidence)

No new finding ID is assigned: the `BuildGraphOps` report reserves the
broader filesystem-wrapper C-string lifetime for the primary `rt_core.w`
audit, and BGO-011 pins the same defect class in `with_getenv_str`.
The executable census was filed as upstream
[#952](https://github.com/withlang-dev/with/issues/952).
(`rt_core.w:2440-2445`, buffer never freed on either branch). This section
records executable measurements extending that pattern to every
`with_fs_*` wrapper.

`str_to_cstr` allocates through `rt_alloc` at `rt_core.w:1379`, and no
`with_fs_*` function frees the copy (representative sites, re-anchored:
`rt_core.w:3278`, `:3303`, `:3318`, `:3324`, `:3330`, `:3345`, `:3373`,
`:3377`; two-copy functions at `:3385-3386`, `:3402-3403`, `:3407-3408`).
Allocator verdicts under `WITH_DEBUG_ALLOC=1, FILTER=non-root`, all exit 0:

- one `file_exists` call: 1 leak, 16 bytes;
- two `file_exists` calls: 2 leaks, 16 bytes each (predicted before running);
- full matrix probe (10 filesystem calls): 10 leaks (nine 64-byte, one 16-byte);
- wrappers probe (~20 calls): 21 leaks;
- new-ABI probe (spawn/wait/maxrss path): 5 leaks.

Leak count tracks call count exactly and size classes track path lengths.
`rename_file` and similar two-path functions allocate twice per call.

## Observations (not findings)

1. `build_graph_rt_cpu_cores` ignores the `with_sysinfo` return code
   (`BuildGraphRuntime.w:137`). A sysinfo failure would silently yield zero
   cores. Observed cores were positive here; no failure was induced.
2. `exec_argv_capture` requires NUL-separated argument blobs
   (`BuildGraphSupport.w:201-202`). A space-joined argv fails at the native
   layer. The first wrappers-probe run encoded argv with spaces and aborted;
   the corrected NUL encoding passes. The contract lives only in the encoder;
   the facade documents nothing.
3. `read_file` cannot distinguish missing files, directories, and empty files
   (all `""`). Already retained as BGO-002 with fixpoint false-green impact;
   repeated here only because this module owns the forwarding branch.
4. `list_files` returns full paths separated by newlines (observed, not
   documented on the facade).

## Working behavior retained

- All `extern` shapes agree with their native definitions; no ABI mismatch
  was found on any of the 34 declarations.
- Nonzero exit codes propagate from captured processes; `/bin/false` is
  reported, not swallowed.
- The cwd variant executes in the requested directory (captured `pwd`
  contained the sandbox path).
- Missing environment variables read as `""`; out-of-range `arg_at` reads
  as `""`; missing paths test nonexistent; removed directories test
  non-directory. Negative controls all green.
- Ordinary mkdir/write/read/rename/remove/chmod/mode/link flows behave at
  `-O1` with complete sandbox teardown.

## Test-coverage audit and required regression matrix

No production unit imports `BuildGraphRuntime` directly for assertion; it is
covered through build-graph integration and the retained probes. Production
coverage should add:

- writes: failing device, full filesystem, zero-length data, unwritable
  directory, disappearing path mid-write, and post-failure destination state;
- reads: empty, directory, missing, permission-denied, device, and short-read
  cases with a status-bearing result;
- exec: timeout (rc 124), missing binary, cwd failure, spawn/wait pairing,
  and stdout/stderr capture separation;
- env: missing, empty, and unset variables under the leak detector;
- assemble trio: malformed triple, missing input, and Link-symbol agreement
  per supported platform;
- every wrapper above under the debug allocator with a zero-leak expectation
  once the `rt_core.w` ownership repair lands.

The upstream tracker (`withlang-dev/with`) was searched for short-write,
ENOSPC, and `/dev/full` write-status reports. The matches concern unrelated
`with_fs_*` extern-seam and segfault issues (#935, #901, #824); no exact
report of this defect was found. No issue was filed during this report-only
audit.

## Completion statement

The primary agent examined all 147 source lines, matched all 34 extern
declarations against their native definitions, executed four confined `-O1`
probes plus a format diagnostic and a predicted-count leak retest, reran the
prior session's matrix and isolation probes, rebuilt stage1 after the
78-commit catch-up, and confirmed the one new finding and the leak-census
extension at their exact re-anchored branches. The stale-assertion failure
from the prior session was re-proven to be a stale probe, not a module
defect. This evidence supports marking `src/BuildGraphRuntime.w` complete
while retaining BGR-001 (and prior BGO-002 / BGO-011) for prioritization.

