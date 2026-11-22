# Cosmic Conflict: Investigation and Development Roadmap

Last updated: 2026-11-19

Status: **Cosmic Conflict v0.19.0 is ready.** The shutdown checkpoint in section
46 has been resumed and superseded by final acceptance in **section 47**.
Thalassa Reach and Kharon Dunes, two purchasable player battleships, shootable
hull-mounted boss scanners, closer pursuit and exact shorter transitions are
verified. The installer now offers an optional desktop shortcut. All **1,254
checks in twenty-three suites**, a complete six-world/twelve-boss exported
campaign, both-renderer native regressions, normal-speed 1080p benchmarks and
isolated installer/shortcut lifecycle tests pass.
Private-release polish, campaign honors, ambient/computer audio, curved planetary
arrivals and the Word player manual remain included.
This is unsigned and private/testing only: clean-Windows-VM
certification, wider hardware/human accessibility testing, public/commercial
rights, title clearance and signing remain external release gates.
Earlier releases are preserved.

The [current development outline](Cosmic_Conflict_Development_Outline.md) is the
working design/status/backlog document; its Word counterpart is synchronized.
Latest progress, validation results, and offline continuation instructions are
in sections 26-47. Earlier investigation and release entries remain historical;
their old proposals and intermediate test results do not override the current
outline or each release's final verification.

[v0.19.0 Windows installer](../releases/0.19.0/CosmicConflict-0.19.0-Setup.exe) |
[v0.18.1 previous installer](../releases/0.18.1/CosmicConflict-0.18.1-Setup.exe) |
[v0.18.0 previous installer](../releases/0.18.0/CosmicConflict-0.18.0-Setup.exe) |
[v0.17.1 previous installer](../releases/0.17.1/CosmicConflict-0.17.1-Setup.exe) |
[v0.17.0 previous installer](../releases/0.17.0/CosmicConflict-0.17.0-Setup.exe) |
[v0.16.0 previous installer](../releases/0.16.0/CosmicConflict-0.16.0-Setup.exe) |
[v0.15.1 previous installer](../releases/0.15.1/CosmicConflict-0.15.1-Setup.exe) |
[v0.15.0 previous installer](../releases/0.15.0/CosmicConflict-0.15.0-Setup.exe) |
[v0.14.0 previous installer](../releases/0.14.0/CosmicConflict-0.14.0-Setup.exe) |
[v0.13.1 previous installer](../releases/0.13.1/CosmicConflict-0.13.1-Setup.exe) |
[v0.13.0 previous installer](../releases/0.13.0/CosmicConflict-0.13.0-Setup.exe) |
[v0.12.0 previous installer](../releases/0.12.0/CosmicConflict-0.12.0-Setup.exe) |
[v0.11.0 previous installer](../releases/0.11.0/CosmicConflict-0.11.0-Setup.exe) |
[v0.10.0 previous installer](../releases/0.10.0/CosmicConflict-0.10.0-Setup.exe) |
[Prototype controls and build instructions](FLIGHT_LAB.md)

## 1. Confirmed direction

Build an original, single-player, offline 3D rail shooter with an arcade combat
loop and between-mission ship progression. Do not turn the Elite inspiration into
an open-world space simulator unless that is explicitly requested.

The following direction was confirmed through the planning questions:

1. Use Godot 4 with typed GDScript for a native Windows game.
2. Prove the first-person mouse aiming, limited ship movement, and vector-hybrid
   appearance in a small, packaged flight/combat prototype. Use glowing detailed
   edges over dark solid forms, with selective sprites.
3. Complete one planet from ground assault through both bosses, asteroids, and
   the Astra Market before multiplying the content across four planets.
4. Implement the entire expanded outline in stages, not only the original
   requirements. Advanced systems belong in later milestones, not all in the
   first flight prototype.
5. Deliver a Windows installer. A portable export can be an intermediate build,
   but a ZIP alone does not satisfy the distribution requirement.
6. Target 1080p at 30-45 FPS on integrated-graphics laptops, with reduced-effects
   options. On 2026-11-16 the user explicitly prioritized more detailed graphics
   over 60 FPS: 30 FPS minimum, about 45 preferred. This supersedes the earlier
   60-FPS goal; historical release measurements retain their original targets.
7. Use timed normal waves followed by untimed boss fights.
8. Autosave at phase boundaries and after market changes.
9. On ship destruction, eject and transfer the pilot to Astra Market for recovery;
   use the confirmed loss and replacement rules in section 4E.
10. Plan for private sharing initially, no fixed deadline, and original or
    appropriately licensed free assets and free tools.

The user authorized implementation by asking to continue on 2026-11-15 at 14:00.
The prototype/one-planet review gate has since been passed through the user's
positive playtest feedback and repeated instructions to continue the outline.
The full four-planet campaign and final distribution review are still outstanding.

## 2. Evidence reviewed

### Project documents

- [Original AI prompt](Cosmos_Conflict_Original_AI_Prompt.docx).
- [Expanded game design and development outline](Cosmos_Conflict__Game_Design_%26_AI_Development_Outline.docx).
- [Current Markdown working outline](Cosmic_Conflict_Development_Outline.md),
  revised with the Word document on 2026-11-17; see section 29.

At the initial investigation, both source documents were read in full, including the expanded outline's planetary
table and embedded mathematical text. The combo progression is **1x -> 2x -> 4x**;
the proposed increase between subsequent tours is **+25%**. These values are
present in the document, not missing placeholders.

The workspace contained only these two source documents before this report.
There was no existing game code, asset library, dependency manifest, build
configuration, test suite, or Git repository to preserve or extend.

### Local development baseline

The initial read-only inspection found:

- Windows 11 Enterprise, 64-bit.
- Approximately 16 GiB RAM.
- Intel Iris Xe integrated graphics, with a reported 1920x1080 display mode.
- Python installations discoverable through the Python launcher.
- Godot, Git, Node.js, and npm were not discoverable on the current command PATH.
  This does not prove they are absent elsewhere on the machine.

At that initial investigation, no tools were installed or reconfigured. This machine was a useful candidate for
initial testing, not an agreed minimum specification or a demonstrated
performance result. No rendering benchmark had yet been run; later release
sections record the installed toolchain and measured results.

### Reference investigation

The three supplied historical references support different parts of the design:

- **Star Wars (1983):** first-person aiming, short staged encounters, survivable
  incoming projectiles that can be shot, and escalating arcade repetition.
- **The Empire Strikes Back (1985):** large enemies with specific vulnerable
  targets, finite special attacks, and a survival-focused asteroid segment.
- **Elite (1984):** readable 3D wireframe silhouettes with hidden-line removal,
  credits, equipment improvements, docking, and combat status progression.

Borrow these broad gameplay ideas, not their spacecraft, station silhouettes,
characters, sound recordings, music, interface artwork, or mission layouts.
All Cosmic Conflict designs should have their own identity. No external assets
were downloaded during the initial investigation. Title/trademark clearance
has not been performed.

## 3. Requirements: baseline versus expansion

| Area | Required by the original prompt | Added or elaborated by the expanded outline |
| --- | --- | --- |
| Presentation | Detailed vector graphics; selective sprites permitted; original ships, scenery, and enemies | Neon glow, bloom, particles, trails, synthwave audio, shake and flashes |
| Flight | Predetermined route; mouse aims and gently nudges the ship horizontally and vertically | Dodge roll/boost and reactor power routing |
| Weapons | LMB primary; Space secondary; purchasable upgrades and secondary ammunition | Heat/cooldown, three primary tiers, three secondary types, additional utilities |
| Pause | RMB pauses and shows ship status; tactical switching is deferred | Active upgrades and sector-credit display; later weapon-station/chaff controls |
| Ground | Planetary obstacles and ground enemies; mandatory end boss | Approximately 90-120 seconds, weak-point stages, bonus objectives, branching paths |
| Orbit | Distinct enemy abilities; mandatory end boss; approximately 90 seconds total | Specific interceptor, shielded gunship, and web-drone archetypes |
| Asteroids | Avoid and destroy rocks; approximately 60 seconds; no boss | Mineral pickups, volatile rocks, chain reactions, optional pirates |
| Market | Performance credits; ships and upgrades with thumbnail, price, and benefits; next-planet choice | Four named ship archetypes, module families, mineral/accuracy/hull bonuses |
| Campaign | Four distinct planets; summary, rank, medal, Retire or Continue | Named biomes and eight named bosses; local Hall of Fame; retained loadout and +25% tour scaling |
| Developer tools | Backtick menu for credits, ships, upgrades, and level jumps | God mode, ammo/heat toggles, instant kills, detailed phase/boss jumps |
| Delivery | Distributable package; preserve multiple versions | Suggested Python or web stack and per-version source snapshots |

### Content implications

The full baseline is not just four background colors:

- Four ground environments with identifiable scenery and enemy differences.
- Four ground bosses and four orbital bosses: **eight distinct boss encounters**.
- Four ground, four orbital, and four asteroid segments.
- A reusable market visited after each planet.
- Ship purchasing, primary/secondary progression, HUD, pause, map, debug tools,
  debrief, ranks, medals, and repeat-tour state.

The approved expanded catalog includes four regular player ship archetypes,
three primary tiers, three secondary families, and the outlined defensive/utility
upgrades. The recovery rules also require a weak emergency ship or loadout.
Its visual design can be resolved during the ship-design milestone.

| Proposed planet | Identity | Distinctive hazard | Ground / orbital boss concepts |
| --- | --- | --- | --- |
| Ignis Prime | Volcanic; red/orange/gold | Lava and heat vents | Vulcan Crawler / Solar Flare Cruiser |
| Cryo-Vex | Glacial; cyan/blue/white | Ice pillars and crystals | Glacier Bore-Mech / Cryo-Carrier Hydra |
| Vespera-9 | Cybernetic city; magenta/purple/teal | Moving laser gates and transit traffic | Overlord Defense Core / Stealth Dreadnought Nyx |
| Xylo-Mire | Alien swamp; green/yellow | Spores and corrosive geysers | Bio-Titan Goliath / Hive Mother Leviathan |

These names and mechanics are the approved starting concepts from the expanded outline.
Ignis is now playable; its ground boss is named **Vulcan Siege Runner** in the
game. The remaining three planets and six bosses are still proposed content.

## 4. Important design gaps and risks

### A. Aiming and dodging compete for the same input

Moving the mouse toward an enemy must not unexpectedly force the ship into an
obstacle. The proposed model is an immediately responsive aiming reticle plus
a separately smoothed, bounded ship offset in the rail's local horizontal and
vertical plane. Camera motion must not create a feedback loop that makes the
reticle drift away from its target.

Prototype sensitivity, offset limits, camera banking, and obstacle clearance
before committing to level geometry. First-person cockpit/HUD view is confirmed.
Separate keyboard movement is an alternative control scheme, not something to
add silently.

### B. Timed stages conflict with mandatory boss kills

The original prompt calls for the entire dogfight to last about 90 seconds while
requiring its boss to be defeated. A slow player cannot be guaranteed both an
exact finish time and an unrestricted opportunity to defeat the boss.

Confirmed resolution: timed regular waves followed by an untimed boss encounter.
This deliberately clarifies the original approximate total-time requirement.
Never automatically declare a surviving boss defeated to meet the timer.

Ground and orbit each need a boss approach/holding pattern so the flight rail
does not end while the fight is still active. Asteroids remain a timed survival
segment with no boss.

At the outlined wave durations, four planets contain approximately **16-18 minutes
of regular combat/hazard time**. Bosses, docking, transitions, shopping, and
recovery attempts add to that; bosses are outside the wave timers.

### C. Vector detail can reduce clarity

Drawing every mesh edge can expose unwanted triangulation and make ships,
terrain, and projectiles hard to distinguish. Excessive glow can obscure weak
points and cause substantial GPU cost on integrated graphics.

Use intentionally authored feature edges and dark depth-writing surfaces for
hidden-line removal. Keep damaging projectiles and weak points visually distinct
by shape as well as color. Test antialiasing, apparent line width, and restrained
glow at the actual output resolution.

Current performance goal: 1080p at 30-45 FPS on integrated-graphics laptops, with
a reduced-effects setting. Prioritize richer detail over 60 FPS, per the user's
2026-11-16 revision. Name the exact benchmark machine and quality setting;
measure frame-time percentiles rather than promising every frame meets budget.

### D. Collisions must match the camera and artwork

The reticle needs a coherent aim ray; visible weapon effects must converge on
the intended hit position. Solid collision volumes should represent ships and
obstacles rather than their individual decorative lines. Fast projectiles need
swept hit detection or an equivalent method to avoid tunneling through targets.

Boss shields, weak points, cover, and interceptable enemy shots must obey one
consistent hit-resolution order. All mandatory bosses and obstacle routes must
remain beatable with the weak emergency ship and its basic primary weapon, with
no paid secondary ammunition. Otherwise the approved recovery system can soft-lock.

### E. Confirmed ejection, recovery, and saving rules

Ship destruction does not kill the pilot or end the campaign:

1. The pilot ejects; the pod transfers to Astra Market. A short automatic sequence
   is the proposed presentation, not a separate pod-survival game.
2. The destroyed ship and its equipped upgrades/ammunition are lost.
3. Unspent credits remain available. Credits earned up to ejection are retained,
   but no completion or survival bonuses are awarded for the failed mission.
4. The pilot may buy an affordable replacement at the market.
5. If no replacement ship is affordable, provide a free, weak emergency ship
   so the campaign can continue. No loan or debt system is required.
6. The player restarts the unfinished planet via station departure and ground
   assault. Selecting among unfinished planets remains future work; only Ignis
   is currently available.
7. Previously completed planets remain completed. Partial progress on the failed
   planet does not count as completion.

The market must prevent departure without a valid ship. Record ship losses and
ejections explicitly in campaign statistics; the pilot has survived.
Already banked earnings must not be paid a second time when the recovery
settlement runs.

Autosave at phase boundaries and after market changes, including the ejection
settlement. Save a valid recovery state if the player exits before purchasing.
Loading must not resurrect the destroyed ship, duplicate settlement credits, or
leave the player permanently stranded. This replaces the initial recommendation
of phase-start death retries with state rollback.

The user subsequently confirmed free full hull/shield repairs when docking.
Voluntary hull purchases replace the current hull and transfer fitted upgrades;
ammunition is limited to the new hull's bay capacity. The destruction-loss policy
remains unchanged.

### F. Market and scoring require precise accounting

Track wallet balance separately from credits earned and spent. Spending should
not accidentally lower a performance rank simply because the player bought an
upgrade. A mission settlement must apply only once, including after loading or
reopening the market.

Define how accuracy treats multi-shot volleys, continuous beams, intercepting
enemy fire, and shooting asteroids. Display combat and mining/interception
statistics separately where one percentage would be misleading.

The original read-only tactical-overlay proposal has been superseded. Owned
secondary stations can now be selected while paused or docked. Concussion,
Swarm and EMP consume 1/2/3 shared ordnance units; C deploys the separate
chaff/flare inventory during combat. See sections 27-28.

### G. Repeat tours need bounded difficulty

The expanded outline says +25% per tour but does not define additive versus
compound increases, caps, or separate tuning for each statistic.

Applying compound increases independently to speed, projectile count, and boss
health can quickly create unfair encounters and excessive rendering load.
Use authored difficulty curves and explicit population/speed limits; tune reward
growth alongside them. Resolve what Retire preserves and what Continue resets.

### H. Debug tools must not corrupt normal play

Phase jumps must clean up enemies, shots, audio, timers, and temporary boss state.
They also need valid prerequisite state, rather than only changing the scene.
Pause and debug overlays must not resume gameplay while another overlay is open.

Recommendation: make testing runs visibly marked and ineligible for ordinary
Hall of Fame records if that feature is approved. Decide whether the public
release retains the backtick menu or only development builds expose it.
Neither document specifies arbitrary code execution; a bounded testing panel is
sufficient.

## 5. Technology assessment

| Candidate | Suitability | Main tradeoff |
| --- | --- | --- |
| **Godot 4 + typed GDScript** | Recommended for a native 3D rail shooter: built-in 3D scene graph, path following, collision, UI, audio, profiling, and Windows export | New tooling to locate/install; vector appearance still requires deliberate art/shader work; renderer choice must be measured on target hardware |
| **Three.js + TypeScript + Electron** | Good alternative if a browser edition and web-based UI are important | Three.js is primarily a rendering library; more game lifecycle, tooling, and packaging integration must be assembled; Electron includes Chromium/Node and has ongoing runtime maintenance |
| **Python + Pygame-CE** | Suitable for a simpler projected-wireframe arcade prototype | Its drawing API renders shapes to surfaces; perspective, clipping, depth/occlusion, and modern effects would need additional custom work |
| **Python + ModernGL with a window/input library** | Can provide GPU rendering while retaining Python | Requires more custom renderer, resource, UI, and gameplay infrastructure than using an existing game engine |

The expanded outline's Python recommendation is feasible, but it is not a reason
to build a custom 3D engine unnecessarily. The requested visual quality and
multi-stage gameplay make an existing 3D engine a better default engineering fit.

Godot's Windows exporter produces a runtime executable and project data; players
do not need the editor. PyInstaller can also bundle Python without requiring
players to install Python, but packaging is platform-specific and assets/native
dependencies still require validation. A single executable is not automatically
more reliable than a portable folder.

Godot 4 with GDScript is now confirmed. Choose and pin the exact release when
implementation is authorized. Verify the selected
renderer and export templates in the prototype; do not assume all renderer
backends support identical post-processing effects.

Windows export is only the application build, not the complete installer.
Select free installer tooling, establish install/uninstall behavior, and validate
the actual installer early. Signing and any resulting Windows reputation warnings
must be handled explicitly; private distribution does not remove that concern.

## 6. Proposed architecture and version organization

Keep the architecture small and use the engine's existing facilities:

- **Campaign state:** tour, completed planets, wallet, ship, loadout, statistics.
- **Mission controller:** explicit transitions for ground, ground boss, ascent,
  orbit, orbital boss, asteroids, docking, ejection/recovery, market, map, and summary.
- **Rail/player controller:** route progress, local offset, camera, aiming, input.
- **Combat components:** health, shields, weapons, hit resolution, enemy behavior.
- **Data definitions:** planet palettes/routes/waves, ship stats, upgrades, prices.
- **UI:** HUD, read-only tactical pause, market, map, debrief, debug panel.
- **Persistence:** versioned saves with validation, atomic writes, visible errors,
  and separate user settings.

Menus must not own combat or economy rules. Rendered effects must not be the
source of truth for damage. Prefer hand-authored, testable encounter layouts;
use seeded variation for decoration and bounded spawn variation, not arbitrary
procedural hazards that can make a route impossible.

Proposed project layout:

```text
Cosmos_Conflict\
  Docs\             Original outlines, this plan, later controls/build notes
  current_dev\      One authoritative active game project
  releases\         Immutable, labeled distributable builds
  versions\         Optional source archives for accepted milestones
```

Use local Git history and release tags for source versioning after approval.
If source snapshots are desired, generate them from the tagged version rather
than editing several copied codebases. No remote hosting or publication is
required or assumed.

Keep installed-game saves in a writable per-user application-data location, not
beside the executable or inside the source asset directory. Build documentation,
licenses, version identifiers, and optional checksums should accompany releases.

## 7. Phased to-do list

Each milestone ends in a reviewable result. The next implementation stage starts
only after its prerequisites and any user review gate are satisfied.

### M0 - Agree on direction

- [x] Read both outlines, including tables and embedded equations.
- [x] Inspect existing workspace and local development prerequisites.
- [x] Investigate the supplied references and relevant official technology docs.
- [x] Separate baseline requirements from expanded proposals.
- [x] Identify control, timing, performance, persistence, and economy risks.
- [x] Confirm platform, visual/camera direction, feature scope, and engine.
- [x] Confirm failure/save rules and timer-versus-boss behavior.
- [x] Confirm that the flight/visual prototype precedes the one-planet slice.
- [x] Receive an explicit instruction to begin implementation and tool setup.

**Exit:** an agreed brief, a short approved feature list, and no unresolved
architecture-blocking decisions.

### M1 - Establish the project and early packaging

Depends on M0.

- [x] Locate or obtain approved development tools and pin their versions.
- [x] Create the active project, local version control, and ignore rules.
- [x] Establish typed code conventions, input actions, and configuration data.
- [x] Create a launchable Windows export and document build steps.
- [x] Select free installer tooling and build an initial Windows installer.
- [x] Verify local installation, launch with development tools absent from PATH,
      and uninstall behavior in an isolated installation directory.
- [ ] Repeat distribution testing on a genuinely fresh Windows machine before
      a public release; the current test reused the development machine.

**Exit:** a reproducible empty-project installer; export/installation problems found before
substantial game development.

### M2 - Prove flight, camera, and vector appearance

Depends on M1.

- [x] Create one original player ship and a short original rail environment.
- [x] Implement mouse reticle and bounded horizontal/vertical ship movement.
- [x] Add primary fire, target dummies, representative obstacles, and hit feedback.
- [x] Add HUD, RMB pause/status, focus-loss pause, and safe resume behavior.
- [x] Compare vector edge treatments, occlusion, glow, and effect-quality levels.
- [x] Package the prototype and run automated targeting, pause, and frame-rate checks.
- [x] Profile the complete course on Intel Iris Xe at 1920x1080.
- [x] Obtain the user's playtest feedback and approval of control feel and visuals.

**Exit:** user-approved controls and visual direction. Ship position, collisions,
and weapon cadence remain consistent at different rendering frame rates.
The selected performance target is measured, not inferred from average FPS alone.

### M3 - Build reusable combat and mission foundations

Depends on M2.

- [x] Implement shields, hull, damage, enemy shots, and projectile interception.
- [x] Implement primary upgrades and one purchasable secondary with finite ammo.
- [x] Implement contrasting turret and fighter behaviors.
- [x] Implement boss shield/weak-point states.
- [x] Implement mission transitions, simulation timers, and object cleanup.
- [x] Implement ejection, loss of equipped ship/items, and recovery-state saving.
- [x] Add the developer panel early: credits, loadout, refill, and phase jumps.
- [x] Add focused tests for damage, ammo, transitions, pause, and ejection state.

**Exit:** common mechanics work independently of planet content. Mandatory
encounters remain possible with emergency equipment and no secondary ammo;
ejections and jumps leave no stale combat state.

### M4 - Deliver one complete planet

Depends on M3. Recommended first planet: Ignis Prime.

- [x] Build the ground assault, distinctive hazards, and ground boss.
- [x] Build the orbital transition, enemy waves, and a different orbital boss.
- [x] Build the 60-second asteroid survival segment and docking.
- [x] Build Astra Market with thumbnails, prices, benefits, and live stat changes.
- [x] Include a meaningful alternative ship, primary upgrade, and secondary purchase.
- [x] Apply performance rewards exactly once; reject unaffordable purchases clearly.
- [x] Add safe-boundary autosaving and a one-planet completion result.
- [x] Complete ejection-to-market recovery, lost-equipment handling, and the
      free emergency-ship path for pilots unable to afford a replacement.
- [x] Add original synthesized combat audio and mute control.
- [x] Exercise the source-build loop without invincibility, including shopping,
      checkpoint reload, secondary fire, forced ejection, and emergency recovery.
- [x] Finish validation of the final packaged build with cockpit and gun variants.
- [x] Receive the user's positive feedback on the playable slice and authorization
      to continue the development outline.

**Exit:** an installable, end-to-end playable slice demonstrating that combat
earnings produce useful market choices and that losing a ship cannot strand
the pilot. Other planets are not presented as finished content.

### M5 - Complete the four-planet campaign

Depends on M4 and approval of the playable slice.

- [ ] Build Cryo-Vex, Vespera-9, and Xylo-Mire with distinct scenery and enemies.
- [ ] Add six further boss encounters, for eight total.
- [ ] Complete the approved ship/weapon/module catalog.
- [ ] Integrate the full expanded feature checklist below in reviewable increments.
- [ ] Add planet selection and correct completed-planet tracking.
- [ ] Add campaign statistics, rank thresholds, and original medal artwork.
- [ ] Implement Retire and Continue with the approved reset/retention rules.
- [ ] Add capped, playtested tour scaling and the local Hall of Fame.
- [ ] Test all legal planet orders, campaign completion, and subsequent tours.

**Exit:** four unique planet loops and the expanded systems are complete, the
summary appears at the right time, and Continue/Retire preserve only the intended state.

### M6 - Balance, accessibility, and release validation

Depends on M5. Basic checks also run throughout M1-M5.

- [ ] Balance enemy patterns, starting equipment, prices, repairs, and progression.
- [ ] Verify saved-game recovery, malformed-save errors, and save-version handling.
- [ ] Test performance in dense asteroid scenes, bosses, and later tours.
- [ ] Add approved audio/visual polish without obscuring important gameplay cues.
- [ ] Provide sensitivity, readable UI scaling, and reduced flash/shake/glow options.
- [ ] Verify keyboard focus, window resizing, pause stacking, and mouse capture.
- [ ] Separate test-assisted scores from normal records if applicable.
- [ ] Package licenses, controls, build/version notes, and release artifacts.
- [ ] Test the distribution offline without installed development tools.
- [ ] Verify the required Windows installer and decide signing and any
      public-release debug-menu policy.

**Exit:** reproducible release build, no known campaign-blocking defects, measured
performance on the agreed machine, and a verified distributable package.

### Approved expanded feature checklist - staged after core validation

- [x] Weapon heat and cooling progression, including the outlined
      two-second overheat cooldown.
- [x] Emergency evasive maneuver and defensive/cooldown rules; gentle bank chosen
      by the user instead of a full spin.
