# Cosmic Conflict - Player Guide v1.0.0

Six complete planetary loops are playable: Ignis Prime, Cryo-Vex, Vespera-9,
Xylo-Mire, Thalassa Reach and Kharon Dunes. Completing a tour awards a campaign rank and original medal,
with a local Hall of Fame and repeat tours.
The original 75-second, non-lethal
training range is still available separately.

## Surface hazards

During a ground sortie, a sound and an amber contact mark warn where a local hazard will strike. Steer away or time a barrel roll. Weather can destroy enemies and installations without awarding a kill or credits.

| World | What to watch for |
| --- | --- |
| Ignis Prime | Incandescent bombs arc out of nearby volcanic cones. Molten channels spill downhill and light the rock around them. |
| Cryo-Vex | A shaggy Glacier Mauler steps into the flight lane once per ground sortie, during the first or second hazard. Watch for its raised paws and dodge the slam. Other ruptures heave the ice upward. |
| Vespera-9 | A derailed maglev drops out of the skyline trailing sparks. Its nose hits first, then the carriage skids. A banded planet with dusty rings is visible during the orbital dogfight. |
| Xylo-Mire | A shadow crosses the canopy. Steer clear or roll before the hooked hand closes. If it catches your ship, it lifts you, shakes you, then throws you back into the flight lane for 35 direct hull damage. |
| Thalassa Reach | A branching lightning leader can hit a ship, tower, or offshore platform. Solid structures can intercept the discharge. |
| Kharon Dunes | Watch for meteor trails over the dunes and for the mechanical siege walker planting its feet before a ground strike. |

Selecting a sector locks its lighting for the sortie. Seconds 00–14 of the current
minute give twilight, 15–29 morning, 30–44 daylight, and 45–59 midnight.
Vale and Lark comment on arrival. Astra Market sells a forward headlight for 200
credits. Enable **Target brackets and distances** in settings for range overlays.
Completed sectors carry a checkmark on the current tour’s map.

Fly through the green hoops marked **$** to earn upgrade money. Each hoop pays
once. A 100-credit hoop is common (60%); a 1,000-credit hoop is rare (1%).

Choose **New Operation / Choose Sector** to start a live mission, or **Continue Saved
Operation / Market** to resume a checkpoint. Starting a new operation asks before
replacing an existing save.

For a topic-based, player-only guide, see the
[illustrated Word user manual](Cosmic_Conflict_Player_Manual_v1.0.0.docx).
See “Read the cockpit at a glance” for the countdown and “Choose the safe or
hazard route” for the steering diagram. The original v0.18.0 edition remains
available separately for players on that release.

## Release 1.0

Version 1.0 accepts existing 0.19.4 checkpoints and named games. In flight,
**Resume Flight** and **Save / Load Game** now sit side by side on the pause
screen. Opening saved games keeps the flight soundtrack paused; at Astra the
station music continues. Asteroid artwork now takes less time to generate.

## Flight and cockpit features

- **Cockpit and guns:** the side braces and roof supports now match the front
  canopy pillars, with bolted, worn steel faces and unchanged window openings.
  Quad Plasma adds two six-barrel clusters: hold fire to spin them up and
  release to watch them coast. Tachyon replaces the clusters with forked,
  illuminated emitter rails. Astra Market shows the fitted exterior beside
  the shop. All five hulls carry the Twin Pulse pair and mount the equipped
  upgrade outboard.
- **Named games:** choose **Save / Load Game** while paused or in Astra Market.
  Enter a name and choose **Save As**, or select a saved name to load. A flight
  save restores the phase checkpoint, not mid-flight damage, kills or rewards.
  A market save restores your ship, purchases and credits. Loading replaces the
  automatic checkpoint but leaves the named copy intact. Training allows loading only.
- **Pilot movement:** in Ground Assault, the asteroid field, and both boss fights,
  steer toward either edge of the screen to move up to 60 m from the course center.
  Small mouse movements near center still give fine aim. Vertical travel is unchanged.
- **Ground Assault:** use the canyon walls for cover from incoming missiles,
  but leave clearance for your own hull. On Ignis Prime and Cryo-Vex,
  steering stops at the terrain surface; hitting it still damages the ship.
  At the marked fork, fly left of
  center for the safe path or right of center for the hazard path. You no
  longer need to shoot a switch.
- **Sector skies:** look for the sun's solid amber limb and bright center.
  Kharon Dunes has a tilted dust ring crossing its sun. In Cryo-Vex orbit,
  look for the blue ice ring around the moon. The moon's cratered surface
  blocks the stars even when dimly lit.
- **Ship recognition:** the five player hulls and hostile fleet have new
  silhouettes. Figure 26 in the player manual compares player and enemy
  profiles without relying on cockpit color.
- **Faster travel:** each timed handoff loses five seconds in total, not five
  seconds per animation. Departure to ground now takes 22s; ground boss to
  orbit 7s; orbital intercept 1s; orbital boss to belt 15s; belt to market
  21s (8s if resuming at the docking checkpoint). The top combiner counts down
  to the next playable phase, even across multiple autopilot maneuvers.

- **Thalassa Reach / storm ocean:** animated waves, offshore platform settlements,
  dockside cranes, marine defense pylons and manta interceptors. An amber ring
  marks the next strike. Watch for the branching leader and steer clear or
  barrel roll through the discharge. A direct hit can destroy your ship, a manta
  or a platform. A structure that intercepts the bolt can shelter a ship below it.
  Tempest Walker and Storm Ark are the ground/orbital bosses. The ocean-themed
  orbital escape retains mining, salvage and optional pirates.
- **Kharon Dunes / desert ruins:** undulating dunes, broken arches, engraved
  monoliths and scarab fighters. Loose ruin blocks warn for two seconds before
  falling into side lanes; two baseline hits clear one, or avoid it. Contact
  deals 14 damage once without frost, credits or combo rewards. Sunforge Colossus
  and Obelisk Sovereign guard ground and orbit. Both worlds have the complete
  ground/boss/orbit/boss/escape/docking loop and individual world themes.
- **Two PLAYER battleships in Astra Market:** Aegis Titan costs 2,400 CR and has
  240 hull, 160 shields, 12 ordnance and 70% steering response. Nova Bastion costs
  3,600 CR and has 200 hull, 220 shields, 16 ordnance and 80% response. Both have
  larger hitboxes, distinct supplied heavy cockpits and battleship silhouettes.
  They are actual purchasable player hulls, not hostile ships or scenery unlocks.
  Existing upgrades transfer on purchase; ejection loses the hull/equipment.
- Each boss carries two rotating scanners. Six baseline hits destroy one and earn
  30 CR. Every lost scanner reduces the launchers' ability to lead the ship and
  increases firing intervals by 25%. On Vespera, the scanners also power reactor
  shielding. Recover both scanners intact elsewhere for a 75 CR intelligence bounty.
- **Closer boss view:** stable pursuit is 25% closer (82.5m ground, 112.5m orbit),
  with gentle 24-second left/right hull drift. Mouse aiming remains active;
  no forced oscillating camera is added.
- **Earlier v0.19.0 timing:** each automatic segment that previously lasted
  more than four seconds loses two seconds. Undock 8->6, alignment 6->4, descent
  16->14, ascent 10->8, boss turn 8->6, belt transfer 18->16, coast 5->3,
  belt climb 12->10, station approach 9->7 and docking 8->6 seconds.
  Hyperspace remains 3 seconds and both wreck-clearance segments remain 4.
  Ground/orbit/field combat clocks remain 90/90/60 seconds; bosses stay untimed.
- **Save preservation:** schema twelve keeps exact pre-upgrade backups. Unfinished
  tours retain checkpoint, credits, equipment, clears and earned replay access
  but gain the two new worlds. Completed four-world debriefs and Hall of Fame
  records retain their original scope, statistics, rank and loadout unchanged.
  Continuing a completed old tour begins six worlds. New records show six worlds;
  old records remain four-world records, with no fabricated completion.
- **Optional desktop shortcut:** on the installer's Additional Tasks page, select
  **Create a desktop shortcut** to add a Cosmic Conflict icon to your desktop.
  It is unchecked for a fresh installation; Start menu shortcuts are always
  installed. Uninstall removes the shortcut but preserves your saves and records.

## Historical changes from earlier releases

The sections through the controls reference below describe what each earlier
release introduced. Their old world counts, save schemas and timings are
historical; the current rules above and reference sections take precedence.

## Smooth Boss Arrival & Shorter Hyperspace from v0.18.1

- **Orbital boss arrival:** after the ninety-second dogfight, the flight computer
  makes an eight-second moving quarter-turn onto the capital ship's intercept
  course. The boss is already present outside the initial forward view and
  moves into the canopy during the turn, rather than appearing directly ahead
  when the next phase starts. The same boss, weak points and appearance remain
  in place when normal untimed pursuit begins.
- **Safe automatic approach:** the prepared boss can animate its radar/cloak,
  but cannot attack or launch drones during the turn. Pause freezes everything.
  Incoming-phase combat time, health scaling, shield/core rules and rewards are
  unchanged. Resuming an orbital-boss checkpoint still starts its normal pursuit.
