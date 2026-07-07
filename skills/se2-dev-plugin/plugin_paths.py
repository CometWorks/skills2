"""
Shared path resolution for plugin source downloads and the PluginHub-SE2 registry.

`Data/` inside the skill folder is a junction (Windows) or symlink (Linux)
to the per-user data folder created by the preparation script
(`%USERPROFILE%\\.se2-dev\\plugin\\` on Windows, `~/.se2-dev/plugin/` on
Linux). Layout under it:

    Data/                            # junction -> ~/.se2-dev/plugin/
        PluginHub-SE2/               # local clone of the plugin registry
        Sources/                     # downloaded plugin source repositories
            <RepoName>/              # per-plugin git clone
        CodeIndex/                   # CSV indexes built from Sources/
        plugins.json                 # registry of versions (see plugin_registry.py)

`Sources/` can be relocated by configuration; `PluginHub-SE2/` and
`plugins.json` always live next to each other in the base directory.
"""

import os
import re
import sys
from pathlib import Path

SCRIPT_DIR = Path(__file__).parent.resolve()

DATA_DIR_NAME = "Data"
PLUGIN_SOURCES_SUBDIR = "Sources"
PLUGINHUB_SUBDIR = "PluginHub-SE2"
CODE_INDEX_SUBDIR = "CodeIndex"


def _read_config_from_file(file_path: Path) -> str:
    """Read plugin_download_folder or PLUGIN_DOWNLOAD_FOLDER from a config file."""
    if not file_path.exists():
        return ""
    try:
        with open(file_path, "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                # Match: plugin_download_folder: /path/to/folder
                m = re.match(r"plugin_download_folder:\s*(.+)", line, re.IGNORECASE)
                if m:
                    return m.group(1).strip()
                # Match: PLUGIN_DOWNLOAD_FOLDER=/path/to/folder
                m = re.match(r"PLUGIN_DOWNLOAD_FOLDER=(.+)", line)
                if m:
                    return m.group(1).strip()
    except Exception:
        pass
    return ""


def resolve_base_dir() -> Path:
    """
    Return the base directory where the skill keeps its downloaded data.

    This is always `{skill_dir}/Data/`.
    """
    return SCRIPT_DIR / DATA_DIR_NAME


def resolve_plugin_sources_dir() -> Path:
    """
    Resolve the plugin sources directory using this priority:

    1. Environment variable SE_PLUGIN_DOWNLOAD_FOLDER
    2. CLAUDE.md or AGENTS.md in the current working directory
    3. `{base}/Sources/` (default)
    """
    env_folder = os.environ.get("SE_PLUGIN_DOWNLOAD_FOLDER", "").strip()
    if env_folder:
        return Path(env_folder)

    cwd = Path.cwd()
    for config_name in ("CLAUDE.md", "AGENTS.md"):
        config_path = cwd / config_name
        folder = _read_config_from_file(config_path)
        if folder:
            return Path(folder)

    return resolve_base_dir() / PLUGIN_SOURCES_SUBDIR


def resolve_pluginhub_dir() -> Path:
    """
    Return the directory that holds the local PluginHub-SE2 clone.

    This is always `{base}/PluginHub-SE2/` — it is not user-configurable so
    that the skill always knows where to find the registry regardless of
    any override applied to the plugin sources folder.
    """
    return resolve_base_dir() / PLUGINHUB_SUBDIR


def resolve_registry_path() -> Path:
    """Return the path to `plugins.json` (sibling of Sources/ and PluginHub-SE2/)."""
    return resolve_base_dir() / "plugins.json"


def resolve_code_index_dir() -> Path:
    """Return the directory that holds CSV index files produced by index_plugin_code.py."""
    return resolve_base_dir() / CODE_INDEX_SUBDIR


def resolve_all_plugin_sources_dirs() -> list:
    """
    Return all directories that may contain plugin sources.

    Currently this is just the configured/temp sources directory; kept as a
    list to keep call sites stable in case additional fallback locations
    are reintroduced later.
    """
    dirs = []
    sources_dir = resolve_plugin_sources_dir()
    if sources_dir.exists():
        dirs.append(sources_dir)
    return dirs


def ensure_plugin_sources_dir() -> Path:
    """
    Resolve and create the plugin sources directory.
    Raises an error with a helpful message if creation fails.
    """
    plugin_dir = resolve_plugin_sources_dir()
    try:
        plugin_dir.mkdir(parents=True, exist_ok=True)
        return plugin_dir
    except OSError as e:
        print(
            f"ERROR: Cannot create plugin download folder: {plugin_dir}\n"
            f"  Reason: {e}\n"
            f"\n"
            f"Please specify a writable plugin download folder by one of:\n"
            f"  1. Set environment variable: SE_PLUGIN_DOWNLOAD_FOLDER=/path/to/folder\n"
            f"  2. Add to CLAUDE.md or AGENTS.md in your project directory:\n"
            f"     plugin_download_folder: /path/to/folder\n",
            file=sys.stderr,
        )
        sys.exit(1)


def ensure_base_dir() -> Path:
    """Resolve and create the base directory."""
    base = resolve_base_dir()
    base.mkdir(parents=True, exist_ok=True)
    return base
