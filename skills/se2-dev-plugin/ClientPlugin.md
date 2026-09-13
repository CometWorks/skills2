Starting a new plugin project:
- Use the [client plugin template](https://github.com/CometWorks/client2-plugin-template) ("Use this template" on GitHub), then clone your new repository.
- Run `setup.py` (requires Python 3.12 or newer) once after cloning. It asks for the plugin name in `CapitalizedWords` format, renames the solution and the PluginHub registration XML, replaces the project GUIDs and detects the game's installation folder.
- Follow the `TODO` comments in the source files, then fill in the registration XML for the PluginHub-SE2 submission.

Building the project:
- In production the plugin is built by the Pulsar plugin loader directly on the player's machine.
- In development the plugin is built either of these ways:
  - By the `dotnet` command line tool or by an IDE like VSCode, JetBrains Rider or Visual Studio. The `DeployPlugin` MSBuild target in `ClientPlugin/ClientPlugin.csproj` copies the built DLL into Pulsar's `Local` plugin folder after each successful build. There is no separate deployment script.
  - By Pulsar using the local development folder feature (needs to be configured in Pulsar, requires the `-sources` option).
- The project targets `net10.0` and references the game assemblies directly from the game's `Game2` folder. It uses `Lib.Harmony` and `Mono.Cecil`. The Krafs publicizer is included, but commented out, see [Publicizer.md](Publicizer.md).
- Stop the game before building, otherwise the running game locks the deployed DLL and the copy fails.

Build configuration (`Directory.Build.props` in the repository root):
- `Game2`: Folder containing `SpaceEngineers2.exe`, defaults to the Steam installation.
- `Pulsar`: Folder containing Pulsar's data, defaults to `%AppData%\Pulsar` on Windows and `~/.config/Pulsar` on Linux.
- `LocalDeploymentDir`: Deployment target of the built DLL, defaults to `$(Pulsar)/Modern/Local`. (`Modern` is Pulsar's SE2 target, `Legacy` and `Interim` are for SE1.)
- `Version`: The plugin's version, change it here at a single place.

Example patches:
- `Examples/Client/ExamplePrefixPostfixPatch.cs` Prefix and Postfix patches
- `Examples/Client/ExampleTranspilerPatch.cs` Transpiler patch
- `Examples/Client/ExamplePrepatch.cs` Preloader (pre-JIT) patch, disabled by an `#if` in the template

Folder structure of a client-only plugin:
- `.run`: JetBrains Rider run configurations (for convenience)
- `Docs`: Images linked from the README file or any further documentation should go here.
- `ClientPlugin`: Pulsar builds only the source code under this folder or its subdirectories, as declared in the `SourceDirectories` element of the registration XML. It contains the plugin's entry point (`Plugin.cs`), its configuration (`Config.cs`) and the preloader registration (`Preloader.cs`, disabled by an `#if` until you need it).
- `ClientPlugin/Settings`: Reusable, attribute driven configuration dialog components. See `ClientPlugin/Settings/Settings.md` for the reference of the available elements and `ClientPlugin/Config.cs` for usage examples.
- `ClientPlugin/Tools`: Utility code for configuration storage, game access, hashing, transpiler and preloader patches, and the publicizer.
- `ClientPlugin/Patches`: Use this folder and namespace to host the Harmony patches.

Files in the repository root:
- `<PluginName>.sln`: Solution file, renamed by `setup.py`
- `<PluginName>.xml`: PluginHub-SE2 registration, renamed by `setup.py`, fill it in before submitting
  - The `<Description>` element is shown in Pulsar's Plugin Details panel, which wraps the text to the panel's width. Indent it along with the surrounding XML: Pulsar left-shifts the text, so the common leading whitespace of the block is not shown. Keep each paragraph on a single line with blank lines between paragraphs, because hard wrapped lines get re-wrapped and render ragged.
- `Directory.Build.props`: Paths, deployment folder and plugin version (see above)
- `setup.py`: One time project setup, see above
- `clean.bat` / `clean.sh`: Remove the `bin` and `obj` folders
- `AGENTS.md`: Instructions for coding agents working on the plugin

References:
- [Client plugin template](https://github.com/CometWorks/client2-plugin-template) Template repository to start a new project.
