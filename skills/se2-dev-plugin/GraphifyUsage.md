# Using a Graphify Graph (optional)

> Read this only when a Graphify graph has been built and you want to query it.
> It is optional tooling layered on top of the regular code search, so it stays
> out of context until needed. To build a graph, see
> [GraphifyPrepare.md](GraphifyPrepare.md).

Graphify answers *structural* questions the CSV code index cannot: how symbols connect
(calls, inheritance, references), the shortest relationship path between two symbols,
what a change would impact, and which community (cluster) a symbol belongs to. Here it maps
the **downloaded plugin sources** under `Data/Sources`. Use it alongside — not instead of —
the `search_plugin_code.py` code index.

## Before querying: is the graph healthy?

A graph is only usable once clustering has finished. Check first:

```bash
# Linux, from the skill folder
bash graphify_check.sh Data/Sources --deep
```

```bat
REM Windows
call GraphifyCheck.bat Data\Sources
```

`OK` means ready. `MISSING`/`INCOMPLETE` means it must be (re)built — see
[GraphifyPrepare.md](GraphifyPrepare.md#health-check-and-rebuild). The plugin sources corpus
is small, so rebuilding is quick.

## Query commands

Run graphify from the graph root (`Data/Sources`) so it finds `graphify-out/graph.json`
by default, or pass `--graph <path>`.

```bash
cd Data/Sources

# BFS traversal answering a natural-language question (default 2000-token budget)
graphify query "How does a plugin register a Harmony patch?" --budget 400

# Narrow the traversal to one edge context (repeatable): call, inherits, references, ...
graphify query "Plugin" --context call --budget 300

# Plain-language explanation of one node and its neighbours (shows its Community)
graphify explain "Plugin"

# Shortest relationship path between two symbols
graphify path "Plugin" "IPlugin"

# Reverse traversal: what depends on / is impacted by a symbol
graphify affected "Plugin" --depth 1
```

Node names are matched fuzzily; `path`/`explain` may warn when a name is ambiguous and
pick the best match. If `query` returns *No matching nodes found*, try a different symbol
or a phrasing that mentions a concrete type/method name. The exact node names depend on
which plugins you have downloaded into `Data/Sources`.

Because this corpus is small, the default 512 MB load cap is not usually a concern; if a
very large set of sources pushes past it, raise `GRAPHIFY_MAX_GRAPH_BYTES` (e.g. `2GB`).
