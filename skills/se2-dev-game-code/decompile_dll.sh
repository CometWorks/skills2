#!/bin/sh

# $1 is the first argument (directory name)
# $2 is the second argument (path to DLL)

# Some XmlSerializers assemblies have very deep generic type graphs that blow
# the default 1 MB managed thread stack inside ilspycmd ("Recursion too deep;
# the stack overflowed", 0xC00000FD). Bump the .NET default stack size to 16 MB
# (16x the default) for every thread the runtime creates. The variable is read
# by the CoreCLR host in hex bytes; 0x1000000 = 16777216 = 16 MB.
export DOTNET_Thread_DefaultStackSize=1000000
export COMPlus_Thread_DefaultStackSize=1000000

# ilspycmd executable. On Windows it is a global dotnet tool on PATH; on
# Linux prepare.sh may install it into a per-user tool-path and export
# ILSPYCMD with the absolute path. Fall back to the bare name otherwise.
ILSPYCMD="${ILSPYCMD:-ilspycmd}"

OUT="Data/Decompiled/$1"

echo "Decompiling: $1"

# A successful previous run leaves the marker file. The marker is what makes
# subsequent runs skip the assembly cleanly even if the source set was wiped
# only partially.
if [ -f "$OUT/.decompiled" ]; then
    echo "Directory $OUT already decompiled. Skipping."
    exit 0
fi

# If a partial directory is left over from an earlier failed/aborted run,
# remove it so ilspycmd can produce a clean tree.
if [ -d "$OUT" ]; then
    echo "Removing stale partial decompilation in $OUT"
    rm -rf "$OUT"
fi

# Workarounds for ilspycmd 10.0.1.8346 bugs against SE2 binaries:
#   -ds Deconstruction=false : avoid IndexOutOfRangeException in
#     TranslateDeconstructionDesignation on certain
#     `using`+foreach-deconstruction patterns (e.g.
#     Keen.VRage.Library.Definitions.DefinitionSet.ApplyDefinitionRemovals).
#     Tuples are emitted as Item1/Item2 accesses instead of `var (a,b) = ...`.
#   -ds AsyncAwait=false : avoid IndexOutOfRangeException in
#     AsyncAwaitDecompiler.MatchTaskCreationPattern on certain async methods
#     (e.g. Keen.VRage.Platform.Windows.Forms.ClipboardHelper.RunAsync).
#     Async methods will appear as their underlying state machines.
# Both losses are acceptable for read-only browsing/indexing.
"$ILSPYCMD" --project --nested-directories --referencepath Game2 --languageversion CSharp14_0 --disable-updatecheck -ds Deconstruction=false -ds AsyncAwait=false -o "$OUT" "$2"
RC=$?
if [ $RC -ne 0 ]; then
    echo "Failed during project decompilation (ilspycmd exit $RC)."
    rm -rf "$OUT"
    exit 1
fi

# Second ilspycmd execution to decompile to IL code
# Uncomment the next line to produce IL code. These files are big and useful only for transpiler and preloader patch development.
#"$ILSPYCMD" --ilcode --il-sequence-points -o "$OUT" "$2"
#RC=$?
#if [ $RC -ne 0 ]; then
#    echo "Failed during IL code generation (ilspycmd exit $RC)."
#    rm -rf "$OUT"
#    exit 1
#fi

# Mark this assembly's decompilation as successful.
touch "$OUT/.decompiled"
exit 0
