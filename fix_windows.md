# Fix Windows — orientation for the Windows agent

You are picking up the one open platform. Mac and Linux build and self-host from
the published seed; **Windows is blocked on a single compiler bug, tracked as
#1081.** This note gets you to the bug fast and tells you what has already been
tried so you don't repeat it.

Read `CLAUDE.md` first — the self-host discipline is binding. In particular:
**own every bug (nothing is "pre-existing"), root cause at the instruction
level, verify by running not by reasoning, debug tools before grep, no C/
Python/bash/perl (With one-liners and With tools only), never `git stash`.**
The route for THIS bug class is fixed by `docs/deep-debugging-tools.md`: a
free/drop/UAF bug **starts with the native debug allocator**, not with a grep or
a trace print.

## Resolved (2026-09-06) — read this before the rest

The crash was found and fixed on a native Windows box. The rest of this note
is kept as the orientation it was; where it guesses, this section rules.

**Root cause.** A double free in the runtime, not a drop-state or
move-checker edge, and nothing to do with the pcre2 corpus or its Copy
types. `with_fs_list_files` converts its path with `str_to_cstr` (an
`rt_alloc`'d copy), walks, then `cstr_free`s it. The Windows walk's only
test was `win_is_dir`, so a path that does not EXIST took the "not a
directory → append the path" branch, and `win_list_append` built
`path_text = with_str_from_cstr(path)` — which was `make_str`, a view of
the C buffer typed as an owned `str`. Its scope-exit drop passed the
ownership guard (the buffer is a live payload) and freed it; `cstr_free`
freed it again. The compiler reached that branch because its temp-archive
cleanup lists `out/lib` before the directory exists during the `.wo`
bundle build. The unix walks return early when `stat` fails, which is the
whole reason only Windows crashed — `list_files_text("<a file>")` took
the same line on every platform (latent double free; the fixture covers
it). Full evidence chain in `c44634d3`.

**Landed** (branch `fix-1081-str-from-cstr`): `with_str_from_cstr` copies
(an owned str owns its bytes, #747-H); the Windows walk treats a missing
path like unix; the instruments that closed the hunt on a box with no
debugger (a panic backtrace on Windows x64, invalid-free forensics, the
range-table stand-down announced, a ledger that fits a compiler run); the
route additions in `docs/deep-debugging-tools.md`. Separately,
`windows-sdk-publish`: every release now republishes its LLVM SDK, which
is what `with build :deps` needs to provision a Windows box at all.

**A second Windows-only defect, found while verifying:** `with run`,
`with test` and `with -e` could not launch the binary they had just built
(`exit code -2` at the run stage; `run`/`-e` silent). `CreateProcessW`
does not resolve a RELATIVE forward-slash program path from the command
line (`out/tmp/x.exe` → `ERROR_FILE_NOT_FOUND`; `out\tmp\x.exe` and any
absolute spelling work — a three-spelling `std.process.run` probe proved
it), and every compiler-built binary is launched by such a path.
`win_build_command_line` now spells argv[0] with backslashes on both
Windows backends. It looked like a seed-only quirk until the tree's own
compiler showed it too.

**The `:test` battery on this box, under main's own release compiler:**
984 behavior files ran, 983 passed; `pcre2-wo-drift` links and runs the
pcre2test harness (after the errno/rlimit shims and
`legacy_stdio_definitions.lib`); the two `nm` targets pass with `NM` set to
the SDK's `llvm-nm.exe`, as the Windows lanes already do. One fixture is
still red: `behav_project_overflow_modes` — its nested `with build` in a
case directory under `out/tmp` reaches the repo's `build.w` graph, whose
`with-sha256` link runs in a build-runner worker that does not carry the
Windows linker variables (`missing Windows LLVM linker metadata … and no
WITH_LLVM_LD / LLVM_LD / LLVM_PREFIX in the environment`). Unix never
notices because `cc` needs none of them. Two defects to file: the nested
project resolving to the enclosing repo's graph, and action workers not
forwarding the toolchain environment (build/compiler.w forwards it for
stage compiles by hand). Also fixed while here: the ownership range
tables grow instead of turning the invalid-free check off.

**The seed ladder, and why the lanes stay red until a seed is published:**
the v0.15.1.8 seed cannot evaluate main's `build.w` — `0173d08e` switched
the build-driver files to comptime `str` indexing (`path[i]`), which that
seed's evaluator lacks (`comptime index requires an array, tuple, or
vec`). But `af7db8ce` is the commit that taught the evaluator `str`
indexing, and v0.15.1.8 builds `af7db8ce`. So, natively on Windows, with
no `--emit-c`: v0.15.1.8 → a worktree at `af7db8ce` carrying the runtime
fix (full build green, `:fixpoint` green) → its release `with.exe` as
`WITH=` for main → main's full build green and `:fixpoint` green. Main's
release `out/release/bin/with.exe` from that chain is the Windows seed to
publish; then move the `seed.lock` Windows overrides off v0.15.1.8 and
`with run tools/bump_seed_pins.w` (numbering per D40: main is the
v0.15.2.x group). Two things to know on a fresh box: the SDK must come
from the release (`windows-sdk-publish` makes `:deps` able to find one),
and the toolchain env (`LLVM_PREFIX`, `WITH_LLVM_LD`, `WITH_LIBCLANG`,
`WITH_WINDOWS_{MSVC,UCRT,UM}_LIBDIR`) must be set before the FIRST
`with build`, because `out/bootstrap-lib/llvm_ld.rsp` caches whatever it
saw and a later run reuses it (two stage1 links here failed on the 2019
defaults for that reason; `with build :clean` resets it).

## The bug (#1081)

Building the pcre2 `.wo` bundle, the compiler **crashes** on native Windows:

```
 --> D:/a/with/with/lib/std/re/pcre2_auto_possess.w:3900:27
3900 |             if not (((if (unsafe *__local_chr_ptr) != 4294967295: 1 else: 0) != 0)) {
  |                           ^^^^^^^^^^^^^^^^^^^^^^^
invalid free addr=2164888967488
panic: invalid free: pointer is not an allocated payload start
error: action target 'pcre2-wo-build' failed during comptime evaluation
```

The freshly-built `with-stage1.exe` panics with an **invalid free** while
compiling the migrated pcre2 corpus. It fails fast (~34 s), so it is **not**
codegen volume or a link step — it is memory corruption in the compiler's own
runtime (a drop scheduled against a pointer that is not an allocation start:
the #729 / double-free / dangling-view class documented in `CLAUDE.md`).

The trigger is the bundle emit, which the `pcre2-wo-build` action runs as a
subprocess of the fresh stage compiler:

```
with build lib/std/re/bundle.w --emit-obj --bundle-corpus std/re -o out/wo/pcre2.o
```

### Scope — this is the crucial fact

**Native Windows only.** The linux-x86_64, linux-aarch64, and darwin bundle
builds succeed (their seeds and CI are green). Cross-compiling the *identical
target* from macOS —

```
with build lib/std/re/bundle.w --emit-obj --target=windows_x86_64 --bundle-corpus std/re -o /tmp/x.o
```

— exits 0 and emits the object cleanly (only warnings). So it is **not** a
codegen-for-Windows defect and **not** the migrated pcre2 source; it is a
drop/free bug in how the compiler's runtime behaves *running on Windows*,
exposed by this corpus (likely a layout- or allocator-dependent garbage drop,
#729 class — the huge Copy types in `lib/std/re/defs.w`, e.g. `heapframe` at
1,048,712 bytes, are a prime suspect for a drop-state or move-checker edge).

Because the bundle builder is the **fresh stage compiler** (`with-stage1.exe`
built from the current tree), a compiler-side fix on `main` takes effect in that
stage **without needing a new Windows seed** — you do not have to bootstrap a
Windows seed to test a fix, only to reach the bundle step.

## The route (do this first)

Per `docs/deep-debugging-tools.md`, a free bug starts with the allocator. On a
Windows machine, reproduce and instrument:

```
# 1. reproduce
with build lib/std/re/bundle.w --emit-obj --bundle-corpus std/re -o out\wo\pcre2.o

# 2. allocator verdict + no-reuse so the address is stable
set WITH_DEBUG_ALLOC=1
set WITH_ALLOC_NO_REUSE=1
with build lib\std\re\bundle.w --emit-obj --bundle-corpus std/re -o out\wo\pcre2.o

# 3. trap every alloc/free of the bad block for its drop origins
set WITH_DEBUG_ALLOC_TRAP_FREE=<the invalid-free address from the report>
with build lib\std\re\bundle.w --emit-obj --bundle-corpus std/re -o out\wo\pcre2.o
```

Then take the alloc site + the bad free's origin into the ownership/drop dumps
(`--dump-drop-plan`, `--dump-drop-state`, `--trace-ownership main:_N`,
`--validate-all`) and, if needed, a Windows debugger on the branch that emitted
the drop. **A cell proven only by grep or a trace print is a hypothesis, not the
root cause** — name the exact line, function, branch, and condition.

**If you have no Windows machine:** you can still run the allocator on the CI
runner. Dispatch the release workflow on a scratch branch that (a) is
af7db8ce-based so the v0.15.1.8 seed can materialize its `build.w`, (b) carries
the compiler fix or instrumentation you're testing, and (c) sets
`WITH_DEBUG_ALLOC=1 WITH_ALLOC_NO_REUSE=1` in the `pcre2-wo-build` action's
child env (`build/wo.w`, the `wo_run(ctx, "build", ...)` invocation). That is
how the panic itself was captured:

```
gh workflow run nightly-release.yml --ref <scratch-branch> -f channel=test -f version=<its src/version>
```

and read the windows-x86_64 job log. **`build/wo` echoing the captured `.wo`
stderr into the failure is what made the panic visible** (that commit, #1035, is
on `main` as 388decf1 — the older release branches do not have it, so a
diagnostic branch must include it).

## What is already landed (do NOT redo)

All on `main`; these were real and are correct, they just uncovered the deeper
crash:

- **#1075 — `Link.w` native-Windows lld-link env fallback** (main, in the D40
  chain): when `<runtime root>/llvm_ld` is absent, native Windows resolves the
  linker from `WITH_LLVM_LD` → `LLVM_LD` → `LLVM_PREFIX/bin/lld-link.exe`, the
  same way `build/compiler.w comp_llvm_lld_tool` does. This fixed the stage
  executable link (`with-stage1.exe` now links); it is not the crash.
- **Build-runner retry (f5af0c98):** the driver retries the native build-runner
  compile once the bootstrap runtime objects + linker metadata exist. On Windows
  the runner still can't link, so actions fall back to comptime — that fallback
  is benign and expected; the "missing Windows LLVM linker metadata" +
  "build runner compile failed; actions fall back to comptime evaluation" lines
  early in the log are NOT the bug.
- **Rob's #1029 / #1016 (cherry-picked into main):** `__std{in,out,err}p` on
  the Windows and non-Darwin backends, and `.wi` fixtures pinned to LF in
  `.gitattributes`. These fixed the earlier Windows reds; they are not the crash.

## State to know

- **Seeds / `seed.lock`:** Mac + Linux are pinned to **v0.15.2.0** (the D40
  bootstrap group; same commit as the retired v0.15.1.10). Windows is pinned to
  **v0.15.1.8** via `seed.lock`'s `<asset>.version=` overrides, because no
  Windows seed can build the current tree yet — that is exactly what #1081
  blocks. When you fix the crash: cut a Windows seed, publish it, and move the
  Windows overrides off v0.15.1.8. See D40 in `docs/decisions.md` for the
  numbering rule (a bootstrap breakage bumps `Y`, resets `Z`).
- **Version numbering:** if your fix is a plain compiler change that the current
  seeds can still bootstrap, it is a `Z` bump within `v0.15.2.x`. It only bumps
  `Y` if it makes the tree unbuildable by the group's seeds (it won't — a
  codegen/drop fix doesn't touch comptime-evaluated `build.w`).
- **`with build :seed-compat`** (part of the local battery) proves the pinned
  seed still builds the tree; keep it green.

## Files that matter

- `lib/std/re/pcre2_auto_possess.w` (crash site line ~3900) and
  `lib/std/re/defs.w` (the giant Copy types — `heapframe`, `heapframe_align`,
  `pcre2_real_match_data_8`).
- `src/Mir.w` — drop-state dataflow (interned place keys, the worklist fixpoint);
  `src/MirLower.w` — where drops are scheduled; the #729 garbage-drop class lives
  in this region.
- `src/compiler/Link.w` — the Windows link path (already fixed for #1075; the
  crash is not here).
- `build/wo.w` — `run_wo_bundle_build_action`: the `.wo` bundle build action, its
  `--emit-obj` sub-invocation, and the captured-stderr echo.
- Runtime: `rt/windows_x86_64.w`, `rt/windows_aarch64.w`, `rt/rt_core.w` — if the
  invalid free is a Windows allocator/runtime layout issue rather than a
  drop-scheduling bug, the difference between Windows and Unix free/alloc lives
  here.

## Definition of done

The Windows self-host lanes (`selfhost-windows.yml`,
`selfhost-windows-aarch64.yml`) and the release `build-windows*` jobs are green
from a Windows seed that builds the current tree, `seed.lock` no longer pins
Windows to the old group, and `with build :fixpoint` holds on Windows. Not
"green because a test was skipped" — the pcre2 bundle actually builds.
