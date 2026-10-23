#if DISABLED_PRELOADER_EXAMPLE

using System.Linq;
using ClientPlugin.Tools;
using Mono.Cecil;

namespace ClientPlugin.Patches;

/*
Example preloader patch skeleton: finds AnalyticsSessionComponent.UpdatePlayerPosition
in Game2.Client.dll, verifies its IL code and records it before and after patching.
It changes nothing yet, put your IL changes where the TODO says.
Pulsar calls it for every assembly listed in Preloader.TargetDLLs.
*/
public static class ExamplePrepatch
{
    public static void Prepatch(AssemblyDefinition asmDef)
    {
        // TODO: Filter for the assembly to patch (a Cecil assembly name has no .dll extension)
        if (asmDef.Name.Name != "Game2.Client")
            return;

        // TODO: Filter for the type to patch (FullName includes the namespace)
        var type = asmDef.MainModule.Types.First(t =>
            t.FullName == "Keen.Game2.Client.RuntimeSystems.Analytics.SessionComponents.AnalyticsSessionComponent"
        );

        // TODO: Filter for the member to patch
        var method = type.Methods.First(m =>
            m.Name == "UpdatePlayerPosition"
        );

        var il = method.Body.Instructions;
        
        // Record original IL code (debug only)
        il.RecordOriginalCode(method);
        
        // TODO: Optional: Ensure that game's code hasn't changed.
        il.VerifyCodeHash(method, "4e2797a2");

        // TODO: Change the IL code in `il` accordingly

        // Record modified IL code (debug only)
        il.RecordPatchedCode(method);
    }
}

#endif
