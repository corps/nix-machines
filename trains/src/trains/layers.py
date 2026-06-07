"""Layer classes for the train game map.

This module provides:
- Layer: Abstract base class for all layers
- VisualLayer: Aesthetic layers (backgrounds, overlays, logos)
- GeometryLayer: Boundary geometry layers (rivers, lakes, political boundaries)
- PositionalLayer: Hex-grid based positional elements (cities, stations, tracks)
- Style classes for rendering
"""

import math
from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from typing import Any, Dict, List, Optional, Tuple, Union
from xml.etree.ElementTree import Element, SubElement, tostring

import geojson_pydantic
from geojson_pydantic import Feature, FeatureCollection, Polygon
from shapely import Geometry, box
from shapely.geometry import MultiPolygon, Point, Polygon as ShapelyPolygon, shape
from shapely.geometry.base import BaseGeometry
from shapely.geometry.collection import GeometryCollection

from .coords import BoundingBox, CoordinateSystem, HexCoord, HexGrid


@dataclass
class Style:
    """Base style class for layer rendering."""
    stroke: str = "black"
    stroke_width: float = 1.0
    fill: Optional[str] = None
    fill_opacity: float = 1.0
    opacity: float = 1.0


@dataclass
class VisualStyle(Style):
    """Style for visual layers."""
    background_color: Optional[str] = None
    background_image: Optional[str] = None
    background_pattern: Optional[str] = None


@dataclass
class GeometryStyle(Style):
    """Style for geometry layers."""
    stroke_dasharray: Optional[str] = None
    stroke_linecap: str = "butt"
    stroke_linejoin: str = "miter"


@dataclass
class PositionalElementStyle(Style):
    """Style for positional elements."""
    radius: float = 5.0
    symbol: str = "circle"  # circle, square, diamond, etc.


@dataclass
class Layer(ABC):
    """Abstract base class for all map layers.

    All layers support:
    - Unique identifier
    - Display name
    - Z-index for stacking order
    - Visibility toggle
    - Opacity control
    - SVG rendering
    """
    layer_id: str
    name: str = ""
    z_index: int = 0
    visible: bool = True
    opacity: float = 1.0

    @abstractmethod
    def render_to_svg(self, svg_root: Element, coordinate_system: CoordinateSystem) -> Element:
        """Render this layer to an SVG group element.

        Args:
            svg_root: The root SVG element to add to
            coordinate_system: The coordinate system for transformations

        Returns:
            An SVG <g> element containing the layer's content
        """
        pass

    def get_svg_group(self, svg_root: Element) -> Element:
        """Create an SVG group element with layer attributes."""
        attrs = {
            "id": self.layer_id,
            "class": f"layer layer-{self.layer_id}",
        }
        if not self.visible:
            attrs["display"] = "none"
        if self.opacity != 1.0:
            attrs["opacity"] = str(self.opacity)

        return SubElement(svg_root, "g", attrs)


@dataclass
class VisualLayer(Layer):
    """A layer for purely aesthetic elements (backgrounds, overlays, logos).

    Visual layers can be:
    - Background: Solid color, texture, or image covering the entire map
    - Overlay: Logo, design element, or decorative graphics
    """
    render_type: str = "background"  # "background" or "overlay"
    color: Optional[str] = None
    image_path: Optional[str] = None
    bounds: Optional[BoundingBox] = None

    def __post_init__(self):
        if self.render_type not in ("background", "overlay"):
            raise ValueError(f"render_type must be 'background' or 'overlay', got {self.render_type}")

    def render_to_svg(self, svg_root: Element, coordinate_system: CoordinateSystem) -> Element:
        """Render the visual layer as an SVG rectangle or image."""
        group = self.get_svg_group(svg_root)

        if self.image_path:
            self._render_image(group, coordinate_system)
        elif self.color:
            self._render_color(group, coordinate_system)

        return group

    def _render_color(self, group: Element, coordinate_system: CoordinateSystem) -> None:
        """Render a solid color background."""
        width = coordinate_system.pixel_width
        height = coordinate_system.pixel_height

        if self.bounds:
            width = self.bounds.width
            height = self.bounds.height

        SubElement(group, "rect", {
            "x": "0",
            "y": "0",
            "width": str(width),
            "height": str(height),
            "fill": self.color,
        })

    def _render_image(self, group: Element, coordinate_system: CoordinateSystem) -> None:
        """Render an image background or overlay."""
        width = coordinate_system.pixel_width
        height = coordinate_system.pixel_height

        if self.bounds:
            width = self.bounds.width
            height = self.bounds.height

        SubElement(group, "image", {
            "x": "0",
            "y": "0",
            "width": str(width),
            "height": str(height),
            "xlink:href": self.image_path,
            "preserveAspectRatio": "none" if self.render_type == "background" else "xMidYMid",
        })


