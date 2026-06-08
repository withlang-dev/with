$ErrorActionPreference = "Stop"

$LLVM_VERSION = if ($env:LLVM_VERSION) { $env:LLVM_VERSION } else { "22.1.6" }
$LLVM_TAG = "llvmorg-$LLVM_VERSION"
$LLVM_SOURCE_SHA256 = if ($env:LLVM_SOURCE_SHA256) { $env:LLVM_SOURCE_SHA256 } else { "6e0b376a1f6d9873e7dfb09ae6e04b9c7024400f01733fa4c29be69d5c138bc2" }
$TARGETS = if ($env:LLVM_TARGETS_TO_BUILD) { $env:LLVM_TARGETS_TO_BUILD } else { "AArch64;X86" }

$ROOT = if ($env:ROOT) { $env:ROOT } else { Join-Path (Get-Location) ".deps" }
$HOST_TAG = if ($env:HOST_TAG) { $env:HOST_TAG } else { "windows-x86_64-msvc" }
$SRC_DIR = Join-Path $ROOT "src"
$BUILD_DIR = Join-Path $ROOT "build\llvm-$LLVM_VERSION-$HOST_TAG"
$INSTALL_PREFIX = if ($env:INSTALL_PREFIX) { $env:INSTALL_PREFIX } else { Join-Path $ROOT "llvm-$LLVM_VERSION-$HOST_TAG" }
$PARALLEL_JOBS = if ($env:PARALLEL_JOBS) { $env:PARALLEL_JOBS } else { "" }
$START_DIR = Get-Location

function Require-Tool($name) {
  if (-not (Get-Command $name -ErrorAction SilentlyContinue)) {
    throw "missing required tool: $name"
  }
}

Require-Tool "curl.exe"
Require-Tool "tar.exe"
$LLVM_BOOTSTRAP_CLANG_CL = if ($env:LLVM_BOOTSTRAP_CLANG_CL) { $env:LLVM_BOOTSTRAP_CLANG_CL } else { "clang-cl.exe" }
$LLVM_BOOTSTRAP_LLD_LINK = if ($env:LLVM_BOOTSTRAP_LLD_LINK) { $env:LLVM_BOOTSTRAP_LLD_LINK } else { "lld-link.exe" }
$LLVM_BOOTSTRAP_LLVM_ML = if ($env:LLVM_BOOTSTRAP_LLVM_ML) { $env:LLVM_BOOTSTRAP_LLVM_ML } else { Join-Path $INSTALL_PREFIX "bin\llvm-ml64.exe" }
$LLVM_BOOTSTRAP_MT = if ($env:LLVM_BOOTSTRAP_MT) { $env:LLVM_BOOTSTRAP_MT } else { "C:\Program Files (x86)\Windows Kits\10\bin\10.0.19041.0\x64\mt.exe" }
Require-Tool $LLVM_BOOTSTRAP_CLANG_CL
Require-Tool $LLVM_BOOTSTRAP_LLD_LINK
Require-Tool $LLVM_BOOTSTRAP_LLVM_ML
if (-not (Test-Path -PathType Leaf $LLVM_BOOTSTRAP_MT)) {
  throw "missing Windows SDK manifest tool: $LLVM_BOOTSTRAP_MT"
}
$sdkCmake = if ($env:SDK_CMAKE) { $env:SDK_CMAKE } else { Join-Path $INSTALL_PREFIX "bin\cmake.exe" }
$sdkNinja = if ($env:SDK_NINJA) { $env:SDK_NINJA } else { Join-Path $INSTALL_PREFIX "bin\ninja.exe" }
if (Test-Path -PathType Leaf $sdkCmake) {
  $CMAKE_TOOL = $sdkCmake
}
else {
  throw "missing SDK CMake: $sdkCmake; build it first with tools\build-cmake.ps1"
}
if (-not (Test-Path -PathType Leaf $sdkNinja)) {
  throw "missing SDK Ninja: $sdkNinja; build it first with tools\build-ninja.ps1"
}

New-Item -ItemType Directory -Force -Path $SRC_DIR | Out-Null
New-Item -ItemType Directory -Force -Path $BUILD_DIR | Out-Null
Set-Location $SRC_DIR

$archive = "llvm-project-$LLVM_VERSION.src.tar.xz"
$sourceDir = "llvm-project-$LLVM_VERSION.src"

