# Windows Bootstrap Status

Last updated: 2026-06-07.

## Anti-Loop Summary

Last known green:

- Windows stage1 via healthy candidate seed: PASS.
- Windows stage2 `version`: PASS.
- Windows direct stage3 object: PASS.
- `with build :fixpoint`: PASS.
- `with build :emit-c-fixpoint`: PASS.
- Windows stage2 stack reserve: PASS, `SizeOfStackReserve: 8388608`.
- Windows release compiler PE imports: PASS; checked imports are Windows
  system DLLs only (`KERNEL32`, `ADVAPI32`, `ntdll`, `ole32`, `SHELL32`,
  `VERSION`, `OLEAUT32`).
- `out/emit-c-test/main.c` raw-NUL check: PASS; generated C has zero raw NUL
  bytes.

Current blocker:

- Windows bootstrap/fixpoint frontier is green.
- Windows `with build :emit-c-fixpoint`: PASS from rebuilt stage2 candidate.
- Linux release gate was blocked in `with build :test` by regex behavior tests
  after `build` and `:fixpoint` passed.
- Current failure class: Linux regex runtime FFI subject pointer bug, fixed in
  source by extracting `str` data before calling PCRE2.
- Latest focused check: Linux `behav_regex_language_semantics.w` and
  `behav_regex_capture_fstring.w` PASS after rebuilding `regex-runtime-object`.
- Linux committed-source release gate PASS: `build`, `:fixpoint`, `:test`,
  `:test-green`, and `:last-green`.
- Windows user-program linker path: fixed in source by routing Windows
  non-LLVM links through `out/lib/llvm_ld` and the existing `lld-link` command
  builder.
- Windows basic async runtime bootstrap: improved enough for focused
  `test/behavior/async_basic.w` to pass by selecting the Windows fiber core and
  Windows x64 fiber assembly.
- Windows action process test: fixed in source by invoking With itself via
  `version`; this avoids external `echo`/shell dependencies after bootstrap.
- Windows async cancellation behavior is not release-gating for v0.15.0.
  It is tracked as GitHub issue #341:
  https://github.com/withlang-dev/with/issues/341
- Current v0.15.0 Windows release gate: rebuild candidate compiler, rerun
  `:fixpoint`, `:emit-c-fixpoint`, PE import checks, stack-reserve checks, and
  Linux build/fixpoint gate from the same source. Full Windows `:test` remains
  expected to fail until #341 is fixed.
- Current release-flow correction: `build` writes the release compiler to
  `out/release/bin/with(.exe)`. A separate explicit `update-bin` target copies
  that artifact to `out/bin/with(.exe)` after gates. On Windows, `update-bin`
  cannot be run from the same `out/bin/with.exe` process because Windows locks
  the running executable.
- Windows v0.15.0 gate after release-flow correction: PASS.
  - `out/bin/with.exe build`: PASS.
  - `out/bin/with.exe build :fixpoint`: PASS.
  - `out/bin/with.exe build :emit-c-fixpoint`: PASS.
  - PE stack reserve: PASS, `SizeOfStackReserve: 8388608`.
  - PE imports: PASS, system DLLs only.
  - Handoff copy from `out/release/bin/with.exe` to `out/bin/with.exe`: PASS.
  - `out/bin/with.exe version`: PASS, `with v0.15.0`.
- Linux same-source gate from fresh worktree: PASS.
  - Source copied into `/home/lazarus/with-linux-gate-v0.15.0` from the
    Windows checkout.
  - Static LLVM SDK linked from `/home/lazarus/with/.deps`.
  - `build`: PASS.
  - `:fixpoint`: PASS.
  - `:emit-c-fixpoint`: PASS.
  - Handoff copy from `out/release/bin/with` to `out/bin/with`: PASS.
  - `out/bin/with version`: PASS, `with v0.15.0`.
- Cross-host emitted-C determinism: PASS after normalizing frontend/imported
  source text and embedded stdlib text to LF. Windows and Linux emitted
  `out/emit-c-test/main.c` matched byte-for-byte at SHA256
  `296ebbe9a72ef6d7b711f1e1a3eb04f33b0f9cad0012c361ccf3077ee773238f`.
- Current SDK/release-tooling frontier: old Windows and Linux LLVM SDKs are
  intentionally rejected because they were not built by the required Clang SDK
  path (`cl.exe` on Windows, `/usr/bin/cc`/`c++` on Linux). Next SDK rebuild
  order is `tools/build-ninja.*`, then `tools/build-cmake.*`, then
  `tools/build-static-llvm.*`, then package SDK assets that include SDK Ninja,
  SDK CMake, and LLVM utility tools.
- Known non-blocking debt: stack-budget checker still reports one frame above
  64 KiB (`max_frame: 99304`) while the Windows stage2 PE stack reserve remains
  the intended 8 MiB.

Do not reopen without fresh evidence:

- 64 MiB stack workaround.
- MIR value locals.
- Broad ABI redesign.
- Hand edits to generated C/artifacts.
- Old regex runtime pointer-temporary issue.
- Old regex runtime `str as *const u8` subject pointer bug.
- Old LLVM/Clang DLL import issue.
- Old `with_arg_at` runtime extern ABI issue.
- Old `to_cstr` terminator issue.
- Old emit-C intern-pool issue.
- Old emit-C bootstrap seed path issue.
- Old emitted-C value-ref pointer argument classification issue.
- Old repeated-string-concat decoder hypothesis.
- Old emitted-C `Vec.with_capacity` zero-`elem_size` issue.
- Old assumption that Windows behavior-test failures are regex-specific.

Known debt, not current blocker:

- Stack frame reduction remains debt; the policy stays at 8 MiB.
- MIR value locals require dominance/PHI design and remain disabled by default.
- `scripts/check-stack-budget.py --max-frame 65536` may still report large
  compiler frames; that is not the current `:emit-c-fixpoint` blocker.

Latest transition:

- Rebase-overflow regression root cause:
  - After rebasing onto `24d6b4d0`, Windows `build` and `:fixpoint` passed,
    but `:emit-c-fixpoint` crashed during `emit-compiler-c` with
    `0xc0000005`.
  - LLDB showed the crash entered `with_panic` from `rt_clock_ns`; registers
    contained the panic text `"integer overflow"`.
  - Five whys: emit-C calls `runtime_clock_nanos`; Windows implements that via
    `rt_clock_ns`; `rt_clock_ns` computed `now * 1000000000 / qpc_freq`;
    commit `36f2ecd0` made integer overflow checked by default; QPC tick counts
    can overflow i64 in the multiply before the division.
  - Why Linux passed: the Linux clock runtime path does not perform this QPC
    tick-count multiply, so checked overflow did not trip there.
  - Source fix: compute Windows QPC nanoseconds as whole seconds plus scaled
    remainder: `seconds * 1000000000 + (remainder * 1000000000) / qpc_freq`.
    This preserves checked overflow and fixes the runtime math.
  - Bootstrap recovery: the broken `out/release/bin/with.exe` contained the old
    overflowing clock runtime, so seed resolution had to fall back to the
    pre-rebase `out/bin/with.exe` seed. After moving the broken generated
    release binary aside, `out/bin/with.exe build`, `:fixpoint`, and
    `:emit-c-fixpoint` passed from the final source.
  - Windows `update-bin` target is not safe to run from `out/bin/with.exe` or
    `out/stage/bin/with-stage2.exe`, because Windows locks the running
    executable while dependencies try to refresh it. The release handoff was
    completed by copying `out/release/bin/with.exe` to `out/bin/with.exe` after
    all With processes exited.

- Windows release-flow root cause:
  - Running `:fixpoint` from `out/release/bin/with.exe` failed with
    `could not move output to: out/release/bin/with.exe`.
  - Five whys: Windows refuses to replace a running executable; the gate was
    run from the release output; the intended stable self-host seed path is
    `out/bin/with(.exe)`; commit `73cbb94c` moved compiler outputs into
    `out/release/bin` but did not add the handoff copy back to `out/bin`; the
    release runbook and build graph therefore diverged.
  - First attempted source fix made `build` a copy handoff, but that caused
    `:fixpoint` from `out/bin/with.exe` to fail when the build graph tried to
    overwrite the running executable.
  - Corrected source fix: keep `build` as the release compiler action writing
    `out/release/bin/with(.exe)` and add a separate explicit `update-bin`
    `CopyFile` target for the post-gate handoff.
  - Verification: from `out/bin/with.exe`, `build`, `:fixpoint`, and
    `:emit-c-fixpoint` pass. Running `update-bin` from
    `out/stage/bin/with-release-seed.exe` refreshes `out/bin/with.exe`, which
    then reports `with v0.15.0`.
  - Linux verification from fresh worktree also passes `build`, `:fixpoint`,
    `:emit-c-fixpoint`, release-to-bin handoff copy, and
    `out/bin/with version`.

- Linux regex behavior root cause:
  - `with build :test` failed in `behav_regex_language_semantics.w` and
    `behav_regex_capture_fstring.w`.
  - LLDB breakpoint on `pcre2_match_8` showed the subject pointer register
    contained a pointer to a With `str` value on the stack. The bytes at that
    address were `{data_ptr, len, ...}`, not the subject bytes `"a1 b2"`.
  - Root cause: `rt/regex_runtime.w` passed `text as *const u8` to PCRE2.
    `str` is a value type, so the runtime must extract the first field rather
    than cast the whole value to a byte pointer.
  - Fix: added `regex_str_data` and used it for PCRE2 match/substitute subject
    pointers. Replacement strings already use `regex_to_cstr`.
  - Focused Linux checks PASS after forcing `:regex-runtime-object` rebuild.
  - Full committed-source Linux release gate PASS.

- Windows release-test root cause:
  - `check` and `--emit-obj` passed for `test/behavior/assoc_type_basic.w`,
    while binary `build` failed silently.
  - `test/hello.w` showed the same object-pass/binary-fail pattern, so this
    was a link path failure, not an associated-type or async compiler bug.
  - Source inspection showed non-LLVM/user-program links call
    `link_stage_make_link_command("cc", ...)`. Linux passed because that path
    exists there; Windows needs `lld-link`.
  - Source fix: route Windows non-LLVM links through the existing Windows
    LLVM linker command builder using `out/lib/llvm_ld`.

- Windows async runtime root cause:
  - After the linker fix, `test/hello.w` built and ran.
  - `:test` advanced to `async_basic.w` and failed with unresolved
    `with_fiber_spawn`, `with_runtime_core_*`, and related scheduler symbols.
  - `build.w` selected `rt/fiber_core_windows_stub.w`; that file intentionally
    exported only `with_windows_fiber_core_stub`.
  - Source fix: select the shared fiber core for Windows, add Windows system
    call shims for the POSIX-shaped hooks it imports, and replace the Windows
    assembly placeholder with `with_fiber_switch` and
    `with_fiber_prepare_initial_context`.
  - Follow-up correction: POSIX-name shim functions in `rt/windows_x86_64.w`
    were module-mangled and therefore did not satisfy `extern fn mmap` from a
    separate object. The final source keeps Windows fiber core separate and
    calls existing unmangled `rt_*` platform hooks.
  - Focused `test/behavior/async_basic.w`: PASS.

