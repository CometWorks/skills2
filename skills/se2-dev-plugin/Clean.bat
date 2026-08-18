@echo off
REM Clean.bat - removes everything that Prepare.bat creates inside the skill
REM folder. The Data folder (a junction to %USERPROFILE%\.se2-dev\plugin) is
REM preserved: only the junction itself is removed so the actual contents
REM (Sources, PluginHub-SE2, CodeIndex, plugins.json) survive across runs.

REM Remove the Data junction (NOT its contents - rmdir without /s deletes only
REM the junction reparse point and leaves the target folder intact).
if exist Data rmdir Data

REM Remove transient skill artefacts.
if exist __pycache__  rmdir /s /q __pycache__
if exist .venv        rmdir /s /q .venv
if exist busybox.exe  del busybox.exe
if exist Prepare.log  del Prepare.log
if exist Prepare.DONE del Prepare.DONE

exit /b 0
