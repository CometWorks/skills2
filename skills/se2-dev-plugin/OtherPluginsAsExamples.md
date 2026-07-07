# Looking at Other Plugins as Examples

You can look into the source code of any other plugin registered on the `PluginHub-SE2` as examples, they are all open source.

## Finding and Downloading Plugins

### Step 1: List Available Plugins

```bash
# List all plugins
uv run list_plugins.py

# Search for plugins by keyword
uv run list_plugins.py --search "camera"
uv run list_plugins.py --search "paint"
uv run list_plugins.py --search "tool"
```

### Step 2: Download Plugin Source

**IMPORTANT**: You must use the EXACT plugin name as shown in the list output.

```bash
# ✅ CORRECT - exact name with proper capitalization and spacing
uv run download_plugin_source.py "Paint Replacer"
uv run download_plugin_source.py "Plugin Name"

# ❌ WRONG - these will fail
uv run download_plugin_source.py "paint replacer"  # wrong case
uv run download_plugin_source.py "Paint-Replacer"  # wrong format
uv run download_plugin_source.py "PaintReplacer"   # wrong spacing
```

**Tip**: Copy-paste the name directly from `list_plugins.py` output to avoid typos.

### Step 3: Search Downloaded Plugin Code

After downloading, the plugin is automatically indexed and ready to search:

```bash
# Search across all downloaded plugins
uv run search_plugin_code.py class declaration Plugin
uv run search_plugin_code.py method signature Patch
```

## Manual Plugin Discovery (Alternative Method)

Look into the `PluginHub-SE2` folder that `download_pluginhub.py` created at
`Data\PluginHub-SE2` within the skill directory. It has a `Plugins` subdirectory
with XML files in it.

You can find the right plugins to look into by searching in the XML files in the
`PluginHub-SE2/Plugins` folder.
They have `FriendlyName` and `Description` which should be enough to identify what they are about in most cases.
The `DotNetCompat` plugin is special (internal plugin), only use it if you want good examples for preloader patches.

Each XML file corresponds to a plugin registered on the PluginHub-SE2. The `<RepoId>` (or if it is not present
then the `Id`) field will tell you the GitHub repository ID of the plugin. 

## Plugin Storage

Plugin sources are downloaded to `Data/Sources/<PluginName>/` by default.
`Data/` is a junction (Windows) or symlink (Linux) created by the
preparation script that points at the per-user data folder
(`%USERPROFILE%\.se2-dev\plugin\` on Windows, `~/.se2-dev/plugin/` on
Linux), so downloads persist across re-installs and `Clean.bat`/`clean.sh`
runs.

You can override the sources directory by:
1. Setting the `SE_PLUGIN_DOWNLOAD_FOLDER` environment variable
2. Adding `plugin_download_folder: /path/to/folder` to `CLAUDE.md` or `AGENTS.md` in your project

The `download_plugin_source.py` script handles this automatically.

Preparation requires `git` on `PATH`, so plugins are `git clone`d at the
commit recorded in the PluginHub XML and can be updated in place later with
`git pull`. Both the listed and downloaded commit hashes are recorded in
`Data\plugins.json` for later comparison.

## Examples of Finding Plugins

### Example 1: Find Camera-Related Plugins
```bash
$ uv run list_plugins.py --search "camera"
Found 116 plugins (2 matching search 'camera')

[REMOTE] Camera Panning
  ID: avaness/CameraPanning
  Author: avaness

[REMOTE] Free Camera
  ID: carlosmaid/FreeCameraPlus
  Author: carlosmaid

# Download exact name
$ uv run download_plugin_source.py "Camera Panning"
```

### Example 2: Find All Tool-Related Plugins
```bash
$ uv run list_plugins.py --search "tool"
Found 116 plugins (3 matching search 'tool')

[REMOTE] Plugin Name
  ID: author-github-username/PluginName
  Author: Author

# Download the one you want (use EXACT name)
$ uv run download_plugin_source.py "Plugin Name"
```

## Re-indexing

The `download_plugin_source.py` script automatically re-indexes all downloaded plugins. 

If you manually add/remove plugin sources, re-index with:
```bash
uv run index_plugin_code.py
```