# Handoff — cutting v0.15.2.2 (2026-09-16)

Read this whole file before touching anything. The active work is the
release worktree `~/.local/with-staging/release` on branch
`release-v0.15.2.2` (tip `4ecfddb0`), PR **#1155** → main. Nothing here is
reseeded; `seed.lock` still pins `v0.15.2.0`.

**Two decisions are blocking the release. They are listed in §4 and Eric
has not answered them yet.** Do not merge, tag, or publish before he does.

## 1. Where things stand

| Thing | State |
|---|---|
| main | `0a0ff13d`. Carries D42 (math builtins, #1154) and the #1144 installer fix (#1152), both merged today. CI green on all five lanes. |
| `~/.local/with-staging/release` | branch `release-v0.15.2.2`, tip `4ecfddb0`, pushed. PR #1155 open. Local battery GREEN through `last-green`; `:release-uat` fails on **openssl only** (#1158). |
| `~/.local/with-staging/math-builtins` | branch `math-builtins`, tip `20800683`. D42's source. Already merged as #1154 — the worktree is only kept because it holds a built release compiler and the fetched UAT projects under `out/release-uat/`. Disposable. |
| `~/.local/with-staging/aarch64` | detached at `0a0ff13d`. Was a scratch checkout for the container work; nothing in it is needed. Disposable. |
| Docker | image `with-aarch64-host` (715 MB), volume `with-aarch64` holding a clone + SDK + seed + `out/`. Both reusable; the image is rebuilt from `tools/docker/linux-aarch64/Dockerfile`. |
| Scratch | `/private/tmp/claude-501/-Users-eric-with/c74a0c2d-…/scratchpad/` — battery logs, the fetched `zlib-project`, `uat-openssl`, `uat-bzip2`, `uat-libcurl` projects for check-level repros. |

The many other `~/.local/with-staging/*` worktrees are from earlier
campaigns and are not part of this work.

## 2. The goal, and Eric's ruling on how releases are cut

Cut **v0.15.2.2** with a compiler *and* an LLVM SDK for every platform. The
motivating defect: the Release workflow had failed on every leg since
2026-09-12, and v0.15.2.1 shipped SDKs for only three of five platforms
because its Windows legs never finished.

**Eric, 2026-09-16 (verbatim intent):** on every release the Mac builds and
uploads the darwin and linux-aarch64 binaries; only the x86_64 platforms
(linux, windows) are built by GitHub CI and appended afterwards. The
process must be documented and automated. Separately: a linux-aarch64 build
on a MacBook must be in the runbooks with a checked-in Dockerfile — "it's
dumb that we had to figure it out from scratch multiple times."

Implemented in #1155:

- `tools/docker/linux-aarch64/Dockerfile` — the native `linux/arm64`
  release host. An Apple Silicon Mac runs it natively
  (`docker run --rm --platform linux/arm64 ubuntu:24.04 uname -m` →
  `aarch64`).
- `tools/release_local.w` — `with run tools/release_local.w vX.Y.Z
  [--channel test] [--skip-darwin] [--skip-linux-aarch64]`, with `GH_TOKEN`
  and `RELEASE_SOURCE_SHA` set. Runs the darwin gates, `:release-uat`,
  packaging and publish-first, then the same inside the container for
  linux-aarch64. It type-checks; **it has never been run end to end.**
- `.github/workflows/nightly-release.yml` — `darwin-aarch64` moved out of
  the unix matrix into its own `build-darwin-aarch64` job; it and
  `build-linux-aarch64` are gated `if: github.event_name != 'push'`, so a
  `v*` tag push builds only linux-x86_64, windows-x86_64 and
  windows-aarch64, while the nightly and test channels still exercise all
  five.
- `docs/with-release-runbook.md` — two new sections: "Linux aarch64 Release
  Host (Docker on Apple Silicon)" and "Local-first: the Mac publishes
  darwin and linux-aarch64; CI appends the rest".

## 3. What #1155 fixes, per leg, with evidence

Diagnosed from failed run `35102512299` and the test-channel run
`35134417320` dispatched on the branch.

| leg | failure | root cause | status |
|---|---|---|---|
| linux-aarch64 | `seed-driver: … is not the pinned seed v0.15.2.0 (79a63ff…)` | `release_asset_for_host()` / `supported_release_platform_tag()` in `build.w` had no linux-aarch64 case and fell through to the darwin asset. That also fed test-green, last-green, seed and the SDK asset name. | **fixed**; the gate prints "the driver is the pinned seed v0.15.2.0" in the test-channel run |
| linux-aarch64 | `ld.lld: undefined symbol: with_vec_append_bytes` in one spec test | That test is the single `known-issue #916` file. #916 **does not reproduce on aarch64**: a native container build ran 210 spec files and it failed the known-issue gate with "expected red but passed". | **scoped** `skip-on: linux-aarch64`; the CI-side link residue is #1156 |
| windows-aarch64 | `nm failed for emit_obj_globals` / bundle object | The Release job never exported `NM`; the runner's MSYS `nm` cannot parse an arm64 COFF image. `selfhost-windows-aarch64.yml` already sets it. | **fixed**: `NM=<sdk>/bin/llvm-nm.exe` |
| windows-x86_64 | `last-green: stale test pass marker` | The gates relink the release compiler on every step on every platform (#1157); only on Windows did the bytes change, because lld-link stamps the PE header and PDB GUID from the wall clock. Fixpoint compares emitted objects, never the linked image, so it never saw the churn. | **fixed**: `/Brepro` on the COFF link in `src/compiler/Link.w`; that leg now passes build, fixpoint, test and last-green |
| windows (both) | `could not rename out/release/bin/with.exe.tmp to with.exe` in the Release UAT step | The UAT step ran `./out/release/bin/with.exe build :release-uat`, and that target's `build` dependency relinks the very binary that is executing. Windows cannot replace a running executable. | **fixed**: the Windows UAT steps now run `./src/main.exe build :release-uat` (the seed drives; the UAT tests the *platform asset* either way) — **not yet validated by CI** |
| all | release UAT: zlib `raw c_import function call requires unsafe context`, sqlite3 `type mismatch in binding`, openssl `undefined variable` | **Not a compiler regression.** `with get` now fetches **zlib 1.3.2** and **OpenSSL 4.0.2**, whose headers reach three latent c_import generator gaps. The 09-06 release compiler v0.15.2.1 fails on them identically (verified directly). | **fixed** in `src/CImport.w`; zlib and sqlite3 UATs pass end to end locally |
| darwin, linux-x86_64 | openssl UAT: compiler **double free** | See §4, decision 1. | **open, #1158** |
| windows-x86_64 | bzip2 UAT exit 124 (timeout) | Windows-only; runs to "UAT passed" well inside the limit on darwin. | uncharacterized; watch the next run |

The three c_import generator fixes, all in `src/CImport.w`:

1. An object-like macro whose value is a **call** is recorded untranslated,
   like a function alias. A known C function would be a raw call at program
   start (`#define zlib_version zlibVersion()`), and a callee this import
   never emitted leaves a dangling name (`#define OSSL_DEPRECATEDIN_4_0
   OSSL_DEPRECATED(4.0)`). Referencing such a macro is now the loud,
   allow-gated omission error.
2. Every type position now spells a raw C function pointer
   `unsafe extern "C" fn(...)`. The **constant-probe emitter**
   (`ci_try_translate_object_macro_probe`), the typedef alias resolver and
   `ci_infer_cast_return_type` had kept the safe spelling, so sqlite3's
   `#define SQLITE_STATIC ((sqlite3_destructor_type)0)` became
   `let SQLITE_STATIC: extern "C" fn(...) = (0 as unsafe extern "C" fn(...))`.
   *Finding the right emitter took three rebuild cycles; I did it by
   appending `// emit:<site>` markers to each candidate emitter's output
   line, rebuilding once, and reading which marker appeared. Use that trick
   again rather than guessing.*
3. `build/release_uat_fixtures/openssl_main.w` needed `use
   std.builtins.write` (import-gated by #750).

### Verified evidence on `4ecfddb0`

- Local seed-driven battery: `build`, `:fixpoint`, `:test`, `:test-green`,
  `:last-green` all rc=0.
- `:release-uat` rc=1, failing **only** `release-openssl-uat`. zlib,
  bzip2, sqlite3, libcurl, install-layout, raylib-spiral and one-liner all
  pass.
- zlib and sqlite3 UAT programs run to "UAT passed" with the rebuilt
  compiler; the untranslated-macro guard produces the correct loud error.
- linux-aarch64 built end to end in the container (build rc=0), and
  `out/lib/rt_core.o` exports `with_vec_append_bytes` while the seed's
  bundled `src/runtime/rt_core.o` does not — that asymmetry is #1156.

## 4. THE TWO BLOCKING DECISIONS

**Decision 1 — #1158, the openssl double free.** Modeling OpenSSL 4.0.2's
`evp.h`, the current compiler double-frees a HashMap in
`Zcu.compile_source_frontend_mode` on the c_import **error path**. lldb
backtrace is on the issue (`with_hashmap_free` ← `compile_source_frontend_mode`).
The 09-06 compiler v0.15.2.1 takes the same error path cleanly, so this is a
main regression since `d9091ce0`, and it is layout-dependent (#729 class):
it **disappears under `tools/debug_drop.w`**, which reports "clean". The
openssl UAT is a release gate. Options put to Eric:

- (a) chase it now — route is the drop-plan / `--trace-ownership` /
  `WITH_DEBUG_ALLOC_TRAP_FREE` sequence; hours, uncertain;
- (b) **pin the openssl UAT to the 3.x package for v0.15.2.2** and ship,
  with #1158 first post-release — *my recommendation*;
- (c) waive the openssl UAT for this release.

Note the generator fix in #1155 stops the *dangling-macro* error, so with
option (b) the openssl UAT should pass on 3.x. Confirm that before relying
on it.

**Decision 2 — windows-aarch64 placement.** No Mac can build it, so I left
it on CI with the x86_64 legs. Eric has not confirmed. If he wants it
elsewhere, the gate to change is `build-windows-aarch64`'s `if:` in
`nightly-release.yml`.

## 5. Exact next steps once the decisions land

1. Apply the openssl decision (likely: pin the UAT's package version, then
   rerun `:release-uat` locally to confirm it is green).
2. Watch the test-channel run already dispatched on `4ecfddb0`:
   **`gh run view 35143254857 --repo withlang-dev/with`**. It was `pending`
   (queued behind run `35134417320`, same concurrency group) at handoff.
   It is the first validation of the NM fix, the Windows UAT-driver fix and
   the generator fixes on CI. The earlier run `35134417320` is pre-fix and
   is diagnostic only — its failures are all explained above.
3. When that run is green on linux-x86_64, windows-x86_64 and
   windows-aarch64: bump `src/version` to `v0.15.2.2`, commit, merge #1155
   to main.
4. Tag at the merge commit and push the tag. **The tag push must come
   before `release_local.w`** — publish-first refuses a commit the
   repository does not have.
5. `export GH_TOKEN=$(gh auth token); export RELEASE_SOURCE_SHA=$(git
   rev-parse v0.15.2.2); with run tools/release_local.w v0.15.2.2`. This
   has never been run; expect to debug it. `--skip-linux-aarch64` /
   `--skip-darwin` rerun one half.
6. CI appends linux-x86_64, windows-x86_64 and windows-aarch64 from the tag
   push.
7. Post-publish: verify the asset list per the runbook's "Post-Publish
   Checks", then consider bumping `seed.lock` to v0.15.2.2 (a separate,
   deliberate step — see the runbook's Publish section).
8. **After the release ships**, flip the deferred D42 surface to `cos(x)`:
   `build/release_uat_fixtures/raylib_spiral_main.w`, the spiral release
   UAT, and the withlang.org homepage example in
   `~/withlang-dev.github.io/index.html` (they still declare `extern fn
   sin/cos`). Eric ruled: "flip only after a release ships the new
   compiler," because the site promises its examples compile on the current
   release.

## 6. Issues filed today

- **#1153** — migrate: stop emitting `pub extern fn` for libm names that
  are now compiler builtins (D42 fallout; not blocking, user code is
  already correct via builtin-over-extern precedence).
- **#1156** — linux-aarch64 `:test` link failure residue (the CI harness
  resolves a stale runtime object for one spec file; the container does
  not).
- **#1157** — the seed-driven gates relink stage2 + the release compiler on
  every step (~2.5–3.5 min each). I confirmed the mechanism: after a
  completed `build`, `--explain stage2` says **fresh**, but the first
  invocation of the *next* gate reports `stale: action signature changed`.
  The signature (`build_cache_compute_signature`) mixes in the driver's
  content fingerprint and, for stage targets, a hash of `src/` and the
  `compiler=` path — so something a gate step writes changes it. Not yet
  root-caused; this is the cheapest large win available (~10 min per
  release leg and per local battery).
- **#1158** — the openssl double free (decision 1).

Also commented: **#916** (does not reproduce on linux-aarch64) and **#1144**
(closed by #1152).

## 7. Environment traps — expensive to rediscover

- **A fresh worktree cannot build.** It has no `src/main` seed and no
  `.deps` SDK. Fix: `cp ~/with/src/main src/main` (or `with build :seed`)
  and `mkdir -p .deps && ln -sfn ~/with/.deps/llvm-22.1.6-darwin-arm64
  .deps/` plus the `-release` sibling.
- **Read `rc=` from your own log.** `with build`'s exit code reaches the
  Bash tool as 0 even when the build fails. Every background build here
  appends `echo "… rc=$?"` to its log for that reason.
- **`:dev` writes `out/bootstrap/bin/with-stage1`**, not `out/stage/bin/`.
- **Three failures are pre-existing on a bootstrap stage1** and are not
  your regression (verified against a clean base-commit build):
  `test/spec/spec_ss16_ffi_and_c_import.w` (stdio.h opaque-struct errors),
  `with-stage1 -e '…'` ("conflicting global declaration for 'stdin'"), and
  `test/benchmark/hash_engines.w` (does not parse, not in any corpus).
- **Bisecting old commits on this Mac needs `SDKROOT`.** Xcode 26's
  `libm.tbd` lists `arm64e.x1-macos`, which ld64.lld 22 rejects; export
  `SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk`. And
  when you kill `git bisect run`, kill its in-flight `build :dev` too
  (match by cwd via `lsof`), or every later step dies instantly with
  "another build is already running" and is recorded as a skip.
- **The arm64 container needs `g++` and `libxml2`** or it fails *silently*
  — the seed prints only "build failed". That is exactly why the Dockerfile
  is checked in. Add `--cap-add=SYS_PTRACE --security-opt seccomp=unconfined`
  when you need `strace` (which is how I found the missing `libstdc++`).
- **Use the zvec-grep tools for workspace search** (`zvec_grep_rg`,
  `zvec_grep_search`), not `git grep` in Bash. Eric flagged this. The MCP
  server may show as disconnected at session start and reconnect later;
  load the tools via ToolSearch when it does. The `release` worktree has no
  index — run searches against `/Users/eric/with`.

## 8. Standing rules

Commits authored `Eric Hartford <eric@quixi.ai>`, never any AI attribution.
Never `git stash`. No python/bash/perl/sed/awk for scripting — With
one-liners or `with run tool.w`. Never `-O0`. Take a `keep_awake` hold for
long runs (this laptop sleeps and kills detached work). The Bash tool is
zsh, so an unquoted `$OPTS` is one argument. Never cite a commit hash you
have not printed. The battery runs under the pinned seed
(`WITH=$PWD/src/main src/main build …`); `seed-driver` refuses any other
driver.
