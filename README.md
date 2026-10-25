# Conker: Live & Reloaded for PS4

A PS4 port of [rashevskyv/conker-lr-recomp](https://github.com/rashevskyv/conker-lr-recomp), the static
recompilation of the original Xbox game (Rare, 2005). The game's x86 code is lifted to C and built for
the PS4 with [ps4-kit](../ps4-kit); the Xbox GPU commands are drawn with the recomp's Vulkan renderer
(`nv2a_vk`) on Mesa RADV.

No game code or data is in this repository. You build it from your **own** unpacked disc: the retail NTSC
(North America) version, whose `default.xbe` has SHA-1 `2232a1b3874d67b4bb4cf53a940420d2dab59535`.

## What the port changes

| Area | PS4 |
|---|---|
| Renderer | `nv2a_vk` on RADV through volk and ps4-kit's VideoOut swapchain (1920x1080, mailbox present); recording and present threads on |
| Guest memory | one 4 GB reservation; RAM, its 28 mirrors and the tiled aperture are direct-memory views that alias (`platform/win32_compat.c`, "Virtual memory on the PS4") |
| Pad | DualShock 4 through scePad (`input/xinput_ps4.c`): Cross/Circle/Square/Triangle = A/B/X/Y, L1/R1 = White/Black, L2/R2 = triggers, Options = Start; **L3 + R3 opens the quick menu** |
| Quick menu | Display (Fit 4:3, Stretch 16:9, Wide 16:9 = the game's Hor+), Upscaling filter (Bilinear, FSR 1), Frame generation (30 shown at 60), Frame rate (native 30/60, restart), render scale, FXAA, anisotropic filter, FPS counter, camera, subtitles, button icons, volume, exit |
| Picture passes | `nv2a_vk/ps4_post.h`: FSR 1 (EASU + RCAS, AMD's MIT headers, built to SPIR-V at build time) and frame generation (`shaders/fg.comp`: DawnStation's v3 in Vulkan compute: whole-picture shift, block search, per-pixel picks, the real frame where nothing fits); the in-between frame is presented a vblank ahead of the real one |
| Sound | SDL2's PS4 audio driver (from the N64 Conker port) |
| Files | the disc is in the package (`/app0/game`, read-only); saves, caches, options and logs in `/data/ConkerLR` |
| Defaults | PlayStation button icons, render scale 200 %, boot movie skipped, cutscenes skip on a press |

## Build (WSL)

```bash
# once: your disc, unpacked (extract-xiso -x Conker.iso -d ~/clx-build/disc)
CLX_VERSION=00.01 ~/clx/scripts/build-clx.sh
```

The first build lifts the XBE (~15 minutes, ~15 GB of RAM) and compiles the lifted code. The package is
`out/ConkerLR-vXX.YY.pkg` (title ID `CLXR00001`); it contains your disc, so never share it.
`build-clx.sh libs` builds only the runtime libraries, without a disc.

Source changes live on branch `ps4` of `~/clx-build/src/conker-lr-recomp`; `scripts/save-patch.sh` exports
them to `patches/clx-ps4.patch` (base in `patches/BASE.txt`).

## On the console

- Logs: `/data/ConkerLR/clx_log.txt` (the last run's in `clx_log-prev.txt`), `crash.log`, `boot-trace.log`.
- Settings: the quick menu (L3 + R3) saves `/data/ConkerLR/clx_options.txt`; advanced switches go
  in `/data/ConkerLR/clx_env.txt` (`KEY=VALUE`, as the Switch's `clx_env.txt`).
