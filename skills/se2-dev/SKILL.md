---
name: se2-dev
description: High level overview of Space Engineers 2 related development. Start here to understand the ecosystem (game client, Pulsar, PluginHub-SE2) and to route to the right se2-dev-* skill for plugins, mods, and decompiled code/handbook reference.
license: MIT
allowed-tools: Read
---

# SE2 Dev — Space Engineers 2 Development Overview

**Applies only to Space Engineers version 2.**

Entry point and table of contents for `se2-dev-*` skills. Read this first to get the
big picture, then open the specific skill the task needs. Does not perform searches or builds
itself — routes you to the skill that does.

SE2 is in early access and its extension surface is still growing. Today only **plugins**
are a full development target; the rest of this page says what exists now and what does not.

## Ways to extend the game

| Layer | What it is | Runs as | Status | Skill |
|-------|-----------|---------|--------|-------|
| **Plugin** | .NET DLL patching the game with Harmony, loaded by Pulsar | Unsandboxed, full .NET | Available | [`se2-dev-plugin`](../se2-dev-plugin/SKILL.md) |
| **Mod** | Steam Workshop content, loaded by the game | Sandboxed | Evolving; no dedicated skill yet | see [Guide.md](../se2-dev-plugin/Guide.md) |
| **In-game script** | Programmable Block code | — | Not yet in SE2 | — |

Plugins run native code with no sandbox — they can do anything, which is why they are open
source and reviewed before release. Client-side-only workshop mods can be registered to
Pulsar so its registry lists them; that flow is documented in the plugin skill's
[Guide.md](../se2-dev-plugin/Guide.md), not in a separate mod skill.

## Where plugins run

SE2 has no dedicated server and no Torch equivalent yet, so every plugin currently targets
the **game client**.

| | Game client |
|---|---|
| **Loader** | [Pulsar](https://github.com/SpaceGT/Pulsar) (installed via [Pulsar-Installer](https://github.com/StarCpt/Pulsar-Installer)) |
| **Registry** | [PluginHub-SE2](https://github.com/StarCpt/PluginHub-SE2/) |
| **Admin UI** | in-game config dialog |
| **Skill** | `se2-dev-plugin` |

Pulsar lists and loads plugins from PluginHub-SE2 and compiles them from source on the
player's machine, pinned to the GitHub commit the registration names. Server-side plugin
hosting (the SE1 Magnetar/Quasar stack) has no SE2 counterpart yet.

**Do not carry SE1 assumptions over.** The `se-dev-*` skills describe a different game with a
different API surface; SE1 plugins are not SE2 plugins.

## Skill map

### Authoring skills (write plugins)
- **[se2-dev-plugin](../se2-dev-plugin/SKILL.md)** — Plugin development (Harmony patching, transpilers, preloader, publicizer). Search plugin source downloaded from PluginHub-SE2, and review submissions to it.

### Reference skills (read/search the game internals)
- **[se2-dev-game-code](../se2-dev-game-code/SKILL.md)** — Search the decompiled C# (and IL) of the game client, plus its textual `Content`. Recommended companion for any plugin work.

The `se2-dev-game-book` handbook — AI-generated summaries of game types organised by
inheritance hierarchy — is **private/internal**, distributed separately and not part of this
public repository. Use it if it is installed; otherwise fall back to `se2-dev-game-code`.

### Graphify graphs (read on demand)
- **[GraphifyPrepare.md](GraphifyPrepare.md)** — how each subskill builds its own per-subskill `graphify-out/`. Prepare installs Graphify on **Python 3.12 with the fast native Rust Leiden clustering backend** and, when that backend is available (Linux/Windows with `uv`), builds the graph **automatically** — clustering then takes ~1-2 minutes even for the decompiled game corpus. Where the fast backend cannot be provisioned, Graphify stays **optional** and only builds on opt-in with `SE2_DEV_GRAPHIFY=1` (the slow single-core fallback adds ~10-30 minutes on the game corpus; small corpora stay quick). `SE2_DEV_GRAPHIFY=0` disables it entirely. Also covers the health check that detects an unusable (unclustered) graph and the clean-and-rebuild flow.
- **[GraphifyUsage.md](GraphifyUsage.md)** — how to query an existing graph (`query`/`explain`/`path`/`affected`), the large-graph load cap, and the query test scripts.

These two docs are fetched **on demand**: skip them entirely unless the user specifically
wants the Graphify graph, so the extra tooling never pollutes context during normal work.

## How to pick

- **Writing or fixing a plugin?** → `se2-dev-plugin` + `se2-dev-game-code` (and `se2-dev-game-book` for orientation).
- **Reviewing a PluginHub-SE2 submission?** → `se2-dev-plugin`, following its `Review.md`.
- **Need to understand how the game does X?** → `se2-dev-game-code` to search the source, `se2-dev-game-book` for orientation.
- **Registering a client-side mod to Pulsar?** → `se2-dev-plugin`, following its `Guide.md`.

Most non-trivial tasks pair the **authoring** skill with a **reference** skill: write with one,
look up the game's internals with the other.

## Plugin template

- [client2-plugin-template](https://github.com/CometWorks/client2-plugin-template) — client plugin. Follow its `README` after cloning.

## Remarks

Original source of these skills: https://github.com/CometWorks/skills2
