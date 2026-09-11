# Miami arrival and taxi update — 2026-09-11

The earlier replay reset before the runway. This update continues through
flare, touchdown, spoiler deployment, reverse thrust and braking, then lets the
player taxi to one of ten selectable stands. Manual speed control uses W/S,
X brakes, and P toggles the parking brake; G enables optional automatic taxi.
Taxi steering follows the marked route. L starts a short final for quick trials.

## Scenery and performance scope

A fictional north apron adds gates A1–A10, terminal glazing, static jet bridges,
stand boundaries and stop bars. A curved runway exit joins a parallel taxiway
and a lead-in to every gate, staying north of 26R. Pavement, centerlines,
route highlights, and edge lights use shared mesh batches. The small audio
loop is generated locally, with no additional asset download.

These taxiways and gate names are original prototype scenery, not an airport
chart. Landing and taxi steering use an assisted deterministic controller,
not the separate Python flight model. No free flying, free ground steering,
airport traffic, ATC clearance, or animated jet-bridge docking is claimed.

## Supplied browser benchmark (previous build)

The user's report `miami-2026-09-11T07-21-56.json` recorded 6,192 frames in
103.50 seconds, averaging 59.83 FPS. Median, p95, and p99 frame times were
16.67 ms. Per-second FPS ranged from 41 to 60, while settings changed from
Low to High and between camera and lighting choices. This is a mixed-settings
short run of the previous build, not a controlled comparison or a benchmark
of this update. Browser counters do not measure total Mac RAM, and the report
does not identify the Mac model or installed memory.

## Validation

Godot import and full-scene smoke checks; deterministic arrival tests for all
ten gates including continuous flare position, runway rollout stopping,
main-wheel contact, reverse-on-ground, taxi speed limits, manual braking and
throttle, parking brakes, selected stand accuracy and restart. The browser
loader check validates the packaged scripts and decompresses/compiles the
actual engine WebAssembly. These checks do not establish browser appearance,
audio playback, or performance on the user's Mac; those need a browser run.
