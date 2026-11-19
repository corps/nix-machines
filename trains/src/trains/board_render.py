"""Render a :class:`~trains.board_model.BoardLayout` to an SVG markup string.

The board is drawn as an SVG sized to ``width`` x ``height`` pixels containing,
in order:

1. a background rect,
2. the point grid — a triangular lattice of points (hex corners + hex centres):
   dots at each point, optionally with light connection lines (the triangular
   mesh) between adjacent points,
3. each layer (bottom-to-top): image, geometry, or SVG-mask stamps centred on
   the masked points.

Only points fully inside the board are drawn, so nothing is partially clipped.
"""

from __future__ import annotations

import html
import json
import re
from typing import Any

from . import hexgrid
from .board_model import BoardLayout, GeometryLayer, ImageLayer, SVGMaskLayer


# --------------------------------------------------------------------------- #
# Small SVG helpers
# --------------------------------------------------------------------------- #


def _esc(value: Any) -> str:
    return html.escape(str(value), quote=True)


# --------------------------------------------------------------------------- #
# Geometry JSON -> SVG
# --------------------------------------------------------------------------- #

_GEOMETRY_ATTRS: dict[str, list[str]] = {
    "polygon": ["points"],
    "polyline": ["points"],
    "rect": ["x", "y", "width", "height", "rx", "ry"],
    "circle": ["cx", "cy", "r"],
    "ellipse": ["cx", "cy", "rx", "ry"],
    "line": ["x1", "y1", "x2", "y2"],
    "path": ["d"],
}

_STYLE_ATTRS = [
    "fill",
    "stroke",
    "stroke_width",
    "opacity",
    "stroke_dasharray",
    "stroke_linecap",
    "stroke_linejoin",
    "fill_opacity",
    "fill_rule",
]


def _style_attr_name(key: str) -> str:
    return "stroke-width" if key == "stroke_width" else key.replace("_", "-")


def shape_to_svg(shape: dict[str, Any]) -> str:
    """Render one shape dict to an SVG element string."""
    stype = str(shape.get("type", "polygon")).lower()
    geom_keys = _GEOMETRY_ATTRS.get(stype)
    if geom_keys is None:
        return ""
    attrs: list[str] = []
    for key in geom_keys:
        if key in shape:
            attrs.append(f'{key}="{_esc(shape[key])}"')
    for key in _STYLE_ATTRS:
        if key in shape:
            attrs.append(f'{_style_attr_name(key)}="{_esc(shape[key])}"')
    if not attrs:
        return ""
    return f"<{stype} {' '.join(attrs)}/>"


def geometry_layer_to_svg(layer: GeometryLayer, board: BoardLayout) -> tuple[str, str | None]:
    """Return ``(svg_fragment, error_message)`` for a geometry layer."""
    try:
        doc = json.loads(layer.json_text)
    except json.JSONDecodeError as exc:
        return "", f"Invalid JSON: {exc.msg} (line {exc.lineno})"

    shapes = doc.get("shapes", [])
    if not isinstance(shapes, list):
        return "", '"shapes" must be a list'

    ox = layer.origin_x if layer.origin_x is not None else board.width / 2.0
    oy = layer.origin_y if layer.origin_y is not None else board.height / 2.0
    rot = layer.rotation
    scl = layer.scale

    parts: list[str] = []
    if rot or scl != 1.0:
        parts.append(
            f'<g transform="translate({ox:.3f} {oy:.3f}) rotate({rot:.4f}) '
            f'scale({scl:.4f}) translate({-ox:.3f} {-oy:.3f})">'
        )
    else:
        parts.append("<g>")
    for shape in shapes:
        if isinstance(shape, dict):
            parts.append(shape_to_svg(shape))
    parts.append("</g>")
    return "".join(parts), None


# --------------------------------------------------------------------------- #
# SVG parsing (for the mask layer)
# --------------------------------------------------------------------------- #


