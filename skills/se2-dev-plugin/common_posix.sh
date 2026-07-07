#!/usr/bin/env bash
# common_posix.sh - shared helpers for the POSIX (Linux) preparation
# scripts of the se2-dev-plugin skill. Sourced by prepare.sh / clean.sh.
#
# The Windows preparation lives in Prepare.bat / Clean.bat and uses BusyBox +
# junctions; on Linux we use the native shell + symlinks instead. The
# Python download/index/search scripts are identical on every platform.

log() {
    printf '%s\n' "$*"
}

fail() {
    printf 'ERROR: %s\n' "$*" >&2
    exit 1
}

prepend_user_paths() {
    # uv installs into ~/.local/bin, which is not always on a non-login
    # shell's PATH.
    local extra
    for extra in "$HOME/.local/bin" "$HOME/.dotnet/tools"; do
        case ":$PATH:" in
            *":$extra:"*) ;;
            *) PATH="$extra:$PATH" ;;
        esac
    done
    export PATH
}

find_python() {
    local candidate
    for candidate in python3 python; do
        if command -v "$candidate" >/dev/null 2>&1; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done
    return 1
}

# The skill's own scripts always run under the uv-managed interpreter pinned by
# .python-version (3.13), which `uv sync` downloads even when the system Python
# is older. So we only report the system Python here and never hard-fail on its
# version; uv guarantees a correct interpreter for the virtual environment.
check_python() {
    prepend_user_paths
    PYTHON_BIN="${PYTHON_BIN:-$(find_python 2>/dev/null || true)}"
    if [ -n "${PYTHON_BIN:-}" ]; then
        log "System Python: $("$PYTHON_BIN" --version 2>&1) ($PYTHON_BIN)"
        export PYTHON_BIN
    else
        log "No system Python found; uv will provide Python 3.13 for the virtual environment."
    fi
}

require_cmd() {
    command -v "$1" >/dev/null 2>&1 || fail "Missing $1. Please install it and make sure it is on PATH."
}

ensure_uv() {
    prepend_user_paths
    if command -v uv >/dev/null 2>&1; then
        return 0
    fi

    log "Installing uv"
    if command -v curl >/dev/null 2>&1; then
        curl -LsSf https://astral.sh/uv/install.sh | env UV_NO_MODIFY_PATH=1 sh
    elif command -v wget >/dev/null 2>&1; then
        wget -qO- https://astral.sh/uv/install.sh | env UV_NO_MODIFY_PATH=1 sh
    else
        fail "Missing uv and neither curl nor wget is available to install it."
    fi

    prepend_user_paths
    command -v uv >/dev/null 2>&1 || fail "uv installation finished but uv is still not on PATH."
}

ensure_uv_sync() {
    if [ -d .venv ]; then
        return 0
    fi
    log "Setting up Python .venv (uv sync)"
    uv sync
}

default_data_home() {
    printf '%s\n' "${SE2_DEV_DATA_ROOT:-$HOME/.se2-dev}"
}

# Create a symlink at $1 pointing to directory $2, creating the target first.
# If something already exists at the link path it is left untouched.
ensure_directory_link() {
    local link_path="$1"
    local target_path="$2"
    mkdir -p "$target_path"
    if [ -L "$link_path" ] || [ -e "$link_path" ]; then
        return 0
    fi
    ln -s "$target_path" "$link_path"
}
