#!/usr/bin/env python3
"""Graphify query smoke test for the decompiled game-code graph.

Usage: test_graphify_queries.py <dir containing graphify-out>

The platform wrapper (`test_graphify_game_code.sh` / `.bat`) runs the health
check and passes the graph directory here. Every query asserts its outcome
instead of only printing it, and `explain` additionally asserts that the name
resolved to a real source-backed node: fuzzy matching happily settles on a stub
node that carries no source location and a single edge, which looks like a
successful answer but tells you nothing.

Exits non-zero if any check failed.
"""

import subprocess
import sys
from pathlib import Path

BANNER = "=" * 60

# Argument lists passed to `graphify`, grouped into printed sections.
#
# `explain`, `path` and `affected` are given names that resolve to exactly one
# source-backed node. Common short names (Entity, CubeGridComponent, ...) occur
# on many nodes, so fuzzy matching lands on a sourceless stub for `explain` and
# `affected` reports "No unique node match" - see the name-resolution pitfalls in
# ../se2-dev/GraphifyUsage.md. Free-text `query` is unaffected: it starts a BFS
# from several seeds rather than resolving one node.
QUERIES = [
    ("section", "QUERY - BFS traversal for a question"),
    ("query", ["query", "How is a cube grid built and updated?", "--budget", "400"]),
    ("query", ["query", "How is an entity created and destroyed?", "--budget", "400"]),

    ("section", "QUERY - narrowed by edge context"),
    ("query", ["query", "GameCoreScene", "--context", "references", "--budget", "300"]),

    ("section", "EXPLAIN - a node and its neighbours"),
    ("explain", ["explain", "GameApp"]),
    ("explain", ["explain", "GameCoreScene"]),
    ("explain", ["explain", "WaterFlowService"]),

    ("section", "PATH - shortest path between two nodes"),
    ("path", ["path", "GameApp", "GameCoreScene"]),

    ("section", "AFFECTED - reverse traversal for impact"),
    ("affected", ["affected", "GameApp", "--depth", "1"]),
    ("affected", ["affected", "GameCoreScene", "--depth", "1"]),
]


def section(title):
    print(BANNER)
    print(title)
    print(BANNER)


def run_graphify(graph_dir, args):
    result = subprocess.run(
        ["graphify", *args], cwd=graph_dir, capture_output=True, text=True
    )
    return (result.stdout + result.stderr).strip()


def check_output(kind, output):
    """Return a problem description, or None when the output looks usable."""
    if not output:
        return "no output"
    if "No matching nodes found" in output:
        return "no matching nodes"
    if kind == "explain":
        # A resolved node must be backed by a source location; a bare stub means
        # the fuzzy match landed on a placeholder rather than the real symbol.
        for line in output.splitlines():
            if line.strip().startswith("Source:"):
                if line.split(":", 1)[1].strip():
                    return None
                return "resolved to a node without a source location"
        return "no Source line in explain output"
    if kind == "path" and "Shortest path" not in output:
        return "no path found"
    return None


def main():
    if len(sys.argv) != 2:
        print(f"usage: {Path(sys.argv[0]).name} <dir containing graphify-out>")
        return 2

    graph_dir = Path(sys.argv[1]).resolve()
    if not (graph_dir / "graphify-out").is_dir():
        print(f"FATAL: no graphify-out directory under {graph_dir}")
        return 2

    checks = 0
    failures = []

    for kind, payload in QUERIES:
        if kind == "section":
            section(payload)
            continue

        checks += 1
        title = " ".join(payload)
        print(f"--- {title} ---")
        output = run_graphify(graph_dir, payload)
        print(output)

        problem = check_output(kind, output)
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