- Windows action process test root cause:
  - Full Windows `:test` later failed only in
    `behav_action_capability_process.w`.
  - The generated nested `build.w` pushed `"/bin/echo"` into
    `ctx.process_runner().run_capture`.
  - Linux passed because `/bin/echo` exists; Windows failed at run stage with
    exit 134 because the nested action could not run the hardcoded POSIX path.
  - Initial host-selected `cmd.exe`/`/bin/echo` fix was rejected because
    post-bootstrap stages should not depend on external userland tools.
  - Intermediate With one-liner fix passed linker metadata into the child, but
    `with -e` is a nested compile/run path on Windows: the direct child emitted
    `lld-link` debug-section warnings on stderr and did not provide the expected
    one-liner stdout to this capture test.
  - Final focused source fix: invoke With itself via `version`. This keeps the
    test free of external userland dependencies and verifies direct process
    stdout/stderr capture without adding a nested compiler-runner behavior to
    this unit test.

- Windows async cancellation root cause:
  - `behav_async_cancel_await_cleans_children.w` and
    `behav_async_cancel_nested_unwind.w` crashed with `0xc0000005`.
  - LLDB crash site: `store_i32` inside
    `with_runtime_current_set_cancelled_return`, writing the cancelled-return
    flag through `current_fiber`.
  - Corrected register analysis: RCX at the final `store_i32` was the value
    being stored, not the fiber pointer. The base was `RAX - 0xd8`.
  - `memory region` showed the current fiber record's page was `---`.
  - Breakpoint on `rt_munmap` showed the page was released immediately before
    the crash by `with_free` from `chain` at the `child.await` source line.
  - Source/codegen inspection showed raw Task await frees `result_buf` but did
    not clear the source Task local. Cleanup/drop paths then saw the old Task
    value and tried to detach/free the same `result_buf` again.
  - Experimental fix attempt cleared all awaited Task locals in `FIBER_AWAIT`
    codegen. That removed the access violation but caused the live-fiber
    assertion to fail because child-cancel propagation later read the cleared
    Task id. This source change was reverted.
  - Experimental follow-up moved the ownership cancellation into MIR lowering
    after the child-cancel check and limited source-place clearing to
    cleanup-only await codegen. This was still incomplete and was reverted.
  - Further LLDB evidence showed `with_free` was still reached directly from
    the normal `child.await` codegen after `with_fiber_await` returned because
    the current fiber was cancelled.
  - Decision for v0.15.0: do not keep layering async patches during the Windows
    compiler-bootstrap release. Track this as post-release issue #341.

- Restored `build/compiler.w` compiler-child actions to use
  `run_capture_with_env` on Windows. The prior no-capture diagnostic branch
  caused `bootstrap-regex-runtime-ir` to print IR to the console instead of
  writing the expected `.ll.tmp` stdout capture file. With `WITH` set to the
  relative candidate path, capture is healthy.
- Windows verification after capture restoration:
  - `with build :stage1`: PASS.
  - `with build :stage2`: PASS.
  - `out/stage/bin/with-stage2.exe version`: PASS.
  - Direct stage3 object command: PASS.
  - `with build :fixpoint`: PASS.
  - `with build :emit-c-fixpoint`: PASS (`EMIT-C OK`, `EMIT-C FIXPOINT`).
- Windows PE checks:
  - `out/stage/bin/with-stage2.exe` `SizeOfStackReserve: 8388608`,
    `SizeOfStackCommit: 4096`.
  - `out/release/bin/with.exe` imports only checked Windows system DLLs:
    `KERNEL32`, `ADVAPI32`, `ntdll`, `ole32`, `SHELL32`, `VERSION`,
    `OLEAUT32`.
  - `scripts/check-stack-budget.py --max-frame 65536` still reports
    `max_frame: 99304`; classification: known frame-size debt, not current
    bootstrap blocker.
- Linux source synced from Windows, then Linux gate with
  `LLVM_PREFIX=$PWD/.deps/llvm-22.1.6-linux-x86_64` and
  `WITH=$PWD/out/bootstrap/bin/with-from-c`: `build` PASS, `:fixpoint` PASS,
  `:emit-c-fixpoint` PASS.
- Removed the temporary `argv.txt` diagnostic write from `build/compiler.w`
  and cleaned trailing whitespace in `src/CodegenDispatch.w`, then reran the
  gates from the final source:
  - Windows `with build :emit-c-fixpoint`: PASS (`EMIT-C OK`,
    `EMIT-C FIXPOINT`).
  - Linux `build`, `:fixpoint`, and `:emit-c-fixpoint`: PASS with
    `LLVM_PREFIX=$PWD/.deps/llvm-22.1.6-linux-x86_64` and
    `WITH=$PWD/out/bootstrap/bin/with-from-c`.
  - Final Windows PE checks still show `SizeOfStackReserve: 8388608`,
    system-only checked imports, and the known non-blocking
    `max_frame: 99304` stack-budget debt.

- Source fix applied: CCodegen now lowers `VEC_WITH_CAPACITY` through
  `with_vec_new_with_capacity_out`, preserving `elem_size` and capacity;
  `runtime/with_runtime.h` now declares the runtime entry point for emitted C.
- Source fix applied: Windows emit-C executable outputs now use `.exe` names.
- Rebuilt with `WITH=out/stage/bin/with-stage2-candidate.exe`.
- `with build :stage1`: PASS.
- `with build :stage2`: PASS.
- `out/stage/bin/with-stage2.exe version`: PASS.
- Direct stage3 object command: PASS.
- `with build :fixpoint`: PASS.
- Attempted `WITH=out/stage/bin/with-stage2.exe with build :emit-c-fixpoint`:
  FAIL before emit-C because the graph tried to rebuild/overwrite the same
  executable currently running as `WITH`; Windows refused the move to
  `out/stage/bin/with-stage2.exe`. Classification: seed path self-lock, not
  compiler/codegen. Use a separate candidate seed path.
- Rebuilt stage1/stage2 after the `.exe` path fix and copied fresh
  `out/stage/bin/with-stage2.exe` to
  `out/stage/bin/with-stage2-candidate.exe`: PASS.
- Clean `WITH=out/stage/bin/with-stage2-candidate.exe with build
  :emit-c-fixpoint`: `EMIT-C OK` PASS, then FAIL because
  `emit-c-fixpoint` still declared `out/emit-c-test/with-from-c` instead of
  `out/emit-c-test/with-from-c.exe`. Classification: build graph input path
  bug, not compiler/codegen.
- Source fix applied: `build.w` now declares that input with `host_bin`.
- Rebuilt stage1/stage2 after the `build.w` input fix, refreshed
  `out/stage/bin/with-stage2-candidate.exe`, then ran clean
  `WITH=out/stage/bin/with-stage2-candidate.exe with build :emit-c-fixpoint`:
  PASS (`EMIT-C OK`, `EMIT-C FIXPOINT`).
- PE/stack validation: `out/stage/bin/with-stage2.exe` stack reserve is
  `8388608`, commit `4096`. `out/release/bin/with.exe` imports only Windows
  system DLLs in the checked import table. `scripts/check-stack-budget.py
  --max-frame 65536` still FAILS with max frame `99304`; classification: known
  stack-frame debt, not current bootstrap blocker.
- Synced source changes to `/home/lazarus/with`.
- Linux gate attempt with explicit `~/.local/bin/with`: FAIL in stage1 with
  `could not locate Linux x86_64 crt/linker files for direct ld.lld link`.
  Host inspection showed `/usr/lib/x86_64-linux-gnu/crt1.o`,
  `/usr/lib/x86_64-linux-gnu/crti.o`,
  `/usr/lib/x86_64-linux-gnu/crtn.o`,
  `/usr/lib/x86_64-linux-gnu/ld-linux-x86-64.so.2`, and
  `/usr/lib/gcc/x86_64-linux-gnu/15/crtbegin.o` exist. Classification:
  source detection bug, not missing host dependency.
- Source fix applied: `src/compiler/Link.w` `link_stage_file_exists` now uses
  `runtime_file_exists(path) != 0` instead of `runtime_read_file(path).len() >
  0`.
- Running `/tmp/with-v0.14.8-seed/with-linux-x86_64` directly got past CRT
  detection but failed linking stage1 because the Linux host has runtime
  libraries only (`libz.so.1`, `libzstd.so.1`, `libxml2.so.16`) and lacks the
  unversioned development linker names required by `-lz`, `-lzstd`, and
  `-lxml2`.
- Source fix applied: Linux direct `ld.lld` linking now falls back to absolute
  versioned system shared-library paths for `z`, `zstd`, and `xml2` when the
  unversioned linker names are absent.
- Local non-root Linux verification setup: created `/tmp/with-link-libs`
  symlinks for `libz.so`, `libzstd.so`, and `libxml2.so`, plus
  `/tmp/with-tools/ld.lld-with-local-libs` adding `-L/tmp/with-link-libs`.
- First wrapper attempt still failed because `build/compiler.w` child compiler
  actions passed only `WITH_OUT_DIR`, dropping `WITH_LLVM_LD`.
- Source fix applied: `build/compiler.w` now passes through explicit LLVM
  toolchain override variables (`LLVM_PREFIX`, `WITH_LLVM_LD`, `LLVM_LD`,
  `WITH_LLVM_CC`, `LLVM_CC`, `WITH_LIBCLANG`, `LIBCLANG_FILE`) to child
  compiler actions.
- Linux gate with local linker wrapper: `with build` PASS, `with build
  :fixpoint` PASS, then `with build :emit-c-fixpoint` failed later after
  producing Linux `out/emit-c-test/main.c`.
- Cross-host emitted-C comparison:
  - Windows `out/emit-c-test/main.c`: 30,800,494 bytes,
    SHA256 `1bacb53f95313696e6a25540ae375cf3e9bcccb8470a5fae5ddbff62ee55d5f0`.
  - Linux `out/emit-c-test/main.c`: 31,697,068 bytes,
    SHA256 `42d814223bd3277edc624ecb79f88313226b553146ad07b3867200854a5cc756`.
  - Both files are LF-only and NUL-free as emitted C files, but the first
    diff is inside `EMBEDDED_STD_0`: Windows embedded raw stdlib text with
    `\r\n`, Linux embedded `\n`.
