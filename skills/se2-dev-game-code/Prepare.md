1. Run `git --version`, if it fails inform the user that the command line `git` client must be available on `PATH` and stop here.
2. On Windows only: run `python --version`; if it fails or is not at least 3.13 then inform the user and stop here. (On Linux the pinned Python 3.13 is provided automatically by `uv` for the virtual environment, so the system Python version does not matter.)
3. Inform the user that this is a one time preparation which will take about 5-15 minutes. Highlight this message.
4. Run the preparation with this same folder as CWD (where `Prepare.md` is situated):
   - **Linux:** `./prepare.sh >Prepare.log 2>&1`
   - **Windows:** `.\Prepare.bat >Prepare.log 2>&1`
5. The preparation is successful if the last line of `Prepare.log` is `DONE`. If it fails, inform the user and stop here.

Notes:
- The game install is detected automatically. On Linux it is found via the Steam library folders (Space Engineers 2, app id 1133870); set the `SE2_GAME_ROOT` environment variable to the game's root folder (the one containing `Game2/`) to override detection.
- The actual data (decompiled sources, content files and indexes) is stored under the per-user data folder and exposed via the `Data` junction/symlink in this skill folder:
  - **Windows:** `%USERPROFILE%\.se2-dev\game-code\` (`%USERPROFILE%` is used instead of `%LOCALAPPDATA%` to stay outside any per-app UWP filesystem virtualization).
  - **Linux:** `~/.se2-dev/game-code/`.
- A local Git repository inside the `Data` folder records every successful decompilation as a commit whose message is the game version label.
- Subsequent runs detect game updates automatically: if the game's version changes, the previous `Decompiled/`, `Content/` and `CodeIndex/` directories are wiped and rebuilt; the previous version stays available in the Git history.
- An optional Graphify graph is built for `Data/Decompiled` at the end of preparation. It builds **automatically** when the fast Rust clustering backend is available (Python 3.12 via `uv`, provisioned in ~30-60s the first time; clustering then takes ~1-2 minutes). Without that backend it falls back to slow single-core clustering (~10-30 minutes) and is **skipped** unless you opt in — ask the user before opting into the slow build, then run prepare with `SE2_DEV_GRAPHIFY=1` (e.g. `SE2_DEV_GRAPHIFY=1 ./prepare.sh`). `SE2_DEV_GRAPHIFY=0` disables it entirely. The graph is supplemental — a failure there never fails the core preparation. See [GraphifyPrepare.md](GraphifyPrepare.md).
