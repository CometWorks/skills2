@echo off
setlocal EnableDelayedExpansion

REM 1. Detect game install location (env var override takes precedence)
if defined SE2_GAME_ROOT goto have_game_root

REM Try the game's registry key
for /f "tokens=2*" %%A in ('reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Steam App 1133870" /v "InstallLocation" 2^>nul') do (
    set "SE2_GAME_ROOT=%%B"
)

if defined SE2_GAME_ROOT goto have_game_root
echo ERROR: Could not detect Space Engineers 2 install location.
echo Please set the SE2_GAME_ROOT environment variable to the game's root folder
echo (the folder containing Game2, GameData, etc.)
goto failed

:have_game_root
echo Game Root: %SE2_GAME_ROOT%

REM 2. Verify Python is available
echo Verifying Python
python --version
if %ERRORLEVEL% EQU 0 goto has_python
echo ERROR: Missing Python
echo Please install Python 3.13 or newer.
echo Make sure python.exe is on PATH.
goto failed
:has_python

REM 3. Verify command line git is available
echo Verifying git
git --version
if %ERRORLEVEL% EQU 0 goto has_git
echo ERROR: Missing git
echo Please install git for Windows from https://git-scm.com/download/win
echo Make sure git.exe is on PATH.
goto failed
:has_git

REM 4. Install uv if missing
uv -V 2>NUL
if %ERRORLEVEL% EQU 0 goto skip_uv
echo Installing uv
powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
uv -V
if %ERRORLEVEL% NEQ 0 goto failed
:skip_uv

REM 5. Set up Python venv
if exist .venv goto skip_venv
echo Setting up Python .venv (uv sync)
uv sync
:skip_venv

REM 6. Download busybox if missing
if exist busybox.exe goto skip_busybox
echo Downloading busybox
powershell -Command "$ProgressPreference = 'SilentlyContinue'; Invoke-WebRequest -Uri https://frippery.org/files/busybox/busybox64u.exe -OutFile busybox.exe"
if %ERRORLEVEL% NEQ 0 goto failed
:skip_busybox

REM 7. Install ILSpy if missing
set ILSPY_VERSION=10.0.1.8346
for /f "delims=" %%V in ('ilspycmd -v 2^>NUL') do set ILSPY_INSTALLED=%%V
if defined ILSPY_INSTALLED (
    echo ilspycmd version %ILSPY_INSTALLED% has already been installed
    goto skip_ilspycmd
)
echo Installing ilspycmd %ILSPY_VERSION%
dotnet tool install --global ilspycmd --version %ILSPY_VERSION%
if %ERRORLEVEL% NEQ 0 goto failed
ilspycmd -v
if %ERRORLEVEL% NEQ 0 goto failed
:skip_ilspycmd

REM 8. Set up the Data folder under %USERPROFILE% and create a Data junction.
REM Using %USERPROFILE% rather than %LOCALAPPDATA% keeps the data outside the
REM UWP filesystem virtualization layer (Claude Code is a packaged app whose
REM writes under %LOCALAPPDATA% would be silently redirected into its
REM per-package LocalCache, hiding the data from regular tools).
set "DATA_ROOT=%USERPROFILE%\.se2-dev\game-code"
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

REM 9. Initialize a local Git repository in the Data folder if missing
if exist Data\.git goto skip_git_init
echo Initializing local Git repository in the Data folder
pushd Data
REM Create the repository with 'main' as the default branch. The -c option sets the
REM initial branch on modern git (>=2.28) and suppresses git's "using master" hint.
git -c init.defaultBranch=main init
if %ERRORLEVEL% NEQ 0 (
    popd
    goto failed
)
REM Ensure default branch is main (fallback for git older than 2.28)
git symbolic-ref HEAD refs/heads/main 2>NUL

REM Required: some decompiled paths exceed the legacy MAX_PATH (260 chars).
git config core.longpaths true

REM Write .gitignore (Data\Content is versioned, so no Content/ entry)
> .gitignore (
    echo CodeIndex/
    echo graphify-out/
    echo __pycache__/
    echo *.py[cod]
    echo *.bak
    echo *.log
)

