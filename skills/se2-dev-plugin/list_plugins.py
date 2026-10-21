#!/usr/bin/env python3
"""
List Plugins from PluginHub-SE2

Lists all available plugins from the PluginHub-SE2 registry, showing which ones
have their source code downloaded locally.

Usage:
    python list_plugins.py [options]

Examples:
    python list_plugins.py                    # List all plugins
    python list_plugins.py --local            # List only locally available plugins
    python list_plugins.py --search "camera"  # Search plugins by name/description
"""

import argparse
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

from plugin_paths import resolve_all_plugin_sources_dirs, resolve_pluginhub_dir
from plugin_registry import load_registry


def parse_plugin_xml(xml_file: Path) -> dict:
    """Parse a plugin XML file and extract relevant information."""
    try:
        tree = ET.parse(xml_file)
        root = tree.getroot()

        plugin_info = {
            "id": "",
            "repo_id": "",
            "name": "",
            "author": "",
            "tooltip": "",
            "description": "",
            "commit": "",
            "source_dirs": [],
            "hidden": False,
            "local": False,
            "xml_file": xml_file.name
        }

        # Extract fields
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

        author_elem = root.find("Author")
        if author_elem is not None and author_elem.text:
            plugin_info["author"] = author_elem.text.strip()

        tooltip_elem = root.find("Tooltip")
        if tooltip_elem is not None and tooltip_elem.text:
            plugin_info["tooltip"] = tooltip_elem.text.strip()

        desc_elem = root.find("Description")
        if desc_elem is not None and desc_elem.text:
            plugin_info["description"] = desc_elem.text.strip()
        elif plugin_info["tooltip"]:
            plugin_info["description"] = plugin_info["tooltip"]

        commit_elem = root.find("Commit")
        if commit_elem is not None and commit_elem.text:
            plugin_info["commit"] = commit_elem.text.strip()

        source_dirs = root.find("SourceDirectories")
        if source_dirs is not None:
            for dir_elem in source_dirs.findall("Directory"):
                if dir_elem.text:
                    plugin_info["source_dirs"].append(dir_elem.text.strip())

        hidden_elem = root.find("Hidden")
        if hidden_elem is not None and hidden_elem.text:
            plugin_info["hidden"] = hidden_elem.text.strip().lower() == "true"

        return plugin_info
    except Exception as e:
        print(f"Error parsing {xml_file}: {e}", file=sys.stderr)
        return None


def load_all_plugins() -> list:
    """Load all plugins from PluginHub-SE2."""
    pluginhub_dir = resolve_pluginhub_dir()
    plugins_dir = pluginhub_dir / "Plugins"
    if not plugins_dir.exists():
        print(f"PluginHub-SE2 not found at {pluginhub_dir}", file=sys.stderr)
        print("Run: uv run download_pluginhub.py", file=sys.stderr)
        return []

    source_dirs = resolve_all_plugin_sources_dirs()
    registry = load_registry()

    plugins = []
    for xml_file in plugins_dir.glob("*.xml"):
        plugin = parse_plugin_xml(xml_file)
        if plugin:
            # Check if source is available locally in any source directory.
            # Use repo_id (owner/repo) to locate the repo folder; fall back to id.
            identifier = plugin["repo_id"] or plugin["id"]
            plugin["local"] = False
            plugin["local_path"] = ""
            plugin["downloaded_commit"] = ""
            if identifier:
                repo_name = identifier.split("/")[-1] if "/" in identifier else identifier
                for src_dir in source_dirs:
                    local_path = src_dir / repo_name
                    if local_path.exists():
                        plugin["local"] = True
                        plugin["local_path"] = str(local_path)
                        break
                entry = registry["downloaded_plugins"].get(repo_name)
                if entry:
                    plugin["downloaded_commit"] = entry.get("downloaded_commit", "")
            plugins.append(plugin)

    return sorted(plugins, key=lambda p: p["name"].lower())


def main():
    parser = argparse.ArgumentParser(description="List plugins from PluginHub-SE2")
    parser.add_argument("--local", action="store_true", help="Show only locally available plugins")
    parser.add_argument("--remote", action="store_true", help="Show only plugins not downloaded locally")
    parser.add_argument("--search", "-s", type=str, help="Search plugins by name or description")
    parser.add_argument("--json", action="store_true", help="Output as JSON")
    parser.add_argument("--verbose", "-v", action="store_true", help="Show detailed information")
    args = parser.parse_args()

    plugins = load_all_plugins()

    if not plugins:
        sys.exit(1)

    # Apply filters
    if args.local:
        plugins = [p for p in plugins if p["local"]]
    elif args.remote:
        plugins = [p for p in plugins if not p["local"]]

    if args.search:
        search_term = args.search.lower()
        plugins = [p for p in plugins if
                   search_term in p["name"].lower() or
                   search_term in p["description"].lower() or
                   search_term in p["tooltip"].lower() or
                   search_term in p["id"].lower() or
                   search_term in p["repo_id"].lower()]

    # Output
    if args.json:
        import json
        print(json.dumps(plugins, indent=2))
    else:
        local_count = sum(1 for p in plugins if p["local"])
        print(f"Found {len(plugins)} plugins ({local_count} available locally)\n")

        for plugin in plugins:
            status = "[LOCAL]" if plugin["local"] else "[REMOTE]"
            print(f"{status} {plugin['name']}")
            print(f"  ID: {plugin['id']}")
            if plugin["repo_id"] and plugin["repo_id"] != plugin["id"]:
                print(f"  RepoId: {plugin['repo_id']}")
            print(f"  Author: {plugin['author']}")
            if plugin["commit"]:
                registered_short = plugin["commit"][:12]
                downloaded_short = plugin.get("downloaded_commit", "")[:12]
                if downloaded_short and downloaded_short != registered_short:
                    print(f"  Commit: registered={registered_short} downloaded={downloaded_short} (stale)")
                elif downloaded_short:
                    print(f"  Commit: {registered_short}")
                else:
                    print(f"  Commit (registered): {registered_short}")
            if args.verbose:
                if plugin["tooltip"]:
                    print(f"  Tooltip: {plugin['tooltip']}")
                if plugin["description"] and plugin["description"] != plugin["tooltip"]:
                    # Truncate long descriptions
                    desc = plugin["description"]
                    if len(desc) > 200:
                        desc = desc[:200] + "..."
                    print(f"  Description: {desc}")
                if plugin["local_path"]:
                    print(f"  Local path: {plugin['local_path']}")
            print()


if __name__ == "__main__":
    main()
