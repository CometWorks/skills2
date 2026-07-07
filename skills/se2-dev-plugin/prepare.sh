#!/usr/bin/env bash
# prepare.sh - one-time preparation of the se2-dev-plugin skill on Linux.
# This is the POSIX counterpart of Prepare.bat (Windows).
#
# It sets up the Python environment, links the persistent Data folder, clones
# the PluginHub-SE2 registry and indexes any already-downloaded plugin sources.
# All heavy lifting is done by the same cross-platform Python scripts used on
# Windows.

set -euo pipefail

SCRIPT_DIR="$(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./common_posix.sh
source "$SCRIPT_DIR/common_posix.sh"

cd "$SCRIPT_DIR"

# 1. Verify prerequisites and set up the toolchain.
log "Verifying Python"
check_python
log "Verifying git"
require_cmd git
ensure_uv
ensure_uv_sync

# 2. Set up the persistent Data folder (symlink -> ~/.se2-dev/plugin) and
#    pre-create the Sources subfolder where per-plugin git clones will live.
DATA_ROOT="$(default_data_home)/plugin"
log "Data Root: $DATA_ROOT"
ensure_directory_link "Data" "$DATA_ROOT"
mkdir -p Data/Sources

# 3. Download / refresh the PluginHub-SE2 registry clone.
log "Downloading PluginHub-SE2 registry"
uv run download_pluginhub.py

# 4. Index any plugin sources already downloaded under Data/Sources.
log "Indexing plugin code (skipped if no sources downloaded yet)"
uv run index_plugin_code.py

: >Prepare.DONE
log "DONE"
