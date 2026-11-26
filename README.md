# Cosmic Conflict

Cosmic Conflict is a single-player, cockpit-view space combat game built with Godot. Launch from Astra Station, pick a route through a planetary strike run, and fight your way back to orbit. Getting home matters: the credits you bring back buy weapons, defenses, and new ships for your next sortie.

**[Download the latest release](https://github.com/BigSamYork/Cosmic-Conflict/releases/latest)** · **[Player guide](Docs/FLIGHT_LAB.md)**

![A Thalassa Reach flyover](Art/Thalassa%20flyover.gif)

## Start flying

- **Windows x64:** Download the `Setup.exe` asset from the release page and run it. For a portable copy, download the `Windows-x64.zip` asset instead, extract the whole ZIP, and launch `CosmicConflict.exe`. Keep the `.pck` file beside the executable.
- **macOS:** Use the [v1.0.8 universal Mac build](https://github.com/BigSamYork/Cosmic-Conflict/releases/download/v1.0.8/CosmicConflict-1.0.8-macOS-universal.zip). There is no macOS package for v1.0.9.

For a first flight, try the non-lethal training range. When you're ready, choose **New Operation / Choose Sector**. The flight computer handles departure and descent; you take control when the ground run begins.

## What to expect on a sortie

The six sectors range from volcanic **Ignis Prime** and glacial **Cryo-Vex** to the city of **Vespera-9**, the swamps of **Xylo-Mire**, the storms of **Thalassa Reach**, and the siege walkers of **Kharon Dunes**. Each has its own ground hazards, dogfight tactics, and bosses.

In the ground fork, keep left or near center for the safe route; steer right for the hazard route and its supplies. Targets you destroy can leave a green **$** hoop at the point of impact. Fly through it to collect the credits. Back at **Astra Market**, you can switch to a parked hull for free. If you eject, you lose the active ship and its fittings, but your parked ships survive.

| Desktop control | Action |
| --- | --- |
| Mouse / WASD | Aim and steer / move independently of the reticle |
| Left mouse / Space | Fire primary / fire selected secondary |
| Shift / B | Emergency side-dash / barrel roll |
| Right mouse or Esc | Pause or resume |

The [player guide](Docs/FLIGHT_LAB.md#controls) covers the rest, including reactor power, radar, countermeasures, and saving.

## Run from source

1. Install the Godot version listed in [the toolchain configuration](tools/toolchain.json).
2. In Godot's Project Manager, import [`current_dev/project.godot`](current_dev/project.godot).
3. Let the assets finish importing, then press **F6** to run the current scene or **F5** to start the full game.

The [game scripts](current_dev/scripts) and [tests](current_dev/tests) live under `current_dev`. For Windows packaging, see the [toolchain bootstrap](tools/bootstrap.ps1) and [build script](tools/build.ps1).

## License and credits

See the [GNU GPL v3 license](LICENSE) for the project license and [licenses and credits](Docs/LICENSES.txt) for the bundled media.
