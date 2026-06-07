"""Coordinate systems and transformations for the train game map.

This module provides:
- HexCoord: Axial coordinate system for hex grids (q, r)
- HexGrid: Hex grid with orientation and size
- CoordinateSystem: Transformations between coordinate spaces
- Transformation utilities for geo <-> pixel <-> hex
"""

import math
from dataclasses import dataclass, field
from typing import Tuple

from shapely.geometry.point import Point


# Hex direction vectors for axial coordinates (q, r)
# In axial coordinates, the 6 neighbors are:
HEX_DIRECTIONS = [
    (+1, 0),   # E
    (+1, -1),  # NE
    (0, -1),   # NW
    (-1, 0),   # W
    (-1, +1),  # SW
    (0, +1),   # SE
]


@dataclass(frozen=True)
class HexCoord:
    """Axial hex coordinate using q and r axes.

    In axial coordinates, the third coordinate s is derived: s = -q - r
    This satisfies q + r + s = 0 (cube coordinates constraint).

    Attributes:
        q: The q coordinate (column-like)
        r: The r coordinate (row-like)
    """
    q: int
    r: int

    @property
    def s(self) -> int:
        """Derived s coordinate for cube coordinate system."""
        return -self.q - self.r

    def __add__(self, other: 'HexCoord') -> 'HexCoord':
        return HexCoord(self.q + other.q, self.r + other.r)

    def __sub__(self, other: 'HexCoord') -> 'HexCoord':
        return HexCoord(self.q - other.q, self.r - other.r)

    def __mul__(self, scalar: int) -> 'HexCoord':
        return HexCoord(self.q * scalar, self.r * scalar)

    def neighbor(self, direction: int) -> 'HexCoord':
        """Get the neighboring hex in the given direction (0-5)."""
        if not 0 <= direction < 6:
            raise ValueError(f"Direction must be 0-5, got {direction}")
        dq, dr = HEX_DIRECTIONS[direction]
        return HexCoord(self.q + dq, self.r + dr)

    def distance_to(self, other: 'HexCoord') -> int:
        """Calculate hex distance to another coordinate.

        In axial coordinates: (|q1-q2| + |q1+r1 - q2-r2| + |r1-r2|) / 2
        Or equivalently: (|q1-q2| + |r1-r2| + |s1-s2|) / 2
        """
        dq = abs(self.q - other.q)
        dr = abs(self.r - other.r)
        ds = abs(self.s - other.s)
        return (dq + dr + ds) // 2

    def ring(self, radius: int) -> list['HexCoord']:
        """Get all hex coordinates in a ring of given radius."""
        if radius < 0:
            return []
        if radius == 0:
            return [self]

        results = []
        var = HexCoord(self.q + radius, self.r)
        for i in range(6):
            for _ in range(radius):
                results.append(var)
                var = var.neighbor(i)
        return results

    def spiral(self, radius: int) -> list['HexCoord']:
        """Get all hex coordinates in a spiral from center to radius."""
        results = [self]
        for r in range(1, radius + 1):
            results.extend(self.ring(r))
        return results

    def to_tuple(self) -> Tuple[int, int]:
        """Convert to tuple representation."""
        return (self.q, self.r)

    @classmethod
    def from_tuple(cls, coords: Tuple[int, int]) -> 'HexCoord':
        """Create from tuple representation."""
        return cls(coords[0], coords[1])

    def __hash__(self) -> int:
        return hash((self.q, self.r))

    def __eq__(self, other: object) -> bool:
        if not isinstance(other, HexCoord):
            return False
        return self.q == other.q and self.r == other.r