- **Hyperspace is 75% shorter:** the actual jump is now **3 seconds instead of
  12**, including the streak envelope and sky transition. The eight-second
  undock, six-second clearance climb and sixteen-second planetary descent are
  unchanged: the complete departure is approximately 33 seconds instead of 42.
  The destination remains hidden until after hyperspace, then reveals normally.
- Existing campaign and Hall of Fame saves remain on schema eleven. The v0.18.0
  Word manual remains a preserved guide to the unchanged core systems; this
  release adds the transition changes above.

## Private Release Polish from v0.18.0

- **Gentler survival:** ordinary enemy missiles now deal 14 damage instead of
  18, shields first. Shields begin recovering after 1.5 quiet seconds instead
  of two. Special hazards retain their documented damage, and flight speed,
  enemy patterns, weapon heat, rewards and the 200% repeat-tour health cap are
  unchanged. Training retains its nonlethal damage rules.
- **Cryo falling ice:** eight loose chunks hang from side-lane ice overhangs.
  Amber markers and a target label warn for two seconds before a chunk falls.
  Two baseline laser hits shatter one; avoiding it is equally valid. A contact
  kicks your ship off course and deals 14 hull damage through shields. The automatic
  centerline stays clear. Clearing ice awards no credits, enemy kill or streak.
  Pause freezes the warning and fall.
- Kevin MacLeod’s “Fanfare for Space” accompanies the opening. “Look Busy”
  plays in Astra Market. Each world loops its own recording through ground
  combat, orbital flight and both bosses. Docking crossfades to the market
  score. Pause holds playback and computer speech lowers the music.
- **Music controls:** the title/pause menu has a separate music slider, default
  60%; zero stops music. Master mute silences everything. Voice volume is
  independent. Recordings ship inside the game and work offline.
- **Backdrop efficiency:** conservative, precomputed bounds cover each complete
  rotating asteroid envelope. Batches wholly behind the camera no longer upload
  invisible animation poses. Giant scale, shapes, crater detail, density, spin
  rates and the clear-before-pull-up exit remain unchanged.
- **Private release readiness:** installer validation uses a separate application
  identity, folder and shortcuts; it must not replace your normal installed game.
  A versioned source archive includes source, recordings, documentation, build
  scripts and file checksums. This remains an unsigned private/testing release,
  not a commercially cleared or clean-machine-certified product.
- Your existing campaign and Hall of Fame remain compatible with schema eleven.
  Reflective-crystal effects, radar supply caches, extra branches and heavy ships
  were not selected for this polish pass and remain future work.

## Curved Planetary Arrival from v0.17.1

- **Curved arrival landscape:** the foundation, terrain, buildings, trees and
  other prepared scenery follow the destination globe's arc during approach.
  The large foundation is temporarily subdivided so it can bend smoothly rather
  than appear as a flat sheet outside the planet.
- **Closer terrain reveal:** the landscape stays hidden until the ship is below
  280 metres above its landing reference and becomes opaque by 60 metres.
  Detail outlines appear after the solid forms, reducing the early wireframe look.
- **Seamless ground entry:** curvature smoothly levels into the existing gameplay
  terrain below 95 metres and reaches zero by 20 metres. The original materials,
  meshes, culling bounds, target positions and collision layout are restored
  before combat. All ninety ground-attack seconds remain available.
- Destination planets still remain hidden until after hyperspace and retain
  their opaque, detailed surfaces. Campaign saves and Hall of Fame records keep
  schema eleven; no extra migration is needed for this visual correction.

## Campaign Honors from v0.17.0

- **Campaign debrief:** after the fourth planet's actual docking, see tour and
  lifetime statistics, including actual hull damage, accuracy, earnings/spending,
  enemies, bosses, objectives, salvage and ship losses/ejections.
- **Ranks and medals:** eight humorous ranks, each with an original vector medal.
  The 0-1000 performance rating uses this tour, not your unspent wallet.
- **Retire:** record the finished tour and return to the title. Your completed
  campaign remains resumable with the same equipment, credits and final result.
- **Continue:** record the result and begin another four-planet tour. Keep ship,
  upgrades, credits, remaining ordnance/flares, lifetime totals and replay access.
  Planet clears, tour statistics and the sortie debrief reset. No free ammunition
  or second payout is granted.
- **Bounded difficulty:** enemy and boss health is 100%, 125%, 150%, 175%, then
  200% from tour five onward, rounded up to whole hit points. This includes
  fighters, gunships, turrets, boss sections, carrier drones and optional pirates/
  guardians. Rocks, egg ships, infrastructure, hazards, enemy damage, speeds,
  firing cadence, waves, timers, prices and rewards are unchanged.
- **Hall of Fame:** available from the title and final debrief. View medals,
  statistics and final loadouts; assisted and unassisted results have separate
  rankings. Retiring repeatedly or continuing after retirement never duplicates
  a tour record. Records survive starting a new operation.
- **Save compatibility:** schema eleven preserves earlier saves and exact
  source-version backups. Old saves did not track cumulative hull damage: their
  debrief explicitly says "since upgrade only" and does not award unearned
  survival points. The next tour has complete damage tracking.

### Campaign rating

- Accuracy: floor of hit ratio times 300, requiring at least 20 shot samples.
- Combat: up to 300 points, reaching the cap at 100,000 combat score.
- Survival: 250 minus 75 per ejection and one per four hull damage, minimum zero.
  Untracked legacy damage makes this component unavailable for that tour.
- Streak: six points per best consecutive kill, capped at 150 for 25 kills.

Rank thresholds: **0** First Lieutenant Loser; **200** Ensign Space Cadet;
**350** Flight Officer Rookie; **500** Captain Star-Strider;
**625** Commander Void-Hunter; **750** Commodore Ace Pilot;
**850** Admiral Nova-Vanguard; **950** General Grandmaster.
The final result freezes at completion; spending credits never lowers a rank.
Developer assistance remains marked for the entire operation, including later tours.

## Xylo-Mire and Computer Voice from v0.16.0

- **Xylo-Mire:** fly through a dark green alien wetland with twisted trees,
  exposed roots, hanging vines, water channels and insectoid enemies. Survey
  rovers are decorative, non-hostile vehicles outside the combat corridor.
- **Corrosive geysers:** visible warning rings precede acid spray. A contact can
  deal 18 damage once per eruption, shields first, with no lingering corrosion.
- **Spore clouds:** exposure adds two seconds of non-stacking radar static.
  Aiming, steering, Shift, weapons, health displays and critical warnings remain usable.
- **Biological bosses:** Bio-Titan Goliath has articulated legs, long claws and
  organic weak points. Hive Mother Leviathan has a segmented arched body,
  mandibles and biological spitter batteries. Both still require the amber
  organs before their cyan core becomes vulnerable.
- **A living fleet, not an asteroid belt:** the final 60-second Xylo stage has
  large background Hive Mothers, egg-like craft and 232 physical egg ships.
  The center course remains clear, while steering off-center can collide with eggs.
  Every outer body clears before the docking pull-up; nothing is hidden or
  relocated to fake the transition.
- **Optional guardians and cargo:** guardians leave peacefully unless attacked;
  shooting or EMP-stunning one provokes retaliation. Gold egg cargo releases a
  biological salvage pod that the tractor can collect. Shell polygons replace stone fragments.
- **Lark's voice:** Locally rendered Chatterbox-Turbo recordings cover combat
  calls, boss recon and route quips, with light radio processing.
  Urgent warnings can interrupt banter; ordinary
  comments never overlap or queue into stale situations.
- **Intermittent route comments:** six lines per route, with a 25% chance only
  after four seconds of silence since the preceding utterance finished.
  They trigger once on a successful hard-route selection or safe-route commitment.
- **Voice controls:** the briefing/pause voice-volume slider is separate from
  effects; zero turns speech off. Master mute also mutes speech. Pause holds
  the recording, and effects gently duck while the computer speaks.
  Gameplay and automated validation do not require online speech services.
- **Editable dialogue:** the separate [voice catalog](../current_dev/assets/voice/lines.json)
  remains editable. Text and per-saying frequency can now be changed without
  rebuilding; see "Editing computer-voice quips" below.
- **Compatible saves:** schema ten preserves active checkpoints, equipment and
  earned replay access, with an exact schema-nine backup. New campaigns unlock
  replays after all four sectors; previously earned replay access stays unlocked.

## Departure and Planet Arrival from v0.15.1

- **Exit-facing departure:** the ship starts aligned with Astra's exit.
  Autodocking now turns smoothly into an outward-facing berth, so later
  departures do not need an opening turn or camera snap.
- **Pull-up before hyperspace:** first clear the hangar and outer ring, then
  climb smoothly while the hyperdrive charges.
- **Destination reveal:** no destination globe or sky planet is visible before
  or during hyperspace. The detailed globe brightens into view after emergence.
- **Opaque planets:** the reveal changes surface brightness, not transparency.
  Stars cannot show through the planet. Prepared terrain already covers the
  globe before the ground handoff removes it.
