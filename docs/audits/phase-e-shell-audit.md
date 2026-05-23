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
    src lib rt build.w build_*.w --glob '!src/main_emit_temp.w'
```

`src/main_emit_temp.w` is excluded from the first pass because it is a tracked
generated snapshot; it should be handled after the authoritative sources no
longer produce shell-string internals.

## Findings

| Area | Current shape | Phase E action |
|------|---------------|----------------|
| `src/compiler/Compilation.w` | Shell command strings removed. Filesystem cleanup and directory creation use typed runtime filesystem primitives; `dsymutil` uses typed argv capture. Runtime exports are reached through `compiler.Runtime`, not local `extern fn` declarations. | Complete for Phase E. |
| `src/compiler/Link.w` | Shell command strings removed. Link command execution, `nm -u` capture, archive creation, and cleanup use typed runtime process/filesystem wrappers. Runtime exports are reached through `compiler.Runtime`, not local `extern fn` declarations. | Complete for Phase E. |
| `src/main.w` | Shell command strings removed. Cleanup, `run`/one-liner execution, test stdout/stderr capture, and benchmark execution use typed runtime process/filesystem wrappers. | Complete for Phase E. |
| `src/compiler/ConanClient.w` | Shell command strings removed. Conan package extraction runs `tar` through typed argv capture; runtime access goes through `compiler.Runtime`. | Complete for Phase E. |
| `src/CImport.w` | The orphan `with_system` extern was removed. The remaining shell pipeline text is a commented verification command. | Complete for Phase E. |
| `lib/std/process.w` | Public `Process` wrapper stores shell command strings and executes them with `with_system`. | Redesign as an argv-first API. If an explicit shell API remains, it must be named as shell execution and documented as such. |
| `rt/clang_bridge.w` | Uses `popen` shell probes for SDK/clang resource discovery and diagnostic command construction. | Replace probes with typed process capture and/or direct filesystem enumeration. |
| `rt/compat_runtime.w` | Provides legacy `with_system` by executing `/bin/sh`. | Retire only after all source users are removed. The runtime export remains the last compatibility layer, not a new dependency target. |
| `build_pcre2.w` | Invokes upstream PCRE2 `RunTest` through `/bin/bash`. | Documented exception candidate: this is an upstream shell test runner boundary, not compiler/build internal filesystem work. Keep isolated and explicit unless PCRE2 tests are ported. |
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
