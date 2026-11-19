"""Board-layout data model and (de)serialization.

A :class:`BoardLayout` is the payload the editor produces and the game consumes.
It has a pixel ``width``/``height``, a ``hex_spacing`` (distance between adjacent
lattice points, where the lattice is the hex corners + hex centres; also the hex
size / centre-to-vertex radius) and an *ordered* list of layers (rendered
bottom-to-top).

Three layer kinds are supported:

* :class:`ImageLayer`   — an embedded image (base64 data URL) with crop/scale fit.
* :class:`GeometryLayer`— a JSON-defined set of coloured shapes with rotation/scale.
* :class:`SVGMaskLayer` — an SVG placed on every hex of a binary bitmap mask.

The whole layout serializes to/from a single JSON document (images embedded as
data URLs), so a board is fully self-contained.
"""

from __future__ import annotations

import base64
import json
import mimetypes
import uuid
from dataclasses import dataclass, field
from typing import Any


def new_id() -> str:
    return uuid.uuid4().hex[:10]


# --------------------------------------------------------------------------- #
# Layers
# --------------------------------------------------------------------------- #


@dataclass
class ImageLayer:
    """An image embedded as a data URL, optionally cropped/scaled to fit."""

    kind: str = "image"
    id: str = field(default_factory=new_id)
    name: str = "Image layer"
    data_url: str = ""          # data:<mime>;base64,<...>
    fit: str = "scale"          # scale (stretch) | fit (contain) | crop (cover)
    x: float = 0.0
    y: float = 0.0
    width: float = 0.0
    height: float = 0.0

    def to_dict(self) -> dict[str, Any]:
        return {
            "type": self.kind,
            "id": self.id,
            "name": self.name,
            "data_url": self.data_url,
            "fit": self.fit,
            "x": self.x,
            "y": self.y,
            "width": self.width,
            "height": self.height,
        }

    @classmethod
    def from_dict(cls, d: dict[str, Any]) -> "ImageLayer":
        return cls(
            id=d.get("id", new_id()),
            name=d.get("name", "Image layer"),
            data_url=d.get("data_url", ""),
            fit=d.get("fit", "scale"),
            x=float(d.get("x", 0.0)),
            y=float(d.get("y", 0.0)),
            width=float(d.get("width", 0.0)),
            height=float(d.get("height", 0.0)),
        )


# NOTE: rotation/scale/origin are *layer-level* fields (see GeometryLayer),
# not part of this JSON. The JSON only describes the shapes themselves.
DEFAULT_GEOMETRY_JSON = json.dumps(
    {
        "shapes": [
            {
                "type": "polygon",
                "points": [[100, 100], [300, 100], [200, 260]],
                "fill": "#3b82f6",
                "stroke": "#1e3a8a",
                "stroke_width": 3,
            }
        ]
    },
    indent=2,
)


@dataclass
class GeometryLayer:
    """A set of shapes defined by a JSON document, with rotation and scale."""

    kind: str = "geometry"
    id: str = field(default_factory=new_id)
    name: str = "Geometry layer"
    json_text: str = DEFAULT_GEOMETRY_JSON
    rotation: float = 0.0
    scale: float = 1.0
    # Origin for rotation/scale. ``None`` means "board centre".
    origin_x: float | None = None
    origin_y: float | None = None

    def to_dict(self) -> dict[str, Any]:
        return {
            "type": self.kind,
            "id": self.id,
            "name": self.name,
            "json_text": self.json_text,
            "rotation": self.rotation,
            "scale": self.scale,
            "origin_x": self.origin_x,
            "origin_y": self.origin_y,
        }

    @classmethod
    def from_dict(cls, d: dict[str, Any]) -> "GeometryLayer":
        return cls(
            id=d.get("id", new_id()),
            name=d.get("name", "Geometry layer"),
            json_text=d.get("json_text", DEFAULT_GEOMETRY_JSON),
            rotation=float(d.get("rotation", 0.0)),
            scale=float(d.get("scale", 1.0)),
            origin_x=d["origin_x"] if d.get("origin_x") is not None else None,
            origin_y=d["origin_y"] if d.get("origin_y") is not None else None,
        )


