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

Publish the Darwin arm64 compiler binary as:

```text
with-darwin-aarch64
```

Do not publish a binary asset named `main`. `src/main` is the local seed path;
it is not the release asset name.

Both seed download paths must use `with-darwin-aarch64`:

- `Makefile` fallback `make seed`
- `build.w` target `with build :seed`

## Verification

Start from a clean worktree on `main`.

```sh
git status -sb
git pull --ff-only
```

Set the release version explicitly:

```sh
export WITH_VERSION=v0.14.0
```

Run the release gates with the primary build interface:

```sh
with build
with build :fixpoint
with build :test
```

Confirm the produced compiler reports the release version:

```sh
out/bin/with version
```

Expected output:

```text
with v0.14.0
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
git tag -a v0.14.0 -m "v0.14.0"
git push origin main
git push origin v0.14.0
```

Prepare the platform-named asset:

```sh
scripts/package-darwin-aarch64.sh
```

This produces `out/release/with-darwin-aarch64` and `out/release/install.sh`.
The public Darwin binary is the verified compiler copied under the platform
asset name. It must not have dynamic LLVM, Clang, zlib, zstd, or libxml2 load
commands, and it must contain static libclang symbols. The package script
checks this with `otool -L` and `nm`.

Create the GitHub release:

```sh
gh release create v0.14.0 \
  out/release/with-darwin-aarch64 \
  out/release/install.sh \
  --repo withlang-dev/with \
  --title "v0.14.0: <release title>" \
  --notes-file <release-notes.md>
```

The release notes verification section should list:

```text
WITH_VERSION=v0.14.0 with build
WITH_VERSION=v0.14.0 with build :fixpoint
WITH_VERSION=v0.14.0 with build :test
```

Do not list Make compatibility wrapper commands on the release page.

## Post-Publish Checks

Confirm the release exposes only the intended binary asset:

```sh
gh release view v0.14.0 \
  --repo withlang-dev/with \
  --json tagName,assets \
  --jq '{tagName, assets: [.assets[].name]}'
```

Expected asset list:

```text
install.sh
with-darwin-aarch64
```

Confirm the tag points at the verified commit:

```sh
git rev-parse --short HEAD
git rev-parse --short v0.14.0^{}
```

Confirm the seed downloader still points at the published asset name:

```sh
rg -n 'with-darwin-aarch64|releases/download/.*/main|seed\.arg\("main"\)' Makefile build.w
```