- **Richer planetary surfaces:** finer relief, layered terrain/cloud patterns,
  volcanic fissures, ice/coast detail and city networks distinguish destinations.
- Xylo-Mire and computer speech were added subsequently in v0.16.0.

## Vespera-9 from v0.15.0

- **Vespera-9:** fly through an original magenta/cyan city with detailed tower
  facades, broad streets, overhead bridges and elevated traffic lanes.
- **Decorative traffic:** moving civilian-style pods remain above and beside
  the flight corridor, clear of building faces and bridges. They are scenery,
  not enemies, collision hazards or sources of credits.
- **Side laser gates:** amber dashed warnings precede moving magenta/cyan beams.
  The central eleven-meter opening always stays clear. Each side uses an
  eight-second cycle with a two-second warning and three active seconds.
  A side-beam crossing can deal 18 damage once per gate.
- **Gate counterplay:** shoot a four-hit emitter to disable its side permanently,
  or use EMP for a temporary shutdown. Disabling infrastructure is not an enemy
  kill and awards no credits or combat multiplier.
- **Overlord Defense Core:** a mobile, layered ground fortress with three
  independently rotating machinery rings and visible missile batteries.
  Destroy both shield radars before attacking its core.
- **Stealth Dreadnought Nyx:** an original swept-wing capital ship with a
  scanning shimmer cloak. Destroying both tracking radars permanently breaks the
  cloak and exposes the core.
- **Readable stealth:** Vespera's light fighters and Nyx remain visible and
  damageable by manually aimed weapons while cloaked. Swarm cannot acquire them;
  existing guided rockets fly straight until they can reacquire a revealed target.
  EMP reveals a cloak for three seconds while applying its normal two-second
  system stun. Light fighters also reveal briefly when firing.
- **Original-color destruction:** cloaked ships restore their original hull
  materials before breakup; fragments do not inherit the cloak's transparency.
- **Replay access preserved:** schema nine keeps replays permanently unlocked
  for existing saves that cleared Ignis and Cryo. New operations unlock replays
  after clearing all three available sectors. Saves, equipment and active
  checkpoints migrate without relocating the pilot; the exact older file is backed up.
- Vespera uses the same seamless launch, ascent, belt approach and docking
  structure. Xylo-Mire subsequently joins these routes in v0.16.0.

## Cryo-Vex and the finite outer-field exit from v0.14.0

- **Cryo-Vex:** fly a glacial canyon with a frozen winding river, faceted cliffs,
  large crystal spires, tracked gun vehicles, ice defense pylons and cold fighters.
- **Two new bosses:** the Glacier Bore-Mech has a rotating drill and missile
  batteries. The Cryo-Carrier Hydra launches drones from a destroyable bay.
  On the Bore-Mech, rupture either coolant pod and attack the core during its
  four-second vent openings. On Hydra, destroy both generators or destroy the
  drone bay and one generator, then attack the core. Losing the bay ends
  reinforcements. EMP temporarily disables deployment.
- **Frost hazards:** blue fissures warn for 1.5 seconds, erupt for two seconds
  and repeat every seven seconds. An eruption can deal 12 damage once.
  Successful frost hits, including frost-tagged missiles, reduce steering
  response to 65% for two seconds. Hits do not stack or extend an active effect.
  Aiming, weapons and the full Shift maneuver remain available.
- **Giant asteroid surroundings:** Cryo has roughly 2,000 peripheral rocks at five times
  normal linear scale, using two distinct irregular oblong forms with different
  tumble axes and speeds. They fill the surrounding starfield while leaving
  the reachable corridor clear. These giant background rocks are scenery;
  ordinary foreground rocks still collide, split and support mining.
  The outer field has a real end. It opens naturally in the final seconds, and
  the ship coasts past every outer rock before beginning its pull-up. Even the
  complete tumbling envelopes are at least 24 meters behind the route position.
  Entry clearance is also reserved; no rock is hidden or relocated mid-flight.
- **Sector navigation:** choose Ignis or Cryo for a new operation and select the
  next unfinished sector at Astra Market. That release unlocked replays after
  both sectors were cleared; v0.15.0 preserves that entitlement while adding
  Vespera. This is not yet a completed four-planet campaign.
- **Continuous travel:** departure retains the current station and camera,
  blends toward the chosen planet during hyperspace and descends into its
  prepared terrain. Ground, orbit, belt and docking keep their seamless handoffs.
- **Save compatibility:** schema eight preserves old checkpoints and equipment,
  associates earlier saves with Ignis, and infers an earlier Ignis clear from
  completed-sortie history. Exact original-format backups remain automatic.
- **Developer sector tests:** the backtick panel can start an assisted test
  launch to an available sector, preserving credits and loadout.
- Crystal spires are scenery or ordinary destructible pylons in this version;
  reflective walls and falling environmental ice pillars remain future work.

## Roadside volcanic eruptions from v0.13.1

- **Staged volcanic eruptions:** cratered basalt cones replace the flat vent
  markers. Light smoke builds into a rising column and a broad rolling ash
  crown; glowing lava runs down the slopes and small cinders arc from the crater.
  The hot jet stops, then ash and lava subside before the next cycle.
- **Beside the valley:** the cones sit on the valley shoulders, with bases
  blended into the terrain. The central nominal flight lane remains clear.
- **Solid cones:** as requested, the rock cones are physical obstacles and
  solid cover. Steer clear if flying low near the valley edges. Gray ash and
  decorative cinders add no new collision or damage behavior.
- **Existing heat rules retained:** the same 1.5-second warning, two-second
  eruption, six-second cycle, five-meter heat radius and nineteen-meter heat
  height apply. Orange rings and the cockpit caution identify the heat hazard.
- **Seamless arrival preserved:** instanced ash and the custom lava materials
  fade with the prepared ground during descent. Pause freezes the entire
  eruption animation along with the existing thermal mechanics.

## Advanced primaries and brighter beams from v0.13.0

- **Quad Plasma Repeaters:** the first 250-credit primary upgrade now fires
  four real, converging plasma bolts per volley, each dealing one damage.
  Balanced power fires four volleys per second; Weapons power fires five.
  Lead fast-moving targets: these are travelling bolts, not homing missiles.
- **Tachyon Beam Cannon:** the second 500-credit upgrade produces a continuous
  beam while LMB is held. It deals three damage per tick at eight ticks per
  second, or ten with Weapons power. The wider, 0.9-meter sampled aiming
  footprint is more forgiving than the original precise pulse ray.
- **Piercing with protection intact:** tachyon fire passes through light
  fighters and pirates, but stops at solid cover, heavy gunships, towers, rocks
  and boss sections. Closed shields, locked cores, tower armor and iron-core
  rocks keep their normal protection. A clear edge cannot shoot around cover
  blocking another part of the beam.
- **Wider, brighter graphics:** plasma strokes have twice the measured bright-core
  width of the basic pulse; tachyon strokes have three to four times its width.
  Both have brighter cores, including OpenGL and reduced-glow mode.
  The existing supplied gun artwork is retained.
- **Heat, not ammunition:** plasma volleys generate 14 base heat; tachyon ticks
  generate nine. Cooling upgrades and reactor routing still apply. Overheating
  locks fire for exactly two seconds; releasing LMB extinguishes the beam.
  Neither weapon consumes secondary ordnance or flare charges.
- **Accurate accounting:** each plasma bolt is a shot; each beam damage tick is
  a shot with at most one hit, even when it damages several ships. Pierced
  targets still grant their normal kills/rewards. Pause freezes effects.
  Checkpoint transitions extinguish the beam and disarm travelling bolts.
- **Existing upgrades become the new weapons:** prices, hull-transfer/loss rules
  and saved primary levels are unchanged. Existing schema-seven saves need no
  migration or replacement. The cockpit, pause inventory and market name each
  family and explain its damage units.

## Branching ground routes and supplies from v0.12.0

- **Choose your ground route:** at the marked fork, stay left for the safe
  canyon or fly right before the choice locks to take the hazard trench.
  The flight computer follows your choice; mouse steering remains active.
- **No jump at either end:** both canyons are already present. The ship curves
  into the selected route and smoothly rejoins the main canyon before the boss.
  Ground combat still lasts exactly 90 active seconds; training is unchanged.
- **Harder trench:** eight close-set towers and four armored, faster-firing
  missile turrets guard the alternate lane. The nominal centerline is clear,
  but manual steering can collide with towers and incoming fire remains dangerous.
  Untaken-route batteries do not fire across the canyon.
- **Three separate fly-through supplies:** cyan restores up to 25 shields,
  amber adds up to two shared secondary units, and pink adds one dedicated flare.
  Each is collectible once and capped by capacity. Ordnance requires an owned
  launcher; flare supply requires a pod. Full or missing equipment is reported,
  not converted into free upgrades or credits.
- **Hazard completion:** reach the rejoin alive with the supplies you collected.
- **Checkpoint integrity:** route choice and uncheckpointed supplies/rewards
  roll back together when restarting ground. The normal boss checkpoint saves
  the resulting wallet and both ammunition inventories. Existing schema-seven
  saves need no migration or replacement.

