# Patching basics

Plugins change the game by patching its methods at runtime with [Harmony](https://harmony.pardeike.net/api/index.html).

- Prefer **prefix** and **postfix** patches, declared with `[HarmonyPatch]` attributes in the `Patches`
  folder; the template applies them all with `PatchAll`. Start from the example patch there.
- Use a **transpiler** only when a prefix or postfix can't do it: it rewrites the IL once, at load, and
  breaks more easily when the game or another plugin changes the method.
- **Preloader patches** (Mono.Cecil, the template's `Preloader.cs`) are a last resort, for changed
  signatures or code that runs before static constructors. Pulsar strips the ReadyToRun precompiled code from
  an assembly it preloads, so every plugin that uses them slows down game loading.
- To reach private and internal members without reflection, enable the
  [Krafs Publicizer](https://github.com/krafs/Publicizer) as the template's README describes. Pulsar
  publicizes the same assemblies when it compiles your plugin. Without it use Harmony's `AccessTools`.
- Use a unique Harmony ID and never call `UnpatchAll()`: it removes other plugins' patches too.
- Pulsar ships Harmony 2.4.2; don't bundle your own.

Details, step by step, in the `se2-dev-plugin` skill: [Patching.md](../se2-dev-plugin/Patching.md) (prefix and
postfix), [PatchInjections.md](../se2-dev-plugin/PatchInjections.md) (`__instance`, `__result`, fields),
[AccessTools.md](../se2-dev-plugin/AccessTools.md), [TranspilerPatching.md](../se2-dev-plugin/TranspilerPatching.md),
[PatchingSpecialCases.md](../se2-dev-plugin/PatchingSpecialCases.md), [PreloaderPatching.md](../se2-dev-plugin/PreloaderPatching.md)
and [Publicizer.md](../se2-dev-plugin/Publicizer.md).
