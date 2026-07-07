@echo off
setlocal EnableDelayedExpansion

:: 1. Verify Python is available
echo Verifying Python
python --version
if %ERRORLEVEL% EQU 0 goto has_python
echo ERROR: Missing Python
echo Please install Python 3.13 or newer.
echo Make sure python.exe is on PATH.
goto failed
:has_python

:: 2. Verify command line git is available
echo Verifying git
git --version
if %ERRORLEVEL% EQU 0 goto has_git
echo ERROR: Missing git
echo Please install git for Windows from https://git-scm.com/download/win
echo Make sure git.exe is on PATH.
goto failed
:has_git

:: 3. Install uv if missing
uv -V 2>NUL
if %ERRORLEVEL% EQU 0 goto skip_uv
echo Installing uv
powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
uv -V
if %ERRORLEVEL% NEQ 0 goto failed
:skip_uv

:: 4. Set up Python venv
if exist .venv goto skip_venv
echo Setting up Python .venv (uv sync)
uv sync
:skip_venv

:: 5. Download busybox if missing
if exist busybox.exe goto skip_busybox
echo Downloading busybox
powershell -Command "$ProgressPreference = 'SilentlyContinue'; Invoke-WebRequest -Uri https://frippery.org/files/busybox/busybox64u.exe -OutFile busybox.exe"
if %ERRORLEVEL% NEQ 0 goto failed
:skip_busybox

:: 6. Set up the Data folder under %USERPROFILE% and create a Data junction.
:: Using %USERPROFILE% rather than %LOCALAPPDATA% keeps the data outside the
:: UWP filesystem virtualization layer (Claude Code is a packaged app whose
:: writes under %LOCALAPPDATA% would be silently redirected into its
:: per-package LocalCache, hiding the data from regular tools).
set "DATA_ROOT=%USERPROFILE%\.se2-dev\plugin"
echo Data Root: %DATA_ROOT%
if not exist "%DATA_ROOT%" (
    echo Creating Data Root folder
    mkdir "%DATA_ROOT%"
    if !ERRORLEVEL! NEQ 0 goto failed
)

if exist Data goto skip_data_junction
echo Linking the Data folder
mklink /J Data "%DATA_ROOT%"
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Could not create Data junction.
    goto failed
)
:skip_data_junction

:: 7. Pre-create the Sources subfolder where per-plugin git clones will live.
::    Each plugin is cloned as Data\Sources\<PluginName>\... so it can be
::    pulled later to fetch upstream updates.
if not exist Data\Sources (
    echo Creating Sources folder
    mkdir Data\Sources
    if !ERRORLEVEL! NEQ 0 goto failed
)

:: 8. Download / refresh the PluginHub-SE2 registry clone
echo Downloading PluginHub-SE2 registry
uv run download_pluginhub.py
if %ERRORLEVEL% NEQ 0 goto failed

:: 9. Index any plugin sources already downloaded under Data\Sources
echo Indexing plugin code (skipped if no sources downloaded yet)
uv run index_plugin_code.py
if %ERRORLEVEL% NEQ 0 goto failed

:: 10. Optionally build the Graphify graph for the downloaded plugin sources. Auto-builds
::     with the fast Rust backend; otherwise stays opt-in (SE2_DEV_GRAPHIFY=1). This is
::     supplemental - a failure here never fails the core preparation.
if defined SE2_DEV_PLUGIN_PROJECT_ROOT (
    set "PLUGIN_GRAPH_ROOT=%SE2_DEV_PLUGIN_PROJECT_ROOT%"
) else (
    set "PLUGIN_GRAPH_ROOT=%CD%\Data\Sources"
)
call "%~dp0GraphifyPrepare.bat" "se2-dev-plugin" "%PLUGIN_GRAPH_ROOT%"

echo DONE
echo DONE >Prepare.DONE
exit /b 0

:failed
echo FAILED
exit /b 1
