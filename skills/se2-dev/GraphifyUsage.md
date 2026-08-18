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
bash ../se2-dev/graphify_check.sh Data --deep
```

```bat
REM Windows
call ..\se2-dev\GraphifyCheck.bat Data
```

The argument is the directory that *contains* `graphify-out/`. For `se2-dev-game-code`
that is `Data` (it graphs `Data/Decompiled` but stores the graph beside it);
`se2-dev-plugin` keeps the graph inside the graphed tree, so pass `Data/Sources`.

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

Run graphify from the directory holding `graphify-out/` (`Data` for
`se2-dev-game-code`, `Data/Sources` for `se2-dev-plugin`) so it finds
`graphify-out/graph.json` by default, or pass `--graph <path>`.

## Query commands

```bash
cd Data

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

## Name resolution pitfalls

Fuzzy matching can settle on a **stub node** - a name that appears in some other file's
extraction, carrying no source location and a single edge. It looks like a successful
answer but tells you nothing. Always check the `Source:` line:

```
Node: Entity
  ID:        game2_simulation_..._somefile_cs_entity
  Source:                  <-- empty: this is a stub, not the real Entity
  Degree:    1
```

A real hit has a populated `Source:` (a file path plus a line number) and a degree in the
dozens or hundreds. When you land on a stub:

- retry with a more distinctive name (`CubeGridComponent` rather than `Entity`), or
- look the symbol up with the code index first (`search_game_code.py class declaration ...`)
  and use the exact declared name.

An `ambiguous match` warning on `path` means the same - verify the endpoints resolved to
the symbols you meant before trusting the path.

## What the graph is good and bad at

- `explain`, `path` and `affected` on a **named symbol** are the reliable modes; they
  answer questions the CSV index cannot (how symbols connect, impact of a change).
- `query` with a **natural-language question** spends much of its token budget on hub
  nodes (`System`, `Vector3`, `Entity`, ...) that everything references. Prefer naming
  a concrete type, keep `--budget` small and follow up with `explain` on what looks
  relevant.
- `--context call` is sparse on the decompiled tree: most extracted edges are
  `references`, `inherits` and `implements`, so narrowing to `call` often returns almost
  nothing. Drop the filter, or use `affected` instead.

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

Every check asserts its outcome, so the exit code is authoritative: 0 with a final
`ALL TESTS COMPLETED` banner means all queries answered, 1 with a `TESTS FAILED` banner
lists what failed. If it stops at the health check, the graph is missing or unusable and
must be rebuilt.