- Source fix applied: `build/runtime.w` and
  `src/tools/generate_embedded_stdlib.w` now canonicalize embedded source text
  to LF before writing `EmbeddedStdlibData.w`.
- Next exact command: regenerate Windows and Linux emitted C from this source,
  compare bytes, then continue Linux `:emit-c-fixpoint` and Windows isolation.
- Bootstrap policy correction: the Linux static LLVM SDK package was incomplete
  for emitted-C bootstrap because it carried LLVM/lld/libclang libraries but no
  `bin/clang`/`bin/clang++`. Do not use GCC or MSVC `cl.exe` for bootstrap C.
  Source/docs fix applied: `scripts/package-llvm-sdk.sh` now packages and
  verifies `bin/clang` and `bin/clang++`; `tools/build-static-llvm.{sh,ps1}`
  now fail if the installed SDK lacks those drivers; the bootstrap-C generated
  README now invokes `$LLVM_PREFIX/bin/clang` and `$LLVM_PREFIX/bin/clang++`.
- Linux SDK repaired: after installing host build tools, reran
  `HOST_TAG=linux-x86_64 PARALLEL_JOBS=$(nproc) tools/build-static-llvm.sh`
  with Ninja on PATH. Verified `.deps/llvm-22.1.6-linux-x86_64/bin/clang`,
  `bin/clang++`, `bin/ld.lld`, `bin/llvm-nm`, and `lib/libclang.a` exist, and
  `llvm-nm -g lib/libclang.a` exports `clang_createIndex`.
- Linux C seed rebuilt from the current Windows-emitted C with the With-owned
  SDK compiler:
  `.deps/llvm-22.1.6-linux-x86_64/bin/clang++ -x c out/tmp/current-windows-emitted-main.c -x none ...`.
  Result: `out/bootstrap/bin/with-from-c version` PASS, reports `with v0.14.8`.

- Refreshed `out/lib` runtime/bridge objects from healthy stage1, regenerated
  `out/lib/embedded_objects.o`, and forced a stage2 relink.
- `out/stage/bin/with-stage2.exe version`: PASS.
- `out/stage/bin/with-stage2.exe check test\hello.w`: PASS.
- Stage2 stack reserve: PASS, `8388608`.
- Direct stage3 object command: PASS.
- `WITH=out/bootstrap-c-v0.14.8/with-bootstrap.exe with build :fixpoint`: PASS.
- Next exact command: clean `out/emit-c-test` stamps and run
  `WITH=out/bootstrap-c-v0.14.8/with-bootstrap.exe with build :emit-c-fixpoint`.
- First clean `:emit-c-fixpoint` after that reached `emit-c-test` hello smoke
  linking and failed with duplicate UCRT symbols (`libucrt.lib` and `ucrt.lib`
  both present). Classification: emit-C wrapper Windows link command bug, not
  stack, ABI, or compiler crash. `out/emit-c-test/main.c` still had zero raw
  NUL bytes.
- Source fix: removed explicit `ucrt.lib` from `emitc_push_system_libs`; the
  clang/MSVC static runtime path already brings the correct CRT libraries via
  the selected static runtime model and `libcmt.lib` directives.
- Second clean `:emit-c-fixpoint` after that reached the hello smoke and failed
  on content: `emit-c-test: hello output mismatch: <NUL><NUL><NUL><NUL><NUL><NUL><NUL>`.
  `out\emit-c-test\main.c` still had zero raw NUL bytes, while
  `out\emit-c-test\hello_test.c` contained seven raw NUL bytes in the emitted
  literal. A control emission with `out\release\bin\with.exe` produced
  `WITH_STR_LIT("hello\n")` and zero raw NUL bytes. Classification: C-built
  compiler runtime/string ABI failure, not stack, not stale generated C, not
  bootstrap seed path.
- Targeted C repros linked against the same `out\lib` runtime proved that
  `with_fs_read_file`, `with_str_slice`, `with_str_concat`,
  `with_str_concat_n`, and `with_str_concat_n_move_first` return correct bytes
  from ordinary emitted-C ABI calls. The remaining bad pattern is the generated
  literal decoder itself. Source fix: changed `cc_decode_with_string_escapes`
  to use `StringBuilder`, matching `cc_escape_c_string` and avoiding the
  repeated string-concat loop that produced zero-filled decoded payloads in the
  C-built compiler.

## Goal

Bring up With on Windows x86_64 from the emitted-C bootstrap path without
hand-editing generated artifacts.

The finish line is:

1. Source fixes live in `.w`, headers, scripts, or runbook source, not in
   generated C.
2. A regenerated `with-bootstrap-c-v0.14.8.tar.zst` builds on Windows into
   `with-bootstrap.exe` plus `with-bootstrap.pdb`.
3. The bootstrap executable links only static LLVM/libclang/lld inputs from the
   With-owned Windows SDK and has no LLVM/Clang/MSVC runtime DLL dependency.
4. The native Windows stage chain completes from that bootstrap compiler.
5. `with build :emit-c-fixpoint` passes on Windows.

## Ground Rules

- Never modify generated artifacts by hand.
- Always regenerate emitted C after source changes.
- Treat build failures as source bugs unless proven otherwise.
- Use the host Linux seed only to build source and regenerate bootstrap
  bundles; the seed itself is self-contained.
- The Windows `.exe` must be self-contained except for normal Windows system
  DLLs.
- Windows SDK `.lib` files under
  `C:\Program Files (x86)\Windows Kits\10\Lib\...\um\x64` are permitted
  bootstrap/final link inputs only as import libraries for Windows system DLLs.
  The acceptance check is the final PE import table: no LLVM, Clang, MSVC
  runtime, zlib, zstd, libxml2, or other non-system DLLs may be imported.

## Current State

Working branch:

```text
windows-bootstrap-v0.14.8-source-fixes
```

Host:

```text
ssh lazarus@192.168.0.115
repo: /home/lazarus/with
```

Windows guest repo:

```text
C:\Users\Eric\with
```

Earlier Linux host source builds used the legacy compiler output layout:

```text
[stage1] wrote out/bin/with-stage1
[stage2] wrote out/bin/with-stage2
[build] wrote out/bin/with
```

The current source layout writes compiler artifacts by role:

```text
[stage1] wrote out/bootstrap/bin/with-stage1
[stage2] wrote out/stage/bin/with-stage2
[build] wrote out/release/bin/with
```

The latest regenerated bundle before the current source edits is:

```text
622ddfe918742bcf40af89f263ed8decc91c3bb4d667cf211c7405fd6dd8c2c6
out/release/with-bootstrap-c-v0.14.8.tar.zst
```

The previous bundle emitted invalid C in `regex_runtime.c` for address-of
pointer temporaries, for example:

```c
_28 = (&_16);
_29 = (uint8_t**)((uint8_t**)(_28));
```

where `_28` was declared as `uint8_t*`. The current source edit changes that
narrow declaration case to use `void*` for locals assigned the address of an
existing pointer/ref local.

## Source Fixes Already In This Session

- `src/CCodegen.w`: tuple C lowering now uses generated `with_tuple_N` structs
  instead of `int64_t`.
- `src/CCodegen.w`: tuple types are collected and emitted like other compound C
  types.
- `src/CCodegen.w`: `*c_void` lowers to real C `void*`.
- `src/CCodegen.w`: emitted bootstrap declarations include `with_memmove`,
  `with_memcmp`, `with_fiber_cleanup_await`, and `with_fiber_cancel`.
- `src/CCodegen.w`: address-like rvalues assigned into integer-shaped storage
  get explicit `intptr_t`/`uintptr_t` casts.
- `src/CCodegen.w`: locals assigned from address-of pointer/ref targets are
  declared as `void*` storage, not as the pointee pointer type.
- `runtime/unistd.h`: Windows bootstrap shim declares `gethostname`.

## Current Blocker

The Windows object compile now passes from regenerated source:

```text
compiled objects: 11
```

The former address-of pointer temporary blocker is resolved. The regenerated
`regex_runtime.c` now declares the `pcre2_jit_get_target` address temporary as:

```c
void* _3 __attribute__((unused)) = {0};
```

Resolved prior blocker:

```text
rt/regex_runtime.w:82: incompatible pointer types assigning to int32_t*
from const char* for _3 = (&_1.ptr[_2])
rt/regex_runtime.w:41: undeclared with_println_str
rt/regex_runtime.w:44: undeclared with_eprint
rt/regex_runtime.w:46: undeclared with_write
rt/regex_runtime.w:54: undeclared with_println_i32
rt/regex_runtime.w:57: undeclared with_println_i64
```

The missing `with_*` declarations are source-side bootstrap declaration gaps.
`git log`/`git blame` rationale:

- `584ef26d` added regex runtime declarations for #300, but only the
  regex-specific surface that failed then. The print/write symbols already
  exist in `runtime/with_runtime.h`; the runtime-object bootstrap compile path
  also needs those prototypes under `WITH_BOOTSTRAP_TYPES_H`.
- `98aa774a` fixed `Vec.ptr` field type inference in both `place_tid` and
  `place_text`; that is not the current string-index failure.
- `place_tid` has treated `str[index]` as `i32` since the early C backend,
  which is correct for the value read from a string byte. The current failure
  is address-taking: `place_text` emits `s.ptr[i]`, so `RK_REF`/`RK_ADDR_OF`
  must infer address-target storage, not reuse the value type.

Source edit added `place_ref_target_tid` and wires only
`RK_REF`/`RK_ADDR_OF` local inference to it. For address-of `str[index]`, it
returns pointer-shaped storage so local declaration falls back to `void*`
instead of `int32_t*`. The edit also adds bootstrap declarations for
`with_println_str`, `with_println_i32`, `with_println_i64`, `with_eprint`, and
`with_write`.

Current linker blocker:

```text
undefined symbol: with_alloc
undefined symbol: with_str_concat_n
undefined symbol: with_fs_remove_file
undefined symbol: rt_compat_setenv_str
...
```

Root cause found from source and generated C inspection: after `c_export`
removal, emitted runtime modules define public functions with mangled internal
names such as `with_alloc__209`, while other separately emitted modules call the
public ABI spelling `with_alloc`. The normal emit-C fixpoint path links against
prebuilt runtime objects, so it did not expose this. Windows emitted-C bootstrap
does compile runtime modules from emitted C, so public ABI-prefixed functions
must retain their declared spelling without using `@[c_export]`.

Current source edit changes `CCodegen.fn_c_name` so public functions whose names
are ABI-prefixed (`with_`, `rt_`, `wl_`, `migrate_`, `ci_`) emit the declared
symbol name. Private helpers remain mangled.

Follow-up `git log`/`git blame` rationale:

- `9af2f80a` moved Clang/LLVM bridge code off `@[c_export]` into normal
  compiler modules.
- `5604b9c5` changed bootstrap declaration discovery to scan the moved public
  bridge modules.
