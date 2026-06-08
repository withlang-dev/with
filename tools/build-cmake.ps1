$ErrorActionPreference = "Stop"

$CMAKE_VERSION = if ($env:CMAKE_VERSION) { $env:CMAKE_VERSION } else { "4.2.3" }
$CMAKE_SOURCE_SHA256 = if ($env:CMAKE_SOURCE_SHA256) { $env:CMAKE_SOURCE_SHA256 } else { "7efaccde8c5a6b2968bad6ce0fe60e19b6e10701a12fce948c2bf79bac8a11e9" }
$ROOT = if ($env:ROOT) { $env:ROOT } else { Join-Path (Get-Location) ".deps" }
$HOST_TAG = if ($env:HOST_TAG) { $env:HOST_TAG } else { "windows-x86_64-msvc" }
$SRC_DIR = Join-Path $ROOT "src"
$BUILD_DIR = Join-Path $ROOT "build\cmake-$CMAKE_VERSION-$HOST_TAG"
$INSTALL_PREFIX = if ($env:INSTALL_PREFIX) { $env:INSTALL_PREFIX } else { Join-Path $ROOT "llvm-22.1.6-$HOST_TAG" }
$START_DIR = Get-Location

function Require-Tool($name) {
  $cmd = Get-Command $name -ErrorAction SilentlyContinue
  if (-not $cmd) {
    throw "missing required tool: $name"
  }
  $cmd.Source
}

$bootstrapCmake = if ($env:CMAKE_BOOTSTRAP_CMAKE) { $env:CMAKE_BOOTSTRAP_CMAKE } else { Require-Tool "cmake.exe" }
$clangCl = if ($env:CMAKE_BOOTSTRAP_CLANG_CL) { $env:CMAKE_BOOTSTRAP_CLANG_CL } else { Require-Tool "clang-cl.exe" }
$lldLink = if ($env:CMAKE_BOOTSTRAP_LLD_LINK) { $env:CMAKE_BOOTSTRAP_LLD_LINK } else { Require-Tool "lld-link.exe" }
$sdkNinja = if ($env:SDK_NINJA) { $env:SDK_NINJA } else { Join-Path $INSTALL_PREFIX "bin\ninja.exe" }
$mt = if ($env:CMAKE_MT) { $env:CMAKE_MT } else { "C:\Program Files (x86)\Windows Kits\10\bin\10.0.19041.0\x64\mt.exe" }
Require-Tool "curl.exe" | Out-Null
Require-Tool "tar.exe" | Out-Null
if (-not (Test-Path -PathType Leaf $sdkNinja)) {
  throw "missing SDK Ninja: $sdkNinja; build it first with tools\build-ninja.ps1"
}
if (-not (Test-Path -PathType Leaf $mt)) {
  throw "missing Windows SDK manifest tool: $mt"
}

New-Item -ItemType Directory -Force -Path $SRC_DIR | Out-Null
New-Item -ItemType Directory -Force -Path $BUILD_DIR | Out-Null
Set-Location $SRC_DIR

$archive = "cmake-$CMAKE_VERSION.tar.gz"
$sourceDir = "cmake-$CMAKE_VERSION"

if (-not (Test-Path $sourceDir)) {
  if (-not (Test-Path $archive)) {
    curl.exe -L -O "https://github.com/Kitware/CMake/releases/download/v$CMAKE_VERSION/$archive"
  }

  $hash = (Get-FileHash $archive -Algorithm SHA256).Hash.ToLowerInvariant()
  if ($hash -ne $CMAKE_SOURCE_SHA256) {
    throw "bad CMake source hash: $hash"
  }

  tar.exe -xzf $archive
}

$cmakeArgs = @(
  "-G", "Ninja",
  "-S", (Join-Path $SRC_DIR $sourceDir),
  "-B", $BUILD_DIR,
  "-DCMAKE_BUILD_TYPE=Release",
  "-DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX",
  "-DCMAKE_C_COMPILER=$clangCl",
  "-DCMAKE_CXX_COMPILER=$clangCl",
  "-DCMAKE_LINKER=$lldLink",
  "-DCMAKE_MAKE_PROGRAM=$sdkNinja",
  "-DCMAKE_MT=$mt",
  "-DCMAKE_MSVC_RUNTIME_LIBRARY=MultiThreaded",
  "-DCMAKE_USE_OPENSSL=OFF"
)

& $bootstrapCmake @cmakeArgs
if ($LASTEXITCODE -ne 0) { throw "CMake configure failed" }

& $bootstrapCmake --build $BUILD_DIR --config Release --target install --parallel
if ($LASTEXITCODE -ne 0) { throw "CMake build failed" }

$cmakeTool = Join-Path $INSTALL_PREFIX "bin\cmake.exe"
if (-not (Test-Path -PathType Leaf $cmakeTool)) {
  throw "CMake did not install to $cmakeTool"
}

Set-Location $START_DIR
Write-Host "CMake ready: $cmakeTool"
