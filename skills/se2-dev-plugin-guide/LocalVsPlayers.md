# Local runs vs. the players' PCs

When a player enables your plugin, Pulsar downloads your repository at the commit named in the hub manifest
and compiles it on their machine. That build differs from yours:

- **No MSBuild.** Your `.csproj`, `Directory.Build.props`, build events, resources, analyzers, source
  generators and implicit global usings are ignored. Pulsar compiles the `.cs` files under
  `SourceDirectories` with Roslyn as C# 14, in Release mode.
- **Committed files only.** Untracked files that a development folder picks up are missing on GitHub. Commit
  everything before you put the commit hash into the manifest.
- **Fixed references.** The game's `SpaceEngineers2.dll`, `VRage*.dll` and `Game2*.dll` plus Harmony,
  Newtonsoft.Json, Mono.Cecil, NLog, DiscordRPC and Microsoft.CSharp, and WinForms/WPF only on Windows.
  Anything else must come from `NuGetReferences` or an `Asset` in the manifest.
- **Different symbols.** Pulsar defines `PULSAR`, `TRACE`, `NETCOREAPP`, and `LINUX` on Linux. `DEBUG` and the
  template's `DEV_BUILD` are not defined.
- **Random assembly name.** Don't rely on `Assembly.GetName().Name` or the DLL's path.
- **Windows and Linux.** Players run both. Avoid Windows-only APIs, or restrict the plugin with `Platforms`.
- **No extra files.** Only compiled code arrives. Ship data files as assets and load them in `LoadAssets`.
  Keep settings in the folder Pulsar gives you through `GetConfigPath`, as the template does.
- **Other plugins.** Players combine your plugin with others that may patch the same methods.

Pulsar caches the compiled plugin and rebuilds it after a Pulsar or game update. Compile errors on a player's
machine end up in their `info.log`.
