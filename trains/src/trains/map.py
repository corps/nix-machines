import math
import os.path
from xml.etree.ElementTree import Element, ElementTree, SubElement, tostring

import geojson_pydantic
import shapely.geometry
from attr import dataclass
from geojson_pydantic import Feature, FeatureCollection, Polygon
from mypyc.crash import contextmanager
from nicegui import ui
from nicegui.elements.html import Html
from shapely import Geometry, box
from shapely.geometry import shape
from shapely.geometry.base import BaseGeometry
from shapely.geometry.collection import GeometryCollection
from shapely.geometry.point import Point

dir = os.path.dirname(os.path.abspath(__file__))
usdata: FeatureCollection[Feature[Polygon, dict]] = (
    geojson_pydantic.FeatureCollection.model_validate_json(
        open(os.path.join(dir, "usa.json")).read()
    )
)
canadata: FeatureCollection[Feature[Polygon, dict]] = (
    geojson_pydantic.FeatureCollection.model_validate_json(
        open(os.path.join(dir, "canada.json")).read()
    )
)
mexicodata: FeatureCollection[Feature[Polygon, dict]] = (
    geojson_pydantic.FeatureCollection.model_validate_json(
        open(os.path.join(dir, "mexico.json")).read()
    )
)
rivers_nadata: FeatureCollection[Feature[Polygon, dict]] = (
    geojson_pydantic.FeatureCollection.model_validate_json(
        open(os.path.join(dir, "rivers_na.json")).read()
    )
)
rivers_50_nadata: FeatureCollection[Feature[Polygon, dict]] = (
    geojson_pydantic.FeatureCollection.model_validate_json(
        open(os.path.join(dir, "rivers_50_na.json")).read()
    )
)
ne_50m_lakesdata: FeatureCollection[Feature[Polygon, dict]] = (
    geojson_pydantic.FeatureCollection.model_validate_json(
        open(os.path.join(dir, "ne_50m_lakes.json")).read()
    )
)

continental_bbox = box(-125, 24, -66, 49)
continental = FeatureCollection(type="FeatureCollection", features=[])

for feature in usdata.features:
    s = shape(feature.geometry)
    if continental_bbox.overlaps(s):
        continental.features.append(feature)

for feature in canadata.features:
    s = shape(feature.geometry)
    if continental_bbox.overlaps(s):
        continental.features.append(feature)

for feature in mexicodata.features:
    s = shape(feature.geometry)
    if continental_bbox.overlaps(s):
        continental.features.append(feature)


@dataclass
class Map:
    land: GeometryCollection
    rivers: GeometryCollection
    lakes: GeometryCollection

    @property
    def width(self):
        return math.ceil(self.land.bounds[2] - self.land.bounds[0])

    @property
    def height(self):
        return math.ceil(self.land.bounds[3] - self.land.bounds[1])


def triangle_coord(x, y):
    px = x
    py = y * math.sin(math.pi / 3)
    if y % 2 == 1:
        px += math.cos(math.pi / 3)
    return px, py


_stack: list[Element] = []


@contextmanager
def parent(p: Element):
    _stack.append(p)
    try:
        yield p
    finally:
        _stack.pop()


def cur() -> Element:
    return _stack[-1]


def miller_projection(x: int, y: int):
    lon_rad = math.radians(x)
    lat_rad = math.radians(y)
    x = lon_rad
    y = 1.25 * math.log(math.tan(math.pi / 4 + 0.4 * lat_rad))
    return math.degrees(x), math.degrees(y)


def render_geometry(feature: BaseGeometry, fill: str):
    if isinstance(feature, shapely.geometry.Polygon):
        result = SubElement(
            cur(),
            "polygon",
            points=" ".join(
                ",".join(str(s) for s in miller_projection(*pair))
                for ring in [feature.exterior]
                for pair in ring.coords
            ),
            fill=fill,
            stroke="black",
            stroke_width="1",
        )
        result.set("vector-effect", "non-scaling-stroke")
        return result
    elif isinstance(feature, shapely.geometry.LineString):
        result = SubElement(
            cur(),
            "polyline",
            points=" ".join(
                ",".join(str(s) for s in miller_projection(*pair))
                for pair in feature.coords
            ),
            stroke=fill,
            fill="none",
        )
        result.set("vector-effect", "non-scaling-stroke")
        return result
    elif isinstance(feature, shapely.geometry.MultiLineString):
        with parent(SubElement(cur(), "g")) as group:
            for geom in feature.geoms:
                render_geometry(geom, fill)
        return group
    assert False, type(feature)


def transform(name: str, *args: any):
    return f"{name}({' '.join(str(s) for s in args)})"


def render_map(grid: Html, map: Map, scale: int):
    with parent(
        Element("svg", xmlns="http://www.w3.org/2000/svg", version="1.1")
    ) as svg:
        svg.set("height", str(int(map.height * scale)))
        svg.set("width", str(int(map.width * scale)))
        SubElement(cur(), "rect", width="100%", height="100%", fill="lightblue")

        with parent(
            SubElement(
                cur(),
                "g",
                transform=" ".join(
                    [
                        transform("scale", -scale, scale),
                        transform("rotate", 180, map.width / 2, map.height / 2),
                        transform(
                            "translate",
                            -map.land.bounds[0] + map.width,
                            -map.land.bounds[1],
                        ),
                    ]
                ),
            )
        ):
            for x in range(int(map.land.bounds[0]), int(map.land.bounds[2])):
                for y in range(int(map.land.bounds[1]), int(map.land.bounds[3])):
                    cx, cy = triangle_coord(x, y)
                    for coll in []:
                        if coll.overlaps(Point(cx, cy)):
                            break
                    else:
                        # if map.land.overlaps(Point(cx, cy)):
                        circle = SubElement(
                            cur(),
                            "circle",
                            r="0.1",
                            cx=str(cx),
                            cy=str(cy),
                            fill="none",
                            stroke="black",
                            stroke_width="1",
                        )
                        circle.set("vector-effect", "non-scaling-stroke")
            for geom in map.land.geoms:
                render_geometry(geom, "white")
            for geom in map.rivers.geoms:
                render_geometry(geom, "blue")
            for geom in map.lakes.geoms:
                render_geometry(geom, "blue")

    grid.set_content(tostring(svg, encoding="unicode"))


def create_maps() -> dict[str, Map]:
    return dict(
        USA=create_us_map(),
    )


def create_us_map() -> Map:
    land = GeometryCollection(
        [shape(f.geometry) for f in continental.features if shape(f.geometry)]
    )
    rivers = GeometryCollection(
        [
            s
            for ds in [rivers_50_nadata]
            for f in ds.features
            if f.geometry
            for s in (shape(f.geometry),)
            if land.contains(s)
        ]
    )
    lakes = GeometryCollection(
        [
            s
            for ds in [ne_50m_lakesdata]
            for f in ds.features
            if f.geometry
            for s in (shape(f.geometry),)
            if land.contains(s) and s.area > 0.3
        ]
    )

    return Map(land=land, rivers=rivers, lakes=lakes)


if __name__ in {"__main__", "__mp_main__"}:
    render_map(ui.html(), create_us_map(), 10)
    ui.run()