@dataclass
class GeometryLayer(Layer):
    """A layer for boundary geometries (rivers, lakes, political boundaries).

    Geometry layers contain GeoJSON features that are rendered as SVG paths.
    They represent functional boundaries that may affect game rules.
    """
    features: List[Feature[Polygon, dict]] = field(default_factory=list)
    geometry: Optional[GeometryCollection] = None
    style: GeometryStyle = field(default_factory=GeometryStyle)

    # For constructing from GeoJSON
    @classmethod
    def from_geojson(
        cls,
        feature_collection: FeatureCollection[Feature[Polygon, dict]],
        layer_id: str,
        name: str = "",
        z_index: int = 0,
        style: Optional[GeometryStyle] = None,
    ) -> 'GeometryLayer':
        """Create a GeometryLayer from a GeoJSON FeatureCollection."""
        features = feature_collection.features

        # Create combined geometry
        shapes = []
        for feature in features:
            if feature.geometry:
                shapes.append(shape(feature.geometry))

        geometry = GeometryCollection(shapes) if shapes else None

        return cls(
            layer_id=layer_id,
            name=name or f"Geometry_{layer_id}",
            z_index=z_index,
            features=features,
            geometry=geometry,
            style=style or GeometryStyle(stroke="blue", stroke_width=1.0, fill="none"),
        )

    def add_feature(self, feature: Feature[Polygon, dict]) -> None:
        """Add a GeoJSON feature to this layer."""
        self.features.append(feature)

        # Update combined geometry
        if feature.geometry:
            new_shape = shape(feature.geometry)
            if self.geometry:
                self.geometry = GeometryCollection(
                    list(self.geometry.geoms) + [new_shape]
                )
            else:
                self.geometry = GeometryCollection([new_shape])

    def render_to_svg(self, svg_root: Element, coordinate_system: CoordinateSystem) -> Element:
        """Render geometry features as SVG paths."""
        group = self.get_svg_group(svg_root)

        if not self.features and not self.geometry:
            return group

        # Render each feature as a path
        for feature in self.features:
            self._render_feature(group, feature, coordinate_system)

        return group

    def _render_feature(
        self,
        group: Element,
        feature: Feature[Polygon, dict],
        coordinate_system: CoordinateSystem,
    ) -> None:
        """Render a single GeoJSON feature as SVG path elements."""
        if not feature.geometry:
            return

        geom = shape(feature.geometry)
        self._render_geometry(group, geom, coordinate_system)

    def _render_geometry(
        self,
        group: Element,
        geometry: BaseGeometry,
        coordinate_system: CoordinateSystem,
    ) -> None:
        """Render a shapely geometry as SVG path elements."""
        if geometry.geom_type == "Polygon":
            self._render_polygon(group, geometry, coordinate_system)
        elif geometry.geom_type == "MultiPolygon":
            for poly in geometry.geoms:
                self._render_polygon(group, poly, coordinate_system)
        elif geometry.geom_type == "GeometryCollection":
            for geom in geometry.geoms:
                self._render_geometry(group, geom, coordinate_system)
        elif geometry.geom_type == "LineString":
            self._render_linestring(group, geometry, coordinate_system)
        elif geometry.geom_type == "MultiLineString":
            for line in geometry.geoms:
                self._render_linestring(group, line, coordinate_system)
        elif geometry.geom_type == "Point":
            self._render_point(group, geometry, coordinate_system)
        elif geometry.geom_type == "MultiPoint":
            for point in geometry.geoms:
                self._render_point(group, point, coordinate_system)

    def _render_polygon(
        self,
        group: Element,
        polygon: ShapelyPolygon,
        coordinate_system: CoordinateSystem,
    ) -> None:
        """Render a polygon as an SVG path element."""
        # Get exterior and interior rings
        exterior = polygon.exterior.coords[:]
        interiors = [ring.coords[:] for ring in polygon.interiors]

        # Build path data
        path_data = []

        # Exterior ring
        if exterior:
            path_data.append(self._points_to_svg_path(exterior, coordinate_system, close=True))

        # Interior rings (holes)
        for interior in interiors:
            if interior:
                path_data.append(self._points_to_svg_path(interior, coordinate_system, close=True))

        if not path_data:
            return

        # Combine into single path with move commands
        full_path = " ".join(path_data)

        attrs = {
            "d": full_path,
            "fill": self.style.fill or "none",
            "fill-opacity": str(self.style.fill_opacity),
            "stroke": self.style.stroke,
            "stroke-width": str(self.style.stroke_width),
        }

        if self.style.stroke_dasharray:
            attrs["stroke-dasharray"] = self.style.stroke_dasharray
        attrs["stroke-linecap"] = self.style.stroke_linecap
        attrs["stroke-linejoin"] = self.style.stroke_linejoin

        SubElement(group, "path", attrs)

    def _render_linestring(
        self,
        group: Element,
        linestring: Any,
        coordinate_system: CoordinateSystem,
    ) -> None:
        """Render a line string as an SVG path element."""
        coords = list(linestring.coords)
        if len(coords) < 2:
            return

        path_data = self._points_to_svg_path(coords, coordinate_system, close=False)

        attrs = {
            "d": path_data,
            "fill": "none",
            "stroke": self.style.stroke,
            "stroke-width": str(self.style.stroke_width),
        }

        if self.style.stroke_dasharray:
            attrs["stroke-dasharray"] = self.style.stroke_dasharray
        attrs["stroke-linecap"] = self.style.stroke_linecap
        attrs["stroke-linejoin"] = self.style.stroke_linejoin

        SubElement(group, "path", attrs)

    def _render_point(
        self,
        group: Element,
        point: Point,
        coordinate_system: CoordinateSystem,
    ) -> None:
        """Render a point as an SVG circle."""
        pixel = coordinate_system.geo_to_pixel(point.x, point.y)

        SubElement(group, "circle", {
            "cx": str(pixel.x),
            "cy": str(pixel.y),
            "r": str(self.style.stroke_width * 2),
            "fill": self.style.stroke,
        })

    def _points_to_svg_path(
        self,
        points: List[Tuple[float, float]],
        coordinate_system: CoordinateSystem,
        close: bool = True,
    ) -> str:
        """Convert a list of (lon, lat) points to SVG path data with coordinate transformation."""
        if not points:
            return ""

        # Convert all points to pixel coordinates
        pixel_points = []
        for lon, lat in points:
            pixel = coordinate_system.geo_to_pixel(lon, lat)
            pixel_points.append((pixel.x, pixel.y))

        # First point is M (move to)
        x, y = pixel_points[0]
        path_parts = [f"M {x} {y}"]

        # Remaining points are L (line to)
        for x, y in pixel_points[1:]:
            path_parts.append(f"L {x} {y}")

        if close and len(pixel_points) > 1:
            path_parts.append("Z")

        return " ".join(path_parts)


