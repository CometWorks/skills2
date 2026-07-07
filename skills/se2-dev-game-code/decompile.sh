#!/bin/sh

LOG="Decompile.log"

echo "Decompiling game assemblies..."
echo "Decompiling game assemblies: " > "$LOG"

# Make sure the destination folder under Data exists (Data is a junction
# pointing to %USERPROFILE%/.se2-dev/game-code/).
mkdir -p Data/Decompiled

# Helper function to run the decompile and handle errors
run_decompile() {
    # Calls the per-assembly decompile script
    ./decompile_dll.sh "$1" "$2" >> "$LOG" 2>&1

    if [ $? -ne 0 ]; then
        echo "Failed to decompile $1. Please check $LOG for details."
        exit 1
    fi
}

# Execution List
run_decompile "Game2.AutoTests" "Game2/Game2.AutoTests.dll"
run_decompile "Game2.Client" "Game2/Game2.Client.dll"
run_decompile "Game2.ContentBuilder" "Game2/Game2.ContentBuilder.dll"
run_decompile "Game2.Game" "Game2/Game2.Game.dll"
run_decompile "Game2.Plugin.Editor" "Game2/Game2.Plugin.Editor.dll"
run_decompile "Game2.Simulation" "Game2/Game2.Simulation.dll"
run_decompile "SpaceEngineers2" "Game2/SpaceEngineers2.dll"
run_decompile "VRage.AI" "Game2/VRage.AI.dll"
run_decompile "VRage.Analytics" "Game2/VRage.Analytics.dll"
run_decompile "VRage.Animation.Client" "Game2/VRage.Animation.Client.dll"
run_decompile "VRage.Animation" "Game2/VRage.Animation.dll"
run_decompile "VRage.Audio" "Game2/VRage.Audio.dll"
run_decompile "VRage.AutoTest" "Game2/VRage.AutoTest.dll"
run_decompile "VRage.Client.ContentBuilder" "Game2/VRage.Client.ContentBuilder.dll"
run_decompile "VRage.Client" "Game2/VRage.Client.dll"
run_decompile "VRage.CodeAnalysis" "Game2/VRage.CodeAnalysis.dll"
run_decompile "VRage.CodeGuard.Analyzers" "Game2/VRage.CodeGuard.Analyzers.dll"
run_decompile "VRage.ContentPipeline.Animations" "Game2/VRage.ContentPipeline.Animations.dll"
run_decompile "VRage.ContentPipeline.ArmorBlockModel" "Game2/VRage.ContentPipeline.ArmorBlockModel.dll"
run_decompile "VRage.ContentPipeline.ArmorBlockSide" "Game2/VRage.ContentPipeline.ArmorBlockSide.dll"
run_decompile "VRage.ContentPipeline.Audio" "Game2/VRage.ContentPipeline.Audio.dll"
run_decompile "VRage.ContentPipeline.Builder" "Game2/VRage.ContentPipeline.Builder.dll"
run_decompile "VRage.ContentPipeline.Builder.Plugin" "Game2/VRage.ContentPipeline.Builder.Plugin.dll"
run_decompile "VRage.ContentPipeline" "Game2/VRage.ContentPipeline.dll"
run_decompile "VRage.ContentPipeline.Game" "Game2/VRage.ContentPipeline.Game.dll"
run_decompile "VRage.ContentPipeline.Models" "Game2/VRage.ContentPipeline.Models.dll"
run_decompile "VRage.ContentPipeline.ModelsBase" "Game2/VRage.ContentPipeline.ModelsBase.dll"
run_decompile "VRage.ContentPipeline.ModelsValidation" "Game2/VRage.ContentPipeline.ModelsValidation.dll"
run_decompile "VRage.ContentPipeline.ModelVoxels" "Game2/VRage.ContentPipeline.ModelVoxels.dll"
run_decompile "VRage.ContentPipeline.PlanetTextures" "Game2/VRage.ContentPipeline.PlanetTextures.dll"
run_decompile "VRage.ContentPipeline.Publishing" "Game2/VRage.ContentPipeline.Publishing.dll"
run_decompile "VRage.ContentPipeline.Scripting" "Game2/VRage.ContentPipeline.Scripting.dll"
run_decompile "VRage.ContentPipeline.SlugFont" "Game2/VRage.ContentPipeline.SlugFont.dll"
run_decompile "VRage.ContentPipeline.SlugSVG" "Game2/VRage.ContentPipeline.SlugSVG.dll"
run_decompile "VRage.ContentPipeline.Textures" "Game2/VRage.ContentPipeline.Textures.dll"
run_decompile "VRage.Core" "Game2/VRage.Core.dll"
run_decompile "VRage.Core.Editor" "Game2/VRage.Core.Editor.dll"
run_decompile "VRage.Core.Game" "Game2/VRage.Core.Game.dll"
run_decompile "VRage.Core.Game.Editor" "Game2/VRage.Core.Game.Editor.dll"
run_decompile "VRage.DCS" "Game2/VRage.DCS.dll"
run_decompile "VRage.DCS.Generator" "Game2/VRage.DCS.Generator.dll"
run_decompile "VRage.DCS.Samples" "Game2/VRage.DCS.Samples.dll"
run_decompile "VRage.EOS" "Game2/VRage.EOS.dll"
run_decompile "VRage.Game.Client" "Game2/VRage.Game.Client.dll"
run_decompile "VRage.Game" "Game2/VRage.Game.dll"
run_decompile "VRage.Input" "Game2/VRage.Input.dll"
run_decompile "VRage.Library" "Game2/VRage.Library.dll"
run_decompile "VRage.Library.Generator" "Game2/VRage.Library.Generator.dll"
run_decompile "VRage.Mod.Io" "Game2/VRage.Mod.Io.dll"
run_decompile "VRage.Multiplayer" "Game2/VRage.Multiplayer.dll"
run_decompile "VRage.Physics.Client" "Game2/VRage.Physics.Client.dll"
run_decompile "VRage.Physics" "Game2/VRage.Physics.dll"
run_decompile "VRage.Platform.Windows" "Game2/VRage.Platform.Windows.dll"
run_decompile "VRage.Render" "Game2/VRage.Render.dll"
run_decompile "VRage.Render12" "Game2/VRage.Render12.dll"
run_decompile "VRage.Scripting" "Game2/VRage.Scripting.dll"
run_decompile "VRage.ShaderBuilder" "Game2/VRage.ShaderBuilder.dll"
run_decompile "VRage.Steam" "Game2/VRage.Steam.dll"
run_decompile "VRage.TestLogger" "Game2/VRage.TestLogger.dll"
run_decompile "VRage.Testing" "Game2/VRage.Testing.dll"
run_decompile "VRage.UI" "Game2/VRage.UI.dll"
run_decompile "VRage.UI.Shared" "Game2/VRage.UI.Shared.dll"
run_decompile "VRage.UI.Tests" "Game2/VRage.UI.Tests.dll"
run_decompile "VRage.Voxels.Client" "Game2/VRage.Voxels.Client.dll"
run_decompile "VRage.Voxels" "Game2/VRage.Voxels.dll"
run_decompile "VRage.Voxels.Editor" "Game2/VRage.Voxels.Editor.dll"
run_decompile "VRage.Water.Client" "Game2/VRage.Water.Client.dll"
run_decompile "VRage.Water" "Game2/VRage.Water.dll"

# Success cleanup
echo "Successfully decompiled the game assemblies."
rm "$LOG"
exit 0
