# Fill the manifest XML

The manifest tells PluginHub-SE2 and Pulsar where your code is and how to build it. The template ships it in
the repository root as `ClientPluginTemplate.xml`, renamed by `setup.py`.

```xml
<?xml version="1.0"?>
<PluginData xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="GitHubPlugin">
    <Id>3F2B9C1E-0D4A-4E57-9B8C-6A1F2E3D4C5B</Id>
    <RepoId>your-github-user/your-plugin</RepoId>
    <FriendlyName>Your Plugin</FriendlyName>
    <Author>Your Name</Author>
    <Tooltip>One line shown in the plugin list.</Tooltip>
    <Description>
        What the plugin does, how to use it and where to report bugs.

        Players can click links here, for example a Discord invite.
    </Description>
    <SourceDirectories>
        <Directory>ClientPlugin</Directory>
    </SourceDirectories>
    <Commit>0123456789abcdef0123456789abcdef01234567</Commit>
</PluginData>
```

| Element | Required | Meaning |
|---|---|---|
| `Id` | yes | Permanent identifier, a GUID from `setup.py`. Profiles and other plugins refer to it: never change it. |
| `RepoId` | yes | The GitHub repository as `owner/repo`. |
| `FriendlyName` | yes | Name in the plugin list. |
| `Author` | yes | Author shown in the list. |
| `Tooltip` | no | One-line summary in the list. |
| `Description` | no | Text of the details panel, up to 1000 characters. Indent it with the XML (the common indentation is removed), keep each paragraph on one line and separate paragraphs with a blank line. |
| `Commit` | yes | Full commit hash of the release, lowercase. Pulsar downloads and compiles exactly this commit. |
| `SourceDirectories` | no | Folders whose `.cs` files are compiled (case-sensitive). Without it every `.cs` file in the repository is compiled. |
| `NuGetReferences` | no | `<PackageReference Include="Name" Version="1.2.3" />` for each package; they must support `net10.0`. Your `.csproj` references are not used. Don't add Harmony. |
| `Asset` | no | Files to put on disk: `<Asset Name="AssetFolder" Path="ClientPlugin/Assets/" />` copies a folder from the repository and makes Pulsar call your plugin's `LoadAssets(string folder)`. `Url` downloads a file (give its `Sha256`), `Extract="true"` unpacks an archive, `Placement="Bin"` puts it next to the DLL, `Reference="true"` compiles against a downloaded DLL. |
| `DependencyIds` | no | `<Id>` of plugins that are enabled together with yours. |
| `GroupId` | no | Plugins sharing it are mutually exclusive: enabling one disables the others. |
| `Platforms` | no | `Windows`, `Linux`, comma separated. Empty means everywhere. |
| `Hidden` | no | `true` hides the plugin from the list unless it is enabled or searched for. For dependency-only or abandoned plugins. |
| `AlternateVersions` | no | Extra `<Version>` entries with a `Name` and a `Commit` that players can pick, for test builds. |
