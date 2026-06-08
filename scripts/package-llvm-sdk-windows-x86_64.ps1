# package-llvm-sdk-windows-x86_64.ps1 -- package the Windows static LLVM SDK.
#
# This is the Windows counterpart of scripts/package-llvm-sdk.sh. It packages
# the With-owned static LLVM/Clang/lld SDK that bootstrap already built; it
# does not build LLVM and it does not trust a system LLVM.
#
# Output:
#   out\release\with-llvm-sdk-<llvm-ver>-windows-x86_64.tar.zst
#
# The archive top-level directory is the SDK prefix basename
# (llvm-<ver>-windows-x86_64-msvc), so fetchers can extract it into .deps.

$ErrorActionPreference = "Stop"

$llvmVersion = if ($env:LLVM_VERSION) { $env:LLVM_VERSION } else { "22.1.6" }
$hostTag = "windows-x86_64-msvc"
$platform = "windows-x86_64"
$releaseDir = if ($env:WITH_RELEASE_DIR) { $env:WITH_RELEASE_DIR } else { "out\release" }
$prefix = if ($env:LLVM_PREFIX) { $env:LLVM_PREFIX } else { ".deps\llvm-$llvmVersion-$hostTag" }
$sdkBase = "llvm-$llvmVersion-$hostTag"
$asset = Join-Path $releaseDir "with-llvm-sdk-$llvmVersion-$platform.tar.zst"
$buildCache = if ($env:LLVM_BUILD_CACHE) { $env:LLVM_BUILD_CACHE } else { ".deps\build\llvm-$llvmVersion-$hostTag\CMakeCache.txt" }

function Require-Tool($name) {
    if (-not (Get-Command $name -ErrorAction SilentlyContinue)) {
        throw "missing required tool: $name"
    }
}

Require-Tool "tar.exe"
Require-Tool "zstd.exe"

$libclang = Join-Path $prefix "lib\libclang.lib"
if (-not (Test-Path -PathType Leaf $libclang)) {
    throw "static SDK not found at $libclang; build it first with tools\build-static-llvm.ps1"
}

if (-not (Test-Path -PathType Leaf $buildCache)) {
    throw "missing SDK build cache: $buildCache; package only SDKs built by tools\build-static-llvm.ps1 in this checkout"
}
$cacheText = Get-Content -Path $buildCache -Raw
if ($cacheText -notmatch "CMAKE_C_COMPILER:[^=]+=.*clang-cl(\\.exe)?" -or
    $cacheText -notmatch "CMAKE_CXX_COMPILER:[^=]+=.*clang-cl(\\.exe)?") {
    $compilerLines = ($cacheText -split "`n") | Where-Object { $_ -match "^CMAKE_(C|CXX)_COMPILER:" }
    throw "refusing to package SDK not built with clang-cl: $($compilerLines -join '; ')"
}
if ($cacheText -notmatch "CMAKE_ASM_MASM_COMPILER:[^=]+=.*llvm-ml64(\\.exe)?") {
    $asmLines = ($cacheText -split "`n") | Where-Object { $_ -match "^CMAKE_ASM_MASM_COMPILER:" }
    throw "refusing to package SDK not built with llvm-ml64 for x64 MASM assembly: $($asmLines -join '; ')"
}

foreach ($tool in @("clang.exe", "clang++.exe", "clang-cl.exe", "cmake.exe", "ninja.exe", "lld-link.exe", "llvm-lib.exe", "llvm-ml.exe", "llvm-ml64.exe", "llvm-nm.exe", "llvm-readobj.exe", "llvm-strip.exe")) {
    $path = Join-Path $prefix "bin\$tool"
    if (-not (Test-Path -PathType Leaf $path)) {
        throw "static SDK is missing required tool: $path"
    }
}

$clangInclude = Join-Path $prefix "lib\clang"
if (-not (Test-Path -PathType Container $clangInclude)) {
    throw "static SDK is missing clang builtin headers: $clangInclude"
}

New-Item -ItemType Directory -Force -Path $releaseDir | Out-Null
$stageRoot = Join-Path $releaseDir ".sdk-stage-windows"
$stage = Join-Path $stageRoot $sdkBase
Remove-Item -Recurse -Force -Path $stageRoot -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path (Join-Path $stage "lib") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $stage "bin") | Out-Null

Copy-Item -Path (Join-Path $prefix "lib\*.lib") -Destination (Join-Path $stage "lib") -Force
Copy-Item -Path $clangInclude -Destination (Join-Path $stage "lib") -Recurse -Force

foreach ($tool in @("clang.exe", "clang++.exe", "clang-cl.exe", "cmake.exe", "ninja.exe", "lld-link.exe", "llvm-lib.exe", "llvm-ml.exe", "llvm-ml64.exe", "llvm-nm.exe", "llvm-readobj.exe", "llvm-strip.exe")) {
    Copy-Item -Path (Join-Path $prefix "bin\$tool") -Destination (Join-Path $stage "bin") -Force
}
foreach ($tool in @("ctest.exe", "cpack.exe")) {
    $path = Join-Path $prefix "bin\$tool"
    if (Test-Path -PathType Leaf $path) {
        Copy-Item -Path $path -Destination (Join-Path $stage "bin") -Force
    }
}

$tarPath = Join-Path $releaseDir "with-llvm-sdk-$llvmVersion-$platform.tar"
$tarFullPath = [System.IO.Path]::GetFullPath($tarPath)
Remove-Item -Force -Path $tarPath, $asset -ErrorAction SilentlyContinue

Push-Location $stageRoot
try {
    tar.exe -cf $tarFullPath $sdkBase
}
finally {
    Pop-Location
}

zstd.exe -19 -T0 -f $tarPath -o $asset
Remove-Item -Recurse -Force -Path $stageRoot
Remove-Item -Force -Path $tarPath

$listing = tar.exe -tf $asset
if (-not ($listing | Select-String -SimpleMatch "$sdkBase/lib/libclang.lib")) {
    throw "packaged SDK is missing lib/libclang.lib"
}
if (-not ($listing | Select-String -Pattern "$([regex]::Escape($sdkBase))/lib/clang/.*/include/stddef.h")) {
    throw "packaged SDK is missing clang builtin headers"
}
foreach ($tool in @("clang.exe", "clang++.exe", "clang-cl.exe", "cmake.exe", "ninja.exe", "lld-link.exe", "llvm-lib.exe", "llvm-ml.exe", "llvm-ml64.exe", "llvm-nm.exe", "llvm-readobj.exe", "llvm-strip.exe")) {
    if (-not ($listing | Select-String -SimpleMatch "$sdkBase/bin/$tool")) {
        throw "packaged SDK is missing bin/$tool"
    }
}

$hash = (Get-FileHash -Algorithm SHA256 $asset).Hash.ToLowerInvariant()
$size = (Get-Item $asset).Length
Write-Output "packaged static LLVM SDK: $asset"
Write-Output "  size: $size bytes"
Write-Output "$hash  $asset"
