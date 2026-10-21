# FAQ

**Which C# version can I use?** C# 14; Pulsar compiles with it. The template sets `LangVersion` to
`latestmajor`.

**Can I use NuGet packages?** Yes, `net10.0` compatible ones, declared in `NuGetReferences`.

**Can I bring data files?** Yes, as assets. Implement `LoadAssets` in your `Plugin` class.

**Is there a server plugin template?** No. SE2 has no dedicated server yet.
