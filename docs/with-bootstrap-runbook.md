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
    clang/<v>/include/      # clang builtin headers (stddef.h, stdarg.h, …)
```

The `lib/clang/<v>/include/` tree is **part of the SDK we build**, not an
afterthought: it holds the clang builtin headers `c_import` needs to parse
any C header. It is embedded into the binary (like the stdlib and runtime
objects) and served from inside — never fetched from a system or `.deps`
LLVM at runtime. See AGENTS.md → *Self-Contained Toolchain*.

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

**This is the only runbook that builds the static SDK from LLVM source.**
Building the `.a` archives and clang's builtin headers from source is a
bootstrap step — done once per platform, when no seed exists there yet. Once a
seed exists, a *release* (`docs/with-release-runbook.md`) **reuses** this
already-built SDK and the resources the seed embeds; it never rebuilds LLVM and
never falls back to a system LLVM. If you find yourself building LLVM during a
release, you are in the wrong runbook.

After building the SDK from source, package it so future releases (and clean
checkouts) can fetch it instead of rebuilding:

```sh
scripts/package-llvm-sdk.sh   # → out/release/with-llvm-sdk-<llvm-ver>-<platform>.tar.zst
```

Publish that asset with the platform's release (see `docs/with-release-runbook.md`
→ *Static LLVM SDK asset*). Thereafter `with build :deps` fetches it; LLVM is
built from source only when `COMPILER_LLVM_VERSION` bumps to an SDK no release
has published yet.

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
   WITH_VERSION=vX.Y.Z scripts/package-bootstrap-c.sh
   ```

2. Transfer or download `out/release/with-bootstrap-c-vX.Y.Z.tar.zst` and the
   static LLVM SDK to the target platform.

3. Compile the emitted C bundle with the target platform C compiler, linking
   against the static LLVM SDK and static libclang archive. The bundle includes
   emitted C for the compiler, LLVM bridge, Clang bridge, runtime core, and the
   target platform shim.

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

6. Before publishing the new platform, run the emitted-C self-host gate:

   ```sh
   make emit-c-fixpoint
   ```

   This builds binary A through the normal self-host path, emits the compiler
   to C, compiles that C to binary B with the host C compiler, then uses B to
   build binary C through the normal build path. A and C must be byte-identical.
   A mismatch is an emit-C bug, not a release packaging issue.

#### Windows x86_64 emitted-C bootstrap

Run the Windows bootstrap from Developer PowerShell. The bootstrap compiler is
temporary, but it must still link the With-owned static LLVM/libclang SDK and
must produce a matching PDB for debugger use.

Required tools:

```powershell
where.exe cl
where.exe clang
where.exe clang++
where.exe lld-link
where.exe llvm-nm
where.exe llvm-readobj
```

Required assets:

```text
with-bootstrap-c-vX.Y.Z.tar.zst
with-llvm-sdk-<llvm-ver>-windows-x86_64-msvc.tar.zst
```

The static Windows SDK must contain:

```text
bin\lld-link.exe
bin\llvm-nm.exe
bin\llvm-readobj.exe
include\
lib\libclang.lib
lib\LLVM*.lib
lib\clang\<v>\include\
```

If no Windows static SDK release asset exists yet, build it once from source:

```powershell
.\tools\build-static-llvm.ps1
```

Verify the static libclang archive:

```powershell
$LLVM_PREFIX = ".deps\llvm-22.1.6-windows-x86_64-msvc"
Test-Path "$LLVM_PREFIX\lib\libclang.lib"
& "$LLVM_PREFIX\bin\llvm-nm.exe" -g "$LLVM_PREFIX\lib\libclang.lib" |
  Select-String clang_createIndex
```

Unpack the emitted-C bundle:

```powershell
$Version = "vX.Y.Z"
$Work = "out\bootstrap-c-$Version"
New-Item -ItemType Directory -Force $Work | Out-Null
tar --zstd -xf "out\release\with-bootstrap-c-$Version.tar.zst" -C $Work
Set-Location $Work
```

Compile with CodeView debug records. Do not use DWARF for the MSVC target.
Use the static MSVC runtime so the bootstrap compiler does not pick up a Visual
Studio runtime DLL dependency while validating the self-contained path.

