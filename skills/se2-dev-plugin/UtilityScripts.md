Catalog of utility scripts:

- `uv run list_plugins.py [--local|--remote] [--search TERM] [--json] [-v]` - List the plugins registered in PluginHub-SE2 (see the [search action](actions/search.md))
- `uv run download_pluginhub.py` - Clone or refresh the PluginHub-SE2 registry in `Data/PluginHub-SE2`
- `uv run download_plugin_source.py <name_or_id>` - Clone a plugin's source at its registered commit, then re-index
- `uv run index_plugin_code.py` - Rebuild the code index of the downloaded plugin sources
- `uv run search_plugin_code.py [options] <category> <symbol_type> <patterns...>` - Search the code index (run with no args for full help)
- `hierarchy_tree.py` - Helper module for generating hierarchy tree text files (used by the indexer)
