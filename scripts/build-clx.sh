#!/usr/bin/env bash
# Build Conker: Live & Reloaded for the PS4 (ps4-kit) and package it as out/ConkerLR-vXX.YY.pkg.
# Run in WSL:
#   CLX_VERSION=00.01 scripts/build-clx.sh            lift (once), build, package
#   CLX_VERSION=00.01 scripts/build-clx.sh libs       only the runtime libraries (no XBE needed)
#   CLX_RELEASE=1 CLX_VERSION=01.00 scripts/build-clx.sh   release package: diagnostics off
#                                                       (CLX_DIAG=1 in clx_env.txt brings them back)
#
#   ~/clx-build/src/conker-lr-recomp   upstream checkout, branch ps4 (patches/clx-ps4.patch)
#   ~/clx-build/disc                   your unpacked disc (default.xbe, retail NTSC)
#   ~/clx-build/gen                    the lifted C (tools/regen.sh, ~15 min, ~15 GB RAM)
#   ~/clx-build/build                  the CMake build
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
source "$HOME/ps4-kit/toolchain/env.sh"
CLX="$HOME/clx-build"
SRC="$CLX/src/conker-lr-recomp"
DISC="${CLX_DISC:-$CLX/disc}"
GEN="$CLX/gen"
B="$CLX/build"
VERSION="${CLX_VERSION:-00.00}"
XBE_SHA1=2232a1b3874d67b4bb4cf53a940420d2dab59535
export PATH="$PSB/host-tools/bin:$PATH"
mkdir -p "$CLX/logs"

if [ "${1:-}" = libs ]; then
    # The runtime alone, against an empty stand-in for the lifted code.
    GEN="$CLX/gen-stub"
    mkdir -p "$GEN"
    [ -f "$GEN/recomp_funcs.h" ] || echo "/* stand-in: no lifted code */" > "$GEN/recomp_funcs.h"
    B="$CLX/build-libs"
else
    [ -f "$DISC/default.xbe" ] || { echo "no $DISC/default.xbe (unpack your disc there)" >&2; exit 1; }
    sum=$(sha1sum "$DISC/default.xbe" | cut -d' ' -f1)
    # Also accepted: the same retail NTSC code with a region-free certificate (region flags 7, media
    # flags 0x400001FF): every seed, override and data pointer of the recomp checked identical.
    [ "$sum" = "$XBE_SHA1" ] || [ "$sum" = bef166b2d2f72fef6bc051fd7bc36caadada0b54 ] \
        || { echo "default.xbe has SHA-1 $sum, needs the retail NTSC one ($XBE_SHA1)" >&2; exit 1; }
    stamp=$(cd "$SRC" && { sha1sum < "$DISC/default.xbe"; find xboxrecomp/tools config tools src/recomp_manual.c \
            -type f ! -path '*/output/*' ! -name '*.pyc' | LC_ALL=C sort | xargs sha1sum; } | sha1sum | cut -d' ' -f1)
    if [ "$(cat "$GEN/.stamp" 2>/dev/null)" != "$stamp" ]; then
        echo "== lifting the XBE to C (~15 min)"
        rm -rf "$GEN"
        (cd "$SRC" && python3 tools/make_logo.py "$DISC/default.xbe")
        XBOXRECOMP_DIR="$SRC/xboxrecomp" CLX_XBE="$DISC/default.xbe" CLX_GEN_DIR="$GEN" \
            bash "$SRC/tools/regen.sh" > "$CLX/logs/regen.log" 2>&1 || { tail -30 "$CLX/logs/regen.log"; exit 1; }
        echo "$stamp" > "$GEN/.stamp"
    fi
fi

echo "== configure"
ps4_cmake -S "$SRC" -B "$B" -G Ninja -DCLX_PS4=ON -DNFSU2_GEN_DIR="$GEN" \
    -DCLX_PS4_VERSION="$VERSION" -DCLX_PS4_RELEASE=$([ "${CLX_RELEASE:-0}" = 1 ] && echo ON || echo OFF) \
    -DSDL2_DIR="$CLX/sysroot/lib/cmake/SDL2" -Dglslang_DIR="$PS4_SYSROOT/lib/cmake/glslang" \
    > "$CLX/logs/configure.log" 2>&1 || { tail -40 "$CLX/logs/configure.log"; exit 1; }

if [ "${1:-}" = libs ]; then
    echo "== runtime libraries"
    ninja -C "$B" -k 0 platform xbox_kernel xbox_devbus xbox_d3d8 xbox_dsound xbox_apu xbox_nv2a \
        xbox_usb xbox_input xbox_video xbox_nv2a_vk > "$CLX/logs/build-libs.log" 2>&1 \
        || { grep -E "error:|FAILED|undefined symbol" "$CLX/logs/build-libs.log" | head -60; exit 1; }
    echo "runtime libraries built"
    exit 0
fi

echo "== build (the lifted code takes a while the first time)"
# Each lifted chunk needs ~1.5 GB of RAM to compile.
mem_mb=$(( $(awk '/^MemAvailable:/ {print $2}' /proc/meminfo) / 1024 ))
JOBS=$(( mem_mb / 1500 )); [ "$JOBS" -lt 1 ] && JOBS=1; [ "$JOBS" -gt "$(nproc)" ] && JOBS=$(nproc)
ninja -C "$B" -j"$JOBS" > "$CLX/logs/build.log" 2>&1 \
    || { grep -E "error:|FAILED|undefined symbol|missing module" "$CLX/logs/build.log" | head -60; exit 1; }

echo "== package"
STAGE="$B/stage"
rm -rf "$STAGE"
mkdir -p "$STAGE/sce_sys" "$STAGE/game"
cp "$B/clx_recomp_eboot/eboot.bin" "$STAGE/eboot.bin"
if [ -f "$HERE/sce_sys/icon0.png" ]; then
    cp "$HERE/sce_sys/icon0.png" "$STAGE/sce_sys/"
else
    # The XBE's own dashboard image (tools/make_logo.py wrote assets/icon.jpg), at the PS4's size.
    python3 -c "from PIL import Image; import sys; Image.open(sys.argv[1]).convert('RGB').resize((512, 512), Image.LANCZOS).save(sys.argv[2])" \
        "$SRC/assets/icon.jpg" "$STAGE/sce_sys/icon0.png"
fi
[ -f "$HERE/sce_sys/pic1.png" ] && cp "$HERE/sce_sys/pic1.png" "$STAGE/sce_sys/"
# The disc, without what the game writes (it goes to /data/ConkerLR/save) and the lifter's notes.
cp -rl "$DISC/." "$STAGE/game/" 2>/dev/null || cp -r "$DISC/." "$STAGE/game/"
rm -rf "$STAGE/game/UDATA" "$STAGE/game/TDATA" "$STAGE/game/CACHE" "$STAGE/game/"*_analysis.json
PKG="$(bash "$PS4_KIT/scripts/make-pkg.sh" "$STAGE" CLXR00001 "Conker: Live & Reloaded" "$VERSION" CONKERLR "$PSB/out" | tail -1)"
mkdir -p "$HERE/out"
cp "$PKG" "$HERE/out/ConkerLR-v$VERSION.pkg"
mkdir -p "$CLX/oelf"
cp "$B/clx_recomp" "$CLX/oelf/v$VERSION.elf"
ls -la "$HERE/out/ConkerLR-v$VERSION.pkg"
