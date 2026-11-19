"""Triangular point-lattice math for the board editor.

The board grid is a **triangular lattice of points** with nearest-neighbour
distance ``hex_spacing``.  These points are exactly the union of:

* the **corner vertices** of the "potential" pointy-top hexes, and
* the **centres** of those hexes,

so the points "form triangles" (equilateral triangles of side ``hex_spacing``).
Every point has six equidistant neighbours, and connecting neighbours yields a
triangular mesh (the dual of the hex tiling).

``hex_spacing`` is the distance between adjacent points.  Because the points are
hex corners/centres of size-``s`` hexes (``s = hex_spacing``):

* hex size (centre-to-vertex)   = ``hex_spacing``
* hex width  (flat-to-flat)     = ``sqrt(3) * hex_spacing``
* hex height (point-to-point)   = ``2 * hex_spacing``
* hex centre-to-centre distance = ``sqrt(3) * hex_spacing``

A point is indexed by axial coordinates ``(q, r)``.  Its pixel position is::

    e1 = (sqrt(3)*s/2, -s/2)     #  30 deg up-right
    e2 = (sqrt(3)*s/2,  s/2)     #  30 deg down-right
    pixel(q, r) = q*e1 + r*e2

A point is a **hex centre** iff ``(r - q) % 3 == 0``; otherwise it is a hex
corner.
"""

from __future__ import annotations

import math
from dataclasses import dataclass

SQRT3 = math.sqrt(3.0)

# A point coordinate is the axial pair (q, r).
PointCoord = tuple[int, int]


# --------------------------------------------------------------------------- #
# Hex geometry reference (the "potential hexes" formed by the points)
# --------------------------------------------------------------------------- #


def hex_size(spacing: float) -> float:
    """Centre-to-vertex radius of the potential hexes (= ``spacing``)."""
    return spacing


def hex_width(spacing: float) -> float:
    """Flat-to-flat (horizontal) extent of a potential hex."""
    return SQRT3 * spacing


def hex_height(spacing: float) -> float:
    """Point-to-point (vertical) extent of a potential hex."""
    return 2.0 * spacing


def hex_center_distance(spacing: float) -> float:
    """Distance between the centres of two adjacent potential hexes."""
    return SQRT3 * spacing


# --------------------------------------------------------------------------- #
# Point lattice
# --------------------------------------------------------------------------- #


def _basis(spacing: float) -> tuple[tuple[float, float], tuple[float, float]]:
    s = spacing
    return ((SQRT3 * s / 2.0, -s / 2.0), (SQRT3 * s / 2.0, s / 2.0))


def point_pixel(q: int, r: int, spacing: float) -> tuple[float, float]:
    """Pixel position of the point ``(q, r)``."""
    e1, e2 = _basis(spacing)
    return (q * e1[0] + r * e2[0], q * e1[1] + r * e2[1])


def point_pixel_coord(coord: PointCoord, spacing: float) -> tuple[float, float]:
    q, r = coord
    return point_pixel(q, r, spacing)


def pixel_to_point(x: float, y: float, spacing: float, *, snap: float = 0.5) -> PointCoord | None:
    """Return the nearest lattice point to ``(x, y)``, or ``None`` if it is
    farther than ``snap * spacing`` from any point."""
    s = spacing
    a = 2.0 * x / (SQRT3 * s)   # = q + r
    b = 2.0 * y / s             # = r - q
    q = round((a - b) / 2.0)
    r = round((a + b) / 2.0)
    cx, cy = point_pixel(q, r, s)
    if math.hypot(x - cx, y - cy) <= snap * s:
        return (q, r)
    return None


def point_neighbors(coord: PointCoord) -> list[PointCoord]:
    """The six neighbouring points of ``coord``."""
    q, r = coord
    return [(q + 1, r), (q - 1, r), (q, r + 1), (q, r - 1), (q + 1, r - 1), (q - 1, r + 1)]


def point_neighbors_forward(coord: PointCoord) -> list[PointCoord]:
    """Three "forward" neighbours; drawing edges to these from every point draws
    each lattice edge exactly once."""
    q, r = coord
    return [(q + 1, r), (q, r + 1), (q + 1, r - 1)]


def is_hex_center(coord: PointCoord) -> bool:
    """Whether the point ``(q, r)`` is a hex centre (vs a hex corner)."""
    q, r = coord
    return (r - q) % 3 == 0


@dataclass(frozen=True)
class Point:
    """A lattice point with its axial coordinate and pixel centre."""

    q: int
    r: int
    cx: float
    cy: float

    @property
    def coord(self) -> PointCoord:
        return (self.q, self.r)

    @property
    def is_center(self) -> bool:
        return is_hex_center(self.coord)


def grid_points(
    width: float,
    height: float,
    spacing: float,
    *,
    inset: float | None = None,
) -> list[Point]:
    """Generate every lattice point that is fully inside the board.

    A point is included only if its centre lies within the board rectangle
    inset by ``inset`` (default ``spacing / 2``).  Because the board rectangle is
    convex, this also keeps every point's hit-area (radius ``spacing / 2``) and
    the connection lines between shown points fully inside the board, so no
    point is ever partially clipped.
    """
    if inset is None:
        inset = spacing / 2.0
    s = spacing
    # Generous axial range derived from the board size and spacing.
    r_range = int(math.ceil(max(2.0 * width / (SQRT3 * s), 2.0 * height / s))) + 2
    pts: list[Point] = []
    for q in range(-r_range, r_range + 1):
        for r in range(-r_range, r_range + 1):
            cx, cy = point_pixel(q, r, s)
            if inset <= cx <= width - inset and inset <= cy <= height - inset:
                pts.append(Point(q=q, r=r, cx=cx, cy=cy))
    return pts


# Backwards-compatible alias.
neighbors = point_neighbors
