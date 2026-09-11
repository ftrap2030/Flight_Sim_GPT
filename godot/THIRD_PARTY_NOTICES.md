# Asset provenance

| Asset | Source | Terms / scope |
| --- | --- | --- |
| Godot Engine 4.5.1 | https://godotengine.org/ | MIT license; https://godotengine.org/license/ |
| KMIA runway endpoints, widths and identifiers | https://github.com/davidmegginson/ourairports-data/blob/main/runways.csv | Public domain; https://ourairports.com/data/ |
| Airport reference location | https://ourairports.com/airports/KMIA/ | OurAirports public-domain data |
| Cockpit, aircraft exterior, buildings, airport proxies, port island, cranes and bridges | Procedurally authored for Flight Sim GPT | Original project assets; no third-party model included |
| Water, ground, facade and cloud shaders | Authored for Flight Sim GPT | Original project code; no third-party shader package included |
| Instrument graphics and interface | Authored for Flight Sim GPT using Godot's bundled default font | Font distributed as part of Godot; see the engine's third-party notices |

The snapshot records its retrieval date and the SHA-256 of the downloaded
source CSV. OurAirports does not guarantee the accuracy of its data. No aerial
imagery or commercial simulator scenery has been included. No Airbus logo,
airline logo, or third-party livery is included. The aircraft is an approximate
A320neo-inspired visual study and has no affiliation with Airbus.

Godot's engine and bundled dependency notices are available in the official
[license information](https://godotengine.org/license/) and
[COPYRIGHT.txt](https://github.com/godotengine/godot/blob/4.5.1-stable/COPYRIGHT.txt).

## Regional shoreline

Made with Natural Earth. `data/miami_coast.json` is a clipped and simplified
regional extract of the public-domain Natural Earth 1:10 million land dataset:
https://www.naturalearthdata.com/downloads/10m-physical-vectors/10m-land/
https://www.naturalearthdata.com/about/terms-of-use/
The JSON records the source URL and SHA-256. `tools/prepare_coast.py` reproduces
the extract. The dataset name `10m` means a 1:10 million map scale, **not**
10-metre geographic precision. The port island is an original approximation.

## Landmark studies

Freedom Tower and One Thousand Museum are original simplified meshes; no
third-party 3D model or photograph is embedded. Architectural references:
https://artsandculture.google.com/story/miami-dade-college-s-freedom-tower-miami-dade-college/kwVxAe_ymWauLQ?hl=en
https://freedomtower.mdc.edu/visit/directions-and-parking/
https://1000museum.com/
Port setting: https://www.miamidade.gov/portmiami/directions-transportation.page
Locations, dimensions and silhouettes are approximate artistic studies.
