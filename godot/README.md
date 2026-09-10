# Miami Approach — Milestone 1

A standalone Godot visual prototype for Flight Sim GPT. It adds a procedural
Airbus-inspired cockpit and exterior, a Miami scenery study, data-backed KMIA
runway placement, lighting and weather presets, and repeatable approach replay.

**This milestone is a graphics study.** The camera follows a programmed 3°
approach at 145 knots. The preview instruments display that demonstration.
The Python flight model has not been ported or connected yet. Manual flying,
taxiing, takeoff, landing physics, and controller support belong to subsequent
milestones. The original Python simulator remains runnable from the repository
root with `python main.py`.

## Run on your Mac

The **Miami graphics** GitHub Actions run attached to the pull request produces
an artifact named **Miami-Approach-macOS**. Download that artifact while signed
into GitHub, unzip it, then unzip `Miami-Approach-macOS.zip` and open the app.
It is a Universal 2 build with an ad-hoc signature for testing, and is not
notarized. macOS may require approval in **System Settings → Privacy & Security**
after the first attempt to open it. See [Godot's Mac export notes](https://docs.godotengine.org/en/4.5/tutorials/export/exporting_for_macos.html).

To run from source instead:

1. Download **Godot 4.5.1 Standard** from the
   [official archive](https://godotengine.org/download/archive/4.5.1-stable/).
2. Download or clone this development branch.
3. In Godot's Project Manager choose **Import**, select `godot/project.godot`,
   and open it. Press **F6** with `main.tscn` open, or **F5** to run the project.

The intended Mac renderer is **Mobile using Metal**, requiring macOS 13 or
later for this path. Low/Balanced/High change internal resolution, building
count, antialiasing, and shadow distance. Begin with Balanced at 1080p or below.
The startup window is 1280×720 and is resizable; the UI uses a 1600×900 design
canvas. See [Godot platform requirements](https://docs.godotengine.org/en/4.5/about/system_requirements.html).

An 8 GB M1 is the target machine, not a verified minimum yet. The 30 FPS and
3–4 GB working-set goals remain unmeasured on that hardware.

## Controls

| Action | Input |
| --- | --- |
| Cockpit / wing / chase camera | 1 / 2 / 3, or bottom controls |
| Look around | Hold right mouse button and drag |
| Zoom | Mouse wheel |
| Release mouse and center view | Escape |
| Pause / resume approach motion | Space |
| Restart the approach | R |
| Cycle golden hour / daylight / blue hour | T, or Light menu |
| Clear / scattered / cloudy sky | Sky menu |
| Change detail preset | Detail menu |
| Toggle performance panel | F1 |
| Hide / show all interface | H |
| Start / stop and save a benchmark | B, or performance-panel button |

The approach restarts shortly before the runway threshold. Pause freezes
aircraft movement; sky animation continues. There is no touchdown simulation.
Changing the detail preset reuses existing scene instances rather than
allocating another city.

## Benchmark on the target Mac

Run the exported app; the editor adds its own overhead. Use a
fixed window size and record whether the 30 FPS limiter is enabled. Test all
camera and lighting presets, including the airport approach and repeated
restarts, for at least **20 minutes**. Record Mac model, RAM, macOS version,
resolution, detail, and weather. For raw frame-rate capacity, disable the FPS
limiter; compare like-for-like configurations.

Press B to start, then B to save a JSON report. Use **Open reports folder** to find it. Its absolute path is also printed in
Godot's console. On macOS reports normally live inside
`~/Library/Application Support/Godot/app_userdata/Miami Approach/benchmarks/`.
Reports contain frame-time percentiles, average FPS, per-second engine
counters, renderer/GPU identification, and setting changes.

**Engine static-memory and render-memory counters are not the application's
total memory footprint. Do not add them together as unified memory usage.**
Use Activity Monitor and, where available, Instruments to check the exported
app's footprint, memory pressure, and swap over the same run. Note other open
applications. No M1 performance result is included or implied by this project.

## Scene scope and assets

The four KMIA runway pairs use the coordinates and widths in the bundled
OurAirports snapshot. The approach targets 26R. Airport pavement, terminal
buildings, taxiways, skyline, coastline, islands, bridges, and port cranes are
**approximate original scenery**, not a surveyed reconstruction. Terrain is
flat. The coast is a procedural outline, not imported GIS geometry.

The cockpit, airframe and materials are original procedural assets. Cockpit
proportions, the fuselage nose, wing profiles, glazing, doors, and lighting need
further art work. There is no licensed production-quality A320 cockpit in this
milestone. There are no paid assets, remote textures, network services, or
runtime downloads. See [asset provenance](THIRD_PARTY_NOTICES.md).

The source is deliberately separated into `miami_world.gd` (scenery),
`aircraft_visual.gd` (model), `instrument.gd` (preview displays), `main.gd`
(demonstration/cameras/settings), `hud.gd`, and `benchmark.gd`. This provides a
clear attachment point for the later flight-model integration.

## Development checks

From the repository root, with the Godot executable on PATH:

```sh
godot --headless --editor --path godot --import
godot --headless --path godot -- --smoke-test
```

The smoke test loads the full scene and checks airport data, camera transforms,
detail/lighting/weather switches, pause/restart behavior, and benchmark output.
Headless rendering cannot validate shader appearance. A normal rendered run
is required too. Capture an actual engine frame with:

```sh
godot --path godot -- --capture=/absolute/path/miami.png --capture-after=4
godot --path godot -- --capture=/absolute/path/chase.png --view=2 --light=1
```

`--hide-ui` captures the scene without the interface. The application exits
after capture. `--view=0/1/2` and `--light=0/1/2` select the starting presets.

## Export locally

Install the 4.5.1 export templates with **Editor → Manage Export Templates**.
The committed `macOS` export preset includes the runway JSON and sets macOS 13
as its minimum. From the repository root:

```sh
mkdir -p godot/build
godot --headless --path godot --export-release macOS build/Miami-Approach-macOS.zip
python3 godot/tests/check_mac_export.py godot/build/Miami-Approach-macOS.zip
```

The export has been built and package-checked on Linux. That verifies the
bundle structure, Apple Silicon/Intel executable slices, permissions and
project pack; it does not verify Metal rendering or launch on macOS. The
project has been rendered on Godot's Mobile renderer using Linux software
Vulkan. [Screenshots and acceptance status](../docs/miami-milestone-1.md).
