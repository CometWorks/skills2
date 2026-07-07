#!/usr/bin/env bash
# prepare.sh - one-time preparation of the se2-dev-game-code skill on
# Linux. This is the POSIX counterpart of Prepare.bat (Windows).
#
# It detects the Space Engineers 2 install, decompiles the game assemblies,
# copies indexable content and builds the code/content indexes. All heavy
# lifting is done by the same cross-platform Python scripts used on Windows.

set -euo pipefail

SCRIPT_DIR="$(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./common_posix.sh
source "$SCRIPT_DIR/common_posix.sh"

cd "$SCRIPT_DIR"

cleanup() {
    rm -f version_check.txt
    # Never leave the transient Game2 symlink behind on failure. Use an `if`
    # (not `&&`) so this stays the last command with status 0 — otherwise a
    # false test here would become the script's exit status under the EXIT trap.
    if [ -L Game2 ]; then
        rm -f Game2
    fi
    return 0
}
trap cleanup EXIT

# 1. Detect the game install (SE2_GAME_ROOT overrides auto-detection).
GAME_ROOT="$(detect_game_root 2>/dev/null || true)"
if [ -z "$GAME_ROOT" ]; then
    fail "Could not detect the Space Engineers 2 install location.
Set the SE2_GAME_ROOT environment variable to the game's root folder
(the folder containing Game2, GameData, etc.)."
fi
[ -d "$GAME_ROOT/Game2" ] || fail "Missing Game2 folder under $GAME_ROOT."
log "Game Root: $GAME_ROOT"

# 2. Verify prerequisites and set up the toolchain.
log "Verifying Python"
check_python
log "Verifying git"
require_cmd git
ensure_uv
ensure_uv_sync
ensure_ilspycmd

# 3. Set up the persistent Data folder (symlink -> ~/.se2-dev/game-code) and
#    the local Git repository that versions the decompiled sources.
DATA_ROOT="$(default_data_home)/game-code"
log "Data Root: $DATA_ROOT"
ensure_directory_link "Data" "$DATA_ROOT"
ensure_git_repo "Data"

# 4. Link the game's Game2 folder so the decompiler can read its assemblies.
ensure_temp_link "Game2" "$GAME_ROOT/Game2"

# 5. Decide whether the recorded decompilation is still current.
log "Checking current game version"
set +e
uv run python -u check_version.py Game2 Data >version_check.txt
RC=$?
set -e
case "$RC" in
    0)
        log "Game version unchanged - keeping existing decompilation"
        ;;
    2)
        log "Game version differs or no previous version recorded - wiping stale outputs"
        rm -rf Data/Decompiled Data/CodeIndex Data/Content
        mkdir -p Data/Decompiled
        ;;
    *)
        cat version_check.txt >&2
        fail "Failed to determine the current game version."
        ;;
esac

# 6. Decompile the game assemblies (skipped if already done for this version).
if [ ! -d Data/Decompiled/VRage.Water ]; then
    log "Decompiling the game assemblies"
    ILSPYCMD="$ILSPYCMD" ./decompile.sh

    log "Recording game version and committing decompiled sources"
    uv run python -u check_version.py --write Game2 Data
    GAME_VERSION_LABEL="$(uv run python -u check_version.py --print Game2)"
    [ -n "$GAME_VERSION_LABEL" ] || fail "Could not determine the game version label."
    log "Game version: $GAME_VERSION_LABEL"

    git -C Data add -A
    git -C Data \
        -c user.name="se2-dev-skills" \
        -c user.email="se2-dev-skills@localhost" \
        commit -m "$GAME_VERSION_LABEL" >/dev/null \
        || log "(No commit made: working tree clean or nothing to commit)"
fi

# 7. Remove the transient Game2 symlink (the game install is untouched).
[ -L Game2 ] && rm -f Game2

# 8. Copy indexable game content.
if [ ! -d Data/Content ]; then
    log "Copying indexable content"
    uv run python -u copy_content.py "$GAME_ROOT/GameData/Vanilla/Content"
fi

# 9. Build the code index.
if [ ! -f Data/CodeIndex/class_declarations.csv ]; then
    log "Indexing decompiled code"
    mkdir -p Data/CodeIndex
    uv run python -OO -u index_code.py Data/Decompiled Data/CodeIndex
fi

# 10. Build the content index.
if [ ! -f Data/CodeIndex/content_index.csv ]; then
    log "Indexing content files"
    uv run python -u index_content.py Data/Content Data/Decompiled Data/CodeIndex
fi

: >Prepare.DONE
log "DONE"
