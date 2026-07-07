# Prepare-Time Graphify Graph

> Read this only when the user wants the Graphify graph. It is not needed for
> normal plugin-development or code-search work, so it stays out of context until
> it is actually relevant. For querying an existing graph see
> [GraphifyUsage.md](GraphifyUsage.md).

The `prepare.sh` / `Prepare.bat` script can build a [Graphify](https://pypi.org/project/graphifyy/)
graph for the downloaded plugin sources under `Data/Sources`. The graph is a navigable map
(call/inherit/reference edges plus LLM-named communities) beside the regular search indexes.
Because the downloaded-sources corpus is small, the graph is quick to build either way.

## Fast clustering vs. the slow fallback

Building a graph is cheap **except for clustering** (community detection). Graphify has two
clustering backends:

- **Fast — native Rust Leiden** (`graspologic`, which needs **Python < 3.13**; we use 3.12).
- **Slow — pure-Python Louvain fallback**, used automatically when `graspologic` is not
  importable (e.g. Graphify installed on Python 3.13, where `graspologic` has no wheel). It
  is single-core; on the small plugin-sources corpus it still finishes in seconds to a
  couple of minutes (the ~10-30 minute figure only applies to a large corpus like the
  decompiled game code).

The skill's own `.venv` stays on Python 3.13; this Python 3.12 pin applies only to the
separately-installed `graphify` tool. Prepare defaults that tool to **Python 3.12 with the
`leiden` extra** and picks its behaviour from which backend is available:

- **Fast backend available** (Linux/Windows with `uv`): prepare **provisions it and builds
  the graph automatically** — no opt-in needed. Because `uv` can fetch Python 3.12 and the
  `graspologic` wheels on demand, this is the normal case.
- **Fast backend cannot be provisioned** (no `uv`, no Python 3.12, or `graspologic` will
  not import): Graphify stays **optional and off**. Build it by opting in with
  `SE2_DEV_GRAPHIFY=1` (for this small corpus the slow fallback is still quick).

`SE2_DEV_GRAPHIFY` is a tri-state override:

| Value | Effect |
|-------|--------|
| unset | **auto** — build when the fast Rust backend is available, skip otherwise |
| `1`   | **always build**, even on the slow single-core fallback |
| `0`   | **never build** — disable Graphify entirely |

The one-time provisioning of the fast backend (uv fetching Python 3.12 + `graspologic`)
takes ~30-60 seconds and is logged. To pin a different interpreter, set
`SE2_DEV_GRAPHIFY_PYTHON` (default `3.12`); it must be `< 3.13` for the fast backend.

## Installation

Prepare installs Graphify automatically through `uv` when the fast backend is available. To
install it manually, use the **fast** form (Python 3.12 + `leiden` extra):

```bash
# Recommended; uv fetches Python 3.12 and puts graphify on PATH automatically
uv tool install --python 3.12 'graphifyy[leiden]'

# Alternatives (the leiden extra is only fast on Python 3.12)
pipx install --python python3.12 'graphifyy[leiden]'
pip install 'graphifyy[leiden]'          # run under a Python 3.12 interpreter

# Then install Graphify integration for the active AI platform
graphify install --platform [AI PLATFORM]
```

Set `SE2_DEV_GRAPHIFY_PLATFORM` before prepare to run the platform install automatically
after the package is installed.

## Graph root

Prepare builds the graph under the graph root's own `graphify-out/` directory:

| Default graph root | Override |
|--------------------|----------|
| downloaded plugin sources (`Data/Sources`) | `SE2_DEV_PLUGIN_PROJECT_ROOT` |

Use the override variable when the skill should graph a specific active plugin project
instead of the downloaded sources.

## Build time

- **First-ever install on a machine**: a one-time ~30-60 second provisioning (Graphify
  plus Python 3.12, the Rust `graspologic` clustering backend, tree-sitter and numpy).
- **First graph build** (`graphify <root>`): seconds to ~1 minute for typical downloaded
  sources, either backend.
- **Later runs** (`graphify <root> --update`): incremental re-extraction of changed code
  files only; no LLM needed.

## Health check and rebuild

A graph is only usable once **clustering** finishes. Clustering writes
`graphify-out/.graphify_analysis.json`; without it every node has an empty community. A
build that is killed part-way leaves a `graph.json` with no clustering — an **incomplete,
unusable** graph. Prepare guards against this: it inspects an existing graph and, if it
finds `graph.json` but no clustering, it **cleans `graphify-out/` and rebuilds from scratch**
rather than `--update`-ing a broken graph.

To check a graph's health independently, run the standalone checker:

```bash
# Linux (from the skill folder)
bash graphify_check.sh Data/Sources          # fast: file presence
bash graphify_check.sh Data/Sources --deep   # also validates clustering content
```

```bat
REM Windows
call GraphifyCheck.bat Data\Sources
```

Exit codes: `0` ok, `2` missing (never built), `3` incomplete (must be rebuilt). If it
reports `incomplete` or `missing` and you want the graph, delete `graphify-out/` and re-run
prepare — it rebuilds automatically with the fast Rust backend, or on opt-in
(`SE2_DEV_GRAPHIFY=1`) with the slow fallback (still quick for this small corpus).

## Corpus content and API keys

Graphify builds a **code-only** graph with no API key. It treats `.md`, `.txt`, `.rst`,
`.yaml`, `.yml`, `.html` and similar files as *documents* that need LLM-based semantic
extraction, and the build fails if any are present and no key (`ANTHROPIC_API_KEY`,
`GEMINI_API_KEY`, …) is set. Plugin repositories frequently ship a `README.md` and other
docs, so to graph only the code without a key add a `.graphifyignore` (gitignore syntax) at
`Data/Sources/` excluding the doc extensions.

## Failure behavior

Graphify is supplemental. Prepare logs a warning and continues if:

- Graphify is disabled (`SE2_DEV_GRAPHIFY=0`),
- the fast backend is unavailable and the user did not opt in (`SE2_DEV_GRAPHIFY` not `1`),
- the user declines installation on the slow-fallback path,
- `graphify` is not on `PATH` after installation,
- the selected graph root does not exist (e.g. no plugin sources downloaded yet),
- graph creation or update fails.

Core preparation (registry download and indexing) still succeeds regardless.
