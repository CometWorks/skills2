# Prepare Action

> **Part of the se2-dev-plugin skill.** Invoked to run the one-time preparation.

**⚠️ IMPORTANT: Read [CommandExecution.md](../CommandExecution.md) for complete guidance on running commands correctly.**

Run `Prepare.bat` (Windows) or `./prepare.sh` (Linux) to set up the skill environment. This is required before using the skill.

## Quick Check Status

**IMPORTANT**: Use bash syntax, NOT Windows CMD syntax. Commands run through a UNIX shell (BusyBox on Windows, the native shell on Linux).

```bash
# ✅ CORRECT - Use bash syntax
test -f "Prepare.DONE" && echo "READY" || echo "NOT_READY"
```

**Alternative**: Use the Glob tool to check for file existence instead of bash commands.

```bash
# ❌ WRONG - Don't use Windows CMD syntax (will NOT work)
# if exist Prepare.DONE (echo READY) else (echo NOT_READY)
```

## Running Preparation

If `Prepare.DONE` is missing:

1. Review the requirements and instructions in [Prepare.md](../Prepare.md).
2. Execute preparation using the skill folder as working directory:

**Linux:**
```bash
./prepare.sh (with workdir set to skill folder)
```

**Windows — recommended approach (using workdir parameter):**
```bash
./Prepare.bat (with workdir set to skill folder)
```

**Windows — alternative approaches:**

Using PowerShell:
```powershell
cd C:\path\to\skill\folder
.\Prepare.bat
```

Using CMD (change directory first):
```cmd
cd /d C:\path\to\skill\folder
Prepare.bat
```

**⚠️ CRITICAL:** See [CommandExecution.md](../CommandExecution.md) for details on:
- Why `&&` doesn't work in CMD
- How to use the workdir parameter correctly
- Common mistakes and how to avoid them

## Critical Rules

- **DO NOT** create the `Prepare.DONE` file yourself.
- It is automatically created by the preparation script only upon a successful run.
- Creating it manually is "faking" success and will lead to errors.

## What Preparation Does

The preparation script:
- Verifies `git` is on `PATH` and sets up the Python virtual environment (uv
  provides the pinned Python 3.13 for the venv even if the system Python is older)
- Creates the per-user data folder (`%USERPROFILE%\.se2-dev\plugin\` on Windows,
  `~/.se2-dev/plugin/` on Linux) and links it into the skill folder as a
  `Data/` junction (Windows) or symlink (Linux), so all downloaded data
  persists across re-installs and `Clean.bat`/`clean.sh` runs
- Pre-creates the `Data/Sources/` folder where each plugin will later be
  cloned into its own `Data/Sources/<PluginName>/` subdirectory
- On Windows, downloads and installs required tools (`busybox.exe`)
- `git clone`s the PluginHub-SE2 registry into `Data/PluginHub-SE2`
  (refreshed with `git fetch` / `git reset` on subsequent runs, so a
  manual `git pull` works too)
- Records the cloned commit in `Data/plugins.json`
- Verifies the environment is ready for use

Individual plugin sources are downloaded on demand by
`download_plugin_source.py`, which `git clone`s each plugin from GitHub into
`Data/Sources/<PluginName>/` (or the override set via
`SE_PLUGIN_DOWNLOAD_FOLDER` / `plugin_download_folder:`). Re-running it pulls
upstream updates in place.
