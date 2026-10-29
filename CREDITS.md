# Credits and licences

This repository holds build scripts and one patch (`patches/clx-ps4.patch`) against
[rashevskyv/conker-lr-recomp](https://github.com/rashevskyv/conker-lr-recomp) at the commit in
`patches/BASE.txt`. The patched files keep their own licences.

| Part | Where | Licence |
|---|---|---|
| Conker: Live & Reloaded recomp (rashevskyv), flatout2-sw game layer (antoxa2584x), xboxrecomp (sp00nz) | the upstream repository; the patch changes its `src/`, `CMakeLists.txt` and `xboxrecomp/` | MIT (upstream `LICENSE`, `xboxrecomp/LICENSE`) |
| xemu MCPX APU code | `xboxrecomp/src/apu/` (the patch changes `apu_vp.c`) | LGPL-2.1-or-later (upstream `xboxrecomp/NOTICE`, `xboxrecomp/LICENSES/`) |
| AMD FidelityFX Super Resolution 1 (`ffx_a.h`, `ffx_fsr1.h`) | added by the patch, `xboxrecomp/src/nv2a_vk/shaders/` | MIT (in the files) |
| volk (Arseny Kapoulkine) | added by the patch, `xboxrecomp/src/nv2a_vk/volk.c`, `volk.h` | MIT (in the files) |
| Frame generation (`shaders/fg.comp`, `ps4_post.h`; built, not in the menu) | added by the patch | from DawnStation's frame generation (iHaiDeeZ); MIT, as this repository |
| ps4-kit (iHaiDeeZ): runtime, Mesa RADV for the PS4, VideoOut swapchain, packaging | linked at build time, not in this repository | not published yet |
| Mesa RADV | built by ps4-kit | MIT |
| SDL2 with a PS4 audio driver | linked at build time | zlib |
| glslang | linked at build time (the recomp compiles its shaders at run time) | BSD-3-Clause and others |
| OpenOrbis toolchain (PacBrew) | build host | GPL-3.0 (tools), the C library under its own licences |

The build scripts and this port's own code in the patch (`src/ps4_clx.c`, `xboxrecomp/src/input/xinput_ps4.c`,
`xboxrecomp/src/nv2a_vk/ps4_post.h` and the PS4 branches in upstream files) are MIT, see `LICENSE`.

The game itself (code, art, sound, text) belongs to its owners. Nothing from it is in this repository or its
releases: the build reads your `default.xbe` and your disc on your own machine.