## Station departure and countermeasures from v0.11.0

- **Seamless sortie departure:** a new mission begins inside Astra's hangar.
  The flight computer turns toward the exit, undocks, aligns for hyperspace,
  travels toward Ignis and descends into the prepared canyon. There is no
  teleport or scene replacement at ground entry. Market departures reuse the
  station you are already in. The full 90-second assault starts after arrival.
- **Chaff/flare pod:** buy it for 240 credits, including three dedicated charges.
  Press **C** during active flight to divert up to four incoming missiles within
  110 meters. Recharge takes eight seconds. No nearby lock means no charge spent.
  Diverted missiles stop homing, veer away and expire; other missiles, beams,
  tripwires, towers and rocks remain dangerous.
- **Separate flare inventory:** the 60-credit flare reload fills the pod to
  three charges. It never uses or refills secondary ordnance. Hull changes
  transfer the pod/charges; ejection loses them. Charges and cooldown appear
  on the left MFD and in the paused inventory.
- **More developer controls:** reset wallet, infinite secondary ordnance,
  one-hit exposed targets, and explicit current-boss defeat. One-hit mode
  still respects ordinary shield/base/iron-core rules. Explicit boss defeat
  starts the destruction sequence without fake shots or combat rewards.
  All changes are marked assisted. Returning to briefing, starting a fresh
  operation or continuing a saved run clears the new toggles.
- Schema-seven saves add the launch checkpoint and dedicated flare inventory.
  Old saves retain their existing progress and loadout without free flare gear.

## Continuous belt entry and tactical weapons from v0.10.0

- **Continuous orbital pull-up:** after defeating the orbital boss, the ship
  clears its wreckage and climbs smoothly toward an asteroid field that is
  already in the world. The same rocks remain when manual flight resumes:
  no scene replacement, position jump, or tumbling reset. The full 60-second
  asteroid stage starts after the approach, not during it.
- **Swarm Rockets:** a 500-credit station fires three homing rockets, each
  dealing 3 damage, at up to three visible, unobstructed hostile targets.
  One salvo costs **2 shared ordnance units**. No valid lock means no launch
  and no ammo spent.
- **EMP Nova:** a 650-credit station costs **3 ordnance units** per activation.
  It clears visible enemy missiles within 220 meters, drops gunship shields,
  and disables hostile weapon systems for two seconds. It also cancels a
  capital ship's active thermal sweep. Solid cover blocks it; it does not
  destroy shield generators, award kills, or bypass the boss's core lock.
- **Tactical weapon switching:** choose an owned station from the dropdown
  while paused or docked. Space fires the selected station. Concussion remains
  an 8-damage manually aimed missile costing **1 ordnance unit**.
- All stations use the original shared bay capacity (Rook 6, Hawk 8, Skiff 3).
  Buying a station includes up to three shared units; reloads add up to six.
  Stations/selection transfer with hull swaps and are lost on ejection.
- Schema-six saves preserve old concussion ownership, ammunition and progress,
  with an original-format backup. Paused switching is checkpointed at the
  next phase boundary; market switching is saved immediately.

## Astra exterior from v0.9.1

- Astra's outer ring is now 256 meters across, over twice its previous diameter.
  Its segmented structure includes armored modules, service panels, illuminated
  slots, connectors, and inner/outer rim lighting.
- Six radar domes contain rotating scanners, four marine-style towers carry
  eight independently rotating scanner bars, and eight defensive turrets
  swivel/elevate their gun heads. This is friendly station equipment, not
  additional enemies. It animates during approach and in the market without
  changing the safe docking reference frame.

## Radar, rock, hangar and branding refinements from v0.9.0

- The game is now **Cosmic Conflict**. Existing saves/preferences and the
  installer upgrade identity are retained.
- Exploding objects release substantially more of their original polygons.
  Faces retain their original hull and trim colors, drift and tumble at full
  size, then fade smoothly in both solid fill and glowing edges.
  Asteroids retain their separate rocky breakup and
  interactive smaller rocks.
- Ground radar dishes now rotate continuously through 360 degrees. Both bosses
  also carry two rotating radar dishes.
- **Interactive asteroid fragments:** destroying a full-size rock releases
  three smaller, drifting/tumbling rocks. They can be shot or collide with the
  pilot. They last ten seconds and do not split again or award additional
  credits/minerals. At most 48 are active; an explicit notice accompanies
  dispersal of the oldest at the limit. Rocky chips replace ship-panel debris.
- **Larger Astra hangar:** a 96-meter-wide, 40-meter-high interior with raised
  service bays, landing gear, guide lights, and eight parked craft in four
  distinct designs. Parked ships remain clear of the automatic docking lane.

## Ignis thermal hazards from v0.8.0

- **Ignis heat vents:** eight volcanic vents line the ground route. Orange
  ground rings warn for 1.5 seconds before a two-second eruption; the cycle
  repeats every six seconds. Flying into a plume adds weapon heat according
  to exposure time. Fly around it or above its 19-meter plume to stay cool.
  The nominal center route remains clear; training has no thermal hazards.
- **Solar Flare Cruiser thermal sweeps:** its separate projector charges for
  1.6 seconds with a dashed fan warning, then sweeps a beam for three seconds.
  Dodge up/down or destroy the marked projector to stop the beam and future
  sweeps. A hit deals 26 damage plus 30 weapon heat once per sweep. Shift does
  not deflect this continuous beam.
- External heat uses the same two-second overheat lock as primary fire.
  It cannot keep resetting an already-active vent cycle. Pause freezes warning,
  eruption, and sweep timers. Destroying the projector exposes the cruiser's reactor.

## Encounter objectives from v0.7.0

- **Web-layer drones:** distinct orbital drones deploy laser tripwires across
  the flight path. A dashed amber beam warns for 1.2 seconds before turning red.
  Fly above/below it or shoot either endpoint twice with the basic primary.
  Disarming the web clears the lane. An active crossing deals
  22 damage; this stationary hazard is not deflected by Shift. Webs expire
  after seven seconds, and at most three can exist at once.
- **Radar-dish objectives:** destroying a green-marked canyon dish jams
  surviving turrets up to 700 meters downstream
  for 12 active seconds. A recovered turret warns again before firing.
  Radars and web nodes do not advance or multiply the combat streak.
- **Optional pirate bounties:** three small skirmishers appear during the belt,
  following its clear lane with banking/weaving motion. Ignore them and they
  leave peacefully. Hitting one draws missile fire. Destroying it adds combat
  score. It escapes after 14 seconds. A HUD label identifies it.
- **Hull plating:** two market tiers, +25 maximum hull each, costing 240 then
  360 credits. Transfers with voluntary hull changes; lost on ejection.
- **Sortie debrief:** docking records your shots, hits, and sector clear.
- Schema-five saves retain earlier progress and back up the original format.
  For an old in-progress save, new accuracy tracking starts at the upgrade
  checkpoint because earlier sortie boundaries were not recorded.

## Boss and docking refinements from v0.6.2

- **Uninterrupted belt departure:** the final rocks stay in the scene as you
  pass them. The ship pulls up above the belt, levels toward Astra Station, and
  automatically docks. The station is already present during the climb; the
  field is not replaced by a separate station scene.
- **Visible boss missile batteries:** the ground boss has four tracking turrets,
  and the orbital boss has six. Their launch ports face the pilot and warning
  lights precede missiles. Destroy a turret to remove it and stop its fire.
- **Removable boss sections:** destroying an amber generator now blows away its
  entire engine nacelle, with a larger fragment burst and cascading explosion.
  Destroyed sections stay gone. Damaged sockets continue venting smoke or ichor.
- The boss health bar tracks progress along the available victory routes.
  The computer's briefing identifies the systems. Optional brackets mark the hitboxes.

## Peripheral-field refinements from v0.6.1

- **Fuller peripheral field:** 1,620 additional cratered rocks fill the sides
  and upper/lower canopy rather than simply adding to the center of the view.
  The backdrop now has 2,133 instanced rocks; the 232 physical mining/collision
  rocks and their safe nominal flight path are unchanged.
- **Varied tumbling:** individual asteroids have different axes, directions,
  and rotation speeds. Nearby rocks range from about 3 to 37 degrees per second,
  while distant rocks tumble more slowly. Crater lines rotate with their solid
  surfaces; pause freezes both, and tumbling continues during belt exit.
- **Detail-first graphics target:** 1080p at 30-45 FPS, with 30 FPS as the minimum
  and about 45 preferred. Richer geometry and field density take priority over
  reaching 60 FPS. This is a quality target, not a new frame-rate cap.

## Asteroid mining from v0.6.0

- **Denser asteroid field:** 232 physical rocks and 513 distant instanced rocks,
  with rounded, elongated, and lumpy silhouettes inspired by the supplied
  drawings. Recessed craters, rims, and branching fractures rotate with each
  nearby rock. The winding nominal flight path remains safe; manual steering
  can still collide with close-pass obstacles.
