1. On Windows only: run `python --version`; if it fails or is not at least 3.13 then inform the user and stop here. (On Linux the pinned Python 3.13 is provided automatically by `uv` for the virtual environment, so the system Python version does not matter.) In all cases the command line `git` client must be available on `PATH`.
2. Inform the user that this is a one time preparation which will take about 1 minute.
3. Run the preparation with this same folder as CWD (where `Prepare.md` is situated):
   - **Linux:** `./prepare.sh >Prepare.log 2>&1`
   - **Windows:** `.\Prepare.bat >Prepare.log 2>&1`
4. The preparation is successful if the last line of `Prepare.log` is `DONE`. If it fails, inform the user and stop here.

Notes:
- An optional Graphify graph is built for the downloaded plugin sources under `Data/Sources` at the end of preparation. It builds **automatically** when the fast Rust clustering backend is available (Python 3.12 via `uv`, provisioned automatically); this corpus is small so it is quick either way. Without that backend it stays opt-in (`SE2_DEV_GRAPHIFY=1`); `SE2_DEV_GRAPHIFY=0` disables it. The graph is supplemental — a failure there never fails the core preparation. See [GraphifyPrepare.md](GraphifyPrepare.md).
