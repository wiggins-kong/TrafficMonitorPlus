@echo off
rem ============================================================================
rem  Build lhm_probe - a diagnostic tool for the TrafficMonitor hardware monitor
rem
rem  This tool calls OpenHardwareMonitorApi.dll directly, so hardware monitor
rem  problems can be checked without the GUI. See wiggins-kong/development.md.
rem
rem  Requirements:
rem    1. Build the full (non-Lite) solution first, so that
rem       Bin\x64\Release\OpenHardwareMonitorApi.lib exists:
rem         MSBuild.exe TrafficMonitor.sln /p:Configuration=Release /p:Platform=x64
rem    2. Visual Studio 2022 with the C++ desktop workload (vcvars64.bat).
rem
rem  Copy the produced tm_lhm_probe.exe into the TrafficMonitor program folder
rem  (next to OpenHardwareMonitorApi.dll and LibreHardwareMonitorLib.dll) and run
rem  it as administrator. The result is written to tm_lhm_probe_out.txt.
rem  (Chinese documentation: wiggins-kong/development.md)
rem ============================================================================
setlocal

set "REPO=%~dp0..\..\.."
set "VCVARS="

for /f "usebackq tokens=*" %%i in (`"%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe" -latest -property installationPath`) do set "VS=%%i"
if defined VS if exist "%VS%\VC\Auxiliary\Build\vcvars64.bat" set "VCVARS=%VS%\VC\Auxiliary\Build\vcvars64.bat"

if not defined VCVARS (
    echo [ERROR] vcvars64.bat not found. Install the Visual Studio 2022 C++ desktop workload.
    exit /b 1
)

if not exist "%REPO%\Bin\x64\Release\OpenHardwareMonitorApi.lib" (
    echo [ERROR] %REPO%\Bin\x64\Release\OpenHardwareMonitorApi.lib not found.
    echo         Build the full solution first:
    echo         MSBuild.exe TrafficMonitor.sln /p:Configuration=Release /p:Platform=x64
    exit /b 1
)

pushd "%~dp0"
call "%VCVARS%" >nul

cl /nologo /std:c++17 /utf-8 /EHsc /MD /O2 /I"%REPO%\include" "%~dp0tm_lhm_probe.cpp" /link /LIBPATH:"%REPO%\Bin\x64\Release" OpenHardwareMonitorApi.lib
set "CL_EXIT=%ERRORLEVEL%"

if exist "%~dp0tm_lhm_probe.exe" (
    echo.
    echo [OK] generated %~dp0tm_lhm_probe.exe
    echo      Copy it into the TrafficMonitor program folder and run as administrator.
) else (
    echo [ERROR] build failed ^(exit=%CL_EXIT%^)
)

popd
endlocal
