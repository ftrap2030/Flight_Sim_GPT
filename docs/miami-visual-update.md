# Aircraft, cockpit and Miami visual update

This update implements priorities 2 and 4. The next sound milestone is deferred
until the user approves it; existing arrival audio is unchanged.

## Aircraft and cockpit

A lofted fuselage replaces the primitive cylinder/sphere assembly, with a shaped
nose and tapering tail. Procedural cabin windows have rounded edges and frames;
doors have panel seams. Separate cockpit panes, closed-section swept wings,
inlet lips, engine pylons, flap-track fairings, navigation lamps and rotating
main wheels improve exterior detail. The nose wheels steer during guided taxi.
Flaps, spoilers and reverser sleeves retain their arrival animation.

Textured cockpit panels add fasteners, wipers, panel legends and gear indication.
The glare-shield readouts now track actual demonstration speed, heading and
altitude. Pitch and radio-height indicators follow the arrival; engine needles
follow the displayed values. On the ground, the navigation display switches to
a route map with the selected gate and aircraft position. Heading direction was
corrected to match the northward taxi turn. No independent avionics simulation
or clickable cockpit systems are claimed.

## Miami

A regional Natural Earth land extract replaces the old procedural coast.
It uses 107 boundary vertices in four polygons, around 2.6 KB of JSON. The
upstream dataset is at 1:10 million map scale; `10m` does not mean ten-metre
accuracy. Shallow-water bands, an ocean-side sand strip, and an original port
island supplement the generalized coastline. Buildings are filtered to land.

Pavement shaders add concrete joints, asphalt seams, grain and runway touchdown
rubber. Gate-area detail includes taxiway signs, window mullions, rooftop units,
static service vehicles, light poles and instanced palms. Original simplified
studies of Freedom Tower and One Thousand Museum, a Brickell tower cluster and
causeway/port adjustments improve the regional silhouette. Gates, terminals,
landmark dimensions and placement remain approximate.

Data and architectural references are recorded in `godot/THIRD_PARTY_NOTICES.md`.
`godot/tools/prepare_coast.py` reproduces the bundled region from the upstream
GeoJSON and records its SHA-256. The build tool needs Shapely; the game does not.
No purchased assets, streamed satellite imagery or new runtime service is used.

## Validation and limits

Godot import and full-scene checks cover cameras, presets, pause/restart,
benchmarks, coast containment at KMIA, visual-shader resource parsing and
cockpit state at the gate. The existing deterministic tests check all ten
arrival/taxi routes. The browser export is checked for HTML/JS syntax, file
references, actual gzip loading and WebAssembly compilation.

These are automated code/export checks. Browser visual appearance and target-Mac
performance have not been measured for this build. This remains a procedural
prototype, not a photorealistic or surveyed digital reconstruction.
