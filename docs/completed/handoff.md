# Handoff — v0.15.2.2 is blocked on `with get` just working (2026-09-16)

Read this whole file before touching anything. Nothing is tagged or
published. `src/version` still says `v0.15.2.1`; `seed.lock` still pins
`v0.15.2.0`.

## Current state (2026-09-18, night) — read this first

Sections 1–5 below are from 2026-09-16 and partly stale; §0 (Eric's ruling),
§8 (environment traps) and §9 (standing rules) still hold. The running record
of the campaign is `docs/with-get-release-investigation.md` (newest findings
at the end); evidence logs are in `~/with/out/with-get-investigation/`.

**Merged to `main` today:** #1181 (D43 tail inference, mission ¶2, spec
§9.1), #1183 (#1172 return cleanup), #1184 (reseed gate 2048M), #1185 (gate
steps no longer rebuild stage2; `:test-with-audits`), #1186 (stage1 emit
width 4 off CI), #1188 (D44 spec + ruling). **Open:** #1190 — D44 step 1, the
map ownership fix (#1187, and the defect behind #1158). The installed `with`
was reseeded from `a91d0bf7`: it has D43 and #1172, not D44.

**The campaign branch is `with-get-release-uat-rebased`** (worktree
`~/.local/with-staging/with-get`): the 23 campaign commits rebased onto
`main` (`667f82d6`) plus a cherry-pick of #1190's commit. The old
`fix-with-get-release-uat` in `~/with` is superseded; nothing is unique to
it. One rebase conflict: `ed39964b` ("Resolve install cache outputs through
the execution path") fixed the same `$HOME` install-path freshness defect as
#1185; `main`'s version was kept, the campaign's regression test
(`behav_build_cache_install_paths.w`) stays.

**The whole darwin `:release-uat` group is green on that branch** (rc=0,
61 s, floating packages: zlib, bzip2, sqlite3, openssl, libcurl,
raylib-spiral) — the first fully green darwin UAT of the campaign. OpenSSL
died with `invalid free` on every earlier validation run. Root cause (D44, spec §2.3):
`HashMap.keys()/values()/items()` byte-copied their elements, so the
compiler's own `sema_clone_str_str_hashmap` double-freed through `.keys()`.
The release UAT targets refuse a compiler that has no last-green record
(`require-last-green`): run the full battery on a tree before its
`:release-uat`.

**Last full validation** is Release run `35388740596` (before the D44 fix):
every leg's battery green, every leg red only in the release UAT.

| leg | failing UAT targets at that run |
|---|---|
| darwin-aarch64 | openssl (fixed since), raylib-spiral (runner has no OpenGL 3.3 context; passes locally) |
| linux-x86_64 | openssl (same invalid free — expect fixed), libcurl, raylib-spiral |
| linux-aarch64 | zlib, bzip2, sqlite3, openssl, libcurl, raylib-spiral (the arm64 source-build gap) |
| windows-x86_64 | bzip2 and libcurl exit 124 at ~185 s; openssl `lld-link: could not open 'crypto.lib' / 'ssl.lib'` |
| windows-aarch64 | bzip2 and libcurl exit 124 at ~186–190 s |

Windows OpenSSL lead, unproven: `conan_library_name_from_path` is correct in
the tree (`c93e4bde`: COFF names keep their basename) and the aarch64 leg
links, so on x86_64 the name `crypto` was produced by something else — most
likely an older binary ran `with get` there. The log does not show which
binary ran it or what it wrote to the package's `metadata.json`; capture both
on the next Windows run before theorizing.

**Next steps, in order:**
1. After #1190 merges, rebase the campaign branch onto `main` (drop the
   cherry-pick), battery with `:test-with-audits`, then
   `gh workflow run Release --ref with-get-release-uat-rebased -f channel=test`
   and rebuild the matrix.
2. Work the remaining cells by root cause (§4 classes A–E), fixtures in
   `:test` for each, then the release steps in §5.
3. D44's remaining non-compliance (`docs/decisions.md` D44): view iterators
   for `keys()`/`values()`/`iter()`, `into_*`/`drain`, retire `items()`, the
   stdlib Vec-backed map in the same commit; `Vec[&T]` rejected while
   `Vec[Wrapper{&T}]` is accepted; #1189 (`HashMap.remove` leaks its key).

**The battery is ~21 minutes now, not ~38.** `export
WITH_CODEGEN_EMIT_WIDTH=16` on a large machine (stage1 289 s → 89 s; `:dev`
228 s → 84 s); use `:test-with-audits` for an ownership batch; gate steps no
longer relink. Reseeding still needs the candidate as the driver for the
last step only, because the pinned seed has the old 1024M gate compiled in:
`WITH=$PWD/out/release/bin/with out/release/bin/with build :install-user`.

Tool gaps filed and still open: #1159 (ownership audit passed the shallow
map owners), #1170, #1173 (drop-state matrix >7 GB), #1174, #1175, #1176,
#1177.

