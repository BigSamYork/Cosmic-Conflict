# Cosmic Conflict 1.0.0: release findings and next steps

**Result:** Built and tested the Windows x64 installer on November 21, 2026. The candidate passed the release checks below. This is a local release artifact, not a publication to a distribution service.

- [Windows installer](../releases/1.0.0/CosmicConflict-1.0.0-Setup.exe) (62,699,804 bytes)
- SHA-256: `4185E50CA35E1BAC165D56D90A4F4B45BD3E184516A3CFAFE16B4A5C43F12C2C`
- [Illustrated player manual](Cosmic_Conflict_Player_Manual_v1.0.0.docx) and [quick reference](FLIGHT_LAB.md)
- [Validation logs](../releases/1.0.0/validation/) and [installer receipt](../releases/1.0.0/validation/installer-lab/results.json)

## What changed and why

| Finding | Fix and evidence |
| --- | --- |
| With countermeasures fitted, the added save button pushed pause actions below the bottom of the 1920 x 1080 viewport. | Put Resume and Save / Load on the same row, with keyboard focus on Resume. Paired the departure and save actions at Astra as well. The native pause layout test failed before the change and passed afterward. |
| The named-game browser was treated as a gameplay music scene. From Pause it could resume playback; from Astra it could request the planet theme. | Use the originating screen for audio decisions, including confirmation prompts. Campaign regression tests exercise both entry points. |
| Continue's legacy-save notice depended on a migration flag that a successful rewrite had already cleared. | Retain the load result until the notice is displayed. No save-schema change. The campaign suite verifies migration, validation and preservation of the original backup. |
| Procedural asteroid generation recomputed rotated crater centers, normalization and angular thresholds for each vertex. | Cache variant centers and thresholds, and reject vertices outside the crater rim before computing an angle. No reduction in mesh detail. See measurement below. |
| The HUD requested a full custom redraw every frame even on static menus. | Retain per-frame HUD draws in flight. Menu construction and resize invalidate the static drawing; UI controls and the instrument atlas retain their own updates. No separate FPS gain is attributed to this change. |
| Some encounter tests depended on a pre-existing campaign in the user profile; a boss animation test advanced combat age but supplied zero time to the visual clock. | Initialize the campaign before building mission terrain in three fixtures. Advance actual visual time for the Overlord rings. The existing behavior assertions remain in place. Run future release gates against an empty, isolated profile. |
| The installer could omit a missing manual without a compilation failure. | Make the manual mandatory and hash-check the installed document. Add a named-save fixture to the upgrade/uninstall preservation checks. |

## Final validation

| Test | Result |
| --- | --- |
| Release build, Godot 4.7.2 | 25 successful headless test invocations, including campaign completion, flight continuity, combat, saving, voice and editor exit. [Build log](../releases/1.0.0/validation/release-build.log) |
| Native presentation and audio | 18 suites passed on Intel Iris Xe / Vulkan. Coverage included pause layout, instruments, gun composition, asteroid visibility, bosses, planetary arrivals, effects, computer voice and music. Per-suite logs are named `native-test_*.log`. |
| Exported Ignis mission | Automated accelerated flight reached Astra through ground assault, both bosses, orbit and asteroids. Verified combat rewards, docking, purchases and checkpoint reload. [Mission log](../releases/1.0.0/validation/export-mission.log) |
| Exported belt, Vulkan, 1920 x 1080, 60 FPS cap | 4,739 measured frames: mean 16.67 ms, p95 17.57 ms, p99 18.07 ms, maximum 63.48 ms. Passed the 33.33 ms p99 budget; not every frame met it. [Benchmark log](../releases/1.0.0/validation/export-belt.log) |
| Exported OpenGL compatibility mode | Training, pause/resume and effects smoke checks passed. This was not a full OpenGL campaign run. [Smoke log](../releases/1.0.0/validation/export-compatibility.log) |
| Installer lifecycle | Installed 0.19.4 under an isolated validation identity, upgraded to 1.0.0, launched the installed game and uninstalled. Verified payloads, shortcuts and preservation of campaign, named save, settings and Hall of Fame fixtures. The validation did not change the normal installation. |

### Reproducing the optimization measurement

Run [benchmark-asteroid-art.gd](../tools/benchmark-asteroid-art.gd) with the project Godot console executable: `--headless --path current_dev --script <absolute-path-to-benchmark>`. It builds three foreground and two giant models seven times, clearing the model cache between samples. On this machine the median fell from **109.59 ms to 33.14 ms** (about **70% less time**). Both runs produced mesh-array SHA-256 `8c4b98bbb7b37b3a4c2b057d18aa0fc06d766f3394788409777e46d779c0a420`. This measures mesh generation, not total launch time or gameplay FPS.

## Limits and possible future enhancements

1. **Distribution:** The installer is unsigned. Before broad public distribution, sign and timestamp the installer and game, test the actual shipping installer in a disposable clean Windows VM, and review distribution rights and the build toolchain's non-commercial designation for the intended channel.
2. **Performance:** Profile the belt's 63 ms worst frame before changing its renderer. Separate asset creation, terrain streaming and MultiMesh uploads in traces. Repeat on AMD/NVIDIA and lower-end hardware, comparing capped and uncapped runs.
3. **Endurance:** Run the existing two-hour soak across renderers. This pass included a full exported Ignis operation, not a continuous six-world tour or a long soak.
4. **Save usability:** Consider phase, sector and last-saved previews in the slot picker, plus a confirmed delete action. Keep named snapshots independent of the automatic checkpoint; do not introduce exact mid-flight saving without a separate simulation-state design.
5. **UI regression coverage:** Exercise the longest translated labels, keyboard-only navigation, different display scaling, and the ejected/no-ship market with every equipment option. A native 1080p pass alone cannot certify all layouts.
