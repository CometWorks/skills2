1. On Windows only: run `python --version`; if it fails or is not at least 3.13 then inform the user and stop here. (On Linux the pinned Python 3.13 is provided automatically by `uv` for the virtual environment, so the system Python version does not matter.) In all cases the command line `git` client must be available on `PATH`.
2. Inform the user that this is a one time preparation which will take about 1 minute.
3. Run the preparation with this same folder as CWD (where `Prepare.md` is situated):
   - **Linux:** `./prepare.sh >Prepare.log 2>&1`
   - **Windows:** `.\Prepare.bat >Prepare.log 2>&1`
4. The preparation is successful if the last line of `Prepare.log` is `DONE`. If it fails, inform the user and stop here.
