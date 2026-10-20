# Test your plugin locally

## Pulsar's files

Pulsar installs into `%AppData%\Pulsar` on Windows and `~/.config/Pulsar` on Linux. SE2 uses the `Modern`
data folder there: Pulsar's log is `Modern/info.log`, profiles are in `Modern/Profiles`, the compiled plugin
cache is in `Modern/GitHub` and `Modern/DevFolder`. A Pulsar update wipes the install folder except the data
folders, so keep nothing else there.

Useful command-line options:

- `-sources` shows the **Sources** button, which developers need.
- `-noSplash` skips the splash window; Pulsar skips the intro by default.
- `-profile <name>` starts with a given profile; `-safeMode` starts with all user plugins disabled.
- `-debug` launches the debugger at startup; `-debugCompileAll` compiles every plugin and lists the ones that
  fail.

## Way 1: a development folder (recommended)

Pulsar compiles your working copy from source, just as it compiles hub plugins on the players' PCs.

1. Start `Modern` with `-sources` and open **Sources**.
2. Add a development folder: your repository's folder.
3. Select the plugin's manifest XML (the one the template ships, renamed by `setup.py`). Pulsar takes the name,
   `SourceDirectories`, NuGet packages, assets and dependencies from it.
4. Enable the new entry in the plugin list. The **Debug Build** checkbox picks the build mode.

A Debug build has symbols with embedded source: attach your IDE's debugger to the game process and set
breakpoints in your plugin and in the game. A Release build is exactly what players get. New dev folders
build in Debug, so switch to Release before your final test.

Pulsar compiles only the `.cs` files, tracked and untracked but not ignored, under `SourceDirectories`. It
never runs MSBuild, so a project that builds in the IDE can still fail here. That is why this test matters.

## Way 2: deploy the DLL from the IDE

Builds deploy nothing by default. Set `Pulsar` in `Directory.Build.props.user` (`$(APPDATA)\Pulsar` on
Windows, `$(HOME)/.config/Pulsar` on Linux) or pass `-p:Pulsar=...` to `dotnet build`, and each build copies
the DLL into `Modern/Local`. The template's `.run` folder has Rider run configurations that start `Modern`
for debugging.

The deployed DLL shows up as a separate local plugin. Remove it when you are done: if it stays enabled it
hides the published version. Stop the game before building, or the old DLL is locked.

## Profiles

Save separate plugin lists as profiles: **Development** (your DLL), **Test** (your development folder, in
Release mode, before each release) and **Production** (your plugin from the hub, as players have it). Back
them up, and keep a copy of each with a `Backup` suffix in case you save over the wrong one.

## Linux

Pulsar's Linux build runs SE2 natively, without Wine or Proton, through the Linux Compat plugin it loads
automatically. Building, deploying and debugging work as on Windows.
