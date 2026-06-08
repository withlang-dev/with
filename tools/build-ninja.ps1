$ErrorActionPreference = "Stop"

$NINJA_VERSION = if ($env:NINJA_VERSION) { $env:NINJA_VERSION } else { "1.13.1" }
$NINJA_SOURCE_SHA256 = if ($env:NINJA_SOURCE_SHA256) { $env:NINJA_SOURCE_SHA256 } else { "f0055ad0369bf2e372955ba55128d000cfcc21777057806015b45e4accbebf23" }
$ROOT = if ($env:ROOT) { $env:ROOT } else { Join-Path (Get-Location) ".deps" }
$HOST_TAG = if ($env:HOST_TAG) { $env:HOST_TAG } else { "windows-x86_64-msvc" }
$SRC_DIR = Join-Path $ROOT "src"
$INSTALL_PREFIX = if ($env:INSTALL_PREFIX) { $env:INSTALL_PREFIX } else { Join-Path $ROOT "llvm-22.1.6-$HOST_TAG" }

function Require-Tool($name) {
  $cmd = Get-Command $name -ErrorAction SilentlyContinue
  if (-not $cmd) {
    throw "missing required tool: $name"
  }
  $cmd.Source
}

$python = if ($env:NINJA_BOOTSTRAP_PYTHON) { $env:NINJA_BOOTSTRAP_PYTHON } else { Require-Tool "python.exe" }
$clangCl = if ($env:NINJA_BOOTSTRAP_CLANG_CL) { $env:NINJA_BOOTSTRAP_CLANG_CL } else { Require-Tool "clang-cl.exe" }
$lldLink = if ($env:NINJA_BOOTSTRAP_LLD_LINK) { $env:NINJA_BOOTSTRAP_LLD_LINK } else { Require-Tool "lld-link.exe" }
Require-Tool "curl.exe" | Out-Null
Require-Tool "tar.exe" | Out-Null

New-Item -ItemType Directory -Force -Path $SRC_DIR | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $INSTALL_PREFIX "bin") | Out-Null
Set-Location $SRC_DIR

$archive = "ninja-$NINJA_VERSION.tar.gz"
$sourceDir = "ninja-$NINJA_VERSION"

if (-not (Test-Path $sourceDir)) {
  if (-not (Test-Path $archive)) {
    curl.exe -L -o $archive "https://github.com/ninja-build/ninja/archive/refs/tags/v$NINJA_VERSION.tar.gz"
  }

  $hash = (Get-FileHash $archive -Algorithm SHA256).Hash.ToLowerInvariant()
  if ($hash -ne $NINJA_SOURCE_SHA256) {
    throw "bad Ninja source hash: $hash"
  }

  tar.exe -xzf $archive
}

Push-Location $sourceDir
try {
  $oldCxx = $env:CXX
  $oldPath = $env:PATH
  $shimDir = Join-Path $INSTALL_PREFIX "bootstrap-tools"
  New-Item -ItemType Directory -Force -Path $shimDir | Out-Null
  Copy-Item -Path $clangCl -Destination (Join-Path $shimDir "cl.exe") -Force
  Copy-Item -Path $lldLink -Destination (Join-Path $shimDir "link.exe") -Force
  $env:CXX = "cl"
  $env:PATH = "$shimDir;$oldPath"
  & $python configure.py --bootstrap
  if ($LASTEXITCODE -ne 0) { throw "Ninja bootstrap failed" }
}
finally {
  $env:CXX = $oldCxx
  $env:PATH = $oldPath
  Pop-Location
}

$ninjaName = if ($IsWindows -or $env:OS -eq "Windows_NT") { "ninja.exe" } else { "ninja" }
$builtNinja = Join-Path $SRC_DIR "$sourceDir\$ninjaName"
$ninjaTool = Join-Path $INSTALL_PREFIX "bin\ninja.exe"
Copy-Item -Path $builtNinja -Destination $ninjaTool -Force

if (-not (Test-Path -PathType Leaf $ninjaTool)) {
  throw "Ninja did not install to $ninjaTool"
}

Write-Host "Ninja ready: $ninjaTool"
