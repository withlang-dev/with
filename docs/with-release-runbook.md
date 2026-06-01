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
already built from source (`tools/build-static-llvm.sh` →
`.deps/llvm-<ver>-<host>`), together with the resources the seed already carries
embedded (stdlib, runtime objects, and clang's builtin headers). Building LLVM
from source is **bootstrap's** job, for a brand-new
platform that has no seed yet. A release does not. Specifically, a release:

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

## Release Asset

Publish, per release:

```text
with-darwin-aarch64                          # Darwin arm64 compiler binary
with-linux-x86_64                            # Linux x86_64 compiler binary
with-bootstrap-c-vX.Y.Z.tar.zst              # emitted-C bootstrap bundle
with-llvm-sdk-<llvm-ver>-darwin-aarch64.tar.zst   # static LLVM SDK (Darwin arm64)
with-llvm-sdk-<llvm-ver>-linux-x86_64.tar.zst     # static LLVM SDK (Linux x86_64)
install.sh
```

Do not publish a binary asset named `main`. `src/main` is the local seed path;
it is not the release asset name.

### Static LLVM SDK asset

The build links the next compiler against the static LLVM/Clang/lld archives in
`.deps/llvm-<ver>-<host>`. So that a release (or any clean checkout) can obtain
that SDK without rebuilding LLVM from source or trusting a system LLVM, publish
it as a per-platform asset and let the build fetch it the same way it fetches
the seed (issue #313):

- **Package** (per platform, after the SDK exists in `.deps`):
  `scripts/package-llvm-sdk.sh` → `out/release/with-llvm-sdk-<llvm-ver>-<platform>.tar.zst`.
  It ships only what the build links against — `lib/*.a`, `lib/clang/<v>/include/`,
  and `bin/lld` (+ driver symlinks) and `bin/llvm-nm` — not `bin/clang` or the
  LLVM C++ `include/` tree, so the asset is ~65 MB, not ~2 GB.
- **Fetch**: `with build :deps` downloads
  `with-llvm-sdk-<COMPILER_LLVM_VERSION>-<host>.tar.zst` from the matching
  release and extracts it into `.deps/llvm-<ver>-<host>`. `WITH_LLVM_SDK_VERSION`
  pins the release tag; otherwise the newest release carrying the asset is used.
- The SDK bytes change only when `COMPILER_LLVM_VERSION` (`build/compiler.w`)
  bumps; publishing it on every release keeps each release self-describing.

Seed and SDK download paths must use the host-specific asset names:

- `with build :seed`
- `with build :deps`

Current per-host assets:

```text
Darwin arm64: with-darwin-aarch64   with-llvm-sdk-<llvm-ver>-darwin-aarch64.tar.zst
Linux x86_64: with-linux-x86_64     with-llvm-sdk-<llvm-ver>-linux-x86_64.tar.zst
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

Run the release gates with the primary build interface on every release
platform:

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
issue61-regression fixture directories, and seed archives beyond the retention
window. It does not remove `.deps/` or `out/release/`.

Run the emitted-C self-host check before publishing a platform for the first
time, and whenever emit-C or bootstrap packaging changed:

```sh
with build :emit-c-fixpoint
```

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

After the first build creates `out/bin/with` in the release worktree, use that
compiler for the remaining Linux gates and packaging:

```sh
export WITH=$PWD/out/bin/with

WITH_VERSION=$WITH_VERSION ./out/bin/with build :fixpoint
WITH_VERSION=$WITH_VERSION ./out/bin/with build :test
WITH_VERSION=$WITH_VERSION ./out/bin/with build :test-green
WITH_VERSION=$WITH_VERSION ./out/bin/with build :last-green
WITH_VERSION=$WITH_VERSION ./out/bin/with version
WITH_VERSION=$WITH_VERSION scripts/package-linux-x86_64.sh
```

Copy the Linux asset back to the macOS release checkout before creating the
GitHub release:

```sh
scp quixi@192.168.86.211:~/with-release-$WITH_VERSION/out/release/with-linux-x86_64 out/release/
```

Confirm the produced compiler reports the release version:

```sh
out/bin/with version
```

Expected output:

```text
with v0.14.3
```

Finalize the local development seeds after the gates pass. This step is
required: the release is not done until the compiler that this checkout will
use for the next self-host build (`out/bin/with`), the local bootstrap seed
(`src/main`), and the installed user compiler all report the released version.

```sh
with build :update-seed
with build :install-user
src/main version
out/bin/with version
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

Prepare the platform-named assets on their native platforms:

```sh
scripts/package-darwin-aarch64.sh
scripts/package-linux-x86_64.sh
scripts/package-bootstrap-c.sh
scripts/package-llvm-sdk.sh
```

`scripts/package-llvm-sdk.sh` runs on each native platform and packages that
host's `.deps/llvm-<ver>-<host>` static SDK into
`out/release/with-llvm-sdk-<llvm-ver>-<platform>.tar.zst`. Copy the Linux SDK
asset back alongside the Linux binary:

```sh
scp quixi@192.168.86.211:~/with-release-$WITH_VERSION/out/release/with-llvm-sdk-*-linux-x86_64.tar.zst out/release/
```

This produces platform assets under `out/release/` plus `install.sh`.
Each public binary is the verified compiler copied under its platform asset
name. It must not have dynamic LLVM, Clang, zlib, zstd, or libxml2 load
commands, and it must contain static libclang symbols. Linux release binaries
must also avoid dynamic `libstdc++` and `libgcc_s`; `libc`, `libm`, and the
platform dynamic loader are the only expected Linux runtime libraries. The
Darwin package script checks this with `otool -L` and `nm`; the Linux package
script checks with `ldd` and `nm`.

The bootstrap-C package produces
`out/release/with-bootstrap-c-$WITH_VERSION.tar.zst`. It is an emitted-C source
bundle for bringing up a new native platform before a With seed exists there.
It is not a release compiler binary.

Create the GitHub release:

```sh
gh release create v0.14.3 \
  out/release/with-darwin-aarch64 \
  out/release/with-linux-x86_64 \
  out/release/with-bootstrap-c-v0.14.3.tar.zst \
  out/release/with-llvm-sdk-*-darwin-aarch64.tar.zst \
  out/release/with-llvm-sdk-*-linux-x86_64.tar.zst \
  out/release/install.sh \
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
WITH_VERSION=v0.14.3 with build :emit-c-fixpoint
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
install.sh
with-bootstrap-c-v0.14.3.tar.zst
with-darwin-aarch64
with-linux-x86_64
with-llvm-sdk-<llvm-ver>-darwin-aarch64.tar.zst
with-llvm-sdk-<llvm-ver>-linux-x86_64.tar.zst
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
