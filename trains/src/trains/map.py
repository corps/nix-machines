"""Map model for the Empire Builders-style train game.

This module provides the main Map class that manages layers and renders to SVG.
It builds upon the existing GeoJSON loading and adds structured layer management.
"""

import os.path
from xml.etree.ElementTree import Element, ElementTree, SubElement, tostring

import geojson_pydantic
from geojson_pydantic import Feature, FeatureCollection, Polygon
from shapely import Geometry, box
from shapely.geometry import shape
from shapely.geometry.base import BaseGeometry
from shapely.geometry.collection import GeometryCollection
from shapely.geometry.point import Point

from .coords import BoundingBox, CoordinateSystem, HexCoord, HexGrid
from .data.geo import (
    canadata,
    get_all_na_countries,
    get_all_water_features,
    mexicodata,
    ne_50m_lakesdata,
    rivers_50_nadata,
    rivers_nadata,
    usdata,
)
from .layers import (
    AnyLayer,
    GeometryLayer,
    GeometryStyle,
    Layer,
    PositionalElementStyle,
    PositionalLayer,
    VisualLayer,
)


# Directory for data files
dir = os.path.dirname(os.path.abspath(__file__))


class Map:
    """Main map class that manages layers and renders to SVG.

    The Map class is the central container for all map data and rendering.
    It manages a collection of layers (visual, geometry, positional) and
    provides methods to render them to SVG.

    Attributes:
        layers: List of layers in z-index order (lower = bottom)
        coordinate_system: Coordinate system for transformations
        bounds: Bounding box of the map in pixel coordinates
        hex_grid: Hex grid for positional layers
    """

    def __init__(
        self,
        pixel_width: float = 800.0,
        pixel_height: float = 600.0,
        hex_grid: HexGrid = None,
    ):
        self.layers: list[AnyLayer] = []
        self.coordinate_system = CoordinateSystem(
            pixel_width=pixel_width,
            pixel_height=pixel_height,
            hex_grid=hex_grid or HexGrid(size=10.0, orientation="flat"),
        )
        self.hex_grid = hex_grid or HexGrid(size=10.0, orientation="flat")
        self.bounds = BoundingBox(0, 0, pixel_width, pixel_height)

        # Update coordinate system with hex grid
        self.coordinate_system.hex_grid = self.hex_grid

    def add_layer(self, layer: AnyLayer) -> None:
        """Add a layer to the map."""
        self.layers.append(layer)
        # Sort by z-index
        self.layers.sort(key=lambda l: l.z_index)

    def remove_layer(self, layer_id: str) -> bool:
        """Remove a layer by its ID."""
        for i, layer in enumerate(self.layers):
            if layer.layer_id == layer_id:
                del self.layers[i]
                return True
        return False

    def get_layer(self, layer_id: str) -> AnyLayer | None:
        """Get a layer by its ID."""
        for layer in self.layers:
            if layer.layer_id == layer_id:
                return layer
        return None

    def get_layers_by_type(self, layer_type: type) -> list[AnyLayer]:
        """Get all layers of a specific type."""
        return [layer for layer in self.layers if isinstance(layer, layer_type)]

    def render_to_svg(self) -> str:
        """Render the entire map to an SVG string.

        Returns:
            SVG XML string
        """
        # Create SVG root element
        svg_attrs = {
            "xmlns": "http://www.w3.org/2000/svg",
            "xmlns:xlink": "http://www.w3.org/1999/xlink",
            "width": str(self.bounds.width),
            "height": str(self.bounds.height),
            "viewBox": f"0 0 {self.bounds.width} {self.bounds.height}",
        }
        svg_root = Element("svg", svg_attrs)

        # Render layers in z-index order (bottom to top)
        for layer in self.layers:
            if layer.visible:
                layer.render_to_svg(svg_root, self.coordinate_system)

        # Convert to string
        return tostring(svg_root, encoding="unicode")

    def render_to_element(self) -> Element:
        """Render the entire map to an SVG Element.

        Returns:
            SVG ElementTree Element
        """
        svg_attrs = {
            "xmlns": "http://www.w3.org/2000/svg",
            "xmlns:xlink": "http://www.w3.org/1999/xlink",
            "width": str(self.bounds.width),
            "height": str(self.bounds.height),
            "viewBox": f"0 0 {self.bounds.width} {self.bounds.height}",
        }
        svg_root = Element("svg", svg_attrs)

        for layer in self.layers:
            if layer.visible:
                layer.render_to_svg(svg_root, self.coordinate_system)

        return svg_root

    def render_to_nicegui(self):
        """Render the map to a NiceGUI Html element."""
        from nicegui.elements.html import Html
        svg_string = self.render_to_svg()
        return Html(svg_string)

    def save_to_file(self, filepath: str) -> None:
        """Save the SVG to a file."""
        svg_content = self.render_to_svg()
        with open(filepath, "w") as f:
            f.write(svg_content)

    def add_geojson_layer(
        self,
        feature_collection: FeatureCollection[Feature[Polygon, dict]],
        layer_id: str,
        name: str = "",
        z_index: int = 0,
        style: GeometryStyle = None,
    ) -> GeometryLayer:
        """Convenience method to add a GeoJSON layer."""
        layer = GeometryLayer.from_geojson(
            feature_collection=feature_collection,
            layer_id=layer_id,
            name=name,
            z_index=z_index,
            style=style,
        )
        self.add_layer(layer)
        return layer

    def add_visual_layer(
        self,
        layer_id: str,
        color: str = None,
        image_path: str = None,
        render_type: str = "background",
        z_index: int = -1,  # Background layers typically at bottom
        name: str = "",
    ) -> VisualLayer:
        """Convenience method to add a visual layer."""
        layer = VisualLayer(
            layer_id=layer_id,
            name=name,
            z_index=z_index,
            color=color,
            image_path=image_path,
            render_type=render_type,
        )
        self.add_layer(layer)
        return layer

    def add_positional_layer(
        self,
        layer_id: str,
        hex_grid: HexGrid = None,
        z_index: int = 10,  # Positional layers typically on top
        name: str = "",
    ) -> PositionalLayer:
        """Convenience method to add a positional layer."""
        layer = PositionalLayer(
            layer_id=layer_id,
            name=name,
            z_index=z_index,
            hex_grid=hex_grid or self.hex_grid,
        )
        self.add_layer(layer)
        return layer


