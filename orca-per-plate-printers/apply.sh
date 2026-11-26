#!/usr/bin/env bash
# Clones OrcaSlicer at the commit the patch was made against and applies the per-plate printers patch.
# Usage: ./apply.sh [target-dir]        (default: ./OrcaSlicer)
# Then build as usual, e.g. on Linux: cd OrcaSlicer && ./build_linux.sh -u && ./build_linux.sh -dsi
set -euo pipefail

BASE_COMMIT=808dd7dff83f8069c05abd3567811339857b90a1   # OrcaSlicer main, 2026-11-25
HERE="$(cd "$(dirname "$0")" && pwd)"
TARGET="${1:-OrcaSlicer}"

if [ ! -d "$TARGET/.git" ]; then
    git clone https://github.com/OrcaSlicer/OrcaSlicer.git "$TARGET"
fi
cd "$TARGET"
git fetch origin "$BASE_COMMIT" 2>/dev/null || true
git checkout -B per-plate-printers "$BASE_COMMIT"
git am "$HERE"/patches/*.patch
echo "Applied. Branch 'per-plate-printers' is checked out in $TARGET."
