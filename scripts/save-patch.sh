#!/usr/bin/env bash
# Export the PS4 changes of the upstream checkout (branch ps4 against its base) into patches/.
# Run in WSL: scripts/save-patch.sh
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$HOME/clx-build/src/conker-lr-recomp"
cd "$SRC"
base=$(git merge-base main HEAD)
git add -A
git diff --cached "$base" > "$HERE/patches/clx-ps4.patch"
echo "upstream rashevskyv/conker-lr-recomp $(git rev-parse --short "$base")" > "$HERE/patches/BASE.txt"
git reset -q
echo "patches/clx-ps4.patch: $(grep -c '^diff --git' "$HERE/patches/clx-ps4.patch") files"