- Therefore, the public bridge wrapper signatures are the source of truth for
  bootstrap declarations. Wrappers assigned at call sites must declare `-> i32`;
  otherwise `wl_decls.h` emits `void` prototypes while emitted definitions and
  callers use `int32_t`.

Current source edit changes `with_cimport_mark_name_emitted`,
`with_cimport_reset_names`, `with_cimport_add_include_path`, and
`with_cimport_clear_include_paths` to return `i32` and return `0` for
side-effect-only success/early-exit paths.

The regenerated bundle then moved to C declaration conflicts caused by stale
extra bootstrap declarations:

- `with_str_from_cstr` and `with_str_from_bytes` were declared as `uint8_t*`
  even though `rt/rt_core.w` defines them as `*const u8`.
- `with_fiber_panic_capture` was declared as `uint8_t*` even though
  `rt/fiber_stubs.w` and `rt/panic_runtime.w` use `*const u8`.
- `with_memcpy`'s source parameter was declared as mutable `void*` even though
  runtime modules use `*const u8` for source buffers.
- `with_cimport_set_resource_dir` had no explicit return annotation, so the
  compiler inferred `u8` from its final buffer assignment while declaration
  scanning emitted a `void` prototype.

Current source edit mirrors those source signatures in `CCodegen.emit_module`
and explicitly marks `with_cimport_set_resource_dir(path: str) -> void`.

The next link attempt with the correct Windows object set eliminated duplicate
bridge/platform symbols but exposed `str_from_byte` and `i64_to_string` as
unresolved. `git log`/`docs/project-state.md` and `Link.w` show these are a
small non-prefixed runtime shim exception to the normal `with_`/`rt_`/`wl_`
runtime ABI naming rule. Current source edit adds exact stable C names for
the actual `rt_core.w` shims: `i32_to_str`, `i64_to_string`, and
`str_from_byte`.

## Next Steps

1. Run the native Windows stage chain from `with-bootstrap.exe`.
2. Run `with build :emit-c-fixpoint` on Windows.
3. Verify/import-check the final native `out\release\bin\with.exe`.
4. Commit source and runbook/status changes after acceptance evidence.

Completed:

- Synced source edits to the Linux host.
- Rebuilt the host compiler with the self-contained v0.14.8 seed.
- Regenerated `with-bootstrap-c-v0.14.8.tar.zst`.
- Copied and extracted the regenerated bundle on Windows.
- Compiled bootstrap C objects on Windows.
- Linked `with-bootstrap.exe` with `with-bootstrap.pdb`.
- Verified imports with `llvm-readobj --coff-imports`; no LLVM/Clang/MSVC
   runtime DLL dependencies.
- Ran bootstrap smoke checks.

## Progress Log

- 2026-06-05: Re-read `AGENTS.md` and `docs/project-state.md`.
- 2026-06-05: Confirmed host source build passes after latest
  `src/CCodegen.w` edit.
- 2026-06-05: Created this status document to avoid losing state or spinning in
  circles.
- 2026-06-05: Regenerated host bootstrap bundle from rebuilt host compiler:
  `622ddfe918742bcf40af89f263ed8decc91c3bb4d667cf211c7405fd6dd8c2c6`.
- 2026-06-05: Copied and extracted regenerated bundle on Windows. Confirmed
  `regex_runtime.c` now declares the formerly failing `_28` temporary as
  `void*` in that function.
- 2026-06-05: Windows object compile moved past the address-of pointer
  temporary blocker. New blocker is missing print/write runtime declarations
  plus one `int32_t*` vs `const char*` temporary assignment in
  `regex_runtime.c`.
- 2026-06-05: Used `git log`/`git blame` to identify the rationale for the
  existing code: normal string indexing is value-typed as `i32`, but
  address-taking needs separate ref-target inference. Added source-side
  `place_ref_target_tid` and missing bootstrap print/write declarations.
- 2026-06-05: Synced source edits to Linux host and verified
  `WITH=/tmp/with-v0.14.8-seed/with-linux-x86_64 with build` passes.
- 2026-06-05: Regenerated bootstrap bundle:
  `e6dff68f4344b1f7178d9e221225956218229b8174a6b24b86a8840f460bc134`.
- 2026-06-05: Copied/extracted the regenerated bundle on Windows and verified
  the formerly bad `pcre2_jit_get_target` temporary is now `void*`.
- 2026-06-05: Windows object compilation passed and produced 11 `.obj` files.
- 2026-06-05: Link reached real symbol resolution and exposed unmangled public
  ABI references versus mangled emitted runtime/bridge definitions. Added a
  source-side CCodegen rule for public ABI-prefixed function names.
- 2026-06-05: Used `git log`/`git blame` on the bridge migration commits.
  Confirmed the intended design is normal With bridge modules, not
  `@[c_export]`. Updated four side-effect bridge wrappers to return `i32`
  because bootstrap declaration scanning uses those source signatures.
- 2026-06-05: Regenerated bundle
  `281d35d13690885af27445168523e78253de642497199ff61451f4beca4b2f5b`.
  Windows object compile moved past previous bridge/ABI blockers and exposed
  stale const declarations for string/fiber/memcpy helpers plus inferred `u8`
  on `with_cimport_set_resource_dir`. Patched those in source.
- 2026-06-05: Regenerated bundle
  `96abbbd239652ad2d6e7e24f17b055ceb52bc4883f434a147e3ac3fbd449a605`.
  Windows object compile passed with 11 objects. Link showed the correct object
  selection is `with_compiler.obj` plus Windows platform/compat/runtime objects,
  not separate `llvm_bridge.obj`, `clang_bridge.obj`, or generic
  `compat_runtime.obj`. Added exact stable names for the non-prefixed
  `rt_core.w` string shims exposed by that link. A follow-up link proved
  `int_to_string` is not in that set because it is a stdlib helper emitted in
  multiple modules, so it remains mangled.
- 2026-06-05: Regenerated bundle
  `f28bf7d344719f70840fe1021d7b917437370ad05265a1441746c7647649fc0e`.
  Selected Windows object compilation passed with 8 objects. Linked
  `out\bootstrap-c-v0.14.8\with-bootstrap.exe` and
  `with-bootstrap.pdb`; import table contains only `ntdll.dll`,
  `ADVAPI32.dll`, `ole32.dll`, `SHELL32.dll`, `VERSION.dll`,
  `OLEAUT32.dll`, and `KERNEL32.dll`. Smoke checks passed for `--version`,
  `--help`, and `check test\hello.w`.
- 2026-06-05: Updated `docs/with-bootstrap-runbook.md` to document the proven
  Windows object selection and `ntdll.lib` link input.
- 2026-06-05: First native Windows `with build` from `with-bootstrap.exe`
  failed early in `compat-runtime-source` with `found no stdlib sources`.
  The checkout has `lib\std`; investigation showed the temporary
  `scripts/bootstrap/windows_platform.c` directory walker emitted backslash
  child paths while the native Windows runtime joins list-file paths with `/`.
  Patched the bootstrap C shim to emit forward-slash list-file paths.
- 2026-06-05: LLDB narrowed the remaining `compat-runtime-source` failure:
  `rt_list_files("lib/std")` returns bytes, `comptime_tool_split_nonempty_lines`
  returns the expected count, and materialization preserves whatever target
  inputs it receives. A scratch build project proved `ctx.fs().normalize` and
  `ctx.fs().list_files` normalized every relative path to `"."`. Generated C
  for `comptime_tool_path_normalize` skipped both `else if part != "."`
  branches, so normal path segments were never pushed. Patched
  `src/ComptimeEval.w` to route path segment handling through an early-return
  helper instead of nested `else if` control flow.
- 2026-06-05: Regenerated and linked `with-bootstrap.exe` plus
  `with-bootstrap.pdb`. Verified `SizeOfStackReserve: 67108864` and imports
  limited to Windows system DLLs; no LLVM/Clang/MSVC runtime DLL imports.
  Scratch `ctx.fs().normalize`/`ctx.fs().list_files` probe now emits real
  paths (`files/a.w`, `files/b.txt`) instead of `"."`.
- 2026-06-05: Native Windows `with build` reached the stage1 link. New blocker:
  `pthread_self`, `mkstemp`, and `realpath` were implemented in
  `rt/windows_x86_64.w` but emitted as module-prefixed symbols in
  `rt_windows_x86_64.o`; LLVM support also required `ntdll.lib` for
  `RtlGetLastNtStatus`. Patched source codegen to preserve exact link names
  for the Windows POSIX shim exports and patched Windows LLVM link metadata to
  include `ntdll.lib`.
- 2026-06-05: Regenerated from those fixes and reran native Windows
  `with build`. Stage1 linked successfully and wrote
  `out/bin/with-stage1.exe`. New blocker: output validation rejected declared
  command-directory extra output `out/command/stage1` because
  `with_fs_file_exists` used `rt_open`, which accepts directories on POSIX but
  not on Windows. Patched `rt/rt_core.w` to use `rt_access(path, 0)` so path
  existence is portable across files and directories.
- 2026-06-05: Regenerated from the `rt_access` fix. Stage1 again built and
  output validation passed, but stage2 failed to launch with exit
  `0xc0000135` (`-1073741515`). PE import inspection showed
  `out/bin/with-stage1.exe` imported `LLVM-C.dll`. Root cause:
  `run_generate_llvm_link_metadata_action` included `LLVM-C.lib` on Windows.
  Patched the metadata generator to exclude `LLVM-C.lib`; the manual bootstrap
  link already excluded it and remained self-contained.
- 2026-06-05: Reran without regenerating bootstrap because the LLVM metadata is
  produced from checkout source. Stage1 no longer imports `LLVM-C.dll`; imports
  are system-only. Stage2 then failed inside stage1 with
  `failed to create output directory './out/bin'`. Root cause:
  `fs_mkdir_component` only treated POSIX `-EEXIST` (`-17`) as success for an
  existing directory; Windows returns `-183`. Patched `rt/rt_core.w` to treat
  any mkdir failure as success when the path is now a directory.
- 2026-06-05: Rebuilt stage1 from the mkdir fix. Stage2 then crashed with
  `0xc0000005`. LLDB showed the fault at an `ntdll` prologue push with `rsp`
  on the guard boundary. PE header confirmed `with-stage1.exe` had only the
  default `SizeOfStackReserve: 1048576`. Patched the Windows lld-link command
  builder in `src/compiler/Link.w` to pass `/stack:67108864`, matching the
  bootstrap runbook/manual bootstrap link.
