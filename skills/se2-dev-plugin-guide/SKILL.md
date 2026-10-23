---
name: se2-dev-plugin-guide
description: Developer guide for Space Engineers 2 plugins - starting from the client plugin template, where to learn the game's internals, patching basics, testing locally with Pulsar's Modern flavor, how players' PCs differ, filling the hub manifest XML, submitting to PluginHub-SE2, and developing with AI coding agents. Use it to answer a plugin developer's process questions or to take a plugin from template to hub release.
license: MIT
allowed-tools: Read
---

# SE2 Plugin Developer Guide

**Applies only to Space Engineers version 2.** For SE1 use the `se-dev-plugin-guide` skill from
[CometWorks/skills](https://github.com/CometWorks/skills).

The workflow around a plugin: start, test, publish, maintain. Written for human developers; agents use it to
answer their questions or to do the steps for them. The same text is on the web at
https://cometworks.github.io/plugin-dev/se2/. Writing the plugin's code is the job of
[`se2-dev-plugin`](../se2-dev-plugin/SKILL.md) (patching handbook, search in other plugins) and
[`se2-dev-game-code`](../se2-dev-game-code/SKILL.md) (the game's code).

## Topics

Read only the page the question needs:

| Question | Page |
|---|---|
| The template, how to start a project | [Templates.md](Templates.md) |
| Where to learn how the game works inside | [GameInternals.md](GameInternals.md) |
| Harmony, transpilers, preloader, publicizer: the basics | [PatchingBasics.md](PatchingBasics.md) |
| Pulsar paths and options, dev folders, DLL deploy, profiles, debugging, Linux | [LocalTesting.md](LocalTesting.md) |
| Why it works locally but fails for players | [LocalVsPlayers.md](LocalVsPlayers.md) |
| The hub manifest XML, field by field | [Manifest.md](Manifest.md) |
| Submitting to PluginHub-SE2, updates, registering a Workshop mod | [Submitting.md](Submitting.md) |
| Using coding agents and these skills | [AiAgents.md](AiAgents.md) |
| C# version, NuGet, data files, server plugins | [FAQ.md](FAQ.md) |

## Key facts

- One template: [client2-plugin-template](https://github.com/CometWorks/client2-plugin-template). SE2 has no
  dedicated server yet, so every plugin is a client plugin.
- Loaded by [Pulsar](https://github.com/SpaceGT/Pulsar) 2.2.0 or newer through `Modern.exe` (`Modern.bin` on
  Linux), listed on [PluginHub-SE2](https://github.com/StarCpt/PluginHub-SE2).
- Players' PCs compile the plugin from its GitHub source at the manifest's `Commit`, with Roslyn and no
  MSBuild. Test the Release build through a Pulsar development folder before every release.
- Never publish decompiled game code.
- Questions the guide doesn't answer: the [Pulsar Discord](https://discord.gg/z8ZczP2YZY).

## Remarks

Original source of this skill: https://github.com/CometWorks/skills2
