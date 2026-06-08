# package-windows-x86_64.ps1 — stage and verify the Windows x86_64 release binary.
#
# Twin of scripts/package-linux-x86_64.sh and scripts/package-darwin-aarch64.sh,
# written in PowerShell to match the repo's Windows-tooling convention
# (tools/build-static-llvm.ps1 is the Windows counterpart of its .sh twin, and
# docs/with-bootstrap-runbook.md runs Windows release work "from Developer
# PowerShell"). Run from the x64 Developer PowerShell for VS so that dumpbin.exe
# is on PATH for the dependency gate.
#
# Written against docs/with-bootstrap-runbook.md (Failure Policy, Release
# Handoff). The normal native stage chain writes the release compiler under
# out\release\bin.
#
# Windows specifics vs the Unix scripts:
#   - Dependency gate uses `dumpbin /DEPENDENTS` (the project's documented Windows
#     "zero dynamic deps" check) in place of ldd / otool -L.
#   - The release asset is `with-windows-x86_64.exe`, because the downloaded
#     Windows compiler should be directly executable from File Explorer,
#     PowerShell, cmd.exe, and tools that infer executability from PATHEXT.
#   - The Unix `nm -g | clang_createIndex` positive symbol gate is not ported:
#     link.exe/lld-link don't emit a COFF symbol table for internal statics into
#     the final .exe, so llvm-nm can't see clang_createIndex there. The negative
#     dependency gate below is the load-bearing static-linking check; positive
#     proof lives in the CI build/fixpoint/test the Release Handoff mandates.

$ErrorActionPreference = "Stop"

$asset = "with-windows-x86_64.exe"
# Default assumes the normal `with build` release output; override if it differs.
$compiler = if ($env:WITH_RELEASE_COMPILER) { $env:WITH_RELEASE_COMPILER } else { "out\release\bin\with.exe" }
$releaseDir = if ($env:WITH_RELEASE_DIR) { $env:WITH_RELEASE_DIR } else { "out\release" }

$version = $env:WITH_VERSION
if (-not $version) {
    throw "set WITH_VERSION, for example WITH_VERSION=v0.14.3"
}

$onWindows = [System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform(
    [System.Runtime.InteropServices.OSPlatform]::Windows)
$arch = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture
if (-not $onWindows -or $arch -ne [System.Runtime.InteropServices.Architecture]::X64) {
    throw "this package script creates only Windows x86_64 artifacts"
}

function Require-Tool($name) {
    if (-not (Get-Command $name -ErrorAction SilentlyContinue)) {
        throw "missing required tool: $name"
    }
}

Require-Tool "dumpbin.exe"

if (-not (Test-Path -PathType Leaf $compiler)) {
    throw "missing compiler: $compiler"
}

New-Item -ItemType Directory -Force -Path $releaseDir | Out-Null
$output = Join-Path $releaseDir $asset
$staged = $output
Copy-Item -Path $compiler -Destination $staged -Force

$versionOutput = (& $staged version | Out-String).Trim()
if ($versionOutput -ne "with $version") {
    throw "release binary reported '$versionOutput', expected 'with $version'"
}

# Negative static-linking gate: the release binary must import no LLVM, Clang, or
# toolchain support DLL. The pattern is the DLL-name equivalent of the Unix list
# (clang/LLVM/libz/libxml2/zstd/libstdc++/libgcc_s). A correct static-CRT (/MT)
# build imports only OS DLLs (kernel32, ntdll, advapi32, ...), none of which match.
$dependents = & dumpbin.exe /nologo /DEPENDENTS $staged
if ($LASTEXITCODE -ne 0) {
    throw "dumpbin failed to read $staged"
}
if ($dependents | Select-String -Pattern 'clang|LLVM|zlib|libxml2|zstd|MSVCP|VCRUNTIME') {
    $dependents | ForEach-Object { Write-Host $_ }
    throw "release binary has forbidden dynamic compiler/support dependency"
}

# The Unix scripts copy scripts/install.sh into the release dir here. install.sh
# selects an asset by `uname` and has no Windows arm, so shipping it unmodified
# would fail for Windows users. A Windows installer is a separate follow-up.
Copy-Item -Path "scripts\install.ps1" -Destination (Join-Path $releaseDir "install.ps1") -Force
Copy-Item -Path "scripts\install.cmd" -Destination (Join-Path $releaseDir "install.cmd") -Force

$hash = (Get-FileHash -Algorithm SHA256 $output).Hash.ToLowerInvariant()
Write-Output "$hash  $output"
