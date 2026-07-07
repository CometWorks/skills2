#!/usr/bin/env python3
"""
Detect the current Space Engineers 2 game version from the game binaries.

Decompiles only the CurrentBundle type from VRage.AI.dll using ilspycmd, then
reads the `Version` string constant to derive a human-readable label.

Modes:
    check_version.py <Game2> <Data>
        Compare the current game version with the one previously recorded in
        <Data>/game_version.txt. Exit codes:
            0 = versions match
            2 = version differs or no recorded version
            1 = error while determining the version

    check_version.py --print <Game2>
        Print the current version label only.

    check_version.py --write <Game2> <Data>
        Write the current version into <Data>/game_version.txt and print the
        version label.
"""

import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path


VERSION_FILE_NAME = "game_version.txt"
GAME_DLL = "VRage.AI.dll"
GAME_TYPE = "CurrentBundle"

# ilspycmd executable. On Windows it is a global dotnet tool on PATH; on
# Linux prepare.sh may install it into a per-user tool-path and export
# ILSPYCMD with the absolute path. Fall back to the bare name otherwise.
ILSPYCMD = os.environ.get("ILSPYCMD", "ilspycmd")


def _decompile_type(game2: Path) -> str:
    dll = game2 / GAME_DLL
    if not dll.is_file():
        raise FileNotFoundError(f"Game DLL not found: {dll}")

    tmp_dir = Path(tempfile.mkdtemp(prefix="se2_version_"))
    try:
        cmd = [
            ILSPYCMD,
            "-t", GAME_TYPE,
            "--disable-updatecheck",
            "-o", str(tmp_dir),
            str(dll),
        ]
        result = subprocess.run(cmd, capture_output=True, text=True)
        if result.returncode != 0:
            raise RuntimeError(
                f"ilspycmd failed (exit {result.returncode}):\n"
                f"stdout:\n{result.stdout}\n"
                f"stderr:\n{result.stderr}"
            )

        text_chunks = []
        for cs_file in tmp_dir.rglob("*.cs"):
            text_chunks.append(cs_file.read_text(encoding="utf-8", errors="replace"))

        if not text_chunks and result.stdout:
            text_chunks.append(result.stdout)

        if not text_chunks:
            raise RuntimeError("ilspycmd produced no output for CurrentBundle")

        return "\n".join(text_chunks)
    finally:
        shutil.rmtree(tmp_dir, ignore_errors=True)


def _extract_version(source: str) -> str:
    match = re.search(r'const\s+string\s+Version\s*=\s*"([^"]+)"', source)
    if not match:
        raise RuntimeError("Could not find Version string in decompiled CurrentBundle")
    return match.group(1)


def _read_current(game2: Path) -> str:
    return _extract_version(_decompile_type(game2))


def _format_file_contents(version: str) -> str:
    return f"VERSION={version}\n"


def _read_recorded(version_file: Path) -> str:
    if not version_file.is_file():
        return ""
    for line in version_file.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or "=" not in line:
            continue
        name, _, value = line.partition("=")
        if name.strip() == "VERSION":
            return value.strip()
    return ""


def _cmd_check(game2: Path, data_dir: Path) -> int:
    try:
        current = _read_current(game2)
    except Exception as e:
        print(f"ERROR: {e}", file=sys.stderr)
        return 1

    version_file = data_dir / VERSION_FILE_NAME
    recorded = _read_recorded(version_file)

    if not recorded:
        print(f"MISSING (current: {current})")
        return 2

    if recorded == current:
        print(f"MATCH ({current})")
        return 0

    print(f"DIFFER (recorded: {recorded}, current: {current})")
    return 2


def _cmd_print(game2: Path) -> int:
    try:
        current = _read_current(game2)
    except Exception as e:
        print(f"ERROR: {e}", file=sys.stderr)
        return 1
    print(current)
    return 0


def _cmd_write(game2: Path, data_dir: Path) -> int:
    try:
        current = _read_current(game2)
    except Exception as e:
        print(f"ERROR: {e}", file=sys.stderr)
        return 1

    data_dir.mkdir(parents=True, exist_ok=True)
    version_file = data_dir / VERSION_FILE_NAME
    version_file.write_text(_format_file_contents(current), encoding="utf-8")
    print(current)
    return 0


def main(argv):
    args = list(argv[1:])
    if not args:
        print(__doc__)
        return 1

    if args[0] == "--print":
        if len(args) != 2:
            print("Usage: check_version.py --print <Game2>", file=sys.stderr)
            return 1
        return _cmd_print(Path(args[1]))

    if args[0] == "--write":
        if len(args) != 3:
            print("Usage: check_version.py --write <Game2> <Data>", file=sys.stderr)
            return 1
        return _cmd_write(Path(args[1]), Path(args[2]))

    if len(args) != 2:
        print("Usage: check_version.py <Game2> <Data>", file=sys.stderr)
        return 1
    return _cmd_check(Path(args[0]), Path(args[1]))


if __name__ == "__main__":
    sys.exit(main(sys.argv))