- 2026-06-05: Regenerated the bootstrap bundle from the `/stack` fix and
  rebuilt Windows bootstrap. Native Windows `with build` completed:
  `out/bin/with-stage1.exe`, `out/bin/with-stage2.exe`, and
  `out/bin/with.exe` were produced. Verified final `with.exe` imports only
  Windows system DLLs (`KERNEL32`, `ADVAPI32`, `ntdll`, `ole32`, `SHELL32`,
  `VERSION`, `OLEAUT32`) and has `SizeOfStackReserve: 67108864`.
- 2026-06-05: Split compiler binary outputs by role: bootstrap stage binaries
  now go under `out/bootstrap/bin`, intermediate stage/fixpoint binaries under
  `out/stage/bin`, and the final compiler under `out/release/bin`. Updated the
  runbook, Makefile seed resolution, Windows packaging default, and active
  project status to use `out/release/bin/with(.exe)` as the canonical final
  compiler path.
- 2026-06-05: `with build :emit-c-fixpoint` on Windows reached the emitted-C
  compile/link path, then failed because clang treated plain Windows `.lib`
  names as missing input files before `lld-link` could apply `/libpath`.
  Patched `build/emit_c.w` to pass explicit SDK/MSVC import-library paths for
  Windows emit-C links while keeping the final binary dependency gate based on
  PE imports.
- 2026-06-05: Deep-dived the `/stack:67108864` workaround. Root-cause evidence:
  the original stage2 crash is reproducible by editing `with-stage1.exe` back
  to a 1 MiB stack reserve; LLDB shows `rsp` on the stack guard boundary and an
  `ntdll` prologue push faulting below it. The same direct compiler invocation
  also crashes with 2, 4, 8, and 16 MiB reserves before reaching diagnostics.
  PE unwind metadata for `out/bootstrap/bin/with-stage1.exe` shows 60,633
  stack-allocating functions, 23 frames >= 64 KiB, 9 frames >= 128 KiB, 2 frames
  >= 256 KiB, and a largest frame of 465,704 bytes. The source root cause is
  the LLVM backend's MIR path: it lowers locals/temporaries to entry-block
  allocas, while the intended `mem2reg` cleanup is explicitly disabled in
  `src/CodegenDispatch.w` (`DISABLED: investigating whether mem2reg causes
  argument setup issues`, introduced by commit 261288cb). Linux and Darwin did
  not expose this because their runtime adapters already call
  `setrlimit(RLIMIT_STACK, 64 MiB)` from `with_raise_stack_limit()` at compiler
  startup; Windows' runtime adapter cannot increase the already-created main
  thread stack and the bootstrap C shim's `with_raise_stack_limit()` is a no-op,
  so the equivalent stack reserve has to be encoded by the linker in the PE
  header. `/stack:67108864` is therefore parity with the existing Linux/Darwin
  compiler behavior, but it remains a compiler-binary workaround for large
  generated frames, not a final runtime policy for user programs.
- 2026-06-05: Began source-side stack reduction instead of raising the Windows
  stack reserve. Added per-function LLVM cleanup through `sroa,mem2reg` with
  verification after MIR codegen. This reduces promotable entry-block allocas,
  but does not eliminate frames caused by large address-taken compiler state.
- 2026-06-05: Added `scripts/check-stack-budget.py` to read native unwind/frame
  metadata and fail when any function exceeds a configured frame budget. On PE
  files it uses `llvm-readobj --unwind`; this gives a stable measurement for
  Windows without relying on crash/no-crash alone.
- 2026-06-05: Split the LLVM MIR intrinsic dispatcher in
  `src/CodegenDispatch.w` into vector, map, scalar/vector, atomic/fiber, and
  ext helper families. Split the C backend builtin dispatcher in
  `src/CCodegen.w` into smaller builtin-family helpers. This removed the former
  largest `CCodegen.emit_builtin_call_term` frame: stage2's largest measured
  frame is now `Compilation.run_mir_lower` at 180,104 bytes.
- 2026-06-05: Changed compiler stack policy from 64 MiB to 8 MiB in
  `src/compiler/Link.w`, `build/emit_c.w`, and POSIX
  `rt_compat_raise_stack_limit()`. A source-built Windows stage2 now reports
  `SizeOfStackReserve: 8388608` and imports only Windows system DLLs.
- 2026-06-05: Reworked `ComptimeWorkspaceNativeCompileResult` so it no longer
  returns a full `Compilation` by value. It now carries a `*mut Compilation`
  allocated for the rare message-harvesting path and freed after use. This
  removes one large aggregate copy from workspace compile results.
- 2026-06-05: Current blocker after those reductions: `with build :fixpoint`
  still fails in `stage3-fixpoint-object` with `0xc0000005` under the 8 MiB
  stage2 compiler. LLDB again shows an `ntdll` prologue `pushq` fault, matching
  stack exhaustion. Manual PE reserve threshold testing on `with-stage2.exe`
  shows 12, 16, and 24 MiB still crash; 32 MiB gets past the stack crash and
  reaches ordinary compiler diagnostics. The remaining root cause is MIR
  lowering ownership: `MirBuilder` stores `Sema` by value and `lower_module`
  copies `Sema` per lowered function. The correct next fix is to make MIR
  lowering borrow or pointer-reference semantic context instead of embedding and
  copying it through builder values.
- 2026-06-05: Implemented the first MIR lowering ownership fix:
  `MirBuilder` is now ephemeral and stores `&Sema`, and `MirBody.init` borrows
  `Sema` instead of taking it by value. Also removed the local `var zcu =
  self.zcu` copy from `Compilation.run_mir_lower`; it now mutates `self.zcu`
  directly. Stage1 and stage2 both build after these changes.
- 2026-06-05: New measurement after the MIR ownership edits:
  `out/stage/bin/with-stage2.exe` has `SizeOfStackReserve: 8388608`; max
  measured PE unwind frame dropped from 180,104 bytes to 136,440 bytes. The
  direct stage3 fixpoint object compile still stack-crashes at 8 MiB, so the
  remaining work is not done. Current largest frames are `match_` from the
  embedded PCRE2 runtime, `Compilation.run_mir_lower`, `CCodegen` builtin
  helpers, `Codegen.mir_emit_*` helpers, `run_build_graph`, and Windows runtime
  helpers. The next source fixes should continue eliminating large by-value
  compiler/runtime aggregates and splitting remaining >64 KiB generated frames.

- 2026-06-06: Continued Windows stack root-cause work under the 8 MiB policy.
  Converted async lowering and no-await suspend checking to borrow `Sema`
  instead of copying it by value; stage2 still builds. Added a Rust-style MIR
  value-local scaffold, then disabled it after LLVM verification showed the
  partial implementation was unsound without dominance/PHI analysis (`is_alpha`
  used a value along a predecessor where it was not defined, and `dump_tokens`
  exposed ignored-call result handling issues). The correct future version must
  mirror rustc's `non_ssa_locals` analysis, including dominance and PHI/value
  merging, before replacing allocas with SSA operands.
- 2026-06-06: Moved Windows runtime copy/spawn scratch buffers off the C stack:
  `win_copy_file` now heap-allocates its 64 KiB copy buffer and
  `win_spawn_argv` heap-allocates the 32 KiB UTF-16 command-line buffer. This
  removed `win_copy_file` and `win_spawn_argv` from the >64 KiB frame list.
  Rebuilt stage2 successfully; PE imports remain system-only. Current measured
  stage2 frame summary: max 136,440 bytes; 12 frames >= 64 KiB; largest active
  compiler frames include `Compilation.run_mir_lower`,
  `Codegen.mir_emit_map_intrinsic_call`, `run_build_graph`,
  `Codegen.mir_emit_call_term`, `Codegen.mir_emit_scalar_vec_intrinsic_call`,
  and `lower_module`.
- 2026-06-06: `with build :fixpoint` still fails in `stage3-fixpoint-object`
  with `0xc0000005` at the 8 MiB PE stack reserve. LLDB stops at the stack guard
  fault in `ntdll` with `rsp` at the guard boundary but cannot unwind past the
  fault. Diagnostic stack-reserve testing on a copied stage2 binary shows the
  actual compiler invocation still crashes at 16 MiB and gets past stack
  exhaustion at 32 MiB, so this is still a real compiler stack-consumption bug,
  not a marginal policy mismatch. An attempted `-O1` stage-executable build was
  abandoned and reverted because it did not complete cleanly from the current
  bootstrap seed; fixpoint object targets remain `-O0`.
- 2026-06-06: Moved the remaining ordinary compiler codegen temporaries from
  block-local `wl_build_alloca(self.builder, ...)` to `create_entry_alloca(...)`
  in `src/Codegen.w` and `src/CodegenTraits.w`, matching the MIR-side entry
  alloca rule. This removed the Windows stack-probe/register-clobber class from
  the compiler codegen files; `rg "wl_build_alloca\\(self\\.builder"`
  returns no matches in `src/Codegen.w`, `src/CodegenDispatch.w`, or
  `src/CodegenTraits.w`.
- 2026-06-06: Rebuilt Windows stage1 and stage2 after the entry-alloca cleanup.
  Both passed, and `out/stage/bin/with-stage2.exe` still has the intended
  8 MiB stack reserve. The direct stage3 object compile still crashes:
  `out/stage/bin/with-stage2.exe build out/gen/main.w --emit-obj -O0 ...`
  exits `0xc0000005`.
- 2026-06-06: LLDB now consistently identifies the remaining crash in the
  frontend helper `exact_int_expr_value(lo: i64, hi: i64, negative: i32) ->
  ExactIntExpr`. At callee entry and at the call instruction in
  `AstPool.int_literal_exact_expr`, registers contain the non-sret argument
  convention (`rcx=lo`, `rdx=hi`, `r8=negative`) while the callee machine code
  is using the Windows large-aggregate return convention and treats `rcx` as
  the hidden return buffer pointer. The fault is therefore a With-to-With
  aggregate-return ABI mismatch, not the earlier stack-reserve failure.
- 2026-06-06: Tried an explicit internal-sret source experiment for normal
  large-struct-return functions plus `mir_build_raw_fn_type`. Stage1/stage2
  built, but stage3 then jumped into the middle of
  `AstPool.pattern_qualifier`, proving the experiment was incomplete and
  corrupted non-MIR/direct call paths. The experiment was backed out. The
  proper fix must be centralized: With-to-With function type construction and
  call emission need a single aggregate-return ABI path shared by MIR raw
  fallback, declared function values, AST/generic direct calls, closure thunks,
  and trait wrappers. Partial sret handling is worse than none.
- 2026-06-06: Rechecked the current tree after resuming. The bootstrap C seed
  and `out/bootstrap/bin/with-stage1.exe` both pass `check test\hello.w`, but
  the newly built `out/stage/bin/with-stage2.exe` crashes with `0xc0000005`
  on the same file. LLDB classifies this as control-flow corruption, not stack
  exhaustion: `rip=0x00007274735f746e`, which is data/string-looking bytes
  being used as an instruction pointer, with the stack showing parser callers.
  This means the current source changes let stage1 compile a corrupted stage2;
  the stage3 aggregate-return repro remains important, but the next immediate
  gate is restoring a sane stage2 baseline before trusting stage3-only
  failures.
