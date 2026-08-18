# Test Action

> **Part of the se2-dev-game-code skill.** Invoked to run game code search tests and verify results.

Run `test_search_game_code.bat` (Windows) or `./test_search_game_code.sh` (Linux) to verify the game code search functionality is working correctly.

## Running Tests

From this skill folder, run:

```bash
# Linux
./test_search_game_code.sh

# Windows
.\test_search_game_code.bat
```

Or redirect output to a file for review:

```bash
# Linux
./test_search_game_code.sh > test_results.txt 2>&1

# Windows
.\test_search_game_code.bat > test_results.txt 2>&1
```

Both wrappers run the same checks from `test_search_code.py`, so Linux and
Windows results are identical.

## What the Tests Cover

The test suite exercises all game code search capabilities:

| Category | Tests |
|----------|-------|
| Class declaration | Entity, GameApp |
| Class usage | Entity, GameApp |
| Struct declaration | Vector3D, ColorHSV |
| Struct usage | Vector3D, ColorHSV |
| Method declaration | Init, Update |
| Method usage | Init, Dispose |
| Method signature | Init, Update, GetPosition |
| Field declaration | Position, Forward |
| Field usage | Update (regex), Position |
| Interface declaration | IEntityContainer, IEntityLifetime |
| Interface usage | IEntityContainer |
| Enum declaration | Type, EntityType |
| Enum usage | Type |
| Enum member declaration | None (plus a lower bound on the total) |
| Delegate declaration | ExternalApi (nested delegate keeps its own name) |
| Property declaration | Position |
| Namespace filtering | Keen.Game2 |
| Pagination | limit and offset options |
| Count mode | counting results instead of listing |
| Regex patterns | ^Grid, Position$, ^Vector[23]D$ |
| Multiple patterns | AND logic with multiple terms |
| Hierarchy - class parent | Entity |
| Hierarchy - class children | Entity |
| Hierarchy - interface parent | IEntityContainer |
| Hierarchy - interface children | IEntityContainer |
| Hierarchy - class implements | Entity |
| Hierarchy - interface implementors | IEntityContainer |
| Member usage vs enclosing method | Update, Dispose, Entity |
| Non-matching examples | Verify empty results don't crash |

## Verifying Results

Each check asserts its own outcome, so reading the output is optional - the exit
code is authoritative:

- **Exit code 0** and a final `ALL TESTS COMPLETED` banner - everything passed
- **Exit code 1**, `FAIL:` lines next to the failing checks and a `TESTS FAILED`
  banner - the `SUMMARY` section lists every failure

Searches that find nothing print `NO-MATCHES`, which is the expected result only
in the non-matching examples section and in the checks that assert a symbol must
*not* be found.

## Example Verification

Check that key searches return expected results:

```bash
# Should find the Entity class
uv run search_game_code.py class declaration Entity

# Should find Vector3D struct
uv run search_game_code.py struct declaration Vector3D

# Should return count > 0
uv run search_game_code.py -c class usage Entity
```

## Troubleshooting

If tests fail:

1. **Preparation not complete** - Run `./prepare.sh` (Linux) or `.\Prepare.bat` (Windows) first
2. **Index not built** - Check that `Data/CodeIndex/` exists and contains `.csv` files
3. **Decompiled folder missing** - Verify `Data/Decompiled/` has `.cs` files
4. **Python environment issues** - Try `uv sync` to reinstall dependencies

As a last resort, you can force repeating the whole preparation process by running the clean then prepare scripts: `./clean.sh` then `./prepare.sh` (Linux), or `.\Clean.bat` then `.\Prepare.bat` (Windows).
Notify the user if you do this, because the preparation may take 5-15 minutes to complete depending on the hardware.

## Optional: Game File Integrity Check

Independent of the search tests, the installed game files can be checked against the
SHA256 digests recorded during preparation (`Data/game_files.json`):

```bash
# Linux
./verify_game_files.sh
```

```cmd
REM Windows
.\VerifyGameFiles.bat
```

Exit code 0 and `VERIFICATION PASSED` means the install matches the snapshot the
decompilation was made from. Exit code 2 lists the `MISSING:`/`MODIFIED:`/`EXTRA:`
files — usually a game update that preparation has not picked up yet, so re-run
preparation. See [GameFileHashes.md](../GameFileHashes.md).

## Optional: Graphify Graph Test

If the optional Graphify graph was built (see [Graphify Graph](../SKILL.md) and
[GraphifyPrepare.md](../../se2-dev/GraphifyPrepare.md)), verify it separately with the graph query
smoke test — analogous to the code-search test but exercising the Graphify graph:

```bash
# Linux
./test_graphify_game_code.sh
```

```cmd
REM Windows
.\test_graphify_game_code.bat
```

It first runs a health check (graph built and clustered), then asserted
`query`/`explain`/`path`/`affected` calls from `test_graphify_queries.py`, ending with
`ALL TESTS COMPLETED` and exit code 0. If it stops at the health check, the graph is
missing or unusable (clustering not finished); rebuild it with `SE2_DEV_GRAPHIFY=1` after
confirming the ~10-30 minute cost with the user.

An `explain` check fails when the name resolves to a node without a source location. That
means Graphify's fuzzy matching settled on a stub node instead of the real symbol - see
[GraphifyUsage.md](../../se2-dev/GraphifyUsage.md#name-resolution-pitfalls).
