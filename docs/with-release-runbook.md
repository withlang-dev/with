# Release Process

This is the canonical checklist for publishing a With compiler release.

## Scope

Release work is packaging and verification. Do not make code changes during a
release unless the change directly blocks the release goal and the maintainer
has approved expanding scope.

If release prep exposes an unrelated bug:

1. Stop investigating once the release impact is clear.
2. File an issue with the repro, expected behavior, and actual behavior.
3. Continue the release only if the bug is not a release gate.

`emit-c-test`, `emit-c-fixpoint`, and `emit-c-roundtrip` are manual emit-C
feature/sprint targets. They are not normal release gates. The default
`:test` target already includes the fast emit-C smoke.

## Toolchain: reuse what bootstrap built — never rebuild, never trust the system

A release **reuses** the static LLVM/Clang/lld SDK that the *bootstrap* runbook
already built from source into `.deps/llvm-<ver>-<host>`, together with the
resources the seed already carries embedded (stdlib, runtime objects, and
clang's builtin headers). Building LLVM from source is **bootstrap's** job, for
a brand-new platform that has no seed yet. A release does not. Specifically, a
release:

- does **not** rebuild LLVM from source;
- does **not** fetch, link against, or otherwise trust a system-installed LLVM —
  we did not build it, and it will not have the static `.a` / resources we need;
- does **not** resolve any LLVM/Clang resource (archive *or* header) from an
  external path at runtime. If a release build or test needs
  `WITH_CLANG_RESOURCE_DIR`, `LLVM_PREFIX`, or `llvm-config` to locate clang's
  builtin headers at *runtime*, that is bug #312 — fix the embedding, do not
  configure the host around it.

`LLVM_PREFIX` / `WITH_LIBCLANG` appear below only as **build-time link inputs**
pointing at the already-built `.deps` SDK. They are reused, not rebuilt, and are
never a runtime dependency.

The reused SDK must itself have been built by the bootstrap runbook with Clang
from the pinned LLVM source tag. Do not release from an SDK whose CMake cache
names GCC, `/usr/bin/cc`, `/usr/bin/c++`, or MSVC `cl.exe` as the compiler.
The release package verification target must enforce this before publishing:

- Unix SDK package: `CMAKE_C_COMPILER=clang`, `CMAKE_CXX_COMPILER=clang++`.
- Windows SDK package: `CMAKE_C_COMPILER=clang-cl`,
  `CMAKE_CXX_COMPILER=clang-cl`, `CMAKE_ASM_MASM_COMPILER=llvm-ml64`.
- All SDK packages must include `bin/ninja` and `bin/cmake` built from source
  and installed by the bootstrap runbook. External Python/CMake may bootstrap
  those first SDK build tools, but release packaging must not publish an SDK
  that lacks either one.

Release-size comparisons are a toolchain parity check. The same LLVM source tag
must be compiled with Clang on every host and linked with the same retention
policy where the object format supports it. If one platform's `.text` is much
larger, investigate the SDK compiler, linker folding, and strip policy before
publishing.

If SDK package verification rejects the local SDK, stop before publishing that
platform's SDK. Do not upload an older or stale SDK just because the compiler
binary packaged cleanly. Refresh the SDK with the bootstrap toolchain flow, then
rerun the release packaging target with `LLVM_PREFIX` and `LLVM_BUILD_CACHE`
pointed at the refreshed prefix/cache. The bootstrap runbook owns the
system-dependent first-SDK commands; this release runbook only consumes the
resulting With-owned SDK.

## Release Asset

Publish, per release:

```text
with-darwin-aarch64                          # Darwin arm64 compiler binary
with-linux-x86_64                            # Linux x86_64 compiler binary
with-windows-x86_64.exe                      # Windows x86_64 compiler binary
with-bootstrap-c-vX.Y.Z.tar.gz               # emitted-C bootstrap bundle
with-llvm-sdk-<llvm-ver>-darwin-aarch64.tar.gz    # static LLVM SDK (Darwin arm64)
with-llvm-sdk-<llvm-ver>-linux-x86_64.tar.gz      # static LLVM SDK (Linux x86_64)
with-llvm-sdk-<llvm-ver>-windows-x86_64.tar.gz    # static LLVM SDK (Windows x86_64)
```

Do not publish a binary asset named `main`. `src/main` is the local seed path;
it is not the release asset name.

Installer scripts are not part of the required post-seed release contract. A
release may temporarily attach shell, PowerShell, or CMD convenience installers
while the With-native installer path is being built, but normal release
verification and post-seed updates use `with build :install-user` and
`with build :update-seed`, not `scripts/install.*`.

### Static LLVM SDK asset

The build links the next compiler against the static LLVM/Clang/lld archives in
`.deps/llvm-<ver>-<host>`. So that a release (or any clean checkout) can obtain
that SDK without rebuilding LLVM from source or trusting a system LLVM, publish
it as a per-platform asset and let the build fetch it the same way it fetches
the seed (issue #313):

- **Package** (per platform, after the SDK exists in `.deps`):
  produce `out/release/with-llvm-sdk-<llvm-ver>-<platform>.tar.gz` through the
  With-native release packaging target. Until that target exists, SDK package
  publishing is tracked by `docs/eliminate-Makefile.md`; shell or PowerShell
  packaging helpers are not the post-seed release contract. The packaging
  target must refuse SDKs not built with Clang/clang-cl by the bootstrap SDK
  flow. It ships only what the build links against: `lib/*.a`,
  `lib/clang/<v>/include/`,
  `bin/ninja`, `bin/cmake`, `bin/clang`, `bin/lld` (+ driver symlinks),
  `bin/llvm-ml`/`bin/llvm-ml64` on Windows, `bin/llvm-nm`, and
  `bin/llvm-strip` — not the LLVM C++ `include/` tree, so the asset remains
  small while still carrying the With-owned build tools required by SDK
  production, emitted-C bootstrap, and release packaging.
- **Fetch**: `with build :deps` downloads
  `with-llvm-sdk-<COMPILER_LLVM_VERSION>-<host>.tar.gz` from the matching
  release and extracts it into `.deps/llvm-<ver>-<host>`. `WITH_LLVM_SDK_VERSION`
  pins the release tag; otherwise the newest release carrying the asset is used.
- The SDK bytes change only when `COMPILER_LLVM_VERSION` (`build/compiler.w`)
  bumps; publishing it on every release keeps each release self-describing.

Seed and SDK download paths must use the host-specific asset names:

- `with build :seed`
- `with build :deps`

Current per-host assets:

```text
Darwin arm64: with-darwin-aarch64   with-llvm-sdk-<llvm-ver>-darwin-aarch64.tar.gz
Linux x86_64: with-linux-x86_64     with-llvm-sdk-<llvm-ver>-linux-x86_64.tar.gz
Windows x86_64: with-windows-x86_64.exe with-llvm-sdk-<llvm-ver>-windows-x86_64.tar.gz
```

## Verification

Start from a clean worktree on `main`.

```sh
git status -sb
git pull --ff-only
```

Set the release version explicitly for the rest of the flow:

```sh
export WITH_VERSION=v0.14.3
```

Bump `src/version` to the release tag and commit it:

```sh
echo "$WITH_VERSION" >src/version
git add src/version
git commit -m "release: $WITH_VERSION"
```

Run the deterministic release gates with the primary build interface on every
release platform:

```sh
with build
with build :fixpoint
with build :test
with build :test-green
with build :last-green
```

`:test` runs the full suite and records current test evidence. `:test-green`
is a fast evidence check/recorder for that completed test run; it is not a
substitute for running `:test`. `:last-green` consumes the current fixpoint and
test evidence, records the seed that started the stage chain in
`out/.build-state/seed-input.json`, writes the verified compiler manifest to
`out/.build-state/last-green.json`, and archives the verified `out/bin/with`
under `out/seed-archive/`. The archive keeps the five most recent verified
seeds total. When the gates are current, `:last-green` must not rerun the test
suite.

If the working `out/` tree has accumulated old build leftovers, inspect and
then apply the bounded cleanup before packaging:

```sh
with build :prune
with build :prune-apply
```

The prune target removes stale `out/bin/*.tmp.*.dSYM` directories, stale
temporary runtime archive wrappers in `out/lib/` and `out/bootstrap-lib/`, stale
build-state files, stale retained test-graph compiler copies, stale
issue61-regression fixture directories, seed archives beyond the retention
window, and versioned release byproducts in `out/release/` beyond the five most
recent release versions. It does not remove `.deps/`, unversioned release
binaries, transitional installer byproducts, or platform SDK archives.

`with build :emit-c-fixpoint` is optional manual verification for emit-C feature
work. Do not treat it as a normal release gate unless the release scope
explicitly includes emit-C self-hosting changes.

Run the release UAT gate before uploading or publishing any release assets:

```sh
with build :release-uat
```

The platform-named asset the gates consume (`out/release/with-darwin-aarch64`
on Darwin arm64) is produced by the `:release-platform-asset` target, an
in-graph copy of `out/release/bin/with` that every UAT target depends on. Do
not copy it by hand; the build graph keeps it current with the verified build.
Note that the packaging script later overwrites this asset with the stripped
publishable binary, so run packaging after the final `:release-uat`; if UAT is
re-run afterwards, the asset is regenerated unstripped and packaging must be
redone before upload.

`:release-uat` is mandatory for every release. It includes:

- `:release-artifact-smoke-uat`, which runs the platform-named release binary
  asset (`out/release/with-darwin-aarch64`, `with-linux-x86_64`, or
  `with-windows-x86_64.exe`) through `version`, `-e`, and `run file.w`.
- `:release-fresh-project-uat`, which validates a clean `with init` project can
  run with the release asset.
- `:release-migrate-uat`, which validates a small C source migrates, checks,
  and runs.
- `:release-zlib-uat`, which validates the universal non-GUI C package path:
  `with init`, `with get c.zlib`, `use c_import("zlib.h")`, an in-memory
  `compress`/`uncompress` round trip, `zlibVersion`, and `with run`.
- `:release-bzip2-uat`, which validates `with get c.bzip2`,
  `use c_import("bzlib.h")`, and an in-memory
  `BZ2_bzBuffToBuffCompress`/`BZ2_bzBuffToBuffDecompress` round trip.
- `:release-sqlite3-uat`, which validates `with get c.sqlite3`,
  `use c_import("sqlite3.h")`, and an in-memory `:memory:` database
  `CREATE TABLE`/`INSERT`/`SELECT` round trip.
- `:release-openssl-uat`, which validates `with get c.openssl`,
  `use c_import("openssl/evp.h")`, and SHA-256 of `"abc"` through the EVP API
  against the standard digest bytes.
- `:release-libcurl-uat`, which validates `with get c.libcurl`,
  `use c_import("curl/curl.h")`, `curl_global_init`, `curl_easy_init`,
  `curl_easy_setopt`, `curl_version_info`, and cleanup without network access.
- `:release-install-layout-uat`, which copies the platform asset into a
  local install-style `bin/with` layout and runs it from there.
- `:release-raylib-spiral-uat`, which must run on a GUI-capable Darwin release
  host. It validates the user-facing C interop happy path end to end:
  `with init`, `with get c.raylib`, writing the spiral program to the
  initialized project's `src/main.w`, and `with run`. The generated raylib app
  renders a deterministic spiral, reads back the rendered framebuffer, counts
  bright non-background samples in the spiral annulus, and exits non-zero if the
  visual check fails.
- `:release-one-liner-uat`, which validates real shell one-liner workflows:
  `seq 100 | with -n 'if line =~ /^[0-9]$/: print(line)'`,
  `cat names.txt | with -p 'line = line.upper()'`, regex captures, numbered
  pipeline transforms, semicolon-separated transforms, and `--` argument
  passing.

If any UAT target fails, if the raylib window cannot be created, if the
framebuffer check does not see the spiral, if any required C package UAT does
not import/link/run, or if any one-liner prints different stdout than expected,
the release fails and must not be published.

### Darwin Release Host

The Darwin arm64 release host is the maintainer macOS checkout. Use a clean
release commit or the release tag. If the release tag already exists, prefer a
detached checkout of that tag for packaging so the asset bytes correspond to
the published tag:

```sh
git fetch origin --tags
git switch --detach "$WITH_VERSION"
```

Use the installed compiler as the first seed only for the first build, and
point the build at the already-built With-owned Darwin SDK:

```sh
export RELEASE_SEED=${RELEASE_SEED:-$HOME/.local/bin/with}
export LLVM_PREFIX=${LLVM_PREFIX:-$PWD/.deps/llvm-22.1.6-darwin-arm64}
export WITH=$RELEASE_SEED

WITH_VERSION=$WITH_VERSION "$RELEASE_SEED" build
```

After the first build creates `out/release/bin/with`, use that verified
compiler for the remaining Darwin gates:

```sh
export WITH=$PWD/out/release/bin/with

WITH_VERSION=$WITH_VERSION ./out/release/bin/with build :fixpoint
WITH_VERSION=$WITH_VERSION ./out/release/bin/with build :test
WITH_VERSION=$WITH_VERSION ./out/release/bin/with build :test-green
WITH_VERSION=$WITH_VERSION ./out/release/bin/with build :last-green
WITH_VERSION=$WITH_VERSION ./out/release/bin/with version
WITH_VERSION=$WITH_VERSION ./out/release/bin/with build :release-uat
```

The Darwin release package target must copy `out/release/bin/with`, verify the
reported version, check that LLVM/Clang/support libraries are not dynamically
loaded, confirm static libclang symbols before stripping, strip with the
With-owned SDK `llvm-strip`, and recheck dynamic dependencies after stripping.

### Linux Release Host

The current Linux x86_64 release host is:

```sh
ssh quixi@192.168.86.211
cd ~/with
```

`~/with` may contain local work in progress. Do not reset, clean, checkout, or
stash it for release work. If it is dirty, create a separate detached release
worktree from the fetched `origin/main` commit:

```sh
cd ~/with
git fetch origin --tags
git worktree add --detach ../with-release-$WITH_VERSION origin/main
cd ../with-release-$WITH_VERSION
```

Noninteractive SSH shells on this host do not currently put `with` on `PATH`.
Use the existing compiler from the main checkout as the first seed, and point
the clean worktree at the **already-built** static LLVM SDK from the main
checkout (the one bootstrap produced under `.deps` — we reuse it for linking,
we do not rebuild it, and it is a build-time input only, never consulted at
runtime):

```sh
export RELEASE_SEED=/home/quixi/with/out/bin/with
export LLVM_PREFIX=/home/quixi/with/.deps/llvm-22.1.6-linux-x86_64
export WITH=$RELEASE_SEED

WITH_VERSION=$WITH_VERSION $RELEASE_SEED build
```

After the first build creates `out/release/bin/with` in the release worktree,
use that compiler for the remaining Linux gates:

```sh
export WITH=$PWD/out/release/bin/with

WITH_VERSION=$WITH_VERSION ./out/release/bin/with build :fixpoint
WITH_VERSION=$WITH_VERSION ./out/release/bin/with build :test
WITH_VERSION=$WITH_VERSION ./out/release/bin/with build :test-green
WITH_VERSION=$WITH_VERSION ./out/release/bin/with build :last-green
WITH_VERSION=$WITH_VERSION ./out/release/bin/with version
```

Copy the Linux asset back to the macOS release checkout before creating the
GitHub release:

```sh
scp quixi@192.168.86.211:~/with-release-$WITH_VERSION/out/release/with-linux-x86_64 out/release/
```

Confirm the produced compiler reports the release version:

```sh
out/release/bin/with version
```

Expected output:

```text
with v0.14.3
```

Finalize the local development seeds after the gates pass. This step is
required: the release is not done until the compiler that this checkout will
use for the next self-host build (`out/release/bin/with`), the local bootstrap
seed (`src/main`), and the installed user compiler all report the released
version.

```sh
with build :update-seed
with build :install-user
src/main version
out/release/bin/with version
~/.local/bin/with version
```

Both commands must print:

```text
with v0.14.3
```

Do not leave a release with `src/main`, `out/bin/with`, or
`~/.local/bin/with` reporting an older version or a different development
build. If this check fails, rerun the release gates with `WITH_VERSION` still
set and stop before publishing.

## Publish

Create an annotated tag at the verified commit:

```sh
git tag -a v0.14.3 -m "v0.14.3"
git push origin main
git push origin v0.14.3
```

Prepare the platform-named assets on their native platforms with the
With-native release package targets. The bootstrap-C package target exists as
`with build :package-bootstrap-c`; platform compiler and SDK package targets
remain tracked by `docs/eliminate-Makefile.md` and must not be treated as a
normal post-seed script workflow until their graph replacements land.

The SDK package target runs on each native platform and packages that host's
`.deps/llvm-<ver>-<host>` static SDK into
`out/release/with-llvm-sdk-<llvm-ver>-<platform>.tar.gz`. Copy the Linux SDK
asset back alongside the Linux binary:

On Windows, the SDK package target packages the
`.deps\llvm-<ver>-windows-x86_64-msvc` SDK and includes the required CMake,
Clang/lld, and LLVM utility tools (`ninja.exe`, `cmake.exe`, `clang.exe`,
`clang++.exe`, `clang-cl.exe`, `lld-link.exe`, `llvm-lib.exe`, `llvm-ml.exe`,
`llvm-ml64.exe`, `llvm-nm.exe`, `llvm-readobj.exe`, `llvm-strip.exe`), static
`.lib` archives, and clang builtin headers.

```sh
scp quixi@192.168.86.211:~/with-release-$WITH_VERSION/out/release/with-llvm-sdk-*-linux-x86_64.tar.gz out/release/
```

This produces platform assets under `out/release/`. Transitional installer
byproducts are not required release assets and must not be used for post-seed
update instructions.
Each public binary is the verified compiler copied under its platform asset
name and stripped with the With-owned SDK `llvm-strip`. It must not have dynamic
LLVM, Clang, zlib, zstd, or libxml2 load commands, and it must contain static
libclang symbols before stripping. Linux release binaries must also avoid
dynamic `libstdc++` and `libgcc_s`; `libc`, `libm`, and the platform dynamic
loader are the only expected Linux runtime libraries. The release package
targets must check those properties with With-owned binary inspection tools, not
host loader or symbol utilities.

The bootstrap-C package is produced by:

```sh
with build :package-bootstrap-c
```

It writes `out/release/with-bootstrap-c-$WITH_VERSION.tar.gz`. It is an
emitted-C source bundle for bringing up a new native platform before a With seed
exists there. It is not a release compiler binary.

Create the GitHub release:

```sh
gh release create v0.14.3 \
  out/release/with-darwin-aarch64 \
  out/release/with-linux-x86_64 \
  out/release/with-bootstrap-c-v0.14.3.tar.gz \
  out/release/with-llvm-sdk-*-darwin-aarch64.tar.gz \
  out/release/with-llvm-sdk-*-linux-x86_64.tar.gz \
  out/release/with-llvm-sdk-*-windows-x86_64.tar.gz \
  --repo withlang-dev/with \
  --title "v0.14.3: <release title>" \
  --notes-file <release-notes.md>
```

The release notes verification section should list:

```text
WITH_VERSION=v0.14.3 with build
WITH_VERSION=v0.14.3 with build :fixpoint
WITH_VERSION=v0.14.3 with build :test
WITH_VERSION=v0.14.3 with build :test-green
WITH_VERSION=v0.14.3 with build :last-green
WITH_VERSION=v0.14.3 with build :release-uat
```

Do not list Make compatibility wrapper commands on the release page.

## Post-Publish Checks

Confirm the release exposes only the intended binary asset:

```sh
gh release view v0.14.3 \
  --repo withlang-dev/with \
  --json tagName,assets \
  --jq '{tagName, assets: [.assets[].name]}'
```

Expected asset list:

```text
with-bootstrap-c-v0.14.3.tar.gz
with-darwin-aarch64
with-linux-x86_64
with-windows-x86_64.exe
with-llvm-sdk-<llvm-ver>-darwin-aarch64.tar.gz
with-llvm-sdk-<llvm-ver>-linux-x86_64.tar.gz
with-llvm-sdk-<llvm-ver>-windows-x86_64.tar.gz
```

Confirm the tag points at the verified commit:

```sh
git rev-parse --short HEAD
git rev-parse --short v0.14.3^{}
```

Confirm the seed downloader still points at the published asset name:

```sh
rg -n 'with-darwin-aarch64|with-linux-x86_64|releases/download/.*/main|seed\.arg\("main"\)' build.w scripts docs/with-release-runbook.md
```