git add .gitignore
if %ERRORLEVEL% NEQ 0 (
    popd
    goto failed
)
git -c user.name="se2-dev-skills" -c user.email="se2-dev-skills@localhost" commit -m "Initial commit: .gitignore"
if %ERRORLEVEL% NEQ 0 (
    popd
    goto failed
)
popd
:skip_git_init

REM 10. Link the game's Game2 folder
if exist Game2 goto skip_game2
echo Linking the game folder as Game2
REM It must be the folder where SpaceEngineers2.dll is located:
mklink /J Game2 "%SE2_GAME_ROOT%\Game2"
if %ERRORLEVEL% EQU 0 goto skip_game2
echo ERROR: Missing Game2 folder.
echo Please verify that Space Engineers 2 is installed.
echo If Space Engineers 2 is installed at a custom location, then set the SE2_GAME_ROOT
echo environment variable to the game's root folder and try again.
goto failed
:skip_game2

REM 11. Bring the Data folder up to the current layout, BEFORE the version check
REM below. An existing install carries a Data\Content that used to be ignored; the
REM migration commits it under the recorded game version so the next version's
REM content shows up as a reviewable diff rather than a wholesale addition.
REM Decompiled holds only decompiled C# code; graphify-out sits beside it. Earlier
REM versions of this skill kept the graph inside Decompiled, where the version
REM commit would have swept its ~1.8 GB into the repository.
if not exist Data\Decompiled\graphify-out goto skip_move_graph
if exist Data\graphify-out (
    rmdir /s /q Data\Decompiled\graphify-out
) else (
    echo Moving Data\Decompiled\graphify-out up to Data\graphify-out
    move /Y Data\Decompiled\graphify-out Data\graphify-out >NUL
)
:skip_move_graph

set MIGRATED=0
REM Content is versioned, so it must not be ignored (older installs ignored it).
findstr /X /L /C:"Content/" Data\.gitignore >NUL 2>NUL
if %ERRORLEVEL% EQU 0 (
    findstr /X /L /V /C:"Content/" Data\.gitignore >Data\.gitignore.tmp
    move /Y Data\.gitignore.tmp Data\.gitignore >NUL
    set MIGRATED=1
)

REM The Graphify graph is a large regenerable artifact, so it must be ignored.
REM This has to be in place before any commit, all of which stage everything.
REM Redirection precedes echo to avoid a trailing space in the line.
findstr /X /L /C:"graphify-out/" Data\.gitignore >NUL 2>NUL
if %ERRORLEVEL% NEQ 0 (
    >>Data\.gitignore echo graphify-out/
    set MIGRATED=1
)

if "!MIGRATED!"=="0" goto skip_migration_commit
echo Migrating the Data layout ^(versioning Content, ignoring graphify-out^)
pushd Data
git add -A
git -c user.name="se2-dev-skills" -c user.email="se2-dev-skills@localhost" commit -m "Data layout migration: version Content, ignore graphify-out"
if %ERRORLEVEL% NEQ 0 (
    echo (No migration commit made: nothing to commit)
)
popd
:skip_migration_commit

REM 12. Determine current game version and decide whether to wipe stale outputs
set NEED_COMMIT=0
echo Checking current game version
uv run python -u check_version.py Game2 Data > version_check.txt
if %ERRORLEVEL% EQU 0 (
    echo Game version unchanged - keeping existing decompilation
    goto skip_wipe
)
if %ERRORLEVEL% EQU 2 (
    echo Game version differs or no previous version recorded - wiping stale outputs
    REM Data files are incomplete until preparation finishes for the new game version
    if exist Prepare.DONE del Prepare.DONE
    if exist Data\Decompiled rmdir /s /q Data\Decompiled
    if exist Data\CodeIndex  rmdir /s /q Data\CodeIndex
    if exist Data\Content    rmdir /s /q Data\Content
    if exist Data\graphify-out rmdir /s /q Data\graphify-out
    mkdir Data\Decompiled 2>NUL
    goto skip_wipe
)
echo ERROR: Failed to determine current game version
type version_check.txt
goto failed
:skip_wipe

