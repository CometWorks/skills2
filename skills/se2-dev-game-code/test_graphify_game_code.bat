@echo off
setlocal EnableExtensions
cd /d "%~dp0"

REM Graphify query smoke test for the decompiled game-code graph.
REM Mirrors test_search_game_code.bat but exercises the optional Graphify graph.

set "GRAPH_ROOT=%SE2_DEV_GAME_CODE_GRAPH_ROOT%"
if "%GRAPH_ROOT%"=="" set "GRAPH_ROOT=Data\Decompiled"
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
call "%~dp0GraphifyCheck.bat" "%GRAPH_ROOT%"
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo FAIL: Graphify graph is missing or unusable. Rebuild it by re-running prepare:
    echo   rmdir /S /Q "%GRAPH_ROOT%\graphify-out"
    echo   .\Prepare.bat   REM auto-builds with the fast Rust backend; set SE2_DEV_GRAPHIFY=1 to force the slow fallback
    exit /b 1
)
echo.

pushd "%GRAPH_ROOT%"

echo ============================================================
echo QUERY - BFS traversal for a question
echo ============================================================
echo --- How is an entity created and updated? ---
graphify query "How is an entity created and updated?" --budget 400
echo.
echo --- How does the game application start up? ---
graphify query "How does the game application start up?" --budget 400
echo.

echo ============================================================
echo QUERY - narrowed by edge context
echo ============================================================
echo --- Call edges out of Entity ---
graphify query "Entity" --context call --budget 300
echo.

echo ============================================================
echo EXPLAIN - a node and its neighbours
echo ============================================================
echo --- Explain Entity ---
graphify explain "Entity"
echo.
echo --- Explain Vector3D ---
graphify explain "Vector3D"
echo.

echo ============================================================
echo PATH - shortest path between two nodes
echo ============================================================
echo --- Entity -^> IEntityContainer ---
graphify path "Entity" "IEntityContainer"
echo.

echo ============================================================
echo AFFECTED - reverse traversal for impact
echo ============================================================
echo --- What is affected by GameApp? ---
graphify affected "GameApp" --depth 1
echo.

popd

echo ============================================================
echo ALL TESTS COMPLETED
echo ============================================================