Traps met today:
- `WITH_DEBUG_ALLOC=1 <compiler> run prog.w` puts the COMPILER under the
  debug allocator too; on a bundle-less stage1 that ran 10 minutes. Use
  `run --debug-alloc`, or build first and set the variable on the binary.
- A plain run is not evidence for ownership: the map defects passed plainly
  and failed only under `WITH_DEBUG_ALLOC_SCRIBBLE=1`. A printed value is not
  evidence of a type: `print(f"{f()}")` on a `Unit` function printed numbers
  until #1180; bind `let x: T = f()`.
- `WITH_BUILD_ACTION_FORCE=1` forces every Action in the chain and rebuilds
  the stages per invocation; do not use it to make one target stale.
- The test cache is keyed on the compiler, so a `build.w`-only commit serves
  tests from cache (`1041 cached, 0 ran`); clear
  `out/.build-state/*.test-pass` and `*.test-verdicts` to really run them.
- A bootstrap stage1 must run from the repo root and prints ~78k lines of
  pcre2 warnings per check; send output to a file and grep `^error`.
- `xargs -I{}` silently stopped a 2,861-file sweep after 29 files; shard a
  With tool and print a processed count.

## 0. Eric's ruling — the task

The release UAT runs `with init` + `with get c.<package>` + `with run`
against whatever Conan Center serves today. When it went red (OpenSSL moved
to 4.0.2, zlib to 1.3.2), the previous handoff proposed pinning the openssl
UAT to 3.x. Eric rejected that (2026-09-16, verbatim):

> Yes, this is valid. `with get` should /just work/ and this correctly
> shows us that it isn't. Fix it - and not with a bandaid - with a true,
> deep, real fix after doing a deep dive and root cause analysis, fix the
> whole class of problem not just the tip of the iceberg.

So:

- **The UAT keeps floating to the newest package.** Do not pin package
  versions in the UAT, do not waive a UAT, do not skip a platform. The UAT
  is the user's experience; it is correct to be red.
