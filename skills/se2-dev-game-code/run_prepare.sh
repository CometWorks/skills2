#!/bin/bash
# run_prepare.sh - Cross-platform wrapper that runs the correct preparation
# script for the current OS: prepare.sh on Linux, Prepare.bat (via cmd)
# on Windows shells such as Git Bash.

set -e  # Exit on error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

echo "Running preparation from: $SCRIPT_DIR"

if [ -f "Prepare.DONE" ]; then
    echo "✓ Preparation already complete (Prepare.DONE exists)"
    exit 0
fi

echo "Starting preparation... This may take 5-15 minutes."
echo "---"

case "$(uname -s 2>/dev/null || echo unknown)" in
    Linux)
        run_prep() { ./prepare.sh; }
        ;;
    *)
        # Windows (Git Bash / MSYS / Cygwin): run the batch file through cmd.
        run_prep() { cmd //c "$SCRIPT_DIR/Prepare.bat"; }
        ;;
esac

if run_prep >Prepare.log 2>&1; then
    if [ -f "Prepare.DONE" ]; then
        echo "---"
        echo "✓ Preparation completed successfully"
        echo ""
        echo "You can now use the skill features:"
        echo "  - Run code searches: uv run search_game_code.py --help"
        echo "  - Test the skill: ./test_search_game_code.sh (Linux) or .\\test_search_game_code.bat (Windows)"
        exit 0
    else
        echo "---"
        echo "✗ Preparation may have failed - Prepare.DONE not found"
        echo ""
        echo "Check Prepare.log for details:"
        tail -20 Prepare.log
        exit 1
    fi
else
    echo "---"
    echo "✗ Preparation execution failed"
    echo ""
    echo "Check Prepare.log for details:"
    tail -20 Prepare.log
    exit 1
fi