@dataclass
class HexGrid:
    """Hex grid definition with orientation and rendering parameters.

    The hex grid supports two orientations:
    - "flat": Flat-topped hexes (horizontal top edge)
    - "pointy": Pointy-topped hexes (vertical top edge)

    Attributes:
        size: Side length of each hex in pixels
        orientation: Either "flat" or "pointy"
        origin: Pixel origin point (0, 0) of the grid
    """
    size: float = 10.0
    orientation: str = "flat"  # or "pointy"
    origin: Tuple[float, float] = (0.0, 0.0)

    def __post_init__(self):
        if self.orientation not in ("flat", "pointy"):
            raise ValueError(f"Orientation must be 'flat' or 'pointy', got {self.orientation}")

    @property
    def height(self) -> float:
        """Height of a hex in pixels."""
        return self.size * 2

    @property
    def width(self) -> float:
        """Width of a hex in pixels."""
        return self.size * math.sqrt(3) * 2

    @property
    def horizontal_spacing(self) -> float:
        """Horizontal distance between adjacent hex centers."""
        return self.size * math.sqrt(3) * 1.5

    @property
    def vertical_spacing(self) -> float:
        """Vertical distance between adjacent hex centers."""
        return self.size * 1.5

    def hex_to_pixel(self, hex_coord: HexCoord) -> Point:
        """Convert hex axial coordinates to pixel coordinates.

        For flat-topped hexes:
        - x = size * sqrt(3) * (q + r/2) + origin_x
        - y = size * 3/2 * r + origin_y

        For pointy-topped hexes:
        - x = size * sqrt(3) * q + origin_x
        - y = size * 3/2 * (r + q/2) + origin_y
        """
        if self.orientation == "flat":
            x = self.origin[0] + self.size * math.sqrt(3) * (hex_coord.q + hex_coord.r / 2)
            y = self.origin[1] + self.size * 1.5 * hex_coord.r
        else:  # pointy
            x = self.origin[0] + self.size * math.sqrt(3) * hex_coord.q
            y = self.origin[1] + self.size * 1.5 * (hex_coord.r + hex_coord.q / 2)

        return Point(x, y)

    def pixel_to_hex(self, point: Point) -> HexCoord:
        """Convert pixel coordinates to hex axial coordinates.

        This is the inverse of hex_to_pixel.
        """
        x = point.x - self.origin[0]
        y = point.y - self.origin[1]

        if self.orientation == "flat":
            q = (x * 2 / (self.size * math.sqrt(3)) - y / (self.size * 1.5)) / 1.5
            r = y / (self.size * 1.5)
        else:  # pointy
            q = x / (self.size * math.sqrt(3))
            r = (y / (self.size * 1.5) - q / 2) * 2

        # Round to nearest hex
        q_rounded = round(q)
        r_rounded = round(r)
        s_rounded = round(-q - r)

        # Convert back to axial and find the best fit
        # This handles the rounding errors in the conversion
        q_floor = int(math.floor(q + 0.5))
        r_floor = int(math.floor(r + 0.5))

        return HexCoord(q_floor, r_floor)

    def hex_to_pixel_polygon(self, hex_coord: HexCoord) -> list[Tuple[float, float]]:
        """Get the 6 corner points of a hex in pixel coordinates.

        Returns a list of (x, y) tuples for the polygon vertices.
        """
        center = self.hex_to_pixel(hex_coord)
        corners = []

        for i in range(6):
            angle = 2 * math.pi * i / 6
            if self.orientation == "flat":
                # Flat-topped: rotate by 30 degrees
                angle += math.pi / 6

            x = center.x + self.size * math.cos(angle)
            y = center.y + self.size * math.sin(angle)
            corners.append((x, y))

        return corners


@dataclass
class BoundingBox:
    """Axis-aligned bounding box in pixel coordinates."""
    min_x: float
    min_y: float
    max_x: float
    max_y: float

    @property
    def width(self) -> float:
        return self.max_x - self.min_x

    @property
    def height(self) -> float:
        return self.max_y - self.min_y

    @property
    def center(self) -> Point:
        return Point((self.min_x + self.max_x) / 2, (self.min_y + self.max_y) / 2)

    def contains(self, point: Point) -> bool:
        return (self.min_x <= point.x <= self.max_x and
                self.min_y <= point.y <= self.max_y)

    def to_tuple(self) -> Tuple[float, float, float, float]:
        return (self.min_x, self.min_y, self.max_x, self.max_y)

    @classmethod
    def from_points(cls, points: list[Point]) -> 'BoundingBox':
        """Create a bounding box from a list of points."""
        if not points:
            raise ValueError("Cannot create BoundingBox from empty list")

        min_x = min(p.x for p in points)
        min_y = min(p.y for p in points)
        max_x = max(p.x for p in points)
        max_y = max(p.y for p in points)

        return cls(min_x, min_y, max_x, max_y)


