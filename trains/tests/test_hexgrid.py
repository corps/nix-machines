"""Unit tests for the triangular point-lattice math (no browser required).

Run with::

    .venv/bin/python -m pytest tests/test_hexgrid.py -q
    .venv/bin/python tests/test_hexgrid.py
"""

from __future__ import annotations

import math

from trains import hexgrid


def test_six_neighbours_at_distance_spacing() -> None:
    s = 44.0
    coords = [(q, r) for q in range(-3, 4) for r in range(-3, 4)]
    for c in coords:
        x, y = hexgrid.point_pixel_coord(c, s)
        dists = sorted(
            round(math.hypot(x - hexgrid.point_pixel_coord(nc, s)[0],
                             y - hexgrid.point_pixel_coord(nc, s)[1]), 6)
            for nc in hexgrid.point_neighbors(c)
        )
        assert dists == [s] * 6, (c, dists)
        # nearest neighbour is exactly s (no point is closer)
        alld = sorted(math.hypot(x - hexgrid.point_pixel_coord(o, s)[0],
                                 y - hexgrid.point_pixel_coord(o, s)[1])
                      for o in coords if o != c)
        assert abs(alld[0] - s) < 1e-6, (c, alld[0])


def test_points_are_hex_corners_and_centres() -> None:
    """Every hex centre and corner is a lattice point (maps back exactly);
    centres are flagged by is_hex_center, corners are not."""
    s = 30.0
    for Q in range(-4, 5):
        for R in range(-4, 5):
            cx = s * hexgrid.SQRT3 * (Q + R / 2)
            cy = s * 1.5 * R
            coord = hexgrid.pixel_to_point(cx, cy, s)
            assert coord is not None
            px, py = hexgrid.point_pixel_coord(coord, s)
            assert math.hypot(px - cx, py - cy) < 1e-6  # centre is a lattice point
            assert hexgrid.is_hex_center(coord)
            for i in range(6):
                a = math.radians(60 * i - 30)
                kx, ky = cx + s * math.cos(a), cy + s * math.sin(a)
                kc = hexgrid.pixel_to_point(kx, ky, s)
                assert kc is not None
                px, py = hexgrid.point_pixel_coord(kc, s)
                assert math.hypot(px - kx, py - ky) < 1e-6  # corner is a lattice point
                assert not hexgrid.is_hex_center(kc)


def test_is_hex_center_predicate() -> None:
    # Hex (Q, R) centre maps to lattice coord (q, r) with (r - q) % 3 == 0.
    for Q in range(-4, 5):
        for R in range(-4, 5):
            cx = 44 * hexgrid.SQRT3 * (Q + R / 2)
            cy = 44 * 1.5 * R
            coord = hexgrid.pixel_to_point(cx, cy, 44)
            assert coord is not None
            assert hexgrid.is_hex_center(coord)
    # A corner (neighbour of a centre) is not a centre.
    assert not hexgrid.is_hex_center((1, 0))
    assert not hexgrid.is_hex_center((0, 1))
    assert hexgrid.is_hex_center((0, 0))


def test_pixel_point_round_trip() -> None:
    s = 38.0
    for c in [(0, 0), (1, 0), (0, 1), (2, -1), (-3, 2), (5, 4)]:
        x, y = hexgrid.point_pixel_coord(c, s)
        assert hexgrid.pixel_to_point(x, y, s) == c


def test_pixel_to_point_none_in_triangle_centroid() -> None:
    # The centroid of a lattice triangle is ~s/sqrt(3) from each vertex -> no snap.
    s = 40.0
    cx = (hexgrid.point_pixel(0, 0, s)[0] + hexgrid.point_pixel(1, 0, s)[0]
          + hexgrid.point_pixel(0, 1, s)[0]) / 3.0
    cy = (hexgrid.point_pixel(0, 0, s)[1] + hexgrid.point_pixel(1, 0, s)[1]
          + hexgrid.point_pixel(0, 1, s)[1]) / 3.0
    assert hexgrid.pixel_to_point(cx, cy, s) is None


def test_grid_points_fully_inside_board() -> None:
    s = 44.0
    w, h = 900.0, 640.0
    inset = s / 2.0
    pts = hexgrid.grid_points(w, h, s)
    assert pts
    for p in pts:
        assert inset - 1e-6 <= p.cx <= w - inset + 1e-6
        assert inset - 1e-6 <= p.cy <= h - inset + 1e-6
        # hit-area (radius 0.45*s) and dot (radius 0.07*s) are fully inside too
        assert p.cx - 0.45 * s >= -1e-6 and p.cx + 0.45 * s <= w + 1e-6
        assert p.cy - 0.45 * s >= -1e-6 and p.cy + 0.45 * s <= h + 1e-6
    coords = [p.coord for p in pts]
    assert len(coords) == len(set(coords))


def test_grid_points_drops_edge_points() -> None:
    """A point whose centre is outside the inset is not generated."""
    s = 44.0
    pts = hexgrid.grid_points(200.0, 200.0, s)
    coords = {p.coord for p in pts}
    # (0, 0) is at pixel (0, 0) -> outside the inset -> must be absent.
    assert (0, 0) not in coords


def test_hex_geometry_reference() -> None:
    s = 44.0
    assert hexgrid.hex_size(s) == s
    assert math.isclose(hexgrid.hex_width(s), math.sqrt(3) * s)
    assert math.isclose(hexgrid.hex_height(s), 2 * s)
    assert math.isclose(hexgrid.hex_center_distance(s), math.sqrt(3) * s)


def main() -> None:
    test_six_neighbours_at_distance_spacing()
    test_points_are_hex_corners_and_centres()
    test_is_hex_center_predicate()
    test_pixel_point_round_trip()
    test_pixel_to_point_none_in_triangle_centroid()
    test_grid_points_fully_inside_board()
    test_grid_points_drops_edge_points()
    test_hex_geometry_reference()
    print("ALL HEXGRID TESTS PASSED")


if __name__ == "__main__":
    main()
