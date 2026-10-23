"""
Git helpers for downloading / updating repositories.

Used by download_pluginhub.py (clone, then `git fetch`/`git checkout` to
refresh the registry in place) and download_plugin_source.py (clone at the
registered commit; it falls back to a ZIP download when `git` is missing).
"""

import shutil
import subprocess
from pathlib import Path
from typing import Optional


def is_git_available() -> bool:
    """Return True if `git` is on PATH and runnable."""
    if shutil.which("git") is None:
        return False
    try:
        result = subprocess.run(
            ["git", "--version"],
            capture_output=True,
            text=True,
            timeout=10,
        )
        return result.returncode == 0
    except (OSError, subprocess.SubprocessError):
        return False


def _run_git(args: list, cwd: Optional[Path] = None) -> subprocess.CompletedProcess:
    return subprocess.run(
        ["git", *args],
        cwd=str(cwd) if cwd else None,
        capture_output=True,
        text=True,
    )


def is_git_repo(path: Path) -> bool:
    """Return True if `path` is a working tree of a git repository."""
    if not path.exists() or not path.is_dir():
        return False
    result = _run_git(["rev-parse", "--is-inside-work-tree"], cwd=path)
    return result.returncode == 0 and result.stdout.strip() == "true"


def get_head_commit(repo_dir: Path) -> str:
    """Return the full commit hash at HEAD, or empty string on failure."""
    if not is_git_repo(repo_dir):
        return ""
    result = _run_git(["rev-parse", "HEAD"], cwd=repo_dir)
    if result.returncode != 0:
        return ""
    return result.stdout.strip()


def clone_repo(url: str, dest: Path, commit: Optional[str] = None) -> bool:
    """
    Clone `url` into `dest`. If `commit` is provided, check that commit out
    after cloning. Returns True on success.
    """
    dest.parent.mkdir(parents=True, exist_ok=True)
    if dest.exists():
        shutil.rmtree(dest)

    result = _run_git(["clone", url, str(dest)])
    if result.returncode != 0:
        print(f"git clone failed: {result.stderr.strip()}")
        return False

    if commit:
        # Full hashes are fetched by default; checkout works even without a branch name.
        result = _run_git(["checkout", "--detach", commit], cwd=dest)
        if result.returncode != 0:
            # Fallback: try fetching the specific commit (works on servers that allow it).
            fetch = _run_git(["fetch", "origin", commit], cwd=dest)
            if fetch.returncode == 0:
                result = _run_git(["checkout", "--detach", commit], cwd=dest)
        if result.returncode != 0:
            print(f"git checkout {commit} failed: {result.stderr.strip()}")
            return False

    return True


def update_repo(repo_dir: Path, commit: Optional[str] = None) -> bool:
    """
    Update an existing repository. Fetches from origin and either checks out
    the given commit (detached) or resets to origin's default branch HEAD.
    Returns True on success.
    """
    if not is_git_repo(repo_dir):
        return False

    fetch = _run_git(["fetch", "--tags", "origin"], cwd=repo_dir)
    if fetch.returncode != 0:
        print(f"git fetch failed: {fetch.stderr.strip()}")
        return False

    if commit:
        co = _run_git(["checkout", "--detach", commit], cwd=repo_dir)
        if co.returncode != 0:
            # Try fetching the specific commit explicitly, then retry.
            fetch_commit = _run_git(["fetch", "origin", commit], cwd=repo_dir)
            if fetch_commit.returncode == 0:
                co = _run_git(["checkout", "--detach", commit], cwd=repo_dir)
        if co.returncode != 0:
            print(f"git checkout {commit} failed: {co.stderr.strip()}")
            return False
        return True

    # No specific commit: reset to origin's default branch HEAD.
    head = _run_git(["symbolic-ref", "refs/remotes/origin/HEAD"], cwd=repo_dir)
    default_ref = "refs/remotes/origin/main"
    if head.returncode == 0 and head.stdout.strip():
        default_ref = head.stdout.strip()
    reset = _run_git(["reset", "--hard", default_ref], cwd=repo_dir)
    if reset.returncode != 0:
        print(f"git reset failed: {reset.stderr.strip()}")
        return False
    return True


def clone_or_update(url: str, dest: Path, commit: Optional[str] = None) -> bool:
    """Clone `url` into `dest` if missing, otherwise update it in place."""
    if is_git_repo(dest):
        return update_repo(dest, commit)
    return clone_repo(url, dest, commit)
