# Space Engineers 2 Developer Skills

A [skill](https://agentskills.io) library for Space Engineers 2 plugin development.

**This library applies only to version 2 of the game.**

## Prerequisites

- Space Engineers 2 (on Linux, installed via Steam/Proton)
- .NET 10 SDK (used to install `ilspycmd` as a dotnet tool)
- `git` command line client on `PATH`
- Python 3.13 or newer on `PATH`
  - On Linux this is optional: [`uv`](https://docs.astral.sh/uv/) provides
    the pinned Python 3.13 for the skills' virtual environments automatically, so
    the system Python version does not matter.

Works on **Windows** and **Linux**. On Windows the skills use BusyBox and
NTFS junctions; on Linux they use the native shell and symlinks. `uv` is
installed automatically by the preparation step if missing.

## How to use

You must have a "skills"-compatible agentic coding environment.
See [agentskills.io](https://agentskills.io) or [skills.sh](https://skills.sh) for details.

**After installing the skills, make sure they work and the agent can actually access the files.**

In case of permission issues, you have to grant access to the folder where the skills are stored.
This usually happens if the skills are linked (via `mklink`) into the coding agent's skills folder.

## Installation

The simplest option is to use skills.sh, if you have Node.js installed (which provides `npx` on `PATH`):

`npx skills add CometWorks/skills2`

Follow the wizard. Later you can update them with: `npx skills update`

If you don't want to use `skills.sh`, just copy the skill folders into your coding agent's `skills` folder.

## Preparation

The skills will automatically prepare themselves on **first use**. This involves downloading some tools and indexing code.
If you want to prepare them ahead of time, run the preparation script in their respective folders:
`Prepare.bat` on Windows, or `./prepare.sh` on Linux.

**Note:** Preparing the `se2-dev-game-code` skill may take 10–20 minutes, as it fully decompiles the game and builds
code indexes to allow for rapid code search later. The fully prepared repository takes about **1 GB** of disk space
due to the decompiled source code, the code index and the copied game contents.

## Skills

* [se2-dev-plugin](skills/se2-dev-plugin/SKILL.md) – Plugin development
* [se2-dev-game-code](skills/se2-dev-game-code/SKILL.md) – Searchable decompiled C# game code

More are planned as the game gains modding, scripting, and multiplayer capabilities.

_Enjoy!_

## Want to know more?

- [SE Mods Discord](https://discord.gg/PYPFPGf3Ca) FAQ, Troubleshooting, Support, Bug Reports, Discussion
- [Pulsar Discord](https://discord.gg/z8ZczP2YZY) Everything about plugins

---

## FAQ

### How well does this work for plugin development?

I am currently testing it myself. It looks promising, but there may be rough edges.
Please try it out and report back, or submit a PR!

### How does Claude Code load this much information into the context?

It doesn't! Skills work on the principle of **progressive disclosure**. Claude Code initially sees only the top-level
skill names and descriptions. It then gradually "discovers" more information as needed for the task. It has been given
specific instructions on how to search the SE codebase efficiently, so it doesn't get overwhelmed.

Ideally, it performs research using sub-agents and clears irrelevant data before passing the results back to the parent
agent. Agent hierarchies are a fascinating and fast-evolving topic, definitely worth looking into!

### How much of this was "vibe-coded"?

The code indexing and search scripts were written entirely by Claude Code with zero human intervention, other than
repeated prompting and some extra testing and review. The indexing logic is based on my previous work using
Tree-sitter's C# parser, originally developed for the (now defunct) *Ask Your Code* ChatGPT plugin and GPT.

## Troubleshooting

If you suspect something is not working in these skills, issue the following test prompt in an empty project:

```md
Check whether you can see these skills:
- `se2-dev-plugin`
- `se2-dev-game-code`

If you see them, then make sure they're prepared for first use.

Once they are prepared, conduct some smoke testing on their features to make sure they work.

If something is missing or not working properly, then list those in a final summary.
```

In case of permission issues, you have to grant access to the folder where the skills are stored.
This usually happens if the skills are linked (via `mklink`) into the coding agent's skills folder.

### Example output

Tested with Claude Code and Opus 4.7:

---
Both skills are visible. Let me prepare and smoke-test them.

Python 3.13 is available. Running the one-time plugin preparation.

Both skills are prepared. Now running smoke tests in parallel.

Both skills are working. Summary:

**se2-dev-plugin**:
- `list_plugins.py`: found 1 registry plugin (No Forced Camera Zoom)
- `download_plugin_source.py`: successfully cloned source via git
- `search_plugin_code.py`: found `Plugin.cs` declaration

**se2-dev-game-code**:
- Class declaration search: found `CubeGridComponent` in 3 files
- Method signature search: found `OnAddedToScene` across many components

No issues detected — both skills are ready for use.
---

## Credits

### Patreon Supporters

_in alphabetical order_

#### Admiral level

- BetaMark
- Casinost
- Mordith - Guardians SE
- Robot10
- wafoxxx

#### Captain level

- Diggz
- jiringgot
- Jimbo
- Kam Solastor
- lazul
- Linux123123
- Lotan
- Lurking StarCpt
- NeonDrip
- NeVaR
- opesoorry

#### Testers

- Avaness
- mkaito

### Creators

- Space - Pulsar
- avaness - Plugin Loader (legacy)
- Fred XVI - Racing maps
- Kamikaze - M&M mod
- LTP
- Mordith - Guardians SE
- Mike Dude - Guardians SE
- SwiftyTech - Stargate Dimensions

**Thank you very much for all your support!**

### Legal

Space Engineers 2 is a trademark of Keen Software House s.r.o.
