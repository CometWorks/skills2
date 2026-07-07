# Command Execution Guide

> **CRITICAL: Read this before running any commands in this skill.**

This guide explains how to correctly execute commands when using this skill. It covers both Windows (BusyBox + CMD/PowerShell) and Linux (native shell). Following these rules will prevent command failures and retries.

## ⚡ Quick Start (Read This First!)

**For 99% of use cases, follow these simple steps:**

1. **Check if prepared:** Look for `Prepare.DONE` file in skill folder
2. **If not prepared, run preparation** (with workdir set to where this documentation file is located):
   ```bash
   ./prepare.sh      # Linux
   ./Prepare.bat     # Windows
   ```
3. **Search game code:**
   ```bash
   # Correct syntax: <category> <type> <pattern>
   uv run search_game_code.py class declaration CubeGridComponent
   uv run search_game_code.py method usage GetPosition
   uv run search_game_code.py interface declaration IInSceneListener
   ```
   (Always use workdir parameter set to the skill folder)

**That's it!** If you encounter issues or need more detailed information, see the [Detailed Command Execution Guide](CommandExecutionDetails.md).