- **Old decision 1 (#1158: chase / pin 3.x / waive) is answered: fix it**,
  as part of the whole class below.
- **Deep dive first.** Build the full failure matrix and find root causes
  before the first edit (CLAUDE.md: "Root cause, always", "Exhaust small
  answer-spaces in one pass", "Every bug has a route"). One-site patches for
  whichever header broke today are exactly what Eric ruled out.
- **Do not tag or publish v0.15.2.2 until `:release-uat` is green on every
  leg with floating packages.** The release exists to ship the Windows LLVM
  SDK (#1145); it still needs to happen, after this.

**Decision 2, windows-aarch64 placement — answered.** Eric (2026-09-16):
"anything the mac can't build, needs to be in the CI". So windows-aarch64
stays on CI with linux-x86_64 and windows-x86_64 on a `v*` tag push, as
#1155 already set up (`build-windows-aarch64` has no `if:` gate in
`.github/workflows/nightly-release.yml`). Nothing to change.

## 1. Where things stand

| Thing | State |
|---|---|
| main | `69bf4e70` = #1155 squash (release prep). Before it: #1154 (D42 math builtins), #1152 (#1144 installers), #1151 (CI gates: seed-driven battery, std.libc seams only, Clang bridge path boundary), #1143 (corpus registry). Main CI for `69bf4e70` was in progress at handoff; `0a0ff13d` was green on all five lanes. |
| `~/with` | at `69bf4e70`. Its main had held a local pre-squash copy of #1144 (`6fd711a6`, patch-id identical to the #1152 squash); kept as branch `backup/main-6fd711a6`, then the branch was moved to origin/main. Eric's uncommitted `plans/*.md` deletions are untouched. **`src/main` is the pinned seed** (digest `79a63ff9…`, matches seed.lock; it self-reports `v0.15.1.10`, which is known). This file is uncommitted there. |
| `~/.local/with-staging/release` | branch `release-v0.15.2.2`, tip `4ecfddb0`, merged as #1155. Holds a built release compiler and fetched UAT projects under `out/release-uat/`. |
| `~/.local/with-staging/ci-gates` | branch `ci-gates`, merged as #1151. Disposable. |
| `~/.local/with-staging/math-builtins`, `aarch64` | disposable (see git history of this file). |
| Docker | image `with-aarch64-host`, volume `with-aarch64` (clone + SDK + seed + `out/`), rebuilt from `tools/docker/linux-aarch64/Dockerfile`. |

## 2. What `with get` + the UAT actually do

- `with get c.openssl` → `src/compiler/ConanClient.w`. With no version
  hint, `conan_resolve_version` picks the **highest** version on
  `center2.conan.io` and `conan_get_latest_recipe_rev` the latest recipe
  revision. It downloads the prebuilt package (headers + libraries).
- The program then `use c_import("openssl/evp.h")`: the compiler translates
  the package's **whole** header closure through the Clang bridge and the
  c_import generator (`src/CImport.w`) at compile time, then links.
- The UAT body is `ruat_run_c_package_uat` in `build/release_uat.w`:
  `with init .`, `with get <package>`, write the fixture from
  `build/release_uat_fixtures/`, `with run`, compare stdout. Packages:
  zlib, bzip2, sqlite3, openssl, libcurl, and the raylib spiral (needs an
  OpenGL 3.3 context). The runbook (`docs/with-release-runbook.md`,
  "Verification") makes `:release-uat` mandatory on every platform.
- **This path has no coverage outside the release UAT** (nightly and
  release channels only). `:test` never runs `with get`. That is why a
  whole class of breakage accumulated unseen until release day.

## 3. The evidence — validation Release run `35143254857`

Test channel, dispatched on `4ecfddb0` (= main minus the later Windows
UAT-driver workflow change and this doc). All five legs failed. Job logs:
`gh api repos/withlang-dev/with/actions/jobs/<id>/logs` (`gh run view
--log-failed` returns nothing while any job of a run is still in progress).

| leg (job id) | failing step | what failed |
|---|---|---|
| darwin-aarch64 | Release UAT (macOS) | openssl: compiler `invalid free` (#1158). raylib spiral: "window not created (no OpenGL 3.3 context)" on the macOS runner (passes on the Mac locally). |
| linux-x86_64 (`104971208165`) | Release UAT (Linux, under Xvfb) | openssl: compiler `invalid free` (#1158). raylib spiral: link fails, `ld.lld: unable to find library -lGL -lX11 -lXext -lXfixes -lXi -lXinerama -lXrandr` (the job installs only `xvfb libgl1-mesa-dri`). |
| windows-x86_64 (`104971208218`) | Release UAT | `build`: "could not rename out/release/bin/with.exe.tmp to with.exe" (see §4 F). bzip2: exit 124 after ~184 s, **no stdout/stderr**. openssl: `error: undefined variable` at `<c_import openssl/evp.h>:3503` `let OSSL_DEPRECATEDIN_4_0: c_int = OSSL_DEPRECATED(4.0)`. libcurl: exit 124 after ~186 s, no output. raylib spiral: "ToolFs path escapes project root: D:/a/_temp/mesa/opengl32.dll". |
| windows-aarch64 (`104971208197`) | Release UAT | identical to windows-x86_64 (bzip2 124 at ~184 s, libcurl 124 at ~195 s, same openssl line 3502, same opengl32.dll refusal). |
| linux-aarch64 (`104971208087`) | Green battery (`build :test`) | `test/spec/spec_ss14_11_await_combinator_cancel_joins.w` fails although the file carries `//! skip-on: linux-aarch64` (added by #1155). The skip is not honored in that lane. |

Passing everywhere: zlib and sqlite3 (after #1155's generator fixes),
install-layout, one-liner. On darwin/linux: bzip2 and libcurl pass.

Two facts worth noticing before theorizing:

- **openssl fails differently by OS.** On darwin/linux the #1155 generator
  fix (an object macro whose value is a call is recorded untranslated)
  suppresses the dangling `OSSL_DEPRECATEDIN_4_0` and the compiler then
  crashes (#1158). On Windows the same macro is still emitted as a
  dangling `let`, so the fix does not cover the Windows expansion of the
  same header. Not root-caused.
- **Windows bzip2 and libcurl die at the same ~180 s with no output at all,**
  while zlib and sqlite3 pass there in 7–11 s. Not characterized: which of
  `get`, translate, compile, link or run is hanging is unknown.

## 4. The class of problem — leads for the deep dive

These are hypotheses and pointers, not conclusions. Settle facts by
running (CLAUDE.md "Verify by Running").

**A. c_import translation breaks on real-world headers, one gap at a
time.** #1155 fixed three generator gaps that newer zlib/sqlite3/openssl
headers exposed; Windows openssl shows a fourth. Questions:
- Why does a construct have several emitters that each spell it
  differently? #1155 fix 2 had to fix the constant-probe emitter
  (`ci_try_translate_object_macro_probe`), the typedef alias resolver and
  `ci_infer_cast_return_type` separately. Find every duplicate emission
  path for macros, typedefs and casts; one source of truth per construct
  (the `FnAbi` lesson in CLAUDE.md).
- Why can a macro the program never references make the whole import
  fail? The fixture uses EVP digests; `OSSL_DEPRECATEDIN_4_0` is unused.
  An untranslatable, unreferenced declaration should never be an error
  at import; a referenced one must be a loud, precise error (No Silent
  Fallbacks).
- What do the MSVC/UCRT header branches expand to that the darwin/glibc
  branches do not (OpenSSL's `OSSL_DEPRECATED` under `_MSC_VER`,
  `__declspec`)? Related: #799 (c_import on MSVC headers), #1140 (UCRT
  `_wassert`).
- Related open issues: #582 (real-header macro omission diagnostics),
  #1047 (c_import translation cache keyed on header + hand-bumped format
  version, not the compiler: a translator fix can ship stale
  translations), #977 (`c_long` platform-invariant), #357 (c_import
  auto-defer heuristic).

**B. The c_import error path is not memory-safe in the compiler (#1158).**
`Zcu.compile_source_frontend_mode` double-frees a HashMap on the error
path; regression since `d9091ce0` (v0.15.2.1 takes the same path cleanly).
Layout-dependent (#729 class): it disappears under `tools/debug_drop.w`.
Route per CLAUDE.md: `WITH_DEBUG_ALLOC=1`, `WITH_ALLOC_NO_REUSE`,
`WITH_DEBUG_ALLOC_TRAP_FREE=<addr>` with `tools/debug_drop_sites.lldb` on
the compiler binary, then `--dump-drop-plan`/`--trace-ownership` on the
map local. The issue body has the lldb backtrace and the suspected window
(error-return edges added to the frontend between 09-06 and 09-16). Once
A stops reaching this error path for openssl, the bug is still there for
any c_import that errors: it needs its own fixture.

**C. Packages hang on Windows (bzip2, libcurl).** Unknown stage. Leads:
#623 (`with get` shells out to host curl/wget), a CRT/DLL-runtime mismatch
with Conan prebuilt libraries (the runbook records one found before), a
child waiting on console/stdin, or #1075 (the Windows seed cannot link the
native build runner, so actions fall back to the comptime evaluator).
Reproduce on a test-channel run with per-stage timing before guessing.

**D. Prebuilt packages have system requirements `with get` neither
provisions nor reports.** raylib on Linux needs GL/X11 development
libraries; the error surfaces as a raw `ld.lld` failure. "Just works"
means `with get` (or `with run`) detects the missing system libraries and
says exactly what to install, or supplies them. Also #1148: on Windows
`with get c.raylib` installs but no documented `c_import` form resolves
it. The CI runner additionally needs the libraries installed for the UAT;
the macOS runner has no OpenGL 3.3 context.

**E. The build capability sandbox refuses the UAT's GL DLL.**
`WITH_UAT_OPENGL32_DLL` points outside the project root and ToolFs rejects
it ("path escapes project root"). Decide whether the harness copies the
file in through a declared input or the action declares the path.

**F. Release plumbing (not `with get`, but blocks the same release).**
- Windows UAT relinked the running `with.exe` ("could not rename"). Main
  now runs `./src/main.exe build :release-uat` on Windows (after
  `4ecfddb0`); **not yet validated by a CI run.**
- linux-aarch64: `skip-on` not honored in `native-spec-tests`. The parser
  is in `src/main.w` (#795 gates); find why this lane's runner does not
  apply it, rather than editing the test. #1156 is the underlying
  runtime-object residue.
- #1157: the seed-driven gates relink stage2 and the release compiler on
  every gate step (~10 min per leg); signature changes between steps.
- `tools/release_local.w` has never run end to end.

**Coverage gap to close as part of the fix:** `with get` for the UAT
package set must run somewhere before release day (a nightly lane at
minimum, filing an issue when newest-package breaks), so the next header
change is found the day it lands, not at the next release.

## 5. Suggested order

1. Reproduce every darwin-reproducible failure locally with the
   release compiler first: build it seed-driven, then
   `WITH=$PWD/out/release/bin/with out/release/bin/with build
   :release-openssl-uat` (targets: `release-{zlib,bzip2,sqlite3,openssl,
   libcurl,raylib-spiral}-uat`; group `:release-uat`). The fetched
   projects land in `out/release-uat/<label>-project/`, where
   `with check src/main.w` gives a check-level repro.
2. For Windows-only failures, dispatch a test-channel run from your branch:
   `gh workflow run Release --ref <branch> -f channel=test` (inputs:
   `channel` test|nightly|release, `version` empty = from src/version).
   Runs share a concurrency group per channel and queue.
3. Write the matrix (package × platform × stage: get / translate / check /
   link / run) with the exact failure per cell before fixing.
4. Fix the classes (A–E), with fixtures in `:test` for each root cause,
   not only a green UAT. Battery seed-driven; a change to drop scheduling
   (B) is alone in its batch with `:drop-audit`/`:move-audit`.
5. Then the release (unchanged from #1155's plan): a green test-channel run
   on main → `echo v0.15.2.2 > src/version`, commit, land on main → tag
   `v0.15.2.2` at that commit and push the tag (**before** release_local;
   publish-first refuses an unknown commit) → `export GH_TOKEN=$(gh auth
   token); export RELEASE_SOURCE_SHA=$(git rev-parse v0.15.2.2); with run
   tools/release_local.w v0.15.2.2` → CI appends linux-x86_64 and both
   Windows legs → runbook "Post-Publish Checks" → consider bumping
   `seed.lock` as a separate step.
6. **After the release ships:** flip the deferred D42 surface to `cos(x)`
   in `build/release_uat_fixtures/raylib_spiral_main.w` and the
   withlang.org homepage example (`~/withlang-dev.github.io/index.html`).
   Eric: "flip only after a release ships the new compiler."

## 6. What #1155 already fixed (keep; do not redo)

- linux-aarch64 host map: `release_asset_for_host()` /
  `supported_release_platform_tag()` in `build.w` fell through to darwin.
- windows-aarch64 `NM=<sdk>/bin/llvm-nm.exe` in the Release job.
- Reproducible Windows links: `/Brepro` in `src/compiler/Link.w`
  (last-green "stale test pass marker").
- c_import generator: call-valued object macros recorded untranslated;
  raw function pointer types spelled `unsafe extern "C" fn` in every type
  position; `openssl_main.w` imports `std.builtins.write`. Debug trick that
  worked: append `// emit:<site>` markers to candidate emitters, rebuild
  once, read which marker appears.
- Local-first release process (`tools/release_local.w`, Docker host,
  workflow split, two runbook sections).

## 7. Issues

Filed 2026-09-14..16: #1144 (closed by #1152), #1145 (Windows SDK not in
tagged releases — the reason for this release), #1146 (`install-user`
outside a project), #1147 (Windows lld-link long section name warnings),
#1148 (raylib on Windows), #1149 (linux-aarch64 lane runs no `:test`),
#1150 (examples/ rotted, in no lane), #1153 (migrate emits `pub extern fn`
for builtin libm names), #1156, #1157, #1158.

Most relevant to the `with get` class: #1158, #1148, #1047, #799, #582,
#623, #1140, #977, #1075, #1079 (`:seed`/`:deps` API response parsed
line-by-line; `ConanClient.w` also hand-parses JSON — check it for the
same fragility).

## 8. Environment traps — expensive to rediscover

- **A fresh worktree cannot build.** No `src/main`, no `.deps`. Fix:
  `with build :seed` (idempotent on seed.lock's digest) and
  `ln -sfn ~/with/.deps .deps`.
- **The battery is seed-driven.** `export WITH=$PWD/src/main; src/main build
  …`. `seed-driver` refuses any other driver (and `WITH=src/main with
  build`). Re-migrating a corpus needs a tree compiler with bundles:
  `WITH=out/stage/bin/with-stage2 out/stage/bin/with-stage2 build
  :<stem>-promote`.
- **Never commit during a battery** (even docs): the version stamp tracks
  `.git`.
- **Read `rc=` from your own log.** Append `echo "rc=$?"` to every
  background build log.
- **`:dev` writes `out/bootstrap/bin/with-stage1`**, not `out/stage/bin/`.
- **Pre-existing on a bootstrap stage1:** `test/spec/spec_ss16_ffi_and_c_import.w`
  (stdio.h opaque-struct errors), `with-stage1 -e '…'` ("conflicting global
  declaration for 'stdin'"), `test/benchmark/hash_engines.w`.
- **Bisecting old commits needs `SDKROOT`**:
  `export SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk`
  (Xcode 26's `libm.tbd` lists `arm64e.x1-macos`, which ld64.lld 22
  rejects). Kill an interrupted bisect's in-flight `build :dev` too.
- **The arm64 container needs `g++` and `libxml2`** or it fails silently.
  `--cap-add=SYS_PTRACE --security-opt seccomp=unconfined` for `strace`.
- **Workspace search:** use the zvec-grep MCP tools when connected
  (`zvec_grep_rg`, `zvec_grep_search`); it failed to connect in the last
  session. The `release` worktree has no index — search `/Users/eric/with`.
- **zsh:** `echo ====` is a glob error; an unquoted `$OPTS` is one
  argument.

## 9. Standing rules

Commits authored `Eric Hartford <eric@quixi.ai>`, never any AI
attribution. Never `git stash`. No python/bash/perl/sed/awk scripts — With
one-liners or `with run tool.w`. Never `-O0`. Take a `keep_awake` hold for
long runs (this laptop sleeps and kills detached work). Never cite a commit
hash you have not printed. Changes reach main by PR targeting `main`
directly (no stacked PRs). A migrator or c_import fix is done only when the
regenerated output compiles and the library's own program runs.