- 2026-06-06: LLDB/root-cause update for the stage2 `hello` crash: the bad RIP
  bytes decode to `nt_str`, and the previous stack slots contain the ASCII
  halves of `with_print_str`. Disassembly of `Parser.intern_current` shows it
  passing a `str` argument to `InternPool.intern` as two registers
  (`rdx=ptr`, `r8=len`). On Windows x64 a 16-byte aggregate parameter must be
  passed indirectly, so the callee reads the first 16 bytes of the identifier
  text as a `str` struct (`ptr="with_pri"`, `len="nt_str"`), causing control
  flow corruption. Enabled the Windows x64 internal aggregate classifier:
  aggregate returns and parameters larger than 8 bytes use hidden sret or
  indirect parameter ABI. This is the same underlying ABI class as the earlier
  `ExactIntExpr` return failure.
- 2026-06-06: After the aggregate classifier, LLDB showed
  `Parser.intern_current -> InternPool.intern` using the correct indirect
  `str` parameter ABI, but `hello` still crashed by jumping to the data bytes
  `nt_str`. Disassembly moved the first bad value to `InternStringArena.store`:
  the generated `with_memcpy(dest, src, len)` passed `&dest_local` instead of
  the pointer value, and the returned `str.ptr` was likewise `&dest_local`.
  Root cause: MIR `RK_CAST` treated every pointer-target cast as a
  place-address cast before considering the source type. That is correct for
  aggregate/array place reinterpretation, but wrong for integer-to-pointer and
  pointer-to-pointer casts. Patched `src/CodegenDispatch.w` so only
  non-int/non-pointer source casts use `mir_try_place_ptr_for_ref`; integer and
  pointer source casts now flow to the normal value cast path.
- 2026-06-06: Rebuilt Windows stage1 and stage2 after the cast fix. Both
  passed. LLDB disassembly of regenerated `out/stage/bin/with-stage2.exe`
  confirms `InternStringArena.store` now passes the loaded arena destination
  pointer to `with_memcpy` and writes that pointer into the returned `str`,
  rather than taking the address of the stack slot. `llvm-readobj` still shows
  `SizeOfStackReserve: 8388608`. `scripts/check-stack-budget.py` still fails
  the 64 KiB frame budget (`max_frame=223368`, 23 frames >=64 KiB), so stack
  frame reduction remains open, but this transition fixed the classified
  pointer-cast/register-data corruption path.
- 2026-06-06: Short Windows gates after regenerated stage2:
  `out/stage/bin/with-stage2.exe check test/hello.w` passes, and
  `out/stage/bin/with-stage2.exe check test/codegen/large_aggregate_abi.w`
  passes. The previous `0xc0000005` is gone. The raw direct stage3 object
  command now exits with ordinary diagnostics about manual extern calls in
  `out/gen/main.w`; this is not a stack fault or control-flow corruption.
  Because `out/gen/main.w` is generated, the next step is to let the build
  graph regenerate it through `with build :fixpoint`, not hand-edit it.
- 2026-06-06: `with build :fixpoint` regenerated enough to reach LLVM function
  cleanup, then failed on `empty_test_discovery` with
  `unknown function pass '<garbage>' in pipeline '<garbage>'`. This is a
  normal diagnostic, not a crash. Root cause is another aggregate/string ABI
  bug in `src/compiler/LlvmBridge.w`: `wl_run_function_passes` passed a With
  `str` directly as `*const u8` to `LLVMRunPassesOnFunction`, so Windows could
  hand LLVM a pointer to the `str` value instead of a NUL-terminated C string.
  Patched the LLVM pass wrappers to call `to_cstr(...)` for pass pipelines.

## 2026-06-06 - LLVM pass pipeline C-string root cause

- Evidence: LLDB showed stage1 contains two `to_cstr` copies and both include the NUL terminator store. Stage2 contains a source-compiled `main.w` copy of `to_cstr` that calls `with_memcpy` and returns the buffer without storing the terminator; the separately linked `LlvmBridge.w` copy still contains the terminator.
- Classification: not stack and not ABI. This is an LLVM cleanup/codegen interaction: the source used integer pointer arithmetic for `*((dst as i64 + n) as *mut u8) = 0`, and the stage1-generated optimized copy dropped that store after the `sroa,mem2reg` cleanup.
- Source fix: changed `src/compiler/LlvmBridge.w` so `to_cstr` writes `cstr_bufs[slot][idx][n] = 0` through the typed buffer instead of pointer-int-pointer arithmetic.
- Next check: rebuild stage1/stage2, confirm stage2's active `to_cstr` contains the terminator store, then rerun the aggregate repro and fixpoint object.


## 2026-06-06 - Typed C-string terminator rebuild result

- Rebuilt `:stage1` and `:stage2` with the typed `cstr_bufs[slot][idx][n] = 0` terminator store.
- LLDB confirmed the active stage2 `main.w` copy of `to_cstr` now contains `movb $0x0, (...)` after `with_memcpy`; the separate `LlvmBridge.w` copy also contains the store.
- `llvm-readobj` reports stage2 stack reserve `8388608` and commit `4096`.
- `stage2 check test/hello.w` passed and `stage2 check test/codegen/large_aggregate_abi.w` passed.
- `scripts/check-stack-budget.py` still reports max frame `223368`, so large generated frames remain tracked debt, but this was not the pass-pipeline failure.


## 2026-06-06 - Post-C-string object checks

- `stage2 build out/tmp/abi-repros/aggregate_deref.w --emit-obj -O0` passed and produced `out/tmp/aggregate_deref_stage2.o`.
- Raw direct `stage2 build out/gen/main.w --emit-obj -O0` no longer crashes and no longer reports LLVM pass pipeline corruption; it now returns normal unsafe-context diagnostics for generated compiler source when invoked outside the build graph's compiler-build context.
- Next check is the actual build graph target `with build :fixpoint`, which supplies the intended compiler build context.


## 2026-06-06 - Windows fixpoint passed

- `WITH=out/bootstrap-c-v0.14.8/with-bootstrap.exe with build :fixpoint` passed on Windows and printed `FIXPOINT`.
- Classification: the previous stage3-fixpoint-object blocker is resolved. The last real blocker was not stack size or aggregate ABI; it was the optimized LLVM bridge C-string terminator store disappearing after pointer-int-pointer lowering.
- Remaining Windows acceptance checks: run `:emit-c-fixpoint`, inspect PE imports for stage2/final compiler, keep stack reserve at 8 MiB, then run Linux build gate from the same source changes.


## 2026-06-06 - Emit-C embedded string literal failure

- `with build :emit-c-fixpoint` built `out/release/bin/with.exe`, then failed compiling `out/emit-c-test/main.c`.
- Classification: emit-C source correctness failure, not stack/ABI/crash. The generated C emitted embedded stdlib globals as raw NUL/binary-looking C string literals, causing Clang `null character(s) preserved` warnings and an unterminated `WITH_STR_LIT` macro error.
- Root cause: `CCodegen.string_literal_node_payload_from_source` accepted any in-bounds `start..end` slice as a string token. For globals from generated/included modules, offsets could be interpreted against the wrong source text, producing garbage. The parser already interns string payloads, including raw strings with a marker, so the safe fallback is available.
- Source fix: added a string-token shape guard before using the source slice; if the slice is not a normal/f/raw string token, emit-C falls back to the interned literal payload.
- Next check: rebuild stage1/stage2, rerun `:emit-c-fixpoint`.


## 2026-06-06 - Stage2 rebuild crash after emit-C patch

- Rebuilding `:stage1` succeeded, but rebuilding `:stage2` crashed with `0xc0000005`.
- LLDB evidence: crash is in `with_arg_at` at `rt_core.w`, writing the returned `str` through `%rax`/hidden result buffer. Registers at fault included `rcx=0`, and the write target was `0x00000001`.
- Classification: aggregate-return ABI mismatch, not stack. `with_arg_at(idx: i32) -> str` is a 16-byte aggregate return across a module/runtime boundary; the callee expects a Windows x64 hidden sret/result pointer, while the caller path did not pass one consistently.
- Stop condition triggered: this is a broad ABI inconsistency. Do not add one-off patches around `with_arg_at`; generalize and wire the internal ABI model before editing more call sites.

## 2026-06-06 - Runtime extern ABI classification source fix

- Source change: added an explicit runtime extern classifier in `src/Codegen.w`. Unannotated `with_*` and `str_from_byte` extern declarations now use the same internal With aggregate ABI as normal With definitions. Extern declarations with an explicit call convention remain foreign/C ABI.
- Reason: `with_arg_at` is declared with `extern fn` in compiler sources but defined as ordinary With code in `rt/rt_core.w`; it is not a C FFI boundary. Treating that declaration as C ABI made callers return `str` directly while the Windows x64 callee expected hidden sret.
- Next check: rebuild stage1/stage2 with value locals disabled and 8 MiB stack policy, then rerun `stage2 check test/hello.w` and the stage3/fixpoint path.

## 2026-06-06 - Runtime extern unsafe classification on Windows paths

- After the runtime extern ABI classifier, a direct stage2 compile reported normal diagnostics for `with_arg_at`, `with_eprint`, etc.: `manual extern function call requires unsafe context`.
- Classification: semantic classifier bug, not stack and not a crash. `Sema.fn_symbol_is_manual_extern` already exempts compiler-owned runtime externs, but the path predicates only recognized `/out/gen/`, `/src/`, `/rt/`, and `/lib/std/`. Windows generated sources use backslash absolute paths such as `C:\Users\Eric\with\out\gen\main.w`.
- Source fix: extended the Sema path predicates in `src/SemaCheck.w` to recognize Windows backslash separators for runtime, stdlib, compiler source, and migrated regex paths.
- Next check: rebuild stage1 so the Sema fix is active, then rebuild stage2.

## 2026-06-06 - Build audit action hang

- `with-bootstrap.exe build :stage1` repeatedly spun for 5 minutes before launching any child compiler. LLDB showed the bootstrap C seed executing a comptime build action, and the repo lock identified the target as `compiler-no-c-export`.
- Classification: build-action/comptime hang, not stack and not a stage compiler crash. The audit target already receives all source files as declared inputs, but the action re-walked `src`, `rt`, and `lib/std` with `ctx.fs().list_files(...)`.
- First source fix: changed `run_check_compiler_no_new_c_export_action` in `build/compiler.w` to scan `ctx.inputs()` instead of performing a second filesystem walk during action evaluation.
- Follow-up evidence: the target still hung in the bootstrap C seed's comptime evaluator while scanning source text, even with a byte-level scanner. LLDB stayed in comptime binary/string evaluation, not a child compiler process.
- Source fix: moved the audit body to `scripts/check-no-c-export.py` and made the build action invoke it through `ctx.process_runner()`. The target now declares the script input and `out/command/compiler-no-c-export` write scope.
- Result: `with-bootstrap.exe build :compiler-no-c-export` passes and updates `out/.build-state/compiler-no-c-export.txt`.
- Next check: retry `:stage1`.