```powershell
$RepoRoot = (Resolve-Path "..\..").Path
$LLVM_PREFIX = Join-Path $RepoRoot ".deps\llvm-22.1.6-windows-x86_64-msvc"
$Obj = "obj-win"
New-Item -ItemType Directory -Force $Obj | Out-Null

$CommonCFlags = @(
  "-target", "x86_64-pc-windows-msvc",
  "-std=gnu11",
  "-O0",
  "-gcodeview",
  "-fms-runtime-lib=static",
  "-D_CRT_SECURE_NO_WARNINGS",
  "-Iruntime",
  "-I$LLVM_PREFIX\include"
)

& clang.exe @CommonCFlags `
  "-include" "runtime\wl_decls.h" `
  "-c" "src\with_compiler.c" `
  "-o" "$Obj\with_compiler.obj"

foreach ($File in @(
  "src\llvm_bridge.c",
  "src\clang_bridge.c",
  "src\windows_platform.c"
)) {
  $Name = [IO.Path]::GetFileNameWithoutExtension($File)
  & clang.exe @CommonCFlags "-c" $File "-o" "$Obj\$Name.obj"
}

foreach ($File in @(
  "src\rt_core.c",
  "src\panic_runtime.c",
  "src\regex_runtime.c",
  "src\fiber_stubs.c",
  "src\compat_runtime.c"
)) {
  $Name = [IO.Path]::GetFileNameWithoutExtension($File)
  & clang.exe @CommonCFlags `
    "-DWITH_RUNTIME_H" `
    "-include" "runtime\bootstrap_types.h" `
    "-c" $File `
    "-o" "$Obj\$Name.obj"
}
```

Warnings from emitted C are bootstrap failures unless this runbook explicitly
documents the warning and the source revision has an open issue for removing
it. Do not add broad warning suppressions as part of the canonical procedure.

Link with LLD through the C++ driver so the static LLVM C++ archives link
correctly. The link must emit `with-bootstrap.pdb` and reserve enough stack for
the generated bootstrap compiler.

```powershell
$Objs = Get-ChildItem $Obj -Filter *.obj | ForEach-Object { $_.FullName }
$LlvmLibs = @(
  "$LLVM_PREFIX\lib\libclang.lib"
) + (Get-ChildItem "$LLVM_PREFIX\lib" -Filter "LLVM*.lib" |
      Where-Object { $_.Name -ne "LLVM-C.lib" } |
      ForEach-Object { $_.FullName }) +
    (Get-ChildItem "$LLVM_PREFIX\lib" -Filter "lld*.lib" | ForEach-Object { $_.FullName }) +
    (Get-ChildItem "$LLVM_PREFIX\lib" -Filter "clang*.lib" | ForEach-Object { $_.FullName })

& clang++.exe `
  "-target" "x86_64-pc-windows-msvc" `
  "-fuse-ld=lld" `
  "-fms-runtime-lib=static" `
  @Objs `
  @LlvmLibs `
  "advapi32.lib" "ole32.lib" "oleaut32.lib" "shell32.lib" "version.lib" `
  "-Wl,/subsystem:console" `
  "-Wl,/debug" `
  "-Wl,/pdb:with-bootstrap.pdb" `
  "-Wl,/stack:67108864" `
  "-o" "with-bootstrap.exe"
```

The 64 MiB stack reserve is required for the current emitted-C bootstrap shape:
some generated compiler/runtime paths have large stack frames. If this becomes
unnecessary, remove it only after proving the generated code no longer needs it
under LLDB.

Do not link `LLVM-C.lib` from the SDK. On Windows that archive can be an import
library for `LLVM-C.dll`; the bootstrap must link the static LLVM component
archives directly and then prove that no LLVM/Clang DLL appears in the COFF
imports.

Verify the temporary bootstrap compiler:

```powershell
Test-Path .\with-bootstrap.exe
Test-Path .\with-bootstrap.pdb
& "$LLVM_PREFIX\bin\llvm-readobj.exe" --file-headers .\with-bootstrap.exe |
  Select-String "SizeOfStackReserve"
& "$LLVM_PREFIX\bin\llvm-readobj.exe" --coff-imports .\with-bootstrap.exe |
  Select-String "DLL name"
.\with-bootstrap.exe --version
.\with-bootstrap.exe --help
.\with-bootstrap.exe check rt\windows_x86_64.w
```

The stack reserve must report `67108864` unless this runbook has been updated
with a smaller proven value. The COFF imports must not include `LLVM-C.dll`,
`libclang.dll`, `LLVM.dll`, any other LLVM/Clang DLL, or Visual Studio runtime
DLLs such as `VCRUNTIME*.dll`, `MSVCP*.dll`, or `UCRTBASE.dll`. Windows system
DLLs such as `KERNEL32.dll`, `ADVAPI32.dll`, `SHELL32.dll`, `ole32.dll`, and
`ntdll.dll` are acceptable.

If the process crashes, debug the exact binary that has the matching PDB:

