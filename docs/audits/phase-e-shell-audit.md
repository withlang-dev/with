# Phase E Shell-String Audit

Status: active audit for Phase E. First implementation slice complete.

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
| `src/compiler/Compilation.w` | Filesystem cleanup and directory creation now use typed runtime filesystem primitives. `dsymutil ... 2>/dev/null` still uses `with_system`. | Later slice: run `dsymutil` through argv process execution. |
| `src/compiler/Link.w` | Uses `with_system` to run link commands, `nm -u > file 2>/dev/null`, `rm -f`, and an `ar rcs` shell condition. | Replace link execution with typed argv command execution, replace `nm` with argv capture, replace cleanup with filesystem primitives, and make archive creation typed. |
| `src/main.w` | Uses `with_system` for cleanup, direct binary execution, test stdout/stderr redirection, and benchmark command execution. | Replace cleanup with filesystem primitives and replace execution/redirection with argv process APIs that support env, cwd, capture, and timeout. |
| `src/compiler/ConanClient.w` | Uses `tar xzf ... -C ... 2>/dev/null` through `with_system`. | Decide whether Conan support is still live. If live, replace with typed archive extraction or argv execution. If dead, remove the client. |
| `src/CImport.w` | Declares `with_system`; scan found only a comment using shell pipeline syntax. | Confirm the extern is orphaned and remove it in a cleanup slice if unused. |
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

The slice intentionally left `dsymutil` command execution for a later
process-execution slice and did not change link command construction or test
execution.

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
