# Conker: Live & Reloaded for PS4

A port of [rashevskyv/conker-lr-recomp](https://github.com/rashevskyv/conker-lr-recomp), the static
recompilation of the original Xbox game (Rare, 2005), to jailbroken PS4 consoles. The game's x86 code is
lifted to C on your PC and compiled for the PS4; the Xbox GPU's commands are drawn with the recomp's
Vulkan renderer on **Mesa RADV**, the PS4's own GPU driver built from Mesa.

> **No game code or data is in this repository**, and none is in its releases. You build the package
> from your **own** copy of the game. The package you build contains your disc, so never share it.

**Status:** the single player game plays: native **60 fps** (most of the time; 30 is one menu row away),
1080p, sound, saves, DualShock 4, an L3 + R3 quick menu. Multiplayer and Xbox Live do not work.

## Features

| | |
|---|---|
| Frame rate | the game's own 60 fps (its step is time-based, so it is a real 60, not interpolated); 30 in the quick menu |
| Picture | rendered at up to 4x the Xbox's 640x480; **1080p** (225%) by default |
| Display | **Fit 4:3** (bars), **Stretch 16:9**, or **Wide 16:9** (the game's view widened, Hor+; HUD and menus stretched) |
| Upscaling | Bilinear, or **FSR 1** (AMD's EASU + RCAS), with FXAA before it |
| Sound | the Xbox's audio chip, as the recomp emulates it (its DSP effects, such as reverb, are not emulated) |
| Pad | DualShock 4: Cross/Circle/Square/Triangle = A/B/X/Y, L1/R1 = White/Black, L2/R2 = triggers, Options = Start |
| Quick menu | **L3 + R3**: display, upscaling, frame rate, render scale, FXAA, anisotropic filtering, FPS counter, camera, subtitles, button icons (PlayStation, Xbox, Switch), volume, exit |

## What you need

- A jailbroken PS4 (tested on a launch model) with a package installer and FTP (GoldHEN).
- Your **own** disc of **Conker: Live & Reloaded**, retail **NTSC (North America)**, as an ISO or unpacked.
  Its `default.xbe` must have SHA-1 `2232a1b3874d67b4bb4cf53a940420d2dab59535`; the same code with a
  region-free certificate (SHA-1 `bef166b2d2f72fef6bc051fd7bc36caadada0b54`) is accepted too.
- A PC with WSL 2 (Ubuntu), about 20 GB free and 16 GB of RAM.
- The OpenOrbis toolchain (PacBrew) and **ps4-kit**, the shared PS4 base of these ports (runtime, Mesa
  RADV for the PS4, VideoOut swapchain, packaging). This release was built with ps4-kit `87a517c`;
  ps4-kit is not published yet.

## Build

1. Unpack your disc into `~/clx-build/disc` in WSL, for example with
   [extract-xiso](https://github.com/XboxDev/extract-xiso): `extract-xiso -x Conker.iso -d ~/clx-build/disc`.
2. Get the upstream recomp at the commit in `patches/BASE.txt` and apply this port:

   ```bash
   mkdir -p ~/clx-build/src && cd ~/clx-build/src
   git clone https://github.com/rashevskyv/conker-lr-recomp && cd conker-lr-recomp
   git checkout 40a54ee && git switch -c ps4
   git apply /path/to/this/repo/patches/clx-ps4.patch
   ```

3. Link this repository as `~/clx` and ps4-kit as `~/ps4-kit`, then build:

   ```bash
   CLX_RELEASE=1 CLX_VERSION=01.00 ~/clx/scripts/build-clx.sh
   ```

   The first build lifts the XBE to C (about 15 minutes, about 15 GB of RAM) and compiles it. The result
   is `out/ConkerLR-v01.00.pkg` (title ID `CLXR00001`, about 4.8 GB with your disc inside). Without
   `CLX_RELEASE=1` you get a development build with every diagnostic on.

4. Copy the package to the console (FTP to `/data/pkg`) and install it.

## On the console

Everything the game writes is in **`/data/ConkerLR/`**: `save/` (the Xbox hard disk's partitions and save
games), `clx_options.txt` (the quick menu's settings), the shader and pipeline caches.

`clx_env.txt` in the same folder takes `NAME=value` lines for advanced switches, for example:

| Line | Effect |
|---|---|
| `CLX_DIAG=1` | diagnostics on: `clx_log.txt`, the `[audio]` report, ps4-kit's crash log, boot trace and thread dumps |
| `RECOMP_GIL_EAGER=0` | guest threads take turns in arrival order (the default hands the game's sound mixer the lock first) |
| `RECOMP_MIRRORS=28` | map all 28 Xbox RAM mirrors (default 1: each view costs the app's flexible memory) |
| `RECOMP_APU_FE_LOCK=0` | the audio chip's commands without its lock (as upstream) |
| `CLX_SKIP_INTRO=0` | play the boot movie |

## How it works on the PS4

| Part | PS4 |
|---|---|
| Build | ps4-kit's toolchain (clang 21, libc++), runtime and packaging; the lifted code at -O2 |
| Renderer | the recomp's `nv2a_vk` on RADV through volk and ps4-kit's VideoOut swapchain (1920x1080, vsync flips); recording and present on threads of their own |
| Picture passes | `nv2a_vk/ps4_post.h`: display modes, FSR 1 (shaders built to SPIR-V at build time) |
| Guest memory | one 4 GB reservation; RAM, a mirror and the GPU's tiled view are aliasing shared-memory views, other memory comes from direct memory in 16 KB pages |
| Files | the disc is read from the package (`/app0/game`, read-only); the Xbox hard disk (E:, T:, U:, Z:) lives in `/data/ConkerLR/save` |
| Sound | SDL2's PS4 audio driver at 48 kHz; the APU and SDL threads above the game's (priority 400) |
| Pad | scePad behind the recomp's console pad interface (`input/xinput_ps4.c`) |

Bugs found on the way that matter for other ports of this recomp:

- **The Xbox hard disk.** Upstream keeps partition 1 (TDATA, UDATA) in the disc folder. A read-only disc
  folder made the game return to the "dashboard" (invalid hard disk) at boot.
- **Extended VMA.** Where a host lets the layout reserve guest memory above the RAM mirrors, Conker puts
  its sound stream buffers at `0x74000000`+. The APU cannot reach them (bit 26 there reads as the
  low-RAM tag), so it played unchanging memory: a hiss over the whole game that sounded like the title
  screen's rain. Linux and the Switch never reserve that range; neither does this port.
- **Sound priority.** Without `RECOMP_GIL_EAGER=1` (the Switch's setting) the game's sound mixer waited
  behind the main thread: crackles at 60 fps.

## Credits

The recomp by [rashevskyv](https://github.com/rashevskyv/conker-lr-recomp), on sp00nz's xboxrecomp and
antoxa2584x's flatout2-sw. PS4 port by iHaiDeeZ. Third-party code and licences: [CREDITS.md](CREDITS.md).

The game belongs to its owners (Rare, Microsoft). This project is not affiliated with them.
