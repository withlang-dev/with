# Handoff — the .wo bundles / stdlib-sourcing campaign

## Current integration (2026-09-12)

PCRE2 C4 (#1101), SDK-macro hygiene (#1107), target-correct va_list
(#1108), and zlib (#1103) have merged. Main is `17109853`. Their old blockers below are
historical, not current instructions to reproduce them again.

Zlib #1103 was integrated in the `zlib-1103-ready` worktree and merged.
The merge keeps main's populated stage2/stage3 embedding object and adds
both bundles to it; only stage1 uses empty bundle slots. The renamed
`std.zl` corpus retains the macro-hygiene and c_va_list re-promotion.
The separate follow-ups preserve c_va_list in `.wi` signatures and check
all required reference files before marking an extracted zlib tree ready.
Main already contains the newer gunzip ownership and input-limit fixes.

Verification for this integration is recorded in
`out/zlib-1103-validation/` in the worktree and the #1103 PR description.
Historical passing batteries below do not certify the integrated commit.
Required checks: re-migration comparison, full build, fixpoint, compiler
audit, full tests including both bundle drift lanes, move/drop audits,
fresh pinned-seed compatibility, test-green and last-green.

The next campaign milestone after #1103 is sourcing Phase 0 (inventory,
complexity fixtures, SlotMap free list), then c-algorithms, TommyDS, STC,
and the M*LIB B+ tree subset. #1106 remains the explicit callable-type ABI
descriptor gap for affected indirect va_list calls; #1113 tracks missing
seed-compat cache inputs, so use fresh bootstrap evidence.

## Historical investigation (2026-09-08–09)

**C4 landing update:** the local A/B performance gate is now green on the
rebased landing tree. After excluding the initial pair, the two uncached
warm pairs were 263.9/268.7 s (C4/baseline 1.018) and 275.6/284.3 s
(1.032); baseline passed 985 files and C4 passed 986 in every run.
`docs/wo_bundles.md` records the measured table. Main's handoff-only changes
have been merged into `wo-c4`. The first battery passed build (164.5 s),
fixpoint (276.6 s), and move audit (15 cells), then caught an audit-generator
defect: 113 probes redeclared private allocation symbols with obsolete
pointer types. LLDB observed the return signature replacement in
`Sema.collect_extern_fn` → `Sema.add_sig` (symbol 32, return 81 → 20).
The generator now uses `std.mem.alloc/free_mem` and retains each side's
diagnostics separately; all 115 drop cells pass against the pinned seed
(102.6 s). The next battery passed build (157.3 s), fixpoint (266.9 s),
and `audit:all` (2,504,943 facts, zero violations), but the test survey
failed only `bundle-interface-tests` (58 other targets green; 728.2 s).
The reduced consumer was just `use std.wi_demo`: LLDB observed
`interface_line_name("impl Pair:", 2)` returning an empty string, then
`parse_interface_chunk` receiving its indented methods without the impl
header. The merge now demands whole declarations, keeping leading
attributes and indented bodies with their header, and names inherent
impls by their target. The development compiler (78.9 s) passes the
reduced import and original consumer. Expanded fixtures verify an unused
attributed type and a demanded packed type: emitted interface and
source/interface fingerprints agree, and the consumer reads 42 from a
five-byte packed value. The full interface lane then passed (18.5 s action,
246.8 s total), fixpoint passed (298.2 s), and `audit:all` reported
2,505,391 facts / zero violations. The full emit-C lane exposed #1043's
two const-field resets as a native MIR bug too: `var text = h.text` through
`&Holder` printed `abc` then an empty source. LLDB observed
`lower_let_binding` restore expected_type to Unit (14) before revisiting
the original AST and queuing a reset for borrowed field place 7.
`90d4858c` removes that redundant cancellation; assignment already consumes
the actual lowered operand. Native output is now `abc` twice, emitted C
passes syntax checking, and all 15 move / 115 drop audit cells pass.
The silent read-only-store audit gap is #1096; the documented but ignored
`--emit-llvm` flag is #1097 (use LLDB disassembly until it exists).

The same review resolved #1036's exact allocation sites: the 2048-byte
table comes from `pcre2_maketables_8`, the 256-byte code from
`pcre2_compile_8`. LLDB observed `detect_drop_functions` skip Regex's
ordinary impl (trait 0 versus Drop 78). The facade now registers
`impl Drop for Regex`, uses PCRE2-managed table ownership, and releases
temporary compile tables on success and failure. #1098 was exposed in the
same path: LLDB saw code free and named capture lookup use the identical
pointer after explicit `re.drop()`. Captures now own a code copy and have
their own Drop. The new lifetime fixture goes from 16 leaks to zero;
escaped clones/captures and both existing regex behavior suites pass with
stage1 (109.5 s development build).

The `6d54088b` battery then passed build (289.4 s), fixpoint (322.6 s),
audit:all (2,505,774 facts / zero violations), the full emitted-C bootstrap
(356.1 s, including C compiler version and hello execution), 15 move cells,
and 115 drop cells. Its full test survey (1132.0 s) failed only
`behav_d27_view_nll_before_owner_consume.w` among 987 behavior files; other
targets passed. #1099 is the exact cause: function setup and closure
rollback popped six borrow columns but omitted scope-depth and creation-
site metadata. LLDB saw refs/depth/site lengths 1/1/1 become 0/1/1, then
the NLL expiration branch skip stale depth 2 in current scope 3. Both
cleanup loops now use complete-row removal, and a column-length invariant
catches this corruption. Stage1 (95.4 s) passes the original regression,
NLL scoping, closure capture, and genuine dangling-view rejection. A With
comparison reducer predicate kept baseline acceptance while minimizing;
the diagnostic-only reducer's noisy result is tracked as #1100.

The next step is the final battery on the committed corrections, including
the full `:emit-c-test` lane, using `out/release/bin/with` for every
post-build step. Logs are under `out/c4-validation/` in `c4r`; `STATUS.md`
there distinguishes current results from prior batteries.
Debugger launches now work; a disabled DevToolsSecurity status did not
establish an authorization blocker, and no approval popup was seen.
Do not repeat the performance gate or
use the earlier quiet-box requirement below; the local ratio ruling

## Historical snapshot — the zlib `.wo` bundle and the ABI/bundle blocker chain (2026-09-09)

The following preserves the September 9 investigation. Its open blockers and
next-step instructions are historical; the current integration update above
supersedes them.

This is a complete state dump for an agent picking up the `.wo` bundles /
stdlib-sourcing campaign. It is long on purpose: read it all before touching
anything. The headline is a **real, unsolved macOS bug** (section 1) that
gates two PRs, plus a **three-deep dependency chain** of ABI/migrator fixes
(section 2). Everything is on branches/worktrees; `main` is untouched.

Author/commit rules (do not violate): commits are `Eric Hartford
<eric@quixi.ai>`, never any other identity, never `lazarus.enterprises`; no
attribution/co-author trailers. Never `git stash`. No Python/bash/perl/sed/awk
for scripts or transforms — use With one-liners (`with -p`/`-n`/`-e`). Never
`-O0`. Only Eric blesses spec wording. The Bash tool's shell is **zsh** (an
unquoted `$OPTS` holding several flags is ONE argument and gets silently
dropped — spell flags out).

