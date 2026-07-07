#!/usr/bin/env python3
"""
Download Plugin Source Code from GitHub

Downloads the source code of a plugin from its GitHub repository.

The download folder is determined by (in priority order):
1. SE_PLUGIN_DOWNLOAD_FOLDER environment variable
2. plugin_download_folder setting in CLAUDE.md or AGENTS.md (in CWD)
3. Default: Data/Sources/ inside the skill directory (a junction on Windows /
   symlink on Linux to the per-user data folder set up by the preparation
   script: %USERPROFILE%\.se2-dev\plugin\Sources\ on Windows,
   ~/.se2-dev/plugin/Sources/ on Linux)

Each plugin is cloned into its own Data/Sources/<PluginName>/ subdirectory
with `git clone` and checked out at the commit recorded in the PluginHub-SE2
XML, so the local copy can later be updated in place with `git pull` (or by
re-running this script). If `git` is not available on PATH the script falls
back to downloading a ZIP archive of that commit.

Regardless of the method, the download is recorded in `Data/plugins.json`,
with both the commit registered in PluginHub and the commit actually
checked out locally.

Usage:
    python download_plugin_source.py <plugin_id_or_name>

Examples:
    python download_plugin_source.py author-github-username/PluginName
    python download_plugin_source.py "Plugin Name"
    python download_plugin_source.py PluginName
"""

import shutil
import subprocess
import sys
import xml.etree.ElementTree as ET
import zipfile
from pathlib import Path

import requests

from git_utils import clone_repo, get_head_commit, is_git_available
from plugin_paths import ensure_plugin_sources_dir, resolve_pluginhub_dir
from plugin_registry import update_plugin

SCRIPT_DIR = Path(__file__).parent.resolve()


def _plugins_dir() -> Path:
    return resolve_pluginhub_dir() / "Plugins"


def parse_plugin_xml(xml_file: Path) -> dict:
    """Parse a plugin XML file and extract relevant information."""
    try:
        tree = ET.parse(xml_file)
        root = tree.getroot()

        plugin_info = {
            "id": "",
            "repo_id": "",
            "name": "",
            "commit": "",
            "source_dirs": [],
        }

        id_elem = root.find("Id")
        if id_elem is not None and id_elem.text:
            plugin_info["id"] = id_elem.text.strip()

        # New-format SE2 plugins store owner/repo in <RepoId>; old-format plugins
        # store it in <Id>. Fall back to <Id> when it looks like owner/repo.
        repo_id_elem = root.find("RepoId")
        if repo_id_elem is not None and repo_id_elem.text:
            plugin_info["repo_id"] = repo_id_elem.text.strip()
        elif "/" in plugin_info["id"]:
            plugin_info["repo_id"] = plugin_info["id"]

        name_elem = root.find("FriendlyName")
        if name_elem is not None and name_elem.text:
            plugin_info["name"] = name_elem.text.strip()

        commit_elem = root.find("Commit")
        if commit_elem is not None and commit_elem.text:
            plugin_info["commit"] = commit_elem.text.strip()

        source_dirs = root.find("SourceDirectories")
        if source_dirs is not None:
            for dir_elem in source_dirs.findall("Directory"):
                if dir_elem.text:
                    plugin_info["source_dirs"].append(dir_elem.text.strip())

        return plugin_info
    except Exception as e:
        print(f"Error parsing {xml_file}: {e}", file=sys.stderr)
        return None


def find_plugin(search_term: str) -> dict:
    """Find a plugin by ID, name, or partial match."""
    plugins_dir = _plugins_dir()
    if not plugins_dir.exists():
        print(f"PluginHub-SE2 not found at {plugins_dir.parent}", file=sys.stderr)
        print("Run: uv run download_pluginhub.py", file=sys.stderr)
        return None

    search_lower = search_term.lower()
    matches = []

    for xml_file in plugins_dir.glob("*.xml"):
        plugin = parse_plugin_xml(xml_file)
        if plugin:
            # Exact ID match (accepts the raw <Id> value — GUID or owner/repo)
            if plugin["id"].lower() == search_lower:
                return plugin

            # Exact RepoId match (owner/repo)
            if plugin["repo_id"] and plugin["repo_id"].lower() == search_lower:
                return plugin

            # Exact name match
            if plugin["name"].lower() == search_lower:
                return plugin

            # Repo name match (e.g., "PluginName" matches "author-github-username/PluginName")
            repo_id = plugin["repo_id"] or plugin["id"]
            repo_name = repo_id.split("/")[-1] if "/" in repo_id else repo_id
            if repo_name.lower() == search_lower:
                return plugin

            # Partial matches
            if (search_lower in plugin["id"].lower() or
                search_lower in plugin["repo_id"].lower() or
                search_lower in plugin["name"].lower() or
                search_lower in repo_name.lower()):
                matches.append(plugin)

    if len(matches) == 1:
        return matches[0]
    elif len(matches) > 1:
        print(f"Multiple plugins match '{search_term}':")
        for m in matches:
            print(f"  - {m['name']} ({m['id']})")
        print("\nPlease specify the exact plugin ID.")
        return None
    else:
        print(f"No plugin found matching '{search_term}'")
        return None


def _download_via_git(
    repo_url: str, dest_dir: Path, registered_commit: str
) -> str:
    """
    Clone the plugin repo and check out `registered_commit` if given.
    Returns the actual commit hash on HEAD after checkout.
    """
    commit_arg = registered_commit or None
    if not clone_repo(repo_url, dest_dir, commit=commit_arg):
        raise RuntimeError("git clone failed")
    actual = get_head_commit(dest_dir)
    if not actual:
        raise RuntimeError("failed to read HEAD commit after clone")
    return actual