REM 13. Decompile the game assemblies
if exist Data\Decompiled\VRage.Water goto skip_decompile
.\busybox sh decompile.sh
if %ERRORLEVEL% NEQ 0 goto failed
set NEED_COMMIT=1
:skip_decompile

REM 14. Copy indexable content. Only the indexable text files are copied (no
REM binaries), so the definition files can be versioned and their changes
REM reviewed across game versions.
if exist Data\Content goto skip_content
echo Copying indexable content
uv run python -u copy_content.py "%SE2_GAME_ROOT%\GameData\Vanilla\Content"
if %ERRORLEVEL% NEQ 0 goto failed
set NEED_COMMIT=1
:skip_content

REM 15. Record the current game version and commit decompiled code and content
if "!NEED_COMMIT!"=="0" goto skip_commit
echo Recording game version and committing decompiled sources and content
uv run python -u check_version.py --write Game2 Data
if %ERRORLEVEL% NEQ 0 goto failed

for /f "usebackq delims=" %%V in (`uv run python -u check_version.py --print Game2`) do set "GAME_VERSION_LABEL=%%V"
if not defined GAME_VERSION_LABEL (
    echo ERROR: Could not determine game version label
    goto failed
)
echo Game version: !GAME_VERSION_LABEL!

pushd Data
git add -A
git -c user.name="se2-dev-skills" -c user.email="se2-dev-skills@localhost" commit -m "!GAME_VERSION_LABEL!"
if %ERRORLEVEL% NEQ 0 (
    echo (No commit made: working tree clean or nothing to commit)
)
popd
:skip_commit

REM 16. Remove the Game2 junction
rmdir /s /q Game2

REM 17. Build the code index
if exist Data\CodeIndex\class_declarations.csv goto skip_code_index
echo Indexing decompiled code
mkdir Data\CodeIndex 2>NUL
uv run python -OO -u index_code.py Data\Decompiled Data\CodeIndex
if %ERRORLEVEL% NEQ 0 goto failed
:skip_code_index

REM 18. Build the content index
if exist Data\CodeIndex\content_index.csv goto skip_content_index
echo Indexing content files
uv run python -u index_content.py Data\Content Data\Decompiled Data\CodeIndex
if %ERRORLEVEL% NEQ 0 goto failed
:skip_content_index

REM 19. Optionally build the Graphify graph for the decompiled game code. The Graphify
REM     integration is shared by all se2-dev-* skills and lives in the se2-dev skill.
REM     Auto-builds with the fast Rust backend; otherwise stays opt-in (SE2_DEV_GRAPHIFY=1).
REM     This is supplemental - a failure here never fails the core preparation.
REM     Only the decompiled C# code is graphed; the graph itself is written beside it
REM     (Data\graphify-out) so it never pollutes the graphed tree or the repository.
if defined SE2_DEV_GAME_CODE_GRAPH_ROOT (
    set "GAME_CODE_GRAPH_ROOT=%SE2_DEV_GAME_CODE_GRAPH_ROOT%"
) else (
    set "GAME_CODE_GRAPH_ROOT=%CD%\Data\Decompiled"
)
if defined SE2_DEV_GAME_CODE_GRAPH_OUT (
    set "GAME_CODE_GRAPH_OUT=%SE2_DEV_GAME_CODE_GRAPH_OUT%"
) else (
    set "GAME_CODE_GRAPH_OUT=%CD%\Data"
)
if exist "%~dp0..\se2-dev\GraphifyPrepare.bat" (
    call "%~dp0..\se2-dev\GraphifyPrepare.bat" "se2-dev-game-code" "%GAME_CODE_GRAPH_ROOT%" "%GAME_CODE_GRAPH_OUT%"
) else (
    echo Graphify: skipping se2-dev-game-code ^(the se2-dev skill is not installed next to this one^)
)

echo DONE
del version_check.txt 2>NUL
del "\\?\%cd%\nul" 2>error.txt
del error.txt
echo DONE >Prepare.DONE
exit /b 0

:failed
del version_check.txt 2>NUL
del "\\?\%cd%\nul" 2>error.txt
del error.txt
echo FAILED
exit /b 1
