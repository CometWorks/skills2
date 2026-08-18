@echo off
setlocal EnableExtensions
cd /d "%~dp0"

REM Graphify query smoke test for the decompiled game-code graph (Windows).
REM
REM Mirrors test_search_game_code.bat (which tests the CSV code index) but
REM exercises the optional Graphify graph instead: it first verifies the graph is
REM healthy (built and clustered), then runs the asserted query / explain / path /
REM affected checks in test_graphify_queries.py, shared with the Linux wrapper.

REM graphify-out sits beside Decompiled, not inside it.
set "GRAPH_OUT=%SE2_DEV_GAME_CODE_GRAPH_OUT%"
if "%GRAPH_OUT%"=="" set "GRAPH_OUT=Data"
if "%GRAPHIFY_MAX_GRAPH_BYTES%"=="" set "GRAPHIFY_MAX_GRAPH_BYTES=2GB"

echo ============================================================
echo GRAPHIFY HEALTH CHECK
echo ============================================================
where graphify >NUL 2>NUL
if %ERRORLEVEL% NEQ 0 (
    echo SKIP: graphify is not on PATH. Build the graph by running prepare:
    echo   .\Prepare.bat   REM auto-builds with the fast Rust backend; set SE2_DEV_GRAPHIFY=1 to force the slow fallback
    exit /b 1
)
call "%~dp0..\se2-dev\GraphifyCheck.bat" "%GRAPH_OUT%"
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo FAIL: Graphify graph is missing or unusable. Rebuild it by re-running prepare:
    echo   rmdir /S /Q "%GRAPH_OUT%\graphify-out"
    echo   .\Prepare.bat   REM auto-builds with the fast Rust backend; set SE2_DEV_GRAPHIFY=1 to force the slow fallback
    exit /b 1
)
echo.

uv run test_graphify_queries.py "%GRAPH_OUT%"
exit /b %ERRORLEVEL%