## 2026-06-06 - Stage2 rebuild DEP crash after Sema path fix

- `with-bootstrap.exe build :stage1` passed after the Windows path predicate fix, producing `out/bootstrap/bin/with-stage1.exe`.
- Direct stage2 rebuild with `out/bootstrap/bin/with-stage1.exe build C:\Users\Eric\with\out\gen\main.w -O0 -o out\stage\bin\with-stage2.exe.tmp` exits `0xc0000005` with no stdout/stderr.
- LLDB classification: not stack. The crash is a DEP violation at the loaded PE image base, `rip=rax=rcx=0x00007ff63d0f0000`, and `image lookup` resolves that address as `with-stage1.exe + 0` (PE header), not executable code. This is a bad indirect target/control-flow corruption.
- The nearest plausible caller address on the stack is `MirModule.mir_resolve_alias + 66`, immediately after its call to `MirModule.mir_get_type_kind`. Disassembly shows `mir_get_type_kind` receives `MirModule` indirectly and calls `with_vec_len`/`with_vec_get_ptr` on the `sema_type_kinds` Vec. Early breakpoints on those runtime vector calls show valid Vec-looking data, so the failure is not currently classified as the old block-local alloca/register-clobber class or a simple vector runtime declaration mismatch.
- Current hypothesis: the remaining ABI model is still too fragmented. Several direct/generic/closure/trait call paths build `wl_build_call` from `fn_fn_types` and `coerce_call_args_for_fn_value` without one canonical internal ABI call helper, while MIR and declarations consult the `extern_fn_*` ABI transform maps differently. Continue by identifying the exact bad indirect call before editing, then centralize internal ABI consumption instead of adding a one-off sret patch.

## 2026-06-06 - Function fat-pointer and string-concat ABI fixes

- Added `Codegen.build_call_fn_value(...)` so direct/generic call sites can share sret, indirect aggregate parameter, and call-attribute handling instead of pairing `coerce_call_args_for_fn_value(...)` with raw `wl_build_call(...)`.
- Root cause found in `test/codegen/large_aggregate_abi.w`: when a function constant was passed to a `fn(...) -> T` parameter, the Windows indirect aggregate path treated the raw code pointer as if it were already a pointer to the fat `{fn, ctx}` value. The generated IR called `call_big(..., ptr @make_big)`, and the callee loaded `{fn, ctx}` from the first bytes of the function body. Fixed MIR and direct byval lowering so indirect aggregate arguments are passed through a real aggregate buffer, and function constants materialize a thunked fat value when the expected type is a fat function value.
- Added `test/codegen/regex_literal_code_abi.w` as a focused repro for the `Regex.__literal_code` shape. The simpler pointer-store form passes; adding the panic string-concat path pointed at the full compiler crash site.
- `WITH_DEBUG_MIR_CODEGEN=1` narrowed the full stage2 crash to `Regex.__literal_code`, block 13, assignment statement 21, a `RK_BIN_OP` string concatenation. Root cause: `mir_str_concat` and `mir_str_concat_n` bypassed the ABI model and emitted raw calls to `with_str_concat*`. On Windows these return `str` via hidden sret and take `str` parameters indirectly. Patched both helpers to use `build_call_fn_value(...)` and to create fallback declarations with the internal ABI when no declaration exists yet.

## 2026-06-06 - Format runtime ABI island fixed

- After the string-concat ABI fix, the direct stage2 rebuild no longer crashed, but LLVM verification failed after MIR cleanup for `type_key_pack1`.
- Classification: invalid IR from another raw aggregate ABI island, not stack and not control-flow corruption. The dumped function showed `call %str @with_fmt_i32(i32 ...)` and `call void @with_fmt_buf_write_str(ptr ..., %str ...)`, which are invalid for the Windows internal ABI because `str` returns use hidden sret and `str` parameters are indirect.
- Source fix: added `ensure_internal_runtime_fn(...)` / `call_internal_runtime_fn(...)` and routed the `with_fmt_*` format-runtime helpers through `build_call_fn_value(...)`, including `with_fmt_i32`, `with_fmt_*_spec`, `with_fmt_buf_write_str`, and `with_fmt_buf_finish`.
- Result: rebuilt stage1 successfully, then the direct command `out/bootstrap/bin/with-stage1.exe build out/gen/main.w -O0 -o out/stage/bin/with-stage2.exe.tmp` passed. The only output was lld-link warnings about DWARF section names longer than 8 characters.
- Next check: run the build graph `:stage2`, then the direct stage3 object command and `:fixpoint`.

## 2026-06-06 - String equality ABI fixed

- Build graph `:stage2` passed after the format-runtime ABI fix, with stack reserve still `8388608`.
- The direct stage3 object command then crashed in `with_str_concat_n` from the unknown-command branch in `run_cli`. LLDB showed this was not stack: `rip=with_str_concat_n`, and the `parts` pointer was invalid. The surprising caller was `run_cli` line 738, meaning `cli_command(argc) == "build"` had evaluated false even though argv[1] was `build`.
- Classification: internal ABI mismatch in the compiler-generated string equality helper. `ensure_with_str_eq_declared` constructed `with_str_eq(%str, %str) -> i32` and `compare_str_eq` called it directly. On Windows, `str` parameters for compiler-owned runtime functions are indirect aggregate params.
- Source fix: `with_str_eq` now declares through `ensure_internal_runtime_fn(...)` and calls through `build_call_fn_value(...)`.
- Result: rebuilt `:stage1` and `:stage2` successfully. Next check is the direct stage3 object command.

## 2026-06-07 - Runtime ABI classifier and embedded runtime refresh

- After relinking stage2 with a refreshed `rt_core.o`, simple CLI checks exposed more internal ABI islands rather than stack faults.
- `version` initially exited through the unknown-command path because the linked stage2 used a stale embedded runtime object. `out/lib/rt_core.o` had ABI-correct `with_arg_at`, but `out/lib/embedded_objects.o` still embedded the older raw-return runtime. Regenerated the embedded runtime bundle from current object inputs.
- Rebuilding stage1 after that failed because the old bootstrap seed prefers `out/lib` over `out/bootstrap-lib`; with `out/lib/cimport_stubs.o` present, stage1 linked the stage2 ABI runtime even though the bootstrap compiler still emitted raw calls for its own CLI. Removed the `out/lib` probe before stage1 so the existing `prepare-bootstrap-link-root` rule made stage1 use bootstrap-compatible runtime artifacts.
- A forced stage2 relink then failed with undefined `with_*` symbols. Root cause: `codegen_is_runtime_source_file(...)` only recognized `/` paths, so direct Windows object builds such as `rt\\rt_core.w` were treated as ordinary module objects and renamed runtime definitions to `__with_mod_*`. Source fix: recognize Windows backslash runtime and generated compat-runtime paths.
- `check test/hello.w` then faulted in `i64_to_string`, with the caller passing `rcx=1` instead of a hidden return buffer. Root cause: `i64_to_string` is a compiler-owned runtime ABI symbol but did not start with `with_`, so extern/runtime call classification missed it. Source fix: `codegen_extern_uses_internal_abi(...)` now delegates to the full `codegen_is_runtime_abi_symbol(...)` predicate.
- Refreshed stage2 runtime objects with stage1 using the build graph object flags (`--emit-obj --no-prelude`), regenerated `out/lib/embedded_objects.s`/`.o`, and forced `:stage2` to relink.
- Result: `out/stage/bin/with-stage2.exe version` passed, `out/stage/bin/with-stage2.exe check test\\hello.w` passed, `llvm-readobj` reports `SizeOfStackReserve: 8388608`, and the direct stage3 object command `out/stage/bin/with-stage2.exe build out/gen/main.w --emit-obj -O0 -o out/stage/bin/with-stage3-fixpoint.o.tmp` passed.
- `WITH=out/bootstrap-c-v0.14.8/with-bootstrap.exe with build :fixpoint` passed and printed `FIXPOINT`.
- Next check: run `:emit-c-fixpoint`.

## 2026-06-07 - Emit-C intern pool root cause

- Rebuilt Windows stage1/stage2 and re-ran the short gates after the C backend
  string-literal guard. `stage2 version`, `stage2 check test\hello.w`,
  stage2 stack reserve `8388608`, direct stage3 object, and `:fixpoint` all
  passed.
- `:emit-c-fixpoint` still failed compiling `out/emit-c-test/main.c` with raw
  NUL bytes in `__with_global_EMBEDDED_STD_0__...`, so the failure remained an
  emit-C source correctness bug, not stack, ABI, or control-flow corruption.
- Root cause: `Compilation.emit_c` passed `self.zcu.pool` into `c_emit_module`,
  while the LLVM backend already switches to `self.zcu.last_sema.pool` after
  semantic analysis. In the full compiler, imported/generated module string
  literal symbols were resolved against the wrong intern pool, producing
  pointer/length-looking binary garbage. Standalone `EmbeddedStdlibData.w`
  emit-C did not expose this because its root pool contained the needed symbols.
- Source fix: make emit-C use `self.zcu.last_sema.pool` when populated, matching
  the LLVM backend handoff. Keep the guarded source-token literal path as a
  second protection for globals whose source text is available.
- Follow-up evidence: direct `out/release/bin/with.exe build out/gen/main.w
  --emit-c` produced valid C with zero raw NULs, but `with build
  :emit-c-fixpoint` still produced raw NULs.
- Deeper root cause: `run_emit_c_test_action` used `Workspace.compile()` for
  the first compiler C emission. During `with build`, that workspace compile is
  executed by the bootstrap seed running the build action, not by the rebuilt
  release compiler under test. The seed does not contain the Windows emit-C
  fixes, so it regenerated corrupted C even though the candidate compiler was
  correct.
- Source fix: make `run_emit_c_test_action` invoke the candidate compiler path
  through `emitc_build_compiler_c(ctx, compiler_path, main_c)`, matching the
  fixpoint invariant.
- Next check: clean `out/emit-c-test` and rerun `:emit-c-fixpoint`.

## 2026-06-07 - Emit-C value-ref pointer argument classification

- After the build action fix and a stage2 relink, `stage2 version`,
  `stage2 check test\hello.w`, direct stage3 object, and `:fixpoint` passed.
