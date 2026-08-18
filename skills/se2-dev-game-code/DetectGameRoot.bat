@echo off
REM DetectGameRoot.bat - detect the Space Engineers 2 install root (the folder
REM holding Game2, GameData, etc.) and leave it in the caller's SE2_GAME_ROOT
REM variable. Invoke it with `call`; it deliberately does NOT use setlocal,
REM otherwise the variable would not survive the return.
REM
REM Windows counterpart of detect_game_root() in common_posix.sh. An already
REM defined SE2_GAME_ROOT always wins, so a custom install location can be
REM pointed at manually. Exits with 1 when the install cannot be located.

if defined SE2_GAME_ROOT exit /b 0

REM The game's Steam uninstall key records the install location.
for /f "tokens=2*" %%A in ('reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Steam App 1133870" /v "InstallLocation" 2^>nul') do (
    set "SE2_GAME_ROOT=%%B"
)

if defined SE2_GAME_ROOT exit /b 0

echo ERROR: Could not detect Space Engineers 2 install location.
echo Please set the SE2_GAME_ROOT environment variable to the game's root folder
echo (the folder containing Game2, GameData, etc.)
exit /b 1
