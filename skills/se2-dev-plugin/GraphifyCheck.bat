@echo off
setlocal EnableExtensions EnableDelayedExpansion

REM Standalone Graphify health check (Windows).
REM
REM Usage: GraphifyCheck.bat [graph-root]
REM   graph-root  Directory containing graphify-out\ (default: Data\Sources)
REM
REM Exit codes: 0 ok, 2 missing, 3 incomplete.
REM A non-zero result means the graph is unusable and must be rebuilt from
REM scratch. The plugin sources corpus is small, so rebuilding is quick.

set "ROOT=%~1"
if "%ROOT%"=="" set "ROOT=Data\Sources"

if not exist "%ROOT%\" (
    echo FAIL: graph root does not exist: %ROOT%
    echo Run prepare first ^(it builds automatically when the fast Rust backend is available; otherwise set SE2_DEV_GRAPHIFY=1^).
    exit /b 2
)

for %%I in ("%ROOT%") do set "ABS_ROOT=%%~fI"
set "OUT=%ABS_ROOT%\graphify-out"

if not exist "%OUT%\graph.json" (
    echo MISSING: no Graphify graph at %OUT%
    echo Build it by running prepare ^(auto-builds with the fast Rust backend; otherwise set SE2_DEV_GRAPHIFY=1^).
    exit /b 2
)

if not exist "%OUT%\.graphify_analysis.json" (
    echo INCOMPLETE: %OUT% has a graph.json but clustering data is missing.
    echo The graph is unusable and must be rebuilt from scratch.
    echo Clean and rebuild by re-running prepare:
    echo   rmdir /S /Q "%OUT%"
    echo   .\Prepare.bat   REM add set SE2_DEV_GRAPHIFY=1 to force a build on the slow fallback
    exit /b 3
)

echo OK: graph.json and clustering data present at %OUT%
exit /b 0
