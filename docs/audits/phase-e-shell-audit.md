# Phase E Shell-String Audit

Status: active audit for Phase E. `src/compiler/Compilation.w` cleanup
complete.

Phase E removes shell command strings from compiler, migrator, runtime,
stdlib, and build-system internals. Shell syntax remains acceptable in the
Makefile while it exists, scripts, and shell-facing test fixtures.

## Scan

Initial scan:

```sh
rg -n "with_system|/bin/bash|/bin/sh| sh -c|bash -c|zsh -c|\| awk|\| grep|2>/dev/null| > .*2>" \
    src lib rt build.w build_*.w
```

`src/main_emit_temp.w` was a tracked legacy entry snapshot generated only as an
unused compiler source output. It has been removed from the source tree and
compiler source generation graph.

## Findings

| Area | Current shape | Phase E action |
|------|---------------|----------------|
| `src/compiler/Compilation.w` | Shell command strings removed. Filesystem cleanup and directory creation use typed runtime filesystem primitives; `dsymutil` uses typed argv capture. Runtime exports are reached through `compiler.Runtime`, not local `extern fn` declarations. | Complete for Phase E. |
| `src/compiler/Link.w` | Shell command strings removed. Link command execution, `nm -u` capture, archive creation, and cleanup use typed runtime process/filesystem wrappers. Runtime exports are reached through `compiler.Runtime`, not local `extern fn` declarations. | Complete for Phase E. |
| `src/main.w` | Shell command strings removed. Cleanup, `run`/one-liner execution, test stdout/stderr capture, and benchmark execution use typed runtime process/filesystem wrappers. | Complete for Phase E. |
| `src/compiler/ConanClient.w` | Shell command strings removed. Conan package extraction runs `tar` through typed argv capture; runtime access goes through `compiler.Runtime`. | Complete for Phase E. |
| `src/CImport.w` | The orphan `with_system` extern was removed. The remaining shell pipeline text is a commented verification command. | Complete for Phase E. |
| `lib/std/process.w` | Shell-string execution removed. `Command` now stores an argv vector and executes through typed argv runtime process execution. | Complete for Phase E. |
| `rt/clang_bridge.w` | Shell probes removed. SDK discovery and `cc -E` preprocessing use typed argv capture; LLVM resource directory discovery uses direct directory enumeration. | Complete for Phase E. |
| `rt/compat_runtime.w` | Legacy shell exports removed. `with_system` and `with_extract_tgz` no longer exist; remaining process operations are argv/binary based. | Complete for Phase E. |
| `build_pcre2.w` | Invokes upstream PCRE2 `RunTest` through typed argv with `/bin/bash` as the program. | Documented exception: owner is the PCRE2 migrated-library test target. This is an upstream shell test runner boundary, not compiler/build internal filesystem work. Keep isolated unless PCRE2 tests are ported. |
| `build_selfhost.w` | Scan hit `shorthand` as a filename substring. | False positive. |

## First Code Slice

Completed in the first implementation slice:

- `rm -f` -> typed file removal;
- `rm -rf <binary>.dSYM` -> typed tree removal;
- `mkdir -p` -> typed recursive directory creation.

Completed in the second implementation slice:

- `dsymutil <binary> 2>/dev/null` -> typed argv capture to `/dev/null`;
- removed raw runtime extern declarations from `Compilation.w` and routed the
  calls through `src/compiler/Runtime.w`.

The slices did not change broader link command construction or test execution.

## Link Slice

Completed:

- `nm -u <object> > <report> 2>/dev/null` -> typed argv capture;
- `rm -f <report>` -> typed file removal;
- shell `ar rcs` condition -> typed argv archive creation through Darwin
  `libtool -static`;
- raw runtime extern declarations in `Link.w` -> `src/compiler/Runtime.w`.

The old shell condition avoided unnecessary archive invocations but was not a
semantic requirement. Direct `ar rcs` produced Mach-O archive members that ld64
rejected as not 8-byte aligned; Darwin static archives are now created through
typed `libtool -static` argv execution. `make fixpoint` is the guard against any
determinism regression from that change.

The remaining `Link.w` scan hit for `_with_system` is a symbol-name string used
to decide which runtime object a user program needs; it is not shell execution.

## Verification

For the audit document itself:

```sh
git diff --check docs/audits/phase-e-shell-audit.md
```

For the first code slice:

```sh
out/bin/with check src/main.w
make build
make fixpoint
make test
```

After each Phase E slice, rerun the scan and update this audit until every
remaining hit is either removed, a false positive, an allowed fixture, or a
documented exception with an owner.

## Std Process Slice

Completed:

- removed the public `system_cmd(cmd: str)` shell-string helper;
- removed `Command { cmd: str }` shell command storage;
- added argv-first `process.run(Vec[str])`;
- changed `Command` to store `Vec[str]`, append via `.arg(...)`, and execute
  through `with_exec_argv`.

This keeps `std.process` at the runtime process boundary but removes shell
parsing from the standard API.

## Clang Bridge Slice

Completed:

- removed `popen`, `pclose`, and `fgets` from the libclang bridge;
- changed `xcrun --show-sdk-path` discovery to typed argv capture;
- changed macro parsing and preprocessing from shell command strings to typed
  `cc` argv capture with stdout read from a temp file;
- replaced `ls -1d ... | head -1` resource directory discovery with direct
  directory enumeration under `/usr/local/llvm/lib/clang`.

## Compat Runtime Slice

Completed:

- removed `with_system`;
- removed the shared `/bin/sh -c` helper;
- removed `with_extract_tgz`, whose only former source user now uses typed
  `tar` argv execution;
- removed stale declarations from `runtime/with_runtime.h`;
- removed `_with_system` from compat-runtime link detection.

## Legacy Entry Snapshot Slice

Completed:

- removed the unused tracked `src/main_emit_temp.w` snapshot;
- removed `out/gen/main_emit_temp.w` generation from the project build graph
  and Makefile source generation path.

## Remaining Scan Hits

After Phase E cleanup, the only source scan hits are:

- `build_pcre2.w` invoking upstream PCRE2 `RunTest` through typed argv with
  `/bin/bash` as the executable. This is a documented migrated-library test
  runner exception, owned by the PCRE2 build module.
- `build_selfhost.w` containing `shorthand` in a filename. This is a false
  positive.

Makefile shell usage remains outside Phase E by design while Make still exists.
