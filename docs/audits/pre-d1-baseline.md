# Pre-D1 Verification Baseline

Status: P9 pre-Phase-D baseline. Captured before D1 implementation.

Date: 2026-05-20.

Verified code/design commit:

```text
617aecd0913f88c598ccb18f4449b3d908dcba0f Reconcile Phase D design with pre-D artifacts
```

This is the baseline commit used for the command results below. The commit
that adds this document is docs-only and does not change the verified compiler
or build behavior.

## Commands Run

All commands were run from the repository root on the local macOS/aarch64
machine.

```sh
out/bin/with build :build
out/bin/with build :fixpoint
out/bin/with build :test
out/bin/with build :emit-c-test
```

## Results

### `out/bin/with build :build`

Result: pass.

Relevant output:

```text
[stage1] wrote out/bin/with-stage1
[stage2] wrote out/bin/with-stage2
[build] wrote out/bin/with
```

The command also emitted the known target-triple warning while compiling
runtime/LLVM objects:

```text
warning: overriding the module target triple with arm64-apple-macosx26.0.0 [-Woverride-module]
1 warning generated.
```

### `out/bin/with build :fixpoint`

Result: pass.

Relevant output:

```text
[stage1] wrote out/bin/with-stage1
[stage2] wrote out/bin/with-stage2
FIXPOINT
```

### `out/bin/with build :test`

Result: pass.

Relevant output:

```text
ok: 526 files passed in build.w test target behavior-tests
ok: 179 files passed in build.w test target native-compile-error-tests
ok: 13 files passed in build.w test target native-codegen-tests
ok: 109 files passed in build.w test target native-spec-tests
ok: 16 files passed in build.w test target native-phase-tests
OK=2 TOTAL_ERRORS=0
generated /Users/eric/with/out/pcre2_reference/pcre2-10.47/src/config.h
PCRE2 MIGRATE SMOKE OK
PCRE2 TEST SMOKE OK
[build] wrote out/bin/with
EMIT-C SMOKE OK
```

Behavior test count: 526 files. This includes the six pre-D build/action
runner regression tests from P7:

- `behav_build_w_basic_invocation.w`
- `behav_action_capability_filesystem.w`
- `behav_action_capability_process.w`
- `behav_capability_token_mismatch.w`
- `behav_action_crash_diagnostic.w`
- `behav_action_no_deps_isolation.w`

Selfhost coverage in the default test target: 7 selfhost action targets:

- `cli-selfhost-smoke-tests`
- `cli-selfhost-one-liner-tests`
- `cli-selfhost-object-symbol-tests`
- `cli-selfhost-build-w-tests`
- `cli-selfhost-project-tests`
- `cli-selfhost-edge-tests`
- `cli-selfhost-parallel-tests`

The default test target also runs fast PCRE2 migration/test smoke coverage and
the emit-C smoke. Full PCRE2 corpus tests and full emit-C tests remain manual
targets.

### `out/bin/with build :emit-c-test`

Result: pass.

Relevant output:

```text
[stage1] wrote out/bin/with-stage1
[stage2] wrote out/bin/with-stage2
[build] wrote out/bin/with
EMIT-C OK
```

The command also emitted the known target-triple warning during C/object
compilation:

```text
warning: overriding the module target triple with arm64-apple-macosx26.0.0 [-Woverride-module]
1 warning generated.
```

## Artifact Sizes

Sizes captured after the baseline run:

```text
91351568 out/bin/with
132400   out/lib/rt_core.o
24112    out/lib/rt_darwin_aarch64.o
96048    out/lib/compat_runtime.o
4088     out/lib/panic_runtime.o
2820592  out/lib/regex_runtime.o
10856    out/lib/fiber_runtime.o
12160    out/lib/channel_runtime.o
55064    out/lib/fiber.o
784      out/lib/fiber_asm.o
5472     out/lib/fiber_stubs.o
19968    out/lib/cimport_stubs.o
3183480  out/lib/embedded_objects.o
453760   out/lib/llvm_bridge.o
4727624  out/lib/clang_bridge.o
15       out/lib/helpers.o
```

## D1 Starting Condition

D1 may begin only from a tree that is at least as healthy as this baseline:

- `:build` passes and writes stage1, stage2, and final compiler artifacts.
- `:fixpoint` reports `FIXPOINT`.
- `:test` passes with behavior count 526 or higher and preserves the listed
  smoke coverage.
- `:emit-c-test` reports `EMIT-C OK`.

Any deviation during D1 must be treated as a regression unless the change is
explicitly explained and reviewed in the D1 slice.
