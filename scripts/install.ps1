# install.ps1 -- Windows installer for With.

$ErrorActionPreference = "Stop"

$repo = if ($env:WITH_REPO) { $env:WITH_REPO } else { "withlang-dev/with" }
$installDir = if ($env:WITH_INSTALL_DIR) { $env:WITH_INSTALL_DIR } else {
    Join-Path $env:USERPROFILE ".local\bin"
}
$installName = if ($env:WITH_INSTALL_NAME) { $env:WITH_INSTALL_NAME } else { "with.exe" }
$version = if ($env:WITH_VERSION) { $env:WITH_VERSION } else { "latest" }

$arch = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture
if ($arch -ne [System.Runtime.InteropServices.Architecture]::X64) {
    throw "unsupported Windows architecture: $arch"
}

$asset = "with-windows-x86_64.exe"
if (-not $installName.EndsWith(".exe", [System.StringComparison]::OrdinalIgnoreCase)) {
    $installName = "$installName.exe"
}

if ($version -eq "latest") {
    $url = "https://github.com/$repo/releases/latest/download/$asset"
}
else {
    $url = "https://github.com/$repo/releases/download/$version/$asset"
}

$tmpDir = Join-Path ([System.IO.Path]::GetTempPath()) ("with-install." + [System.Guid]::NewGuid().ToString("N"))
$tmpBin = Join-Path $tmpDir $installName
$target = Join-Path $installDir $installName

New-Item -ItemType Directory -Force -Path $tmpDir | Out-Null
New-Item -ItemType Directory -Force -Path $installDir | Out-Null

try {
    Write-Output "downloading $url"
    Invoke-WebRequest -Uri $url -OutFile $tmpBin
    Move-Item -Path $tmpBin -Destination $target -Force

    Write-Output "installed $target"
    & $target version

    $pathParts = $env:PATH -split ';'
    $onPath = $false
    foreach ($part in $pathParts) {
        if ($part -and ([System.IO.Path]::GetFullPath($part.Trim('"')).TrimEnd('\') -eq [System.IO.Path]::GetFullPath($installDir).TrimEnd('\'))) {
            $onPath = $true
            break
        }
    }
    if (-not $onPath) {
        Write-Warning "add $installDir to PATH to run 'with' from any shell"
    }
}
finally {
    Remove-Item -Recurse -Force -Path $tmpDir -ErrorAction SilentlyContinue
}
