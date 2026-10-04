# Plugin development guide

This guide was made for human plugin developers.

## Start with a template
Click on the green "Use this template" button on GitHub to make your own repo, then clone that repo.

- Client plugin template: https://github.com/CometWorks/client2-plugin-template

**Please follow the `README` after cloning your plugin project locally.** It starts with running `setup.py`, which renames the project to your plugin's name and detects your game installation.

*There is no server plugin template for SE2 yet, since the dedicated server is not available.*

*Good luck!*
### Channels
- Plugin ideas: #🙏🏼｜requests 
- Ask questions here: #📃｜chat
### Documentation
- Harmony patching library: https://harmony.pardeike.net/api/index.html
- Krafs publicizer: https://github.com/krafs/Publicizer

## Build, run and debug your plugin locally
There are two ways to build and debug your client plugin locally:

- **Build from the IDE**. A plain build deploys nothing. Set `Pulsar` in `Directory.Build.props.user` (to `$(APPDATA)\Pulsar`) or pass `-p:Pulsar=...` and the `DeployPlugin` MSBuild target **copies the DLL** into the `%AppData%\Pulsar\Modern\Local` folder after each successful build. A deployed DLL shows up as a separate local plugin; remove it when you are done, or it can shadow the published version later. You can set up run configs to start `%AppData%\Pulsar\Modern.exe` with debugging right from your IDE, which allows you to debug your plugin code and most of the game's code. The template ships such run configs in its `.run` folder. If you plan to debug, then make sure to make a `Debug` build of your plugin. It is recommended to pass the `-skipintro` option to Pulsar for a faster startup.

- **Set up a "dev" folder in Pulsar's Sources dialog** for the plugin. You must pass the `-sources` option to Pulsar to access this dialog. This setup is essential for pre-release testing to make sure Pulsar can also build your plugin, because it may happen that the IDE can build it, but Pulsar fails with an error. You can make Debug or Release builds inside a plugin dev folder. A Debug build should allow your IDE to connect the debugger to the game process started by Pulsar. A Release build allows for testing the exact same build which players will have on their machines when they install your plugin. Once a dev folder is added in the Sources dialog, you can add that dev folder to the regular plugin list (and save in profiles). Make sure to assign the plugin's XML "info" file in the dialog you open by double clicking on your dev folder added to the Plugins list. *(BUG: Currently this association is not saved. There is a PR to fix this.)*

## Release your plugin
- Fill in the fields of the `YourPluginName.xml` file you can find in your project's folder.  (This file came with the plugin template as `ClientPluginTemplate.xml` and was renamed by `setup.py`. If you haven't used the template, then you can find one in the [PluginHub-SE2](https://github.com/StarCpt/PluginHub-SE2/) repository.)
- Fork the [PluginHub-SE2](https://github.com/StarCpt/PluginHub-SE2/) repository and make a PR adding your XML file to the `Plugins` folder, where all the plugins are defined.
- Wait for the PR to be merged. It will involve a human reviewing the source code of your plugin, so please be patient.

Updating your plugin is the same workflow by changing your XML in the [PluginHub-SE2](https://github.com/StarCpt/PluginHub-SE2/).

## Pusar

Pulsar is a plugin loader for Space Engineers.

### Paths 
- Main installation folder: `%AppData%\Pulsar`
- Executable: `%AppData%\Pulsar\Modern.exe`
- Data files: `%AppData%\Pulsar\Modern\`
- Pulsar log file: `%AppData%\Pulsar\Modern\info.log`
### Options

Copy: `-skipintro -nosplash -sources`
- `-skipintro`: Passed on to the game to make it start faster
- `-nosplash`: Passed on to the game to skip the splash window
- `-sources`: Enables access to the **Sources** dialog (developers only)
### Profiles
- Use **Profiles** to save separate `Development`, `Test` and `Production` plugin lists.
  - `Development`: Loads your plugins from DLL files.
  - `Test`: Loads your plugins from "dev" folders. Use before each release.
  - `Production`: Loads your plugins from the publicly visible source (PluginHub-SE2 registered).

You can add your usual plugins made by other developers to all the saved profile above if you wish.

*Backup your profiles regularly. Also, make a copy of each of them with a "Backup" suffix to protect you from mistakenly updating the wrong one.*
### Useful plugins for development
- `Instant Exit`: Makes the game stop faster and cleaner (kills itself), it also prevents instances being stuck in the background.
- TODO: Add more

## FAQ
- *Which C# versions are supported?*
The template sets `LangVersion` to `latestmajor`, so the C# version follows the installed .NET SDK (C# 14 with .NET 10).
- *Can I use NuGet packages?*
Yes. They must be compatible with `net10.0`, which the plugin targets. Declare them in the `NuGetReferences` element of your PluginHub-SE2 registration XML as well, otherwise Pulsar cannot build your plugin on the player's machine.
- *Can I use additional data files?*
Bring them as asset files. Implement the `LoadAssets` method in your `Plugin` class.
- *Where can I find example source code to learn from?*
Please look into the source code of other plugins (all of them are open source on GitHub) to see how the basics work. 
- *I have an older plugin and some software complains that its project file is not in "SDK format"*
If you have an older plugin, then make sure to rebuild it based on the current template, so the project file is in the "SDK format". Using VSCode requires the SDK format. You can build your plugin from the command line using the `dotnet build` command. This also allows for coding agents to rebuild your project and fix errors/warnings automatically without your intervention if you use a "looping workflow" in your prompt.

## Registering a mod to Pulsar

Mods running only on client side (not requiring a server side mod being present) may be registered to Pulsar:

- First, check whether the mod is already present on Pulsar.
- Fork the [PluginHub-SE2](https://github.com/StarCpt/PluginHub-SE2/) and clone it using Git
- Double check whether the mod is already present by searching for the mod's workshop ID in the XML files under `Plugins/Mods`
- Make a new branch from `main`
- Copy `SampleMod.xml` from the repository root into `Plugins/Mods` and rename to match the mod's name
- Carefully fill in the fields of the XML file carefully. You can use the other XML files in that folder as examples
- Commit the new file into your branch and push it
- Open a PR from your branch to add the file to the PluginHub-SE2
- We will review the PR and merge it if the mod is acceptable

The mod will be updated by the game, therefore the XML file does not need to be changed anymore unless you need to fix some field in it.
