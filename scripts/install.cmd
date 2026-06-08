@echo off
setlocal

set "SCRIPT=%~dp0install.ps1"
if exist "%SCRIPT%" (
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%"
  exit /b %ERRORLEVEL%
)

set "REPO=%WITH_REPO%"
if "%REPO%"=="" set "REPO=withlang-dev/with"

set "VERSION=%WITH_VERSION%"
if "%VERSION%"=="" set "VERSION=latest"

set "TMP_SCRIPT=%TEMP%\with-install-%RANDOM%-%RANDOM%.ps1"
if "%VERSION%"=="latest" (
  set "URL=https://github.com/%REPO%/releases/latest/download/install.ps1"
) else (
  set "URL=https://github.com/%REPO%/releases/download/%VERSION%/install.ps1"
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Invoke-WebRequest -Uri '%URL%' -OutFile '%TMP_SCRIPT%'"
if errorlevel 1 exit /b %ERRORLEVEL%

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%TMP_SCRIPT%"
set "STATUS=%ERRORLEVEL%"
del "%TMP_SCRIPT%" >nul 2>nul
exit /b %STATUS%