@dataclass
class AffineTransform:
    """2D affine transformation: translation, rotation, scale, skew.

    The transformation matrix is:
    [ a  b  tx ]
    [ c  d  ty ]
    [ 0  0  1  ]

    Attributes:
        a: Scale and rotation (x basis x component)
        b: Skew (y basis x component)
        c: Skew (x basis y component)
        d: Scale and rotation (y basis y component)
        tx: Translation x
        ty: Translation y
    """
    a: float = 1.0
    b: float = 0.0
    c: float = 0.0
    d: float = 1.0
    tx: float = 0.0
    ty: float = 0.0

    @classmethod
    def identity(cls) -> 'AffineTransform':
        return cls()

    @classmethod
    def translate(cls, tx: float, ty: float) -> 'AffineTransform':
        return cls(a=1.0, b=0.0, c=0.0, d=1.0, tx=tx, ty=ty)

    @classmethod
    def scale(cls, sx: float, sy: float = None) -> 'AffineTransform':
        if sy is None:
            sy = sx
        return cls(a=sx, b=0.0, c=0.0, d=sy, tx=0.0, ty=0.0)

    @classmethod
    def rotate(cls, angle: float) -> 'AffineTransform':
        """Create a rotation transform (in radians)."""
        cos_a = math.cos(angle)
        sin_a = math.sin(angle)
        return cls(a=cos_a, b=-sin_a, c=sin_a, d=cos_a, tx=0.0, ty=0.0)

    def transform_point(self, point: Point) -> Point:
        """Apply transformation to a point."""
        x = self.a * point.x + self.b * point.y + self.tx
        y = self.c * point.x + self.d * point.y + self.ty
        return Point(x, y)

    def inverse(self) -> 'AffineTransform':
        """Calculate the inverse transformation."""
        det = self.a * self.d - self.b * self.c
        if abs(det) < 1e-10:
            raise ValueError("Cannot invert singular matrix")

        inv_det = 1.0 / det
        return AffineTransform(
            a=self.d * inv_det,
            b=-self.b * inv_det,
            c=-self.c * inv_det,
            d=self.a * inv_det,
            tx=(self.b * self.ty - self.d * self.tx) * inv_det,
            ty=(self.c * self.tx - self.a * self.ty) * inv_det,
        )

    def __mul__(self, other: 'AffineTransform') -> 'AffineTransform':
        """Compose two transformations (apply other first, then self)."""
        return AffineTransform(
            a=self.a * other.a + self.b * other.c,
            b=self.a * other.b + self.b * other.d,
            c=self.c * other.a + self.d * other.c,
            d=self.c * other.b + self.d * other.d,
            tx=self.a * other.tx + self.b * other.ty + self.tx,
            ty=self.c * other.tx + self.d * other.ty + self.ty,
        )


@dataclass
class CoordinateSystem:
    """Manages coordinate transformations between different spaces.

    Supports transformations between:
    - Geo coordinates (longitude, latitude)
    - Pixel coordinates (x, y in SVG space)
    - Hex coordinates (axial q, r)

    The transformation pipeline is:
    geo -> (geo_to_pixel) -> pixel -> (pixel_to_hex) -> hex
    """
    # Geo bounds (longitude, latitude)
    geo_min_lon: float = -180.0
    geo_max_lon: float = 180.0
    geo_min_lat: float = -90.0
    geo_max_lat: float = 90.0

    # Pixel bounds
    pixel_width: float = 800.0
    pixel_height: float = 600.0

    # Hex grid for pixel-to-hex conversion
    hex_grid: HexGrid = field(default_factory=HexGrid)

    def geo_to_pixel(self, lon: float, lat: float) -> Point:
        """Convert geo coordinates to pixel coordinates."""
        # Normalize longitude and latitude to 0-1 range
        norm_x = (lon - self.geo_min_lon) / (self.geo_max_lon - self.geo_min_lon)
        norm_y = (lat - self.geo_min_lat) / (self.geo_max_lat - self.geo_min_lat)

        # Flip Y axis (geo has lat increasing north, pixels have y increasing down)
        norm_y = 1.0 - norm_y

        x = norm_x * self.pixel_width
        y = norm_y * self.pixel_height

        return Point(x, y)

    def pixel_to_geo(self, point: Point) -> Tuple[float, float]:
        """Convert pixel coordinates to geo coordinates."""
        norm_x = point.x / self.pixel_width
        norm_y = point.y / self.pixel_height

        # Flip Y axis back
        norm_y = 1.0 - norm_y

        lon = self.geo_min_lon + norm_x * (self.geo_max_lon - self.geo_min_lon)
        lat = self.geo_min_lat + norm_y * (self.geo_max_lat - self.geo_min_lat)

        return (lon, lat)

    def geo_to_hex(self, lon: float, lat: float) -> HexCoord:
        """Convert geo coordinates to hex coordinates."""
        pixel = self.geo_to_pixel(lon, lat)
        return self.hex_grid.pixel_to_hex(pixel)

    def hex_to_geo(self, hex_coord: HexCoord) -> Tuple[float, float]:
        """Convert hex coordinates to geo coordinates."""
        pixel = self.hex_grid.hex_to_pixel(hex_coord)
        return self.pixel_to_geo(pixel)

    def geo_to_hex_direct(self, lon: float, lat: float) -> HexCoord:
        """Direct geo to hex conversion (for testing/debugging)."""
        return self.geo_to_hex(lon, lat)