def parse_svg(svg_text: str) -> tuple[str, tuple[float, float, float, float]]:
    """Split an SVG document into ``(inner_content, viewbox)``.

    ``viewbox`` is ``(min_x, min_y, width, height)``.  Falls back to the
    ``width``/``height`` attributes, then to ``(0, 0, 100, 100)``.
    """
    m = re.search(r"<svg\b[^>]*>", svg_text, re.IGNORECASE)
    if not m:
        return svg_text, (0.0, 0.0, 100.0, 100.0)
    open_tag = m.group(0)
    close = svg_text.rfind("</svg>")
    inner = svg_text[m.end(): close if close != -1 else len(svg_text)]

    vb = re.search(r"viewBox\s*=\s*\"([^\"]+)\"", open_tag, re.IGNORECASE)
    if vb:
        nums = [float(x) for x in re.split(r"[\s,]+", vb.group(1).strip()) if x]
        if len(nums) == 4:
            return inner, (nums[0], nums[1], nums[2], nums[3])

    def _dim(attr: str) -> float | None:
        mm = re.search(rf"\b{attr}\s*=\s*\"([0-9.]+)", open_tag, re.IGNORECASE)
        return float(mm.group(1)) if mm else None

    w = _dim("width")
    h = _dim("height")
    return inner, (0.0, 0.0, w if w else 100.0, h if h else 100.0)


# --------------------------------------------------------------------------- #
# Layer fragments
# --------------------------------------------------------------------------- #


def image_layer_to_svg(layer: ImageLayer, clip_id: str) -> str:
    """Render an image layer, with optional crop (cover) clipping."""
    if not layer.data_url:
        return ""
    x, y = layer.x, layer.y
    w, h = layer.width, layer.height
    if w <= 0 or h <= 0:
        return ""

    if layer.fit == "fit":
        par = "xMidYMid meet"
    elif layer.fit == "crop":
        par = "xMidYMid slice"
    else:  # scale / stretch
        par = "none"

    clip = ""
    if layer.fit == "crop":
        clip = f' clip-path="url(#{clip_id})"'

    return (
        f'<image href="{_esc(layer.data_url)}" x="{x:.3f}" y="{y:.3f}" '
        f'width="{w:.3f}" height="{h:.3f}" preserveAspectRatio="{par}"{clip}/>'
    )


def svg_mask_layer_to_svg(layer: SVGMaskLayer, spacing: float) -> str:
    """Stamp the layer's SVG onto every corner point in its bitmap.

    Each stamp is centred on the point and scaled to fit a square of side
    ``spacing * layer.scale`` (so stamps on adjacent points just touch at
    ``scale == 1``).
    """
    if not layer.svg_text or not layer.bitmap:
        return ""
    inner, (vbx, vby, vbw, vbh) = parse_svg(layer.svg_text)
    if vbw <= 0 or vbh <= 0:
        return ""

    box = spacing * layer.scale
    vb = f"{vbx:.4f} {vby:.4f} {vbw:.4f} {vbh:.4f}"

    parts: list[str] = []
    for coord in sorted(layer.bitmap):
        cx, cy = hexgrid.point_pixel_coord(coord, spacing)
        x = cx - box / 2.0
        y = cy - box / 2.0
        parts.append(
            f'<svg x="{x:.3f}" y="{y:.3f}" width="{box:.3f}" height="{box:.3f}" '
            f'viewBox="{vb}" preserveAspectRatio="xMidYMid meet">{inner}</svg>'
        )
    return "".join(parts)


# --------------------------------------------------------------------------- #
# Corner-point grid
# --------------------------------------------------------------------------- #


