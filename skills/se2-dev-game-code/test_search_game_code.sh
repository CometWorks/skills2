#!/usr/bin/env bash
# test_search_game_code.sh - POSIX counterpart of test_search_game_code.bat.
# Exercises every game code search capability. Run from any directory.
set -u
cd "$(dirname "$(readlink -f "$0")")"

section() {
    echo "============================================================"
    echo "$1"
    echo "============================================================"
}

section "CLASS DECLARATION"
echo "--- Entity class declaration ---"
uv run search_game_code.py class declaration Entity
echo
echo "--- GameApp class declaration ---"
uv run search_game_code.py class declaration GameApp
echo

section "CLASS USAGE"
echo "--- Entity class usage (limit 5) ---"
uv run search_game_code.py -l 5 class usage Entity
echo
echo "--- GameApp class usage (limit 5) ---"
uv run search_game_code.py -l 5 class usage GameApp
echo

section "STRUCT DECLARATION"
echo "--- Vector3D struct declaration ---"
uv run search_game_code.py struct declaration Vector3D
echo
echo "--- ColorHSV struct declaration ---"
uv run search_game_code.py struct declaration "re:^ColorHSV$"
echo

section "STRUCT USAGE"
echo "--- Vector3D struct usage (limit 5) ---"
uv run search_game_code.py -l 5 struct usage Vector3D
echo
echo "--- ColorHSV struct usage (limit 5) ---"
uv run search_game_code.py -l 5 struct usage "re:^ColorHSV$"
echo

section "METHOD DECLARATION"
echo "--- Init method declaration (limit 5) ---"
uv run search_game_code.py -l 5 method declaration Init
echo
echo "--- Update method declaration (limit 5) ---"
uv run search_game_code.py -l 5 method declaration "re:^Update$"
echo

section "METHOD USAGE"
echo "--- Init method usage (limit 5) ---"
uv run search_game_code.py -l 5 method usage Init
echo
echo "--- Dispose method usage (limit 5) ---"
uv run search_game_code.py -l 5 method usage Dispose
echo

section "FIELD DECLARATION"
echo "--- Position field declaration ---"
uv run search_game_code.py field declaration Position
echo
echo "--- Forward field declaration (limit 5) ---"
uv run search_game_code.py -l 5 field declaration "re:^Forward$"
echo

section "FIELD USAGE"
echo "--- Field usage in Update methods (limit 5) ---"
uv run search_game_code.py -l 5 field usage "re:^Update$"
echo
echo "--- Position field usage (limit 5) ---"
uv run search_game_code.py -l 5 field usage Position
echo

section "INTERFACE DECLARATION"
echo "--- IEntityContainer interface declaration ---"
uv run search_game_code.py interface declaration IEntityContainer
echo
echo "--- IEntityLifetime interface declaration ---"
uv run search_game_code.py interface declaration IEntityLifetime
echo

section "INTERFACE USAGE"
echo "--- IEntityContainer interface usage (limit 5) ---"
uv run search_game_code.py -l 5 interface usage IEntityContainer
echo

section "ENUM DECLARATION"
echo "--- enum declarations matching \"Type\" (limit 5) ---"
uv run search_game_code.py -l 5 enum declaration Type
echo

section "ENUM USAGE"
echo "--- enum usages matching \"Type\" (limit 5) ---"
uv run search_game_code.py -l 5 enum usage Type
echo

section "NAMESPACE FILTERING"
echo "--- Classes in Keen.Game2 namespace (limit 5) ---"
uv run search_game_code.py -n Keen.Game2 -l 5 class declaration ""
echo
echo "--- Methods in Keen.Game2 namespace containing \"Update\" (limit 5) ---"
uv run search_game_code.py -n Keen.Game2 -l 5 method declaration Update
echo