def _download_via_zip(
    owner: str, repo: str, dest_dir: Path, registered_commit: str, plugin_sources_dir: Path
) -> str:
    """
    Download and extract a ZIP archive. Returns the commit hash that was
    downloaded (the GitHub folder suffix, which matches the commit for a
    full SHA URL and is the branch name otherwise).
    """
    if registered_commit:
        zip_url = f"https://github.com/{owner}/{repo}/archive/{registered_commit}.zip"
    else:
        zip_url = f"https://github.com/{owner}/{repo}/archive/refs/heads/main.zip"

    print(f"  URL: {zip_url}")

    response = requests.get(zip_url)
    response.raise_for_status()

    zip_path = plugin_sources_dir / "temp_download.zip"
    with open(zip_path, "wb") as f:
        f.write(response.content)

    print("Extracting...")
    downloaded_suffix = ""
    try:
        with zipfile.ZipFile(zip_path, "r") as zip_ref:
            zip_ref.extractall(plugin_sources_dir)
            top_names = {name.split("/")[0] for name in zip_ref.namelist() if name}
            prefix = f"{repo}-"
            for top in top_names:
                if top.startswith(prefix):
                    downloaded_suffix = top[len(prefix):]
                    break
    except zipfile.BadZipFile as e:
        zip_path.unlink(missing_ok=True)
        raise RuntimeError(f"failed to extract: {e}")

    # Rename extracted directory to the canonical repo name.
    for item in plugin_sources_dir.iterdir():
        if item.is_dir() and item.name.startswith(repo) and item != dest_dir:
            if dest_dir.exists():
                shutil.rmtree(dest_dir)
            item.rename(dest_dir)
            break

    zip_path.unlink(missing_ok=True)

    # GitHub archive folder suffix is the commit SHA for sha URLs, branch name for branch URLs.
    if len(downloaded_suffix) == 40 and all(c in "0123456789abcdef" for c in downloaded_suffix.lower()):
        return downloaded_suffix.lower()
    # For branch downloads we cannot determine the commit from the archive alone.
    return registered_commit or ""


def download_plugin(plugin: dict) -> bool:
    """Download a plugin's source code from GitHub."""
    plugin_sources_dir = ensure_plugin_sources_dir()
    print(f"Plugin sources directory: {plugin_sources_dir}")

    # Prefer <RepoId> (new format); fall back to <Id> when it holds owner/repo.
    repo_id = plugin["repo_id"] or plugin["id"]
    if not repo_id:
        print("Plugin has no GitHub repo reference (<RepoId> or owner/repo <Id>)", file=sys.stderr)
        return False

    parts = repo_id.split("/")
    if len(parts) != 2 or not parts[0] or not parts[1]:
        print(
            f"Plugin repo reference is not in 'owner/repo' form: {repo_id}. "
            f"Add a <RepoId>owner/repo</RepoId> element to the plugin XML.",
            file=sys.stderr,
        )
        return False

    owner, repo = parts
    registered_commit = plugin.get("commit", "")
    dest_dir = plugin_sources_dir / repo

    if dest_dir.exists():
        print(f"Removing existing directory: {dest_dir}")
        shutil.rmtree(dest_dir)

    print(f"Downloading {plugin['name']} from GitHub...")

    try:
        if is_git_available():
            print("  Method: git clone")
            repo_url = f"https://github.com/{owner}/{repo}.git"
            downloaded_commit = _download_via_git(repo_url, dest_dir, registered_commit)
            method = "git"
        else:
            print("  Method: ZIP download (git not on PATH)")
            downloaded_commit = _download_via_zip(
                owner, repo, dest_dir, registered_commit, plugin_sources_dir
            )
            method = "zip"
    except requests.exceptions.RequestException as e:
        print(f"Failed to download: {e}", file=sys.stderr)
        return False
    except RuntimeError as e:
        print(f"Failed to download: {e}", file=sys.stderr)
        return False

    print(f"Downloaded to: {dest_dir}")
    if downloaded_commit:
        print(f"Commit: registered={registered_commit[:12] or '(none)'} downloaded={downloaded_commit[:12]}")

    # Record the download in plugins.json.
    try:
        update_plugin(
            key=repo,
            id=plugin.get("id", ""),
            repo_id=repo_id,
            name=plugin.get("name", ""),
            registered_commit=registered_commit,
            downloaded_commit=downloaded_commit,
            method=method,
            local_path=str(dest_dir),
        )
    except Exception as e:
        print(f"Warning: failed to update plugins.json: {e}", file=sys.stderr)

    # Run indexing
    print("\nIndexing plugin code...")
    index_script = SCRIPT_DIR / "index_plugin_code.py"
    result = subprocess.run(["uv", "run", str(index_script)], cwd=SCRIPT_DIR)
    if result.returncode != 0:
        print("Warning: Indexing failed", file=sys.stderr)

    return True


def main():
    if len(sys.argv) < 2:
        print("Usage: python download_plugin_source.py <plugin_id_or_name>")
        print("\nExamples:")
        print("  python download_plugin_source.py author-github-username/PluginName")
        print("  python download_plugin_source.py \"Plugin Name\"")
        print("  python download_plugin_source.py PluginName")
        print("\nTo list available plugins, run: uv run list_plugins.py")
        sys.exit(1)

    search_term = " ".join(sys.argv[1:])
    plugin = find_plugin(search_term)

    if plugin:
        success = download_plugin(plugin)
        sys.exit(0 if success else 1)
    else:
        sys.exit(1)


if __name__ == "__main__":
    main()