- [x] Three-way reactor power routing for weapons, shields, and engines.
- [x] Combat-streak score/credit multipliers, including the outlined 1x/2x/4x tiers.
- [x] Separate end-of-mission accuracy bonus and visible debrief accounting.
- [x] Distinct Quad Plasma projectiles and continuous wider/brighter piercing Tachyon Beam.
- [x] Radar-dish side objectives and downstream tracking suppression.
- [x] First optional safe/hazard ground route with continuous fork/rejoin.
- [x] Mineral collection, tractor beam, and volatile asteroid chains.
- [x] Optional pirate bounty encounters.
- [x] Orbital web-layer drones and shootable tripwire nodes.
- [x] Hull-plating utility progression.
- [x] Ignis-specific heat vents and the orbital boss's thermal sweep.
- [ ] Other planetary interactions: reflective crystals, security gates and spores.
- [x] Shield, shared-ordnance and separate flare pickups; shootable track-switch conduit.
- [x] Tactical secondary weapon-station switching, Swarm Rockets, and EMP Nova.
- [x] Chaff/flares with separate inventory, cooldown and market reload.
- [ ] Further defensive ordnance variants.

These are now included in the approved project scope, not optional omissions.
Integrate them progressively after the one-planet core slice and before the
full expanded release, with tuning for controls, difficulty, UI, and economy.

## 8. Concrete validation plan

Full-campaign checks remain planned. Current one-planet evidence is in sections
26-28 and the working outline; section 12 records only the original prototype:

| Area | Required evidence |
| --- | --- |
| Controls | 30/45-Hz continuity and pause; preserve the existing 30/60/120-Hz movement/fire checks; bounded movement through rail turns; user playtest feedback |
| Pause | Ship, enemy movement, damage, cooldowns, ammo use, spawns, and mission clock stop; nested overlays cannot accidentally resume combat |
| Timing | Asteroid phase lasts 60 seconds of active simulation within one simulation tick, excluding docking; ground/orbit follow the approved timer/boss policy |
| Damage | Shots do not pass through cover; fast projectiles register hits; shields and boss weak points enforce their rules |
| Economy | No negative balances, duplicated settlements, or duplicated owned upgrades; ejection preserves earned credits without paying them twice or granting completion bonuses |
| Recovery | Lost ship/upgrades/ammo stay lost; affordable replacement or free emergency ship is always available; unfinished planets restart through launch into ground assault |
| Saves | Correct loadout and campaign/recovery progress after restart; invalid data produces an explicit error and preserves recoverable data |
| Campaign | Eight boss encounters; four planet completions per tour; all permitted planet orders; correct summary and next-tour reset |
| Debugging | Jumping to each supported phase creates valid state and cleans up the previous phase |
| Performance | 1080p, 30 FPS minimum / about 45 preferred; prioritize visual detail and collect frame-time percentiles, spikes, and entity counts under representative peak load |
| Packaging | Install, launch, play offline, and uninstall without the engine editor, Python, or Node being installed on the recipient's machine |

The current minimum-performance test uses a p99 frame-time budget of 33.33 ms
at 1920x1080 on Intel Iris Xe; report spikes separately. Future scenes, hardware
and tour scaling need fresh measurements, not an extrapolation from launch.
Do not invent a delivery date before the first packaged slice demonstrates the
required fidelity and content-production effort.

## 9. Decision record and remaining decisions

Both rounds of questions were answered on 2026-11-15. The answers are incorporated
in section 1, the milestone checklist, and the detailed recovery rules in section 4E.

The original prototype and first-planet review gates are passed, not current
blockers. Godot/Inno Setup, Vulkan plus OpenGL fallback, detail-first 1080p,
free docking repairs, equipment transfer/loss rules, shared secondary ordnance
and separate flare inventory have been selected and implemented.

Resolve these at their relevant implementation milestone:

- Further branch layouts; the first fork's defaults, rewards and three supply
  types were explicitly approved on 2026-11-17 and are implemented.
- Further weapon balance across later planets; primary targeting, heat and
  shot/accuracy semantics were approved and implemented in v0.13.0.
- Initial sector choice and available-sector replays are now approved in section 32.
- Rank tone/thresholds, Retire/Continue resets and bounded tour-scaling formulas.
- Renewed approval before expanding the playable scout/interceptor hull boundary.
- Signing, commercial-tool licensing and public-release debug-menu policy.

The current outline's section 9 gives the recommended remaining-work sequence;
these unresolved decisions are not silently approved defaults.

## 10. Sources and limits

Historical descriptions were checked against the three links supplied in the
documents; they are design references, not asset sources:

