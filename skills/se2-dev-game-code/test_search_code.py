#!/usr/bin/env python3
"""Code search smoke test for the decompiled code index.

Every check asserts its outcome: searches that must find something, searches
that must find nothing, and counts that must reach a lower bound. The runner
prints a summary and exits non-zero if any check failed, so a broken index or a
regression in the search script cannot pass unnoticed.

Run it through the platform wrapper (`test_search_game_code.sh` / `.bat`) so the
same checks run on Linux and Windows.
"""

import subprocess
import sys
from pathlib import Path

SCRIPT_DIR = Path(__file__).parent.resolve()

# (kind, title, args) where kind is:
#   "any"    - must return at least one result
#   "none"   - must return NO-MATCHES
#   (min, N) - -c count must be at least N
CHECKS = [
    ("section", "CLASS DECLARATION", None),
    ("any", "Entity class declaration", ["class", "declaration", "Entity"]),
    ("any", "CubeGridComponent class declaration", ["class", "declaration", "CubeGridComponent"]),

    ("section", "CLASS USAGE", None),
    ("any", "Entity class usage (limit 5)", ["-l", "5", "class", "usage", "Entity"]),
    ("any", "CubeGridComponent class usage (limit 5)", ["-l", "5", "class", "usage", "CubeGridComponent"]),

    ("section", "STRUCT DECLARATION", None),
    ("any", "Vector3D struct declaration", ["struct", "declaration", "Vector3D"]),
    ("any", "ColorHSV struct declaration", ["struct", "declaration", "re:^ColorHSV$"]),

    ("section", "STRUCT USAGE", None),
    ("any", "Vector3D struct usage (limit 5)", ["-l", "5", "struct", "usage", "Vector3D"]),
    ("any", "ColorHSV struct usage (limit 5)", ["-l", "5", "struct", "usage", "re:^ColorHSV$"]),

    ("section", "METHOD DECLARATION", None),
    ("any", "Init method declaration (limit 5)", ["-l", "5", "method", "declaration", "Init"]),
    ("any", "Update method declaration (limit 5)", ["-l", "5", "method", "declaration", "re:^Update$"]),
    ("any", "Methods in Keen.VRage namespace (namespace filter)", ["-n", "Keen.VRage", "-l", "5", "method", "declaration", "Update"]),

    ("section", "METHOD USAGE", None),
    ("any", "Init method usage (limit 5)", ["-l", "5", "method", "usage", "Init"]),
    ("any", "Dispose method usage (limit 5)", ["-l", "5", "method", "usage", "Dispose"]),

    ("section", "FIELD DECLARATION", None),
    ("any", "Position field declaration (limit 5)", ["-l", "5", "field", "declaration", "Position"]),
    ("any", "Forward field declaration (limit 5)", ["-l", "5", "field", "declaration", "re:^Forward$"]),

    ("section", "FIELD USAGE", None),
    ("any", "Position field usage (limit 5)", ["-l", "5", "field", "usage", "Position"]),

    ("section", "PROPERTY DECLARATION", None),
    # Properties used to be recorded with their type in the name column when the
    # type was namespace-qualified, which lost the property's own name.
    ("any", "Position property declaration (limit 5)", ["-l", "5", "property", "declaration", "re:^Position$"]),

    ("section", "INTERFACE DECLARATION", None),
    ("any", "IEntityContainer interface declaration", ["interface", "declaration", "IEntityContainer"]),
    ("any", "IEntityLifetime interface declaration", ["interface", "declaration", "IEntityLifetime"]),

    ("section", "INTERFACE USAGE", None),
    ("any", "IEntityContainer interface usage (limit 5)", ["-l", "5", "interface", "usage", "IEntityContainer"]),

    ("section", "ENUM DECLARATION", None),
    ("any", 'Enum declarations matching "Type" (limit 5)', ["-l", "5", "enum", "declaration", "Type"]),
    ("any", "EntityType enum declaration", ["enum", "declaration", "re:^EntityType$"]),

    ("section", "ENUM USAGE", None),
    ("any", 'Enum usages matching "Type" (limit 5)', ["-l", "5", "enum", "usage", "Type"]),

    ("section", "ENUM MEMBER DECLARATION", None),
    (("min", 1000), "Enum members are indexed at all", ["enum_member", "declaration", ""]),
    ("any", "None enum member declaration", ["-l", "5", "enum_member", "declaration", "re:^None$"]),
    # Enum members have no usage form of their own; the search must degrade to
    # NO-MATCHES instead of failing.
    ("none", "Enum member usage form does not exist", ["enum_member", "usage", "None"]),

    ("section", "DELEGATE DECLARATION", None),
    (("min", 100), "Delegates are indexed at all", ["delegate", "declaration", ""]),
    ("none", "Delegate usage form does not exist", ["delegate", "usage", "ExternalApi"]),
    # A delegate nested in a class keeps its own name. Re-attributing it to the
    # enclosing type would overwrite the very column its name lives in, leaving
    # it findable only under the parent's name.
    ("any", "Nested delegate keeps its own name", ["-l", "5", "delegate", "declaration", "re:^ExternalApi$"]),

    # Usage rows carry the enclosing namespace/type/method as context columns next
    # to the symbol itself. Matching the wrong column silently hides most member
    # usages (they sit inside method bodies) and invents matches on method names.
    ("section", "MEMBER USAGE RESOLVES THE MEMBER, NOT ITS ENCLOSING METHOD", None),
    ("none", "Update is a method - must not appear as a field usage", ["field", "usage", "re:^Update$"]),
    ("none", "Dispose is a method - must not appear as a property usage", ["property", "usage", "re:^Dispose$"]),
    (("min", 50), "Entity class usages include those inside methods", ["class", "usage", "re:^Entity$"]),

    ("section", "NAMESPACE FILTERING", None),
    ("any", "Classes in Keen.Game2 namespace", ["-n", "Keen.Game2", "-l", "5", "class", "declaration", ""]),
    ("any", 'Methods in Keen.Game2 namespace containing "Update"', ["-n", "Keen.Game2", "-l", "5", "method", "declaration", "Update"]),

    ("section", "PAGINATION (LIMIT AND OFFSET)", None),
    ("any", "First 3 Vector3D usages", ["-l", "3", "struct", "usage", "Vector3D"]),
    ("any", "Next 3 Vector3D usages (offset 3)", ["-l", "3", "-o", "3", "struct", "usage", "Vector3D"]),
    ("any", "Skip 6, show 3", ["-l", "3", "-o", "6", "struct", "usage", "Vector3D"]),

    ("section", "COUNT MODE", None),
    (("min", 1), "Count of Entity usages", ["class", "usage", "Entity"]),
    (("min", 1), "Count of Vector3D usages", ["struct", "usage", "Vector3D"]),
    (("min", 1), "Count of Init method declarations", ["method", "declaration", "Init"]),

    ("section", "REGEX PATTERNS", None),
    ("any", 'Classes starting with "Grid"', ["-l", "5", "class", "declaration", "re:^Grid"]),
    ("any", 'Methods ending with "Position" (limit 5)', ["-l", "5", "method", "declaration", "re:Position$"]),
    ("any", 'Structs matching "Vector[23]D"', ["struct", "declaration", "re:^Vector[23]D$"]),

    ("section", "MULTIPLE PATTERNS (AND logic)", None),
    ("any", 'Methods containing both "Get" and "Position"', ["-l", "5", "method", "declaration", "Get", "Position"]),

    ("section", "METHOD SIGNATURE SEARCH", None),
    ("any", "Init method signature (limit 5)", ["-l", "5", "method", "signature", "Init"]),
    ("any", "Update method signature (limit 5)", ["-l", "5", "method", "signature", "re:^Update$"]),
    (("min", 1), "Count of GetPosition method signatures", ["method", "signature", "GetPosition"]),
    ("any", 'Signature containing both "Get" and "Position"', ["-l", "5", "method", "signature", "Get", "Position"]),

    ("section", "NON-MATCHING EXAMPLES", None),
    ("none", "Non-existent class", ["class", "declaration", "ThisClassDoesNotExist12345"]),
    ("none", "Non-existent method", ["method", "declaration", "ZzzNonExistentMethod999"]),
    ("none", "Non-matching regex", ["struct", "declaration", "re:^ZZZZZ.*XXXXX$"]),

    ("section", "HIERARCHY SEARCH - CLASS PARENT", None),
    ("any", "Find parent of Entity", ["-l", "5", "class", "parent", "Entity"]),
    ("any", "Find parent of CubeGridComponent", ["-l", "5", "class", "parent", "CubeGridComponent"]),

    ("section", "HIERARCHY SEARCH - CLASS CHILDREN", None),
    ("any", "Find children of Entity (limit 5)", ["-l", "5", "class", "children", "Entity"]),

    ("section", "HIERARCHY SEARCH - INTERFACE PARENT", None),
    ("any", "Find parent of IEntityContainer", ["interface", "parent", "IEntityContainer"]),

    ("section", "HIERARCHY SEARCH - INTERFACE CHILDREN", None),
    ("any", "Find children of IEntityContainer (limit 5)", ["-l", "5", "interface", "children", "IEntityContainer"]),

    ("section", "HIERARCHY SEARCH - CLASS IMPLEMENTS", None),
    ("any", "Find interfaces implemented by CubeGridComponent", ["-l", "5", "class", "implements", "CubeGridComponent"]),

    ("section", "HIERARCHY SEARCH - INTERFACE IMPLEMENTORS", None),
    ("any", "Find implementors of IEntityContainer (limit 5)", ["-l", "5", "interface", "implementors", "IEntityContainer"]),

    ("section", "HIERARCHY SEARCH - COUNT MODE", None),
    (("min", 1), "Count children of Entity", ["class", "children", "Entity"]),
    (("min", 1), "Count implementors of IEntityContainer", ["interface", "implementors", "IEntityContainer"]),

    ("section", "HIERARCHY SEARCH - WITH NAMESPACE FILTER", None),
    ("any", "Find children of Entity in Keen.Game2 namespace", ["-n", "Keen.Game2", "-l", "5", "class", "children", "Entity"]),
]