def create_sample_map() -> Map:
    """Create a sample map with North America data for demonstration."""
    # Create map
    map_obj = Map(pixel_width=1000, pixel_height=800)

    # Add background (ocean)
    map_obj.add_visual_layer(
        layer_id="ocean_background",
        color="#a8d8ea",
        render_type="background",
        z_index=-10,
        name="Ocean Background",
    )

    # Add land background
    map_obj.add_visual_layer(
        layer_id="land_background",
        color="#e8f5e9",
        render_type="background",
        z_index=-5,
        name="Land Background",
    )

    # Add North America countries (USA, Canada, Mexico)
    na_layer = map_obj.add_geojson_layer(
        feature_collection=get_all_na_countries(),
        layer_id="north_america",
        name="North America",
        z_index=0,
        style=GeometryStyle(
            stroke="#388e3c",
            stroke_width=1.0,
            fill="#8bc34a",
            fill_opacity=0.5,
        ),
    )

    # Add rivers
    rivers_layer = map_obj.add_geojson_layer(
        feature_collection=rivers_50_nadata,
        layer_id="rivers",
        name="Rivers",
        z_index=5,
        style=GeometryStyle(
            stroke="#1976d2",
            stroke_width=1.5,
            fill="none",
        ),
    )

    # Add lakes
    lakes_layer = map_obj.add_geojson_layer(
        feature_collection=ne_50m_lakesdata,
        layer_id="lakes",
        name="Lakes",
        z_index=5,
        style=GeometryStyle(
            stroke="#1976d2",
            stroke_width=1.0,
            fill="#90caf9",
            fill_opacity=0.5,
        ),
    )

    # Add positional layer for cities
    cities_layer = map_obj.add_positional_layer(
        layer_id="cities",
        z_index=20,
        name="Cities",
    )

    # Add some sample cities (these would normally come from data)
    # For now, add cities at approximate hex positions
    # These are placeholder coordinates - real implementation would use geo data
    cities_layer.add_element(
        hex_coord=HexCoord(0, 0),
        element_type="city",
        name="Chicago",
    )
    cities_layer.add_element(
        hex_coord=HexCoord(5, 2),
        element_type="city",
        name="New York",
    )
    cities_layer.add_element(
        hex_coord=HexCoord(-3, -2),
        element_type="city",
        name="Denver",
    )

    # Style cities
    cities_layer.styles_by_type["city"] = PositionalElementStyle(
        radius=8,
        fill="#f44336",
        stroke="#d32f2f",
        stroke_width=2,
        symbol="circle",
    )

    return map_obj


def create_hex_only_map() -> Map:
    """Create a simple hex-grid only map for testing."""
    map_obj = Map(pixel_width=800, pixel_height=600)

    # Use a larger hex grid with centered origin
    hex_grid = HexGrid(size=20, orientation="flat", origin=(400, 300))

    # Add background
    map_obj.add_visual_layer(
        layer_id="background",
        color="#f5f5f5",
        z_index=-1,
    )

    # Add hex grid positional layer
    hex_layer = map_obj.add_positional_layer(
        layer_id="hex_grid",
        hex_grid=hex_grid,
        z_index=0,
        name="Hex Grid",
    )

    # Style hexes
    hex_layer.default_style = PositionalElementStyle(
        symbol="hex",
        stroke="#9e9e9e",
        stroke_width=0.5,
        fill="none",
    )

    # Add hexes in a pattern
    for q in range(-5, 6):
        for r in range(-5, 6):
            hex_coord = HexCoord(q, r)
            hex_layer.add_element(
                hex_coord=hex_coord,
                element_type="hex",
            )

    # Add some cities
    cities_layer = map_obj.add_positional_layer(
        layer_id="cities",
        hex_grid=hex_grid,
        z_index=10,
        name="Cities",
    )

    cities_layer.add_element(
        hex_coord=HexCoord(0, 0),
        element_type="city",
        name="Central City",
    )
    cities_layer.add_element(
        hex_coord=HexCoord(3, -1),
        element_type="city",
        name="East City",
    )
    cities_layer.add_element(
        hex_coord=HexCoord(-2, 2),
        element_type="city",
        name="North City",
    )

    cities_layer.styles_by_type["city"] = PositionalElementStyle(
        radius=10,
        fill="#2196f3",
        stroke="#1976d2",
        stroke_width=2,
        symbol="circle",
    )

    return map_obj


def main():
    """Main function for testing map rendering."""
    # Create a sample map
    map_obj = create_hex_only_map()

    # Save to file
    map_obj.save_to_file("/tmp/train_map_test.svg")
    print("Sample map saved to /tmp/train_map_test.svg")

    # Also create one with North America
    na_map = create_sample_map()
    na_map.save_to_file("/tmp/train_map_na.svg")
    print("North America map saved to /tmp/train_map_na.svg")


if __name__ in {"__main__", "__mp_main__"}:
    main()
