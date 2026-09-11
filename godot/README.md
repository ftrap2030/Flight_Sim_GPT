# Miami Approach — Landing and taxi prototype

A standalone Godot prototype for Flight Sim GPT with an assisted arrival,
animated landing surfaces, reverse thrust, and a connected ten-gate apron.

**Landing and taxi steering are assisted.** The aircraft follows a programmed
3° approach, flares, touches down, deploys spoilers and reversers, then brakes
to a stop before taxi. You control taxi speed on the selected route, or enable
auto taxi. This is not a validated flight or landing dynamics model. The Python
flight model is still separate; manual flying, free taxi steering, takeoff,
and controller support are not connected. The original Python simulator
remains runnable with `python main.py`.

## Run in a browser

Open [Miami Approach](https://miami-approach.ftrap.chatgpt.site) and select
**Open cockpit**. No Mac app download is needed. It starts at Low detail. A desktop browser with
WebGL 2 and hardware acceleration is required. Chrome is the first browser to
try on Mac. The engine downloads about 9 MB compressed on the first launch.

The browser uses Godot's Compatibility renderer and a 1280×720 canvas; visual
lighting differences from Metal are expected. Detail changes building count,
antialiasing and shadows; internal rendering stays at 100% of that canvas.
Benchmark reports download as JSON files when recording stops. Browser memory
counters do not measure total browser/process memory. Tab suspension can affect
replay timing and benchmark results.

To rebuild from source (Godot 4.5.1 with Web export templates installed):

```sh
mkdir -p godot/build/web
touch godot/build/.gdignore
godot --headless --editor --path godot --import
godot --headless --path godot --export-release Web build/web/index.html
python3 godot/web/prepare_web.py godot/build/web
node godot/tests/check_web_export.mjs godot/build/web
```

Serve the prepared files over HTTP(S). Opening `index.html` directly from Finder
will not work. The loader decompresses the engine explicitly; no special gzip
headers, service worker, or cross-origin isolation is required. Check
[Godot's Web export documentation](https://docs.godotengine.org/en/4.5/tutorials/export/exporting_for_web.html)
for browser limitations.

## Run on your Mac

The **Miami graphics** GitHub Actions run attached to the pull request produces
an artifact named **Miami-Approach-Mac-Verified**. Download that artifact while signed
into GitHub, unzip it, then unzip `Miami-Approach-Mac.zip` and open **Miami Approach.app**.
Use the final verified artifact; `Miami-Approach-export` is an intermediate build.
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
| Restart the full arrival, keeping the selected gate | R |
| Jump to short final (about 17 seconds to touchdown) | L, or arrival-panel button |
| Select gate A1–A10 before taxi begins | Destination menu |
| Increase / decrease taxi target speed | Hold W / S or Up / Down, or Faster / Slower |
| Brake and cancel auto taxi | Hold X |
| Auto taxi / stop auto taxi | G, or arrival-panel button |
| Set / release parking brake | P, or arrival-panel button |
| Enable / mute synthesized engine and reverse sound | Engine / reverse sound switch |
| Cycle golden hour / daylight / blue hour | T, or Light menu |
| Clear / scattered / cloudy sky | Sky menu |
| Change detail preset | Detail menu |
| Toggle performance panel | F1 |
| Hide / show all interface | H |
| Start / stop and save a benchmark | B, or performance-panel button |

The aircraft now lands and stops on the runway, waiting for taxi input. Choose
a gate, then press W to increase taxi speed or G for auto taxi. Steering follows
the mint dashed route; yellow lines mark the taxiways and blue lights their
edges. Taxi speed is capped at 15 kt, reduced to about 6 kt on the final gate
turn. Braking overrides auto taxi. Parking at the stand sets the brake; press R
or L for another arrival. Gate selection locks when taxi begins.

Flaps extend on approach and retract after leaving the runway. Spoilers rise
after touchdown, reverser sleeves open during high-speed rollout, and a
synthesized engine/reverse loop follows the sequence. Sound can be muted.
Pause freezes aircraft movement and sound; sky animation continues.
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
OurAirports snapshot. The approach targets 26R. Gates A1–A10 form a **fictional north apron**, connected
without crossing the other runway strips. These are not real KMIA gate numbers
or real-world taxi instructions. Airport pavement, terminal
buildings, taxiways, skyline, port island, bridges, and port cranes are
**approximate original scenery**, not a surveyed reconstruction. Terrain is
flat. Regional land and coast shapes now use a clipped Natural Earth 1:10 million
land dataset. This is generalized GIS geometry, not satellite imagery or a
surveyed shoreline. Beaches and shallow-water bands are original visual effects.

The cockpit, airframe and materials are original procedural assets. The visual
update adds a lofted fuselage and shaped nose, rounded cabin windows and door
seams, cockpit glazing, swept wing sections, inlet lips, pylons and fairings.
Textured cockpit panels include live speed/heading/altitude readouts, pitch and
radio-height indications, responsive engine gauges and a taxi map. These
instruments show the assisted arrival state, not independently simulated avionics.
Further art refinement is still needed. There is no licensed production-quality A320 cockpit in this
milestone. There are no paid assets or remote scenery/texture services; the browser
downloads its engine and packaged project from the site. See [asset provenance](THIRD_PARTY_NOTICES.md).

The source is deliberately separated into `miami_world.gd` (scenery),
`aircraft_visual.gd` (model), `instrument.gd` (preview displays), `main.gd`
(demonstration/cameras/settings), `hud.gd`, and `benchmark.gd`. This provides a
clear attachment point for the later flight-model integration.

## Aircraft and Miami visual update

Runway and taxiway materials add surface grain, asphalt seams, concrete joints
and touchdown rubber. Taxiway signs, terminal mullions, roof equipment, static
ground-service vehicles, light poles and palms add detail around all ten gates.
Freedom Tower and One Thousand Museum have original simplified landmark studies;
a denser Brickell cluster and port/causeway details make the skyline easier to
recognize. Landmark placement and dimensions remain approximate.

The subsequent compact audio update adds engine variation, wheel rumble, flap
motor noise and a touchdown thump. Altitude callouts (1000, 500, 100, 50, 40,
30, 20, 10 ft) use an installed English browser voice when available, with
on-screen captions. Speech availability and voice vary by browser; no cloud
voice is selected. The Sound switch mutes all audio. Sounds are synthesized
prototype effects, not aircraft recordings. Mesh batches are used for repetitive scenery;
there is no satellite texture stream. Performance and RAM on an 8 GB M1 remain
targets to measure, not guaranteed limits.

## Development checks

From the repository root, with the Godot executable on PATH:

```sh
godot --headless --editor --path godot --import
godot --headless --path godot -- --smoke-test
```

The smoke test loads the full scene and checks airport data, camera transforms,
detail/lighting/weather switches, pause/restart behavior, and benchmark output.
Arrival checks also exercise all ten routes, wheel contact, reverse inhibition
in flight, braking overrides, manual taxi speed, stand stopping, and reset.
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

The workflow first exports on Linux, then uses a macOS runner to repackage
with Apple's `ditto`, apply and verify an ad-hoc signature, extract the final
ZIP again, and run the packaged executable's headless scene checks. The final
artifact is uploaded only if those checks pass. These checks do not establish
Metal rendering or performance on an 8 GB M1. The
project has been rendered on Godot's Mobile renderer using Linux software
Vulkan. [Screenshots and acceptance status](../docs/miami-milestone-1.md).
