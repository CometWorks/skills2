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

Use the plugin name, `RepoId` or `Id` as shown in the list output. Matching is case-insensitive;
a partial term works when it matches exactly one plugin, otherwise the script lists the candidates.

```bash
uv run download_plugin_source.py "No Forced Camera Zoom"               # FriendlyName
uv run download_plugin_source.py WesternSpace/SE2-NoForcedCameraZoom   # RepoId
uv run download_plugin_source.py SE2-NoForcedCameraZoom                # repo name
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
The hidden `linux-compat` plugin (`CometWorks/linux-compat2`) is special (internal plugin), only use it if you want good examples for preloader patches.

Each XML file corresponds to a plugin registered on the PluginHub-SE2. The `<RepoId>` (or if it is not present
then the `Id`) field will tell you the GitHub repository ID of the plugin. 

## Plugin Storage

Plugin sources are downloaded to `Data/Sources/<RepoName>/` by default.
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
commit recorded in the PluginHub XML; re-running `download_plugin_source.py`
re-clones a plugin when that commit changes. Both the listed and downloaded commit hashes are recorded in
`Data\plugins.json` for later comparison.

## Examples of Finding Plugins

### Example 1: Find Camera-Related Plugins
```bash
$ uv run list_plugins.py --search "camera"
Found 1 plugins (0 available locally)

[REMOTE] No Forced Camera Zoom
  ID: DA18B71F-9B46-42E9-BDCD-841CCC571E2A
  RepoId: WesternSpace/SE2-NoForcedCameraZoom
  Author: WesternSpace
  Commit (registered): 508fa9bbd782

$ uv run download_plugin_source.py "No Forced Camera Zoom"
```

### Example 2: Several Matches
```bash
$ uv run list_plugins.py --search "hdr"
Found 2 plugins (0 available locally)

[REMOTE] HDR Render 2
  ID: 109CBF17-F8C8-49C6-AC39-8EA58910A631
  RepoId: lolifamily/HdrRender2
  Author: lolifamily
  Commit (registered): 293e268e4d93

[REMOTE] Tonemapping + HDR
  ID: F03809A6-80F0-472C-B8FA-5A40FE3AB9DC
  RepoId: matelemons/SE2_HDR
  Author: Matelemons
  Commit (registered): 735c7772e385

# "hdr" alone matches both, so name the one you want
$ uv run download_plugin_source.py "HDR Render 2"
```

## Re-indexing

The `download_plugin_source.py` script automatically re-indexes all downloaded plugins. 

If you manually add/remove plugin sources, re-index with:
```bash
uv run index_plugin_code.py
```