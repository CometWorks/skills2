# Learn the game's internals

SE2 is in early access and Keen documents little of its code, so you read the code itself.

- **Decompiled game code.** The [`se2-dev-game-code`](../se2-dev-game-code/SKILL.md) skill decompiles the game
  with ILSpy, copies its text content and indexes both for search. Run `Prepare.bat` (Windows) or `prepare.sh`
  (Linux) in the skill's folder, or let the agent prepare it on first use. After a game update it decompiles
  again. Without the skill, open the DLLs in the game's `Game2` folder with
  [ILSpy](https://github.com/icsharpcode/ILSpy), dnSpyEx or Rider's decompiler.
- **Handbook.** `se2-dev-game-book` explains how the game works, by subsystem. It is distributed separately;
  if installed, read it before searching the code. The code wins where the two disagree.
- **Other plugins.** Every plugin on PluginHub-SE2 is open source. Find similar ones in the
  [plugin list](https://cometworks.github.io/plugins/se2/) and read how they do it. The
  [`se2-dev-plugin`](../se2-dev-plugin/SKILL.md) skill downloads and indexes them for search
  ([OtherPluginsAsExamples.md](../se2-dev-plugin/OtherPluginsAsExamples.md)).
- **Not SE1.** Many type names look familiar, but the engine changed. Check every SE1 habit against the SE2
  code.

**Never publish decompiled game code**, not in a repository, an issue or a pull request. It stays on the
developer's machine; it is Keen's property.
