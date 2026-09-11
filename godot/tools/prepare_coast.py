"""Clip Natural Earth's public-domain 1:10m land to Miami. Offline build tool.
Requires Shapely; runtime uses only the generated JSON. Input is the upstream
ne_10m_land.geojson. Coordinates in output are metres east / south of KMIA.
"""
import hashlib,json,math,sys
from pathlib import Path
from shapely.geometry import shape,box
from shapely.ops import unary_union,transform

source=Path(sys.argv[1])
output=Path(sys.argv[2])
origin_lat,origin_lon=25.796011,-80.289751
bounds=box(-80.90,25.25,-79.80,26.35)
polygons=[]
for feature in json.loads(source.read_text())['features']:
    geom=shape(feature['geometry']).intersection(bounds)
    if not geom.is_empty: polygons.append(geom)
land=unary_union(polygons)
land=transform(lambda lon,lat,z=None: ((lon-origin_lon)*111320*math.cos(math.radians(origin_lat)),-(lat-origin_lat)*111320),land)
land=land.simplify(8,preserve_topology=True)
rows=[]
for polygon in ([land] if land.geom_type=='Polygon' else land.geoms):
    if polygon.area<1000:continue
    rows.append({'outer':[[round(x,2),round(y,2)] for x,y in list(polygon.exterior.coords)[:-1]],'holes':[[[round(x,2),round(y,2)] for x,y in list(r.coords)[:-1]] for r in polygon.interiors]})
result={'source':'https://raw.githubusercontent.com/nvkelso/natural-earth-vector/master/geojson/ne_10m_land.geojson','source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'license':'Public domain; https://www.naturalearthdata.com/about/terms-of-use/','scale':'1:10 million (NOT 10 metre resolution)','simplification_metres':8,'origin':[origin_lat,origin_lon],'polygons':rows}
output.write_text(json.dumps(result,separators=(',',':'))+'\n')
print(len(rows),'polygons;',sum(len(p['outer']) for p in rows),'vertices;',sum(len(p['holes']) for p in rows),'holes;',output.stat().st_size,'bytes')