- Clean `:emit-c-fixpoint` no longer generated raw NULs in
  `out/emit-c-test/main.c`; a byte check reported zero NUL bytes in the C file.
- New failure classification: normal C compiler diagnostic in emitted C, not
  stack, ABI crash, or register clobber. Clang rejected calls such as
  `Sema_can_auto_ref_arg(&((*_1).sema), ...)` because `MirBuilder.sema` is
  already emitted as `const Sema*`, so taking its address produces
  `const Sema**` for a value-ref ABI parameter represented as `Sema*`.
- Root cause: `CCodegen.call_args_text` knew when a callee parameter is lowered
  as a C pointer for value-ref ABI, but it always emitted `&arg`. That is only
  valid when the argument expression is a struct value. If the MIR operand is
  already a pointer/ref value, the correct C argument is the operand itself.
- Source fix: added `operand_is_pointer_value(...)` and used it in the
  value-ref pointer-parameter branch so already-pointer operands are passed
  unchanged; non-pointer aggregate values still pass by address.
- Next check: rebuild Windows stage1/stage2 from source, then rerun the direct
  stage3 object, `:fixpoint`, and `:emit-c-fixpoint`.


### 2026-06-07 Cross-Host Generated Source Recheck

- Compared Windows `out/gen/main.w` against Linux `out/gen/main.w` after LF normalization. Initial remaining divergence was only the embedded version string: Windows used `v0.14.8`; Linux, without `WITH_VERSION`, used the Git-derived `v0.14.8-ge4aa059f6`.
- Re-ran Linux `:compiler-sources` with `WITH_VERSION=v0.14.8`; Linux `out/gen/main.w` now matches Windows exactly: size `127403`, SHA-256 `fc3b1d204d12230d93412eb152614fb742243ce46043dd00dd4fb5c7333bcb1a`, LF-only.
- Classification: build metadata/environment mismatch, not compiler/codegen divergence. Next frontier is byte-for-byte comparison of emitted C generated from the matching `out/gen/main.w` on both hosts.


### 2026-06-07 Windows Emitted-C Regeneration

- Regenerated Windows emitted C from matching `out/gen/main.w` using `out/stage/bin/with-stage2-candidate.exe`.
- Result: `out/emit-c-test/main.c` size `31702785`, SHA-256 `ca333406407c85a0df49bb8d545b8adfe769720f60d009723ced5baf246e8391`, LF-only, zero raw NUL bytes.
- Next command: copy this C to Linux, rebuild `out/bootstrap/bin/with-from-c` with `.deps/llvm-22.1.6-linux-x86_64/bin/clang++`, then emit Linux C for byte comparison.


### 2026-06-07 Stale Windows Candidate Detected

- Attempted to compile the Windows-emitted C on Linux with SDK `clang++`; compile failed at `#line "C:\Users\Eric\with\out\gen\main.w"` because backslashes in C line directives are interpreted as escapes.
- Classification: stale Windows emitter binary was used for regeneration; source has a canonical `#line` path fix, but `out/stage/bin/with-stage2-candidate.exe` did not contain it.
- Next command: regenerate emitted C with the rebuilt comparison compiler that contains the CCodegen `#line` canonicalization, then verify absence of `C:\` line directives before rebuilding the Linux C seed.


### 2026-06-07 Canonical-Line Windows Emitted C

- Regenerated Windows emitted C with `out/tmp/with-canonical-lines.exe`, which includes the CCodegen `#line` path canonicalization.
- Result: `out/emit-c-test/main.c` size `30671626`, SHA-256 `c3fb10097db77932aee86637f7e4c95b7e48019d4f7edd4df6bf65e5e7ab26fd`, LF-only, zero raw NUL bytes.
- First line directive is `#line 68 "out/gen/main.w"`; no backslash `\out\gen` directives remain.
- Next command: copy this C to Linux and rebuild the Linux C seed with With-owned SDK Clang.


### 2026-06-07 Linux C Seed Rebuilt

- Rebuilt Linux `out/bootstrap/bin/with-from-c` from the current Windows-emitted C using `.deps/llvm-22.1.6-linux-x86_64/bin/clang++`.
- Command linked successfully and `./out/bootstrap/bin/with-from-c version` reported `with v0.14.8`.
- Used that seed to regenerate Linux `out/emit-c-test/main.c`; emission completed. The remote stats snippet failed due shell quoting only, so the emitted C is being copied back for local byte comparison.


### 2026-06-07 Source Line-Ending Determinism Fix

- New cross-host emitted-C diff after fixing generated `main.w`: code aligned, but `#line` numbers diverged at imported module code (`src/Span.w`). Windows workspace has CRLF in `src/Span.w`; Linux has LF. Parser spans are byte offsets, so CRLF changed imported-module span offsets and therefore emitted C line directives.
- Source fix applied: frontend source ingestion now normalizes CRLF and bare CR to LF before lexing/parsing root sources, extra sources, resolved imports, and import expansion. Resolve import parsing also normalizes source text before lexing/parsing.
- Classification: source ingestion/span determinism bug, not stack/ABI/MIR-value-local. Next command: rebuild a fresh Windows comparison compiler containing this fix, regenerate Windows emitted C, sync to Linux, rebuild Linux C seed, and compare emitted C bytes again.


### 2026-06-07 Windows Emitted C After Source Normalization

- Built fresh Windows comparison compiler `out/tmp/with-source-normalized.exe` from current source: PASS, `with v0.14.8`.
- Regenerated Windows emitted C with that compiler. Result: `out/emit-c-test/main.c` size `30686907`, SHA-256 `296ebbe9a72ef6d7b711f1e1a3eb04f33b0f9cad0012c361ccf3077ee773238f`, LF-only, zero raw NUL bytes.
- First line directive remains canonical: `#line 68 "out/gen/main.w"`.
- Next command: rebuild Linux C seed from this C and rerun the Linux emitted-C comparison.


### 2026-06-07 Linux Re-Emit After Source Normalization

- Rebuilt Linux `out/bootstrap/bin/with-from-c` from the normalized Windows emitted C with SDK `clang++`: PASS, `with v0.14.8`.
- Regenerated Linux `out/gen/main.w` with `WITH_VERSION=v0.14.8`: PASS.
- Regenerated Linux `out/emit-c-test/main.c`: PASS.
- Next command: copy Linux emitted C back to Windows and compare bytes against Windows `out/emit-c-test/main.c`.


### 2026-06-07 Cross-Host Emitted C Match

- Copied Linux emitted C back to Windows and compared against Windows `out/emit-c-test/main.c`.
- Result: MATCH byte-for-byte. Both files size `30686907`, SHA-256 `296ebbe9a72ef6d7b711f1e1a3eb04f33b0f9cad0012c361ccf3077ee773238f`, LF-only, zero raw NUL bytes.
- Source fix applied: `build/emit_c.w` now defaults to the With-owned LLVM SDK `bin/clang` on Linux/macOS/Windows when no explicit `WITH_EMIT_C_CC`/`CC` is set; this matches the Clang-only bootstrap rule.
- Next command: run Linux `:emit-c-fixpoint` using the rebuilt C seed to prove the emitted C roundtrip on Linux.


### 2026-06-07 Linux Emit-C Fixpoint Link Metadata Failure

- Linux `:emit-c-fixpoint` failed during stage1 link with `ld.lld: error: unable to find library -lzstd`.
- Host inspection: `/usr/lib/x86_64-linux-gnu/libzstd.so.1` exists but unversioned `libzstd.so` does not; `/tmp/with-link-libs` symlink workaround existed only for manual C-seed linking.
- Classification: generated LLVM link metadata used `-lzstd` even though the direct Linux link-stage code already has versioned-library fallback logic.
- Source fix applied: `build/compiler.w` now emits concrete Linux system library paths for z/zstd/xml2 when unversioned linker names are unavailable.
- Next command: rerun Linux `:emit-c-fixpoint`.


### 2026-06-07 Linux Emit-C C++ Driver Failure

- Rerunning Linux `:emit-c-fixpoint` after the zstd metadata fix built stage1, stage2, and release, then failed during emitted-C compiler link with many unresolved C++ standard-library symbols from static LLVM/Clang archives.
- Classification: emit-C wrapper used `clang` as the C driver while linking C++ LLVM/Clang archives. The generated source still must be compiled as C, but the link driver must be Clang's C++ driver.
- Source fix applied: `build/emit_c.w` now defaults to SDK `clang++` and wraps generated C inputs as `-x c <file.c> -x none`, including the hello C compile path.
- Next command: rerun Linux `:emit-c-fixpoint`.


### 2026-06-07 Linux Emit-C Linker Driver Correction

- Rerunning after the `clang++ -x c` fix still failed during emitted-C link, and diagnostics showed `/usr/bin/x86_64-linux-gnu-ld.bfd` was used.
- Manual Linux C-seed build had already proven `clang++ -fuse-ld=lld` works for this link shape.
- Source fix applied: Linux emit-C compile flags now include `-fuse-ld=lld`, matching the proven manual command.
- Next command: rerun Linux `:emit-c-fixpoint`.


### 2026-06-07 Linux Emit-C Fixpoint Green

- Reran Linux `:emit-c-fixpoint` with `WITH_VERSION=v0.14.8`, `LLVM_PREFIX=.deps/llvm-22.1.6-linux-x86_64`, and `WITH=out/bootstrap/bin/with-from-c`.
- Result: PASS. The build wrote Linux stage1, stage2, release compiler, then reported `EMIT-C OK` and `EMIT-C FIXPOINT`.
- Current isolation state: Windows and Linux emit identical `out/emit-c-test/main.c` bytes from matching `out/gen/main.w`; Linux emit-C fixpoint passes. Any remaining failure is now Windows-side compile/link/runtime execution, not cross-host C emission.
- Next command: rebuild Windows stage1/stage2 from current source, then run Windows direct stage3 object, `:fixpoint`, and `:emit-c-fixpoint`.


### 2026-06-07 SDK CMake Packaging Rule

- Release-tooling correction: LLVM may use CMake, but CMake and its generator
  backend must be With-owned SDK tools after the first bootstrap. Source scripts
  now build Ninja and CMake from pinned source into `LLVM_PREFIX/bin/`, and
  `tools/build-static-llvm.{sh,ps1}` requires SDK CMake plus SDK Ninja for LLVM
  configuration/build.
- Package scripts now require and include SDK CMake plus LLVM utility tools:
  Unix packages include `bin/ninja`, `bin/cmake`, and `bin/llvm-strip`;
  Windows packages include `ninja.exe`, `cmake.exe`, `clang-cl.exe`, and
  `llvm-strip.exe` in addition to the existing Clang/lld tools.
- Classification: SDK hermeticity/policy bug, not compiler codegen. Do not
  use host Ninja, Make, MSBuild, or a Visual Studio generator for repeat SDK
  production.
