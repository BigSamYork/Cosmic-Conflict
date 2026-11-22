# Cosmic Conflict - Game Design and Development Outline

**Reviewed:** 2026-11-19  
**Current verified release:** v0.19.0 - Six Worlds and Player Battleships  
**Scope:** Original, single-player, offline Windows rail shooter.

This is the current working specification, updated from the original expanded
outline, subsequent user decisions, implemented behavior, and release evidence.
It replaces obsolete proposals without treating unfinished features as delivered.
The [Word outline](Cosmos_Conflict__Game_Design_%26_AI_Development_Outline.docx)
is a synchronized reading copy. Maintain this Markdown version for future work.
The [pre-review Word outline](Archive/Cosmos_Conflict_Development_Outline_before_2026-11-17_review.docx)
preserves the original specification; the [original prompt](Cosmos_Conflict_Original_AI_Prompt.docx)
is unchanged.

The [independently saved Word revision from 2026-11-17](Archive/Cosmic_Conflict_Development_Outline_user_revision_2026-11-17_113745.docx)
is also preserved. Its complete text matched the original specification;
no new requirements were added. Its styles/page settings are retained in the
current Word copy, combined with this updated specification and release status.

**Status key:** DELIVERED means implemented in the current build; PARTIAL means only the
identified portion exists; PLANNED means not implemented; DEFERRED means wait
for the stated scope decision. Proposed future tuning is not a new user approval.

## 1. Vision and confirmed direction

- **Current name:** Cosmic Conflict. Retain historical workspace/document names
  and the legacy save directory so the rename does not break existing games.
- **Genre:** First-person 3D vector-hybrid rail shooter with between-sortie
  ship/equipment progression, not an open-world space simulator.
- **Presentation:** Detailed original solid geometry with authored glowing
  feature edges and hidden-line removal. Use supplied cockpit/gun artwork and
  selective sprites where appropriate; do not expose every triangulation edge.
- **Performance:** Detail-first 1920x1080, 30 FPS minimum goal and about 45 FPS
  preferred on integrated graphics. This supersedes the original 60-FPS goal
  and is not an imposed frame-rate cap. Measure percentiles and spikes.
- **Platform:** Godot 4 with typed GDScript; native Windows x64 export and a
  versioned installer. The original Python/Three.js proposals were not selected.
- **Flight:** Mouse aiming plus bounded, smoothed horizontal/vertical steering
  around an automatic route. Keep the nominal route clear; manual steering may
  still collide with hazards. Do not silently add an unrelated movement scheme.
- **Continuity:** Normal mission travel must feel like one flight, without
  jump cuts or scenery replacements at phase handoffs.
- **Scope:** Six planetary loops, final campaign summary, ranks, medals,
  Hall of Fame and repeat-tour rules; preserved completed four-world results.
- **Ownership:** Create original ships, enemies, stations, environments, medals,
  music and effects, or use appropriately licensed/user-supplied assets.
- **Distribution:** Private sharing initially, no fixed deadline. Preserve older
  releases and never overwrite normal saves or the installed game during tests.

