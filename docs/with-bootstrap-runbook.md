# With Release Bootstrap Runbook

This runbook describes how to bring With up on a new release platform and
produce a single-file compiler binary for that platform.

For publishing an already-supported platform release, use
`docs/with-release-runbook.md` instead.

## Goal

The release compiler for a platform is one executable:

```text
with
```

It must run on a clean system without an installed LLVM, Clang, libclang,
Homebrew, apt, pacman, Chocolatey, or Visual Studio toolchain dependency.

The normal compiler build must not require the `clang` executable. The only
acceptable external C compiler dependency is during emit-C bootstrap work for a
new platform.

## Required Inputs

For each release platform, build or fetch a pinned With-owned static LLVM SDK:

```text
llvm-static-sdk/
  bin/
    ld64.lld or ld.lld or lld-link
    llvm-nm
  include/
  lib/
    libclang.a              # Unix/macOS
    libLLVM*.a
    libclang*.a
```

On Windows/MSVC the required static C API archive is:

```text
lib/libclang.lib
```

Use the repo scripts to build this SDK:

```sh
HOST_TAG=darwin-arm64 tools/build-static-llvm.sh
HOST_TAG=linux-x86_64 tools/build-static-llvm.sh
```

On Windows, run from Developer PowerShell:

```powershell
.\tools\build-static-llvm.ps1
```

The scripts fail unless the static libclang archive exists and exports
`clang_createIndex`.

## Bootstrap Paths

There are two valid bootstrap paths.

### Path A: Existing With Seed

Use this when a working With seed already exists for the host.

1. Set the static SDK environment:

   ```sh
   export LLVM_PREFIX=/path/to/llvm-static-sdk
   export WITH_LIBCLANG="$LLVM_PREFIX/lib/libclang.a"
   export SDKROOT="$(xcrun --sdk macosx --show-sdk-path)"  # macOS only
   export WITH=/path/to/existing/with
   ```

2. Verify the toolchain:

   ```sh
   test -x "$LLVM_PREFIX/bin/ld64.lld" || test -x "$LLVM_PREFIX/bin/ld.lld"
   test -f "$WITH_LIBCLANG"
   "$LLVM_PREFIX/bin/llvm-nm" -g "$WITH_LIBCLANG" | rg clang_createIndex
   ```

3. Build the stage chain:

   ```sh
   make build
   make fixpoint
   make test
   ```

4. Verify the binary has no dynamic LLVM or Clang dependency:

   ```sh
   otool -L out/bin/with | rg 'clang|LLVM' && exit 1 || true
   ```

   On Linux:

   ```sh
   ldd out/bin/with | rg 'libclang|libLLVM' && exit 1 || true
   ```

5. Install only after all gates pass:

   ```sh
   make install-user
   ```

### Path B: Emit-C Bootstrap

Use this when no working With seed exists for the target platform.

This path may use an external C compiler temporarily. That dependency is only
for creating the first native With compiler.

1. On a supported host, generate the compiler C output:

   ```sh
   make emit-c-test
   ```

2. Transfer the emitted C source, runtime support C files, and static LLVM SDK
   to the target platform.

3. Compile the emitted C with the target platform C compiler, linking against
   the static LLVM SDK and static libclang archive.

4. Use the resulting native `with` as `WITH` on the target:

   ```sh
   export WITH=/path/to/native/bootstrap/with
   export LLVM_PREFIX=/path/to/llvm-static-sdk
   export WITH_LIBCLANG="$LLVM_PREFIX/lib/libclang.a"
   make build
   make fixpoint
   make test
   ```

5. Verify the final `out/bin/with` has no dynamic LLVM or Clang dependency.
   The temporary C compiler output is not the release asset unless it passes the
   full With stage-chain gates.

## Failure Policy

Do not work around missing static resources by linking dynamically.

The build must fail if any of these are true:

- `libclang.a` or `libclang.lib` is missing.
- The static libclang archive does not export `clang_createIndex`.
- The final release binary loads `libclang`, `libLLVM`, or any other LLVM/Clang
  dynamic library.
- The normal build path invokes `clang` as a linker driver.

If a platform cannot satisfy these constraints yet, it is not release-ready.

## Release Handoff

Once the new platform passes bootstrap gates:

1. Add the platform asset name to the release packaging scripts.
2. Add the platform to CI with its static LLVM SDK build/cache step.
3. Update `docs/with-release-runbook.md` with the new asset name and
   post-publish checks.
4. Publish only after the release runbook gates pass on the final asset.