@dataclass
class SVGMaskLayer:
    """An SVG object stamped onto every point listed in a binary bitmap.

    ``bitmap`` is a set of lattice-point coordinates ``(q, r)`` (see
    :mod:`trains.hexgrid`).  Each stamped SVG is centred on the point and scaled
    to fit a square of side ``hex_spacing * scale``.
    """

    kind: str = "svg_mask"
    id: str = field(default_factory=new_id)
    name: str = "SVG mask layer"
    svg_text: str = ""
    viewbox: tuple[float, float, float, float] = (0.0, 0.0, 100.0, 100.0)
    bitmap: set[tuple[int, int]] = field(default_factory=set)
    scale: float = 1.0

    def to_dict(self) -> dict[str, Any]:
        return {
            "type": self.kind,
            "id": self.id,
            "name": self.name,
            "svg_text": self.svg_text,
            "viewbox": list(self.viewbox),
            "bitmap": sorted([list(c) for c in self.bitmap]),
            "scale": self.scale,
        }

    @classmethod
    def from_dict(cls, d: dict[str, Any]) -> "SVGMaskLayer":
        vb = d.get("viewbox", [0, 0, 100, 100])
        bitmap = {tuple(c) for c in d.get("bitmap", [])}  # type: ignore[misc]
        return cls(
            id=d.get("id", new_id()),
            name=d.get("name", "SVG mask layer"),
            svg_text=d.get("svg_text", ""),
            viewbox=(float(vb[0]), float(vb[1]), float(vb[2]), float(vb[3])),
            bitmap=bitmap,
            scale=float(d.get("scale", 1.0)),
        )


Layer = ImageLayer | GeometryLayer | SVGMaskLayer

_LAYER_TYPES: dict[str, type[Layer]] = {
    "image": ImageLayer,
    "geometry": GeometryLayer,
    "svg_mask": SVGMaskLayer,
}


def layer_from_dict(d: dict[str, Any]) -> Layer:
    t = d.get("type")
    if not isinstance(t, str):
        raise ValueError(f"Unknown layer type: {t!r}")
    cls = _LAYER_TYPES.get(t)
    if cls is None:
        raise ValueError(f"Unknown layer type: {t!r}")
    return cls.from_dict(d)  # type: ignore[return-value]


# --------------------------------------------------------------------------- #
# Board
# --------------------------------------------------------------------------- #


@dataclass
class BoardLayout:
    width: float = 900.0
    height: float = 640.0
    hex_spacing: float = 44.0
    # Ordered bottom-to-top.
    layers: list[Layer] = field(default_factory=list)
    background: str = "#e8eef5"

    # -- layer helpers ----------------------------------------------------- #

    def add_layer(self, layer: Layer) -> Layer:
        self.layers.append(layer)
        return layer

    def remove_layer(self, layer_id: str) -> None:
        self.layers = [lyr for lyr in self.layers if lyr.id != layer_id]

    def get_layer(self, layer_id: str) -> Layer | None:
        for lyr in self.layers:
            if lyr.id == layer_id:
                return lyr
        return None

    def move_layer(self, layer_id: str, delta: int) -> None:
        """Move a layer by ``delta`` positions in the ordered list."""
        idx = next((i for i, lyr in enumerate(self.layers) if lyr.id == layer_id), None)
        if idx is None:
            return
        new_idx = max(0, min(len(self.layers) - 1, idx + delta))
        if new_idx == idx:
            return
        lyr = self.layers.pop(idx)
        self.layers.insert(new_idx, lyr)

    # -- (de)serialization ------------------------------------------------- #

    def to_dict(self) -> dict[str, Any]:
        return {
            "format": "trains-board-layout",
            "version": 1,
            "width": self.width,
            "height": self.height,
            "hex_spacing": self.hex_spacing,
            "background": self.background,
            "layers": [lyr.to_dict() for lyr in self.layers],
        }

    def to_json(self, *, indent: int = 2) -> str:
        return json.dumps(self.to_dict(), indent=indent)

    @classmethod
    def from_dict(cls, d: dict[str, Any]) -> "BoardLayout":
        layers = [layer_from_dict(lyr) for lyr in d.get("layers", [])]
        return cls(
            width=float(d.get("width", 900.0)),
            height=float(d.get("height", 640.0)),
            hex_spacing=float(d.get("hex_spacing", 44.0)),
            background=d.get("background", "#e8eef5"),
            layers=layers,
        )

    @classmethod
    def from_json(cls, text: str) -> "BoardLayout":
        return cls.from_dict(json.loads(text))


# --------------------------------------------------------------------------- #
# Upload helpers
# --------------------------------------------------------------------------- #


def guess_mime(filename: str, content_type: str | None = None) -> str:
    if content_type and "/" in content_type:
        return content_type
    mime, _ = mimetypes.guess_type(filename)
    return mime or "application/octet-stream"


def bytes_to_data_url(data: bytes, mime: str) -> str:
    return f"data:{mime};base64,{base64.b64encode(data).decode('ascii')}"