The broad references remain [Star Wars (1983)](https://en.wikipedia.org/wiki/Star_Wars_(1983_video_game)),
[The Empire Strikes Back (1985)](https://en.wikipedia.org/wiki/Star_Wars:_The_Empire_Strikes_Back_(1985_video_game)),
and [Elite (1984)](https://en.wikipedia.org/wiki/Elite_(video_game)):
aiming/interception, weak-point encounters, and readable 3D silhouettes with
market progression. Do not reproduce their art, ship designs, audio or layouts.
Title/trademark clearance remains a distribution task.

### 1.1 Current delivery boundary

| Area | Verified status in v0.19.0 |
| --- | --- |
| Playable planets | DELIVERED: six complete launch/ground/boss/orbit/boss/survival/docking loops |
| Pilot systems | DELIVERED: heat, cooling, reactor routing, banking side-dash, combat streaks |
| Tactical equipment | DELIVERED: Concussion, Swarm, EMP, tactical selection and separate chaff/flares |
| Encounters | DELIVERED: branches/supplies, radars/webs, thermal/frost/acid/spore hazards, warned shootable falling ice, gates, cloaking, drones, salvage and optional pirates/guardians |
| Presentation | Six environments, biological hive/egg fleet, curved opaque arrivals, animated station, original-color breakup, computer speech and nine credited Kevin MacLeod recordings |
| Progression | DELIVERED: six-world tours, preserved four-world records, Rook/Hawk, two purchasable player battleships, rescue, upgrades, saves and debriefs |
| Weapons | DELIVERED: Twin Pulse, travelling Quad Plasma and a continuous wider/brighter piercing Tachyon Beam |
| Campaign/endgame | DELIVERED: tour/lifetime statistics, ranks/medals, local Hall of Fame, resumable retirement and capped-health repeat tours |
| Distribution | DELIVERED private scope: versioned installers, isolated install/upgrade/uninstall tests and checksum-verified source archives; clean-machine/public-release gates remain |

## 2. Controls, cockpit and combat systems

### 2.1 Controls and accessibility

| Input | Current behavior |
| --- | --- |
| Mouse | Aim and steer along a surface route or turn the ship during an orbital dogfight |
| LMB | Fire primary weapon; live sorties generate heat |
| Space | Fire the selected owned secondary station |
| RMB / Escape | Pause/status overlay; owned secondary selection is available while paused |
| Shift / B | Side-dash or barrel roll using the shared maneuver capacitor |
| WASD / hold F | Independent thrusters or hold the current line while aiming |
| V / X | Toggle the thermal governor or discharge the shield surge bank |
| R / I | Cycle scope range or repeat boss recon |
| 1 / 2 / 3 / 0 | Weapons / Shields / Engines / Balanced reactor routing |
| C | Deploy an equipped chaff/flare charge during active combat |
| Backtick | Developer testing panel |
| F11 | Fullscreen toggle |

Six live cockpit instruments show objectives, timers, damage, ammunition,
heat, radar, warnings and credits. All five flyable ships use individual
canopy frames, exterior paint colors and views of their Blender-built hulls.
Instrument textures refresh at 30 Hz; aiming and world
rendering remain full-rate.

Pause and focus loss freeze combat and automatic travel. Losing focus never
automatically resumes play. Existing settings include three flight responses,
reduced glow, audio mute and camera-motion control. Disabling camera motion
removes impact shake/evasive bank without removing dodge movement.
Computer voice and ambient music have independent volume controls; zero disables
the corresponding playback. Music defaults to 35% and ducks under speech.
The full-loadout pause overlay keeps its controls inside the 1080p viewport.
Broader UI scaling, keyboard-focus and accessibility validation remain planned.

Training is a separate 75-second, nonlethal practice course with heat-free
primary fire and no campaign rewards. It does not replay the station departure.

### 2.2 Delivered mechanics and limits

- **Gentler survival, approved for v0.18.0:** ordinary campaign missiles deal
  14 shield-first damage instead of 18. Shield recovery starts after 1.5 quiet
  seconds instead of two, counting only elapsed time after that deadline.
  Special hazards, speeds, enemy patterns, weapon heat, rewards and the 200%
  tour-health cap are unchanged. Training retains its nonlethal damage rules.
- **Heat:** Sustained primary fire builds heat; 100% causes exactly two seconds
  of primary lockout. Releasing the trigger cools quickly. Secondary fire remains
  usable. Two purchasable cooling tiers reduce heat gain.
- **Power:** Weapons increases cadence/reduces heat, Shields improves regeneration
  between hits, Engines improves steering response; 0 restores Balanced.
- **Evasion:** Shift lasts 0.65 seconds, recharges in six seconds and banks at
  most 14 degrees. It deflects projectiles, not rocks, towers, webs or thermal beams.
- **Interception:** Incoming enemy missiles can be shot. Dedicated seeker-mine
  and plasma-torpedo variants from the original proposal remain future content.
- **Streaks:** Combat kills 1-4 earn 1x credits, 5-9 earn 2x, and 10+ earn 4x.
  Hull damage breaks the in-flight streak; shield-only damage does not. Docking,
  ejection and a new sortie also reset it.
- **Accounting:** Combat score is separate from wallet spending. Generators,
  radar objectives, web disarms, mining, interception, settlement bonuses and
  developer credits are not ordinary combo kills. Rewards must never be paid twice.

### 2.3 Weapons and countermeasures

The **DELIVERED** primary progression now has distinct behavior. The user
explicitly approved small-ship piercing, a wider physical hit footprint, individual
plasma-bolt accounting and fixed-tick beam accounting on 2026-11-17.

- **Twin Pulse:** unchanged precise hitscan fire, one damage per shot, eight
  shots/second at Balanced power. Its two visual muzzle traces are one shot.
  Training retains this heat-free baseline.
- **Quad Plasma Repeaters:** the 250-credit first upgrade launches four real,
  converging bolts per volley, one damage each, at four volleys/second.
  Bolts travel at 650 m/s with swept collision and a 490 m travel limit;
  lead moving targets rather than expecting homing. Each bolt is an accuracy
  sample. A volley generates fourteen base heat.
- **Tachyon Beam Cannon:** the 500-credit second upgrade holds a continuous
  beam while LMB is pressed, dealing three damage per tick at eight ticks/second.
  It has a 490 m reach and a modestly wider, 0.9 m sampled firing aperture.
  One center ray plus sixteen rim rays share the nearest obstruction, so clear
  edges cannot shoot around cover. It pierces light fighters and pirates, but
  stops at heavy gunships, scenery/cover, towers, rocks and boss sections.
  Normal shield, weak-point and iron-core guards still apply.
- **Accounting and heat:** a beam tick is one shot and at most one hit, even
  when it damages several ships; each destroyed ship still pays its normal
  reward. Beam ticks generate nine base heat. Weapons routing raises rates
  to five plasma volleys or ten beam ticks/second and reduces heat; cooling
  upgrades still apply. The overheat lock remains exactly two seconds.
- **Presentation:** plasma cores measure twice the basic pulse width; tachyon
  cores measure three to four times its width. Both have brighter cores in
  Vulkan/OpenGL, including reduced glow. Supplied gun artwork is unchanged.
- **Lifecycle:** releasing LMB extinguishes the beam. Pause freezes effects.
  Phase checkpoints disarm travelling bolts and extinguish the beam, preventing
  post-checkpoint rewards. Neither primary uses secondary ordnance or flares.
- **Compatibility:** existing primary levels select the new behavior without
  repurchase, schema migration or loss of progress. Prices and hull-transfer/
  ejection-loss rules are unchanged. Broader campaign balancing remains planned.

| Secondary | Delivered behavior | Shared ordnance cost |
| --- | --- | --- |
| Concussion | Manually aimed missile, 8 damage; can stun a shielded gunship | 1 |
| Swarm Rockets | Three homing rockets, 3 damage each, up to three visible/unobstructed targets | 2 |
| EMP Nova | Visible/unobstructed threats within 220 m; clears missiles and stuns systems for two seconds | 3 |

Shared capacity is Rook 6 / Hawk 8 / Rescue Skiff 3. Swarm costs 500 credits,
EMP 650; new stations include up to three shared units. No Swarm lock means
no expenditure. EMP does not bypass locked boss cores, destroy generators,
award kills or grant blanket screen-wide immunity. Boss/pirate movement continues
when weapon systems are stunned.

Select an owned station while paused or docked. Paused changes persist at the
next checkpoint; market changes save immediately. This replaces the original
"future Revision 2" tactical-switching proposal.

**Chaff/flares are a separate inventory**, as explicitly chosen by the user:
the 240-credit pod includes three charges; its 60-credit reload fills only that
pod. C diverts up to four nearest incoming missiles within 110 m, then has an
eight-second cooldown. No incoming lock means no charge spent. Diverted missiles
visibly veer away and expire; ordinary collision remains possible. Beams, webs,
physical hazards and other missiles remain dangerous.

## 3. Mission loop and seamless travel

The current playable route is:

**Astra launch -> Ignis ground -> ground boss -> ascent -> orbital waves ->
orbital boss -> rising belt approach -> asteroid survival -> climb/autodock ->
Astra Market.**

Cryo, Vespera and Xylo follow the same uninterrupted structure with their own
environments, enemies and bosses. Xylo replaces the rock field with a living
hive/egg-ship fleet. Sector selection precedes departure.

Ground and orbit each have **90 active seconds**, followed by mandatory
**untimed** bosses. The belt has **60 active seconds** and no boss.
Automatic travel is outside those clocks. Never kill a surviving boss merely
to satisfy a timer.

### 3.1 Station departure and planetary arrival - DELIVERED

New sorties begin in Astra's hangar already facing the exit: six-second undock,
four-second climbing alignment, three-second hyperspace flight and fourteen-second
descent. The climb starts only after clearing the hangar/outer ring. Automatic
docking turns smoothly into an outward-facing berth, so market departure reuses
the actual station/camera without a new turn or orientation snap.
The v0.18.1 reduction of hyperspace from twelve seconds to three remains intact.
The subsequent v0.19.0 request subtracts exactly two seconds from every automatic
segment previously longer than four seconds, not two seconds repeatedly from
already-shortened values. The departure now totals approximately 27 seconds.
Wreck-clearance segments remain four seconds. Ascent is eight, boss intercept
turn six, belt transfer sixteen, belt coast three, belt climb ten, station
approach seven and docking six seconds. Combat clocks remain unchanged.

The destination globe and sky disk remain hidden through hyperspace. After
emergence, the planet's opaque surface brightens over 2.4 seconds rather than
alpha-blending stars through it. Finer geometric relief and procedural terrain,
clouds, fissures, ice/coasts or city networks provide sector-specific detail.
The globe sits beneath the ground's base elevation; fully opaque prepared
terrain already occludes it before removal. Vespera has an opaque foundation
under its city horizon for the same continuity guarantee.

The v0.17.1 approach wraps prepared terrain, foundations, structures and effects
around the globe instead of revealing a 40km-wide flat sheet above it. Temporary
foundation triangles are subdivided to at most 500m edges so the whole surface
can follow the arc, including Vespera/Xylo's formerly two-triangle foundations.
Terrain remains hidden above 280m relative to the landing reference, becomes
fully opaque by 60m, and reveals bright outlines after the solid shapes.
Curvature stays full above 95m, smoothly levels below that and reaches zero by
20m. Original materials, meshes and culling bounds are restored before combat.
The same targets and collision layout remain in place; only the non-combat
approach presentation is curved. Cached source resources are not mutated.

Prepare the destination course before descent. Planet, atmosphere and terrain
blend into the same ground scene that becomes active; all 90 ground seconds
remain at handoff. Preserve position, heading and visible objects, not just
mathematically matching coordinates between replacement scenes.

### 3.2 Ground assault - DELIVERED core, branch and supplies

- Existing content: canyon terrain, destructible tower foundations, missile
  turrets, patrol fighters and five continuously rotating radar dishes.
- Destroying a radar pays 60 credits and jams surviving downstream turrets
  within 700 m for 12 active seconds. It does not reveal a supply cache yet.
- Eight Ignis volcanic cones sit on the valley shoulders, with terrain-blended
  bases, flowing lava, staged smoke/ash crowns and decorative flying cinders.
  Their 1.5-second warning, two-second eruption, six-second cycle, five-meter
  heat radius and nineteen-meter heat height remain unchanged.
- The user approved solid cones and side-of-valley placement. Rock/foundation
  geometry is physical cover; smoke/cinders add no new damage or collisions.
  The nominal flight lane remains clear. Pause freezes the entire eruption.
  Instanced smoke and custom lava shaders fade correctly during planetary arrival.
- **Vulcan Siege Runner** is the current ground boss, replacing the working
  name "Vulcan Crawler." Destroy both shield generators before the exposed core.
  Four visible missile turrets are optional defensive targets.
- Destroyed generator nacelles and turrets disappear from the ship with local
  breakup effects. Rotating boss radar dishes add visible machinery.

**DELIVERED in v0.12.0:** One optional ground fork, with the following choices
explicitly approved by the user on 2026-11-17:

- The original shootable conduit has been superseded: lateral ship position at
  commitment selects the lane (left for safe, right for hazard). A shot does
  not select or change the route.
- The fork starts after thirty active seconds and rejoins after seventy.
  Both paths exist before the choice; smooth curves preserve position and
  heading. The ground phase remains ninety seconds with the same boss entry.
- Eight close-set towers and four armored, faster-firing missile turrets guard
  the alternate lane. Untaken-route batteries do not fire across the canyon.
  The nominal centerline clears real collision volumes, but manual steering
  and incoming missiles remain dangerous.
- Three fly-through supplies restore up to 25 shields, two shared ordnance
  units and one separate flare charge. They are collected once and capped by
  inventory capacity. Ammunition requires its owned launcher/pod; full or absent
  equipment is reported rather than silently granting equipment or bonus credits.
- Reaching the rejoin alive pays 100 credits once, without the combat multiplier.
  Extra enemies retain normal rewards. The conduit itself is not a kill.
- Route choice and uncheckpointed rewards/supplies roll back with a ground-phase
  retry. The normal boss checkpoint saves the resulting credits/ammunition
  together; schema seven remains compatible without a migration.

**PLANNED:** Further branch layouts, bridges and additional
environmental interactions. Training retains its original unbranched course.

### 3.3 Orbital dogfight - DELIVERED core, PARTIAL enemy catalog

After ninety active dogfight seconds, v0.19.0 makes a six-second moving
quarter-turn onto the capital ship's intercept course. The actual boss scene is
prepared outside the initial camera view before the turn, becomes visible as
the pilot turns, and is reused unchanged when untimed pursuit activates.
There is no straight-flight pause followed by a new boss spawning ahead.
Visual radar/cloak animation continues across handoff while combat/pursuit
clocks, missiles, sweeps and drone deployment wait for active combat.
Pause freezes the turn and preview; title/phase changes remove unused previews.
The existing orbital-boss checkpoint still resumes into a fresh normal pursuit.

All twelve bosses carry two shootable marine-style bar scanners, each on solid
supports rooted in static hull triangles and high enough to clear physical hull
cover and other boss systems. Six base hits, tour-scaled, destroy a scanner with
explosion and original-color breakup. A radar pays thirty credits once, adds no
enemy kill/combat streak, and adds 25% to turret firing intervals (50% for both).
The radars are optional and cannot unlock the core. Stable pursuit is now 25%
closer: 82.5m ground/112.5m orbital, with a slow 24-second lateral drift of
4m/8m respectively. Mouse aiming remains usable; no forced camera oscillation.

The flight computer smoothly acquires nearby fighters from multiple bearings,
including behind the pilot. Radar marks hostile contacts and the acquired target.
Several original fighter models, directional-shield gunships and web-layer drones
are implemented. Dedicated heavy-bomber/stealth behavior and the exact proposed
three-ship Dart formations remain future encounter work.

Gunship shields have banking openings and can be disabled by secondaries;
basic weapons must remain sufficient. Web tripwires warn before arming.
Shooting either endpoint disarms the web; it is not deflected by Shift.

The **Solar Flare Cruiser** has two required generators/core, six optional missile
turrets, two rotating shootable bar scanners and a separately destructible thermal projector.
Its sweep warns for 1.6 seconds, runs for three seconds and can hit once for
26 damage plus 30 heat. Destroying the projector cancels current/future sweeps.

After victory, four seconds of wreck clearance lead into a sixteen-second
rising belt approach. The prepared field remains the same at activation.
Tumbling continues while the full sixty-second gameplay clock waits.

### 3.4 Asteroid field - DELIVERED

- On Ignis, 232 physical rocks plus 2,133 distant instanced backdrop rocks fill the
  periphery. Backdrop rocks are unreachable visual dressing, not mining targets.
- Cryo retains the physical field and adds a dense finite cold backdrop, with
  roughly 2,000 giants and several hundred smaller rocks. Entry-obstructing
  placements and rocks extending past the outer field's end are omitted.
  Giant reference radii of 9-20 m are multiplied by exactly five.
  Two irregular oblong forms include an elongated body and a pinched/bent
  bilobed body; tumble rates range from 0.025 to 0.23 rad/s on varied axes.
  Verify starfield coverage in actual rendered pixels, including corridor-edge
  views. Visual pose uploads are coalesced once per rendered frame, with no
  changes to collision, clocks, density or individual spin rates.
- Reserve space around the actual arrival curve. At the other end, the outer
  field must clear completely before the pull-up, not merely leave a tunnel
  through surrounding rocks. Bound each full tumbling envelope to end at least
  24 m behind the three-second coast's endpoint camera plane. The dense field opens naturally
  in its final seconds; all placements stay fixed throughout the sortie.
- Rounded, elongated and lumpy cratered forms have varied axes, directions and
  tumble speeds. Nearby rates range from 0.06 to 0.65 rad/s.
- Destroyed full-size rocks release three smaller shootable/collidable rocks,
  plus rocky chips rather than ship-panel debris. Children last ten seconds,
  do not recursively split or yield duplicate rewards, and have a cap of 48.
- A normal shatter pays 8 credits. Gold mineral rocks release a collectible
  core worth 50 credits only when collected; cores expire after twelve seconds.
  Free ammunition drops from minerals are not implemented.
- The 400-credit tractor attracts unobstructed cores within 32 m; solid rocks
  block attraction.
- Volatile rocks warn for 0.65 seconds, damage nearby rocks and can chain.
  Close blasts can deal 28 pilot damage within 18 m. Iron cores remain indestructible.
- Three optional pirate encounters leave peacefully if ignored. Provoked pirates
  return fire; a kill has an 80-credit base bounty.

The last rocks pass naturally before a pull-up, station approach and autodocking.
Do not swap the belt for a station scene. The safe nominal lane does not make
manual steering, moving fragments or close volatile blasts harmless.

### 3.5 Astra Market and ship progression - DELIVERED core

Astra has an approximately 96 x 40 x 166 m hangar with eight parked craft in
four designs. The 256 m outer ring has service modules, trusses, six scanning
domes, four marine-style radar towers and eight swiveling/elevating friendly
turrets. Decorative parked craft are not additional playable hulls.

The market provides thumbnails, prices, benefits, current upgrades, tactical
selection and exact debrief accounting. Docking repairs hull/shields fully for
free. Completion pays 350 credits; hull bonus is one credit per remaining hull
point; accuracy pays up to 200 with at least twenty sortie shots.
Already-earned combat/mineral credits are not paid again at settlement.

| Hull | Current status |
| --- | --- |
| Rook Scout | DELIVERED: 300 credits, 100 hull / 100 shields, six-unit bay; replaces proposed Viper-V1 |
| Vector Hawk | DELIVERED: 900 credits, 80 hull / 80 shields, faster steering, smaller hitbox, eight-unit bay |
| Rescue Skiff | DELIVERED: free weak recovery craft only when no regular replacement is affordable |
| Aegis Titan | DELIVERED player battleship: 2,400 CR; 240 hull / 160 shield; 12-unit bay; 0.70 response; radius 0.85 |
| Nova Bastion | DELIVERED player battleship: 3,600 CR; 200 hull / 220 shield; 16-unit bay; 0.80 response; radius 0.78 |

Shield capacity, hull plating, cooling, tractor, primary upgrades, all three
secondary stations and the separate countermeasure pod are available.
Voluntary hull purchases transfer equipped upgrades; ammunition is limited to
the replacement bay. Ejection has different loss rules, described in section 6.

**DELIVERED:** Sector navigation at the briefing and market. New operations can
start at any of the six sectors; unfinished sectors can be selected at market.
New campaigns unlock replays after all six are cleared. Previously earned
replay entitlement remains unlocked through updates. Replays keep current
equipment and normal sortie rewards.

## 4. Six-planet content plan

All six rows now have playable loops. Environmental concepts explicitly
marked as remaining are not silently treated as delivered.

| Planet / status | Identity and hazards | Ground / orbital boss |
| --- | --- | --- |
| Ignis Prime - DELIVERED loop | Volcanic canyon; crimson/orange/gold; weapon-heating vents | Vulcan Siege Runner / Solar Flare Cruiser with thermal sweeps |
| Cryo-Vex - DELIVERED loop, PARTIAL environmental concepts | Frozen river, glacial canyon, crystal spires, tracked vehicles, ice pylons, frost fissures and warned shootable falling ice; reflective walls remain planned | Glacier Bore-Mech with rotating drill / Cryo-Carrier Hydra with destructible drone bay and frost missiles |
| Vespera-9 - DELIVERED loop | Neon city streets/towers, elevated decorative traffic, safe-center side laser gates, shootable shimmer cloaks and violet-edged belt | Mobile Overlord Defense Core with rotating machinery / swept-wing Stealth Dreadnought Nyx with EMP-reveal counterplay |
| Xylo-Mire - DELIVERED loop | Twisted swamp forest, acid geysers, radar-only spores, decorative rovers, insectoid enemies and a living hive/egg fleet | Articulated Bio-Titan Goliath / segmented Hive Mother Leviathan with organic weak points and spitter batteries |
| Thalassa Reach - DELIVERED loop | Animated storm ocean, moving cloud bands, offshore platforms/cranes, marine defense pylons, warned side-lane lightning and manta enemies | Tempest Walker / Storm Ark |
| Kharon Dunes - DELIVERED loop | Dunes, broken arches, engraved monoliths, warned collapsing side blocks, scarab enemies and amber debris belt | Sunforge Colossus / Obelisk Sovereign |

Each added planet needs distinct scenery, enemies, ground/orbital bosses, a
sector-specific belt treatment and a complete station loop. Recoloring Ignis
does not complete a planet. Keep critical warnings readable during spore,
stealth and other visibility effects.

**Cryo implementation:** the supplied reference guides faceted ice cliffs,
crystal spires, a winding frozen river, tracked vehicles and the drill boss.
The requested five-times-scale oblong peripheral field is implemented.
Decorative crystals do not yet reflect fire or topple into the flight lane.

Frost fissures use a seven-second cycle, 1.5-second warning and two active
seconds; a five-meter-radius/fifteen-meter-high field can hit once per eruption
for twelve damage. Successful frost impacts, including tagged missiles, reduce
steering response to 65% for two seconds without stacking or refreshing.
Weapons, immediate aiming, forward speed and Shift remain unchanged. Pause
freezes frost; immediate phase handoffs retain remaining duration.

The user delegated a comparison of slowdown versus damage-only behavior.
Both full Rook safe-route tests completed with one frost event, no hull damage
and identical 438.71-second scripted completion times. Both Rescue hazard-route
tests also passed, but avoided frost entirely and are viability evidence, not
proof of slowdown balance. Focused 30/45/120-Hz tests exercise actual slow steering,
unchanged weapons/Shift, non-stacking, pause and expiry. Retain the mild slowdown
for a distinct cold effect; this is a design choice supported by automated
checks, not a claim of human preference testing.

Sector identity, completed-planet tracking and migration support multi-planet
travel. Initial access remains free choice among available sectors. The user
explicitly approved retaining earned replay access when Vespera is added.
New campaigns clear all six available sectors to unlock replays; older saves
that already earned access are grandfathered. Sector completion is recorded,
with final ranks, medals and explicit new-tour choices added in v0.17.0.
Difficulty grows between tours, not between planets within the same tour.

### 4.1 Vespera-9 - implemented in v0.15.0

The user's [city, gate and stealth reference](Reference_Art/vespera_city_gates_stealth_reference.png)
guides the planet's original visual design:

- Deep urban canyons with tall layered towers, magenta/violet architecture,
  cyan powered details and elevated transit lanes.
- A cylindrical Overlord Defense Core with stacked machinery, surrounding
  rings and an imposing city-interchange silhouette.
- Readable magenta/cyan laser-gate arrays with visible posts and warning states.
- Stealth craft shown through partial silhouettes, shimmer and scanning/reveal
  planes rather than relying solely on invisible targets.

The user approved decorative traffic, permanently clear gate centers, shootable
shimmer cloaks with EMP counterplay and preserved existing replay entitlement.

- City streets are flat industrial decks, with detailed inner building facades,
  overhead bridges and elevated lanes. Eighty instanced transit pods stay above
  the reachable corridor, inside building faces and below bridge decks.
  Traffic has no combat targets, collision or rewards.
- Side gates use an eight-second cycle, two-second dashed warning and three
  active seconds. Their eleven-meter central gap always remains clear. Beams
  shift vertically; swept collision follows the actual beam positions.
  A crossing deals eighteen damage at most once per gate.
- Four-hit posts disable their own side permanently. EMP jams them for two
  seconds. Infrastructure damage counts actual weapon hits, but awards no enemy
  kills, credits or combo bonuses. Both normal and branch lanes have gates.
- Overlord is a mobile layered defense structure with three independently
  rotating machinery rings. Nyx has a separate swept-wing hull and scanning
  cloak. Required generators/core and removable missile batteries remain.
- Vespera light fighters and Nyx are visibly translucent, not invisible, during
  the cloak window (2.5-6.5 seconds of an eight-second cycle). Manual primaries
  still damage exposed targets. Swarm cannot acquire them, and existing guided
  rockets stop steering until reacquisition becomes possible.
- EMP reveals for three seconds and applies the usual two-second system stun.
  Light fighters reveal briefly when firing. Pause freezes effects. Death
  restores original hull materials before polygon breakup; weak-point shields
  are never bypassed by cloaking or EMP.

Native inspection prompted flat street foundations, richer side facades,
clearer traffic lanes and shorter nearby-only shimmer/emitter labels.
More advanced stealth repositioning/decoy patterns remain future refinements.

### 4.2 Xylo-Mire - implemented in v0.16.0

The user explicitly requested incorporating the elements in the
[swamp, geyser and biological-boss reference](Reference_Art/xylo_swamp_geysers_biobosses_reference.png).
The original implementation incorporates:

- A dark green/yellow alien wetland with enormous twisted trunks, exposed roots,
  low plants, reeds, shallow channels and drifting spore clouds.
- Corrosive geysers with visible buildup, readable acid warnings and animated
  spray. Damage timing and safe routes must be understandable from the cockpit.
- Small insect-like walkers or drones with articulated legs and distinct
  silhouettes; survey rovers and sensor equipment among the vegetation.
- Bio-Titan Goliath: a towering organic ground boss with jointed limbs,
  long forearms/claws and clear destructible weak points.
- Hive Mother Leviathan: a huge segmented, carapaced creature with prominent
  mandibles and a hive-like silhouette, retaining its orbital-boss role.

The image's biological forms, palette and environmental details are required
direction, not an instruction to copy its meshes or interface text. Spore
interference must not hide critical warnings or eliminate readable navigation.
The user has now approved decorative non-hostile sensor rovers; eighteen
shield-first acid damage once per eruption contact, without lingering corrosion;
and brief radar-only spore static while aiming, steering and critical warnings
remain usable. Xylo is selectable from the briefing and market.

Its final sixty-second flight is a biological fleet rather than a standard
asteroid belt: large background Hive Mothers, shootable/avoidable egg-like ships,
and a few optional guardians that return fire only when attacked. There is no
extra mandatory boss. The fleet leaves clear flight/entry/exit corridors and
fully clears before the docking pull-up.

- Acid and spore fields share the tested seven-second cycle, 1.5-second warning,
  two-second eruption and swept contact detection. Acid deals eighteen
  shield-first damage once per eruption contact, without DOT. Spores add two
  seconds of radar-only static without stacking/refreshing active interference.
- Survey rovers have no collision or combat targeting. Insects have moving
  legs; Goliath walks with articulated legs and clawed arms. Leviathan's raised,
  segmented tail has matching physical cover.
- The representative field contains 232 physical egg ships, 89 large background
  mothers and 593 background egg craft. Sizes/poses vary; placement is fixed
  and conservative envelopes keep entry and exit clear.
- Eggs pay eight credits once, without enemy/combination rewards, and shed
  original-colored shell polygons rather than stone fragments. Gold cargo
  releases a biological salvage pod worth fifty credits on collection; tractor
  and persistent salvage totals retain their existing rules.
- Guardians have an eighty-credit base bounty and retaliate only after being
  attacked. EMP is an attack. They expire/leave normally, never gate completion.

### 4.3 Computer voice - implemented in v0.16.0

The user supplied fifty lines across seven categories and requested three
additional lines in each. The catalog contains those fifty plus twenty-one
additions, and a further twelve route quips (six easy/six hard): **83 lines**.
The selected voice is offline **Microsoft Zira**, with restrained electronic/
radio processing, occasional banter and urgent-warning priority.

Route quips have a one-in-four random chance only after at least four seconds
of silence since the preceding utterance finished. They never interrupt or
queue. Other speech drops instead of queuing stale messages. Critical warnings
can preempt lower-priority speech; event cooldowns and silence gaps limit chatter.
Small stat-wording corrections were approved.

The briefing/pause voice-volume slider is separate from effects; zero disables
speech. Master mute and pause are honored, ordinary validation suppresses speech,
and effects gently duck during playback. Native tests verify actual processed
audio, pause, preemption, silence timing and volume-off without audible output.
The game uses packaged recordings, not an online speech service.

The user requested an editable file for future changes. Keep the
[voice catalog](../current_dev/assets/voice/lines.json) separate from gameplay
logic. Editing `text` does not change an existing recording: run the
[offline generator](../tools/generate-voice.ps1) with `-Overwrite`, then rebuild.
Preserve IDs/event tags so changed dialogue stays attached to the right trigger.
Recording fingerprints are checked by the runtime and build; stale text/audio
produces an explicit regeneration instruction instead of old spoken dialogue.

### 4.4 Private-release polish - implemented in v0.18.0

The user selected warned falling ice, easier survival, restrained ambient music
and private/testing distribution on 2026-11-18. Reflective-crystal effects and
radar-triggered supply caches were explicitly not selected for this pass.

- **Falling ice:** eight chunks hang from visible Cryo side-lane overhangs.
  Entering the 140m approach range starts a two-second warning. Two baseline
  laser hits shatter a chunk; a physical contact deals fourteen shield-first
  damage once, without frost slowdown. No credits, enemy kill or streak reward.
  The nominal centerline stays clear; pause freezes warning and falling motion.
  Shooting, translated/rotated courses, actual downward motion and stage cleanup
  are verified. No ice is added to training or other planets.
- The soundtrack uses nine Kevin MacLeod recordings. The opening, title,
  market and six worlds have individual themes. Each world keeps its track
  across combat and travel. Playback supports four-second crossfades, an
  independent volume control, pause, mute and speech ducking.
- **Dense-field efficiency:** preserve rock count, five-times scale, shapes,
  craters, spin rates and finite clearance. Conservative static bounds cover
  complete tumbling envelopes; giant instances are grouped spatially for
  renderer culling, and wholly rearward batches skip invisible pose uploads.
  Equivalent matrix-vector grouping avoids unnecessary matrix-matrix work in
  the vector-line shader. Native beam width/brightness and giant coverage
  regression checks pass.
- **Release boundary:** this is an unsigned private/testing release. Installer
  lifecycle tests use a separate AppId, directory and shortcuts and verify
  normal install/data fingerprints remain unchanged. No clean Windows VM is
  available here, so clean-machine certification is not claimed. Public/
  commercial distribution still needs rights/license/title/signing decisions.
- **Balance evidence:** automated complete tours and upgraded-loadout missions
  verify viability and exact mechanics. They do not substitute for beginner
  playtesting or prove a universal human difficulty preference.

## 5. Campaign summary, ranks and replayability

The user approved these rules on 2026-11-18. They are delivered and verified
in v0.17.0.

After every required distinct planet's actual docking, freeze a campaign debrief
with tour and lifetime statistics, a rank and an original vector medal. Count
ship losses/ejections, not pilot deaths. Include enemies, bosses, rocks, egg ships,
guardians, pirates, salvage, shots/hits, earnings/spending, score/streaks, objectives,
successful sorties and actual shield-overflow hull damage. Overkill counts only
remaining hull; shield-only, rejected and invincibility hits add no hull damage.
Reloads roll back unfinished damage with the rest of the phase.

- **Rating:** 0-1000, based on this tour. Accuracy contributes floor(hit ratio
  times 300), with at least 20 samples. Combat contributes up to 300, capped at
  100,000 combat score. Survival contributes max(0, 250 - 75 per ejection -
  floor(hull damage / 4)). Best streak contributes six per kill, capped at 150
  for 25 kills. Spending credits never penalizes rank.
- **Rank thresholds:** 0 First Lieutenant Loser; 200 Ensign Space Cadet;
  350 Flight Officer Rookie; 500 Captain Star-Strider; 625 Commander Void-Hunter;
  750 Commodore Ace Pilot; 850 Admiral Nova-Vanguard; 950 General Grandmaster.
  Each rank has an original vector medal, from Surviving Hardware to Cosmic Apex.
- **Retire:** Record the frozen statistics, score, rank, medal and final loadout
  in the local Hall of Fame, then return to the title. Unlike the initial
  recommendation, the user's approved choice keeps the completed campaign
  resumable, with its credits and equipment intact.
- **Continue:** Record the completed tour, then begin six worlds with fresh planet clears,
  per-tour counters/best streak and sortie debrief. Retain ship, upgrades,
  credits, remaining secondary ammunition/flares, lifetime totals and replay
  access. Shopping and departure resume at Astra. Do not refill ammo, pay
  settlement twice or allow repeated Continue to skip an unfinished tour.
- **Scaling:** Enemy/boss health only: 100%, 125%, 150%, 175%, then 200% from
  tour five onward. Round up to whole hit points. Apply to ground/branch turrets,
  fighters/gunships, boss parts/turrets/emitters/bays, carrier drones and optional
  pirates/guardians. Keep physical rocks, egg ships, infrastructure, hazards,
  enemy damage, projectile/flight speed, firing cadence, waves, timers, rewards
  and prices unchanged. No compound growth.
- **Hall of Fame:** Separate assisted/unassisted rankings, highest rating first,
  with selectable record details. One immutable record per operation/tour.
  Retire followed by resume/Continue remains idempotent. Records are independent
  of the active campaign, survive New Operation and are written atomically.
  A record-write failure keeps the completed checkpoint and offers retry.
- **Assistance:** Developer assistance remains sticky for the entire operation,
  including subsequent tours; it cannot be cleared by Retire or Continue.
- **Legacy damage:** Old saves cannot supply missing history. Track actual
  damage from upgrade onward, mark that first tour/lifetime incomplete and award
  no survival component for an incompletely tracked tour. The next tour has full
  damage tracking while the lifetime limitation stays visible.

## 6. Persistence, recovery and developer tools

### 6.1 Confirmed recovery and save contract

1. Destruction ejects the pilot to Astra Market; the ship, fitted upgrades,
   secondary ammunition, utilities and flare pod/charges are lost.
2. Earned/unspent credits remain. Failed sorties receive no completion, hull
   or accuracy settlement bonus. Do not add a debt system.
3. Offer an affordable replacement, or the free weak Rescue Skiff if none is
   affordable. Never permit departure without a ship.
4. Restart the unfinished planet via station departure and ground assault.
   Completed-sector records survive an ejection.
5. Mandatory bosses and routes must remain possible with emergency equipment
   and no purchased secondary ammunition.
6. Autosave at phase boundaries, docking/recovery and market changes. Restoring
   a phase rolls back its unfinished rewards, damage and ammo together.
7. An unfinished launch resumes from the station; an active ground checkpoint
   resumes ground without replaying launch. Docking resumes its approach rather
   than granting settlement before arrival.

Save schema **12** supports schemas 1-11 with exact original-format backups before
the first upgraded write. Schemas before eight become Ignis saves, retaining
their active phase/equipment; completed-sortie history infers an earlier Ignis
clear. Schema-eight saves retain their destination and receive permanent replay
entitlement if both original available sectors were cleared. New saves unlock
that entitlement on completing all currently available sectors.
Schema-nine saves retain their destination, equipment and replay entitlement;
egg/guardian counters start at zero rather than inventing past biological encounters.
Schema-ten saves retain progress and equipment and start honestly labeled
damage tracking. Completed docked saves gain a frozen debrief; active replays
finish their current sortie first. New fields include stable operation identity,
tour number, lifetime baselines, tour best streak and immutable completion result.
Continuing a tour preserves replay entitlement even after its sector clears reset.
JSON numbers are normalized to typed counters before snapshot comparisons.
The expansion stores explicit required-sector lists. Unfinished legacy saves
retain phase/equipment/credits/clears/replay access but add the two new worlds.
Completed four-world results are frozen unchanged, as are existing Hall of Fame
records without a sector-list field (their scope is four). New results carry an
explicit six-world list; both scopes are displayed. Continue from an old completed
tour begins six worlds. An invalid old completed save missing its frozen result
is rejected, not silently turned into an unfinished campaign. Heavy hulls and
new sector IDs are rejected in source schemas where they did not exist.
Selected/cleared IDs must be available, unique and consistent with completed
sortie counts. Saves use atomic temporary-file/flush/rename handling.
Malformed data and write failures must be explicit, not disguised as successful
new games or silently discarded.

Keep `%APPDATA%\Cosmos Conflict` and the existing installer upgrade identity.
Normal campaigns, preferences, supplied artwork and installed releases are
never disposable validation fixtures.

### 6.2 Delivered developer controls

Backtick exposes +1,000/+10,000 credits, wallet reset, available hull/equipment
controls, refill, god mode, zero heat, infinite secondary ordnance, one-hit
exposed targets, explicit current-boss defeat, supported phase jumps and
assisted test launches to all six sectors. Sector tests retain credits/equipment and
repair the ship; a shipless test receives a valid basic hull.

Wallet reset does not rewrite earnings/spending history. Infinite ordnance does
not mean infinite flare charges. One-hit mode still respects shield/base/iron-core
guards; explicit boss defeat bypasses the encounter without fake shot statistics
or combat rewards. Changes mark the run assisted. New toggles clear on fresh
operations, saved-run continuation and return to briefing/training.

Title/training testing uses an isolated debug campaign; non-warp controls retain
phase time and nested pause state. Future-sector and endgame jumps remain
unavailable until their destination content exists.

## 7. Technical architecture and delivery

The pinned toolchain is Godot **4.7.2-stable**, typed GDScript, Windows x64,
Vulkan Mobile by default and an OpenGL Compatibility shortcut. Inno Setup
**6.7.3** creates the installer. Revisit its non-commercial-use licensing before
commercial distribution. Current installers are unsigned.
The installer offers an optional **Create a desktop shortcut** task, unchecked
on a fresh install. Start-menu shortcuts remain standard. Uninstall removes
the selected desktop shortcut but preserves saves, preferences and records.

| Responsibility | Existing implementation |
| --- | --- |
| Lifecycle, input and encounter coordination | `main.gd` |
| Flight state and continuous reference frames | `flight_state.gd`, `flight_director.gd` |
| Primary projectiles and reusable beam rendering | `plasma_bolt.gd`, `tachyon_beam.gd`, `primary_art.gd` |
| Planet-specific hazards and visual effects | `heat_vent.gd`, `volcano_eruption.gd`, `frost_field.gd`, `city_laser_gate.gd`, `stealth_signature.gd`, `storm_lightning.gd`, `ruin_fall.gd`, planet art/shaders |
| Economy, sectors and durable checkpoints | `campaign_state.gd`, `campaign_store.gd`, `sector_catalog.gd` |
| Planet approach, orbital waves and belt | `launch_approach.gd`, `mission_world.gd` |
| Cached geometry, vector edges and breakup | `vector_art.gd`, `geometry_batch.gd`, breakup scripts/shader |
| Cockpit, market and station | `hud.gd`, `cockpit_instruments.gd`, `station_hangar.gd` |
| Computer speech and editable dialogue | `computer_voice.gd`, `voice_policy.gd`, `assets/voice/lines.json`, `generate-voice.ps1` |
| Soundtrack, recorded destruction effects and audio controls | `ambient_music.gd`, `assets/music/credits.txt`, `prepare_game_audio.py` |
| Isolated installer lifecycle and source backup | `validate-installer.ps1`, `archive-source.ps1` |

Use the existing state/economy/render helpers rather than duplicate logic.
Keep new changes focused; extract coherent responsibilities from the growing
controller when a feature requires it, not through an unrelated rewrite.

Actual layout:

```text
C:\temp\Cosmos_Conflict\
  Docs\                 Current outline, roadmap, player guide, references
  Docs\Archive\         Pre-review outline
  current_dev\          Godot project, scripts, shaders, assets, tests
  tools\                build.ps1, toolchain.json, installer.iss, bootstrap
  .tools\               Cached development tools
  releases\<version>\   Installer, app payload and validation evidence
  Cockpit_Overlays\     Preserved supplied artwork
  Gun_Overlays\         Preserved supplied artwork
```

The original proposed Python file tree and `versions\` layout were not adopted.
Versioned installers and source ZIPs live under `releases\<version>`.
Source archives include source, generated recordings, import settings, tools,
documentation and per-file hashes; engine/template caches, `.godot` caches,
release products and user saves are excluded. Restore the pinned tool cache
before rebuilding. Archive hashes are verified; this does not claim that
timestamped installer binaries are bit-for-bit reproducible.
Local Git remains uncommitted/untracked, without a remote, and is not a separate
source backup. The two new release-check scripts require PowerShell 7 or newer.

The [build script](../tools/build.ps1) imports the project, runs twenty-three focused
headless suites, exports Windows and compiles the installer. Use `-TestOnly` for
the import/test steps. Current tools/templates are cached; normal development
and gameplay do not require an internet connection.

## 8. Lessons learned and non-regression rules

- **Continuity is visual as well as numerical.** Prepare upcoming scenery outside
  view and retain the same nodes through handoff. Preserve tumbling clocks,
  camera heading and transit state; start combat timers only at activation.
- **Route decisions need a commitment boundary.** Choose before curvature starts,
  reject late hits, and rejoin the original frame exactly. Test physical
  centerline clearance and actual shots/collection, not only route formulas.
- **Coordinates must be course-relative.** Ground scenery, turret targeting,
  patrols, pursuit and ascent must work after translating/rotating the route.
  Global negative-Z assumptions break launches from the current station.
- **Physics and appearance can be separate.** Tumble visual rocks without moving
  the original collision body; interactive children need swept relative-motion
  collision. Distant MultiMesh rocks are not silently collidable obstacles.
- **Breakup should match its source.** Ships release actual source polygons that
  retain original face/trim colors, drift/tumble at full size and fade. Asteroids
  additionally produce smaller rocks. Do not replace either with generic panels.
- **Avoid impact-time GPU readbacks.** Cache source geometry/colors on the CPU.
  Use instancing and bounded fragment populations; preserve geometry while
  reducing expensive effects when possible.
- **Respect rendering-cache ownership.** Duplicate materials for approach fades,
  restore opaque materials before play, and do not mutate shared cached originals.
  Animated attachments belong outside cached flat-model helpers.
- **Measure visual requirements in pixels.** A wider/brighter material setting
  is not proof of its rendered result. Native tests caught incorrect beam-axis
  scaling and insufficient OpenGL reduced-glow width before release.
- **Separate visual lines from combat samples.** Four plasma bolts are four
  shots, but four tachyon muzzle traces share one damage tick. All rays in the
  wider firing aperture obey the same nearest cover before continuing through
  eligible small ships.
- **Persist transactions, not fragments of them.** Wallet, loadout, damage, ammo,
  phase state and rewards must agree after reload. Settlement is idempotent.
  New schemas validate old data before conversion and retain accurate backups.
- **Respect GDScript/runtime details.** JSON numbers may be floats; validate then
  convert. Avoid mixing typed arrays with untyped empty arrays in ternaries.
  Keep shared constants in the appropriate state layer, not actor dependency cycles.
- **Separate functionality from performance.** Accelerated/headless missions
  prove behavior, not GPU frame rate. Measure normal-speed exports at actual
  resolution, identify renderer/effects/GPU, and avoid screenshot readbacks.
- **Do not trust exit code alone.** Godot can report script errors and exit zero.
  Scan errors and require explicit successful completion markers. Do not run
  editor import concurrently with native tests on the same project/cache.
- **Validation must not disturb the user.** Use isolated campaigns and tracked
  process IDs. Engine file logs can buffer until exit; redirected stdout's
  validation-startup marker confirms native initialization. Do not rely solely
  on .NET MainWindowHandle for intentionally unfocusable test windows.
  Automated runs must not capture/warp the
  pointer or consume physical gameplay input. Fix the internal rendering
  viewport at 1920x1080 rather than assuming the presentation window remains
  that size. Never kill unrelated game/editor processes.

Original synthesized effects, mute, impact shake and an original restrained
ambient soundtrack are delivered. The user chose ambient rather than synthwave.
Deliberate hit-stop and further polish remain optional future work; effects
must not obscure warnings or undermine comfort settings.

## 9. Prioritized remaining work

This is the recommended sequence, not a promise of specific version numbers
or dates. Each increment should end in a separately packaged, verified result.
The user's positive playtest feedback and repeated requests to continue have
passed the original prototype-review gate; do not reset progress to that gate.

| Priority | Work and dependencies | Completion evidence |
| --- | --- | --- |
| Done | v0.12.0 ground fork, track-switch conduit and three supply types | Continuous 30/45-Hz routes, real shooting/collection, exact rewards, pause and checkpoint tests; see section 10 |
| Done | v0.13.0 Quad Plasma and piercing Tachyon Beam | Real projectiles, bounded tick accuracy, heat/cover/weak-point tests, native width and brightness measurements; see section 10 |
| Done | v0.14.0 sector progression, Cryo-Vex and finite outer-field exit | 573 focused checks, native coverage/clearance, full exported missions and default-Vulkan 1080p performance; see section 10 |
| Done | v0.15.0 Vespera city, gates, stealth and permanent replay access | 611 focused checks, full exported missions, native appearance and normal-speed exported performance pass |
| Done | v0.15.1 outward departure, pre-warp climb and opaque detailed arrival | 614 focused checks, native zero-leak/zero-handoff-change comparisons and exported launch verification |
| Done | v0.16.0 Xylo-Mire, hive field and computer voice | 668 focused checks, full exported sorties, native visual/audio checks and normal-speed export performance pass |
| Done | v0.17.0 campaign damage/statistics, debrief, ranks, original medals, Hall of Fame, Retire/Continue | 779 focused checks; two exported four-planet/eight-boss campaigns, including capped-health Rescue Skiff; native screen and transaction/retry verification |
| Done | v0.17.1 curved planetary terrain and closer ground reveal | 785 focused checks; native intermediate-arrival alignment/negative controls and zero-change handoffs on both renderers; exported normal-speed 1080p launch benchmarks |
| Done | v0.18.0 approved private-release polish: easier survival, warned falling ice, ambient score, dense-field optimization, isolated installer tests and source archive | 831 focused checks; native visual/audio regressions; full normal/capped campaigns and upgraded missions; repeated real-music 1080p performance; installer lifecycle and source restoration |
| Done | v0.18.1 orbital boss intercept turn and 75% shorter hyperspace | 959 focused checks; all-four-sector native zero-pop boss handoffs; three-second warp; four full exported missions and normal-speed launch/orbit benchmarks |
| Done | v0.19.0 two worlds, two player battleships, destructible boss scanners, closer pursuit, exact shorter transitions and optional desktop icon | 1,254 checks/23 suites; full six-world/twelve-boss campaign and endgame; both-renderer moving-ocean/finite-hive checks; five actual-1080p benchmarks; isolated shortcut/install/upgrade/uninstall verification |
| 1 | External release gates and optional further refinement | Clean Windows VM/other hardware, human balance/accessibility feedback, public/commercial rights/title/signing decisions; unselected environmental concepts and ship catalog remain deferred |

The user explicitly approved two heavy PLAYER battleships for v0.19.0, superseding
the earlier scout/interceptor-only boundary. Titan and Bastion are market hull
purchases, not parked props or hostile bosses. Further hull/ordnance concepts
outside those two remain deferred.

Decisions still to resolve at the relevant milestone: additional playable hulls
and public debug policy/signing. Rank tone, Retire/Continue retention and bounded
additive health scaling are approved and implemented in section 5.
Primary targeting/accuracy choices are resolved in section 2.3; the first
branch's defaults/rewards and supplies are resolved in section 3.2. Initial
sector choice and available-sector replays are resolved in section 4.
Vespera traffic, gate safety, stealth counterplay and grandfathered replays are
resolved in section 4.1.
Xylo rover/acid/spore/fleet behavior and computer-voice policy are resolved in
sections 4.2-4.3.
The remaining decisions are not silently approved defaults.

**User-requested arrival correction (2026-11-18), delivered in v0.17.1:**
the arriving terrain now follows the globe's arc and appears closer to the
surface. Native tests cover the intermediate alignment that the earlier
opaque-globe/late-handoff checks missed, without changing ground gameplay.

## 10. Verified baseline and future acceptance

### v0.19.0 six-world expansion and optional desktop shortcut

- **1,254 focused assertions / twenty-three suites** pass on the final source.
  Legacy frozen four-world results coexist unchanged with new six-world records.
  Exact automatic durations, full-height lightning contact, heavy-hull purchases,
  persistence/ejection and both shootable radar heads on all twelve bosses pass.
- The final exported Nova Bastion/Twin Pulse campaign completes all six worlds
  and twelve bosses without invincibility, instant kills or replacement. The
  six-world debrief, assisted Hall of Fame, Retire/resume, Continue/deduplication,
  exact next-tour reload and another departure pass. Earlier complete new-world
  missions also cover Rook, Rescue Skiff, Titan/Quad Plasma and Bastion/Tachyon.
- Both native renderers verify moving ocean waves and all twelve radar-equipped
  bosses. The updated hive exit test samples the actual shortened endpoint at
  63 seconds, not the old 65: zero forward hive pixels on Vulkan and OpenGL.
  Six-world curved arrivals and prepared orbital boss handoffs remain verified.
- Uncaptured normal-speed exports use actual 1920x1080 rendering and real ambient
  playback with muted master output. P99 frame times: Thalassa ground/Vulkan
  **10.28ms**; Kharon ground/OpenGL reduced **12.63ms**; shortened Cryo field/OpenGL
  reduced **33.29ms**, repeated at **24.36ms**; Xylo hive/Vulkan **9.85ms**.
  All meet the 33.33ms percentile budget. Isolated longer frames still occur;
  this is not an all-frame minimum or other-hardware certification.
- Isolated v0.18.1 install, v0.19.0 upgrade, installed gameplay and uninstall pass.
  Fresh defaults create no desktop icon; selecting the task creates the correct
  shortcut; uninstall removes it. Normal installation, data and desktop shortcut
  fingerprints remain unchanged. The validation campaign is schema eleven so
  both releases can genuinely read the preservation fixture.
- [Final Windows installer](../releases/0.19.0/CosmicConflict-0.19.0-Setup.exe):
  **41,661,162 bytes**, SHA-256
  `254211E8DDE62A379445E75E4F8387401B2E9810F329B76870F7C27D51BB02B0`.
  This is unsigned/private testing. Earlier releases and the versioned v0.18.0
  illustrated manual remain intact; the current player guide covers the expansion.

### v0.18.1 smooth orbital boss arrival and shortened jump

- **959 focused assertions** pass across twenty-two suites. All four sectors
  verify the prepared boss turn at 30/45/120Hz, including translated/pitched
  courses, active evasion, pause, no preview attacks or rewards, intact core
  protection, scene/pose reuse, continuous first pursuit frame, cleanup and reload.
- Hyperspace is **three seconds instead of twelve**, measured within one
  simulation tick, with its full streak intensity retained. Undock/climb/descent
  remain 8/6/16 seconds; the whole departure is approximately 33 seconds.
  The shorter segment keeps its continuous endpoints and hidden-before-arrival
  planet behavior.
- Native Vulkan/OpenGL, all four sectors, actual 1920x1080: adding the prepared
  boss changes **zero initial forward-canopy pixels**. At six seconds of the
  turn it contributes **3,843-5,964 visible canopy pixels**. Activating pursuit
  changes **zero canopy pixels** and preserves the actual boss pose and visual
  clock. Full planetary-arrival render tests still pass with the shorter jump.
- All four exported sorties pass without invincibility, including both mandatory
  bosses, docking, purchases, exact reload, another departure, secondaries,
  countermeasures, ejection and recovery. Tests cover Twin Pulse, Quad Plasma
  and Tachyon; real ambient music plays with master output muted. Recorded
  phase handoffs have **0m** position difference and at most **0.00098 rad**
  angular difference. Accelerated sorties are functional evidence, not benchmarks.
- Normal-speed exported tests, real music, actual 1920x1080, no captures or
  GPU timing instrumentation: Ignis launch/Vulkan **5,610 frames**, mean 6.07ms,
  p95 11.16ms, **p99 20.66ms**, max 31.11ms; Xylo launch/OpenGL reduced
  **4,440 frames**, mean 7.67ms, p95 14.41ms, **p99 25.34ms**, max 49.83ms.
  Cryo orbital stage/turn/Vulkan **30,450 frames**, mean 3.25ms, p95 4.78ms,
  **p99 6.32ms**, max 38.22ms; Vespera orbit/turn/OpenGL reduced
  **22,538 frames**, mean 4.39ms, p95 6.81ms, **p99 11.15ms**, max 35.87ms.
  Each passes the 33.33ms p99 target; isolated longer frames are not concealed.
- [v0.18.1 installer](../releases/0.18.1/CosmicConflict-0.18.1-Setup.exe):
  **38,864,454 bytes**, executable version **0.18.1.0**, unsigned. SHA-256:
  `E521DB098559AE63F5BC2F9ECE100EDEFBFCE09F1FDCB99EAD5345CF02158FF6`.
  Save schema eleven, normal user data, previous releases and the v0.18.0
  illustrated player manual are retained. The installed game was not replaced
  automatically.

### v0.18.0 private-release polish verified release

- **831 focused assertions** pass across twenty-one suites. New cases cover
  30/45/120-Hz recovery timing and falling-ice contact, actual missile damage,
  non-farmable ice destruction, safe centerline/pause/stage cleanup, conservative
  rotating bounds, and all seven recordings' signal levels and loop seams.
- Native Vulkan/OpenGL verifies real music, fades, pause, speech ducking, loop
  wrap and volume-off; visible ice supports/warnings/downward motion; and title/
  full-loadout pause fit. Advanced beams retain the required width/brightness.
  Giant peripheral coverage remains above **99.5%** during the measured
  main field (lowest sample approximately **99.78%**), with **zero outer-rock
  pixels** ahead before the pull-up.
- Exported first-tour Rook and capped-health Rescue Skiff each complete all four
  sectors/eight bosses without invincibility, upgrades, secondary ammunition
  or ship loss. Real ambient music plays throughout. The Rook records 280
  enemies/265,000 score; the capped Skiff 231 enemies/216,800 score. Both have
  zero hull damage in these scripted runs. Prior-tour counters in the capped
  fixture are not represented as played tours.
- Complete Hawk/Quad Plasma Cryo hazard-route and Rook/Tachyon Vespera missions
  also pass, including purchases, exact reload, weapon switching, countermeasures,
  forced ejection and rescue. Accelerated missions are functional/balance
  evidence, not performance benchmarks.
- Final exported, normal-speed, actual 1920x1080 with **real music playing**
  (master output muted), without captures or GPU instrumentation:
  Cryo/OpenGL reduced **7,648 frames**, mean 12.03ms, p95 23.52ms,
  **p99 29.84ms**, max 71.87ms. Repeat: **7,921 frames**, mean 11.62ms,
  p95 21.66ms, **p99 26.97ms**, max 67.72ms.
  Cryo/Vulkan **10,038 frames**, mean 9.17ms, p95 17.11ms,
  **p99 18.94ms**, max 68.07ms.
  Cryo ground/OpenGL reduced **9,731 frames**, mean 9.04ms, p95 14.49ms,
  **p99 17.02ms**, max 38.00ms.
  All meet the 33.33ms p99 gate; isolated longer frames remain documented.
- The historical Cryo/OpenGL failure was not reproduced in the initial current
  baseline (p99 27.74ms without music). Initial new real-music candidates did
  fail at p99 38.11/34.95ms. Further renderer/audio changes were required before
  the final repeated passes above. Failed/instrumented runs remain evidence,
  not performance successes.
- Isolated v0.17.1 install -> v0.18.0 upgrade -> uninstall passes. Installed
  payload hashes, both shortcuts, installed-game startup/play, retained test
  saves/settings/Hall of Fame, and unchanged normal registration/payload/data
  are verified. Clean-machine validation remains explicitly unperformed.
- [v0.18.0 installer](../releases/0.18.0/CosmicConflict-0.18.0-Setup.exe):
  **38,861,690 bytes**, executable version **0.18.0.0**, unsigned. SHA-256:
  `191CD3CC28BE85F69A898945E36E8D0FB2A01359FA858E816AFA66E0A46CDEED`.
  Campaign/Hall of Fame schema eleven and previous releases are preserved.

### v0.17.1 curved planetary arrival verified release

- **785 focused assertions** pass across twenty suites. The expanded launch
  checks verify the below-280m reveal, visible curvature, original mesh/material/
  culling restoration, physical corridor clearance and continuous 30/45-Hz
  handoffs with all ninety combat seconds intact.
- Native Vulkan/OpenGL, all four planets, actual 1920x1080: curved foundation
  masks contain approximately 1.47-1.49 million visible pixels with **zero
  detached pixels** outside a globe envelope allowing 2.5% radial clearance.
  Disabling curvature in the same scene produces roughly **352,000-366,000
  detached pixels**, so the check demonstrably detects the original flat sheet.
- Intermediate images cover 4, 7, 9, 11, 12, 13, 14 and 15.5 descent seconds.
  The globe remains hidden through hyperspace and opaque afterward. Removing
  it at the final handoff changes **zero canopy pixels** for every sector on
  both renderers.
- Normal-speed exported launch checks measure the actual 1920x1080 viewport,
  without screenshots or timing instrumentation. Ignis/Vulkan: 7,054 frames,
  mean 6.10ms, p95 10.43ms, **p99 13.69ms**, max 25.87ms.
  Vespera/Vulkan: 7,046 frames, mean 6.11ms, p95 11.21ms,
  **p99 16.45ms**, max 20.89ms.
  Ignis/OpenGL reduced: 5,239 frames, mean 8.21ms, p95 12.90ms,
  **p99 16.68ms**, max 38.01ms.
  Vespera/OpenGL reduced: 5,957 frames, mean 7.23ms, p95 12.66ms,
  **p99 17.24ms**, max 42.93ms. All satisfy the 33.33ms p99 gate;
  isolated maximum-frame spikes are not hidden.
- The remaining two planets also pass exported normal-speed launches:
  Cryo/Vulkan **p99 11.82ms** (7,861 frames), Xylo/Vulkan **12.03ms**
  (7,949), Cryo/OpenGL reduced **16.00ms** (5,607), and Xylo/OpenGL
  reduced **15.98ms** (5,429). Their respective maximum frame times are
  27.98, 23.37, 35.09 and 36.36ms. An additional Ignis/Vulkan repeat passes
  at **p99 11.28ms** over 7,692 frames, maximum 15.10ms.
- The first launch benchmark ended during alignment without a success marker
  or logged engine error. It is retained as an incomplete failed validation,
  not counted as passing. All eight sector/renderer combinations and the
  additional Ignis repeat completed successfully.
- [v0.17.1 installer](../releases/0.17.1/CosmicConflict-0.17.1-Setup.exe):
  **32,783,007 bytes**, executable version **0.17.1.0**, unsigned. SHA-256:
  `BBDF1899974C638983FA9708CADC810BDF2FD26175CC2F4F2D433C3C42761058`.
  Campaign/Hall of Fame schema eleven and v0.17.0 endgame behavior are unchanged.
  Normal saves, preferences, installed game and earlier releases remain intact.
  The separate Cryo/OpenGL dense-field performance issue remains open.

### v0.17.0 campaign completion verified release

- **779 focused assertions** pass across twenty suites, including real hull
  damage/overkill, tour baselines, rank thresholds/caps, exact legacy backups,
  frozen loadouts, separate records, duplicate prevention and recoverable
  record/checkpoint failures.
- Native Vulkan/OpenGL 1920x1080 screens verify the debrief, medal, scrolling
  statistics, rank rules, confirmation, Hall of Fame and resumable title.
- Exported Vulkan, Rook/Twin Pulse, tour one: all four actual planetary loops
  and eight mandatory bosses complete without invincibility, instant kills or
  secondary ordnance. Rating **816 / Commodore Ace Pilot**, 283 enemies,
  269,800 combat score, 2,548/6,549 hit samples, zero hull damage/ejections.
- Exported OpenGL/reduced effects, baseline Rescue Skiff/Twin Pulse, tour five
  at **200% enemy/boss health**: all four loops/eight bosses complete without
  invincibility, upgrades, secondary ammunition or replacements. Rating
  **861 / Admiral Nova-Vanguard**, 225 enemies, 212,000 combat score,
  4,307/7,994 hit samples, zero hull damage/ejections.
  Earlier-tour counters are an explicitly labeled setup fixture; this is a
  real capped-health tour, not a claim of playing twenty complete sorties.
- Both exports verify Retire, exact resumed debrief, separate assisted records,
  idempotent Continue after retirement, lifetime retention, tour reset, disk
  reload and the next departure's scaled enemies. Their accelerated runs are
  functional evidence, not normal-speed performance measurements.
- The installer is unsigned. Previous releases, normal saves/preferences and
  the installed game remain untouched. Cryo/OpenGL dense-field performance
  remains open; the new middle-descent terrain-alignment request is next.

### v0.16.0 Xylo-Mire and computer voice verified release

- **668 focused assertions** pass across nineteen suites.
- Full source Xylo sorties pass for the basic Rook safe route and Rescue
  Skiff hazard route. Real egg-cargo shooting, tractor collection and persistent
  rewards pass without creating asteroid fragments.
- Native Vulkan/OpenGL fleet checks show substantial biological coverage and
  **zero** mother/egg pixels ahead before the pull-up. Radar-static comparisons
  change the actual radar panel, but no critical-warning/health/weapon pixels.
- Native Zira playback produces a real processed bus signal, honors pause and
  volume-off, preempts banter for critical warnings and enforces actual
  four-second silence before an eligible one-in-four route outcome.
- Final exported speech validation loads the packaged catalog/recording and
  measures real processed audio while master output remains muted.
- Complete exported Xylo missions pass with Vulkan/Quad Plasma and
  OpenGL/reduced-effects/Tachyon in the Rescue Skiff on the hazard route.
  Purchases, exact reload, cross-sector departure, ejection and recovery pass;
  handoff differences are zero position and at most 0.0007 rad.
- Complete Ignis, Cryo and Vespera regressions pass. Native opacity/handoff
  checks now cover all four actual destinations in both renderers, with zero
  background leakage and zero canopy changes on globe removal.
- Final normal-speed exports at actual 1920x1080 on Intel Iris Xe, without
  screenshots: hive/Vulkan **15,259 frames**, mean 6.03 ms, p95 10.28 ms,
  **p99 11.35 ms**, max 60.03 ms; swamp/OpenGL reduced-effects **13,042 frames**,
  mean 6.75 ms, p95 11.26 ms, **p99 13.14 ms**, max 39.09 ms.
  Both meet the 33.33 ms p99 gate; isolated longer frames remain possible.
- The older Cryo/OpenGL dense-field performance limitation remains tracked.
  Final campaign ranks/medals/Hall of Fame/tour rules are not claimed complete.
- [v0.16.0 installer](../releases/0.16.0/CosmicConflict-0.16.0-Setup.exe):
  **32,751,169 bytes**, executable version **0.16.0.0**, unsigned. SHA-256:

```text
FCA02C2847D89A9B9DA61DB4E62063428014FFB67B83C95CF3B768369D1EAE2D
```

### v0.15.1 departure/arrival correction

- **614 focused assertions** pass. Docking/outward departure and the pre-warp
  climb remain continuous at 30/45-Hz validation rates.
- Native Vulkan/OpenGL background-color comparisons report **zero leaking
  pixels** through all four generated planet styles at early/full reveal.
  All three playable destination handoffs report **zero changed canopy pixels**
  when the already-occluded globe is removed.
- Exported OpenGL full mission/departure/docking passes with zero measured
  position/orientation handoff difference.
- Final exported normal-speed Cryo launch, Vulkan, actual 1920x1080, no captures:
  7,003 frames, mean 6.15 ms, p95 11.85 ms, **p99 15.87 ms**, max 21.54 ms.
- [v0.15.1 installer](../releases/0.15.1/CosmicConflict-0.15.1-Setup.exe):
  **30,044,844 bytes**, unsigned. SHA-256:

```text
F9812B54EA0C626323E385257C195AA1CEB450383FEBE37106FA2B6CE9C87DEF
```

### v0.15.0 Vespera-9 verified release

- **611 focused assertions** pass across seventeen suites.
- Full source Vespera sorties pass with the basic Rook on the safe route and
  the Rescue Skiff on the hazard route, without invincibility.
- Native Vulkan/OpenGL gate comparisons show fuller active beams than dashed
  warnings and no beam pixels in the central opening. Nyx shimmer remains
  visibly present and changes materially on reveal; native traffic moves.
- Normal-speed source checks at actual 1920x1080, Vulkan/normal effects on
  Intel Iris Xe, without screenshots: city ground p99 **12.89 ms** and Nyx
  combat p99 **7.67 ms**. Both meet the 33.33 ms gate; maxima were 50.62 ms
  and 114.35 ms respectively, so this is not an every-frame guarantee.
- Final exported missions pass with Vulkan/Quad Plasma on the safe route and
  OpenGL/reduced-effects/Tachyon in the Rescue Skiff on the hazard route.
  Both preserve shopping, exact reload, cross-sector departure, ejection and
  recovery. Handoff differences are zero position and at most 0.0007 rad.
- Final basic-weapon Rescue hazard viability and full Ignis/Cryo regressions
  also pass. Existing campaign progress and v0.14.0 release files are preserved.
- Final native Nyx comparisons retain 11,112 visible shimmer pixels on Vulkan
  and 9,717 on OpenGL, with substantial reveal differences in both. Gate active
  pixels exceed dashed warnings (10,644 vs 7,676 Vulkan; 9,602 vs 6,718 OpenGL)
  and the central opening has zero beam pixels.
- Normal-speed final exports, actual 1920x1080 on Intel Iris Xe, without
  screenshot readbacks: city/Vulkan 12,604 frames, mean 6.98 ms, p95 12.04 ms,
  **p99 13.65 ms**, max 32.02 ms; Nyx/OpenGL reduced-effects 7,950 frames, mean
  5.39 ms, p95 8.15 ms, **p99 9.44 ms**, max 75.30 ms. Both meet the p99 gate;
  occasional longer frames remain possible.
- The previously documented Cryo/OpenGL dense-field performance limitation
  remains open; this milestone does not claim to resolve it.
- [v0.15.0 installer](../releases/0.15.0/CosmicConflict-0.15.0-Setup.exe):
  **30,038,734 bytes**, executable version **0.15.0.0**, unsigned. SHA-256:

```text
E187FA3111127AD69C99B6B9386DF4DD5B8B6021194C411EF0DF4820DB04C0E5
```

### 10.0 v0.14.0 Cryo-Vex and finite-field exit

- **573 focused assertions** pass across sixteen suites, including schema-seven
  migration/backup, replay policy, selection cancellation, explicit save-failure
  retry, cross-sector station/sky continuity, frost, drone caps/EMP and optional
  bay/core separation.
- Final exported scene inspection caught giants across the automatic pull-up.
  The user clarified that all outer rocks must pass before climbing. A finite
  field boundary now guarantees that, preserving the original five-second
  coast and continuous twelve-second pull-up. Controller tests check all
  tumbling envelopes; native pixels must show zero outer rocks ahead at climb
  entry. Coverage remains above 99.5% during the main field and tapers at its end.
- Complete source Cryo missions pass with the Rook safe route and Rescue Skiff
  hazard route in both frost modes. Existing Ignis regression suites pass.
- Initial peripheral coverage was only 95.6% at entry. Densification and entrance
  padding raised final main-traversal coverage to **99.77%-100%**, with exact
  scale and real uploaded spin/solid-stroke alignment checks in Vulkan/OpenGL.
  At 59 seconds the finite field naturally opens to approximately 71% coverage;
  at climb entry both renderers measure **zero** outer-rock pixels ahead.
- Initial belt frame times exceeded budget. Rendering now batches visual pose
  uploads once per draw frame and uses a leaner giant mesh while preserving all
  crater features, five-times scale, two forms, dense traversal and varied tumbling.
- Source normal-speed 1920x1080 Vulkan/Iris Xe checks, no screenshot readbacks:
  belt p99 **24.24 ms**, ground **11.01 ms**, Hydra **9.57 ms**. All satisfy
  the 33.33 ms p99 gate. One intermediate belt run contained a 1,174 ms outlier;
  do not claim every frame meets budget.
- Full exported Cryo missions pass with Vulkan/Quad Plasma and
  OpenGL/reduced-effects/Tachyon, including shopping, cross-sector departure,
  reload, ejection and rescue. The complete Ignis regression also passes.
  Camera handoff differences were zero position and at most 0.001 rad.
- Final exported finite-field benchmark, normal speed, actual 1920x1080,
  no captures or GPU instrumentation: **Vulkan**, 10,583 frames, mean 8.70 ms,
  p95 23.79 ms, p99 **29.76 ms**, maximum 96.11 ms. It passes the p99 gate,
  retains the belt through docking and reports zero nominal-route impacts.
- **Known limitation:** the same OpenGL/reduced-effects run completes correctly
  but misses the p99 performance gate: 8,270 frames, mean 11.13 ms, p95 33.27 ms,
  p99 **46.06 ms**, maximum 122.78 ms. Recommend default Vulkan on this hardware;
  compatibility optimization remains open. A heavily stalled instrumented
  Vulkan run is retained as failed evidence, not relabeled a performance pass.
- [v0.14.0 installer](../releases/0.14.0/CosmicConflict-0.14.0-Setup.exe):
  **30,014,538 bytes**, executable version **0.14.0.0**, unsigned. Its explicit
  four-file payload excludes exporter scratch binaries. SHA-256:

```text
70BC7AE37F17415A3A72B74E87E38C0E42B84D6F8979316EE498D9FCD054B80F
```

### 10.1 v0.13.1 volcanic refinement

- **524 focused assertions** pass across fifteen suites. Existing heat/timer
  checks remain intact; new checks cover lava progression, solid cone cover,
  instanced-smoke arrival fading and nominal clearance on transformed courses.
- Native Vulkan/OpenGL stage comparisons show smoke buildup, lava, a rising
  column, a domed ash crown and dissipation. Peak changed ash pixels measured
  22,020 versus 1,363 during buildup on Vulkan, and 20,294 versus 1,014 on OpenGL.
- Exported Vulkan/normal and OpenGL/reduced-effects full missions pass with
  **0 m / 0 rad** handoff discontinuity, including both departures, bosses,
  docking, purchases/reload, ejection and rescue.
- Normal-speed safe-ground benchmark: Intel Iris Xe, Vulkan/normal effects,
  **actual 1920x1080 rendering**, no screenshot readbacks; 19,169 frames,
  mean **4.59 ms**, p95 **8.37 ms**, p99 **10.26 ms**, maximum **26.70 ms**.
  The p99 meets the 33.33 ms minimum-performance budget for this workload.
- A native resize probe confirmed that an 873x490 presentation window still
  renders internally at 1920x1080. Earlier interrupted/resized runs were not
  counted as performance passes.
- [v0.13.1 installer](../releases/0.13.1/CosmicConflict-0.13.1-Setup.exe):
  **29,984,471 bytes**, executable version **0.13.1.0**, unsigned. SHA-256:

```text
7E0140A3CEDB6C611AFCE9187D8006D6029D77D00348EA3B8126490A99D5FD61
```

### 10.2 Previous v0.13.0 baseline

- **515 focused assertions** pass across fifteen suites. New cases cover
  frame-rate-independent cadence/heat, actual bolt impacts, piercing, protected
  targets, partial cover, translated courses, initial overlaps, missile
  interception, bounded accuracy, pause and harmless post-checkpoint effects.
- Complete headless missions pass with each of the three primary tiers,
  including the hazard route with Tachyon, both bosses, docking, equipment
  transfer/purchases, exact reload, re-departure and ejection/recovery.
- Native Vulkan/OpenGL comparisons use actual rendered effects: basic pulse
  bright-core width is two pixels; plasma is four; tachyon is six to eight.
  Core peak luminance is at least twenty percent higher for both upgrades in
  normal and reduced-glow modes. Actual cockpit/pause/market views were inspected.
- Final exported missions pass with Quad Plasma on Vulkan/normal effects and
  Tachyon on OpenGL/reduced effects, including the hazard branch for Tachyon.
  Both complete the full loop, preserve upgrades through purchases/reload,
  launch again, and pass ejection/rescue checks without invincibility.
  Reported handoff differences are **0 m / at most 0.0007 rad**.
- Separate normal-speed ninety-second orbital benchmarks, Intel Iris Xe,
  1920x1080, Vulkan/normal effects, no screenshot readbacks:
  **Plasma:** 16,146 frames, mean 5.45 ms, p95 8.53 ms, p99 10.12 ms,
  maximum 13.46 ms. **Tachyon:** 17,590 frames, mean 5.00 ms, p95 7.83 ms,
  p99 9.25 ms, maximum 14.05 ms. Both meet the 33.33 ms p99 budget;
  these results do not guarantee every scene or machine meets that budget.
- Existing native polygon-color/fade tests pass in both renderers, confirming
  the brighter weapon materials did not change original-color debris.
- [v0.13.0 installer](../releases/0.13.0/CosmicConflict-0.13.0-Setup.exe):
  **29,972,609 bytes**, executable version **0.13.0.0**, unsigned. Existing
  v0.12.0 remains unchanged. SHA-256:

```text
99F7AACF88D797C392143F79E2322BB3ED959FC311F5008244E593BF519DAFE0
```

### 10.3 Previous v0.12.0 baseline

- **470 focused assertions** pass across fourteen suites. New cases cover both
  routes at 30/45 Hz, translated courses, late-hit rejection, actual conduit
  shooting, real collision-volume clearance, capped supplies, missing equipment,
  pause, one-time bonus and checkpoint rollback/commit behavior.
- Complete headless missions pass for the Rook on safe and hazard routes and
  the Rescue Skiff on the safe route, including both bosses, docking, purchases,
  exact save reload, station re-departure and ejection/recovery.
- Native source validation collected all three supplies through real flight,
  reached the boss without invincibility, and preserved the rejoin handoff.
- Final exported missions pass on Vulkan/normal effects with the Rook taking
  the hazard route, and OpenGL/reduced effects with the Rescue Skiff taking the
  safe route. Both report **0 m / 0 rad** phase-handoff discontinuity and verify
  docking, purchases, exact reload, re-departure and ejection/recovery.
- The final exported normal-speed hazard benchmark uses Intel Iris Xe,
  1920x1080, Vulkan/normal effects, with no screenshot readbacks: **11,011 frames**,
  mean **7.99 ms**, p95 **12.92 ms**, p99 **14.49 ms**, maximum **37.23 ms**.
  The p99 meets the 33.33 ms minimum-performance budget; an occasional longer
  frame remains possible. Accelerated full missions are functional evidence.
- [v0.12.0 installer](../releases/0.12.0/CosmicConflict-0.12.0-Setup.exe):
  **29,950,849 bytes**, executable version **0.12.0.0**, unsigned. SHA-256:

```text
2BB5EFE4FD22DE81D5F61FE188BCF3B9B85B25DB0CB7592A5ACCF48320260423
```

### 10.4 Previous v0.11.0 baseline

The following are **existing v0.11.0 results**, rechecked against stored release
evidence during this review, not new gameplay tests run for this documentation:

- Final [build log](../releases/0.11.0/validation/build.log): **432 passing
  assertions** across thirteen focused suites, all completion markers successful.
  The earlier `headless-tests.log` records 427 and is an intermediate result.
- Exported full missions passed with Vulkan/normal effects and OpenGL/reduced
  effects. Both report **0 m / 0 rad** handoff discontinuity and verify launch,
  encounters, purchases, exact reload, market re-departure, weapons, flares,
  ejection and rescue. Do not label the OpenGL run as normal-effects validation.
- Normal-speed uncaptured launch benchmark: Intel Iris Xe, 1920x1080,
  Vulkan/normal effects, 6,020 measured frames; mean **7.81 ms**, p95 **13.14 ms**,
  p99 **16.46 ms**, maximum **31.56 ms**. Required p99 budget: **33.33 ms**.
  This covers departure through the first five ground seconds, not every scene,
  machine or future tour. It is not a guarantee that every frame stays in budget.
- [v0.11.0 installer](../releases/0.11.0/CosmicConflict-0.11.0-Setup.exe):
  **29,937,265 bytes**, executable version **0.11.0.0**, unsigned. Its SHA-256 was
  rechecked during this review:

```text
F3AC43DD0C0A829CCCAF4FA13BA244549405FE954AC705DC6946FD0E5D3795D9
```

For each behavioral increment, add only focused regression tests for changed
behavior, then the required mission/visual/performance checks for its risk.
Keep pause, 30/45-Hz continuity, exact active timers, readable warnings, collision,
unassisted emergency viability, old-save migration and reward integrity covered.
Final distribution still needs a genuinely fresh Windows machine and broader
hardware/campaign/accessibility testing.

Use the [investigation and release history](INVESTIGATION_AND_ROADMAP.md) for
historical decisions, detailed measurements and offline continuation notes.
Use the [player/build guide](FLIGHT_LAB.md) for controls and execution instructions.
Future work should update this outline's status, those directly affected guides
and the release evidence together; do not rewrite historical results as if a
new feature existed in older releases.