def grid_to_svg(
    board: BoardLayout,
    *,
    show_points: bool = True,
    show_connections: bool = True,
    point_color: str = "#475569",
    connection_color: str = "#cbd5e1",
    connection_width: float = 1.0,
) -> str:
    """Render the triangular point grid: dots at each lattice point, and
    optionally the light connection lines (triangular mesh) between adjacent
    points.  Only points fully inside the board are drawn, and connections are
    only drawn between two such points, so nothing is partially clipped."""
    spacing = board.hex_spacing
    points = hexgrid.grid_points(board.width, board.height, spacing)
    radius = max(2.0, spacing * 0.07)
    shown = {p.coord for p in points}

    parts: list[str] = []
    if show_connections:
        # Draw each lattice edge once (three forward neighbours per point), and
        # only when both endpoints are shown (fully inside the board).
        for p in points:
            for nc in hexgrid.point_neighbors_forward(p.coord):
                if nc in shown:
                    nx, ny = hexgrid.point_pixel_coord(nc, spacing)
                    parts.append(
                        f'<line x1="{p.cx:.3f}" y1="{p.cy:.3f}" x2="{nx:.3f}" y2="{ny:.3f}" '
                        f'stroke="{_esc(connection_color)}" stroke-width="{connection_width}"/>'
                    )
    if show_points:
        for p in points:
            parts.append(f'<circle cx="{p.cx:.3f}" cy="{p.cy:.3f}" r="{radius:.3f}" fill="{_esc(point_color)}"/>')
    return "".join(parts)


# --------------------------------------------------------------------------- #
# Full board
# --------------------------------------------------------------------------- #


def render_board_svg(
    board: BoardLayout,
    *,
    show_grid: bool = True,
    show_connections: bool = True,
    point_color: str = "#475569",
    connection_color: str = "#cbd5e1",
) -> str:
    """Render the full board (background + point grid + layers) to an SVG string."""
    w, h = board.width, board.height
    spacing = board.hex_spacing

    defs: list[str] = []
    body: list[str] = []

    # Background.
    body.append(f'<rect x="0" y="0" width="{w:.3f}" height="{h:.3f}" fill="{_esc(board.background)}"/>')

    # Clip everything to the board.
    defs.append(f'<clipPath id="board-clip"><rect x="0" y="0" width="{w:.3f}" height="{h:.3f}"/></clipPath>')
    body.append('<g clip-path="url(#board-clip)">')

    # Corner-point grid.
    if show_grid or show_connections:
        body.append(
            grid_to_svg(
                board,
                show_points=show_grid,
                show_connections=show_connections,
                point_color=point_color,
                connection_color=connection_color,
            )
        )

    # Layers (bottom-to-top).
    clip_counter = 0
    for layer in board.layers:
        if isinstance(layer, ImageLayer):
            clip_id = f"img-clip-{clip_counter}"
            clip_counter += 1
            if layer.fit == "crop" and layer.data_url and layer.width > 0 and layer.height > 0:
                defs.append(
                    f'<clipPath id="{clip_id}"><rect x="{layer.x:.3f}" y="{layer.y:.3f}" '
                    f'width="{layer.width:.3f}" height="{layer.height:.3f}"/></clipPath>'
                )
            frag = image_layer_to_svg(layer, clip_id)
            if frag:
                body.append(frag)
        elif isinstance(layer, GeometryLayer):
            frag, _err = geometry_layer_to_svg(layer, board)
            if frag:
                body.append(frag)
        elif isinstance(layer, SVGMaskLayer):
            frag = svg_mask_layer_to_svg(layer, spacing)
            if frag:
                body.append(frag)

    body.append("</g>")  # end board-clip group

    defs_svg = f"<defs>{''.join(defs)}</defs>" if defs else ""
    return (
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{w:.3f}" height="{h:.3f}" '
        f'viewBox="0 0 {w:.3f} {h:.3f}">{defs_svg}{"".join(body)}</svg>'
    )


def geometry_layer_error(layer: GeometryLayer) -> str | None:
    """Return a JSON error message for a geometry layer, or ``None`` if valid."""
    try:
        doc = json.loads(layer.json_text)
    except json.JSONDecodeError as exc:
        return f"Invalid JSON: {exc.msg} (line {exc.lineno})"
    if not isinstance(doc.get("shapes", []), list):
        return '"shapes" must be a list'
    return None


__all__ = [
    "render_board_svg",
    "grid_to_svg",
    "geometry_layer_to_svg",
    "geometry_layer_error",
    "parse_svg",
    "shape_to_svg",
]
