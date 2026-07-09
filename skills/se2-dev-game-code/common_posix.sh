#!/usr/bin/env bash
# common_posix.sh - shared helpers for the POSIX (Linux) preparation
# scripts of the se2-dev-game-code skill. Sourced by prepare.sh / clean.sh.
#
# The Windows preparation lives in Prepare.bat / Clean.bat and uses BusyBox +
# junctions; on Linux we use the native shell + symlinks instead. The
# Python indexing/search scripts are identical on every platform.

# Steam application id of Space Engineers 2.
SE2_APP_ID=1133870
ILSPY_VERSION="${ILSPY_VERSION:-10.0.1.8346}"
# Where per-user tools (ilspycmd) are installed when not already on PATH.
SE2_TOOLS_ROOT="${SE2_TOOLS_ROOT:-$HOME/.se2-dev/tools}"

log() {
    printf '%s\n' "$*"
}

fail() {
    printf 'ERROR: %s\n' "$*" >&2
    exit 1
}

prepend_user_paths() {
    # dotnet global/tool-path tools and uv install into these locations, which
    # are not always on a non-login shell's PATH.
    local extra
    for extra in "$HOME/.local/bin" "$HOME/.dotnet/tools" "$SE2_TOOLS_ROOT/ilspycmd"; do
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

# Create a transient symlink at $1 pointing to $2. Refuses to clobber a real
# (non-symlink) entry so we never touch the game install by accident.
ensure_temp_link() {
    local link_path="$1"
    local target_path="$2"
    if [ -e "$link_path" ] && [ ! -L "$link_path" ]; then
        fail "$link_path exists and is not a symlink. Remove it or point it at $target_path."
    fi
    if [ -L "$link_path" ]; then
        rm -f "$link_path"
    fi
    ln -s "$target_path" "$link_path"
}

# Print every Steam library "steamapps" directory known to this machine:
# the well-known defaults plus any extra libraries listed in libraryfolders.vdf.
steamapps_candidates() {
    if [ -n "${STEAMAPPS_DIR:-}" ]; then
        printf '%s\n' "$STEAMAPPS_DIR"
    fi

    local defaults=(
        "$HOME/.local/share/Steam/steamapps"
        "$HOME/.steam/steam/steamapps"
        "$HOME/.steam/root/steamapps"
        "$HOME/.steam/debian-installation/steamapps"
        "$HOME/.var/app/com.valvesoftware.Steam/.local/share/Steam/steamapps"
    )
    printf '%s\n' "${defaults[@]}"

    # Extra library folders configured through the Steam client. Their "path"
    # entries point at the library root; steamapps sits directly beneath.
    local vdf root
    for vdf in "${defaults[@]}"; do
        vdf="$vdf/libraryfolders.vdf"
        [ -f "$vdf" ] || continue
        while IFS= read -r root; do
            printf '%s\n' "$root/steamapps"
        done < <(grep -oE '"path"[[:space:]]+"[^"]+"' "$vdf" | sed -E 's/.*"path"[[:space:]]+"([^"]+)".*/\1/')
    done
}

# Locate the Space Engineers 2 install (the folder containing Game2/).
# Honours the SE2_GAME_ROOT override first.
detect_game_root() {
    if [ -n "${SE2_GAME_ROOT:-}" ]; then
        [ -d "$SE2_GAME_ROOT" ] || fail "SE2_GAME_ROOT does not exist: $SE2_GAME_ROOT"
        printf '%s\n' "$SE2_GAME_ROOT"
        return 0
    fi

    local steamapps candidate
    while IFS= read -r steamapps; do
        [ -d "$steamapps" ] || continue
        candidate="$steamapps/common/SpaceEngineers2"
        if [ -d "$candidate/Game2" ]; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done < <(steamapps_candidates)

    return 1
}

# Initialise the local Git repository that versions the decompiled sources.
ensure_git_repo() {
    local repo_dir="$1"
    if [ -d "$repo_dir/.git" ]; then
        return 0
    fi

    # Create the repository with 'main' as the default branch. The -c option sets
    # the initial branch on modern git (>=2.28) and suppresses git's "using
    # master" hint; the symbolic-ref fallback covers older git versions.
    git -C "$repo_dir" -c init.defaultBranch=main init >/dev/null
    git -C "$repo_dir" symbolic-ref HEAD refs/heads/main 2>/dev/null || true
    cat >"$repo_dir/.gitignore" <<'EOF'
CodeIndex/
Content/
__pycache__/
*.py[cod]
*.bak
*.log
EOF
    git -C "$repo_dir" add .gitignore
    git -C "$repo_dir" \
        -c user.name="se2-dev-skills" \
        -c user.email="se2-dev-skills@localhost" \
        commit -m "Initial commit: .gitignore" >/dev/null || true
}

# Ensure ilspycmd is available; install it into a per-user tool-path if needed.
# Exports ILSPYCMD with the absolute path to the executable.
ensure_ilspycmd() {
    prepend_user_paths

    if [ -n "${ILSPYCMD:-}" ] && [ -x "$ILSPYCMD" ]; then
        export ILSPYCMD
        return 0
    fi

    if command -v ilspycmd >/dev/null 2>&1; then
        ILSPYCMD="$(command -v ilspycmd)"
        export ILSPYCMD
        return 0
    fi

    require_cmd dotnet
    local tool_dir="$SE2_TOOLS_ROOT/ilspycmd"
    local tool_path="$tool_dir/ilspycmd"

    if [ ! -x "$tool_path" ]; then
        mkdir -p "$tool_dir"
        log "Installing ilspycmd $ILSPY_VERSION"
        dotnet tool install --tool-path "$tool_dir" ilspycmd --version "$ILSPY_VERSION" >/dev/null
    fi

    [ -x "$tool_path" ] || fail "ilspycmd installation failed."
    ILSPYCMD="$tool_path"
    export ILSPYCMD
}