if (-not (Test-Path $sourceDir)) {
  if (-not (Test-Path $archive)) {
    curl.exe -L -O "https://github.com/llvm/llvm-project/releases/download/$LLVM_TAG/$archive"
  }

  $hash = (Get-FileHash $archive -Algorithm SHA256).Hash.ToLowerInvariant()
  if ($hash -ne $LLVM_SOURCE_SHA256) {
    throw "bad llvm source hash: $hash"
  }

  tar.exe -xf $archive
}

$cmakeArgs = @(
  "-G", "Ninja",
  "-S", (Join-Path $SRC_DIR "$sourceDir\llvm"),
  "-B", $BUILD_DIR,
  "-DCMAKE_BUILD_TYPE=Release",
  "-DCMAKE_C_COMPILER=$LLVM_BOOTSTRAP_CLANG_CL",
  "-DCMAKE_CXX_COMPILER=$LLVM_BOOTSTRAP_CLANG_CL",
  "-DCMAKE_ASM_MASM_COMPILER=$LLVM_BOOTSTRAP_LLVM_ML",
  "-DCMAKE_LINKER=$LLVM_BOOTSTRAP_LLD_LINK",
  "-DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX",
  "-DCMAKE_MAKE_PROGRAM=$sdkNinja",
  "-DCMAKE_MT=$LLVM_BOOTSTRAP_MT",
  "-DCMAKE_MSVC_RUNTIME_LIBRARY=MultiThreaded",
  "-DLLVM_ENABLE_PROJECTS=clang;lld",
  "-DLLVM_TARGETS_TO_BUILD=$TARGETS",
  "-DLIBCLANG_BUILD_STATIC=ON",
  "-DLLVM_ENABLE_PIC=OFF",
  "-DBUILD_SHARED_LIBS=OFF",
  "-DLLVM_BUILD_LLVM_DYLIB=OFF",
  "-DLLVM_LINK_LLVM_DYLIB=OFF",
  "-DCLANG_LINK_CLANG_DYLIB=OFF",
  "-DLLVM_INCLUDE_TESTS=OFF",
  "-DLLVM_INCLUDE_BENCHMARKS=OFF",
  "-DLLVM_INCLUDE_EXAMPLES=OFF",
  "-DCLANG_INCLUDE_TESTS=OFF",
  "-DCLANG_BUILD_EXAMPLES=OFF",
  "-DLLVM_ENABLE_ZLIB=OFF",
  "-DLLVM_ENABLE_ZSTD=OFF",
  "-DLLVM_ENABLE_DIA_SDK=OFF"
)

& $CMAKE_TOOL @cmakeArgs
if ($LASTEXITCODE -ne 0) { throw "LLVM CMake configure failed" }

$oldPath = $env:PATH
try {
  $env:PATH = "$(Split-Path $LLVM_BOOTSTRAP_MT);$(Split-Path $LLVM_BOOTSTRAP_LLVM_ML);$oldPath"
  if ($PARALLEL_JOBS) {
    & $CMAKE_TOOL --build $BUILD_DIR --target install --parallel $PARALLEL_JOBS
  }
  else {
    & $CMAKE_TOOL --build $BUILD_DIR --target install --parallel
  }
  if ($LASTEXITCODE -ne 0) { throw "LLVM CMake build failed" }
}
finally {
  $env:PATH = $oldPath
}

$libclang = Join-Path $INSTALL_PREFIX "lib\libclang.lib"
if (-not (Test-Path $libclang)) {
  throw "static libclang archive was not installed: $libclang"
}

$clang = Join-Path $INSTALL_PREFIX "bin\clang.exe"
if (-not (Test-Path $clang)) {
  throw "missing clang driver in static SDK: $clang"
}

$clangxx = Join-Path $INSTALL_PREFIX "bin\clang++.exe"
if (-not (Test-Path $clangxx)) {
  throw "missing clang++ driver in static SDK: $clangxx"
}

$nm = Join-Path $INSTALL_PREFIX "bin\llvm-nm.exe"
if (-not (Test-Path $nm)) {
  throw "missing llvm-nm in static SDK: $nm"
}

& $nm -g $libclang | findstr "clang_createIndex" | Out-Null
if ($LASTEXITCODE -ne 0) {
  throw "$libclang does not export clang_createIndex"
}

Write-Host "static LLVM SDK ready: $INSTALL_PREFIX"
Write-Host "`$env:LLVM_PREFIX=`"$INSTALL_PREFIX`""
Write-Host "`$env:WITH_LIBCLANG=`"$libclang`""
Set-Location $START_DIR
