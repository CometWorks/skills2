"""
Plugin registry — manages `Data/plugins.json` within the skill directory.

The registry lives next to the PluginHub-SE2 clone and the Sources folder
(see plugin_paths.resolve_registry_path) and records:

* The PluginHub-SE2 repository version that was downloaded, so the local
  clone can be refreshed when the upstream repo changes.
* Each plugin listed in PluginHub-SE2 along with both the commit hash
  registered in the PluginHub XML (`registered_commit`) and the commit
  hash that was actually cloned (or, as a per-plugin fallback, unzipped)
  locally (`downloaded_commit`).
  The two may diverge if the XML was updated upstream after the local
  copy was fetched; comparing them tells the skill whether a local copy
  is out of date.
* The plugins whose source code has been indexed by index_plugin_code.py
  (`indexed_plugins`) and the full catalog of plugins available from the
  PluginHub-SE2 XML files (`available_plugins`).

The registry is intentionally JSON with stable keys so it is easy to
inspect by hand and diff in version control if users commit it.
"""

import datetime
import json
from typing import List, Optional

from plugin_paths import ensure_base_dir, resolve_registry_path


REGISTRY_VERSION = 2


def _now_iso() -> str:
    return datetime.datetime.now(datetime.timezone.utc).isoformat(timespec="seconds")


def load_registry() -> dict:
    """Load the registry, returning a fresh empty structure if missing."""
    path = resolve_registry_path()
    if not path.exists():
        return _empty_registry()
    try:
        with open(path, "r", encoding="utf-8") as f:
            data = json.load(f)
    except (OSError, json.JSONDecodeError):
        return _empty_registry()
    data.setdefault("version", REGISTRY_VERSION)
    data.setdefault("pluginhub", {})
    data.setdefault("downloaded_plugins", {})
    data.setdefault("indexed_plugins", [])
    data.setdefault("available_plugins", [])
    return data


def save_registry(registry: dict) -> None:
    ensure_base_dir()
    path = resolve_registry_path()
    with open(path, "w", encoding="utf-8") as f:
        json.dump(registry, f, indent=2, sort_keys=True)
        f.write("\n")


def _empty_registry() -> dict:
    return {
        "version": REGISTRY_VERSION,
        "pluginhub": {},
        "downloaded_plugins": {},
        "indexed_plugins": [],
        "available_plugins": [],
    }


def update_pluginhub(
    *,
    repo_url: str,
    commit: str,
    method: str,
    local_path: Optional[str] = None,
) -> None:
    """Record the PluginHub-SE2 version that is present locally."""
    registry = load_registry()
    registry["pluginhub"] = {
        "repo_url": repo_url,
        "commit": commit,
        "method": method,
        "local_path": local_path or "",
        "updated_at": _now_iso(),
    }
    save_registry(registry)


def update_plugin(
    *,
    key: str,
    id: str,
    repo_id: str,
    name: str,
    registered_commit: str,
    downloaded_commit: str,
    method: str,
    local_path: str,
) -> None:
    """Record a plugin download in the registry."""
    registry = load_registry()
    registry["downloaded_plugins"][key] = {
        "id": id,
        "repo_id": repo_id,
        "name": name,
        "registered_commit": registered_commit,
        "downloaded_commit": downloaded_commit,
        "method": method,
        "local_path": local_path,
        "updated_at": _now_iso(),
    }
    save_registry(registry)


def get_plugin_entry(key: str) -> Optional[dict]:
    return load_registry()["downloaded_plugins"].get(key)


def update_indexer_state(
    *,
    indexed_plugins: List[dict],
    available_plugins: List[dict],
) -> None:
    """Record the latest indexer output (which plugins were indexed and the
    full PluginHub-SE2 catalog) into the registry."""
    registry = load_registry()
    registry["indexed_plugins"] = list(indexed_plugins)
    registry["available_plugins"] = list(available_plugins)
    save_registry(registry)