- **Mineral collection:** gold rocks release a cyan core. Fly through it to add
  it to your salvage tally. Cores disperse after 12 active seconds.
- **Tractor upgrade:** buy it for 400 credits at Astra Market. It automatically
  attracts unobstructed cores within 32 meters, with a visible tether. No extra
  key is needed. Solid rocks block attraction.
- **Volatile chains:** violet rocks warn before detonating after 0.65 seconds.
  They can shatter nearby rocks and ignite another volatile core. Stay outside
  the 18-meter pilot danger radius: a close blast can deal 28 damage. Rust-orange
  iron cores survive these blasts and all weapons.
- Tractor ownership, collected minerals, mineral earnings, and chain statistics
  are checkpointed. Existing saves migrate without losing progress, preserving
  a backup before the first upgraded write.

## Tactical systems from v0.5.0

- **Shift evasive maneuver:** cross toward the opposite side of the corridor in
  0.65 seconds, with the requested gentle camera bank instead of a full spin.
  Incoming missiles are deflected during that window. Recharge takes six active
  seconds from activation. Towers and asteroids can still collide with you.
- **Combat streaks:** earn double combat score from your fifth consecutive kill and
  4x from your tenth. Only hull damage breaks the in-flight streak; shield-only
  hits and pauses do not. Streaks carry between combat phases and reset on docking,
  ejection, or a new sortie.
- **Combat score:** the market shows your score and best streak.
- **Directional gunship shields:** heavy orbital gunships protect their front.
  Attack from the side/rear, fire during their banking opening, or use a
  concussion missile to disable the shield and stun them for two seconds.
  No purchased weapon is required to defeat them.
- Older saves retain equipment, credits, and mission progress. New score/streak
  fields start at zero; a backup preserves the previous save format.

## Pilot systems from v0.4.0

- Live-mission primary weapons build heat. At 100%, firing locks for exactly two
  seconds while the weapon vents. Releasing the trigger cools quickly; controlled
  bursts produce more sustained fire than repeatedly overheating.
- Reactor routing: **1 Weapons**, **2 Shields**, **3 Engines**, **0 Balanced**.
  Weapons increases primary fire rate and reduces heat gain; Shields boosts
  regeneration between hits; Engines increases dodge response.
- Two purchasable cooling-vent tiers, reducing base heat per volley by 18% each.
  They transfer during hull changes and are lost with the ship on ejection.
- The right five-slot cockpit gauges now show weapon heat. Missile count stays
  on the right MFD, together with the selected reactor mode and vent countdown.
- Old campaign saves migrate to balanced routing with no cooling upgrades.
  The original version-one checkpoint is preserved as a timestamped backup
  before the first upgraded write.
- The developer panel now includes a Zero Heat toggle. Training retains its
  original unlimited firing, without thermal penalties.

## Continuous-flight improvements from v0.3.0

- Continuous first-person flight between combat stages: no sector-clear modal
  or camera reset. After a ground-boss kill, autopilot brakes and watches the
  four-second breakup from the cockpit before climbing into orbit. The orbital
  battle leads into the asteroid belt, and the station approach ends inside the
  hangar before Astra Market opens.
- Detailed moving bosses with engine banks, cooling rings, trusses, weapons,
  bridge windows, armor panels, and hangar structures. They flee ahead of the
  pilot and gradually enter engagement range while the ship keeps moving.
- Staged capital-ship destruction: cascading fireballs, an expanding shockwave,
  and larger spinning hull fragments.
- The entire tower silhouette accepts shots. A foundation breach topples the
  structure. A shaft hit breaks the upper body free, and a crown hit tears off
  the head. Tight shot groups cut through faster. Towers also intercept hostile missiles.
- Close dogfight encounters from different bearings, including behind the pilot.
  The flight computer smoothly acquires the next live fighter; red triangles
  appear on the center Flight Vector display, with a gold ring around its target.
- New compact engine-scout, swept-wing fighter, delta-wing fighter, and armored
  escort-gunship models inspired by the supplied references.
- Larger, closer asteroid passes. The flight computer follows a winding safe
  corridor; manual mouse offset can still steer into danger. Rust-orange
  iron-core asteroids cannot be destroyed.

## Features retained

- Ships shed fragments on hits and break into drifting, tumbling hull panels
  when destroyed. The original training damage balance is unchanged.
- A full Ignis loop: 90-second ground assault, Vulcan Siege Runner boss, 90-second
  orbital battle, Solar Flare Cruiser boss, and 60-second asteroid escape.
- Boss fights are untimed and beatable with the starting primary weapon. Follow the
  sector-specific briefing. For example, the Tempest Walker sinks when both
  ballast pods rupture, and the Obelisk Sovereign can suffer a magazine chain
  reaction if all six launchers are destroyed.
- Astra Market provides ships, primary/shield upgrades, a concussion launcher,
  ammunition, live prices/benefits, and a one-planet completion result.
- Campaign hull damage is lethal. Ejection returns the pilot to market.
- Atomic checkpoint saves, resumable campaigns, and a developer testing panel.
- User-supplied RGBA cockpit artwork, with the 3D world behind it and live
  instruments perspective-mapped onto all six supplied display areas.
- Each of the five flyable hulls has its own canopy, paint and view over the
  bow. The port sill carries the hull name. From the Rescue Skiff’s offset
  seat you can see the recovery pod to starboard. Buying or resuming a hull
  restores its cockpit and equipped guns together.
- Quad Plasma and Tachyon Beam reuse the supplied plasma-shroud and outboard
  autocannon artwork. The guns sit behind the canopy/consoles, preserving the
  MFD screens; artwork is composited once per hull/tier rather than every frame.
  The additional gun designs and animated Vulcan frames remain available for
  later weapon expansion.

## Controls