section "PAGINATION (LIMIT AND OFFSET)"
echo "--- First 3 class declarations ---"
uv run search_game_code.py -l 3 class declaration ""
echo
echo "--- Next 3 class declarations (offset 3) ---"
uv run search_game_code.py -l 3 -o 3 class declaration ""
echo
echo "--- Skip 6, show 3 ---"
uv run search_game_code.py -l 3 -o 6 class declaration ""
echo

section "COUNT MODE"
echo "--- Count of Entity usages ---"
uv run search_game_code.py -c class usage Entity
echo
echo "--- Count of Vector3D usages ---"
uv run search_game_code.py -c struct usage Vector3D
echo
echo "--- Count of Init method declarations ---"
uv run search_game_code.py -c method declaration Init
echo

section "REGEX PATTERNS"
echo "--- Classes starting with \"Grid\" (limit 5) ---"
uv run search_game_code.py -l 5 class declaration "re:^Grid"
echo
echo "--- Methods ending with \"Position\" (limit 5) ---"
uv run search_game_code.py -l 5 method declaration "re:Position$"
echo
echo "--- Structs matching \"Vector[23]D\" ---"
uv run search_game_code.py struct declaration "re:^Vector[23]D$"
echo

section "MULTIPLE PATTERNS (AND logic)"
echo "--- Methods containing both \"Get\" and \"Position\" ---"
uv run search_game_code.py -l 5 method declaration Get Position
echo

section "METHOD SIGNATURE SEARCH"
echo "--- Init method signature (limit 5) ---"
uv run search_game_code.py -l 5 method signature Init
echo
echo "--- Update method signature (limit 5) ---"
uv run search_game_code.py -l 5 method signature "re:^Update$"
echo
echo "--- Count of GetPosition method signatures ---"
uv run search_game_code.py -c method signature GetPosition
echo
echo "--- Signature containing both \"Get\" and \"Position\" ---"
uv run search_game_code.py -l 5 method signature Get Position
echo

section "NON-MATCHING EXAMPLES"
echo "--- Non-existent class ---"
uv run search_game_code.py class declaration ThisClassDoesNotExist12345
echo
echo "--- Non-existent method ---"
uv run search_game_code.py method declaration ZzzNonExistentMethod999
echo
echo "--- Non-matching regex ---"
uv run search_game_code.py struct declaration "re:^ZZZZZ.*XXXXX$"
echo

section "HIERARCHY SEARCH - CLASS PARENT"
echo "--- Find parent of Entity ---"
uv run search_game_code.py -l 5 class parent Entity
echo

section "HIERARCHY SEARCH - CLASS CHILDREN"
echo "--- Find children of Entity (limit 5) ---"
uv run search_game_code.py -l 5 class children Entity
echo

section "HIERARCHY SEARCH - INTERFACE PARENT"
echo "--- Find parent of IEntityContainer ---"
uv run search_game_code.py interface parent IEntityContainer
echo

section "HIERARCHY SEARCH - INTERFACE CHILDREN"
echo "--- Find children of IEntityContainer (limit 5) ---"
uv run search_game_code.py -l 5 interface children IEntityContainer
echo

section "HIERARCHY SEARCH - CLASS IMPLEMENTS"
echo "--- Find interfaces implemented by Entity (limit 5) ---"
uv run search_game_code.py -l 5 class implements Entity
echo

section "HIERARCHY SEARCH - INTERFACE IMPLEMENTORS"
echo "--- Find implementors of IEntityContainer (limit 5) ---"
uv run search_game_code.py -l 5 interface implementors IEntityContainer
echo

section "HIERARCHY SEARCH - COUNT MODE"
echo "--- Count children of Entity ---"
uv run search_game_code.py -c class children Entity
echo
echo "--- Count implementors of IEntityContainer ---"
uv run search_game_code.py -c interface implementors IEntityContainer
echo

section "HIERARCHY SEARCH - WITH NAMESPACE FILTER"
echo "--- Find children of Entity in Keen.Game2 namespace (limit 5) ---"
uv run search_game_code.py -n Keen.Game2 -l 5 class children Entity
echo

section "ALL TESTS COMPLETED"