- [Star Wars (1983), gameplay](https://en.wikipedia.org/wiki/Star_Wars_%281983_video_game%29#Gameplay).
- [The Empire Strikes Back (1985), gameplay](https://en.wikipedia.org/wiki/Star_Wars:_The_Empire_Strikes_Back_%281985_video_game%29#Gameplay).
- [Elite, gameplay](https://en.wikipedia.org/wiki/Elite_%28video_game%29#Gameplay).

Technical references:

- [Godot features and renderers](https://docs.godotengine.org/en/stable/about/list_of_features.html).
- [Godot PathFollow3D](https://docs.godotengine.org/en/stable/classes/class_pathfollow3d.html).
- [Godot Windows export](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_windows.html).
- [Godot license and third-party notice requirements](https://docs.godotengine.org/en/stable/about/complying_with_licenses.html).
- [Pygame-CE drawing API](https://pyga.me/docs/ref/draw.html).
- [PyInstaller operation and distribution constraints](https://pyinstaller.org/en/stable/operating-mode.html).
- [Three.js API catalog](https://threejs.org/docs/).
- [Electron overview](https://www.electronjs.org/docs/latest).
- [Electron release/support policy](https://www.electronjs.org/docs/latest/tutorial/electron-timelines).

Some individual Three.js documentation routes returned HTTP 404; the API catalog
was accessible. No claim about a specific Three.js release or measured engine
performance is based on those unavailable pages.

This investigation establishes requirements, tradeoffs, and a validation plan.
It does not establish benchmark results, finished art quality, final balance,
verified package compatibility, or a completed game.

## 11. Historical offline progress handoff

Checkpoint: 2026-11-15, following the warning that internet access will shortly
be unavailable.

### Work completed

- Read both original Word documents completely and compared their requirements.
- Reviewed the supplied historical game references and relevant engine,
  packaging, and licensing documentation.
- Inspected the local workspace, available command-line tools, and graphics baseline.
- Produced the investigation, architecture proposal, milestone checklist, risks,
  and validation criteria in this document.
- Collected two rounds of user decisions and incorporated every answer above.
- Preserved the source Word documents unchanged.

### Confirmed decisions to preserve when resuming

- **Engine:** Godot 4 with GDScript.
- **Delivery:** Windows desktop with an installer, not just a portable ZIP.
- **Performance target:** 1080p/60 FPS on integrated-graphics laptops, with
  reduced-effects options; not yet benchmarked.
- **Presentation:** first-person cockpit/HUD; glowing detailed vector edges over
  dark solid forms, with selective sprites.
- **Scope:** the entire expanded outline, implemented in stages.
- **First review:** a small flight/visual prototype, then one complete planet.
- **Timing:** timed regular waves followed by untimed mandatory boss encounters.
- **Saves:** autosave at phase boundaries and after market changes.
- **Destruction:** pilot ejects and transfers to Astra Market; destroyed ship,
  equipped upgrades, and ammunition are lost.
- **Money after ejection:** retain unspent credits and credits earned before
  ejection; no failed-mission completion/survival bonuses.
- **Recovery:** buy a replacement if affordable; otherwise receive a free, weak
  emergency ship. There is no debt system or forced campaign end.
- **Next destination:** choose any unfinished planet and restart that planet at
  ground assault. Previously completed planets stay complete.
- **Constraints:** private sharing initially, no fixed deadline, free tools,
  and original or appropriately licensed free assets.

### Not started

There is no game implementation, Godot project, generated art/audio, installed
engine/export template, installer project, build, benchmark, or test result.
No dependencies were installed, no Git repository was initialized, no remote
repository was created, and no material was published.

The planning answers were explicitly collected without authorizing implementation.
The user has now requested preservation of progress, not a change to that boundary.

### Resume procedure

1. Read this handoff and sections 1, 4E, and 7 before taking further action.
   Do not revert to the initial Python recommendation or phase-retry death model.
2. Await an explicit request to begin development.
3. Once authorized, check locally for Godot, matching export templates, Git,
   and suitable free installer tooling. Godot/Git/Node/npm were not found on
   PATH during this investigation; they might exist elsewhere.
4. If offline, use available local tools only. Missing engine binaries, export
   templates, or installer tools may block execution and packaging. Report the
   exact missing prerequisite rather than claiming that a build is verified.
5. Start M1, then M2. Do not jump directly to four planets or attempt to implement
   all expanded systems before the flight/visual review.
6. Preserve the first playable review gate before the full one-planet slice.
7. During recovery implementation, test the no-money path and ensure every
   mandatory encounter is possible with emergency equipment.

### Offline source and research availability

The two source Word documents and this Markdown report are local. Web research
findings and source URLs are summarized here; complete web-page snapshots,
engine binaries, export templates, asset packs, and dependency packages were
not downloaded for offline use.

If the Word documents need to be re-examined without Office, they are ZIP-based
DOCX archives. Text is in `word/document.xml`. Preserve both ordinary Word text
and Office Math text: the combo tiers and +25% tour increase were stored as
embedded equations. The expanded document was open in another process during
inspection; read-only access using file sharing succeeded without modifying it.

No further internet requests were made to prepare this handoff. Documentation
changes require no game tests; the game and its test suite do not yet exist.

## 12. Implementation checkpoint: playable v0.1.0

Date: 2026-11-15. This section supersedes the pre-implementation status in the
historical handoff above.

### Delivered

- [Windows installer](../releases/0.1.0/CosmosConflict-0.1.0-Setup.exe):
  28,171,721 bytes, approximately 26.9 MiB.
- [Player/developer guide](FLIGHT_LAB.md).
- [License notes](LICENSES.txt), with full engine and bundled-component notices
  available in the game's Credits & Licenses panel.
- Active Godot project under `current_dev`, build/bootstrap scripts under `tools`,
  and cached portable tools under `.tools`.
- Local Git repository initialized on branch `main`. No commits, remote
  repository, or publication have been made.

Installer SHA-256:

```text
0EB7B4DE058E1F9EB46436652890AA783B03EF37B8D44C2668745483DE9DA127
```

### What is playable

A 75-second first-person Ignis training course with original terrain, a Rook
training craft, a starfield and moon, 33 target drones, and alternating obstacle
pylons. The prototype includes:

- Mouse aiming and gently smoothed, bounded corridor movement.
- Twin pulse firing, ray-based target hits, cover blocking, and hit effects.
- Swept collision checks, contact counts, and regenerating training shields.
- Cockpit/HUD instruments, reticle, target-distance markers, and course telemetry.
- Pause/status overlay, focus-loss pause, and explicit resume.
- A course-completion result screen and replay.
- Three flight-response options, reduced glow, mute, impact-motion preference,
  fullscreen toggle, and local preference persistence.
- Original synthesized weapon/impact sounds.
- Native smoke-test and full-course benchmark modes.

Training is explicitly non-lethal. Campaign ejection, purchases, and emergency
replacement ships have not been replaced by this training behavior.

### Technology actually used

- Godot **4.7.2-stable**, standard GDScript build, OpenGL Compatibility renderer.
- Screen-space vector strokes with an adjustable halo over dark depth-writing
  geometry; no heavy full-screen bloom requirement.
- Git for Windows **2.56.1**, portable MinGit.
- Existing **Inno Setup 6.7.3** compiler, reporting non-commercial use mode.
  This matches the current private/non-commercial sharing plan. Reassess its
  licensing or select another installer tool before any commercial release.

The engine ZIP was verified against the official SHA-512 manifest. Git was
verified against the official release's SHA-256 digest.
Only the two Windows x86_64 export templates were downloaded from the official
multi-platform archive using HTTPS byte ranges and entry size/CRC-32 checks.
The abandoned full-archive download and its partial file were stopped/removed.
No global Godot/Git installation is needed for this checkout.

### Verification completed

1. Godot import, script parsing, and release export succeeded.
2. **22 focused assertions passed:** travel, bounded steering and firing cadence
   at 30/60/120 time steps; pause freezing; collision cooldown; exact course end;
   rail-coordinate scale; target damage/destruction; duplicate-hit prevention;
   cover occlusion; and focus-loss pause.
3. Native GPU smoke checks passed, including screenshots of briefing, flight,
   pause, and reduced effects. Screenshots were visually inspected.
4. The actual installer was run into an isolated validation directory.
5. The installed executable ran from a different working directory with only
   Windows System32 on PATH, without relying on the source project or editor.
6. The installed game completed its full 75-second course:
   **600 shots, 66 valid hits, 33 drones disabled, 75.000 active seconds**.
7. The packaged game was also exercised under actual **30, 60, and 120 FPS render
   caps**. Each short scenario produced **48 shots, 14 hits, 7 disabled drones,
   and 6.000 active seconds**, with pause/resume and corridor checks passing.
8. Uninstall succeeded; both the installed executable and its uninstall
   registration were confirmed removed. No test game process was left running.

Full-course installed-build performance on the local Intel Iris Xe, at
1920x1080 with normal glow, uncapped rendering:

| Metric | Result |
| --- | --- |
| Samples after warm-up | 9,222 frames |
| Mean frame time | 7.92 ms |
| 95th percentile | 10.13 ms |
| 99th percentile | 11.93 ms |
| Maximum | 29.07 ms |
| 60 FPS frame budget | 16.67 ms |

The 99th-percentile check passed the 60 FPS budget. There were occasional
longer frames; this is not a claim that every frame stayed below 16.67 ms.
These results concern the training course, not future dense boss battles or
every integrated-graphics laptop.

Native automated runs mute playback but exercise the real audio path. Headless
logic tests explicitly skip playback because no output device is present.

Logs and screenshots are under `releases\0.1.0\validation`. A fresh Windows
machine and a human control-feel playtest are still needed; an isolated
installation on the development PC is not equivalent to a clean-OS test.

### Current boundaries

- This is the agreed prototype review milestone, not the complete game.
- Bosses, campaign planets, market/economy, secondary weapons, upgrades, advanced
  combat systems, campaign saves, ranks, and ejection recovery remain pending.
- The installer is unsigned; Windows publisher/reputation warnings are possible.
- No deadline was inferred and no paid tools/assets were acquired.
- Source files remain uncommitted. Do not assume a release tag or source archive
  already exists.

### Resume from here, including offline

1. Obtain the user's feedback on aiming versus dodging, readability, cockpit
   motion, and visual detail using the installer and the player guide.
2. Make focused adjustments to this prototype if requested.
3. Once the prototype is approved, proceed to M3 and then the one-planet slice.
   Preserve all confirmed ejection and economy rules in section 4E.
4. Existing cached tools allow offline tests/builds:

   ```powershell
   .\tools\build.ps1 -TestOnly
   .\tools\build.ps1
   ```

5. Use `tools\bootstrap.ps1` only if the engine/templates need restoration; its
   remote template verification needs a connection. The current cached files
   have already been verified and are ready for offline builds.
6. Keep later release versions separate from `releases\0.1.0`; do not overwrite
   the accepted prototype once review is complete.

## 13. Review update: visual detail, steering, and ground combat

Date: 2026-11-15. Version: **0.1.1**.

The user liked the first playable version and requested:

1. More detail on the pilot's ship, ground, and towers.
2. Detail appearing farther ahead.
3. At least twice the mouse steerability.
4. Ground turrets firing missiles at the pilot.

All four requests are implemented in this update.

### Visual changes

- Player ship: additional canopy framing, wing panels, cannons, engine housings,
  exhaust rings, cooling vents, and navigation markings.
- Cockpit: detailed gun housings/muzzles, cooling fins, support brackets,
  dashboard panels, calibration marks, and instrument surrounds.
- Ground: maintenance tracks, grates, rock formations, industrial stations,
  piping, and more legible terrain grid detail.
- Towers: structural bracing, armor panels, ladders, vents, hazard markings,
  rooftop equipment, and more recognizable silhouettes.
- Static details are batched into shared opaque/stroke meshes rather than
  assigning a separate draw call to every small part.

View distance increased from **620 to 1,200 meters**. Stroke detail stays at
full strength to **850 meters**, then fades to **1,150 meters**; the previous
fade ran from 300 to 610 meters. Ground generation extends beyond the complete
course plus the new view distance.

Native rendering exposed a fixed clip-space depth offset that clipped distant
strokes. It was replaced with a projection-derived, view-space bias. The native
tests confirm both distant visibility and correct hiding behind opaque scenery.
Reduced glow retains the same detailed geometry and viewing distance.

### Steering changes

| Setting | v0.1.0 | v0.1.1 |
| --- | --- | --- |
| Horizontal movement limit | +/-6 m | +/-12 m |
| Vertical movement limit | +/-3.6 m | +/-7.2 m |
| Soft response rate | 2.5 | 5.0 |
| Balanced response rate | 4.5 | 9.0 |
| Responsive response rate | 7.0 | 14.0 |

The reticle still follows the mouse directly; ship translation has twice the
range and twice the response rate. Existing preference selections are retained.
A behavioral check verifies at least double the displacement in both axes for
the same mouse input.

### Ground combat

- Thirteen targetable ground turrets with rotating launcher heads.
- A visible charge beacon precedes firing; launchers alternate barrels.
- Turrets engage only ahead of the pilot and inside their attack range.
- Missiles lead the pilot's rail motion, briefly adjust their course, and then
  fly ballistically, giving deliberate dodges a chance to work.
- Pink threat markers and an incoming-warning display distinguish missiles.
- Primary fire can destroy turrets and intercept missiles.
- Swept relative-motion collision prevents fast missiles passing through a
  moving pilot between frames. Cover can block them.
- Missiles have finite lifetimes and a maximum simultaneous population.
- Pause freezes launch timers and missiles; restarting clears missiles and
  restores turret state.
- The result screen tracks disabled turrets and intercepted missiles.

This remains a **non-lethal training scenario**. Missiles damage regenerating
training shields; the agreed campaign ejection/market recovery system is still
reserved for the campaign milestone.

### Verification

- Godot import, script checks, release export, and installer compilation passed.
- **34 focused gameplay assertions passed**, including stronger steering,
  turret warning/firing/destruction, interception, missile leading and shield
  damage, swept hits, population limits, pause, and restart cleanup.
- **Five native rendering checks passed**: visible tower strokes at 750 and
  1,000 meters in normal/reduced glow, plus occlusion by opaque scenery.
- Briefing, flight, and reduced-effect screenshots were visually inspected.
- The packaged runtime passed smoke tests and a complete 75-second benchmark,
  with development tools absent from PATH.
- Actual 30/60/120 FPS render-cap runs produced identical short-scenario results:
  48 shots, 14 hits, 7 disabled targets, 3 missile launches, 1 missile hit, and
  6.000 active seconds.

Packaged full-course run at 1920x1080, normal glow, balanced response, Intel Iris Xe:

| Metric | Result |
| --- | --- |
| Frame samples after warm-up | 9,245 |
| Mean frame time | 7.90 ms |
| 95th percentile | 11.11 ms |
| 99th percentile | 13.39 ms |
| Maximum frame time | 34.20 ms |
| Active course duration | 75.000 seconds |
| Primary shots / valid hits | 600 / 82 |
| Disabled targets | 34, including 1 ground turret |
| Missile launches / interceptions / shield hits | 34 / 12 / 12 |

The 99th-percentile frame time remains below the 16.67 ms / 60 FPS budget.
Occasional longer frames remain; this is not a guarantee for every frame or
every integrated-graphics laptop.

### Release and preservation

- [v0.1.1 Windows installer](../releases/0.1.1/CosmosConflict-0.1.1-Setup.exe)
  (28,189,484 bytes).
- [Updated player/build guide](FLIGHT_LAB.md).
- Runtime executable file/product version: **0.1.1.0**.
- The v0.1.0 installer hash was checked and is unchanged.
- The existing installed v0.1.0 was not replaced or uninstalled during testing.
  The new installer was compiled, while runtime validation used its exported
  application payload. Installation/upgrading this version is left to the user.
- No game/test process was intentionally left running.

New installer SHA-256:

```text
6AF640409B8F95925F936883656F6EB2E1554381CA8D49C149D965A075071947
```

The build remains unsigned. No additional dependencies or network downloads
were needed for this update.

### Next continuation

Collect feedback on the richer cockpit/scenery, increased steering authority,
and missile difficulty. Further campaign work should build on these mechanics,
without treating the remaining boss, market, upgrade, save, or ejection systems
as already implemented.

## 14. Offline handoff: v0.2.0 first-planet build

Checkpoint date: 2026-11-15, following the latest warning of imminent loss of
internet access. This section supersedes the historical status above.

### User decisions made during this implementation

- The user approved v0.1.1 and authorized the next part of the game.
- Ships should visibly break apart when hit. Nonlethal hits now shed a fragment;
  destruction creates multiple moving hull pieces. Training damage balance is
  unchanged.
- Docking fully repairs hull and shields **for free**.
- Buying another hull replaces the current hull and transfers fitted upgrades.
- The supplied transparent cockpit should sit above the live 3D world, with
  live instruments and menus above the artwork.
- Use the supplied exact coordinates for all six display surfaces.
- Use the new scout and interceptor artwork for the two current playable hulls.
  Keep **Rook Scout** and **Vector Hawk** names. Defer the three heavier classes.

### Implemented first-planet loop

1. Ground assault: 90 active seconds.
2. Vulcan Crawler: untimed ground boss.
3. Orbital fighter battle: 90 active seconds, with fast/light and armored fighters.
4. Solar Flare Cruiser: untimed orbital capital-ship boss.
5. Asteroid escape: exactly 60 active seconds.
6. Astra Market: purchases, free repairs, completion statistics, and another
   Ignis sortie from ground assault.

Both bosses require the amber generators to fall before the cyan core is
vulnerable. They can be defeated with the basic primary weapon and no secondary
ammunition. Phase transitions are short checkpoint/loading presentations;
elaborate ascent/warp cinematics remain polish work.

The market includes Rook Scout, Vector Hawk, two primary upgrade levels, two
shield upgrade levels, a concussion launcher, and ammunition. Secondary missiles
are real projectiles with finite ammo and collision/cover handling.

Campaign damage now affects shields and hull. Ejection retains earned credits,
loses the ship and equipped items, and returns to market. If no replacement is
affordable, the pilot can claim a free Rescue Skiff. Failed missions receive no
completion bonus; restarting after recovery begins at ground assault.

### Checkpoints and developer tools

- Campaign data is validated and atomically written through a temporary file.
- Normal saves use `user://campaign.json`, normally under
  `%APPDATA%\Cosmos Conflict`.
- Saves occur at phase boundaries, docking/recovery, and market changes.
- Mid-phase exit/resume restores the phase-start checkpoint, rolling back
  unfinished phase earnings and expenditure together.
- Save failures show an explicit retry/discard dialog and do not silently
  replace the previous checkpoint with defaults.
- Backtick provides credits, equipment, refill, invincibility, and phase jumps.
- Developer changes mark an operation as assisted.
- Starting testing from training/title uses a separate `debug_campaign.json`.
- Ordinary debug actions preserve phase time. Closing debug preserves an
  existing pause. Credit-only actions do not secretly repair the ship.

### Cockpit artwork and live display mapping

All source artwork was preserved. Game copies are under `current_dev\assets`.

| Game use | Imported game asset | Supplied source |
| --- | --- | --- |
| Rook Scout / training / Rescue Skiff | `assets\cockpits\rook.png` | `Cockpit_Overlays\cockpit_1_light_fighter.png` |
| Vector Hawk | `assets\cockpits\hawk.png` | `Cockpit_Overlays\cockpit_2_interceptor.png` |
| No assigned ship / recovery view | `assets\cockpit_overlay.png` | Original user attachment |

The strike-fighter, heavy-gunship, and heavy-bomber originals remain in
`Cockpit_Overlays` for later use; they are not additional purchasable ships yet.
The interceptor alias was not imported twice.

The renderer uses:

1. The 3D scene behind the cockpit.
2. RGBA artwork on canvas layer 1, preserving alpha and aspect ratio.
3. Live HUD, perspective-projected screens, and menus on canvas layer 2.

The old opaque procedural cockpit was removed to avoid drawing duplicate
structure through the new window cutouts. Primary beam origins are aligned to
the new cylindrical barrel mouths.

Shared source coordinate system: **1376x768**.

| Display | TL | TR | BR | BL |
| --- | --- | --- | --- | --- |
| Top combiner | 504,98 | 871,98 | 847,188 | 528,188 |
| Left MFD | 243,628 | 361,578 | 410,692 | 292,742 |
| Right MFD | 1014,578 | 1132,628 | 1083,742 | 965,692 |
| Center radar | 616,633 | 759,633 | 775,764 | 600,764 |
| Left gauges | 446,616 | 584,616 | 584,698 | 446,698 |
| Right gauges | 791,616 | 929,616 | 929,698 | 791,698 |

One transparent instrument atlas feeds six projectively mapped quads. This
avoids six independent render targets and keeps fonts aligned with tilted and
trapezoidal screens. Left gauges show shield charge; right gauges show missile
capacity. The center display shows actual corridor position.

### Breakup rendering and performance work

Fragments are sampled from the target's actual hull triangles, then drift,
tumble, and expire. Nonlethal hits produce one fragment; destruction produces
multiple pieces. Pause and scene changes handle their lifecycle.

An initial implementation missed the 60 FPS frame-time target. It was corrected
by using shared instanced fragment meshes and retaining source geometry on the
CPU, avoiding renderer-buffer readback on impacts. Detail was not removed to
make the test pass.

The last completed normal-speed source benchmark, with the original transparent
cockpit, produced:

| Metric | Result |
| --- | --- |
| Resolution / GPU | 1920x1080 / Intel Iris Xe |
| Samples | 9,250 |
| Mean | 7.89 ms |
| p95 | 11.20 ms |
| p99 | 14.88 ms |
| Maximum | 26.90 ms |

The p99 result passed the 16.67 ms budget. This is not a guarantee for every
frame. The final packaged scout/interceptor build is being measured separately.
Telemetry now uses wall-clock frame time, not simulation-scaled delta.

### Validation already completed

- Latest build/import/export and installer compilation succeeded.
- **78 headless gameplay, campaign, save, and cockpit-layout assertions passed**
  in the latest build.
- Native checks verified world-through-window transparency, frame-over-world
  composition, and live HUD above the image.
- Native rendering confirmed fragment transforms, distant detail, and occlusion
  during development.
- A complete source-build mission passed without invincibility. Its active
  phase times were 90 seconds, 7.13-second ground boss, 90 seconds, 9.07-second
  orbital boss, and 60-second asteroids.
- That functional test also verified free market repairs, hull/upgrades/ammo
  purchases, exact checkpoint reload, secondary ammo consumption, forced
  ejection, and free emergency replacement.
- Mission automation runs at accelerated simulation speed; it is not the
  normal-speed performance benchmark.
- The latest build includes additional checks for automatic cockpit switching
  after hull purchases and emergency recovery.

### Built release (updated after final validation)

[v0.2.0 Windows installer](../releases/0.2.0/CosmosConflict-0.2.0-Setup.exe)

- Size: **29,779,798 bytes**.
- Executable file/product version: **0.2.0.0**.
- Both v0.1.0 and v0.1.1 installers were checked and remain unchanged.
- The user's installed v0.1.1 was intentionally left in place.
- No new game installation or upgrade was performed automatically.
- The installer remains unsigned.

SHA-256:

```text
ACB807121D3C95069FC4F9A333440A7A60B63304B029ED0B1348E246BF4CA20F
```

### Outcome after reconnection

The originally pending command completed: its mission checks passed, but its
OpenGL p99 performance check failed at 20.19 ms. That result was not treated as
a release pass. Renderer comparisons, further checks, and the user-approved
Vulkan default resolved the release blocker; final results are in section 15.
No validation process remains pending.

### Resume procedure without internet

1. Use section 15 as the latest verified status.
2. Collect the user's playtest feedback on v0.2.0.
3. Make focused fixes to that feedback, preserving the previous installers.
4. Do not begin the remaining planets or heavier ship catalog before that review.

No internet is required for the remaining work. Godot, Windows templates,
portable Git, Inno Setup, artwork, and source code are local.

```powershell
.\tools\build.ps1 -TestOnly
.\tools\build.ps1
& '.\.tools\godot\Godot_v4.7.2-stable_win64_console.exe' --path '.\current_dev' --script 'res://tests/test_cockpit_composite.gd'
```

The player/build guide is [FLIGHT_LAB.md](FLIGHT_LAB.md). Do not run bootstrap
unnecessarily while offline: existing verified tools are sufficient.
Source files remain uncommitted; no remote repository or publication was created.

## 15. Final v0.2.0 verification and gun-art integration

Date: 2026-11-15, after internet access was restored. The game work stayed in
`C:\temp\Cosmos_Conflict`; the separately tagged Driftless Farm README was not
part of this task and was not modified.

### Additional supplied artwork

The source `Gun_Overlays` folder now includes eight named upgrade designs and
three animation frames for the Vulcan design. The `gun_upgrade_1` and
`gun_upgrade_2` files are byte-identical to their earlier `upgrade_1` and
`upgrade_2` counterparts.

The two existing primary upgrade levels now use:

- Level 1: plasma shroud.
- Level 2: outboard autocannons.

Their artwork is copied into the game's assets without editing the originals.
The gun image is composited behind the cockpit canopy, consoles, and bezels,
then cached per hull/tier. This preserves transparent windows and all six
instrument regions without adding another full-screen blending pass every frame.
Visible firing origins follow the equipped barrel layout. Damage still uses
the existing upgrade balance rather than multiplying damage per decorative barrel.

The later gun designs and animation frames remain source assets for future
weapon-family work. They were not silently added as six more purchasable tiers.

### Renderer decision and performance findings

The user explicitly approved **Vulkan by default, with an OpenGL Compatibility
shortcut**. Godot's Forward Mobile rendering path runs on the local Iris Xe.
The compatibility shortcut passes:

```text
--rendering-method gl_compatibility --rendering-driver opengl3
```

Both paths use the same gameplay, artwork, save files, and preferences.
Cross-renderer tests verify distant strokes, opaque occlusion, and preservation
of the authored terrain colors. Color-space conversion prevents the Vulkan
renderer from washing out the original dark vector palette.

Other focused improvements:

- Shared immutable materials instead of a separate material per solid object.
- Reused player collision-query resources.
- Cached GPU-instanced breakup fragments and CPU geometry source data.
- A single instrument atlas refreshed at 30 Hz, with immediate critical-state
  updates. The reticle, controls, world, and threat markers remain full-rate.
- Optional slow-frame profiling separates physics, firing, debris, and render
  costs instead of relying only on average FPS.

Final packaged normal-speed training benchmark, 1920x1080, normal glow, Iris Xe:

| Metric | Result |
| --- | --- |
| Frame samples after warm-up | 9,426 |
| Mean frame time | 7.75 ms |
| 95th percentile | 13.69 ms |
| 99th percentile | 16.31 ms |
| Maximum frame time | 174.38 ms |
| Required p99 budget | 16.67 ms |

The required p99 check passed. There are occasional stalls, including the
reported maximum; this is not a claim of a flawless locked 60 FPS or a result
for every computer. OpenGL remains a functional fallback, not a promise of
identical performance.

### Final verification results

- **90 headless assertions passed** across flight, combat, campaign/economy,
  saves, cockpit projection, image alpha, and gun compositing.
- Six native distant-detail/palette checks passed on each rendering backend.
- Five native cockpit/HUD/gun compositing checks passed.
- Native breakup transforms were checked against actual render instances.
- The final packaged mission completed both bosses without invincibility,
  reached the market, bought a Hawk, bought both primary tiers, and fitted a
  secondary launcher.
- Both gun tiers and the hull purchase switched the visible cockpit/weapon
  artwork correctly.
- The saved market state reloaded exactly.
- Secondary firing consumed ammunition.
- Forced ejection removed the hull and fitted upgrades; the no-money pilot
  obtained a free Rescue Skiff and the scout cockpit was restored.
- Final OpenGL Compatibility smoke checks passed.
- Final phase, cockpit, market, and gun-tier screenshots were inspected.

Final mission phase sequence:

```text
ground -> ground_boss -> orbit -> orbit_boss -> asteroids -> market
       -> ground -> ejection -> market
```

Regular-wave durations were exactly 90, 90, and 60 active seconds. The automated
pilot took approximately 7.13 and 9.07 seconds for the two untimed bosses. The
mission test uses accelerated simulation, so its frame-time numbers are not the
normal-speed performance acceptance result.

One earlier packaged mission run exited before reporting completion, without
a captured script error or Windows crash event. It was not counted as passed.
A subsequent complete run returned exit code 0 and all expected assertions.

Useful final logs and screenshots:

```text
releases\0.2.0\validation\final-mission-test.log
releases\0.2.0\validation\final-benchmark.log
releases\0.2.0\validation\final-compatibility-smoke.log
releases\0.2.0\validation\phase-ground_boss.png
releases\0.2.0\validation\phase-orbit_boss.png
releases\0.2.0\validation\phase-asteroids.png
releases\0.2.0\validation\gun-tier-1.png
releases\0.2.0\validation\gun-tier-2.png
```

### Delivery and remaining boundaries

- [Install v0.2.0](../releases/0.2.0/CosmosConflict-0.2.0-Setup.exe), then select
  **New Ignis Operation**. The player guide is [FLIGHT_LAB.md](FLIGHT_LAB.md).
- The user's installed v0.1.1 was left untouched. Both older installers remain
  unchanged; installing the new version is the user's choice.
- The installer compiled successfully. The final exported payload was exercised
  directly; no automatic reinstall/uninstall was performed on the user's setup.
- The final installer is 29,779,798 bytes; its hash is recorded in section 14.
- No helper game process remains running.
- The build remains an unsigned, private-sharing, one-planet preview. Clean-PC
  installation testing, broader hardware testing, further balancing, and
  additional campaign content remain future work.
- Next gate: user playtest of Ignis, the ship breakup effects, market/recovery,
  and the cockpit/gun artwork before expanding the remaining planets.

## 16. Continuous-flight release: v0.3.0

The user requested richer moving bosses, gradual pursuit along the canyon,
larger destruction effects, continuous ground/orbit/asteroid transitions,
close-range dogfighting with radar and automatic target acquisition, collapsible
towers, asteroid near-passes, and real station docking.

### Confirmed control choices

- Asteroid autopilot selects a safe nominal route. The mouse remains active and
  can deliberately steer the ship into danger; there is no hidden invincibility.
- Use the cleaner first engine-bank reference for a compact fighter and the
  armed variant for a boss. Additional swept-wing, wedge/escort, and delta-wing
  references were incorporated as distinct 3D vector models.
- Later long-nose/twin-engine and pod/boom images are retained as reference ideas.
  The named franchise craft was not copied or added with its original markings.

### Implemented changes

- Vulcan Siege Runner and Solar Flare Cruiser have engine banks, detailed nozzle
  rings, trusses, weapon pods, armor panels, bridge windows, and superstructure.
- Both bosses move away from the pilot while the player continues forward.
  They begin about 480 meters ahead and gradually approach engagement distance.
  Weak points stay protected during the distant approach.
- Destruction uses timed fireball cascades, expanding shockwaves, and a larger
  set of spinning hull fragments. The camera continues through wreckage clearance.
- Canyon terrain streams ahead during an untimed boss fight. Shared model caches
  and prewarmed terrain avoid reconstructing identical detailed meshes in flight.
- Ground victory flows into a climbing atmospheric ascent, then close orbital
  combat. Orbital victory leads into the belt, followed by station alignment and
  actual hangar entry. There are no sector-clear modal interruptions in that loop.
- New dogfight waves spawn approximately 85-125 meters away on several bearings,
  including behind. The flight computer turns smoothly toward the next live
  target. Red center-MFD triangles show relative bearings; gold indicates the lock.
- Four enemy appearances are available: compact engine scout, swept-wing fighter,
  delta fighter, and armored escort gunship.
- Towers need six base hits at starter weapon damage; upper armor rejects fire.
  The structure topples about its foundation before breaking into debris.
- Asteroids are larger and closer. Rust-orange iron-core rocks cannot be destroyed.
  The winding nominal route was checked against every generated rock; minimum
  clearance beyond the player collision radius was approximately 2.70 meters.
- Station docking uses an open entrance, alignment lights, and an interior.
  The market opens only after the camera reaches the dock inside the hangar.
- Automatic transit, collapse animations, and docking pause correctly with RMB,
  Escape, or focus loss.
- A docking checkpoint resumes the approach, not the market; completion payout
  is applied only after arrival.

All supplied references were preserved unchanged under `Docs\Reference_Art`.
These images are reference material, not textures shipped as enemy sprites.

### Verification and release

- 115 focused assertions passed before the subsequent pilot-systems additions.
- Packaged full mission, purchases, saves, recovery, and compatibility checks passed.
- Measured phase-boundary camera jump: **0.0 meters**.
- Maximum measured phase-boundary rotation difference: **0.00069 radians**.
- Docking finished at station-local **z=-12 meters**, inside the hangar.
- Actual 1920x1080 Vulkan training benchmark: mean **7.09 ms**, p95 **10.48 ms**,
  p99 **12.92 ms**, maximum **42.35 ms**. Render-target size was explicitly checked.

Installer: [v0.3.0](../releases/0.3.0/CosmosConflict-0.3.0-Setup.exe)
(29,809,604 bytes).

SHA-256:

```text
48BC2B9982DA2375D01304D56A960A49051E74CCB14281DC9997CB66BBDF7553
```

### Outline re-read

After completing that release, the full
[expanded design outline](Cosmos_Conflict__Game_Design_%26_AI_Development_Outline.docx)
was read again, including all 169 paragraphs, the planet table, and the embedded
1x/2x/4x combo and +25% tour-scaling formulas.

The user explicitly authorized proceeding to the next tasks rather than waiting
for another approval gate. The next bounded feature group selected was weapon
heat, cooling upgrades, and reactor power routing, because these shared systems
should be established before duplicating content across additional planets.
The originally suggested Python stack remains superseded by the approved Godot
implementation; the full four-planet scope has not been dropped.

## 17. Pilot-systems release: v0.4.0

### New systems

- Primary weapon heat in live missions. At 100%, the primary locks for exactly
  **2.000 seconds** while venting; the secondary remains available.
- Rapid cooling while not firing makes controlled bursts outperform repeated
  overheating. Thermal simulation handles shot/cooldown event boundaries rather
  than accumulating frame-rate-dependent shortcuts.
- **1 = Weapons:** 10 volleys/second instead of 8, with reduced heat per volley.
- **2 = Shields:** faster regeneration after the normal no-hit delay.
- **3 = Engines:** 40% faster lateral/vertical response.
- **0 = Balanced:** restore baseline routing.
- Two cooling-vent tiers in Astra Market, each reducing base heat per volley by
  18%. The interceptor also has faster passive cooling.
- Cooling equipment transfers with voluntary hull purchases and is lost on ejection.
- Right cockpit gauges show heat; the right MFD shows heat percentage, vent time,
  reactor selection, and ammunition. The top combiner warns during overheating.
- Market equipment is scrollable so all modules remain accessible.
- The developer panel has a Zero Heat toggle, recorded as assisted testing.
- The training range remains unlimited-fire and non-lethal, preserving its feel.

### Save compatibility

The save schema is now version 2. Existing version-one saves are accepted and
receive zero cooling upgrades plus balanced routing. The first upgraded save
preserves the original checkpoint as a timestamped
`campaign.json.v1-<timestamp>-<counter>.bak` file.

Unknown versions, invalid routing, invalid upgrade levels, and failed backup or
save writes produce explicit errors. Tests cover actual Windows replacement of
an existing save, migration, backup contents, and recovery-state validation.
No user's campaign file was modified during automated validation.

### Validation and balance

- **134 focused assertions passed** across gameplay, heat, saves/migration,
  artwork, continuous movement, radar, avoidance, collapse, and docking.
- Heat/shot output matches at 30, 60, and 120 update rates.
- Exact overheat duration, pause freezing, zero-heat testing, routing effects,
  equipment transfer/loss, and old-save backup were tested.
- An initial slow-cooling design made the live-mission test fail. Cooling was
  adjusted so releasing the trigger is a useful tactic; a focused test verifies
  that disciplined bursts outperform sustained overheating.
- The final packaged mission completed both bosses without invincibility or
  zero-heat mode. The automatic test pilot uses bursts, evasive movement while
  cooling, and the same reactor input actions available to the player.
- Final live-mission wave times: ground 90 seconds, orbit 90 seconds, belt
  60 seconds. Automated boss times were about 26.67 and 31 seconds.
- Final camera phase discontinuity: **0 meters / 0 radians**.
- The market, cooling purchase, save reload, secondary fire, ejection, and free
  emergency-ship recovery all passed.
- Screenshot inspection covered bosses, dogfight radar, market layout, and docking.
- OpenGL Compatibility smoke checks passed.

Final packaged benchmark on Intel Iris Xe, normal effects, actual 1920x1080:

| Metric | Result |
| --- | --- |
| Frames sampled after warm-up | 12,153 |
| Mean | 6.01 ms |
| p95 | 8.91 ms |
| p99 | 10.94 ms |
| Maximum | 22.75 ms |
| Required p99 budget | 16.67 ms |

This benchmark is the normal-speed training workload. The full mission was also
functionally exercised, at accelerated simulation speed; its timing is not
presented as a normal-speed performance guarantee. Startup/prewarming and phase
construction can still produce occasional loading stalls despite continuous
camera positions. Further hardware/long-session profiling remains release polish.

### Final package and continuation

[Install v0.4.0](../releases/0.4.0/CosmosConflict-0.4.0-Setup.exe)
(29,816,938 bytes). Executable version: **0.4.0.0**.

SHA-256:

```text
29147E24B1AE652DE369C48EC6FE57E001F745E3504F1D2C65FDDC512EBE4406
```

- v0.3.0 is preserved separately for comparison without the heat/power additions.
- v0.2.0 and earlier installers were not overwritten.
- The user's installed v0.2.0 was left untouched. Installation/upgrading is the
  user's choice; the final package payload was validated directly.
- The installer is unsigned and includes the OpenGL Compatibility shortcut.
- No validation game process remains running. The failed-test temporary save
  was removed; ordinary campaign files were not touched.
- Tests/builds remain available offline using the cached tools.

Next unfinished groups as of v0.4.0 (updated completion status is in section 18):

1. Emergency roll/boost, combo scoring, and more enemy defense/attack types.
2. Mineral collection/tractor beam, volatile-rock chains, and optional side objectives.
3. Additional secondary families and heavier ships, with corresponding artwork.
4. Three additional planetary systems with distinct hazards and six more bosses.
5. Sector selection, full-tour ranks/medals, Hall of Fame, and bounded new-tour scaling.

These are still unfinished, not represented as working features. Continue in
bounded, tested releases rather than silently treating the single Ignis sortie
as the complete four-planet game.

## 18. Tactical-combat release: v0.5.0

Date: 2026-11-16.

The user requested the next outlined features. The relevant maneuver, combo,
and shielded-gunship paragraphs were re-read from the DOCX. Before implementation
the user chose **a gentle bank during the side-dash, for comfort**, rather than
a full 360-degree camera roll.

### Emergency maneuver

- Press **Shift** during training or live combat to cross toward the opposite
  side of the current corridor position.
- The move lasts **0.65 seconds** and targets approximately +/-10.2 meters,
  within the existing +/-12-meter movement corridor.
- A maximum additional **14-degree bank** provides motion feedback.
  The Camera motion preference disables this bank and impact shake without
  changing evasion mechanics.
- Missile impacts during the maneuver are deflected. Towers and asteroids remain
  physical collision hazards; evasion is not general invincibility.
- The capacitor recharges over **six active seconds from activation**. Key-repeat
  does not repeatedly trigger the maneuver.
- The left cockpit display shows readiness/recharge, and the combiner reports
  active deflection.
- Pause freezes motion and recharge. Continuous phase handoffs preserve an
  active maneuver and its bank instead of snapping the camera upright.
- New maneuvers cannot be initiated during automatic transit or menus.

### Streak rewards and scoring

- First four consecutive combat kills pay the existing base reward.
- The fifth kill starts **2x**; the tenth starts **4x**.
- Only actual hull damage breaks the in-flight streak. Shield-only damage,
  intercepted/deflected missiles, and pauses do not.
- The streak carries across combat phases and is included in phase checkpoints.
  Docking, ejection, and a new sortie reset the current streak.
- Hostile ships, turrets, tower destruction, and defeated boss cores qualify.
  Boss generators, asteroid mining, projectile interception, docking payouts,
  and developer credits do not increase or receive the multiplier.
- Combat score earns ten points per awarded combat credit. It is independent
  of wallet balance, so buying equipment does not lower the score.
- The market reports cumulative combat score, best streak, and bonus credits.
  Bonus credits are already part of earnings, not paid a second time.
- Training has no persistent campaign scoring.

### Shielded gunships

- Heavy orbital gunships have a translucent blue, forward-facing shield and
  ten hull points. Rear/flank attacks bypass the shield.
- The shield opens for a visible bank during its six-second cycle. The basic
  primary weapon can defeat the ship without purchased ammunition.
- A concussion hit deals its ordinary damage, disables the shield, and stuns
  the surviving gunship for **two seconds**. Movement and firing stop during stun.
- Shielded primary hits give clear feedback but do not count as successful hits
  or grant score/credits. Blue brackets identify a shield facing the pilot.
- The shield recovers after a stun unless the ship is in its banking opening.

### Checkpoint compatibility

- Save schema is now version 3. Versions 1 and 2 remain supported.
- Equipment, money, existing statistics, and phase progress are preserved.
  Older saves start the newly introduced streak/score fields at zero; no past
  combat score is invented.
- Backups are labeled with the original schema (`.v1-...bak` or `.v2-...bak`)
  before the first upgraded write.
- Validation rejects inconsistent streak/best-streak or bonus totals.
- Scores, enemies, and money restore together when resuming a phase, preventing
  duplicate rewards from reloading.

### Verification completed

- **169 focused assertions passed** in flight, combat, campaign/save, artwork,
  and continuous-flight suites.
- Maneuver timing and opposite-side arrival agree at 30, 60, and 120 update rates.
  Recharge, pause, phase handoff, physical-collision danger, and deflection were checked.
- Tests verify exact fifth/tenth-kill payouts, hull-only reset, score independence
  from developer credits, settlement idempotency, and both old save migrations.
- Native rendering tests passed for the visible forward shield, an actual fired
  secondary projectile penetrating/stunning it, and the gentle bank/motion toggle.
- Native screenshots of the shield, stun, evasion, pause menu, and market were inspected.
- The final packaged mission completed both mandatory bosses without
  invincibility or zero-heat mode. It exercised 17 Shift maneuvers, a missile
  deflection, 63 blocked frontal shots, and the 4x streak tier.
- That run recorded a 75-kill best streak, 5,095 bonus credits, and 69,400 combat
  score before docking. These are automated-test results, not player requirements.
- Full mission validation also passed shopping, checkpoint reload, secondary
  ammunition, forced ejection, and free emergency replacement.
- Phase boundaries remained at **0 meters / 0 radians** of discontinuity.
- The OpenGL Compatibility smoke test passed.

Final packaged normal-speed benchmark, Intel Iris Xe, full 1920x1080:

| Metric | Result |
| --- | --- |
| Frames after warm-up | 10,704 |
| Mean frame time | 6.82 ms |
| p95 | 10.14 ms |
| p99 | 12.02 ms |
| Maximum | 23.58 ms |
| Required p99 budget | 16.67 ms |

This normal-speed benchmark covers the training workload. The new gunship
mechanics were exercised in the accelerated full-mission functional test and
native tactical test; those are not substituted for a normal-speed benchmark.
Occasional longer frames and startup/phase construction stalls remain possible.

### Release and next steps

[v0.5.0 Windows installer](../releases/0.5.0/CosmosConflict-0.5.0-Setup.exe):
**29,827,484 bytes**, executable version **0.5.0.0**.

SHA-256:

```text
02023C271AF5ADCBA068ADC7645A3A851A6B49C5C400489DCC709CE522DAFFF0
```

- The v0.4.0 installer hash was checked and is unchanged.
- The user's installed v0.2.0 was not modified. Installation is left to the user.
- No normal campaign save was changed by validation; isolated test saves were used.
- No test game remains running, and temporary test checkpoints were cleaned up.
- The installer remains unsigned and includes the OpenGL Compatibility shortcut.
- Controls and tactics are documented in [FLIGHT_LAB.md](FLIGHT_LAB.md).

Next bounded group: web-layer drones and/or mineral collection, tractor-beam
pickups, and volatile-rock chain reactions. Additional planets, ship classes,
secondary families, and full-tour rank/medal progression remain unfinished.
The single Ignis mission is not presented as the finished four-planet game.

## 19. Asteroid-mining release: v0.6.0

### Approved scope and reference art

The user requested the next outlined features and more asteroids in view,
providing three cratered-rock drawings. They explicitly approved volatile blasts
damaging nearby rocks **and the pilot at close range, with a warning**.
The related outline group is mineral collection, tractor utilities, and volatile
chain reactions; it does not add another planet or the heavier ship catalog.

Reference copies are preserved under `Docs/Reference_Art` as
`asteroid_cratered_round.png`, `asteroid_cratered_elongated.png`, and
`asteroid_cratered_lumpy.png`. The original attachments are untouched.

### Field density and geometry

- Physical asteroid count increased from 116 to **232**, retaining the original
  two close-pass lanes and adding two wider placements per row.
- **513** seeded instanced rocks add a distant backdrop outside the playable
  corridor. These are explicitly visual dressing, not collidable/shootable rocks.
- Three cached irregular meshes provide rounded, elongated, and lumpy forms.
  Eighteen crater sites produce recessed bowls and raised rims; fracture strokes
  are attached to the triangulated surface rather than floating analytic rings.
- Near meshes use 28 x 56 tessellation; distant meshes use 14 x 28.
  Collision spheres enclose all variants. Only the visual child rotates;
  stationary collision bodies do not incur repeated physics-transform updates.
- Gray = normal, gold = mineral, violet = volatile, rust-orange = indestructible.
- Nominal-route clearance remains about 2.70 meters beyond the pilot envelope;
  deliberate mouse steering into a close pass is still dangerous.

### Mining, tractor, and chains

- All shattered destructible rocks pay 8 credits. Gold rocks release a visible
  cyan mineral core worth another **50 credits only when collected**.
- Manual collection uses swept movement detection. Cores last 12 active seconds.
  At most 32 are active; replacing the oldest produces an explicit HUD message.
- The **400-credit tractor** attracts cores within 32 meters at 65 m/s when the
  path is unobstructed. A visible tether and HUD lock identify active attraction.
- Volatile cores have a **0.65-second warning fuse**, a 28-meter rock blast
  radius (testing against the rock surface), and an 18-meter pilot danger radius
  for 28 damage. Nearby volatile rocks get independent fuses, not recursive
  immediate detonation. Iron cores survive; chains can release mineral cores.
- Chain destruction does not fabricate shot accuracy or combat-streak kills.
  Mineral credits are not combo-multiplied and do not inflate combat score.
- Pause freezes pickups and fuses. Phase cleanup removes unfinished salvage.
  A destroyed pilot cannot collect more cores while awaiting ejection.

### Save compatibility

- Schema **4** adds tractor ownership, mineral earnings, collected-core counts,
  and chain-rock counts. Schemas 1, 2, and 3 migrate with their existing equipment,
  money, progress, and applicable scoring preserved.
- Original-version backup naming is retained, including `.v3-...bak`.
- Buying another hull transfers the tractor; ejection loses it but retains
  earned credits and historical mining statistics.
- Phase-boundary restoration rolls back uncompleted mining earnings with the
  rest of the phase. Invalid ownership flags and mining totals are rejected.

### Verification completed

- Native canopy visibility comparison at 160/800/1500/2250/2800 meters:
  old two-lane counts **44 / 42 / 42 / 29 / 8**; new-field counts
  **193 / 181 / 183 / 164 / 115**. Sum **165 -> 836**, approximately **5.07x**.
  Counts require the center to lie in the transparent canopy, within 1,100
  meters, with at least a three-pixel apparent radius.
- Rendered canopy coverage increased **20,988 -> 28,725 samples**, about 37%.
  The old-lane comparison uses the same new models, isolating the density change.
- All three cratered previews and the native tether/volatile-warning images
  were inspected. Screenshots and logs are under `releases/0.6.0/validation`.
- Twenty-one focused mining assertions passed: real depressions/collision envelope,
  manual/swept/tractor collection, cover obstruction, expiry, warning timing,
  pause, pilot damage, iron survival, chains, credit isolation, cleanup, and
  scripted-input isolation without disabling interactive steering.
- Native `--mining-test` collected one core for 50 credits, chained two rocks,
  and docked with zero impacts; the saved tractor and totals were reloaded.
- Added a dedicated `--belt-benchmark`; the older training benchmark alone does
  not validate this denser field. Normal-speed Iris Xe, actual 1920x1080,
  normal effects: **7,636 frames, mean 7.60 ms, p95 11.71 ms, p99 13.80 ms,
  maximum 18.36 ms**. P99 met the 16.67 ms target; nominal flight had zero impacts.
- Automation now ignores physical mouse-motion events during scripted aiming,
  preventing desktop activity from steering a benchmark off its nominal route.
  Interactive steering remains unchanged. Screenshot readbacks are excluded
  from the benchmark; occasional longer frames can still occur.

### Final packaged validation

- **201 focused assertions passed** across flight, combat, campaign/save,
  cockpit layout, gun artwork, continuous flight, and mining.
- The exported full mission completed both bosses, shopping including the
  tractor, checkpoint reload, secondary fire, forced ejection, and emergency
  replacement. No invincibility or zero-heat mode was used.
- Phase boundaries remained at **0 meters / 0 radians** discontinuity, and the
  camera entered the station hangar before opening the market.
- Exported Vulkan mining collected one core, earned 50 mineral credits, chained
  two rocks, and docked with zero impacts; the saved totals and tractor reloaded.
- OpenGL Compatibility with reduced effects passed the same complete mining and
  docking scenario. Its p99 was **17.90 ms**, above the 16.67 ms target; it is a
  functional fallback, not a claimed 60-FPS-budget pass. Vulkan remains default.
- Packaged market and asteroid screenshots were inspected.

Final exported **normal-speed dense-belt benchmark**, Intel Iris Xe, full
1920x1080, normal effects:

| Metric | Result |
| --- | --- |
| Frames after warm-up | 8,479 |
| Mean frame time | 6.84 ms |
| p95 | 10.39 ms |
| p99 | 12.32 ms |
| Maximum | 25.35 ms |
| Required p99 budget | 16.67 ms |
| Nominal-route impacts | 0 |

The full mission is an accelerated functional test; these normal-speed belt
measurements are separate. Occasional long frames and phase construction stalls
remain possible.

### Package and preservation

[v0.6.0 Windows installer](../releases/0.6.0/CosmosConflict-0.6.0-Setup.exe):
**29,847,386 bytes**, executable version **0.6.0.0**.

SHA-256:

```text
28DA5F5C5A4CC256F781690636115EE06DEF4FD6AC497EEA4121240F148D7E88
```

- The v0.5.0 installer hash remains
  `02023C271AF5ADCBA068ADC7645A3A851A6B49C5C400489DCC709CE522DAFFF0`.
- The user's existing installation and normal campaign were not updated.
  Installation is left to the user; the installer remains unsigned.
- The exported payload was tested without installing it over the user's game.
  No test process remains running; six disposable validation checkpoints were
  deleted after verification. Logs and screenshots are retained.
- The Windows GUI export does not provide reliable pipeline stdout. For native
  validation use `Start-Process -PassThru`, wait for that specific process, and
  supply `--log-file <absolute-path>` before the game's `--` arguments. Check
  both the process exit code and the log's `AUTOMATION_FAILURES=0` sentinel.

All required tools and assets are cached locally; current work can continue
without internet. Build with `tools/build.ps1`; do not overwrite older releases.
Next outlined group after this milestone: web-layer drones and additional
asteroid encounters such as mineral-hauling pirates. More planets, weapons,
ship classes, branching objectives, ranks, medals, and tours remain unfinished.

## 20. Peripheral-field refinement: v0.6.1

### User direction

- Add more asteroids specifically in the periphery, not just down the center.
- Some asteroids should tumble faster than others.
- Prefer more detailed graphics to 60 FPS. **30-45 FPS** is sufficient:
  use 30 FPS as the minimum budget and about 45 as the preferred range.
  This changes the quality target, not the frame-rate cap or physics timestep.

### Implemented changes

- Added **1,620** larger cratered backdrop rocks in a wider elliptical field:
  **2,133 backdrop rocks plus the existing 232 physical asteroids**.
  Placement extends 160-340 meters radially (65% vertical scale), putting rocks
  into the side and upper/lower canopy rather than simply thickening the center.
- Kept the original seeded inner backdrop and every physical asteroid placement.
  The new outer dressing remains beyond the reachable flight corridor and is
  not shootable/collidable. Mining, dangerous close passes, and the nominal
  2.70-meter clearance remain unchanged.
- Each nearby rock has a seeded rotation axis/direction and speed between
  0.06 and 0.65 rad/s (about 3-37 degrees/s). Backdrop rocks now also rotate,
  at 60% of that rate, instead of remaining static.
- Solids and crater strokes share each instance transform. Physical collision
  bodies stay fixed. Animation uses mission time, freezes on pause, and continues
  during the five-second belt-exit sequence. Out-of-range backdrop batches skip
  transform work and resume at the correct absolute orientation when visible.
- Existing model detail is retained. The benchmark now checks p99 against
  **33.33 ms**, reflecting the newly approved 30-FPS minimum.
- No save-format or economy changes.

### Source verification

- Native outer-canopy counts at 160/800/1500/2250/2800 meters:
  v0.6.0 **6 / 1 / 3 / 5 / 5**, updated **33 / 24 / 25 / 26 / 30**.
  Summed peripheral count **20 -> 138**, or **6.9x**.
- The peripheral region is the outer 22.5% on either side or top/bottom,
  masked to transparent cockpit windows. Rocks must be within 1,100 meters
  and project to at least a three-pixel radius.
- Each left/right/upper-lower region exceeds twice the previous visible count.
  Actual rendered peripheral coverage rose **13,018 -> 25,062 samples**
  (about **92.5%**), so this is not merely an increased spawn list.
- Comparison uses the same rotations on each side and hides only the new outer
  instances, isolating the density change from the tumble change.
- Native instance-transform checks prove varied rotation rates, matching solid
  and stroke transforms, and stationary centers/sizes. Focused gameplay tests
  verify slow/fast foreground rotation, unchanged colliders, and pause freezing.
- Cockpit screenshots at 25 and 45 seconds were inspected. Native mining still
  collected one core, chained two rocks, and docked with zero impacts.
- Source normal-speed 1080p Vulkan benchmark (Iris Xe, normal effects):
  mean **12.54 ms**, p95 **18.53 ms**, p99 **22.36 ms**, max **52.29 ms**;
  zero nominal-route impacts. P99 meets the revised 33.33-ms minimum budget.
  Occasional longer frames remain; screenshot capture is not part of this test.

### Final package

- **204 focused assertions passed** during the build.
- Exported normal-speed Vulkan, 1920x1080, normal effects: **4,335 frames**,
  mean **13.38 ms**, p95 **18.84 ms**, p99 **20.57 ms**, maximum **28.00 ms**.
  Zero nominal-route impacts; the 30-FPS minimum budget passed.
- OpenGL/reduced-effects mining, chain reactions, saved results, and docking
  passed. Its p99 **35.36 ms** missed the 33.33-ms minimum; Vulkan remains the
  default and OpenGL is a functional fallback, not a performance guarantee.
- One initial Vulkan launch stalled before writing a startup log and was stopped
  by its specific process ID. Headless exported startup, OpenGL, and a fresh
  Vulkan run then passed. No reproducible cause was established.
- Installer: **29,850,477 bytes**, version **0.6.1.0**, SHA-256:
  `F5A03D7551413A9752623B1BE5CE5425E4F810C7573AF9E0C4A9ADA76DDCE54A`.
- Earlier installers, the existing installation, normal saves, and supplied
  artwork are unchanged. Validation output is under `releases/0.6.1/validation`.

## 21. Continuous docking and destructible boss sections: v0.6.2

The user requested no jump cut between the asteroid field and station, a pull-up
similar to the end of the ground phase, more visible boss missile turrets, and
boss ship sections that explode and disappear individually.

### Belt-to-station continuity

- The previous `_prepare_station()` discarded the whole field and created a
  station 500 meters ahead. Camera position was continuous but the scenery was
  not; that caused the perceived jump cut.
- Live belt exit now retains the existing world and places the station ahead
  and above it. Five seconds of clearing rocks lead into a 12-second pull-up,
  a nine-second alignment, then eight seconds of final docking.
- All rocks remain in that same scene; they naturally leave the view as the
  pilot climbs. Foreground/backdrop tumbling continues during transit and freezes
  on pause. There is no field removal or station repositioning at those joins.
- The new path gains roughly 500 meters. The shared cubic flight transition
  provides continuous position and heading, ending inside the station hangar.
- Resuming an already-saved docking checkpoint still starts its station approach,
  rather than opening the market or replaying unsaved mining rewards.
- The belt benchmark now includes the climb, approach, and docking, rather than
  measuring the combat portion only.

### Boss weaponry and removable geometry

- Four ground-boss and six orbital-boss missile batteries replace decorative or
  invisible firing points. Each has a tracking six-port launcher, warning beacon,
  individual cooldown, health, and actual muzzle-origin missiles.
- Orbital batteries sit on separated outriggers so one does not hide another
  in the rear pursuit view. All batteries are targetable using actual reticle
  rays. Pink HUD brackets distinguish weapons from amber generator targets.
- Destroyed turrets stop firing and lose both their visible geometry and target
  collision. Destroying every turret does not defeat the boss or unlock its core.
- The three large engine nacelles are separate boss parts, rather than baked
  into the unbreakable hull mesh. Destroying an amber generator removes that
  complete nacelle and exposes its dark mounting socket.
- Removed sections emit 12 drifting/tumbling fragments and a local multi-stage
  explosion. Already-detached sections are excluded from final hull breakup.
- The original two-generator/core requirement, mandatory health totals, basic
  primary viability, and core reward remain. Optional turrets pay the existing
  component reward, not a combat-streak kill; the progress bar excludes them.

### Source verification

- Focused combat checks cover warning before launch, real muzzle origins,
  disabling firing/geometry/collision on turret death, optional-weapon behavior,
  full nacelle removal, one-time payout, and larger local breakup.
- Native tests fired actual primary rays at every turret on both boss types,
  spawned real missiles, and removed a turret and nacelle. Intact/exploding/
  removed-section screenshots were inspected.
- At 30 updates/sec, continuous-flight checks recorded at most **2.73 meters**
  and **0.020 radians** between frames during belt exit through docking.
  The same asteroid world, last rock position, and station transform survived
  the entire sequence. The test gained **507.1 meters** before docking.
- The native full mission beat both bosses without invincibility, completed
  docking, shopping, reload, secondary fire, ejection, and emergency recovery.
  Boss encounters took about 32.5 seconds (ground) and 42.9 seconds (orbital) for
  the automated pilot, which disables the turrets before the generators/core.
- Native mining still collected a core, chained two rocks, and saved its results
  after the new climb/docking path, with zero nominal-route impacts.
- Logs and inspected screenshots are under `releases/0.6.2/validation`.

### Final exported validation and package

- **224 focused assertions passed** during the final build.
- The exported full mission passed both bosses, continuous climb and hangar
  entry, shopping/tractor purchase, exact checkpoint reload, secondary fire,
  ejection, and emergency replacement, without invincibility.
- Phase handoffs recorded **0 meters** positional discontinuity and at most
  **0.00069 radians** numerical orientation difference.
- Normal-speed **Vulkan**, Intel Iris Xe, actual **1920x1080**, normal effects,
  complete asteroid stage plus climb/approach/docking:

| Metric | Result |
| --- | --- |
| Frames after initial warm-up | 9,498 |
| Mean | 9.69 ms |
| p95 | 16.98 ms |
| p99 | 18.99 ms |
| Maximum | 30.43 ms |
| Required p99 minimum-performance budget | 33.33 ms (30 FPS) |
| Nominal-route impacts | 0 |

This includes the less crowded transit as well as the dense belt. It is not
directly comparable with v0.6.1's flight-only average, nor is the accelerated
full mission a substitute for this normal-speed test.

- Exported OpenGL/reduced-effects mining, chain reactions, retained belt scene,
  docking, and saved results passed. Its flight p99 was **39.45 ms**, missing the
  30-FPS budget; OpenGL remains a functional fallback, not a promised minimum
  frame rate. Vulkan is the supported default for this measured target.
- The separately preserved v0.6.0 and v0.6.1 installer hashes were rechecked
  unchanged. No installed game, normal campaign, or supplied artwork was changed.
- Nine disposable validation checkpoints from v0.6.1/v0.6.2 were removed after
  verification; logs/screenshots remain. No test game was left running.

[v0.6.2 Windows installer](../releases/0.6.2/CosmosConflict-0.6.2-Setup.exe):
**29,855,726 bytes**, executable version **0.6.2.0**.

SHA-256:

```text
3C1DD7656EE4CC316395D59BFE7BA21525C2382876528E8051D544A0FC1177C3
```

The installer is unsigned and has not been applied to the user's existing
installation. Controls and tactics are in [FLIGHT_LAB.md](FLIGHT_LAB.md).
The remaining outline groups are unchanged: web-layer drones, pirate encounters,
additional planets/weapons/ships, branching objectives, ranks, medals, and tours.

## 22. Autonomous outline work: encounter objectives, v0.7.0

The user authorized at least two hours of autonomous work without questions,
starting 2026-11-16 around 18:00. Work began at **18:02 local time**. The expanded
DOCX was re-read in full (including Office Math text). The bounded, unambiguous
next groups selected were orbital web-layer drones, ground radar suppression,
optional pursuit pirates, hull plating, and explicit sortie accuracy bonuses.
No new ship-selection, recovery, or four-planet completion rules were invented.

### Implemented

- Original web-layer drone model with emitter pods; one appears in every other
  orbital wave. Each can drop a two-node tripwire ahead of the current flight
  direction. 1.2-second amber warning, then a red beam; shoot either node or
  fly around it. Swept collision accounts for arming/expiry within a frame.
- At most three seven-second webs are active. A crossing deals 22 damage once;
  destroying either two-hit node disables both and pays 15 credits only once.
  No combat multiplier/kill inflation for nodes; pause and phase cleanup work.
- Five original scanning radar dishes along the canyon walls. Destroying one
  pays 60 credits and jams living turrets within 700 meters downstream for
  12 active seconds. Upstream and distant batteries are unaffected; recovery
  includes a fresh warning before firing.
- Three optional 14-second pirate encounters during the belt, with an original
  compact craft, engine trails, banking, red radar contact, and bounty label.
  They stay inside the clear winding lane and only return fire once provoked.
  One defeat pays an 80-credit base combat bounty; ignoring them is valid.
- Two hull-plating tiers add 25 hull each (240/360 credits), transfer with
  voluntary hull swaps, and are lost on ejection.
- Docking records the current sortie's shot/hit sample and separates completion
  (350), remaining-hull, and accuracy bonuses. Accuracy is floor(hit ratio x 200)
  after at least 20 shots. Failed sorties receive none; repeated settlement
  does not duplicate payouts or combat score.
- Schema 5 adds plating, objective statistics, sortie baselines, and the debrief.
  Schemas 1-4 migrate with original-format backups. Existing in-flight saves
  start the new accuracy sample at migration, not from invented historic data.
- Added real-time/ship-selection validation flags, confined to assisted isolated
  test saves. Interactive starting ships and normal progress remain unchanged.

### Checks completed so far

- Targeted campaign/economy and encounter tests passed: tripwire warning,
  30/45/60-Hz swept crossings and dodging, either-node disarm, one-time payouts,
  expiry boundaries, bounded populations, radar suppression/recovery, pirate
  provocation and escape, plating, migration, and debrief settlement.
- Sampled pirate clearance from physical rock colliders stayed positive,
  minimum **0.45 meters** after accounting for the pirate's collision radius.
- Native shots hit a visible canyon dish, disarmed a deployed web, and defeated
  a nearby pirate. Screenshots of warnings, objectives, craft, and the updated
  market were inspected.
- Initial full mission passed. The subsequent **normal-speed Rook at 30 FPS**
  completed both bosses, two radars, four disarmed webs, one pirate, and docking.
  It earned an 80-credit accuracy bonus from 662 hits / 1,639 shots.
- That capped run is functional/timing validation, not an uncapped performance
  benchmark (frame-time p99 includes the intentional 30-FPS limiter).
- Shopping, plating/tractor persistence, exact market reload, secondary fire,
  forced ejection, and emergency replacement also passed.

### In progress / continuation

Package v0.7.0 separately, run uncapped representative benchmarks, and exercise
an extended real-time matrix across hulls, 30/45-FPS caps, effects settings and
renderers. Each matrix run performs actual gameplay and recovery; no artificial
waiting is needed. Stop specific test processes on timeouts and report failures
explicitly. Do not install over the user's game or touch normal saves.
Keep validation output under `releases/0.7.0/validation` and record results here.

### Package checkpoint before extended run

- **278 focused assertions passed**. Native objective rendering and the normal
  30-FPS Rook mission passed as described above.
- Exported normal-speed Vulkan, actual 1920x1080, normal effects:
  orbital benchmark p99 **6.85 ms** (22,405 frames, mean 3.93 ms);
  asteroid stage plus transit p99 **16.35 ms** (11,328 frames, mean 8.12 ms).
  Both met the 33.33-ms minimum budget; nominal belt traversal had zero impacts.
- Exported actual mineral collection, volatile chain, and save-after-docking
  scenario also passed.
- Frozen v0.7.0 installer: **29,875,420 bytes**; SHA-256
  `DF909B317A5B06AE2B754BF5627A1E8281036F8305A0D31D1770F50BCDA6EB40`.
- At **18:32:10**, started `tools/validate-soak.ps1 -Minutes 100` against this
  frozen package. It runs actual normal-speed missions, alternating Vulkan/
  OpenGL, 30/45 FPS, Rook/Hawk/Rescue Skiff, then effects variants. It checks
  startup readiness, mission results and errors; records failures explicitly;
  removes only its own disposable checkpoints. No idle delays.
- Output: `releases/0.7.0/validation/soak-20261116-183210/results.jsonl`.
  This first run was **aborted**: the harness incorrectly required live log
  output for readiness. Export-template file logs are buffered until exit.
  Process inspection found responsive game windows with active CPU time, and
  a native console-engine probe passed. Early cases were terminated by the
  harness before their missions could complete, not proven gameplay failures.
- Fixed readiness to require a responsive native game window, while still
  checking exit code and fully flushed error/assertion logs after completion.
  Restarted at **18:43:07** with `-Minutes 90 -Version 0.7.0`; its first game
  window was verified responsive. Output:
  `releases/0.7.0/validation/soak-20261116-184307/results.jsonl`.
  Retain the initial failure record rather than claiming aborted cases passed.
- Source work can proceed independently because the matrix uses the immutable
  v0.7.0 export. Do not overwrite that export or run other native-render tests
  concurrently on this GPU.

### Extended matrix completed

The corrected run finished at **20:14:49**, after **91.69 minutes**, with
**14 completed full missions and zero failures**:

- Rook Scout, Vector Hawk, and Rescue Skiff each passed 30- and 45-FPS caps
  under Vulkan and OpenGL, with normal effects (12 scenarios).
- Rook also passed 30 FPS with reduced effects under both renderers.
- Each run exercised both bosses, radar/web/pirate objectives, actual hangar
  entry, shopping including hull plating, checkpoint reload, secondary fire,
  ejection, and emergency recovery.
- These capped runs validate gameplay/timing and stability, not an uncapped
  frame-time budget. The entire requested autonomous session had exceeded
  two hours by the time the user returned with further refinements.
- Per-scenario logs and the JSONL result ledger are retained. The corrected
  harness cleaned its own isolated checkpoints.

## 23. Ignis-specific hazards: v0.8.0 in development

The next clearly specified outline items are Ignis heat vents (paragraph 84)
and the Solar Flare Cruiser's sweeping thermal beams (paragraph 86).

- Eight ground heat vents: 1.5-second ring warning, two-second eruption, a
  six-second cycle. Entering the five-meter-radius, 19-meter-high plume adds
  85 heat/sec of actual exposure. Swept sampling avoids missing fast passes.
- The nominal center route is outside the plumes; lateral/upward dodging avoids
  heat. These hazards are not added to nonlethal training.
- A separate, targetable thermal projector on the orbital boss charges for
  1.6 seconds, then sweeps for three seconds. The fan warning identifies the
  threatened plane; vertical steering clears it. One crossing deals 26 damage
  and 30 heat. Destroying the projector cancels the beam and future sweeps.
- Projector destruction is optional and does not change mandatory generator/
  reactor progression. Beam damage is not a deflectable missile.
- External heat reuses the established exact two-second weapon cooldown and
  cannot perpetually reset an existing lock. Training/Zero Heat bypass it.
- Timers are simulation-driven, freeze on pause, and are cleared at stage exit.
  Ground plumes continue visually through ascent; no new scene pop is added.
- Focused tests cover 30/45/60-Hz exposure/dodging, trigger timing, overheat,
  swept thermal collision, projector cancellation, pause, and cleanup.
- Native visual verification and package testing are deferred until the v0.7.0
  matrix releases the GPU. This source milestone is not yet a verified release.
- **312 focused assertions passed** across all current suites, including 34
  thermal-specific checks. A headless fixed-step full mission also completed
  both bosses, all three new objective types, shopping, saves and recovery.
  That simulation is functional evidence only, not a graphics measurement.
- At **18:46**, built the separate v0.8.0 candidate installer:
  **29,886,299 bytes**, SHA-256
  `DF56400288B714BF10FC3B762CAF8B5862A98D273F8BFE295D1B57E9331F0825`.
  This candidate still needs native thermal screenshots, actual projector
  targeting, exported full-mission, and performance validation. Do not mark
  it released solely because the build/headless suites passed.
- Rebuilt at **19:57** with a dedicated thermal-boss benchmark:
  **29,886,884 bytes**, SHA-256
  `F872F6CD7F0094FA4BD8F7A14B1E88CBCA4506150E8F57A024BB17DC44786EB0`.
  This candidate was superseded by the user's v0.9.0 requests. An initial
  exported benchmark ended without a completion sentinel; it was not counted
  as a pass. Native thermal rendering and a complete boss benchmark subsequently
  passed in the consolidated v0.9.0 source (see below).

## 24. Return feedback: radar, asteroid breakup, and hangar, v0.9.0

The user returned pleased with the autonomous upgrades and requested rotating
ground dishes, rotating dishes on bosses, asteroid-specific breakup, and a
larger station bay with other parked ship types. When asked about fragment
behavior, they selected **interactive: shootable/collidable smaller asteroids**.

### Implemented in source

- Ground dishes rotate continuously at 0.75 rad/s instead of oscillating over
  a narrow arc. Both boss models gain two mast-mounted dishes, rotating at
  slightly different rates/directions and included in final hull breakup.
- Large rocks split into three children at 42% of the original radius. They
  drift apart and tumble, remain weapon targets and physical hazards for ten
  seconds, and do not split recursively. Relative swept collision detects
  moving fragments crossing a moving pilot.
- Children are ordinary rocks: no inherited mineral core, volatility, or
  indestructibility, and no new credit/mineral/original-rock-stat payouts.
  Their destruction uses the same rocky chips, never triangular ship panels.
- A separate cached volumetric rock-chip effect replaces asteroid hull flakes
  on both damage and shatter. Physical chunks are capped at 48 and visual
  clouds at eight. The oldest physical chunk disperses with a HUD notice.
  Pause, transition motion, chain reactions, and cleanup remain bounded.
- The station interior expands from roughly 24 x 18 x 65 meters to
  **96 x 40 x 166 meters**, with a longer apron and wider docking ring.
- Eight parked craft use four original designs, with landing gear and raised
  lower/upper service platforms. Bay placement keeps the center lane clear
  and aims to leave several craft visible beside the market panel.
- Existing continuous belt climb and docking path are retained. The final
  camera still reaches inside the hangar before the market appears.

### Verification pending

- Initial headless radar/fragment/hangar checks, previous mining tests, and the
  complete continuity suite passed. Added a native visual/ray test for rocky
  breakup, child targeting, boss dishes, and parked-ship visibility beside UI.
- Finish the shared-GPU matrix, then run thermal/refinement native checks,
  inspect screenshots, exercise live mining with new fragments, and verify
  the exported complete mission and normal-speed performance.
- Package separately as v0.9.0. Preserve v0.6.2, v0.7.0 and v0.8.0 artifacts,
  the user's existing installation, normal saves, and all supplied artwork.

### Additional user requests: Cosmic Conflict and fading polygons

- Renamed the game, live HUD, credits, executable metadata, installer, and
  Start-menu shortcuts to **Cosmic Conflict**. New executable/installer filenames
  start with `CosmicConflict`.
- Kept the existing installer AppId and enabled previous-directory reuse, so an
  upgrade finds the prior installation. Fresh installs use the new name.
  The installer removes only the named legacy executable/pack and its three
  old Start-menu shortcuts; it does not delete saves or user artwork.
- Retained `%APPDATA%\Cosmos Conflict` deliberately for save/settings continuity.
  Workspace folders, original documents, old release names and historical logs
  are not mass-renamed. Old pinned shortcuts may need repinning after upgrade.
- Breakup now releases many original mesh faces (up to 96 for ordinary targets,
  256 for boss sections, 192 for towers, and 1,024 for the final capital ship).
  They drift/tumble without shrinking and fade smoothly using per-instance
  alpha on both fill and glowing outlines.
- Asteroids retain their three interactive children and separate volumetric
  rock chips, plus fading polygons sampled from their actual cratered surfaces.
  Rock fills use their source surface colors rather than generic metallic hull colors.
- Following the user's color refinement, polygon fills retain their original
  material/vertex colors and authored edges retain their original trim colors.
  Per-face CPU metadata avoids renderer-buffer readbacks on impact. Only alpha
  changes while fading; debris is no longer recolored by an explosion tint.

### Native source validation completed

- **331 focused assertions passed** after adding fade and original-color regressions.
- Native shots verified smaller rock targeting and no duplicate payouts.
  Screenshots of actual rocky breakup and the enlarged hangar were inspected.
- At least three parked craft are visible in the area to the right of the
  market panel. Eight craft/four designs remain in the full bay.
- Native thermal tests verified the warning, visible active sweep, actual
  projector targeting, and immediate cancellation after destruction.
- The fade test held geometry fixed to isolate alpha: rendered brightness
  fell from **702.290 to 121.306** near expiry, with zero visibility at expiry.
  Solid and line instance buffers both carried reduced alpha; rock chips and
  asteroid polygons passed the same rendered-fade check.
- Native pixel comparisons verified detached polygons match the original
  colored surfaces, not just stored color constants.
- Normal-speed 1080p Vulkan thermal-boss benchmark included an active sweep and
  the large polygon explosion: **10,868 frames**, mean **4.71 ms**, p95 **7.46 ms**,
  p99 **9.71 ms**, maximum **24.01 ms**. The 33.33-ms budget passed.
- Live mining with interactive fragments still collected a core and chained two
  rocks without impact. The full mission passed all objectives, both bosses,
  docking into the new bay, purchases, saves and recovery.
- Final installer/export validation and cleanup remain.

### v0.9.0 final package verification

- **331 focused assertions**, native original-color pixel comparisons and fading
  under Vulkan/OpenGL, live mining, and the exported full mission all passed.
- Exported normal-speed 1080p Vulkan, normal effects:
  thermal boss including active sweep/final polygon explosion **p99 9.39 ms**;
  asteroid stage plus continuous docking **p99 18.10 ms**. Both passed the
  revised 33.33-ms budget. Nominal belt traversal had zero impacts.
- Full mission passed radars, webs, pirate bounty, both mandatory bosses,
  accurate debrief settlement, hull/tractor purchases, reload, ejection and rescue.
- OpenGL mining/chain/docking and original-color fading passed functionally.
  Its mining p99 **42.29 ms** missed the frame-time target; Vulkan remains the
  performance-supported default. No flawless frame-rate guarantee is implied.
- The standalone v0.9.0 installer is **29,899,467 bytes**, SHA-256
  `CFB3714D7C39E338C64DB87F5FBE51DE3194650043AC22D9B7E6370FB41830D3`.
- Prior v0.6.2/v0.7.0/v0.8.0 package hashes were rechecked unchanged.
  Eighteen leftover isolated test checkpoints were removed; normal saves and
  the installed game were not modified. The new name appears in executable
  product metadata and screenshots.

## 25. Larger animated station exterior: v0.9.1

The user requested a much larger, more detailed outer ring, rotating radar
domes, moving gun turrets, and marine-style rotating radar towers.

- Increased the outer diameter from about 116 meters to **256 meters**.
  The ring now has a solid segmented annular structure with front/back
  surfaces, inner/outer skins, and illuminated rims.
- Twenty-four armored service modules add inset panels, four light slots each,
  side housings, and structural connectors. Eight trusses connect the ring to
  the actual central-bay wall/roof boundary rather than floating in empty space.
- Six wireframe radar domes contain visible rotating antenna assemblies.
- Four marine-style lattice towers carry eight independently rotating scanner
  bars, with contrasting upper/lower rotation.
- Eight friendly defensive turrets swivel and elevate their barrels. They do
  not fire at the player or turn the market into a combat encounter.
- Equipment animates throughout approach and while the market is open; pausing
  transit freezes it. The station's docking transform never changes.
- Retained the 96 x 40-meter hangar, eight parked craft, safe center lane,
  continuous asteroid pull-up, and all prior gameplay/branding refinements.
- Native front and close-up screenshots were inspected, including visible dome
  antennae and marine scanner bars. Focused tests verify the new diameter,
  independent equipment motion, fixed docking reference, and pause/market behavior.
- Build and exported docking/performance validation remain.

### Final v0.9.1 verification and delivery

- **336 focused assertions passed**. Native front/close exterior screenshots
  and the populated market view were inspected.
- Exported normal-speed **1920x1080 Vulkan**, Intel Iris Xe, normal effects,
  complete asteroid stage plus climb/approach/docking: **9,483 frames**,
  mean **9.70 ms**, p95 **16.35 ms**, p99 **18.44 ms**, maximum **81.87 ms**.
  The 33.33-ms p99 budget passed; occasional scene-construction/long frames
  remain possible. Nominal traversal had zero impacts.
- Exported OpenGL/reduced-effects mining, fragments, chain reactions, continuous
  docking and saved results passed functionally. Its flight p99 was **42.59 ms**,
  above the performance target; Vulkan remains the measured default.
- Original-color polygon fading was separately verified under both renderers.
  The immediately preceding v0.9.0 export passed the full mission, objective
  rewards, shopping/plating, checkpoint reload and ejection/recovery.
- The v0.9.0 installer hash remains unchanged. No normal campaign or existing
  installation was modified. The two final disposable checkpoints were removed
  and no validation game was left running.

[Cosmic Conflict v0.9.1 Windows installer](../releases/0.9.1/CosmicConflict-0.9.1-Setup.exe):
**29,903,498 bytes**, SHA-256:

```text
F4581A8E8C742DBB6ADC08B104A91B645A5D017AF58102D5C998475A5A129704
```

The installer is unsigned and installation remains the user's choice. Saved
progress/preferences continue to use the legacy user-data directory for
compatibility. Source, tools and cached assets remain usable offline.

## 26. Complete outline review and continuous belt entry: v0.10.0

The user requested a smooth pull-up from the end of the dogfight into the belt,
then a complete review of the development outline and continued implementation.
Both DOCX files were read in full, including tables and Office Math text:
the 16 non-empty paragraphs of the original prompt and all 163 non-empty
paragraphs of the expanded specification. The source documents were not edited.

### Review of every major requirement group

| Outline group | Current result | Remaining work |
| --- | --- | --- |
| Original IP / vector-hybrid presentation | Original procedural scenery/craft, user-supplied cockpit/gun art, detailed solids/edges, original-color fading breakup | Further environmental polish; composed synthwave soundtrack and deliberate hit-stop treatment |
| Basic controls / HUD | Mouse aim/steer, primary fire, Space secondary, C countermeasures, pause/status, developer panel, six live cockpit screens | Further station interaction |
| Heat / power / evasive move / score multiplier | Implemented and tested; user-selected gentle Shift bank replaces a full roll | Further balance across the eventual full campaign |
| Interceptable projectiles | Enemy missiles can be shot or deflected | Additional mine/plasma variants where useful |
| Ground phase | 90 seconds, terrain, patrol fighters, turrets, towers, radar suppression, heat vents, optional safe/hazard fork, three supply types and moving modular boss | Further branch layouts and ground enemy/structure variants |
| Orbital phase | 90 seconds, multi-bearing pursuit, several fighter models, directional gunships, web-layer drones, modular missile/thermal boss | Heavy-bomber and stealth-specific behaviors; additional sector fleets |
| Belt phase | 60 active seconds, dense irregular rocks, safe nominal path, interactive fragments, minerals, tractor, volatile chains and optional pirates | Additional sector-specific variations |
| Phase continuity / station | Station launch/hyperspace/descent, ground ascent, orbital pull-up, persistent belt scenery, continuous climb/autodock; detailed populated animated station | Extend existing travel to selectable destinations when multiple planets exist |
| Market / utility progression | Clear prices/benefits, two approved playable hulls plus rescue craft, primary/shield/cooling/armor/tractor upgrades, exact reward accounting | Heavier ship catalog remains deferred; NPC parked craft do not unlock playable hulls |
| Primary weapon families | Twin Pulse, four travelling Quad Plasma bolts and continuous wider/brighter piercing Tachyon Beam | Further balance across the eventual full campaign |
| Secondary families / tactical inventory | Concussion, Swarm Rockets, EMP Nova, paused/docked switching and separate chaff/flares implemented | Further ordnance variants |
| Sector map / four planets | One complete Ignis operation | Cryo-Vex, Vespera-9, Xylo-Mire, six further bosses, their scenery/hazards and selectable sector map |
| Campaign summary | Wallet, score, enemies/bosses/rocks/minerals, accuracy, objectives, ejections and sortie debrief | Full four-planet summary, cumulative hull damage, ranks and original medals |
| Retire / Continue / tours | Not presented as complete | Local Hall of Fame, retirement, retained-equipment tours and bounded 25% scaling |
| Developer tools | Credits/reset, ship/equipment/refill, god/zero-heat/infinite-ordnance/one-hit, explicit boss defeat, phase jumps, assisted flag and isolated debug saves | Multi-sector/endgame warps when that content exists |
| Packaging / architecture | Godot/GDScript and Windows installer per confirmed user choice; preserved installers and local cached toolchain | Broader campaign/clean-machine validation and explicit versioned source archives |

Confirmed overrides remain: **Cosmic Conflict** is the current title; Godot is
the chosen stack; the current playable hull names remain Rook Scout / Vector
Hawk; heavier hulls are deferred; target detail-first 1080p at 30-45 FPS; ejection
retains earned credits but loses equipment, with a free weak rescue craft when
needed. These supersede conflicting names/technology suggestions in the DOCX.

### Fixed orbital-to-belt transition

- Previously, a short straight transfer ended by clearing the old world and
  constructing the field around the camera. Coordinates were continuous but
  scenery appeared suddenly.
- Now the field is prepared beyond draw range when the orbital boss falls.
  Four seconds of wreckage clearance lead into an 18-second rising approach,
  gaining about 550 meters before leveling into the belt.
- The same asteroid nodes and positions are retained at handoff. Their visual
  clock continues through the approach, while the 60-second phase/pirate timers
  start only once active asteroid flight begins.
- Pause freezes camera movement and preview tumbling. Old defeated-boss scenery
  is retired after safe separation rather than replacing the visible field.
- Continuity checks recorded maximum adjacent-frame movement **3.37 m** and
  heading change **0.008 rad** at 30 Hz, with no transition discontinuity.
- The actual full mission passed with **0 m / 0 rad** handoff discontinuity.
  Native screenshots confirmed a dense approaching field before manual flight.
- A custom visual fixture exposed a script-retention warning at shutdown;
  final visual verification uses the normal game automation and the expanded
  existing continuity tests instead of shipping that fixture.

## 27. Tactical secondary stations: v0.10.0

After the full review, the next bounded feature group was Swarm Rockets, EMP
Nova, and weapon-station switching. The user explicitly chose **shared ordnance**
with **Concussion 1 / Swarm 2 / EMP 3** per activation.

- New 500-credit Swarm station: three guided 3-damage rockets, distributed across
  up to three visible/unobstructed hostile targets. No lock means no ammo spent.
  Each actual projectile is counted in shot/hit accuracy, preventing multi-hit
  salvos from exceeding their sample size.
- New 650-credit EMP station: clears visible missiles within 220 meters and
  disables hostile systems for two seconds. Gunship shields drop; capital
  weapons and active thermal sweeps stop. Capital/pirate flight motion continues
  so a stun does not create an unsafe rail interception.
- EMP does not destroy generators, bypass the core lock, award kills, or invent
  combo rewards. A successful activation counts one hit even if it affects
  several threats. Solid cover, range, and forward visibility are respected.
- Pause/market dropdown selects an owned station; Space uses it. Costs and
  remaining shared units appear in the cockpit. Paused selection saves at the
  next normal checkpoint; docked selection saves immediately.
- All launchers share the existing 6/8/3-unit hull bay. Purchases include up to
  three units and never erase existing ammo. Hull swaps transfer unlocks and
  selection; ejection removes all stations and ammunition.
- Schema **6** retains schemas 1-5, with a correctly labeled `.v5-...bak` when
  upgrading the previous format. Legacy concussion ownership/ammo are preserved
  without free new weapons.
- Mineral value now belongs to the economy state, and the shared stun duration
  belongs to flight state, avoiding unnecessary actor/resource dependencies.
- Twenty-seven focused secondary tests cover actual homing hits,
  EMP visibility/cover, interrupted beams, exact costs, pause, recovery, station
  selection persistence, post-checkpoint projectile behavior, and the exact
  schema-five backup.
- Native UI/effects passed: actual guided rockets reached separate enemies,
  EMP cleared incoming missiles/cancelled a thermal sweep, and pause/market
  selectors fit the screen. The named equipment scroller exposes the new cards.
- Outstanding player missiles continue moving during automatic transit but
  stop resolving hits after the phase checkpoint, avoiding frozen rockets or
  post-checkpoint reward discrepancies.
- The complete mission simulation now purchases both stations, saves/reloads
  the selection, fires Swarm / EMP / Concussion for exactly 2 / 3 / 1 units,
  and verifies that ejection removes all three stations.
- Final exported gameplay, performance and release results follow.

### Final verification and package

- **371 focused assertions passed** across all current suites, including the
  prepared-field handoff, original combat, new weapon physics, economy and
  schemas 1-5 migration.
- Final exported full mission completed both bosses without invincibility,
  all encounter objectives, the 18-second belt pull-up, the full 60 active
  asteroid seconds, and actual hangar docking.
- Phase handoffs reported **0 meters / 0 radians** discontinuity. The canopy
  test found **260 backdrop centers** already visible before activation, and
  the actual near-entry screenshot shows the dense field during the climb.
- Shopping and exact checkpoint reload included both new stations. The game
  fired Swarm for two units, switched while paused, fired EMP for three, then
  Concussion for one. Ejection removed every station and shared ammunition;
  free emergency recovery still passed.
- The automation now waits for the actual secondary cooldown rather than a
  fixed elapsed timestamp; screenshot stalls cannot trigger a premature test
  shot. Gameplay cooldowns were not shortened.
- Native Vulkan and OpenGL tests passed guided impacts, visible EMP effects,
  beam cancellation, pause-menu fit and scrolling to the new market cards.
- Normal-speed final exported **1920x1080 Vulkan**, Intel Iris Xe, normal
  effects, orbital boss plus wreck clearance/climb/first five active belt seconds:

| Metric | Result |
| --- | --- |
| Frames after initial warm-up | 13,239 |
| Mean | 5.13 ms |
| p95 | 10.23 ms |
| p99 | 13.36 ms |
| Maximum | 53.77 ms |
| Required p99 budget | 33.33 ms (30 FPS) |
| Belt-entry impacts | 0 |

This benchmark measures the new transition workload at normal speed. The
accelerated complete mission is a separate functional check; occasional longer
frames remain possible.

[Cosmic Conflict v0.10.0 Windows installer](../releases/0.10.0/CosmicConflict-0.10.0-Setup.exe):
**29,916,642 bytes**, executable version **0.10.0.0**, SHA-256:

```text
CC1C800A95B5E7782DFCEDF3F0C249DD3F6BA453B75AEDBD87187D8BDF8C9B05
```

- v0.9.1's installer hash remains
  `F4581A8E8C742DBB6ADC08B104A91B645A5D017AF58102D5C998475A5A129704`.
- Four isolated validation checkpoints were removed. No validation export
  remains running; the user's installation, normal saves and artwork were not
  changed.
- At the v0.10.0 checkpoint, next groups included branching routes, advanced
  primaries, flares, debug actions and the other planetary/campaign systems.
  Flares and the next debug controls subsequently shipped in v0.11.0.
  Use the current working outline for the remaining backlog.

## 28. Seamless sortie departure and defensive countermeasures: v0.11.0

Work started 2026-11-17 at approximately 05:36 local time.

### Requested/approved behavior

- New sorties must begin inside Astra Station, undock, enter hyperspace, descend
  to the planet and start ground assault without camera jumps or scenery swaps.
- Departing the market should use the existing station/camera, not recreate them.
- Prepare the destination terrain before descent and activate that same scene
  when the full 90-second ground clock starts.
- Keep pause/resume, phase checkpoints, old saves, training and the previous
  seamless ground/orbit/belt/station transitions working.
- Add the next outlined defensive chaff/flare module. The user explicitly chose
  **separate flare charges and a separate reload purchase**. Secondary weapon
  costs remain Concussion 1 / Swarm 2 / EMP 3 in their existing shared pool.
- Activation will use C; countermeasures should visibly divert nearby missiles,
  not erase physical collision or beam hazards.

### Implementation plan recorded before work

Add a launch checkpoint, a continuous hangar turn/exit, visible hyperspace
streaks, a procedural destination planet and atmospheric descent. Ground
geometry and actors will use a shared course transform so any departure from
the current station can connect to the same ground route without teleporting.
Then implement the flare pod, inventory, cooldown, defensive effect and HUD.
Verify native appearance, 30/45-Hz continuity, save migration, full mission and
normal-speed 1080p performance before creating the separate release.

### Implemented and checked in source

- Launch flow: four-second in-hangar turn, eight-second undock, six-second
  alignment, twelve-second continuous hyperspace flight, then sixteen-second
  atmospheric descent. No screen blackout hides a teleport.
- The destination uses an original shaded/vector planet, camera-relative
  hyperspace streaks and a broad ground horizon. Planet and prepared surface
  cross-fade through the atmosphere; the same terrain/actors remain at arrival.
  Original opaque materials are restored before manual flight.
- The ground course can be translated/rotated to connect from the current
  station. Turret aiming, ground patrols, boss pursuit and ground-to-space ascent
  now respect that course instead of assuming global negative Z.
- New and market-departure launch checkpoints use schema **7**. Ground entry
  saves its own checkpoint only at arrival. Old active-phase saves preserve
  their phase; legacy schema-six files receive exact `.v6-...bak` backups.
- At 30/45 updates per second, both canonical and translated/rotated departures
  passed continuous-position/heading tests, pause checks in all five stages,
  station/camera reuse, the complete 90-second ground clock and valid targeting.
  Hyperspace intentionally travels faster: maximum movement per update was
  about **31.14 m at 30 Hz / 20.76 m at 45 Hz**, with no discontinuity.
- The dedicated countermeasure pod costs **240 credits**, holds **three separate
  charges**, and its **60-credit reload** fills only that pod. C diverts up to
  four nearest incoming missiles within 110 meters, with an eight-second cooldown.
  Threat displays drop broken locks; projectiles visibly veer away rather than
  disappearing. No artificial hits, kills, credits or combo bonuses are awarded.
- Flares do not consume secondary ammunition, grant immunity to physical
  hazards, or neutralize every missile on screen. Charges transfer with a
  voluntary hull swap and are lost with the pod on ejection.
- Completed the next outlined testing tools: wallet reset, infinite secondary
  ordnance, one-hit exposed targets and explicit current-boss defeat. The
  explicit defeat action awards no combat reward and fabricates no shot/hit
  statistics; all testing changes mark the operation assisted.
- **427 focused assertions passed**. A headless complete mission also passed
  both departures, translated ground combat, all weapon/pod purchases, the
  C deployment fixture, checkpoint reload and ejection/recovery.
- Native screenshots of undocking, hyperspace, the planet/surface blend,
  flare diversion, separate inventory/reload cards and expanded debug controls
  were inspected. Native countermeasure/UI checks passed.
- At this intermediate checkpoint, exported gameplay, compatibility, uncaptured
  performance measurements and separate packaging remained; they were completed
  in the final verification below.
- Departure rendering was refined after inspecting the first native captures:
  the camera keeps the planet in view during hyperspace, prepared ground detail
  fades in through atmospheric haze instead of protruding above the distant
  planet, and original opaque ground materials are restored before control
  returns. A continuous broad horizon removes the isolated terrain-patch look.
- Fresh debug operations now use a clean loadout instead of inheriting stale
  ammunition from another flight. The build runner requires each test's explicit
  successful completion marker, not only an exit code.

### Final verification and package

- **432 focused assertions passed**, including both launch frame rates, material
  restoration, translated ground targeting, separate flare economy, actual
  missile diversion, pause, recovery, new developer actions and old-save migration.
- Final exported **Vulkan/normal effects and OpenGL/reduced effects** complete missions passed: first station
  departure, ground/orbit/belt/boss encounters, docking, equipment and pod
  purchases, exact checkpoint reload, departure from that existing station,
  secondary station use, C deployment, ejection and free rescue.
- Both complete missions reported **0 m / 0 rad** phase discontinuity.
  Their accelerated timings are functional evidence, not performance benchmarks.
- The dedicated final **normal-speed 1920x1080 Vulkan** launch benchmark used
  normal effects on Intel Iris Xe, without screenshot readback:

| Metric | Result |
| --- | --- |
| Frames after initial warm-up | 6,020 |
| Mean | 7.81 ms |
| p95 | 13.14 ms |
| p99 | 16.46 ms |
| Maximum | 31.56 ms |
| Required p99 budget | 33.33 ms (30 FPS) |

This covers station rotation/undocking, alignment, hyperspace, atmospheric
descent and the first five ground seconds. It met the agreed minimum budget.
Other scenes/machines can still have longer frames.

[Cosmic Conflict v0.11.0 Windows installer](../releases/0.11.0/CosmicConflict-0.11.0-Setup.exe):
**29,937,265 bytes**, executable version **0.11.0.0**, SHA-256:

```text
F3AC43DD0C0A829CCCAF4FA13BA244549405FE954AC705DC6946FD0E5D3795D9
```

- v0.10.0 remains unchanged:
  `CC1C800A95B5E7782DFCEDF3F0C249DD3F6BA453B75AEDBD87187D8BDF8C9B05`.
- Five isolated validation checkpoints were removed. Normal saves, preferences,
  the user's existing installation and supplied artwork were not modified.
  No validation export remains running.
- Remaining outlined groups include branching ground routes/supply pickups,
  advanced primary weapon behaviors, remaining planet/ship/enemy content,
  sector selection and campaign-wide ranks, medals, retirement and tours.
  The launch framework supports future sector travel, but only Ignis is
  presented as playable.

## 29. Development outline revision and Markdown working copy: 2026-11-17

The user requested an updated development outline reflecting the actual game
and lessons learned, then requested a Markdown conversion for future work.
This is a documentation revision, not another game release.

### Current documents

- [Markdown development outline](Cosmic_Conflict_Development_Outline.md):
  the current working specification and prioritized backlog.
- [Synchronized Word outline](Cosmos_Conflict__Game_Design_%26_AI_Development_Outline.docx):
  revised in place, retaining its established filename.
- [Pre-review Word outline](Archive/Cosmos_Conflict_Development_Outline_before_2026-11-17_review.docx):
  an exact copy of the original expanded design, before this review.
- The original AI prompt, source code, installed game, saves, supplied artwork
  and existing release payloads are unchanged.

### Review and corrections

Both original documents were reread completely, including table and Office Math
text, and compared with current state/economy/flight code, toolchain/build
configuration, user decisions and final release logs.

- Replaced the old title, proposed Python/web stack and hypothetical directory
  layout with Cosmic Conflict, Godot/GDScript and the actual Windows build.
- Clearly separated **DELIVERED / PARTIAL / PLANNED / DEFERRED** work. Only
  Ignis is playable; extra parked ships are not unlocked player hulls.
- Incorporated launch/hyperspace/descent, all existing continuous transitions,
  active timers versus untimed bosses, and the same-world handoff requirement.
- Recorded shared Concussion/Swarm/EMP costs separately from the flare pod,
  the user's gentle-banking choice, recovery/repair rules and save schema seven.
- Updated bosses, dense cratered asteroids, interactive fragments, source-color
  breakup, station machinery, objective encounters and current equipment.
- Retained the remaining three planets, six bosses, advanced primary behaviors,
  branching routes, pickups, sector map and endgame rather than implying they
  have already shipped.
- Added recommended next priorities, real dependencies, completion evidence and
  unresolved design gates. Heavier playable hulls still need renewed approval.
- Recorded lessons about scene continuity, course-relative coordinates, cached
  geometry/materials, bounded debris, atomic accounting, typed save migration,
  native versus accelerated measurements and safe isolated validation.
- Corrected stale prototype-review gates and the player's recovery-departure
  description. Historical release results remain historical.

### Evidence and document validation

- The final v0.11.0 `build.log` contains **432** passing assertions; the earlier
  `headless-tests.log` contains **427**, an intermediate checkpoint.
- Final Vulkan mission evidence uses normal effects; the OpenGL mission uses
  reduced effects. The new outline states those profiles explicitly.
- Rechecked the existing v0.11.0 installer hash against section 28. No new
  gameplay test, build or installer was needed for this documentation change.
- All **252** generated Word paragraphs/table cells match the Markdown-derived
  text. The DOCX contains seven tables with repeating headers; all seventeen
  package parts parse, with styles and relationships validated.
- Native Microsoft Word opened the revised document without repair and paginated
  it to **16 pages**. Its complete native text matches the Markdown conversion;
  rendered page previews were inspected.
- All local links across the working outline, roadmap and player guide
  resolve. The original source prompt is unchanged.
- The archived outline's SHA-256 matches the pre-edit original:

```text
FCBD240EE8E990FF2E3E259943FC58674D068F27AF0C037E06DA09008C7F74F7
```

For the next feature, start with the working outline's section 9, then read the
relevant implementation and focused tests. Keep the Markdown and Word outline
aligned, update player-facing behavior where needed, and append actual release
evidence here. Do not treat unresolved future decisions as approved defaults.

## 30. Branching ground routes and supplies: v0.12.0

The user requested continued work from the updated outline. The next bounded
milestone was the first branching ground route and supply pickups.

### Explicitly approved choices

- Safe route by default; shoot the conduit before the fork to select the hazard
  trench. Both paths rejoin smoothly before the boss without changing the
  ninety-second active ground phase.
- Three distinct pickups: **+25 shields / +2 shared ordnance / +1 separate flare**.
  Refills are capped, require the relevant equipment and do not unlock gear.
- **100 credits** for reaching the harder branch's rejoin alive, paid once and
  not combo-multiplied; extra enemies retain their normal rewards.

### Implemented and checked

- Both visible canyons are prepared before selection. Smooth lateral curves
  split at thirty seconds and rejoin at seventy, returning to the original
  ground frame. The route also works with translated/rotated launch destinations.
- A flashing amber conduit, HUD objective and target label explain the choice.
  It commits before curvature starts; late projectiles cannot change the path.
  Shooting it counts as a valid hit, not a kill, credit award or combo advance.
- Eight close-set towers and four armored, faster-firing turrets guard the
  trench. Untaken-route weapons do not fire across the canyon. The nominal
  hazard centerline was sampled against actual tower/turret collision volumes.
- Swept fly-through collection handles low frame rates and separate inventory
  caps. Full capacity and missing equipment get explicit messages. Dead pilots
  cannot collect a supply or earn the branch reward on that frame.
- Training retains its original route. Pause freezes route timing and supply
  motion. No mid-phase save was added: retries roll back choices, rewards and
  pickups with the rest of the phase, and the boss checkpoint commits them
  together. Existing schema-seven saves remain valid.
- **470 focused assertions pass** across fourteen suites. Complete headless
  safe-Rook, hazard-Rook and safe-Rescue-Skiff missions pass through both bosses,
  docking, purchases, reload, second departure, ejection and recovery.
- Native source visuals show the fork, parallel canyons, supplies and rejoin.
  The live flight collected all three supplies and reached the boss with
  100 hull without invincibility.
- An initial conduit test hit an intervening patrol fighter: the fixture now
  isolates only the aimed-switch assertion while retaining real primary-ray
  collision. Real mission tests retain all enemies. Splitting pure checks from
  the asynchronous game fixture also removed a test-only script-retention warning.
- Final exported results follow. Validation uses isolated campaigns, never the
  normal save, installed game or supplied artwork.

### Final exported validation and release

- **470 focused assertions passed** in the final build across fourteen suites.
- Final exported **Vulkan/normal effects** hazard-route Rook mission and
  **OpenGL/reduced effects** safe-route Rescue Skiff mission both completed
  without invincibility, including both bosses, docking, equipment purchases,
  exact save reload, station re-departure, all secondary stations, C deployment,
  ejection and free recovery.
- Both missions reported **0 m / 0 rad** phase-handoff discontinuity.
  Their accelerated timings are functional evidence, not GPU benchmarks.
- A separate real-speed exported flight collected all three supplies through
  physical crossings, retained two ordnance units and one flare charge, earned
  the branch reward once and reached the boss with 100 hull.
  Native captures show the readable conduit choice, split canyon, supplies and
  rejoin. Screenshot readback spikes are excluded from the following run.
- Final **normal-speed 1920x1080 Vulkan**, Intel Iris Xe, normal effects,
  complete ninety-second ground/hazard course, no screenshot readbacks:

| Metric | Result |
| --- | --- |
| Frames after initial warm-up | 11,011 |
| Mean | 7.99 ms |
| p95 | 12.92 ms |
| p99 | 14.49 ms |
| Maximum | 37.23 ms |
| Required p99 budget | 33.33 ms (30 FPS) |

This met the agreed minimum-performance budget; occasional longer frames still
occur. Both nominal paths remain clear, but manual mouse offsets can cause
collisions, including those observed from the aiming test pilot.

[Cosmic Conflict v0.12.0 Windows installer](../releases/0.12.0/CosmicConflict-0.12.0-Setup.exe):
**29,950,849 bytes**, executable version **0.12.0.0**, SHA-256:

```text
2BB5EFE4FD22DE81D5F61FE188BCF3B9B85B25DB0CB7592A5ACCF48320260423
```

- v0.11.0 remains unchanged:
  `F3AC43DD0C0A829CCCAF4FA13BA244549405FE954AC705DC6946FD0E5D3795D9`.
- The packaged player guide matches the updated source. The working outline
  now marks this milestone delivered and moves advanced-primary behavior to
  the next priority. The separate heavier-hull approval gate remains in place.
- The Word outline is synchronized with all **269** Markdown paragraphs/table
  cells. Native Word opened it without repair and paginated it to seventeen
  pages with seven tables; all package XML and forty-one local documentation
  links validate. The original prompt and archived outline retain their hashes.
- Eight explicitly named validation campaigns and temporary diagnostic files
  were removed. All validation exports exited; normal saves/preferences,
  the user's existing installation and supplied artwork remain untouched.

## 31. Advanced primaries and wider/brighter lasers: v0.13.0

The user requested the next outline item and specifically wider, brighter
advanced lasers. The user explicitly selected **piercing small ships while
stopping at cover/protected sections**, a **modestly wider physical hit area**,
and **individual plasma-bolt / fixed beam-tick accuracy**.

### Implemented behavior

- Twin Pulse retains its original precise hitscan behavior and training balance.
- The 250-credit first upgrade is now **Quad Plasma Repeaters**: four converging
  travelling bolts, one damage each, four volleys/second at Balanced power or
  five with Weapons routing. Bolts travel at 650 m/s and sweep each movement
  segment against real cover/targets; maximum travel is 490 m.
- The 500-credit second upgrade is **Tachyon Beam Cannon**: continuous light
  while firing, three damage per tick at eight ticks/second, or ten with Weapons.
  A center ray and sixteen rim rays form a 0.9 m sampled aperture. Every ray
  shares the nearest obstruction before further small-ship piercing.
- Light fighters and pirates can be pierced; heavy gunships, solid scenery,
  towers, rocks and boss sections stop the beam. Shields, locked cores, tower
  armor and iron cores retain their normal protection.
- Each bolt is an accuracy sample. A beam tick records at most one hit even
  when it damages multiple ships; normal kills and rewards still apply per ship.
  Neither weapon consumes shared ordnance or separate flare charges.
- Plasma volleys generate fourteen base heat; beam ticks generate nine.
  Existing cooling/routing modifiers and exact two-second lock remain.
- Beam segments reuse meshes/materials and update transforms rather than
  rebuilding meshes each frame. Advanced materials have their own width/gain;
  the shared world-line shader retains a default gain of one.
- Releasing LMB extinguishes the beam. Pause freezes it and travelling bolts.
  Checkpoint transitions extinguish the beam and disarm outstanding plasma so
  it can continue visually without post-checkpoint hits or rewards.
- Existing primary levels, prices, supplied artwork, transfer/loss rules and
  schema-seven saves remain compatible. Cockpit, pause and market UI now name
  the actual families and their damage units.

### Verification and lessons

- **515 focused assertions pass** across fifteen suites, including actual
  projectile impacts, piercing/cover order, partial aperture-edge cover,
  shield/iron/core/tower guards, translated courses, initial overlaps, missile
  interception, accuracy, heat, pause and checkpoint cleanup.
- Headless complete missions pass with each primary family; Tachyon also
  completes the hazard branch. All include both bosses, docking, purchases,
  equipment transfer, exact reload, station re-departure, ejection and rescue.
- Native pixel measurements use real effect nodes, not shader-setting values.
  Bright-core widths at half peak luminance:

| Renderer / effects | Twin Pulse | Quad Plasma | Tachyon |
| --- | --- | --- | --- |
| Vulkan / normal | 2 px | 4 px | 8 px |
| Vulkan / reduced glow | 2 px | 4 px | 6 px |
| OpenGL / normal | 2 px | 4 px | 6 px |
| OpenGL / reduced glow | 2 px | 4 px | 6 px |

- Upgrade peak luminance is at least twenty percent higher in every measured
  mode. Actual cockpit, pause inventory and market captures fit and remain
  readable. Glow reduction still removes halos without shrinking the upgrades
  back to baseline-width strokes.
- The first native render check caught world-axis scaling on an oblique beam;
  scaling along its local axis fixed the missing/short segment. OpenGL's
  reduced-glow measurement then required larger core widths. Neither problem
  was treated as solved merely because the material constants looked correct.
- Long, narrow shape queries produced inconsistent near-contact results after
  translated launches. The final implementation uses deterministic aperture
  rays with shared nearest-cover ordering instead of accepting unresolved
  contacts or bypassing protection. Full missions now run without those errors.
- Final exported results follow. Older installers and ordinary saves are not
  modified by validation.

### Final exported validation and package

- **515 focused assertions passed** in the final build across fifteen suites.
- Full exported missions passed for **Quad Plasma / Vulkan / normal effects**
  and **Tachyon / OpenGL / reduced effects**, the latter using the hazard route.
  Both defeat both bosses without invincibility, dock, purchase/transfer
  equipment, reload exactly, depart the existing station, exercise secondaries
  and C, then pass ejection and free-rescue checks.
- Both missions reported **0 m** maximum positional discontinuity and
  **0.00069054 rad** maximum heading difference (about 0.04 degrees), within
  the continuity check. Their accelerated/captured frame times are functional
  evidence, not the performance measurements below.
- Native original-color polygon/fade regressions also passed under Vulkan and
  OpenGL. The shared shader's default appearance and original-color breakup
  remain intact.
- Separate **normal-speed 1920x1080 Vulkan**, Intel Iris Xe, normal effects,
  ninety-second orbital benchmarks include real combat and web disarming,
  without screenshot readback:

| Metric | Quad Plasma | Tachyon Beam |
| --- | --- | --- |
| Frames after initial warm-up | 16,146 | 17,590 |
| Mean | 5.45 ms | 5.00 ms |
| p95 | 8.53 ms | 7.83 ms |
| p99 | 10.12 ms | 9.25 ms |
| Maximum | 13.46 ms | 14.05 ms |
| Required p99 budget | 33.33 ms | 33.33 ms |

Both meet the agreed minimum-performance budget for this workload; other
scenes and machines can still produce longer frames.

[Cosmic Conflict v0.13.0 Windows installer](../releases/0.13.0/CosmicConflict-0.13.0-Setup.exe):
**29,972,609 bytes**, executable version **0.13.0.0**, SHA-256:

```text
99F7AACF88D797C392143F79E2322BB3ED959FC311F5008244E593BF519DAFE0
```

- v0.12.0 remains unchanged:
  `2BB5EFE4FD22DE81D5F61FE188BCF3B9B85B25DB0CB7592A5ACCF48320260423`.
- The packaged player guide matches the source. Sector identity, the map and
  completed-planet/save foundations are now the next outlined milestone before
  adding Cryo-Vex. Heavier playable hulls remain separately gated.
- The Word outline was independently saved at 11:37 AM during this work.
  Synchronization stopped rather than overwriting the changed file. The user
  approved review/merge with a backup. All 169 extracted paragraphs/table cells
  and mathematical text exactly matched the original specification, with no
  tracked changes or comments; no new design requirements needed merging.
  Its styles and page settings are retained while restoring the current outline.
- [Exact backup of that Word revision](Archive/Cosmic_Conflict_Development_Outline_user_revision_2026-11-17_113745.docx),
  SHA-256:

```text
EA4124BFF47FFBC4AAF9EF3CC3A915D021F5480E695385B4E3FB312B6A535E0F
```

- The merged Word copy matches all **290** Markdown paragraphs/table cells.
  Native Word opened it without repair: **19 pages / seven tables**. All sixteen
  package parts parse; the reviewed styles, numbering and theme are retained.
  A fresh process verified that the updated Word file persisted.
- All **46** local documentation links resolve. The original source prompt,
  original outline archive and independently saved Word revision remain preserved.
- Seven explicitly named validation campaigns and temporary probes/comparison
  files were removed. All validation exports exited. Normal saves/preferences,
  the installed game and supplied artwork were not modified.

## 32. Volcanic eruption refinement: v0.13.1

The user supplied a four-stage volcanic reference and requested that eruptions
look more like it. The user explicitly approved **solid volcanic cones**, with
the existing heat radius/warnings/timing retained, and then asked for placement
off the side of the main valley.

- New cratered cones, flowing lava, rising smoke, an expanding billowing ash
  crown and decorative ballistic cinders replace flat rings with wire columns.
- Cones sit on the valley shoulders at approximately +/-16 m, outside the
  central marked lane. Terrain-shaped aprons blend their bases into the slopes.
  One placement avoids an existing turret at the same travel distance.
- Cone collision uses the actual generated rock/foundation vertices. It is
  solid cover; smoke/cinders introduce no extra damage or colliders.
- Existing five-meter radius, nineteen-meter heat height, 1.5-second warning,
  two-second eruption and six-second cycle remain unchanged.
- Launch material fading now includes MultiMesh geometry and the new custom
  opacity shaders; volcanic smoke does not appear prematurely during descent.
- Focused heat, collision, launch-fade and nominal-route checks pass. Native
  eruption/cooling pixel comparisons pass under Vulkan and OpenGL.
- Native preview review led to a fuller ash column, a domed crown and stronger
  volume shading. Final native checks and separate packaging are complete.

### Final verification and package

- **524 focused assertions passed** across fifteen suites. Native staged
  eruption comparisons passed under Vulkan and OpenGL; peak changed ash pixels
  grew from 1,363 to 22,020 on Vulkan and from 1,014 to 20,294 on OpenGL, then
  diminished during cooling.
- Final exported Vulkan/normal and OpenGL/reduced-effects missions passed:
  station departure/descent, ground/orbit/bosses/belt, docking, purchases,
  exact reload, second departure, secondary/flare use and ejection/rescue.
  Both reported **0 m / 0 rad** handoff discontinuity.
- Normal-speed full safe-ground benchmark, Intel Iris Xe, Vulkan/normal effects,
  actual **1920x1080** internal rendering, without screenshot readbacks:
  **19,169 frames**, mean **4.59 ms**, p95 **8.37 ms**, p99 **10.26 ms**,
  maximum **26.70 ms**; required p99 budget **33.33 ms**.
- Early native runs were interrupted, paused or resized; those were not accepted
  as passes. Validation now leaves the pointer alone, ignores physical gameplay
  input and uses an unfocusable/click-through test window. Its internal rendering
  viewport remains 1920x1080 even if the presentation window is resized; a native
  probe explicitly tested an 873x490 window. Ordinary game controls are unchanged.
- A missing screenshot directory was corrected in the runner, not hidden.
  An initial headless combat process exited with an access violation after its
  passing marker; five isolated repeats and subsequent complete builds exited
  cleanly. The failure log is retained; no matching native-export crash was
  reproduced in the final checks.

[Cosmic Conflict v0.13.1 Windows installer](../releases/0.13.1/CosmicConflict-0.13.1-Setup.exe):
**29,984,471 bytes**, executable version **0.13.1.0**, SHA-256:

```text
7E0140A3CEDB6C611AFCE9187D8006D6029D77D00348EA3B8126490A99D5FD61
```

v0.13.0 remains unchanged:
`99F7AACF88D797C392143F79E2322BB3ED959FC311F5008244E593BF519DAFE0`.

### Queued next request: Cryo-Vex

After this volcanic update, begin Cryo-Vex, including the required sector/save
foundations. The user requests **5x larger peripheral asteroids**, **at least two
different irregular oblong forms**, and **different rotation rates**, filling
the peripheral starfield view. Keep the central flight corridor clear and
verify rendered coverage, not only instance counts. Ignis should retain its
current field. Planet-access/order decisions will be resolved before implementing
the sector interface.

The user has now approved choosing **Ignis Prime or Cryo-Vex from the start and
at Astra Market**, and replaying available sectors with the current loadout and
normal sortie rewards once both are cleared. Vespera-9 and Xylo-Mire remain
unavailable; clearing two sectors is not the final four-planet campaign victory.

The Word document was left untouched while open, then synchronized after the
user saved/closed it. Its reviewed hash was unchanged. Native Word verified
**302 matching Markdown paragraphs/table cells, 20 pages and seven tables**.
All 49 local documentation links resolve. Four isolated validation campaigns
and temporary probes were removed; normal saves, the installed game and earlier
release payloads remain untouched. No volcanic validation process remains running.

## 33. Cryo-Vex implementation and release: v0.14.0

The supplied landscape reference guides faceted blue/white cliffs, a frozen
winding river, large crystalline spires, tracked vehicles and a drill-equipped
ground boss. New source now includes:

- Sector selection at the briefing and Astra Market, with Ignis/Cryo available
  and the other two planets visibly unavailable. Replays unlock after both
  available sectors are cleared; existing loadouts and normal rewards persist.
- Schema-eight checkpoints with selected/cleared sectors. Earlier schemas
  migrate to Ignis without relocating an active phase; completed-sortie history
  infers an earlier Ignis clear. The store preserves an exact migration backup.
- Cryo terrain, frozen river, side crystals, ice defense pylons, tracked gun
  vehicles, cold fighters, a glacier Bore-Mech and a Hydra drone carrier.
  The optional destroyable carrier bay stops reinforcements, not mandatory
  generator/core progression. Sector-aware developer warps mark play assisted.
- Seamless destination-colored station departure, hyperspace and descent.
- Frost fissures and tagged missiles. The user requested comparing slowdown
  against damage-only behavior. Both Rook safe-route tests completed with one
  frost event, no hull damage and identical 438.71-second scripted duration.
  Both Rescue hazard-route trials passed but avoided frost entirely.
  Retain the mild, non-stacking two-second 65% steering response for a distinct
  cold effect. Aim, weapons and Shift remain available. This choice is supported
  by automated behavior/viability tests, not human preference testing.
- Cryo-only five-times-scale peripheral asteroids, two distinct irregular
  oblong forms and varied tumble rates. Actual rendered peripheral coverage,
  corridor clearance and normal-speed performance are release gates; instance
  counts alone are not evidence of a filled starfield.

All **569 focused assertions** now pass. Initial checks exposed a floating-point
frost-expiry residual and an insufficient test wait for the full launch; both
were corrected. Additional tests cover cancellation, explicit save-error retry,
cross-sector station/sky continuity, EMP deployment suppression and separation
of optional carrier-bay health from required boss health.

The first giant distribution left a visible entrance gap (95.6% coverage).
The field attempts **2,700 giants plus 513 ordinary cold backdrop rocks**.
Actual Vulkan/OpenGL pixels across nine times/corridor positions show
**99.77%-100% peripheral coverage**. Native uploaded matrices confirm different
spin rates, stable scale/centers and aligned crater strokes; Ignis's existing
native density/tumbling regression also passes.

Early belt runs exceeded the p99 budget. Coalescing background pose uploads
per rendered frame and reducing giant tessellation/line subdivision retained
density, all craters, exact scale and both shapes. Normal-speed actual-1080p
Vulkan source checks now pass: belt p99 24.24 ms, ground 11.01 ms, Hydra 9.57 ms.
One belt run had a 1,174 ms outlier; keep that evidence rather than claiming
every frame meets budget. Final exported missions/benchmark and packaging
verification remain in progress.

Final exported scene inspection caught a further integration issue: the manual
corridor was clear, but giant rocks could obstruct the automatic pull-up.
Placement now excludes the real arrival/departure paths, including a conservative
tumbling envelope, without hiding or moving rocks mid-flight. A representative
field retains 3,189 backdrop rocks. Controller-driven tests verify the approach
and complete coast/climb/docking path, and native coverage still meets the
99.5% peripheral threshold. This fix must be included in the final package;
the first candidate installer/export is not the final release.

The user then explicitly required the outer rocks to **clear before** the
pull-up, rather than permitting an empty path through surrounding rocks.
The backdrop now has a finite longitudinal end: every complete tumbling
envelope must pass at least 24 m behind the coast endpoint before climbing.
The five-second coast and twelve-second pull-up are unchanged. No rocks are
hidden, teleported or removed mid-flight. A representative field has 2,327
backdrop rocks, preserving over 99.5% peripheral coverage through the main
traversal, opening naturally in the final seconds, and rendering **zero**
outer-rock pixels ahead when the climb begins. Earlier all-times density
checks were updated to distinguish dense traversal from the now-required exit.

### Final release evidence

- **573 focused assertions** pass in sixteen suites, including actual
  controller-driven pre-climb clearance and persistent-world docking.
- Final Vulkan/OpenGL rendered main-field coverage is 99.77%-100%, tapering
  naturally to about 71% at 59 seconds, then **zero outer-rock pixels** ahead
  at climb entry. No runtime hiding, relocation or jump cut performs the exit.
- Full exported Cryo missions pass with Vulkan/Quad Plasma and
  OpenGL/reduced-effects/Tachyon; the complete Ignis regression also passes.
  Purchases, exact reload, cross-sector departure, ejection and rescue are covered.
- Final normal-speed exported belt/docking benchmark, actual 1920x1080,
  without captures or GPU instrumentation: Vulkan 10,583 frames, mean 8.70 ms,
  p95 23.79 ms, **p99 29.76 ms**, max 96.11 ms; zero nominal-route impacts.
- OpenGL/reduced-effects completes the same route, but **fails** the p99 gate:
  8,270 frames, mean 11.13 ms, p95 33.27 ms, **p99 46.06 ms**, max 122.78 ms.
  Default Vulkan is recommended. Compatibility performance remains open;
  failed and instrumented/interrupted runs are retained, not counted as passes.
- The package now explicitly includes only the executable, resource pack,
  player guide and licenses. An exporter scratch executable initially inflated
  a candidate package; it was excluded, the installer rebuilt and the scratch
  file subsequently removed. Normal saves and the installed game were not used
  for validation.
- The Word outline was synchronized only after the user saved/closed it and its
  reviewed hash was verified unchanged. Native Word confirms all **331**
  Markdown paragraphs/table cells, **23 pages** and **seven tables**.
  Eighteen explicitly named validation campaigns were removed. Both newly
  supplied reference images were preserved byte-for-byte; attachments remain
  unchanged. The v0.13.1 installer hash still matches its published value.

[v0.14.0 installer](../releases/0.14.0/CosmicConflict-0.14.0-Setup.exe):
**30,014,538 bytes**, executable version **0.14.0.0**, unsigned. SHA-256:

```text
70BC7AE37F17415A3A72B74E87E38C0E42B84D6F8979316EE498D9FCD054B80F
```

## 34. Vespera-9 reference recorded

The user supplied a four-panel city/laser-gate/stealth reference, preserved as
[Vespera-9 visual inspiration](Reference_Art/vespera_city_gates_stealth_reference.png).
Its useful directions are magenta/violet city canyons, cyan powered machinery,
elevated traffic lanes, a layered cylindrical Overlord Defense Core, readable
gate emitters and translucent scanning/cloaking effects. The development outline
records these as future design guidance, not completed content. Vespera remains
unavailable in the sector menu. Finish the Cryo release/exit correction before
implementing the next planet; do not silently decide traffic roles or stealth
counterplay solely from the image.

## 35. Xylo-Mire reference requirements recorded

The user explicitly requested incorporating the
[Xylo-Mire concept elements](Reference_Art/xylo_swamp_geysers_biobosses_reference.png).
The original attachment is unchanged; the project copy preserves its bytes.
Required direction includes twisted swamp trunks/roots, vegetation and channels,
spore clouds, warning-marked corrosive geysers, articulated insectoid creatures,
survey rovers, the long-clawed Bio-Titan Goliath and a segmented, carapaced Hive
Mother Leviathan with prominent mandibles. The outline records the visual
requirements and outstanding gameplay choices. Xylo is not yet a playable
sector; retain the planned ground/orbital boss roles unless explicitly revised.

## 36. Vespera-9: v0.15.0 released

The user approved decorative traffic outside the flight lane, side laser gates
that always leave the center clear, visible/shootable stealth shimmer with EMP
reveal and guided-lock restoration, and permanent replay access for pilots who
already cleared the two previously available sectors.

Source implementation now includes a neon city canyon and elevated lanes,
instanced moving traffic, side gates with warning/active states and destructible
posts, a layered rotating Overlord Defense Core, a cloaking Nyx dreadnought,
stealth light fighters, city arrival/sky and third-sector navigation.
Schema nine preserves an earned replay entitlement across the upgrade; schema
eight migrations retain the exact old file and the active checkpoint.

Native inspection prompted flat street decks, richer inner facades, clearer
elevated traffic lanes, compact nearby-only labels and Nyx's distinct swept-wing
hull. Traffic stays inside building faces and below bridge decks, but above
the reachable flight corridor. Cloaked deaths restore original hull materials.

### Final verification

- **611 focused assertions** pass in seventeen suites. New cases cover exact
  schema-eight backups, grandfathered replays, gate timing/swept damage,
  central safety, pause, infrastructure accounting, real manual shots against
  cloaks, EMP reveal, guided-lock loss/reacquisition and original-color breakup.
- Full source flights pass for the basic Rook safe route and Rescue hazard
  route; final complete Ignis and Cryo regression sorties also pass.
- Final exported Vespera missions pass with Vulkan/Quad Plasma and
  OpenGL/reduced-effects/Tachyon (Rescue Skiff, hazard route), including
  purchases, exact reload, cross-sector launch, ejection and rescue.
  Phase handoffs measure zero position difference and at most 0.0007 rad.
- Native Vulkan/OpenGL comparisons confirm solid versus dashed gate states,
  zero beam pixels in the central opening, actual traffic movement and visible
  Nyx shimmer/reveal differences. Cloaking is not an invisible damage guard.
- Normal-speed final exports, actual 1920x1080, Intel Iris Xe, no screenshots:
  city/Vulkan **12,604 frames**, mean 6.98 ms, p95 12.04 ms,
  **p99 13.65 ms**, max 32.02 ms; Nyx/OpenGL reduced-effects **7,950 frames**,
  mean 5.39 ms, p95 8.15 ms, **p99 9.44 ms**, max 75.30 ms.
  Both meet the 33.33 ms p99 target; this is not an every-frame guarantee.
- The existing Cryo/OpenGL dense-field limitation is not resolved by this
  release and remains a tracked performance task.
- Native Word verifies **353 matching Markdown paragraphs/table cells**,
  **25 pages** and **seven tables** after synchronization. The previous Word
  fingerprint was unchanged before replacement. Eleven explicitly named test
  campaigns were removed; normal saves/preferences and the installed game were
  not used as fixtures. No Vespera validation process remains running.

[v0.15.0 installer](../releases/0.15.0/CosmicConflict-0.15.0-Setup.exe):
**30,038,734 bytes**, executable version **0.15.0.0**, unsigned. SHA-256:

```text
E187FA3111127AD69C99B6B9386DF4DD5B8B6021194C411EF0DF4820DB04C0E5
```

v0.14.0 is unchanged (`70BC7AE37F17415A3A72B74E87E38C0E42B84D6F8979316EE498D9FCD054B80F`).
Xylo-Mire remains next; its environmental/creature reference is preserved, but
rover roles, acid/spore behavior and full-campaign completion still need design
decisions before implementation. Heavier playable hulls remain separately gated.

## 37. Departure correction and Xylo-Mire work started

The user requested an exit-facing departure, a smooth pull-up after station
clearance and before hyperspace, no visible destination before the jump, and
an opaque, more detailed planet fading into view afterward.
The departure source now starts already facing outward. Automatic docking turns
smoothly into an outward-facing berth so subsequent launches need no camera snap.
The destination and sky disk stay hidden through hyperspace; a richer opaque
procedural globe brightens afterward instead of becoming transparent.

Final **614 focused checks** pass. Native Vulkan/OpenGL tests report zero
background leakage through all four planet styles during early and full reveal,
and zero canopy changes when removing the already-covered globe for all three
playable destinations. Vespera's city horizon now includes an opaque foundation
below its streets. Real camera tests confirm outward parking/departure and
a visible climb before hyperspace, without phase jumps.

The exported OpenGL complete mission passes with zero measured handoff
position/orientation difference. Final uncaptured normal-speed exported Cryo
launch at actual 1920x1080 (Vulkan/Iris Xe): 7,003 frames, mean 6.15 ms,
p95 11.85 ms, **p99 15.87 ms**, max 21.54 ms.

[v0.15.1 installer](../releases/0.15.1/CosmicConflict-0.15.1-Setup.exe):
**30,044,844 bytes**, unsigned; SHA-256
`F9812B54EA0C626323E385257C195AA1CEB450383FEBE37106FA2B6CE9C87DEF`.
Earlier releases remain unchanged.

Xylo gameplay choices are now confirmed: decorative non-hostile sensor rovers;
18 shield-first acid damage once per eruption contact, with no lingering DOT;
brief radar static from spores without disabling aim/steering/critical warnings;
and a unique 60-second biological field with large background Hive Mothers,
shootable/avoidable egg ships and a few optional guardians that return fire only
when attacked. The field has no extra mandatory boss and must clear before
the docking pull-up. Xylo implementation follows the departure correction.

## 38. Computer voice requested

The user supplied fifty dry-humor lines in seven categories and requested three
additional lines in each category. The voice catalog now contains all fifty
provided lines plus twenty-one additions. The user selected **Microsoft Zira**,
a restrained electronic/radio treatment, occasional banter with urgent warnings
prioritized, and small factual wording corrections. These include ten kills
versus a nonexistent 10x multiplier, the Rescue Skiff's ordnance capacity, radar-only
spore interference, and remaining rather than always-eight-second flare cooldown.

Implementation must remain offline, avoid overlapping/stale speech, provide
separate speech controls, respect pause/mute/lifecycle, and suppress unsolicited
audio in automation. The catalog exists; runtime event hooks and native audio validation are not
yet complete.

The user additionally requested at least twelve easy/hard route quips. The
catalog now includes six for each route (83 total voice lines). A route quip
must be eligible only after four seconds of silence since the previous spoken
line finished, with a one-in-four random chance. It must not interrupt or queue
behind other speech. Trigger once on the real hard-route selection or default
safe-route commitment, not on rejected/repeated conduit hits.

All **83** lines have now been generated offline with Zira into session staging:
22,050 Hz mono PCM16, approximately 4-8 seconds per line. The generation tool
validates catalog counts, IDs, PCM headers and nonempty audio payloads; it does
not send dialogue to an online service or play synthesis through the speakers.
At this checkpoint the audio was staged, not yet integrated. Section 39 records
the subsequently completed runtime and release verification.

## 39. Xylo-Mire and computer voice: v0.16.0 released

The fourth sector now has source implementations for twisted swamp trees/roots,
water channels, insectoid fighters, organic pylons/spitters, decorative survey
rovers, corrosive geysers and radar-only spore interference. Goliath has moving
legs, clawed arms and organic weak points; Leviathan has an arched segmented body,
mandibles, biological projectiles and removable spitter organs.

Its separate hive field has 232 physical egg ships and, in the representative
layout, 89 large background mothers plus 593 background egg craft. Optional
guardians remain passive until attacked. Gold egg cargo releases a collectible
biological pod; eggs break into their own polygons, never stone fragments.
The field has a finite end and clears before the docking pull-up.

Initial complete Rook and Rescue/hazard sorties pass. Actual egg-cargo shooting,
tractor collection and save persistence pass. Native tests verify visible mothers/
eggs, zero fleet pixels ahead at climb entry, and radar static that changes no
critical-warning, shield/hull or weapon-instrument pixels. A guardian test initially
placed the pilot just outside retaliation range; its fixture was corrected.
Native review prompted more twisted trees, segmented Goliath armor and an arched,
physically covered Leviathan tail rather than accepting the first simple forms.

Computer speech now has event hooks, a separate volume control, critical-warning
preemption, pause/mute/automation guards, and the precise four-second/one-in-four
route policy. All 83 local recordings map to their editable catalog, with stale
recording detection. Headless policy/event tests and actual muted native audio
playback tests pass, including processed-bus signal, pause, preemption, silence
timing and volume-off.

### Final combined-release verification

- **668 focused assertions** pass in nineteen suites. Exact schema-nine backups,
  preserved replay access, acid damage/no DOT, radar-only spores, passive-until-
  attacked guardians, egg cargo, real collision clearance and continuous
  entry/coast/pull-up/docking are covered.
- Final native Vulkan/OpenGL checks cover refined biology, visible acid
  eruptions, radar-only changes and a completely cleared forward fleet view
  before the pull-up. All four actual planetary arrivals retain opaque surfaces
  and zero visible handoff changes.
- Packaged speech loads and produces a real processed bus signal with master
  output muted. The editable catalog contains 50 supplied lines, 21 category
  additions and 12 route quips. Runtime/build fingerprints reject stale audio.
- Final exported Xylo missions pass on Vulkan/Quad Plasma and
  OpenGL/reduced-effects/Tachyon (Rescue Skiff, hazard route), including purchases,
  reload, cross-sector launch, ejection and recovery. Position handoff difference
  is zero; angular difference is at most 0.0007 rad. Complete earlier-sector
  regressions also pass.
- Final normal-speed exports, actual 1920x1080, Iris Xe, no screenshots:
  hive/Vulkan **15,259 frames**, mean 6.03 ms, p95 10.28 ms,
  **p99 11.35 ms**, max 60.03 ms; swamp/OpenGL reduced-effects **13,042 frames**,
  mean 6.75 ms, p95 11.26 ms, **p99 13.14 ms**, max 39.09 ms.
  Both satisfy the 33.33 ms p99 budget without claiming every frame is in budget.
- The older Cryo/OpenGL dense-field performance issue remains open. Full
  campaign statistics/debrief, ranks, medals, Hall of Fame and explicit tour/reset
  rules remain the next design/implementation milestone.
- Native Word verifies **389 matching Markdown paragraphs/table cells**,
  **28 pages** and **seven tables** after synchronization. Thirteen explicitly
  named validation campaigns and the verified duplicate voice-staging folder
  were removed; project audio, the voice preview, normal saves/preferences and
  previous releases are retained. No combined-release validation process remains running.

[v0.16.0 installer](../releases/0.16.0/CosmicConflict-0.16.0-Setup.exe):
**32,751,169 bytes**, executable version **0.16.0.0**, unsigned. SHA-256:

```text
FCA02C2847D89A9B9DA61DB4E62063428014FFB67B83C95CF3B768369D1EAE2D
```

During development, the published baseline and Word reading copy remained
v0.13.1. Reflective crystals and collapsing environmental ice pillars
are not implemented and must not be advertised as available.

## 40. Campaign completion systems: v0.17.0

On 2026-11-18 the user requested completion of the campaign milestone and approved:

- Keep the original humorous eight-rank ladder, with explicit tested thresholds.
- Retire records the result but leaves the completed campaign resumable.
- Continue retains ship, upgrades, credits, remaining ammunition, lifetime totals
  and earned replay access, while resetting planet clears and per-tour statistics.
- Increase only enemy/boss health by an additive 25% per tour, capped at 200%
  from tour five. Leave all other difficulty factors, timers and rewards unchanged.

Implemented a frozen fourth-planet debrief, original vector medals, tour/lifetime
statistics and actual shield-overflow hull damage. Rank points use capped accuracy,
combat, survival and best-streak components; upgrade spending never reduces rank.
The local Hall of Fame has separate assisted/unassisted views and immutable
operation/tour identities. Retire/resume/Continue retries cannot duplicate records.
Record-write failures retain the completed checkpoint; next-tour checkpoint
failures can be retried even when the record has already been saved.

Schema eleven preserves source-version backups and earlier progress. Old damage
history is explicitly unknown, not fabricated as pristine survival; the next tour
starts complete damage tracking. The initial focused run exposed Godot JSON's
float-versus-integer dictionary comparisons; loaded metrics/records now normalize
their validated counters before equality checks. Another regression exposed an
overly strict new hit-counter restriction on existing combat fixtures; the original
save acceptance contract was retained and displayed/ranked accuracy remains bounded.

The detailed approved scoring, retention and scaling contract is in section 5
of the development outline.

### Campaign release verification

- **779 focused assertions / twenty suites**, including actual menu callbacks,
  record detail selection, damage rollback, legacy history, frozen loadouts and
  retry after the Hall of Fame is saved but the next checkpoint write fails.
- Native 1920x1080 Vulkan/OpenGL screens fit their viewport and show the medal,
  statistics, ranks, continuation confirmation, Hall of Fame and resumable title.
- Exported Vulkan, first-tour Rook/Twin Pulse: four actual loops/eight bosses,
  no invincibility or secondary ammunition, zero hull damage/ejections.
  **816 points / Commodore Ace Pilot**; 283 enemies; 269,800 combat score.
- Exported OpenGL/reduced-effects, tour-five Rescue Skiff/Twin Pulse at 200%
  enemy/boss health: four actual loops/eight bosses, no upgrades, invincibility,
  replacements or secondary ammunition, zero hull damage/ejections.
  **861 points / Admiral Nova-Vanguard**; 225 enemies; 212,000 combat score.
  Earlier-tour counters are labeled fixtures; only this actual tour was flown.
- Both runs exercise retirement, exact resume, separate assisted rankings,
  idempotent next-tour creation, retained lifetime totals/wallet, save reload
  and the next sector's real scaled enemies. These accelerated runs are not
  performance measurements or human-preference playtests.

While this release was being verified, the user reported that ground terrain
appears off the planet during descent. Investigation confirms the 40km-square
flat ground foundation is revealed too early over an 8km-diameter globe.
That intermediate alignment was not covered by the old late-handoff/opacity
checks. Correct curved terrain and closer reveal are the next requested task.

## 41. Shutdown checkpoint: curved planetary arrival candidate

**Saved on 2026-11-18 at the user's request before computer shutdown.**
All source/document edits are on disk. Do not claim v0.17.1 is packaged or fully
verified yet. The last completed, packaged release remains **v0.17.0**.

### Completed campaign release

- Installer: `releases\0.17.0\CosmicConflict-0.17.0-Setup.exe`,
  **32,779,105 bytes**, unsigned.
- SHA-256: `4903A2E64592BF170792ABAE4FCBE4342A3EDA8459C0E6FC87AC8DF42381BC5E`.
- 779 focused assertions in twenty suites; both exported four-planet/eight-boss
  campaigns pass, including the baseline Rescue Skiff at capped enemy health.
- Native Word reading copy matches the completed campaign outline:
  **400 paragraphs/table cells, seven tables, 29 pages**.
  Word SHA-256: `27EFB3BD8BB42CEF0004C3E147F7D652D19E929E660D4380B7EBBF5183A6640C`.
- Four explicitly named campaign-validation save/record files were removed.
  Logs and screenshots remain. Normal saves, preferences, installed game and
  previous releases were not changed.

### User's follow-on request

The ground-attack landscape appears off the planet while descending. Curve/arch
it to match the globe and get closer before revealing it. Preserve the existing
ground gameplay and seamless handoff.

The cause was a 40km-square flat foundation fading in over an 8km-diameter globe
from only 2.4 seconds into descent. Previous tests checked opacity and the final
handoff but missed this middle-descent mismatch.

### Implemented candidate, saved but not finally packaged

- `current_dev\scripts\launch_approach.gd` now temporarily projects all prepared
  scenery onto the globe's arc using shared shader uniforms. The planet radius
  remains 4,000m and its original 80m surface-clearance allowance remains.
- New `arrival_curve.gdshaderinc` shares the coordinate mapping; new
  `arrival_ground.gdshader` replaces only temporary unshaded ground-material
  copies. Vector lines, volcanic lava/smoke and stealth shaders use the same
  curvature, defaulting to zero outside the arrival.
- Large horizon triangles are temporarily subdivided to at most 500m edges,
  using cached CPU mesh metadata. This is essential for the Vespera/Xylo
  foundations that previously consisted of just two huge triangles.
  Original meshes, materials and culling margins are retained and restored.
- Terrain remains hidden above 280m and is fully opaque below 60m, relative to
  the landing reference. Lines appear after the solid shapes (last quarter of
  the opacity progression), reducing the early ghost-wireframe appearance.
- Curvature remains full above 95m, smoothly levels below that and reaches zero
  by 20m. Original geometry/materials are restored before combat; exit cleanup
  also restores temporary resources. Target transforms, physical collisions,
  the 42-second launch path and all ninety ground-combat seconds are unchanged.
- The game/toolchain/export versions and player guide now say **0.17.1**.
  The authoritative outline and Word reading copy still describe verified
  **0.17.0**; update them after final v0.17.1 acceptance.

### Validation already performed

- Initial Godot import and launch continuity tests passed.
- Expanded native arrival tests pass on **Vulkan and OpenGL**, all four planets,
  actual 1920x1080. Captures include descent at 4, 7, 9, 11, 12, 13, 14 and
  15.5 seconds; the globe remains hidden before hyperspace and opaque afterward.
- At 12 seconds the ship is approximately 185.61m high, terrain opacity 0.394
  and curvature 1. At 13 seconds: 112.88m, opacity 0.854, curvature 1.
  At 15.5 seconds: 14.87m, full opacity and zero curvature.
- Native foundation masks contain roughly 1.47-1.49 million visible pixels and
  **zero detached pixels** outside a globe envelope allowing 2.5% radial
  clearance. Turning curvature off in the same test produces approximately
  **352,000-366,000 detached pixels**, proving the test catches the flat-sheet
  defect rather than passing a blank image.
- Globe removal at the final handoff still changes **zero canopy pixels** for
  every planet on both renderers.
- The first native mask attempt was invalid because an 8%-enlarged test sphere
  enclosed the camera. The corrected test isolates the actual foundation,
  uses 2.5% clearance and includes the flat negative control. Keep the initial
  failed log as investigation history, not as the final outcome.
- Evidence: `releases\0.17.1\validation\arrival-mobile`,
  `arrival-gl_compatibility`, `arrival-vulkan-initial`, `curve-import.log` and
  `launch-initial.log`. Screenshot/readback runs are **not** performance evidence.

### Resume here

1. Run the full existing twenty-suite build/test command against current
   v0.17.1 source. The newly expanded headless launch assertions have not yet
   been run as part of the final suite.
2. Build the v0.17.1 Windows export and installer without replacing v0.17.0.
3. Run actual normal-speed exported `--launch-benchmark` checks on Vulkan and
   OpenGL at 1920x1080, without screenshots/readbacks. Cover at least Ignis and
   Vespera; confirm p99 <=33.33ms and the real ground handoff. Investigate any
   genuine regression from the shared shader/temporary mesh changes.
4. Update the outline, player guide if needed, roadmap and synchronized Word
   reading copy with final evidence. Recheck the Word fingerprint above before
   syncing; preserve independent user edits.
5. Verify installer metadata/hash, remove only named disposable test saves and
   deliver the latest verified installer. No source commit has been made.

The separate Cryo/OpenGL dense-field performance issue, broader balance,
accessibility, soundtrack/polish and distribution work remain outside this fix.

## 42. Resumed curved-arrival release: v0.17.1

Resumed the shutdown checkpoint on 2026-11-18. The source candidate and the
Word outline fingerprint matched the saved state; no independent document edits
needed merging. The full existing build passes **785 assertions in twenty
suites** and creates a separate v0.17.1 Windows export/installer.

The native all-four-sector evidence in section 41 remains valid for this source:
zero foundation pixels outside the allowed globe envelope, a failing flat-sheet
negative control, opaque planets, no pre-hyperspace reveal, and zero changed
canopy pixels when removing the fully covered globe. Original gameplay meshes,
materials, culling bounds, target positions and collisions are restored before
the ninety-second ground assault.

### Exported normal-speed performance

These are actual 1920x1080 launches through the first five ground-combat seconds,
without screenshots or GPU timing instrumentation, on Intel Iris Xe:

- Ignis/Vulkan: 7,054 frames; mean 6.10ms; p95 10.43ms; p99 **13.69ms**;
  maximum 25.87ms.
- Vespera/Vulkan: 7,046 frames; mean 6.11ms; p95 11.21ms; p99 **16.45ms**;
  maximum 20.89ms.
- Ignis/OpenGL reduced effects: 5,239 frames; mean 8.21ms; p95 12.90ms;
  p99 **16.68ms**; maximum 38.01ms.
- Vespera/OpenGL reduced effects: 5,957 frames; mean 7.23ms; p95 12.66ms;
  p99 **17.24ms**; maximum 42.93ms.
- Cryo/Vulkan: 7,861 frames; mean 5.47ms; p95 9.54ms; p99 **11.82ms**;
  maximum 27.98ms.
- Xylo/Vulkan: 7,949 frames; mean 5.41ms; p95 10.24ms; p99 **12.03ms**;
  maximum 23.37ms.
- Cryo/OpenGL reduced effects: 5,607 frames; mean 7.68ms; p95 12.36ms;
  p99 **16.00ms**; maximum 35.09ms.
- Xylo/OpenGL reduced effects: 5,429 frames; mean 7.93ms; p95 12.84ms;
  p99 **15.98ms**; maximum 36.36ms.
- Additional Ignis/Vulkan repeat: 7,692 frames; mean 5.59ms; p95 9.87ms;
  p99 **11.28ms**; maximum 15.10ms.

All meet the 33.33ms p99 threshold, without claiming that every individual frame
is within budget. The first attempted benchmark ended during alignment without
a completion marker or engine error. Its log is retained, no application crash
event was found, and all eight sector/renderer combinations plus a second
Ignis/Vulkan repeat passed. Do not invent a cause or count that incomplete run
as success.

[v0.17.1 installer](../releases/0.17.1/CosmicConflict-0.17.1-Setup.exe):
**32,783,007 bytes**, executable version **0.17.1.0**, unsigned. SHA-256:

```text
BBDF1899974C638983FA9708CADC810BDF2FD26175CC2F4F2D433C3C42761058
```

Previous releases and normal saves/preferences are preserved; the new installer
has not been installed over the user's game. No campaign migration is required
for this visual fix. The historical shutdown steps in section 41 are superseded
by this completed release record, not another pending work list.

Final document/delivery verification: native Word matches **412 normalized
paragraphs/table cells, seven tables and 31 pages**. Its synchronized SHA-256 is
`17C303481F3040FE6EF2BA299E38F77DDD83A88ECDD4B387B8451D8C854A1B02`.
The installer fingerprint and both packaged guide/license files match the
verified build. All nine completed benchmark saves and the named incomplete-run
save were removed; logs, screenshots and acceptance proofs remain. No release
validation process is left running. The planetary-arrival request is complete.

## 43. Private-release polish: v0.18.0 implementation and validation

The user requested campaign balancing, environmental interactions, performance,
soundtrack and installer testing. On 2026-11-18 they selected:

- **Falling ice only** for this environmental pass. Reflective-crystal effects
  and radar-triggered supply caches were not selected.
- **Easier survival:** ordinary enemy missile damage 18 -> 14; shield recovery
  delay 2 -> 1.5 seconds. Keep special hazards, flight/enemy speeds, weapon heat,
  rewards and the approved additive tour-health increase/200% cap unchanged.
- Cryo side lanes retain a clear automatic centerline. Ice warns for two seconds,
  shatters after two baseline hits, deals fourteen shield-first contact damage
  once, applies no frost and grants no credits/kills/streak. Pause freezes it.
- **Restrained atmospheric ambient music**, original and offline, with a separate
  volume control and speech ducking.
- **Private/testing distribution**, still unsigned. No isolated clean Windows VM
  is available here, so local installer tests must not be called clean-machine
  certification. Public/commercial rights, licensing, naming and signing remain
  separate decisions.

### Implemented candidate

Eight falling chunks now hang from visible side-lane ice overhangs. Native tests
show actual downward motion and warning labels; focused tests cover rotated
courses, single damage, centerline clearance, two-hit destruction without farming,
pause and stage cleanup. Missile/regen changes use the existing damage/rollback
path. Recovery integrates only time after the deadline, including large timesteps.

Seven original 64-second stereo recordings cover station, four planets, travel
and restrained boss pressure. They were generated entirely offline with the
new Godot synthesis script, with no external samples or songs. Native tests pass
real playback, two-player crossfade, pause, actual voice ducking, loop wrap, zero
volume and mute/automation suppression. The initial PCM test incorrectly decoded
Godot's compressed imported QOA bytes as PCM; the corrected signal/seam check
reads the generated WAV data, while native tests independently verify imported
playback. No bad audio was substituted or accepted.

Backdrop animation now uses conservative static bounds covering every complete
rotating envelope and skips pose uploads for whole batches behind the camera.
No rock is removed, reduced, reshaped or sped up. Native Cryo coverage, distinct
spin and finite-exit checks pass.

The current v0.17.1 OpenGL baseline already passed on this session's machine:
7,965 frames, mean 11.55ms, p95 21.95ms, p99 27.74ms, max 71.25ms. The first
optimized run passed with 9,147 frames, mean 10.06ms, p95 21.64ms, p99 30.18ms,
max 105.71ms. Mean work improved, but that run's tail did not; do not claim a
uniform percentile improvement. Vulkan passed at p99 19.77ms, max 39.01ms,
over 10,975 frames. These are normal-speed 1920x1080 runs, not screenshots.

### Current verification status

The candidate passes **831 focused assertions in twenty-one suites**. Both native
audio/visual renderer checks pass. Expanded full-loadout pause layout and visible
ice supports are saved; final native recheck remains. The new installer validator
uses a separate AppId, app directory and Start Menu group; the source-archive
tool creates a versioned checksum-verified ZIP without engine caches or user saves.

Final exported full campaigns, upgraded-loadout missions, real music during
gameplay, installer install/upgrade/uninstall and source restoration are being
verified. Do not mark the private release complete until those outcomes and the
final document synchronization are recorded below.

### Final implementation and acceptance

- **831 focused assertions / twenty-one suites** pass in the final build.
- Native Vulkan/OpenGL verifies visible ice overhangs, warning and downward
  motion; title and fully equipped pause fit; actual ambient playback/fades/
  pause/loop wrap/voice ducking/off; and unchanged wider/brighter advanced beams.
- Spatially partitioned giants retain over **99.5%** measured main-field
  peripheral coverage (lowest sample approximately **99.78%**), distinct spins,
  matching solids/lines and **zero outer
  pixels** ahead at pull-up. No scale, shape, count or crater-detail reduction.
- The initial new music-enabled field missed the p99 budget at **38.11ms**;
  spatial grouping alone still missed at **34.95ms**. Diagnostic profiling
  showed rendering cost, not heavy combat simulation. Equivalent matrix-vector
  grouping in the line shader avoids unnecessary matrix-matrix work. Stable
  music now avoids redundant player/bus writes, and validation no longer
  stops/restarts music while applying each phase's settings.
- Final exported, normal-speed, actual 1920x1080 with real music playing and
  master output muted, no screenshots/GPU timing instrumentation:
  OpenGL/reduced Cryo field **7,648 frames**, mean 12.03ms, p95 23.52ms,
  **p99 29.84ms**, max 71.87ms. Repeat **7,921 frames**, mean 11.62ms,
  p95 21.66ms, **p99 26.97ms**, max 67.72ms.
  Vulkan Cryo field **10,038 frames**, mean 9.17ms, p95 17.11ms,
  **p99 18.94ms**, max 68.07ms.
  OpenGL/reduced Cryo ground **9,731 frames**, mean 9.04ms, p95 14.49ms,
  **p99 17.02ms**, max 38.00ms.
  The repeated real-music field passes resolve this workload's release gate
  on the tested hardware; they are not a guarantee of every frame or every PC.
- Exported first-tour Rook: four sectors/eight bosses, **280 enemies,
  265,000 score, rating 815**, zero hull damage/ship loss in the scripted run.
  Capped-tour Rescue Skiff: four sectors/eight bosses at 200% enemy health,
  **231 enemies, 216,800 score, rating 862**, zero hull damage/ship loss.
  Neither uses invincibility, upgrades or secondary ammunition. Prior-tour
  counters in the capped fixture are explicitly synthetic setup.
- Hawk/Quad Plasma Cryo hazard route and Rook/Tachyon Vespera full missions
  also pass, including shopping, reload, secondaries, countermeasures, forced
  ejection and recovery. All these scenarios produce real ambient audio while
  master output remains muted. The exported `--music-test` independently passes.
- One Vespera attempt was incorrectly stopped by the validation harness despite
  its log showing active gameplay: intentionally unfocusable windows do not
  always expose a .NET MainWindowHandle. Startup now uses the native validation
  stdout marker, the corrected scenario passes, and the reusable soak tool
  adopts the same fix. Do not label that harness false negative a game crash.
- Isolated v0.17.1 install, upgrade to v0.18.0, installed-game smoke checks and
  uninstall pass. Payload hashes, normal/OpenGL shortcuts, retained test data
  and unchanged normal registration/payload/saves/settings/records are checked.
  The first attempt's driver reused Inno's uninstall log filename; separate
  logs and bounded self-cleanup waiting fixed the harness, and the lifecycle
  then passed. A clean Windows VM is still unavailable and not claimed tested.
- Source archival uses fixed entry timestamps and per-file hashes, verifies
  every ZIP member, excludes build caches/binaries/user saves, and preserves
  existing archive files. The release evidence contains the independent
  extracted-source import/test result. Installer timestamp reproducibility
  and public/commercial clearance are not claimed.

[v0.18.0 private installer](../releases/0.18.0/CosmicConflict-0.18.0-Setup.exe):
**38,861,690 bytes**, executable version **0.18.0.0**, unsigned. SHA-256:

```text
191CD3CC28BE85F69A898945E36E8D0FB2A01359FA858E816AFA66E0A46CDEED
```

Final Word-parity, archive and lifecycle proof files are retained under
`releases\0.18.0\validation`. Normal saves/preferences, the installed game and
all previous release installers are preserved. Unselected reflections, supply
caches, further branches/hulls and broader accessibility work remain deferred.

The final Word copy matches **436 paragraphs/table cells, seven tables and
34 pages**, SHA-256
`D3654AB38242B2FF45639B0A9C55B6429C13F28F31053AA508313403472DDD08`.
The accepted payload's isolated install/upgrade/uninstall lifecycle was rerun
successfully after the renderer/audio refinements. Source backups also retain
the owner's original cockpit and gun overlay inputs, not only their runtime
copies. Final archive and extracted-source verification are recorded separately
in the release validation directory so they need not be embedded recursively
inside their own source snapshot.

## 44. Illustrated player manual: Word-only delivery

The user requested a detailed manual with screenshots, then chose **Word only**
and **no developer appendix**. The resulting
[player manual](Cosmic_Conflict_Player_Manual_v0.18.0.docx) is a standalone,
editable DOCX for v0.18.0:

- **37 pages, 35 player-focused chapters, 7,222 words**.
- **33 embedded images**, including 32 numbered figures and a cover montage;
  no external screenshot files are needed to open it.
- **28 reference tables**, a clickable contents list, page-number footers and
  image alternative text.
- Controls, annotated cockpit map, enlarged instrument displays, training,
  mission flow, weapons, power/defenses, routes, all four worlds/eight bosses,
  mining/hive fleet, shops/ships/prices, ejection, saves, ranks, Hall of Fame,
  Retire/Continue, sound/comfort, troubleshooting and a quick-reference glossary.

Current-build screenshots were captured with isolated illustrative campaigns,
muted output and no pointer/focus capture. Staged examples and assisted labels
are explained in the manual; they are not performance claims or developer
instructions. Temporary campaign and record files were removed.

Validation reopened the DOCX in native Word, confirmed every chapter fits its
own page, checked **614 authored text segments**, all 33 embedded images,
28 tables, internal contents destinations, footer fields and macro-free packaging.
Actual full-page print renderings verified all 37 pages, complete table text,
correct contents page numbers and absence of clipped text or broken references.
Range-only image exports produced misleading layout/reference artifacts and
were not used as final visual evidence.

Word's automated Save command failed even on a minimal document. Standard
Open XML packaging preserved the native Word layout; the result was reopened
and verified in Word. A temporary print proof was used only for validation,
not delivered as a PDF. No system execution policy was changed.

Manual size: **22,820,946 bytes**. SHA-256:

```text
64E4F4282609AFBF1BEB4B6EEC57045B19BD6F277E1E528624ADC1DE1CFACDD9
```

This is a documentation-only addition. The v0.18.0 installer and source archive
remain unchanged. The current player/build guide now links the manual and
corrects an outdated pre-polish OpenGL note; existing packaged guide copies
remain frozen with their original releases.

### Shutdown checkpoint after manual delivery

The user requested a shutdown checkpoint after the manual was completed.
The Word document above is the finished deliverable, not an unfinished draft.
All game captures, document checks and faithful 37-page print checks completed;
no manual-generation or validation process remains running.

Temporary PDF, duplicate draft, range-image proofs and save probes were removed.
The actual Word file, raw/annotated screenshots, faithful page images and
verification JSON remain saved. A temporary PDF-renderer package folder under
the assistant's session workspace could not be removed because access was
denied; it was left alone without changing permissions or execution policy.
That auxiliary folder is not needed to open the manual or play the game.
There is no unfinished manual feature to resume after shutdown.

## 45. Orbital boss intercept turn and shorter hyperspace

The user reported that the orbital boss abruptly appeared after the dogfight,
and requested a normal autopilot turn before it entered view. Investigation
confirmed that the old five-second `blockade_exit` moved straight ahead and
only constructed the boss at phase activation, 480m in front of the pilot.

The verified v0.18.1 release prepares the actual boss outside the initial forward
camera view and performs an eight-second moving quarter-turn using the existing
continuous autopilot path. The same scene and boss are retained when pursuit
starts. Visual radar/cloak animation continues, but preview pursuit/combat
clocks, missiles, thermal attacks and drone deployment do not advance. Pause
freezes the approach, and title/phase changes remove unused prepared scenes.
The existing orbital-boss checkpoint remains compatible and restores its normal
fresh pursuit. No campaign schema or economy change is introduced.

The user also requested hyperspace be **75% shorter**. Its actual duration is
now **three seconds instead of twelve**, with the streak intensity and sky
interpolation following the same duration. Eight-second undocking, six-second
clearance climb and sixteen-second planetary descent remain unchanged. The
destination still appears only after hyperspace; overall departure is about
33 rather than 42 seconds.

### Completed release verification

- **959 focused assertions in twenty-two suites** pass. New all-four-sector
  30/45/120-Hz approach tests cover moving turns, pause, original boss/scene
  reuse, unconsumed pursuit time, silent weapons/drones, stable first combat
  frame and cleanup/reload. The initial check caught a one-physics-tick visual
  preview overshoot; preview animation now uses the director's actual clamped
  transition advance instead of consuming an extra full frame.
- Launch tests measure the real three-second interval and full streak peak,
  unchanged undock/climb/descent clocks and no pre-warp planet reveal.
- Native Vulkan/OpenGL, all four planets, actual 1920x1080: preparing the boss
  changes **zero initial forward-canopy pixels**. By six seconds, the rendered
  boss contributes **3,843-5,964 pixels** in the measured canopy. Activation
  changes **zero canopy pixels**, preserving exact pose and visual time.
  Intermediate screenshots show the boss moving into view during the turn.
- The all-four-sector planetary-arrival render checks also pass with the
  shortened jump, retaining opaque globes, curved ground and unchanged handoff.
- The orbital performance benchmark now includes the intercept turn and first
  five pursuit seconds instead of stopping just before the old defect.
- Packaged normal-speed 1080p launches and orbital approaches pass, with real
  music playing and master output muted; no captures or GPU timing instrumentation:
  Ignis/Vulkan launch **5,610 frames**, mean 6.07ms, p95 11.16ms,
  **p99 20.66ms**, max 31.11ms.
  Xylo/OpenGL reduced launch **4,440 frames**, mean 7.67ms, p95 14.41ms,
  **p99 25.34ms**, max 49.83ms.
  Cryo/Vulkan dogfight + boss turn **30,450 frames**, mean 3.25ms, p95 4.78ms,
  **p99 6.32ms**, max 38.22ms.
  Vespera/OpenGL reduced dogfight + boss turn **22,538 frames**, mean 4.39ms,
  p95 6.81ms, **p99 11.15ms**, max 35.87ms.
  All meet the 33.33ms p99 target; some individual frames exceed that budget.
- Four complete exported missions pass without invincibility: Ignis/Twin Pulse/
  Vulkan, Cryo/Quad Plasma/OpenGL reduced, Vespera/Tachyon/Vulkan and Xylo/
  Twin Pulse/OpenGL reduced. Each exercises two mandatory bosses, docking,
  shopping, exact checkpoint reload, another departure, secondaries,
  countermeasures, forced ejection and recovery with actual ambient playback.
  Position handoff difference is zero; angular difference is at most
  0.0009765625 rad. Accelerated full missions are not performance evidence.

[v0.18.1 installer](../releases/0.18.1/CosmicConflict-0.18.1-Setup.exe):
**38,864,454 bytes**, executable version **0.18.1.0**, unsigned. SHA-256:

```text
E521DB098559AE63F5BC2F9ECE100EDEFBFCE09F1FDCB99EAD5345CF02158FF6
```

The player/build guide and authoritative outline describe the new timings and
approach. The v0.18.0 Word player manual is preserved rather than silently
rewritten; its core mechanics are unchanged. The new installer is separate
from prior releases; the v0.18.0 source archive remains its original snapshot.
Current changes are saved in `current_dev` and the related build/documentation
files. Normal saves/preferences and the installed game were not changed by the
validation campaigns.

The synchronized Word outline verifies **447 matching paragraphs/table cells,
seven tables and 36 pages**, SHA-256
`529162EFEF3A9E110604F50597B7C30DB0051D9351CED525061A6C318599FCDB`.
Eight explicitly named validation campaigns were removed after successful
results; their logs and native screenshots remain. The illustrated player
manual was verified unchanged using read sharing, without closing or altering
the user's open document. No release-validation process remains running.

## 46. Six-world and player-battleship expansion: implementation checkpoint

The user explicitly requested and approved an expansion beyond the earlier
deferred ship/content boundary. Agreed choices:

- Thalassa Reach: storm ocean, animated water/offshore platforms, warned
  side-lane lightning, manta enemies, Tempest Walker and Storm Ark.
- Kharon Dunes: desert dunes, broken arches/monoliths, collapsing side blocks,
  scarab enemies, Sunforge Colossus and Obelisk Sovereign.
- Aegis Titan PLAYER battleship: 2,400 CR, 240/160 hull/shield,12 ordnance,
  response0.7, radius0.85. Nova Bastion PLAYER battleship: 3,600 CR,200/220,
  16 ordnance,response0.8,radius0.78. Actual market purchase, upgrade transfer,
  distinct supplied heavy cockpit/ship art, ordinary ejection loss.
- Every boss: two hull-mounted rotating marine scanners,6 base HP with tour
  scaling,30CR once/no streak; each loss increases turret intervals25%.
- Closer boss pursuit by25%, gentle slow hull drift, steady aimable camera.
- Every automatic transition previously>4s loses EXACTLY2s. Launch6/4/3/14,
  wrecks4 unchanged, ascent8,boss turn6,belt transfer16,coast3,climb10,
  station approach7,docking6. Combat clocks remain90/90/60.
- Unfinished legacy tours expand to6 with progress intact. Frozen completed
  four-world campaigns/records stay unchanged; next/new tours require6.
  Schema12 keeps exact source-format backups and record scope is explicit.

Source implementation is saved under v0.19.0. Focused expansion/legacy tests
currently pass after correcting integration issues; final build/release
acceptance remains in progress.

Important findings: shortening the coast changed the final camera tangent, so
finite Cryo/Xylo backdrop placement now checks the actual end-camera plane,
including every rock's full rotating envelope. Shortening the clearance climb
made path-tangent orientation turn too sharply at entry; the existing smooth
orientation interpolation now preserves the exact4s duration without a snap.
Boss radar supports use actual static hull triangles, not animated limbs, and
mast height also clears the boss's physical cover volume. Actual physics rays
proved all twelve boss types' left scanners exposed; direct hit tests alone
would have missed three originally occluded mounts.

Native Vulkan/OpenGL screenshots show six selectable worlds, both purchased
heavy player cockpits, different ocean/desert ground scenes and all twelve closer
bosses. The first exported complete Thalassa/Rook mission passes; the remainder
of the new-world/player-hull mission matrix, native approach/finite-exit
regressions, six-world campaign and final packaging are still being verified.
Do not treat this implementation checkpoint as the final release outcome.

### SHUTDOWN CHECKPOINT - expansion paused at the user's request

**The user is shutting down in two minutes. All source edits are saved.
Owned validation processes were stopped. v0.19.0 is NOT a completed release;
the last fully verified/delivered release remains v0.18.1.**

#### Implemented on disk

- Six selectable worlds; Thalassa ocean/platforms/cranes/animated water and
  cloud bands/lightning/manta enemies; Kharon dunes/arches/monoliths/falling
  ruin blocks/scarab enemies; four new distinct boss models and nine original
  ambient tracks. Original worlds remain available.
- Actual Titan/Bastion player purchases, approved stats and larger hitboxes;
  separate supplied heavy cockpit copies, market icons, title-preview ship
  models, upgrade transfer, save/load and ejection loss.
- All twelve bosses have two rotating, shootable marine scanner assemblies,
  visible solid hull-mounted supports, explosive breakup, six base HP with
  tour scaling, thirty-credit non-combo reward, additive +25% turret intervals.
  Final mounts clear actual hull cover AND other boss components. Physics rays
  verified BOTH scanner targets on every boss, not only direct damage calls.
- Stable bosses are 25% closer with slow hull drift; camera/mouse aim unchanged.
- Exact shortened transitions: undock6,alignment4,hyperspace3,descent14,
  ground/orbital wreck clearance4,ascent8,boss turn6,belt transfer16,
  coast3,belt climb10,station approach7,docking6. Timers >4 lost exactly2;
  clocks <=4 remain unchanged. Combat clocks90/90/60 remain unchanged.
- Schema12 preserves exact migration backups, active equipment/credits/checkpoint/
  clears and earned replay entitlement. Unfinished tours require six worlds;
  completed legacy four-world results and existing Hall of Fame records remain
  immutable and display their original scope. Continue begins six worlds.
  A malformed legacy completed save with its frozen result missing is rejected.

#### Validation already completed

- Latest full build: **1,250 focused assertions / twenty-three suites** pass.
  Log: `releases\0.19.0\validation\build-final.log`.
- Additional final guard tests subsequently pass:
  `expansion-final-guards.log` ends with **EXPANSION_FAILURES=0**.
  These include the missing-legacy-result rejection and lightning damage along
  the full visible 45m strike (rather than only the reused frost plume's15m).
  Full-suite assertion count will rise when those extra cases are integrated
  into the final build.
- Four complete exported new-world missions pass, including shopping/reload/
  secondaries/countermeasures/ejection/rescue and real ambient playback:
  `thalassa-rook` (Vulkan/Twin Pulse), `kharon-rescue` (OpenGL/Twin Pulse),
  `thalassa-titan` (OpenGL/Quad Plasma), `kharon-bastion` (Vulkan/Tachyon).
  Their logs are functional evidence, not normal-speed performance benchmarks.
- Native Vulkan/OpenGL expansion checks show both heavy player cockpits,
  all six navigation cards, distinct new landscapes and all twelve closer
  radar-equipped bosses. Final updated screenshots are in
  `final2-test_expansion-mobile`; earlier `expansion-mobile` and
  `expansion-gl_compatibility` captures are retained.
- Six-world planetary-arrival tests pass on Vulkan and OpenGL, with zero final
  globe-removal changes. The first ocean attempt leaked1270 canopy pixels:
  fixed by separate opaque gameplay water and temporary fading arrival shaders.
  Final logs: `accepted-test_planet_arrival_render-mobile` and
  `final2-test_planet_arrival_render-gl_compatibility`.
- The OpenGL flat-foundation negative control initially had insufficient
  brightness at33% terrain opacity. It now runs above70% reveal while curvature
  is still full, retaining the positive/negative pixel tests. This was a test
  visibility issue, not permission to hide a real alignment defect.
- Six-sector orbital-approach native tests pass:
  `final2-test_orbital_arrival-mobile`.
  Shorter-coast Cryo native coverage/zero-rock-pixels-before-climb passes:
  `final2-test_cryo_render-gl_compatibility`.
- Exact launch and other automatic durations are measured in
  `test_expansion.gd`; launch continuity and all other remaining old suites pass.

#### What was interrupted, not passed

The owned PowerShell sessions `expansion-acceptance-matrix` and
`expansion-final-guards` were stopped for shutdown. The latter had already
written its passing completion sentinel. The former was still running its
first case, `six-world-bastion`: it had completed Ignis, Cryo, Vespera and Xylo
(eight bosses), then completed Thalassa ground and its ground boss and entered
Thalassa orbit. No error was logged, but the six-world campaign/debrief was NOT
finished and MUST NOT be claimed passed.

The later cases in that stopped matrix have not run:
`ocean-ground-vulkan`, `desert-ground-opengl`, `short-cryo-field`,
`short-hive-field`. These are intended normal-speed actual1080p benchmarks with
real ambient music and master mute, no captures or GPU instrumentation.
Keep the partial six-world log/checkpoint as interrupted evidence; use a new
isolated path for the final full-tour run (to avoid stale Hall of Fame entries).

#### Current candidate artifact and remaining work

Current candidate installer:
`releases\0.19.0\CosmicConflict-0.19.0-Setup.exe`,
**41,660,034 bytes**, SHA-256:
`9A69955983DA77566A0EC3E8C7992D06457AA17328E6168B91D58E43E375899E`.
It is **not the final accepted release**. Source now includes the subsequently
added legacy-result guard, full-height lightning collision and expanded tests;
rebuild before final delivery.

1. Rerun the full build/test command on saved source; fix any real regressions.
2. Finish an exported six-world/twelve-boss campaign, verifying final debrief,
   Retire/Continue, correct six-world records, exact reload and another departure.
3. Run the four normal-speed benchmarks above; preserve actual1920x1080 and
   p99<=33.33ms evidence. Recheck new-world missions if final changes require it.
4. Run the new native moving-ocean pixel comparison in `test_expansion.gd`
   (added after the previous native run). Consider a final heavy-cockpit/laser
   overlay check and Xylo finite-exit renderer regression after shortened coast.
5. Finalize player/build guide, outline and roadmap evidence. The Markdown
   outline is partially updated as a **candidate**; the Word reading copy is
   still the last verified v0.18.1, SHA-256
   `529162EFEF3A9E110604F50597B7C30DB0051D9351CED525061A6C318599FCDB`.
   Check for independent changes before synchronizing. Keep the user's v0.18.0
   illustrated manual intact (it may be open in Word).
6. Package/hash the final installer, optionally create a new source archive,
   remove only named test saves and deliver. Do not silently replace the normal
   installed game, normal campaign/preferences, old releases or Hall of Fame.

Key new files: `frontier_art.gd`, `boss_radar.gd`, `storm_lightning.gd`,
`ruin_fall.gd`, `storm_water.gdshader`, `storm_water_arrival.gdshader`,
`storm_water_surface.gdshaderinc`, `test_expansion.gd`; heavy cockpit copies
`assets\cockpits\titan.png` and `bastion.png`. Relevant edits also touch campaign
state/honors/catalog, main/HUD, boss/turret, enemy geometry, flight director,
finite backdrops, sky/planet shaders and original music generation.

No source commit was created. Original artwork, normal saves, existing records,
previous releases and the installed game have not been used as test fixtures.

## 47. v0.19.0 final acceptance and desktop-icon installer

Resumed on 2026-11-19 at the user's request. The final source, exported game and
installer include the late legacy-result/full-height-lightning guards. The old
interrupted five-world campaign remains interrupted evidence, not a passing run.

### Completed checks

- `validation\resume-build.log`: **1,254 assertions / twenty-three suites**,
  no script/engine errors, every required success sentinel present.
- `resume-test_expansion-mobile` and `resume-test_expansion-gl_compatibility`:
  actual ocean motion changes **23,773 / 23,863** canopy samples; both heavy
  cockpits, market purchases, six navigation cards and all twelve bosses pass.
- `resume-test_xylo_render-mobile` and `resume-test_xylo_render-gl_compatibility`:
  changed the regression's old hardcoded 18-second approach/65-second exit to
  the current 16-second approach and actual **63-second** coast endpoint.
  The visible fleet remains dense earlier and leaves **zero forward pixels**
  before pull-up on both renderers. No gameplay workaround was added.
- `resume2-six-world-bastion`: final exported six-world/twelve-boss campaign
  passes using baseline Twin Pulse and the actual Nova Bastion hull. No god mode,
  instant kills, replacements or failed sorties. Final result: six sorties,
  twelve bosses, 411 enemies, 45,572 CR, rating813; assisted classification remains.
  Real music plays with master muted. Retire preserves the exact completed save;
  resume, six-world Hall of Fame, Continue, record deduplication, exact next-tour
  reload and a subsequent departure all pass. Accelerated timing is functional
  evidence only, not the performance result.
- The first `resume-six-world-bastion` launch was stopped by an over-short
  five-second harness startup deadline, before readiness. The harness now waits
  up to sixty seconds for the actual profile banner while checking process
  lifetime. The fresh second run passed; no game fallback or timing change.

### Actual-1080p normal-speed performance

Each run is an uncaptured export, real music/master mute, no GPU instrumentation.
All verify the full render target, enough actual frames and p99<=33.33ms.

| Retained case | Mean / p95 / p99 / maximum milliseconds |
| --- | --- |
| `resume-ocean-ground-vulkan` | 5.61 / 8.79 / 10.28 / 75.68 |
| `resume-desert-ground-opengl` (reduced glow) | 6.47 / 10.89 / 12.63 / 349.85 |
| `resume-short-cryo-field` (OpenGL reduced) | 11.62 / 24.47 / 33.29 / 87.06 |
| `resume-repeat-short-cryo-field` (same settings) | 9.90 / 19.59 / 24.36 / 66.26 |
| `resume-short-hive-field` (Vulkan) | 5.08 / 8.50 / 9.85 / 40.84 |

Cryo was repeated because the first passing result was close to the percentile
budget. Both pass without changing scenery, resolution or the target. Isolated
long frames remain visible in the maxima; do not claim a universal 30-FPS floor
or clean-machine/other-hardware certification.

### Installer and preservation

The standard Inno Additional Tasks page offers **Create a desktop shortcut**,
unchecked on fresh installation. Start-menu shortcuts are unchanged. Production
uses the current user's Cosmic Conflict desktop link; the validation identity
uses a differently named link to avoid touching the user's own shortcut.

`validation\installer-lifecycle.log` and `installer-lab\results.json` verify:

- Fresh v0.18.1-payload install with the current installer template/default task:
  no unsolicited desktop icon.
- Upgrade to v0.19.0 with `desktopicon` selected: correct target, no extra launch
  arguments, preserved data and installed gameplay smoke checks.
- Uninstall removes its desktop and Start-menu shortcuts, application and test
  registration while preserving the explicit save/preferences/record fixtures.
- Normal game registration, payload, data and desktop icon remain byte-identical.
- The fixture is a valid unfinished schema-eleven campaign, readable by both
  versions; a schema-twelve fixture would not prove old-release compatibility.

Final installer: `releases\0.19.0\CosmicConflict-0.19.0-Setup.exe`,
**41,661,162 bytes**, SHA-256
`254211E8DDE62A379445E75E4F8387401B2E9810F329B76870F7C27D51BB02B0`.
The app's player guide matches the current source guide. It labels older release
notes as historical and corrects current world counts, hull availability, save
backups and music/automation instructions. The v0.18.0 illustrated manual is
preserved rather than silently rewritten.

The source remains uncommitted; no remote or public upload was created.
Unsigned private/testing scope and the external release gates at the top remain.

The Word outline's previous fingerprint matched before synchronization. Native
Word verifies **466 matching paragraphs/table cells, seven tables and 37 pages**.
The synchronized SHA-256 is
`99ECAAB88888DB6CB0ECFE9037B0B465EC4BBDE28570F7C91D794BA503C21667`.
Only the generated reading copy was promoted; no independent user edits or the
versioned illustrated player manual were replaced.

Final source backup:
[CosmicConflict-0.19.0-Source.zip](../releases/0.19.0/CosmicConflict-0.19.0-Source.zip),
**517 files / 115,256,088 bytes**, SHA-256
`6D1F9BE08475A6BF4FF87EE7E1AB1B8C42C15CD99844F4BB5A9768FA26517B86`.
Every archived and extracted file matched its manifest checksum. A clean
extraction imported successfully and passed **389 assertions in three focused
suites** (expansion, launch and campaign completion), supplementing the full
1,254-check source build. Restoration evidence is retained under
`validation\source-restore-*.log` and `source-restore-results.json`.

The temporary extraction, newly created isolated user-data/cache folders and
seven disposable validation save/record files were removed after verification.
Screenshots, logs, fingerprints and results remain. All owned validation
processes finished; no game, installer or helper was left running. The original
player manual's SHA-256 still matches
`64E4F4282609AFBF1BEB4B6EEC57045B19BD6F277E1E528624ADC1DE1CFACDD9`.