BANNER = "=" * 60


def find_search_script():
    """Locate the skill's search script (search_game_code.py)."""
    candidates = sorted(SCRIPT_DIR.glob("search_*_code.py"))
    if not candidates:
        print(f"FATAL: no search_*_code.py found in {SCRIPT_DIR}")
        sys.exit(2)
    return candidates[0]


def section(title):
    print(BANNER)
    print(title)
    print(BANNER)


def run_search(script, args):
    result = subprocess.run(
        [sys.executable, str(script), *args],
        cwd=SCRIPT_DIR,
        capture_output=True,
        text=True,
    )
    return (result.stdout + result.stderr).strip()


def main():
    script = find_search_script()
    checks = 0
    failures = []

    for kind, title, args in CHECKS:
        if kind == "section":
            section(title)
            continue

        checks += 1
        is_count_check = kind not in ("any", "none")

        print(f"--- {title} ---")
        output = run_search(script, ["-c", *args] if is_count_check else args)
        print(output)

        problem = None
        if kind == "any":
            if not output or output == "NO-MATCHES":
                problem = "expected at least one result"
        elif kind == "none":
            if output != "NO-MATCHES":
                problem = "expected NO-MATCHES"
        else:
            minimum = kind[1]
            if not output.isdigit():
                problem = f"expected a count, got {output!r}"
            elif int(output) < minimum:
                problem = f"expected count >= {minimum}, got {output}"

        if problem:
            print(f"FAIL: {problem}")
            failures.append(f"{title}: {problem}")
        print()

    section("SUMMARY")
    print(f"Checks run: {checks}")
    print(f"Failures:   {len(failures)}")
    print()
    if failures:
        for failure in failures:
            print(f"FAILED - {failure}")
        print()
        section("TESTS FAILED")
        return 1

    section("ALL TESTS COMPLETED")
    return 0


if __name__ == "__main__":
    sys.exit(main())
