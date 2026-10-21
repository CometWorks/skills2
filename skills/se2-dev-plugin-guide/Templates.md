# Start from the template

There is one template: [client2-plugin-template](https://github.com/CometWorks/client2-plugin-template).

Prerequisites: Space Engineers 2, [Pulsar](https://github.com/SpaceGT/Pulsar), the .NET 10 SDK and Python 3.12
or newer. Windows and Linux both work.

1. On GitHub click **Use this template** and create your repository, then clone it.
2. Run `setup.py` and give the plugin's name in `CapitalizedWords` form. It renames the project and files,
   generates the manifest's `Id` and writes the detected `Game2` folder into `Directory.Build.props.user`,
   which is not committed.
3. Open the solution in Visual Studio, Rider or VS Code and build it once.
4. Load it into the game as a development folder (see [Test your plugin locally](LocalTesting.md)) and check
   that the empty plugin can be enabled.
5. Replace the README with your plugin's description and follow the `TODO` comments in the code.

Read the template's README: it covers the settings dialog generator, debugging, the publicizer and preloader
patches. The plugin targets `net10.0`; its version is in `Version.Build.props`.

The `Plugin` class implements `Keen.VRage.Core.Plugins.IPlugin`. SE2 has no `Init` or `Update` calls like SE1:
the constructor does the setup and applies the Harmony patches, and `OpenConfigDialog()` opens the settings
screen when the player clicks the plugin's config button.
