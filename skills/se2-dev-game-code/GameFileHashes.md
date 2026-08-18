# Game File Hashes

> **Part of the se2-dev-game-code skill.** Read this only when you need to know
> *which game files* changed between two builds, or to check an install for
> modified/missing files.

Preparation records a SHA256 digest of **every** file in the Space Engineers 2
install into `Data/game_files.json`. Unlike `Data/Decompiled` (C# code only) and
`Data/Content` (text content only), this covers the whole install: native DLLs,
shader caches, packed assets, models, textures, audio, videos, the redistributables
— everything.

## File format

A plain JSON object, nothing else:

```json
{
  "Game2/Assimp64.dll": "a12e4003b0eaaaf2a66beaa0ff4e8c1269ade48b40c5092ec8928509637da348",
  "Game2/Avalonia.Base.dll": "16286813b393b5684fc2b84d12647577763f08939a6eb03de238313d7f45572e",
  "Licenses.txt": "17f165d5a5ba695f27c023a83aa2b3463e23810e360b7517127e90161eebabda"
}
```

- **Key** — the file's path relative to the game's `SpaceEngineers2` folder (the
  install root holding `Game2`, `GameData`, etc.), always with forward slashes so
  the file is byte-identical on Windows and Linux.
- **Value** — lower-case hex SHA256 of the file's contents, with no algorithm prefix.
- Keys are sorted alphabetically and the file is written with 2-space indentation,
  so every pair sits on its own line and `git diff` shows one line per changed file.
- Line endings are always LF, so the file is byte-identical on Windows and Linux and
  snapshots taken on different machines compare directly.
- Symlinks, junctions and non-regular files are skipped; only real files are hashed.

## Versioning and diffing

`Data/game_files.json` is committed to the `Data` Git repository along with the
decompiled sources and content, under the game version label. Preparation
regenerates it whenever the game version changes (the wipe step deletes it), so
the history has one snapshot per game build.

To see exactly which binaries a game update touched:

```bash
git -C Data log --oneline -- game_files.json     # one commit per game version
git -C Data diff <older-version> <newer-version> -- game_files.json
```

Removed lines that have no matching added line are deleted files; added lines with
no matching removed line are new files; a `-`/`+` pair on the same path is a changed
file. This is the only way to spot changes in assets that are neither assemblies
(so not in `Data/Decompiled`) nor text (so not in `Data/Content`) — for example a
shader cache rebuild, a repacked model archive or an updated native library.

## Verifying an install

Re-hash the installed game and compare it against the recorded digests:

```bash
# Linux
./verify_game_files.sh
```

```cmd
REM Windows
.\VerifyGameFiles.bat
```

Both detect the game install the same way preparation does (`SE2_GAME_ROOT`
overrides detection) and print one line per discrepancy followed by a summary:

| Prefix | Meaning |
|--------|---------|
| `MISSING:` | recorded in `game_files.json`, absent from the install |
| `MODIFIED:` | present but its contents no longer hash to the recorded digest |
| `EXTRA:` | present in the install but not recorded (added after the snapshot) |

Exit codes: `0` everything matches, `2` discrepancies found, `1` error (install or
hash file not found).

A failing verification usually means one of:

- the game was updated but preparation has not been re-run — re-run it
- files were modified by a mod loader, an anti-cheat, or a partial Steam update
- the install is corrupted — verify the files through Steam

Extra arguments are passed on to the underlying script, e.g. `-j 8` to limit the
number of hashing threads or `-q` to suppress progress output.

## Direct script use

```bash
# Write the digests (what preparation runs)
uv run hash_game_files.py --write "<GameRoot>" Data

# Verify against them
uv run hash_game_files.py --verify "<GameRoot>" Data
```

`<GameRoot>` is the install root, **not** the `Game2` subfolder; passing `Game2`
is rejected because the recorded paths are relative to the root. Hashing runs on a
thread pool (`-j`, default: CPU count capped at 16) and takes well under a minute
on a fast SSD for the ~70 GiB install.
