# Develop with AI coding agents

Coding agents such as Claude Code work well on plugins when they have the right context.

- **Install the skills.** `npx skills add CometWorks/skills2` installs the
  [SE2 developer skills](https://github.com/CometWorks/skills2): `se2-dev` (start here), `se2-dev-plugin`
  (patching handbook, search in other plugins' code), `se2-dev-game-code` (decompiled code search),
  `se2-dev-plugin-review` (hub review) and `se2-dev-plugin-guide` (this guide). Prepare them once, or let the
  agent do it on first use. Don't mix in the SE1 skills: they describe a different game.
- **Use the template's `AGENTS.md`.** It points the agent to the skills.
- **Let the agent build.** `dotnet build` lets it build, read the errors and fix them in a loop. Ask it to
  read the game code it patches before it writes the patch.
- **Give it the evidence.** Point it at `Modern/info.log` and the game's log when something fails.
- **Test in the game yourself.** Do the Release test from [Test your plugin locally](LocalTesting.md) before
  every release.
- **Review before you submit.** Ask the agent to check your code against the review policy of the
  `se2-dev-plugin-review` skill
  ([ReviewPolicy.md](../se2-dev-plugin-review/ReviewPolicy.md)), the one hub reviewers use, before you open the hub pull request.
- **Don't publish decompiled code**, not even in an issue or a pull request.

## When you are the agent

- Start from [`se2-dev`](../se2-dev/SKILL.md) for the skill map, then read the project's `AGENTS.md` and
  `README.md`. Don't apply SE1 knowledge without checking it against the SE2 code.
- Read the game code you patch before you write the patch ([`se2-dev-game-code`](../se2-dev-game-code/SKILL.md)).
- Build with `dotnet build` and fix every error and warning you introduced. A green build is not the release
  check: Pulsar compiles differently ([LocalVsPlayers.md](LocalVsPlayers.md)).
- Keep the manifest in step with the code: new source folders go into `SourceDirectories`, every NuGet package
  in the `.csproj` also goes into `NuGetReferences`, data files become `Asset` entries ([Manifest.md](Manifest.md)).
- Code under `#if DEBUG` or `#if DEV_BUILD` doesn't exist in the players' build.
- You can't run the game. Ask the developer to do the in-game Release test ([LocalTesting.md](LocalTesting.md))
  and to give you `Modern/info.log` and the game log when something fails.
- Put the commit hash into the manifest only after that commit is pushed to the public repository.
- Never commit, paste or quote decompiled game code outside the developer's machine.
