---
name: se2-dev-plugin
description: Plugin development for Space Engineers 2. Search plugin code from PluginHub-SE2 for examples and patterns.
license: MIT
allowed-tools: Read, Bash(*Prepare.bat*), Bash(*Clean.bat*), Bash(*prepare.sh*), Bash(*clean.sh*), Bash(*run_prepare.sh*), Bash(*graphify_check.sh*), Bash(*GraphifyCheck.bat*), Bash(command -v graphify*), Bash(graphify*), Bash(*GRAPHIFY_MAX_GRAPH_BYTES*), Bash(*dotnet build*), Bash(*dotnet clean*), Bash(*uv run search_plugin_code.py *), Bash(*uv run index_plugin_code.py*), Bash(*uv run list_plugins.py*), Bash(*uv run download_plugin_source.py *), Bash(*uv run download_pluginhub.py*), Bash(*busybox* grep *), Bash(*busybox* find *), Bash(*busybox* cat *), Bash(*busybox* head *), Bash(*busybox* tail *), Bash(*busybox* ls*), Bash(*busybox* wc *), Bash(*busybox* sort *), Bash(*busybox* uniq *), Bash(*busybox* tree*), Bash(grep *), Bash(find *), Bash(cat *), Bash(head *), Bash(tail *), Bash(ls *), Bash(wc *), Bash(sort *), Bash(uniq *), Bash(tree *)
---

# SE2 Plugin Development Skill

Plugin development for Space Engineers 2.

**⚠️ CRITICAL: Commands run in a UNIX shell. Use bash syntax! On Windows this is BusyBox (`busybox.exe <cmd>`); on Linux use the native shell directly.**

Examples:
- ✅ `test -f file.txt && echo exists`
- ✅ `ls -la | head -10`
- ❌ `if exist file.txt (echo exists)` - This will NOT work

**Actions:**

- **prepare**: Run the one-time preparation (`Prepare.bat` on Windows, `prepare.sh` on Linux)
- **bash**: Run UNIX shell commands (BusyBox on Windows, native shell on Linux)
- **search**: Search plugin code using `search_plugin_code.py`

## Routing Decision

Check these patterns **in order** - first match wins:

| Priority | Pattern | Example | Route |
|----------|---------|---------|-------|
| 1 | Empty or bare invocation | `se2-dev-plugin` | Show this help |
| 2 | Prepare keywords | `se2-dev-plugin prepare`, `se2-dev-plugin setup`, `se2-dev-plugin init` | prepare |
| 3 | Bash/shell keywords | `se2-dev-plugin bash`, `se2-dev-plugin grep`, `se2-dev-plugin cat` | bash |
| 4 | Search keywords | `se2-dev-plugin search`, `se2-dev-plugin find class`, `se2-dev-plugin lookup` | search |

## Getting Started

**⚠️ CRITICAL: Before running ANY commands, read [CommandExecution.md](CommandExecution.md) to avoid common mistakes that cause command failures.**

If the `Prepare.DONE` file is missing in this folder, you MUST run the one-time preparation steps first. See the [prepare action](./actions/prepare.md).

## Essential Documentation

- **[CommandExecution.md](CommandExecution.md)** - ⚠️ **READ THIS FIRST** - How to run commands correctly on Windows and Linux

## Plugin Development Documentation

Read the appropriate documents for further details:
- [Plugin.md](Plugin.md) Plugin development (shared skills for both client and server)
- [ClientPlugin.md](ClientPlugin.md) Client plugin development (relevant on client side)
- [Guide.md](Guide.md) Use this to answer questions about the plugin development process in general.
- [Review.md](Review.md) How to review a plugin for inclusion on PluginHub-SE2 (manifest conformance, commit pin, security audit, from-source build).
- [Publicizer.md](Publicizer.md) How to use the Krafs publicizer to access internal, protected or private members in the original game code (optional).
- [OtherPluginsAsExamples.md](OtherPluginsAsExamples.md) How to look into the source code of other plugins as examples.

## Harmony Patching Documentation

Progressive documentation for Harmony patching (start with basics, then read advanced topics as needed):

1. **[Patching.md](Patching.md)** - Start here: patch types, prefix/postfix basics, common patterns
2. **[PatchInjections.md](PatchInjections.md)** - Special parameters: `__instance`, `__result`, `___fields`, `__state`
3. **[AccessTools.md](AccessTools.md)** - Reflection utilities for finding methods, fields, and types
4. **[TranspilerPatching.md](TranspilerPatching.md)** - IL-level patching for complex modifications
5. **[PatchingSpecialCases.md](PatchingSpecialCases.md)** - Finalizers, reverse patches, auxiliary methods, priority
6. **[PreloaderPatching.md](PreloaderPatching.md)** - Pre-JIT patching (Mono.Cecil, client only)