@dataclass
class PositionalElement:
    """An element positioned on the hex grid.

    Positional elements can represent:
    - Cities
    - Stations
    - Track pieces
    - Terrain types
    - Any other game element positioned on hexes
    """
    hex_coord: HexCoord
    element_type: str = "generic"
    name: str = ""
    properties: Dict[str, Any] = field(default_factory=dict)
    style: PositionalElementStyle = field(default_factory=PositionalElementStyle)


@dataclass
class PositionalLayer(Layer):
    """A layer for elements positioned on the hex grid.

    Positional layers contain elements placed at specific hex coordinates.
    They represent game pieces, cities, tracks, and other positional features.
    """
    hex_grid: HexGrid = field(default_factory=HexGrid)
    elements: Dict[HexCoord, PositionalElement] = field(default_factory=dict)
    default_style: PositionalElementStyle = field(default_factory=PositionalElementStyle)
    styles_by_type: Dict[str, PositionalElementStyle] = field(default_factory=dict)

    def add_element(
        self,
        hex_coord: HexCoord,
        element_type: str = "generic",
        name: str = "",
        properties: Optional[Dict[str, Any]] = None,
        style: Optional[PositionalElementStyle] = None,
    ) -> PositionalElement:
        """Add a positional element at a hex coordinate."""
        element = PositionalElement(
            hex_coord=hex_coord,
            element_type=element_type,
            name=name,
            properties=properties or {},
            style=style or self.styles_by_type.get(element_type, self.default_style),
        )
        self.elements[hex_coord] = element
        return element

    def get_element(self, hex_coord: HexCoord) -> Optional[PositionalElement]:
        """Get the element at a hex coordinate, if any."""
        return self.elements.get(hex_coord)

    def remove_element(self, hex_coord: HexCoord) -> bool:
        """Remove the element at a hex coordinate."""
        if hex_coord in self.elements:
            del self.elements[hex_coord]
            return True
        return False

    def render_to_svg(self, svg_root: Element, coordinate_system: CoordinateSystem) -> Element:
        """Render positional elements as SVG elements."""
        group = self.get_svg_group(svg_root)

        for element in self.elements.values():
            self._render_element(group, element, coordinate_system)

        return group

    def _render_element(
        self,
        group: Element,
        element: PositionalElement,
        coordinate_system: CoordinateSystem,
    ) -> None:
        """Render a single positional element."""
        # Get the pixel position
        pixel = self.hex_grid.hex_to_pixel(element.hex_coord)
        style = element.style

        # Use per-type style if available
        if element.element_type in self.styles_by_type:
            style = self.styles_by_type[element.element_type]

        if style.symbol == "circle":
            SubElement(group, "circle", {
                "cx": str(pixel.x),
                "cy": str(pixel.y),
                "r": str(style.radius),
                "fill": style.fill or style.stroke,
                "stroke": style.stroke,
                "stroke-width": str(style.stroke_width),
                "opacity": str(style.opacity),
            })
        elif style.symbol == "square":
            half = style.radius
            SubElement(group, "rect", {
                "x": str(pixel.x - half),
                "y": str(pixel.y - half),
                "width": str(style.radius * 2),
                "height": str(style.radius * 2),
                "fill": style.fill or style.stroke,
                "stroke": style.stroke,
                "stroke-width": str(style.stroke_width),
                "opacity": str(style.opacity),
            })
        elif style.symbol == "diamond":
            # Diamond (rotated square)
            points = [
                (pixel.x, pixel.y - style.radius),
                (pixel.x + style.radius, pixel.y),
                (pixel.x, pixel.y + style.radius),
                (pixel.x - style.radius, pixel.y),
            ]
            SubElement(group, "polygon", {
                "points": ",".join(f"{x},{y}" for x, y in points),
                "fill": style.fill or style.stroke,
                "stroke": style.stroke,
                "stroke-width": str(style.stroke_width),
                "opacity": str(style.opacity),
            })
        elif style.symbol == "hex":
            # Hexagon
            corners = self.hex_grid.hex_to_pixel_polygon(element.hex_coord)
            SubElement(group, "polygon", {
                "points": ",".join(f"{x},{y}" for x, y in corners),
                "fill": style.fill or style.stroke,
                "stroke": style.stroke,
                "stroke-width": str(style.stroke_width),
                "opacity": str(style.opacity),
            })
        else:
            # Default: circle
            SubElement(group, "circle", {
                "cx": str(pixel.x),
                "cy": str(pixel.y),
                "r": str(style.radius),
                "fill": style.fill or style.stroke,
                "stroke": style.stroke,
                "stroke-width": str(style.stroke_width),
                "opacity": str(style.opacity),
            })


# Type alias for layer union
AnyLayer = Union[Layer, VisualLayer, GeometryLayer, PositionalLayer]
