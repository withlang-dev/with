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

## Release Asset

Publish platform compiler binaries as:

```text
with-darwin-aarch64
with-linux-x86_64
with-bootstrap-c-vX.Y.Z.tar.zst
```

Do not publish a binary asset named `main`. `src/main` is the local seed path;
it is not the release asset name.

Seed download paths must use the host-specific asset name:

- `Makefile` fallback `make seed`
- `build.w` target `with build :seed`

Current seed assets:

```text
Darwin arm64: with-darwin-aarch64
Linux x86_64: with-linux-x86_64
```

## Verification

Start from a clean worktree on `main`.

```sh
git status -sb
git pull --ff-only
```

Set the release version explicitly:

```sh
export WITH_VERSION=v0.14.3
```

Run the release gates with the primary build interface on every release
platform:

```sh
with build
with build :fixpoint
with build :test
```

Run the emitted-C self-host check before publishing a platform for the first
time, and whenever emit-C or bootstrap packaging changed:

```sh
with build :emit-c-fixpoint
```

Confirm the produced compiler reports the release version:

```sh
out/bin/with version
```

Expected output:

```text
with v0.14.3
```

Install the verified compiler locally after the gates pass:

```sh
cp out/bin/with ~/.local/bin/with
chmod +x ~/.local/bin/with
~/.local/bin/with version
```

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
```

Confirm the tag points at the verified commit:

```sh
git rev-parse --short HEAD
git rev-parse --short v0.14.3^{}
```

Confirm the seed downloader still points at the published asset name:

```sh
rg -n 'with-darwin-aarch64|with-linux-x86_64|releases/download/.*/main|seed\.arg\("main"\)' Makefile build.w
```