```powershell
lldb.exe -b `
  -o "run" `
  -k "bt all" `
  -k "image lookup -a `$pc" `
  -- .\with-bootstrap.exe check build.w
```

Do not continue bootstrap with a crashing seed.

Run the normal stage chain from the repository root:

```powershell
Set-Location $RepoRoot
$env:WITH = (Resolve-Path (Join-Path $RepoRoot "$Work\with-bootstrap.exe")).Path
$env:LLVM_PREFIX = (Resolve-Path ".deps\llvm-22.1.6-windows-x86_64-msvc").Path
$env:WITH_LIBCLANG = Join-Path $env:LLVM_PREFIX "lib\libclang.lib"

with build
with build :fixpoint
with build :test
```

The release candidate is the verified stage-chain output, not
`with-bootstrap.exe`.

### Scope of the C backend (why some intrinsics are LLVM-only)

The C backend (`--emit-c`) exists for exactly one job: this no-LLVM bootstrap.
It only has to emit **the compiler's own source** — nothing more. User programs
are always compiled through the LLVM backend (the release binary embeds its own
LLVM/libclang), so they never route through `--emit-c`.

Consequently several intrinsic families are **LLVM-only by design**, and the C
backend loudly `self.fail(...)`s on them instead of lowering them: dyn-trait
method dispatch, `MultiIndex`, `Vec.get_disjoint` (tuple-valued slots),
`SlotMap`, and `VecRange` (plus their `len32`/`len64`/`ulen32` variants). The
compiler does not use any of these internally, so they can never block this
bootstrap. The guarantee is enforced, not assumed: if a future compiler change
starts using one of them, the `make emit-c-fixpoint` gate above fails loudly and
points at it.

Reaching LLVM↔C parity for these families is therefore **not a requirement**
(issue #301). Keep the loud failure; never add a silent fallback to make
`--emit-c` pass. The only emit-C gaps worth fixing are ones the *compiler's own
source* hits — those surface as `emit-c-fixpoint` failures.

## Failure Policy

Do not work around missing static resources by linking dynamically.

The build must fail if any of these are true:

- `libclang.a` or `libclang.lib` is missing.
- The static libclang archive does not export `clang_createIndex`.
- The final release binary loads `libclang`, `libLLVM`, or any other LLVM/Clang
  dynamic library.
- The bootstrap or final Windows compiler imports Visual Studio runtime DLLs
  instead of using the static MSVC runtime.
- The normal build path invokes `clang` as a linker driver.
- On Windows, `with-bootstrap.pdb` is missing for an emitted-C bootstrap build.
- On Windows, the bootstrap compiler is linked with the default 1 MiB stack
  reserve instead of the documented stack reserve.

The same rule applies to **resources, not just archives**. We build our own
static SDK; the binary embeds it; at runtime the compiler trusts only what it
embedded. A clean release host has no LLVM at all — not in `/usr`, not in
`.deps`. So:

- `c_import` must obtain clang's builtin headers (`stddef.h`, …) from the
  embedded resource dir, never from a system path, `LLVM_PREFIX`, `llvm-config`,
  or `WITH_CLANG_RESOURCE_DIR` discovered at runtime.
- Any runtime lookup that probes the filesystem for an LLVM/Clang resource is a
  bug, even if it happens to succeed on a dev box that has LLVM installed. We
  did not build that LLVM, so we do not trust it — and it will not have the
  static resources we need anyway.

If a platform cannot satisfy these constraints yet, it is not release-ready.

## Release Handoff

Once the new platform passes bootstrap gates:

1. Add the platform asset name to the release packaging scripts.
2. Add the platform to CI with its static LLVM SDK build/cache step.
3. Update `docs/with-release-runbook.md` with the new asset name and
   post-publish checks.
4. Publish only after the release runbook gates pass on the final asset.

## Current Release Platform Notes

Linux x86_64 is now a release platform with asset name:

```text
with-linux-x86_64
```

Lessons from the first Linux bootstrap:

- Do not use Darwin runtime objects as normal Linux link inputs. Non-host
  runtime object symbols may be embedded as empty blobs only so one compiler
  binary can carry both symbol names.
- Emit-C C compilation must select the host platform runtime object and host
  linker flags. Linux x86_64 uses `rt_linux_x86_64.o`, `-no-pie`, and `-lm`.
- The seed downloader must choose the release asset for the host platform.
  `with-darwin-aarch64` is not a valid Linux seed.
- Release version generation depends on both `WITH_VERSION` and the current
  Git ref. If a release build reports an old commit hash, rebuild the generated
  compiler entrypoints before packaging; the build graph now declares those
  inputs explicitly.
