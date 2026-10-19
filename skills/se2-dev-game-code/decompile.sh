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

# Decompile every managed game assembly. The set changes between game versions
# (2.4 -> 4.0 dropped the test and sample assemblies), so it is discovered rather
# than listed. The *.Native.dll files are unmanaged and cannot be decompiled.
for dll in Game2/Game2.*.dll Game2/SpaceEngineers2.dll Game2/VRage.*.dll; do
    case "$dll" in
        *.Native.dll) continue ;;
    esac
    name="${dll#Game2/}"
    run_decompile "${name%.dll}" "$dll"
done

# Success cleanup
echo "Successfully decompiled the game assemblies."
rm "$LOG"
exit 0
