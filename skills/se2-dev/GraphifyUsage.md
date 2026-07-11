# Using a Graphify Graph (optional)

> Read this only when a Graphify graph has been built and you want to query it.
> It is optional tooling layered on top of the regular code search, so it stays
> out of context until needed. To build a graph, see
> [GraphifyPrepare.md](GraphifyPrepare.md).

Graphify answers *structural* questions the CSV code index cannot: how symbols connect
(calls, inheritance, references), the shortest relationship path between two symbols,
what a change would impact, and which community (cluster) a symbol belongs to. Use it
alongside — not instead of — the `search_*` code index.

Each subskill graphs its own corpus: `se2-dev-game-code` maps the decompiled game code
under `Data/Decompiled`, `se2-dev-plugin` maps the downloaded plugin sources under
`Data/Sources`.

## Before querying: is the graph healthy?

A graph is only usable once clustering has finished. Check first:

```bash
# Linux, from the subskill folder
bash ../se2-dev/graphify_check.sh Data/Decompiled --deep
```

```bat
REM Windows
call ..\se2-dev\GraphifyCheck.bat Data\Decompiled
```

`OK` means ready. `MISSING`/`INCOMPLETE` means it must be (re)built — see
[GraphifyPrepare.md](GraphifyPrepare.md#health-check-and-rebuild). Confirm the rebuild
cost with the user before rebuilding the large game-code graph; the plugin-sources graph
is small and quick to rebuild.

## Large-graph load cap

Graphify refuses to load a `graph.json` larger than 512 MB by default. The decompiled
game-code graph can approach or exceed that, so every `query`/`explain`/`path`/`affected`
on it may need the cap raised:

```bash
export GRAPHIFY_MAX_GRAPH_BYTES=2GB
```

The plugin-sources graph is far smaller and does not normally hit the cap.

Run graphify from the graph root (`Data/Decompiled` or `Data/Sources`) so it finds
`graphify-out/graph.json` by default, or pass `--graph <path>`.

## Query commands

```bash
cd Data/Decompiled

# BFS traversal answering a natural-language question (default 2000-token budget)
graphify query "How is an entity created and updated?" --budget 400

# Narrow the traversal to one edge context (repeatable): call, inherits, references, ...
graphify query "Entity" --context call --budget 300

# Plain-language explanation of one node and its neighbours (shows its Community)
graphify explain "Entity"

# Shortest relationship path between two symbols
graphify path "Entity" "IEntityContainer"

# Reverse traversal: what depends on / is impacted by a symbol
graphify affected "Entity" --depth 1
```

The same commands work against the plugin-sources graph with plugin symbols instead, e.g.
`graphify query "How does a plugin register a Harmony patch?" --budget 400` or
`graphify explain "Plugin"`. The exact node names there depend on which plugins have been
downloaded into `Data/Sources`.

Node names are matched fuzzily; `path`/`explain` may warn when a name is ambiguous and
pick the best match. If `query` returns *No matching nodes found*, try a different symbol
or a phrasing that mentions a concrete type/method name.

## Verifying a prepared graph

`se2-dev-game-code` ships a query smoke test that runs a representative set of the commands
above (after a health check):

```bash
# Linux
./test_graphify_game_code.sh
```

```bat
REM Windows
.\test_graphify_game_code.bat
```

A healthy run ends with `ALL TESTS COMPLETED`. If it stops at the health check, the graph
is missing or unusable and must be rebuilt.
