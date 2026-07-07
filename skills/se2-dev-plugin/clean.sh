#!/usr/bin/env bash
# clean.sh - POSIX counterpart of Clean.bat. Removes everything prepare.sh
# creates inside the skill folder. The Data folder (a symlink to
# ~/.se2-dev/plugin) is preserved: only the symlink itself is removed so the
# actual contents (Sources, PluginHub-SE2, CodeIndex, plugins.json) survive
# across runs.
set -u
cd "$(dirname "$(readlink -f "$0")")"

# Remove the Data symlink (NOT its contents - plain rm on a symlink removes
# only the link and leaves the target folder intact). If Data happens to be a
# real directory, rm without -r refuses, which preserves user data.
[ -L Data ] && rm Data

# Remove transient skill artefacts.
rm -rf __pycache__
rm -rf .venv
rm -f Prepare.log
rm -f Prepare.DONE

exit 0