## Plugin Distribution

Plugins are released exclusively on the PluginHub-SE2. All plugins must be open source, since they are compiled on
the player's machine from the GitHub source revision identified by its PluginHub-SE2 registration. Plugins are
reviewed for safety and security on submission, but only on a best effort basis, without any legal guarantees.
Plugins are running native code and can do anything. When reviewing a submission (or update) to PluginHub-SE2,
follow [Review.md](Review.md).

Use the `se2-dev-game-code` skill to search the game's decompiled code. You will need this to
understand how the game's internals work and how to interface with it and patch it properly.

## References

- [Pulsar](https://github.com/SpaceGT/Pulsar) Plugin loader for Space Engineers
- [Pulsar Installer](https://github.com/StarCpt/Pulsar-Installer) Installer for Pulsar on Windows
- [PluginHub-SE2](https://github.com/StarCpt/PluginHub-SE2/) Public plugin registry for Pulsar

## Plugin Code Search

Search the source code of plugins from PluginHub-SE2 for examples and patterns:

```bash
# List available plugins
uv run list_plugins.py
uv run list_plugins.py --search "camera"

# Download a plugin's source code (use EXACT name from list)
uv run download_plugin_source.py "Plugin Name"

# Index downloaded plugins (automatic after download)
uv run index_plugin_code.py

# Search plugin code
uv run search_plugin_code.py class declaration Plugin
uv run search_plugin_code.py method signature Patch

# Count results before viewing (useful for large result sets)
uv run search_plugin_code.py class usage Plugin --count

# Limit number of results
uv run search_plugin_code.py class usage IPlugin --limit 20
```

The PluginHub-SE2 contains descriptions of all available plugins. Download sources for plugins
that may help with your task, then index and search them.

### Storage layout

`Data/` inside this skill folder is a junction (Windows) or symlink (Linux)
created by the preparation script. It points to the per-user data folder —
`%USERPROFILE%\.se2-dev\plugin\` on Windows, `~/.se2-dev/plugin/` on Linux.
Everything downloaded by the skill is stored there so it survives across
re-installs and `Clean.bat`/`clean.sh` runs.

- `Data/PluginHub-SE2/` — `git clone` of the PluginHub-SE2 registry
  (refreshed in place by `download_pluginhub.py` / `git pull`)
- `Data/Sources/` — pre-created by the preparation script; contains a per-plugin
  subfolder for every downloaded plugin
- `Data/Sources/<PluginName>/` — git clone of the plugin's GitHub repository
  (overridable via `SE_PLUGIN_DOWNLOAD_FOLDER` or `plugin_download_folder:` in
  `CLAUDE.md`/`AGENTS.md`)
- `Data/CodeIndex/` — CSV indexes produced by
  `index_plugin_code.py` and consumed by `search_plugin_code.py`
- `Data/plugins.json` — **registry**: records the upstream commit of the
  PluginHub clone, the per-plugin download state (`downloaded_plugins` —
  `registered_commit` vs `downloaded_commit`, so you can tell when a local copy
  is out of date), the plugins that have been indexed (`indexed_plugins`),
  and the full PluginHub-SE2 catalog (`available_plugins`).

`download_plugin_source.py` requires `git` on `PATH` and clones each plugin
into its own `Data/Sources/<PluginName>/` directory. Re-running it does
`git fetch` + `git checkout` so local copies can be updated incrementally with
a `git pull`. The commit hashes above are recorded in `plugins.json`.

See [search action](./actions/search.md) for complete documentation.

## Graphify Graph (optional)

Preparation can build a separate Graphify graph for the downloaded plugin sources under
`Data/Sources` (or `SE2_DEV_PLUGIN_PROJECT_ROOT`). It is a navigable map of
call/inherit/reference edges plus clustered communities that answers *structural* questions
the CSV code index cannot. With the fast Rust clustering backend (Python 3.12 via `uv`,
provisioned automatically) prepare builds it **automatically**; this corpus is small so it
is quick either way. Where the fast backend is unavailable it stays **opt-in** with
`SE2_DEV_GRAPHIFY=1`; `SE2_DEV_GRAPHIFY=0` disables it. Read on demand — skip for normal
search work: build via [GraphifyPrepare.md](GraphifyPrepare.md), query via
[GraphifyUsage.md](GraphifyUsage.md). Check a built graph with
`bash graphify_check.sh Data/Sources --deep`.

## Action References

Follow the detailed instructions in:

- [prepare action](./actions/prepare.md) - One-time preparation
- [bash action](./actions/bash.md) - Running UNIX shell commands via busybox
- [search action](./actions/search.md) - Search plugin code for examples

## Remarks

The original source of this skill: https://github.com/CometWorks/skills2
