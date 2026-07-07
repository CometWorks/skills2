# Search Action

> **Part of the se2-dev-plugin skill.** Invoked when searching plugin source code.

Search plugin code using `uv run search_plugin_code.py` from this skill folder.

## Prerequisites

### 1. Update PluginHub-SE2 (optional but recommended)

```cmd
uv run download_pluginhub.py
```

This downloads (or updates) the PluginHub-SE2 registry into
`Data\PluginHub-SE2` within the skill directory. When `git` is available on PATH
the registry is cloned with `git clone` and refreshed with `git fetch`/`git reset`
on subsequent runs; otherwise the script falls back to downloading a ZIP snapshot.
Either way, the current commit hash is recorded in `plugins.json` (see below).

### 2. List Available Plugins

```cmd
uv run list_plugins.py                    # List all plugins
uv run list_plugins.py --local            # List only locally available plugins
uv run list_plugins.py --search "camera"  # Search plugins by name/description
uv run list_plugins.py -v                 # Verbose output with descriptions
```

### 3. Download Plugin Source

```cmd
uv run download_plugin_source.py "Plugin Name"
uv run download_plugin_source.py author-github-username/PluginName
uv run download_plugin_source.py PluginName
```

Plugin sources are downloaded to `Data/Sources/<PluginName>` (where `Data/`
is a junction (Windows) / symlink (Linux) to the per-user data folder —
`%USERPROFILE%\.se2-dev\plugin\` on Windows, `~/.se2-dev/plugin/` on
Linux — set up by the preparation script). The destination can be
overridden via the `SE_PLUGIN_DOWNLOAD_FOLDER` environment variable or a
`plugin_download_folder:` entry in `CLAUDE.md` / `AGENTS.md` in the current
working directory.

Preparation requires `git` on `PATH`, so each plugin is `git clone`d at the
commit recorded in its PluginHub XML and can later be updated in place with
`git pull` (or by re-running `download_plugin_source.py`). Both the commit
registered in PluginHub and the commit actually checked out locally are
recorded in `plugins.json`.

### 4. Index Downloaded Plugins

```cmd
uv run index_plugin_code.py
```

This indexes all downloaded plugin source code.

## Quick Reference

```cmd
uv run search_plugin_code.py --help
```

## Search Syntax

```cmd
uv run search_plugin_code.py <category> <symbol_type> <pattern> [options]
```

### Categories
- `class` - Classes and records
- `interface` - Interfaces
- `struct` - Structs
- `enum` - Enums
- `method` - Methods
- `field` - Fields (member variables)
- `property` - Properties
- `event` - Events
- `constructor` - Constructors
- `namespace` - Namespaces

### Symbol Types
- `declaration` - Where symbols are defined
- `usage` - Where symbols are used
- `signature` - Method signatures (method category only)
- `parent` - Parent class/interface (class/interface categories)
- `children` - Child classes/interfaces (class/interface categories)
- `implements` - Interfaces implemented by a class (class category)
- `implementors` - Classes implementing an interface (interface category)

### Options
- `-c, --count` - Print only the count of matches
- `-l, --limit N` - Limit number of results
- `-o, --offset N` - Skip first N results
- `-n, --namespace PREFIX` - Filter by namespace prefix
- `-i, --case-insensitive` - Case-insensitive matching

### Patterns
- `text:X` or just `X` - Literal text match
- `re:X` - Regular expression match

## Examples

### Find class declarations
```cmd
uv run search_plugin_code.py class declaration Plugin
```

### Find Harmony patch methods
```cmd
uv run search_plugin_code.py method declaration Patch
uv run search_plugin_code.py method signature Prefix
uv run search_plugin_code.py method signature Postfix
```

### Find method usages
```cmd
uv run search_plugin_code.py method usage Harmony
```

### Find children of a base class
```cmd
uv run search_plugin_code.py class children PluginBase
```

### Case-insensitive search
```cmd
uv run search_plugin_code.py -i class declaration config
```

## Plugin List

A single `Data\plugins.json` keeps track of plugins, with these top-level keys:

- `pluginhub` — the upstream commit of the PluginHub-SE2 clone (so the copy can
  be refreshed when the upstream repo changes).
- `downloaded_plugins.<repo>` — for each cloned plugin:
  - `registered_commit` — the commit the PluginHub XML currently points at.
  - `downloaded_commit` — the commit actually checked out in
    `Sources/<PluginName>`. If the two differ, the local copy is out of date and
    can be re-fetched with `download_plugin_source.py`.
  - `method` — `git` (clone) or `zip` (snapshot).
- `indexed_plugins` — plugins whose sources were found and indexed by
  `index_plugin_code.py`.
- `available_plugins` — everything PluginHub-SE2 knows about (parsed from the
  XML files in `Data\PluginHub-SE2\Plugins\`).

## Workflow

1. **Find relevant plugins**: Use `list_plugins.py --search` to find plugins with features you want to learn from
2. **Download sources**: Use `download_plugin_source.py` to get the source code
3. **Index**: Run `index_plugin_code.py` to build the search index
4. **Search**: Use `search_plugin_code.py` to find code patterns

## When to Search

Search plugin code when:
- Looking for examples of Harmony patching techniques
- Understanding how other plugins implement specific features
- Finding examples of game API usage in plugin context
- Learning plugin development patterns