---

## 0. Branches, worktrees, PRs, issues (verified 2026-09-09 ~18:30Z)

| Branch  | Worktree                          | Tip       | Meaning |
|---------|-----------------------------------|-----------|---------|
| main    | `~/with`                          | a2df2115  | untouched baseline |
| wo-c4   | `~/.local/with-staging/c4r`       | 7910cf98  | **PR #1101** (C4: retire regex shim). Eric-finished; +my CI diagnostics |
| zlib-wo | `~/.local/with-staging/zlibwo`    | 61f1e301  | **PR #1103** (zlib `.wo` bundle), stacked on wo-c4 |
| va-list | `~/.local/with-staging/valist`    | 71b7467c  | **#1104** va_list ABI fix, off wo-c4. WIP, does not build yet |

- **PR #1101** (wo-c4): `linux aarch64/x86_64` + `windows aarch64/x86_64` GREEN;
  **`macOS arm64` FAILURE** (section 1). This is the ONLY thing blocking C4.
- **PR #1103** (zlib-wo): `linux aarch64` + both `windows` GREEN (the Windows
  `fcntl` fix worked); **`macOS arm64` FAILURE** (same bug, section 1);
  **`linux x86_64` FAILURE** (= #1104 va_list crash, section 2).
- **#1102** OPEN — migrator leaks host SDK macros into shared defs.
- **#1104** OPEN — va_list modeled as a pointer on every target.

Landing order intended: fix macOS bug → #1102 → #1104 → C4 (#1101) → #1103.
The macOS bug (section 1) must be solved first; it blocks BOTH #1101 and #1103.

---

## 1. THE BLOCKER: macOS embedded-bundle bug (unsolved, not reproducible locally)

### What fails

Both `wo-c4` and `zlib-wo` fail the `macOS arm64` CI lane on the **same two
tests**, deterministically (three reruns, identical):

1. **`selfcheck`** corpus test = `out/stage/bin/with-stage2 check src/main.w`.
   Errors:
   ```
   let stderr = with_fs_read_file(err_path)   // src/main.w:1307
   error: wrong argument type in call to 'reduce_discard_kept_test_binary'
     = label argument 'stderr' has type *mut c_void
     = note: parameter 'text' expects &str
   error: shadowing is not allowed for 'stderr'   --> src/main.w:1:1
   ```
   The local `stderr` binding is typed `*mut c_void` — the type of the libc /
   bundle-interface global `stderr` (Darwin's `__stderrp`). The local should be
   `str` (return of `with_fs_read_file`).

2. **`behav_cli_test_command_args.w`** (a p7 CLI test). It writes a trivial
   `tests/one.w` (`fn main: print("one")`) into a scratch dir and runs the
   compiler there. It fails with:
   ```
   error: import module not found: 'std.re.defs' (build-generated modules live
     under out/gen; run `with build` once in a fresh checkout)
   error: import module not found: 'std.re.pcre2_compile' ...
   ... (every std.re.* module)
   ```

### Root cause (as far as established)

Both symptoms are downstream of the **embedded pcre2 bundle interface not being
used** on the macOS CI build. When the bundle interface is active, `use
std.regex` resolves to the embedded `.wi`, `std.re.*` resolve to it, and the
libc/interface `stderr` global is import-gated (a local `stderr` wins). When it
is NOT active, the frontend falls back to looking for `std.re` **sources** under
`out/gen` (symptom 2's message), and the flat namespace lets the interface/libc
`stderr` shadow a program local (symptom 1).

### Critical facts — read these before forming a theory

- **Not a flake.** Deterministic across reruns. The failing tests are real
  compile errors, surfaced by the `Failure diagnostics` CI step (added on wo-c4
  in 7910cf98 / zlib-wo 61f1e301 — `if: failure()` dumps captures + probes the
  stage2 binary; it is the reason we can see this at all).
- **Not reproducible locally.** On `~/.local/with-staging/c4r`,
  `out/stage/bin/with-stage2 check src/main.w` returns **rc 0**, and
  `out/release/bin/with test test/behavior/behav_cli_test_command_args.w`
  passes. The C4 release binary embeds the bundle (`strings out/release/bin/with
  | grep -c std/re/pcre2_compile` = 6) and its abi-sha is
  `ea839643fc8666b5e605023e5e41f05026918a62405ea69d7fdf91f6f179718b`.
  **The failure is layout/build-dependent** — the #729 / test-runner-only class
  (see the `test-runner-only-failures` playbook: hard-link the runner's binary,
  break on the collision). It manifests on the CI runner's freshly-built
  stage2/release, not on a locally-built one.
- **The zlib-wo Sema fix does NOT fix it.** I hypothesized that my zlib-wo
  commit `ca40e7f5` ("a source definition keeps the flat signature index
  whatever the collection order; interface globals bind per declaring module")
  would green macOS. **REFUTED**: zlib-wo (61f1e301) CONTAINS ca40e7f5 and still
  fails macOS on the identical two tests. Do not re-assert this.

### Candidate causes NOT yet checked (start here)

1. **Embedded-bundle abi-sha mismatch on the macOS build.** `Link.w`
   (`link_stage_select_embedded_bundles`) refuses a bundle whose manifest
   abi-sha != the compiler's baked abi-sha, and the frontend then has no
   interface → falls back to out/gen. If the macOS CI build stamps a different
   abi-sha into the compiler than into the bundle (build ordering, a stale
   embed, the `.unstamped` vs stamped binary), the bundle is silently refused.
   Check: on the runner, `with version --abi-sha` vs the embedded bundle
   manifest's abi-sha; look for a "was built for ABI X but this compiler is Y"
   eprint (it may be swallowed).
2. **Empty/stale embed data.** `out/gen/compiler/EmbeddedBundlesData.w` (the
   embed index) or the embedded `.wi` blob could be empty/wrong on the macOS
   build. The p7 "run with build once" message is exactly the fresh-checkout
   fallback — the frontend found neither embedded nor out/gen sources.
3. **cwd / WITH_OUT_DIR resolution.** The p7 test runs the compiler with cwd =
   scratch dir. macOS CI sets `WITH_OUT_DIR=<workspace>/out` (ci.yml). If bundle
   / out/gen resolution uses cwd instead of WITH_OUT_DIR, a scratch-cwd compile
   fails to find them. But the EMBEDDED bundle should not need out/gen at all —
   so the real question is why the embedded path isn't taken.
4. **The stderr collision itself** (symptom 1) may be a second, independent
   flat-namespace hole not covered by wo-c4's `785730e1` / `b7758cad` /
   zlib-wo's `ca40e7f5` — a local named exactly like a libc global the
   (embedded or fallback) bundle interface re-exports. But if the bundle were
   used correctly, `stderr` would be import-gated; so symptom 1 is likely also
   downstream of "bundle not used."

### How to reproduce (the hard part)

You need the CI runner's binary or a from-scratch macOS build that reproduces
the layout. Options: (a) trigger the macOS lane and pull the uploaded artifacts
(zlib-wo's ci.yml `Failure diagnostics` dumps captures; consider adding an
`actions/upload-artifact` of `out/stage/bin/with-stage2` + `out/gen` +
`out/wo/*` on failure, as the Windows workflow already does); (b) a clean
`git clone` + `with build :seed` + full `with build` on this Mac and run
`out/stage/bin/with-stage2 check src/main.w` and the p7 test — try to hit the
layout. The `WITH_ALLOC_NO_REUSE` / debug-allocator / `--dump-place-map` route
applies once reproduced. This is a real deep-compiler bug; use the deep tools,
not grep.

**THE PLAN — a local CI VM via Apple Virtualization.** The failure is
layout/build-dependent and does not reproduce on the dev Mac (option b keeps
passing), so the strategy is to build a virtual machine that replicates the
GitHub `macos-latest` runner environment as closely as possible and reproduce
the failure inside it, where we can then attach the debugger. Use Apple's
Virtualization framework (`https://developer.apple.com/documentation/virtualization`)
to stand up a macOS arm64 guest that mirrors the runner: a clean checkout, the
same seed (`with build :seed`, pinned in `seed.lock`), the same `.deps` LLVM
SDK, the same env (`WITH_OUT_DIR`, `WITH`, `LLVM_PREFIX` per `.github/workflows/ci.yml`),
and the same steps (`src/main build` → `build :fixpoint` → `src/main build :test`).
The goal is a fresh, isolated filesystem/build layout matching the runner so the
`#729`-class non-determinism actually triggers; once it fails inside the VM, the
usual deep tools (debug allocator, `WITH_ALLOC_NO_REUSE`, breakpoints on the
`stderr`/bundle collision, `--dump-place-map`, `--trace-ownership`) reach the
live compiler branch. Per the self-host rule, any VM orchestration/driver we
write is With, not shell/Python (the only exception is the framework calls
themselves, reached via `extern fn`). This is Anka/Tart-style runner
virtualization but built on the first-party Virtualization API so it stays a
self-contained, reproducible local environment.

CI run IDs for the dumps (`gh run view <id> --log`): #1101 macOS = 34368362224;
#1103 macOS = 34372877059; #1103 linux x86_64 = 34372876934.

---

## 2. The dependency chain behind #1103's `linux x86_64` lane

`#1103 (zlib bundle) → #1104 (va_list ABI) → #1102 (migrator macro leak)`.

### #1104 — va_list is modeled as a pointer on every target (IMPLEMENTED, verified)

**Bug**: `va_list` was modeled as the migration HOST's shape. On macOS it is
`char *`, so a variadic C definition migrated there (zlib's `gzprintf`/
`gzvprintf`, pcre2test's `cfprintf`) becomes `var __local_va: *mut i8`;
`llvm.va_start` writes into an 8-byte slot. On SysV x86_64 the `__va_list_tag`
is 24 bytes and `vsnprintf` wants a POINTER to it → stack corruption, **exit
139** (this is #1103's `linux x86_64` `zlib-wo-drift` crash). Only variadic
DEFINITIONS that read varargs are affected; calls and externs already work.
pcre2 (the bundle) has none; only pcre2test (the harness) and zlib's gz layer.

**Fix (on branch `va-list`, worktree `~/.local/with-staging/valist`, commits
aec8b11a + 71b7467c):** C's va_list is a compiler-known per-target type
`c_va_list`:
- `TypeKind.TY_VA_LIST` (=21) in `src/Sema.w`; `ty_c_va_list` field, created
  with `add_type(TY_VA_LIST,0,0,0)`, `register_prim("c_va_list", ...)`;
  `is_copy` returns 1. Sema imports `TargetSpec`.
- `src/TypeLayout.w`: `type_layout_c_va_list_size()` = 8 (Darwin/Windows) / 24
  (Linux x86_64) / 32 (Linux aarch64); size_of/align_of handle TY_VA_LIST
  (align 8). **TypeLayout.w is in `docs/with-abi.sha256` — re-record it.**
- `src/Codegen.w` `sema_type_to_llvm`: TY_VA_LIST → `ptr` when size 8, else
  `[i8 x size]`. Codegen imports `TypeLayout`.
- **Share-place on Linux**: `Sema.sig_param_is_c_va_list_by_place(sig,pi)` (true
  when the param is c_va_list AND `target_spec_os() == "Linux"`) →
  `set_sig_param_value_ref_abi`, wired in `src/SemaDecl.w` for BOTH
  `collect_fn_decl` and `collect_extern_fn`. `Codegen.declare_extern_fn`
  declares a value_ref_abi param as `ptr`.
- **Migrator**: `src/compiler/ClangBridge.w` `translate_type_recursive_mode`
  checks the PRE-canonical spelling (`clang_getTypeSpelling` + `c_strstr
  "va_list"`) and returns `c_va_list` BEFORE canonicalization decays a macOS
  `char *` va_list. Also `CImport.w ci_map_builtin_typedef` maps
  va_list/__builtin_va_list/__gnuc_va_list → c_va_list, the aggregate-va_list
  path returns `ty_named("c_va_list")`, and `ci_translated_builtin_type_name`
  knows it. `lib/std/libc.w`'s `vsnprintf`/`vfprintf`/`vprintf` take `c_va_list`.
  `with_va_start`/`with_va_end` stay `*mut i8` (the migrator passes `&raw mut va`).

**VERIFIED from IR** (`with ir X.w --target=linux_x86_64` vs native): the
migrated pattern `var va: c_va_list; with_va_start(&raw mut va as *mut i8);
vsnprintf(..., va)` emits, on linux_x86_64, `alloca [24 x i8]`, `va_start` on it,
`vsnprintf(..., ptr %2)` (the tag ADDRESS); on darwin, `alloca ptr`, `va_start`
on it, `vsnprintf(..., ptr %loaded)` (the char* BY VALUE). A macOS re-migration
of `gzwrite.c` now emits `var __local_va: c_va_list` and `gzvprintf(...,
__param_va: c_va_list)`.

**Remaining for #1104 to land:**
1. **Fix #1102 first** (below) — it blocks the pcre2 corpus re-promotion.
2. Re-promote both corpora so `gzwrite.w` and `pcre2test.w` carry `c_va_list`.
   The zlib half is done on `va-list` (71b7467c: only gzwrite.w's 2 va lines
   changed; the +105-line SDK-macro defs.w drift was discarded = #1102). pcre2
   still needs it (pcre2test.w's `cfprintf` still `__local_args: *mut i8`).
3. **The branch does NOT build yet** — std.libc's v-formatters take c_va_list,
   so pcre2test.w won't compile until re-promoted.
4. Re-record `docs/with-abi.sha256` (TypeLayout.w changed → abi-hash-check trips).
5. Full battery + move/drop audits (this is an ABI change — isolated batch).

`c_va_list` is a builtin (registered prim), NOT emitted into `defs.w`, so
`defs.w` does not change for #1104 — only the two files that USE va change.

### #1102 — migrator leaks host SDK macros into shared defs (fix located)

**Bug**: since the 2026-09-03 promote, the migrator captures object-like macros
from SYSTEM headers and emits them as `pub let` into the shared `defs.w` —
`MAC_OS_X_VERSION_10_0`, `FD_SETSIZE`, and on pcre2 config macros
(`HAVE_UNISTD_H`, `USE_CLANG_TYPES`, `USE_CLANG_STDDEF`, `USER_ADDR_NULL`,
`USE_CLANG_STDARG`) that collide → `error: shadowing is not allowed for
'HAVE_UNISTD_H'`. This makes corpus output host-dependent AND blocks re-migrating
pcre2 (the collisions are hard errors). Candidates for the regression: the
c_import macro commits `1f826ac4` / `82f21d7c`.

**Fix (located, one guard — NOT yet applied):** the bridge already computes
system-ness. In `src/CiMigrate.w` `ci_capture_macro_values` (~line 776) and
`src/CImport.w` `ci_collect_object_macro_values` (~line 2698), skip a macro when
`with_cimport_macro_is_system(session, i) != 0`. That predicate
(`src/compiler/ClangBridge.w:2613`, populated at 2310 from
`macro_location_is_system_from_cursor` → `cimport_location_path_is_system`) is
real and populated. **Still verify the pub-let EMIT path reads the capture
table** (so skipping at capture actually suppresses emission), then re-promote
both corpora and confirm the diff is empty except intended changes. #1102 is a
migrator-hygiene fix; keep it its own commit/batch (do not fold into the ABI
batch beyond what's forced).

### Corpus re-promotion gotchas (both #1102 and #1104 need it)

- The zlib corpus is package `std.zlib` under `lib/std/zlib/` on wo-c4 (NOT the
  `std.zl` rename — that is zlib-wo only). It is prelude-ON (committed
  `lib/std/zlib/defs.w` has NO `type c_void = opaque`). Migrate settings:
  `--shared-defs std.zlib.defs --no-c-export --prefer-brace --width-slice 8`,
  NO `--no-prelude`. A faithful full-directory re-migrate matched committed
  byte-for-byte except gzwrite's va lines and defs.w's SDK-macro drift (#1102).
- The pcre2 corpus is package `std.re` under `lib/std/re/`, prelude-OFF
  (committed `lib/std/re/defs.w` HAS `type c_void = opaque` via the name-based
  `ci_migrate_shared_defs_targets_regex_zone`). Its migrate is a directory
  migrate with excludes (pcre2demo/pcre2grep/pcre2posix_test/pcre2_jit_test/
  pcre2_dftables/pcre2_fuzzsupport) and special source handling
  (`pcre2_chkdint.c` fails a naive CLI directory scan) — use the
  `:pcre2-migrate` ACTION, not a hand CLI migrate.
- **Reference trees** the actions expect: `out/zlib_reference/zlib-1.3.2/`
  (with `.with-reference-ready`) and `out/pcre2_reference/pcre2-10.47/`
  (NOT `out/pcre2_reference/src`). Copy from `~/with/out/*_reference/` or another
  worktree; the reference download is network-gated.
- **`:*-promote` chain via the native runner hits #921**: `error:
  Workspace.set_migrate_options requires compiler driver comptime evaluation`.
  Run `:*-migrate` directly (`WITH=<stage1> <stage1> build :zlib-migrate`), which
  re-runs under comptime, then copy the .w files the way `run_*_promote_action`
  does. Do the re-migrate with a stage1 that HAS the migrator changes.

---

## 3. The zlib `.wo` bundle (PR #1103) — what it is and what landed

The campaign: compile each migrated C corpus once into a versioned-ABI `.wo`
bundle (object + `.wi` interface + manifest, keyed by corpus/target/ABI), embed
it, link on demand, so a consumer of `std.zlib` doesn't recompile zlib every
build. pcre2 was the first bundle (C1–C4). zlib is the second.

zlib-wo (61f1e301, over wo-c4) is a fully-green worktree battery (build/fixpoint/
test/seed-compat/test-green/last-green) — the macOS + linux-x86_64 failures are
CI-only (sections 1, 2). What the second bundle exposed and fixed (all in the
batch; each is now a general rule, see `docs/wo_bundles.md`):
- Corpus package `std.zlib` collided with the facade module `lib/std/zlib.w`
  (the frontend's parent-module import fallback pulled the facade into the
  `--no-prelude` bundle build). Renamed corpus → `std.zl` under `lib/std/zl/`;
  `build/wo.w` now refuses a corpus whose package name is also a module file.
  (This rename is ON zlib-wo only, NOT wo-c4/va-list.)
- The migrator's prelude-free vocabulary (c_void, `__ci_unreachable`) is keyed
  on the migrate workspace's `prelude_mode: None` (`with migrate --no-prelude`),
  no longer on the corpus name `std.re` (`ci_migrate_output_is_prelude_free`).
- The bundle interface spells variadic functions (`gzprintf(..., ...)`) instead
  of refusing them (§18.5c: a `.wi` is ordinary declaration syntax).
- Two Sema flat-namespace holes (`ca40e7f5`): a source fn signature was
  overwritten by a same-named interface signature (facade `compress` vs corpus C
  `compress`); interface globals were keyed by name only (pcre2's `UINT_MAX` hid
  zlib's) → per-declaring-module binding (`interface_global_alt_*`).
- Two codegen gaps (`f6b82ba0`): unions weren't predeclared (the alphabetical
  `.wi` puts `ct_data_s` before its unions); a bundle build now carries the
  non-corpus With functions its corpus reaches (std.libc's gz I/O wrappers) as
  INTERNAL copies (`decl_path_is_bundle_carried`), because a whole-program
  consumer never defines module-link-named symbols.
- The store slot is keyed by the compiler SOURCES too (`compiler-src-sha`,
  `ab30b320`): battery #2 linked a stale object under an unchanged ABI.
- Windows: `fcntl` is a per-target runtime seam (`961bbda6`) — zlib's gz layer,
  migrated on macOS with O_NONBLOCK/O_CLOEXEC resolved, calls fcntl, which
  std.libc had as a bare extern and UCRT lacks. POSIX forwards via a variadic
  libc extern; Windows returns -1. A failed undefined-symbol probe now warns
  instead of silently linking every bundle (`6cb098c8`).
- ToolFs accepts an absolute path under the project root (`0da6940b`, a
  failure-path bug in build-helper-programs); `std.zl` is an internal module for
  the spec inventory.

**Measured** (interleaved A/B, `WITH_PROFILE=1`, release compilers wo-c4 vs
zlib-wo, 3 rounds): a program importing `std.zlib` spends ~800 ms in compiler
phases with the corpus in-unit vs ~160 ms with the bundle (imports 48→1.3 ms,
comptime 75→11 ms, mir.lower 30→4 ms, llvm gen/opt/emit 570→115 ms; link
unchanged). The compiler's own build is unchanged (it never reaches zlib).

`docs/wo_bundles.md` on zlib-wo has the full mechanism (naming rule, variadics,
carried copies, the `compiler-src-sha` key). Design docs: `docs/wo_bundles.md`,
`docs/abi_roadmap.md` (Level 0), `docs/with-abi.md`, `docs/decisions.md` D38/D39,
`docs/stdlib_sourcing_plan.md`.

---

## 4. Battery / reseed discipline (do not skip)

- Battery (batch tier): `with build` → `:fixpoint` → `:test` (includes
  `:seed-compat`) → `:test-green` → `:last-green`; add `:move-audit`/`:drop-audit`
  for ownership/codegen/ABI changes (#1104 needs them). Reseed once after
  (`:update-seed` + `:install-user`). Commit BEFORE the battery, never during it
  (even docs) or `install-user`'s gate trips.
- An ABI change (#1104) must be ALONE in its batch. It changes
  `docs/with-abi.sha256` inputs (TypeLayout.w) → re-record and expect
  `abi-hash-check` to trip until you do.
- The perf gate is a RELATIVE ratio measured LOCALLY by interleaved A/B on
  Eric's laptop (~10x CI), never on CI, never by waiting for an idle box.
- Run long work detached with a keep_awake hold (Eric's box is a traveling
  laptop; runs die ~10 min after turn activity stops). Verify via logs.
- The macOS in-place-overwrite SIGKILL class (2026-09-03 install incident):
  `:install-user` renames via a temp sibling, not an in-place copy.

---

## 5. Recommended order for the next agent

1. **Reproduce and fix the macOS embedded-bundle bug (section 1)** — it blocks
   BOTH #1101 and #1103, is not fixed by anything on the branches, and is the
   real gate. Start with the abi-sha-mismatch / empty-embed candidates; get a
   reproduction (CI artifact upload of the runner's stage2 + out/gen + out/wo,
   or a clean from-scratch build on this Mac). Use the deep-compiler tools once
   reproduced. Land the fix so C4's macOS lane goes green; then #1101 can merge.
2. **#1102** (one-guard migrator fix) — its own small batch.
3. **#1104** (va_list) rebased on #1102 — re-promote both corpora, re-record
   abi-hash, full battery + audits. Verify #1103's `linux x86_64`
   `zlib-wo-drift` no longer exits 139.
4. **#1103** rebased on the merged main — should then be green on all five.

All the detail above (commits, file:line, IR evidence, reproduction notes) is
mirrored in the session memory notes `wo-bundles-state`, `va-list-per-target-1104`,
`bundled-corpus-two-exclusions`, `test-runner-only-failures`, `zsh-no-word-split`.