- Move the mouse to aim and steer. In orbital dogfights, moving the pointer well off center turns the ship onto a new heading. Center it to resume automatic pursuit.
- Use **WASD** to move the ship independently of the reticle. Hold **F** to hold your line and traverse the guns. The thrusters still work while F is held.
- Press **B** for a barrel roll toward the pointer. The roll evades incoming fire for 0.92 seconds and shares a six-second capacitor with the Shift dash. A parasite already attached to the glass can still bite.
- Leave clearance around ships, canyon walls and solid scenery. A collision pushes your ship away from the point of contact and damages the hull through active shields, even during a roll. A continuous scrape counts as one impact. The training range keeps you flying at one hull point.
- Press **V** to toggle the thermal governor. It breaks sustained fire into cooling bursts.
- Press **X** to restore up to 23% of maximum shield in a campaign sortie. The surge adds 34 heat and recharges in 16 seconds. It requires enough thermal headroom.
- Press **R** to cycle the tactical radar through 180, 360 and 720 meters. Press **I** during a boss encounter to hear the computer repeat its recon.
- Hold left mouse: fire the equipped primary weapon.
- Right mouse or Escape: pause and inspect status. Use Resume or Escape to return.
- Space: fire the selected secondary station if its shared ordnance cost is available.
- F11: toggle fullscreen.
- Backtick (`): developer testing panel. Close it with backtick or Escape.
- 1/2/3: route reactor power to weapons/shields/engines during live combat.
- 0: restore balanced reactor power.
- Shift: emergency side-dash and temporary projectile deflection.
- C: deploy an equipped chaff/flare charge against nearby incoming missiles.

During station departure, hyperspace, descent, ascent, wreckage clearance, and docking, the flight computer controls
the approach. Right mouse/Escape and focus-loss pause also freeze these
automatic sequences. During asteroid combat, the mouse remains fully active.
Evasion can only be initiated during combat/training, not during autopilot
transit. An already-active maneuver finishes smoothly across a phase transition.

The briefing and pause menus offer three flight-response settings, reduced effects,
audio mute and camera motion. Reduced effects dampen the roll animation and
interior light flashes. Turning off camera motion also dampens the roll and removes impact shake.
Settings persist locally. Losing focus pauses the
game; it does not resume automatically.

Reduced glow retains the additional geometry and extended view distance.
Aim for pink ground turrets before reaching them, and change direction after a
missile is launched rather than maintaining a straight intercept course.

## Live cockpit displays

- Top combiner: phase, objectives, time until the next sequence during automatic
  flight, boss/progress bar, and missile warnings.
- Left angled MFD: shield, hull, impact status, and Shift recharge/readiness.
- Right angled MFD: weapon damage, missile ammunition, credits, speed, and FPS.
- The center MFD plots contacts on a forward-up scope around your ship. Red triangles mark threats, circled red triangles mark missiles, amber squares mark objectives, green crosses mark salvage and dots mark obstacles. A white ring marks the tracked target. A short vertical stroke indicates a contact significantly above or below you.
- A closing missile or predicted collision with an egg or rock gives a time-to-impact warning. The escape arrow points away from the obstacle. The winged white pip shows lateral motion, and the amber lead pip predicts a Quad Plasma intercept on a moving fighter.
- Left five-slot gauges: shield charge. Right five-slot gauges: weapon heat.
  Overheat locks only the primary; secondary missiles remain available.
- Live HUD: current combat multiplier and score. Blue target brackets indicate
  a gunship whose shield faces you.
- Cyan core markers identify collectible minerals; the top combiner reports
  tractor locks and nearby blast danger. Igniting a volatile core also raises
  an immediate warning message.

## Asteroid mining

Mine gold rocks early enough to collect their cores as you approach. Without
a tractor, steer through the core; with a tractor, remain within 32 meters
with a clear line of sight. The cyan tether shows when the tractor has a lock.

Shoot violet rocks from a distance. Each newly ignited core has its own warning
fuse, so a chain can continue toward your flight path. Blast damage can break a
combat streak if it reaches the hull. Pausing freezes cores and warning fuses.
Uncollected cores and outstanding blasts are removed when leaving the stage;
at most 32 cores remain active, with an explicit message if the oldest disperses.

The distant gray rock field provides depth outside the reachable corridor.
Those instanced background rocks are visual dressing, not shootable obstacles.
The 232 foreground rocks provide the actual collisions, mining, and chains.

## Combat tactics and scoring

The side-dash moves to the opposite side of your **current** position. Use it to
escape a missile approach, but check the corridor before shifting toward a tower
or rock. Holding Shift does not repeat the maneuver automatically.

Gunship shields open during a clearly visible bank in their six-second cycle.
A concussion hit both deals damage and briefly halts the gunship's movement and
firing. Shield-blocked primary shots do not count as hits or earn rewards.

Ships, ground turrets, collapsing towers, and defeated boss cores advance the
combat streak. Hoops fund the wallet independently of the score multiplier.
Training permits practice evasions but does not earn campaign score or credits.

The artwork retains its original transparency and aspect ratio. The HUD uses the
provided 1376x768 corner coordinates, including perspective correction for
trapezoid displays; it is not painted into the PNG.
The digital instrument textures refresh at 30 Hz, with immediate updates for
critical changes. Mouse control, aiming reticle, threat markers, and world
rendering remain full-rate.

## Market, repairs, and recovery

All docking repairs are free: intact ships regain full hull and shield strength.
Shields also recharge at phase boundaries; hull damage carries between combat
phases until docking.

Buying another hull replaces the previous hull and transfers fitted upgrades.
This includes the tractor beam; ejection loses it with the ship.
Ammunition is limited to the new hull's bay capacity. The Rook Scout costs 300
credits. The Vector Hawk costs 900 and trades some hull/shield strength for faster
response, a smaller hitbox, and an eight-round bay.
The Aegis Titan costs 2,400 credits (240 hull / 160 shield / 12 ordnance);
the Nova Bastion costs 3,600 (200 hull / 220 shield / 16 ordnance).
Their steering responses are 70% and 80% of the Rook's, with larger hitboxes.

Ejection loses the ship, fitted upgrades, and ammunition, but keeps credits
earned before ejection. A failed sortie receives no completion/survival bonus.
If no replacement is affordable, claim the free Rescue Skiff; no debt is added.
After obtaining a ship, choose an eligible sector for station launch, hyperspace,
descent and ground assault. Cleared-sector progress survives ejection. Complete
all currently available sectors to unlock normal-reward replays. Pilots who
already unlocked replays in earlier builds keep that access. Completing all six
opens the final debrief; choose Continue to start the next tour, or Retire to
record the result and return to the title without losing the saved campaign.

## Checkpoints and developer tools

Campaign saves are stored in `%APPDATA%\Cosmos Conflict\campaign.json`.
This legacy folder name is deliberately retained after the Cosmic Conflict
rename so existing saves and preferences continue to work.
Autosaves occur at phase boundaries, on recovery/docking, and after market
changes. Exiting during combat restarts that phase at its saved boundary:
unfinished phase earnings, damage, and ammo usage roll back together.
Training never changes campaign progress.
Power selection and cooling upgrades are included in phase-boundary saves.
An unfinished launch resumes from the station. Reaching the canyon writes the
ground-phase checkpoint; continuing that active-phase checkpoint does not
replay the departure. Training remains the separate immediate practice course.
Combat streaks, best streak, score, and bonus totals are also checkpointed.
Tractor ownership, mineral earnings, collected cores, and chain counts are saved
with the same phase boundary, preventing extra mining rewards from reloading.
When loading an older save, the first upgraded write preserves its original
contents as `campaign.json.v1-<timestamp>-<counter>.bak` or
`campaign.json.v2-<timestamp>-<counter>.bak` or
`campaign.json.v3-<timestamp>-<counter>.bak` or
`campaign.json.v4-<timestamp>-<counter>.bak` or
`campaign.json.v5-<timestamp>-<counter>.bak` or
`campaign.json.v6-<timestamp>-<counter>.bak` or
`campaign.json.v7-<timestamp>-<counter>.bak` or
`campaign.json.v8-<timestamp>-<counter>.bak` or
`campaign.json.v9-<timestamp>-<counter>.bak` or
`campaign.json.v10-<timestamp>-<counter>.bak` or
`campaign.json.v11-<timestamp>-<counter>.bak`, matching the old schema.
Reloading a phase restores its score, streak, credits, and encounters together;
it does not duplicate rewards.
The docking approach has its own checkpoint. Resuming it repeats alignment and
hangar entry. Docking marks the sector complete.
Tour baselines, cumulative hull damage and frozen completion results use that
same checkpoint. The separate `%APPDATA%\Cosmos Conflict\hall_of_fame.json`
contains completed-tour records. Malformed saves or record-write failures are
reported explicitly; a failed recording cannot discard the completed campaign.

Backtick opens credits, ship/equipment, refill, invincibility, sector-test and phase-jump
tools. Changes mark the operation as developer-assisted. Opening testing tools
from training/title uses a separate `debug_campaign.json`; normal progress is
not replaced. Non-warp actions preserve phase time, and closing the testing
panel restores an existing pause.

## Install and play

Run the provided Windows installer. It installs for the current user without
requiring administrator access and creates Start-menu shortcuts. Launch
**Cosmic Conflict** and select **New Operation / Choose Sector**.
Select **Create a desktop shortcut** on the Additional Tasks page if desired;
the option is unchecked on a fresh install.
Use **Launch Training Flight** for the separate practice course.
Installing this version updates an existing Flight Lab installation and retains
your preferences. Earlier installers remain in their separate release folders.
The installer keeps the same upgrade identity and reuses an existing installation
directory. New Start-menu entries use Cosmic Conflict; repin an old taskbar
shortcut if it still points at the previous executable name.

The build is unsigned. Windows may display a publisher/reputation warning.
No network connection, Godot editor, or language runtime is required to play.
Uninstall through Windows Installed Apps or the Start-menu uninstall shortcut.
User saves, preferences and Hall of Fame records are retained on uninstall.
An installed desktop shortcut is removed with the application.

Vulkan is the default graphics renderer. If an older PC cannot start it, use
the **Cosmic Conflict (OpenGL Compatibility)** Start-menu shortcut. It uses
the same saves, artwork, and gameplay; frame-time performance may differ.
In v0.18.0, the verified 1080p Cryo-field runs with music meet the 33.33ms
99th-percentile frame-time target on the test machine with Vulkan and with
OpenGL using Reduced glow. Prefer the default Vulkan shortcut when supported.
Performance depends on the machine and settings; isolated longer frames remain
possible, and clean-machine/every-hardware compatibility is not certified.
From a portable export, use:

```powershell
.\CosmicConflict.exe --rendering-method gl_compatibility --rendering-driver opengl3
```

## Review focus

1. Do boss pursuit, ascent, belt entry, and docking feel like one continuous flight?
2. Are the boss weak points readable amid the added mechanical details?
3. Are dogfight acquisition speed and red radar contacts comfortable and useful?
4. Do asteroid passes feel close without the nominal autopilot route colliding?
5. Are tower-base targeting and collapse animations clear?
6. Do the cratered models and increased field density match the supplied ideas?
7. Are core collection, tractor attraction, and volatile-blast warnings clear?
8. Are tripwire nodes, radar suppression, and optional pirate bounties readable?
9. Do vent warnings and the boss thermal fan allow enough time to steer clear?
10. Is the left/right route choice clear, and do the fork and rejoin feel smooth?
11. Are the three supply types and their separate inventory limits easy to understand?
12. Are the brighter plasma and continuous tachyon beams readable without obscuring targets?

## Still in development

Hull concepts beyond the two delivered player battleships, additional ordnance,
mission branches and unselected planetary hazards remain future refinements.
All three primary families and six selectable planets have distinct behavior.
Human balance/accessibility feedback, clean-machine and other-hardware testing,
and public/commercial rights, title and signing decisions remain open.

## Developer commands (PowerShell, from the project root)

### Original soundtrack and release checks

The original composition/synthesis is in
[generate-music.gd](../tools/generate-music.gd). Its nine recordings and checksum
index are under `current_dev\assets\music`. To regenerate them entirely offline:

```powershell
& '.\.tools\godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path '.\current_dev' --script (Join-Path (Get-Location) 'tools\generate-music.gd')
.\tools\build.ps1
```

The build checks generator and recording fingerprints rather than silently
packaging stale/missing music. Native
`--script res://tests/test_polish_render_audio.gd` checks real playback, fades,
pause, speech ducking, end-of-loop continuity and the added controls.
The exported game's `-- --music-test` checks packaged playback with master output
muted; it does not capture microphone or other applications' audio.
Add `--with-music` to a campaign mission or performance benchmark to exercise
real soundtrack playback and scene changes while master output stays muted.
The benchmark verifies an actual music-bus signal, not just a configured slider.

After building a release, `.\tools\validate-installer.ps1` compiles separate
validation-identity installers, exercises install/upgrade/uninstall, verifies
payload hashes and shortcuts, runs installed-game checks and verifies retained
test saves/settings/records. It checks the normal installation registration and
normal data fingerprints without changing them. The default upgrade source is
v0.17.1. This is a local isolated test, **not** a substitute for a clean Windows VM.
The installer-validation and source-archive scripts require PowerShell 7 or newer;
playing the installed game requires neither PowerShell nor developer tools.

`.\tools\archive-source.ps1` creates a versioned ZIP with per-file hashes and
verifies every archived entry. It preserves any existing archive rather than
overwriting it. Generated recordings and import settings are included; local
engine/template caches, build products, user saves and `.godot` caches are not.
Restore the pinned tools with bootstrap or an existing offline cache before
rebuilding. Archive verification does not claim that timestamped installers
are bit-for-bit reproducible.

Before any public/commercial release, independently confirm supplied-art and
platform voice redistribution rights, Inno Setup licensing, title/trademark
clearance and code signing. Those decisions are not implied by private testing.

### Editing computer-voice quips

#### Desktop voice editor

Open **Cosmic Conflict Voice Editor** from the Start menu after installing the
updated build, or double-click `VoiceEditor.cmd` beside the game executable.
It opens its own editor window without starting a mission.

- Search sayings by words, ID or event, and narrow the list by category.
- **Add saying** creates an extra entry without changing existing sayings.
  Choose a category and an existing game event, enter the words, then click
  **Add saying** in the dialog. The editor assigns a unique ID and selects the
  new entry. Ordinary entries start at 100% chance; route entries start at 25%,
  both with no extra repeat delay. Adjust these controls, preview, then save.
  New entries receive offline audio automatically; no rebuild is needed for
  an installed game's voice file. Canceling the dialog adds nothing.
- Edit the text, percentage chance and minimum repeat delay with normal controls.
  The **Enabled** switch sets a saying's chance to zero; switching it back on
  restores its previous chance during that editing session.
- **Play voice preview** speaks your current, unsaved text with the game's
  offline voice and radio effects. Preview ignores chance/cooldown and works
  even for a disabled saying. **Stop** ends playback immediately.
- **Open...** accepts either the installed game's JSON or a development catalog.
  **Game file** opens the per-user installed-game file; **Source file** is also
  available when running from the development project. The full current path
  appears above the library; **Show folder** opens its location.
- **Save changes** (`Ctrl+S`) validates the entire file before replacing it.
  The previous contents are preserved in a sibling `.bak` file, replaced by the
  next successful save. **Save as...** (`Ctrl+Shift+S`) saves a separate copy.
  **Exit editor** closes the editor. It and the window's close button offer
  Save changes, Discard changes or Cancel if you have unsaved edits; Cancel
  keeps the editor open. Changing files also asks before discarding unsaved changes.
  If another program changes the file, the editor refuses to overwrite it:
  reopen it, or use Save as to preserve your edits elsewhere.

Close and restart the game after saving. The editor does not change event IDs,
category metadata or your campaign saves, and does not rebuild the game.
Previewing changed text needs the same locally installed Windows voice as the game.

Developers can launch the editor directly:

```powershell
& '.\.tools\godot\Godot_v4.7.2-stable_win64.exe' --path '.\current_dev' --rendering-method gl_compatibility --rendering-driver opengl3 -- --voice-editor
```

An optional `--voice-file="C:\path\to\lines.json"` after `--voice-editor` opens a
specific file. The editor normally opens the development catalog when running
from source, or the per-user file when running the exported game.

#### Editing the JSON directly

You can still close the game, edit its JSON file in a text editor, save, then restart:

- **Running from this source project:** edit
  [the voice catalog](../current_dev/assets/voice/lines.json).
- **Running an exported/installed game with this feature:** the first launch
  creates `%APPDATA%\Cosmos Conflict\computer-voice.json`. Open that path with
  Notepad. This writable, per-user file survives game updates and is never
  overwritten automatically. An older installed executable must first be
  updated to a build containing this feature.

Each saying has three editable fields:

```json
{"id":"reactor_01","event":"reactor_weapons","added":false,"chance_percent":50,"cooldown_seconds":120,"text":"Weapons ready. Please aim carefully."}
```

- `text`: the actual words spoken. Keep `id`, `event` and category metadata
  unchanged. Use valid JSON; escape quotation marks inside a saying as `\"`.
- `chance_percent`: a whole number from **0 to 100**. **0 disables** this saying;
  100 always passes its chance check. When a relevant event is eligible, the game
  chooses one available saying, avoiding immediate repeats where possible, then
  rolls that saying's chance. A failed roll produces silence, not a retry with a
  different saying. Thus 50 means half the occasions **when that saying is
  selected**, not half of all events when several sayings compete.
- `cooldown_seconds`: **0 to 86400**, including fractional seconds. Minimum
  gameplay time between starts of this particular saying; 120 means at least two
  minutes. Pausing freezes it; phase changes do not clear it. Restarting the game
  clears repeat timers. Zero adds no extra repeat delay.

Existing event cooldowns, quiet intervals and urgent-warning priorities still
apply. Sayings remain event-triggered, not periodic announcements, so a cooldown
is a minimum rather than a promise to speak on a schedule. Defaults preserve the
old timing: ordinary sayings have 100% chance, route quips 25%, and all extra
per-saying cooldowns start at zero. Disabling a warning also disables that warning's
spoken line, so take care with hull and ejection messages.

The game plays bundled Chatterbox-Turbo recordings offline. The opening casts
Captain Tomas Vale and Lark separately. The spoofed beacon uses Lark's voice.
The Windows Voice Editor also plays the bundled takes for unchanged text.
For new text it uses the configured Turbo Python environment, or Microsoft Zira
Desktop on a standard installation. Older catalogs keep their selected Windows
voice for custom lines. Edited audio is cached under
`%APPDATA%\Cosmos Conflict\voice-cache`; changing frequency reuses the recording.

To render release audio or enable Turbo for custom lines, install Python 3.11
and Git, then run these commands from the repository root. The first render
downloads the pinned public Turbo checkpoint. For offline authoring set
`COSMIC_TTS_MODEL` to a previously downloaded checkpoint directory. The engine
selects CUDA when available and otherwise runs on CPU. Launch the Voice Editor
from the same environment to use Turbo for newly edited text.

```powershell
py -3.11 -m venv .tools\chatterbox
$env:COSMIC_TTS_PYTHON = (Resolve-Path .tools\chatterbox\Scripts\python.exe).Path
& $env:COSMIC_TTS_PYTHON -m pip install -r tools\chatterbox-requirements.txt
.\tools\generate-voice.ps1 -Overwrite
.\tools\generate-opening.ps1
.\tools\build.ps1
```

The generator replaces only the named generated clips and validates their audio
format. The build checks each recording's text fingerprint, independently of
frequency settings. Editing the source file does not change a separate installed
game's per-user file.

### Building and running

```powershell
.\tools\bootstrap.ps1
.\tools\build.ps1 -TestOnly
.\tools\build.ps1
& '.\.tools\godot\Godot_v4.7.2-stable_win64_console.exe' --path '.\current_dev'
```

Godot is pinned in the toolchain manifest. Bootstrap stores a portable engine and
Windows export templates under `.tools`; it does not change global engine
settings. The editor ZIP is checked against the official SHA-512 manifest.
Windows templates are fetched from the official archive using HTTPS byte ranges,
then checked against each ZIP entry's size and CRC-32. This avoids downloading
unneeded templates for other platforms; it is not a full-archive SHA-512 check.

Inno Setup 6 is required to compile the installer. Its compiler path can be
supplied with `build.ps1 -Iscc 'C:\path\to\ISCC.exe'`. Existing cached tools support
offline build/test use. Bootstrap requires internet when checking remote entries.

#### Android

The left thumbstick aims and steers. Touch the canopy with a second finger to aim
independently while steering. Hold **FIRE** for the primary guns, or tap **ORD**,
**FLARE**, **ROLL**, **DASH**, or **PAUSE**. The controls appear during flight on
Android. Menus accept ordinary taps.

On Windows, set `JAVA_HOME` to a JDK 17 or newer and `ANDROID_HOME` to an Android
SDK with Platform-Tools and Build-Tools 35.0.0 or newer. To make a test install:

```powershell
.\tools\bootstrap.ps1 -Platform Android
.\tools\build.ps1 -Platform Android -AndroidPreview
```

The preview APK in `releases/<version>/` has its own application ID and a fresh
test signing key. Uninstall an older preview before installing another preview.
Production builds keep the same signing key so Android can upgrade existing
installs and preserve their saves. Set `ANDROID_RELEASE_KEYSTORE` to the keystore
path, `ANDROID_KEY_ALIAS` to its alias and `ANDROID_KEYSTORE_PASSWORD` to its
password. Set `ANDROID_KEY_PASSWORD` if the key uses a different password.
Run `.\tools\build.ps1 -Platform Android` for the signed APK, or use
`-Platform All` with both bootstrap and build to include Windows. The APK
supports ARM64 phones and x86-64 emulators.

For GitHub releases, configure repository secrets `ANDROID_KEYSTORE_BASE64`
(the base64-encoded release keystore), `ANDROID_KEY_ALIAS`,
`ANDROID_KEYSTORE_PASSWORD`, and optionally `ANDROID_KEY_PASSWORD`. The main
release workflow attaches the verified, signed APK and lists its SHA-256.
Until the keystore is configured, CI uploads the test APK as a preview workflow
artifact and continues to publish the desktop releases.

Native render validation supports `-- --smoke-test` or `-- --benchmark`.
`-- --campaign-test` flies all six sectors and twelve bosses, then exercises the
final debrief, retirement, exact reload, separate assisted records, next-tour
reset and another departure. It uses an isolated campaign and adjacent Hall of
Fame, never normal records. Add `--validation-tour=5 --validation-ship=emergency`
to play the capped-health campaign with a baseline Rescue Skiff; earlier-tour
counters are an explicitly labeled validation fixture, not fake gameplay results.
This accelerated functional test is not performance evidence. The focused/native
screen test is `--script res://tests/test_campaign_completion.gd`; native runs can
use `-- --capture-dir=C:\existing\folder` to retain the new screens.
`-- --ground-benchmark` measures the full ninety-second safe ground course,
including the roadside eruptions, at normal speed and actual 1080p resolution.
Add `--validation-sector=ignis`, `--validation-sector=cryo` or
`--validation-sector=vespera`, `--validation-sector=xylo`,
`--validation-sector=thalassa` or `--validation-sector=kharon` to choose a test
destination. `--frost-damage-only` is a validation-only comparison: it retains
frost damage and timing but removes the steering penalty. Ordinary play uses
the brief non-stacking slowdown.
Add `--validation-primary=0`, `1` or `2` to a campaign mission/benchmark for
Twin Pulse, Quad Plasma or Tachyon Beam. This equips an assisted test fixture,
not a free upgrade in ordinary play. Use the orbital benchmark separately for
each advanced primary and omit screenshots for performance measurements.
`-- --branch-benchmark` flies the complete hazard route at normal speed with an
assisted equipment fixture, but without invincibility. It verifies the real
right-side route selection, all three fly-through supplies, the rejoin reward, boss handoff
and actual 1080p frame-time budget. The normal `-- --mission-test` keeps the
safe route; add `--hazard-route` to test the full mission through the trench.
`-- --launch-benchmark` flies the station turn/undocking, hyperspace and descent
at normal speed, then checks the first five ground seconds and actual 1080p
frame-time budget. Avoid screenshots during performance measurements.
`-- --orbit-benchmark` plays the 90-second orbital stage at normal speed,
including deployed tripwires and their disarm, then follows the automatic
boss-intercept turn and first five pursuit seconds. The turn is included in
the same actual-1080p/30-FPS percentile checks. Native
`--script res://tests/test_orbital_arrival.gd` additionally compares the rendered
boss before, during and after activation on all six sectors.
`-- --boss-benchmark` includes an active thermal sweep, defeating the orbital
boss, and its final explosion at normal speed. Its scripted pilot deliberately
leaves the projector alive long enough to exercise the effect.
With Cryo selected it instead verifies actual Hydra drone launches before
destroying the optional bay and required boss sections.
With Vespera selected it verifies an active Nyx cloak and ordinary primary-weapon
victory without bypassing the generators.
With Xylo selected it verifies biological projectile attacks and Leviathan's
normal defeat.
`-- --entry-benchmark` includes the orbital boss, wreck clearance, rising belt
approach and the first five active seconds in the same asteroid field.
`-- --belt-benchmark` measures the complete 60-second asteroid stage and its
continuous climb/approach/docking at normal
speed and requires collision-free nominal flight, actual 1920x1080 rendering,
and p99 frame time at or below 33.33 ms (the 30 FPS minimum). It does not capture screenshots during
measurement, avoiding image-readback stalls.
`-- --mining-test` fires at real mineral/volatile rocks, collects a core with the
tractor, triggers a chain, docks, and verifies the saved mining totals.
On Xylo it instead shoots egg cargo, collects the biological pod, and verifies
that egg destruction creates no asteroid fragments.
These modes default to an isolated validation save; `--campaign-save=` can name
a separate disposable test checkpoint.
Add `--capture-dir=C:\an\existing\directory` for screenshots. These runs exit
automatically, mute their audio, and do not save changed preferences. Benchmark
windows do not capture/warp the pointer, accept physical gameplay input or take
keyboard focus. Their rendering viewport is fixed at 1920x1080 independently
of the presentation window size, preserving the actual-resolution measurement.
Benchmark output includes frame-time mean, p95, p99, maximum, and gameplay counters.
Do not interpret a headless run as a GPU performance measurement.

Automation uses normal glow and balanced response unless `--reduced-effects` is
provided. For the native distant-detail and depth-occlusion check:

```powershell
& '.\.tools\godot\Godot_v4.7.2-stable_win64_console.exe' --path '.\current_dev' --script 'res://tests/test_detail_render.gd'
& '.\.tools\godot\Godot_v4.7.2-stable_win64_console.exe' --path '.\current_dev' --script 'res://tests/test_cockpit_composite.gd'
& '.\.tools\godot\Godot_v4.7.2-stable_win64_console.exe' --path '.\current_dev' --script 'res://tests/test_tactical_render.gd'
& '.\.tools\godot\Godot_v4.7.2-stable_win64_console.exe' --path '.\current_dev' --script 'res://tests/test_belt_visual.gd'
& '.\.tools\godot\Godot_v4.7.2-stable_win64_console.exe' --path '.\current_dev' --script 'res://tests/test_cryo_render.gd'
& '.\.tools\godot\Godot_v4.7.2-stable_win64_console.exe' --path '.\current_dev' --script 'res://tests/test_vespera_render.gd'
& '.\.tools\godot\Godot_v4.7.2-stable_win64_console.exe' --path '.\current_dev' --script 'res://tests/test_xylo_render.gd'
& '.\.tools\godot\Godot_v4.7.2-stable_win64_console.exe' --path '.\current_dev' --script 'res://tests/test_planet_arrival_render.gd'
& '.\.tools\godot\Godot_v4.7.2-stable_win64_console.exe' --path '.\current_dev' --script 'res://tests/test_computer_voice_audio.gd'
& '.\.tools\godot\Godot_v4.7.2-stable_win64_console.exe' --path '.\current_dev' --script 'res://tests/test_boss_render.gd'
& '.\.tools\godot\Godot_v4.7.2-stable_win64_console.exe' --path '.\current_dev' --script 'res://tests/test_outline_render.gd'
& '.\.tools\godot\Godot_v4.7.2-stable_win64_console.exe' --path '.\current_dev' --script 'res://tests/test_thermal_render.gd'
& '.\.tools\godot\Godot_v4.7.2-stable_win64_console.exe' --path '.\current_dev' --script 'res://tests/test_secondary_render.gd'
& '.\.tools\godot\Godot_v4.7.2-stable_win64_console.exe' --path '.\current_dev' --script 'res://tests/test_countermeasure_render.gd'
```

`-- --mission-test --campaign-save=C:\existing\folder\test-campaign.json`
exercises the complete mission, shopping, reload, secondary fire, forced ejection,
and emergency recovery using an isolated save. It runs at accelerated simulation
speed and is a functional test, not the normal-speed performance benchmark.
Add `--real-time` to run it at normal simulation speed, and use the engine's
`--max-fps 30` or `--max-fps 45` before `--` to test capped presentation.
`--validation-ship=rook`, `hawk`, or `emergency` selects an isolated assisted
test loadout; it does not change interactive starting ships or normal saves.
`.\tools\validate-soak.ps1 -Minutes 120` runs a bounded real-time full-mission
matrix across hulls, 30/45-FPS caps, effects settings and renderers using the
current export. Logs and per-scenario results remain in the release validation
folder; disposable test checkpoints are removed. A failed scenario or startup
timeout is recorded explicitly and makes the overall command fail.

Native voice validation mutes the master output while checking the isolated
voice bus, actual playback position, pause/preemption, four-second silence and
volume-off behavior. `--voice-preview=C:\existing\folder\preview.wav` records only
that game's processed voice bus, not microphone or other application audio.
The exported game's `-- --voice-test` mode verifies that the packaged catalog,
recordings and processed voice bus work, with master output kept muted.
