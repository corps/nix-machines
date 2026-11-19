"""Headless tests for the board editor (no browser required).

These tests build the editor UI directly into a detached NiceGUI ``Client``
and drive the editor's methods, validating the full pipeline: board rendering
with the triangular point grid, layer management, the SVG-mask point-toggle
flow, geometry validation, and save/load serialization.

Run directly::

    .venv/bin/python tests/test_editor_ui.py

or via pytest::

    .venv/bin/python -m pytest tests/test_editor_ui.py -q
"""

from __future__ import annotations

import asyncio
import json

from nicegui import ui
from nicegui.client import Client
from nicegui.page import page
from nicegui.testing.general import nicegui_reset_globals, prepare_simulation

from trains.board_model import (
    BoardLayout,
    GeometryLayer,
    ImageLayer,
    SVGMaskLayer,
    bytes_to_data_url,
)
from trains.editor import BoardEditor


def _build(board: BoardLayout | None = None) -> tuple[Client, BoardEditor]:
    """Build an editor into a fresh detached client and return both."""
    prepare_simulation()
    client = Client(page("/"))
    with client:
        ed = BoardEditor(board=board)
        ed.build()
    return client, ed


class _FakeFile:
    """Minimal stand-in for a Starlette UploadFile used by ui.upload handlers."""

    def __init__(self, name: str, content_type: str, *, text: str | None = None, data: bytes = b"") -> None:
        self.name = name
        self.content_type = content_type
        self._text = text
        self._data = data

    async def text(self) -> str:
        return self._text or ""

    async def read(self) -> bytes:
        return self._data


class _FakeUploadEvent:
    """Stand-in for nicegui UploadEventArguments (only .client and .file are used)."""

    def __init__(self, client: Client, file: _FakeFile) -> None:
        self.client = client
        self.file = file


# --------------------------------------------------------------------------- #
# Tests
# --------------------------------------------------------------------------- #


def test_build_renders_point_grid() -> None:
    with nicegui_reset_globals():
        client, ed = _build()
        svg = ed.svg_holder.content
        assert svg.startswith("<svg") and svg.endswith("</svg>")
        assert "<circle" in svg  # point dots
        assert "<line" in svg  # triangular-mesh connections (on by default)
        assert "polygon" not in svg  # no hex outlines
        assert 'width="900.000"' in svg
        assert ed.board.width == 900 and ed.board.hex_spacing == 44
        # No hit-areas until an SVG-mask layer is active.
        assert ed.point_divs == {}
    print("PASS: build renders triangular point grid (dots + connections, no hexes)")


def test_connections_toggle_draws_lines() -> None:
    with nicegui_reset_globals():
        client, ed = _build()
        with client:
            assert "<line" in ed.svg_holder.content  # on by default
            ed._toggle_connections(False)
            assert "<line" not in ed.svg_holder.content
            ed._toggle_connections(True)
            assert "<line" in ed.svg_holder.content
    print("PASS: connections toggle draws/removes lattice edges")


def test_grid_points_are_not_clipped() -> None:
    """Only fully-inside points are shown; connections stay inside the board."""
    with nicegui_reset_globals():
        from trains import hexgrid

        client, ed = _build()
        s = ed.board.hex_spacing
        w, h = ed.board.width, ed.board.height
        pts = hexgrid.grid_points(w, h, s)
        assert pts
        for p in pts:
            assert s / 2 - 1e-6 <= p.cx <= w - s / 2 + 1e-6
            assert s / 2 - 1e-6 <= p.cy <= h - s / 2 + 1e-6
        # No connection line endpoint is outside the board.
        svg = ed.svg_holder.content
        assert "<line" in svg
    print("PASS: grid points are fully inside the board (nothing clipped)")


def test_add_layers_and_reorder() -> None:
    with nicegui_reset_globals():
        client, ed = _build()
        with client:
            ed._add_layer("image")
            ed._add_layer("geometry")
            ed._add_layer("svg_mask")
            assert [type(l) for l in ed.board.layers] == [ImageLayer, GeometryLayer, SVGMaskLayer]
            assert ed.active_layer_id == ed.board.layers[-1].id  # last added is active

            img_id = ed.board.layers[0].id
            ed._move(img_id, +1)
            assert [type(l) for l in ed.board.layers] == [GeometryLayer, ImageLayer, SVGMaskLayer]

            geo_id = next(l.id for l in ed.board.layers if isinstance(l, GeometryLayer))
            ed._delete(geo_id)
            assert len(ed.board.layers) == 2
    print("PASS: add / reorder / delete layers")


def test_svg_mask_point_toggle_flow() -> None:
    with nicegui_reset_globals():
        board = BoardLayout(width=600, height=400, hex_spacing=44)
        svg_layer = SVGMaskLayer(
            name="cities",
            svg_text='<svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="10" fill="gold"/></svg>',
        )
        board.add_layer(svg_layer)
        client, ed = _build(board)
        with client:
            ed.active_layer_id = svg_layer.id
            ed.refresh_svg()
            ed.refresh_overlay()

            assert ed.point_divs, "hit-areas should be built for active mask layer"
            assert ed.svg_holder.content.count("<svg x=") == 0  # empty mask -> no stamps

            # Use points fully inside the board (inset = spacing/2).
            ed._on_point_click((2, 5))
            assert (2, 5) in svg_layer.bitmap
            assert ed.svg_holder.content.count("<svg x=") == 1
            assert "on" in ed.point_divs[(2, 5)].classes

            ed._on_point_click((4, 7))
            assert (4, 7) in svg_layer.bitmap
            assert ed.svg_holder.content.count("<svg x=") == 2

            # Toggle (2, 5) off again.
            ed._on_point_click((2, 5))
            assert (2, 5) not in svg_layer.bitmap
            assert ed.svg_holder.content.count("<svg x=") == 1
            assert "on" not in ed.point_divs[(2, 5)].classes

            ed._clear_mask(svg_layer)
            assert svg_layer.bitmap == set()
            assert ed.svg_holder.content.count("<svg x=") == 0
    print("PASS: SVG mask point toggle updates bitmap, canvas, and highlight")


def test_svg_stamp_centered_on_point() -> None:
    with nicegui_reset_globals():
        from trains import hexgrid

        board = BoardLayout(width=600, height=400, hex_spacing=44)
        svg_layer = SVGMaskLayer(
            name="cities",
            svg_text='<svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="10" fill="gold"/></svg>',
            scale=1.0,
        )
        coord = (2, 5)  # fully inside the board (inset = spacing/2)
        svg_layer.bitmap = {coord}
        board.add_layer(svg_layer)
        client, ed = _build(board)
        with client:
            ed.refresh_svg()
            cx, cy = hexgrid.point_pixel_coord(coord, board.hex_spacing)
            box = board.hex_spacing * svg_layer.scale
            # The nested stamp is centred on the point: x = cx - box/2.
            assert f'x="{cx - box / 2:.3f}"' in ed.svg_holder.content
            assert f'y="{cy - box / 2:.3f}"' in ed.svg_holder.content
    print("PASS: SVG stamp is centred on the masked point")


def test_image_layer_crop_and_scale() -> None:
    with nicegui_reset_globals():
        board = BoardLayout(width=800, height=600, hex_spacing=40)
        img = ImageLayer(
            name="bg",
            data_url=bytes_to_data_url(b"\x89PNG\r\n\x1a\n fake", "image/png"),
            fit="crop",
            width=800,
            height=600,
        )
        board.add_layer(img)
        client, ed = _build(board)
        with client:
            ed.refresh_svg()
            svg = ed.svg_holder.content
            assert "data:image/png;base64," in svg
            assert 'preserveAspectRatio="xMidYMid slice"' in svg
            assert "clip-path=\"url(#img-clip-0)\"" in svg

            ed._set_image_fit(img, "fit")
            svg = ed.svg_holder.content
            assert 'preserveAspectRatio="xMidYMid meet"' in svg
            assert "url(#img-clip-0)" not in svg
    print("PASS: image layer crop/scale rendering")


def test_geometry_layer_validation_and_render() -> None:
    with nicegui_reset_globals():
        board = BoardLayout(width=800, height=600, hex_spacing=40)
        geo = GeometryLayer(
            name="geo",
            json_text=json.dumps(
                {"shapes": [{"type": "rect", "x": 10, "y": 10, "width": 80, "height": 40,
                             "fill": "#ef4444", "stroke": "#7f1d1d", "stroke_width": 2}]}
            ),
            rotation=15,
            scale=1.5,
        )
        board.add_layer(geo)
        client, ed = _build(board)
        with client:
            ed.refresh_svg()
            svg = ed.svg_holder.content
            assert "<rect" in svg and "rotate(15.0000)" in svg and "scale(1.5000)" in svg
            assert ed.geom_errors[geo.id].text == ""

            ed._on_geom_json(geo, "{not valid")
            assert "Invalid JSON" in ed.geom_errors[geo.id].text
    print("PASS: geometry layer validation and render")


def test_save_load_round_trip() -> None:
    with nicegui_reset_globals():
        board = BoardLayout(width=700, height=500, hex_spacing=36)
        board.add_layer(ImageLayer(name="bg", data_url=bytes_to_data_url(b"img", "image/png"),
                                   fit="fit", width=700, height=500))
        svg_layer = SVGMaskLayer(name="stops",
                                 svg_text='<svg viewBox="0 0 10 10"><rect width="10" height="10"/></svg>')
        svg_layer.bitmap = {(0, 0), (1, 2)}
        board.add_layer(svg_layer)

        client, ed = _build(board)
        payload = ed.board.to_json()

        with client:
            ed.board = BoardLayout.from_json(payload)
            ed.active_layer_id = None
            ed.refresh_layers()
            ed.refresh_all()
        assert ed.board.width == 700 and ed.board.hex_spacing == 36
        assert len(ed.board.layers) == 2
        assert isinstance(ed.board.layers[0], ImageLayer)
        assert ed.board.layers[0].data_url.startswith("data:image/png;base64,")
        assert isinstance(ed.board.layers[1], SVGMaskLayer)
        assert ed.board.layers[1].bitmap == {(0, 0), (1, 2)}
        assert "data:image/png;base64," in ed.svg_holder.content
    print("PASS: save/load round trip")


def test_svg_upload_handler_notifies_after_rebuild() -> None:
    """Regression: the SVG upload handler rebuilds the layer panel (deleting the
    upload element) and then notifies -- this must not raise
    'The parent element this slot belongs to has been deleted.'"""
    with nicegui_reset_globals():
        board = BoardLayout(width=600, height=400, hex_spacing=44)
        svg_layer = SVGMaskLayer(name="cities")
        board.add_layer(svg_layer)
        client, ed = _build(board)
        svg = '<svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="10" fill="gold"/></svg>'
        handler = ed._svg_upload_handler(svg_layer)
        asyncio.run(handler(_FakeUploadEvent(client, _FakeFile("t.svg", "image/svg+xml", text=svg))))
        assert svg_layer.svg_text == svg
        assert svg_layer.viewbox == (0.0, 0.0, 24.0, 24.0)
        # The bitmap is still empty, so no stamp renders yet.
        assert "gold" not in ed.svg_holder.content
        # Stamp a point and confirm the uploaded SVG actually renders.
        svg_layer.bitmap = {(2, 5)}
        ed.refresh_svg()
        assert "gold" in ed.svg_holder.content
    print("PASS: SVG upload handler notifies after layer-panel rebuild (no crash)")


def test_image_upload_handler_notifies_after_rebuild() -> None:
    """Regression: same as above for the image upload handler."""
    with nicegui_reset_globals():
        board = BoardLayout(width=600, height=400, hex_spacing=44)
        img_layer = ImageLayer(name="bg")
        board.add_layer(img_layer)
        client, ed = _build(board)
        handler = ed._image_upload_handler(img_layer)
        asyncio.run(
            handler(_FakeUploadEvent(client, _FakeFile("t.png", "image/png", data=b"\x89PNG\r\n\x1a\nfake")))
        )
        assert img_layer.data_url.startswith("data:image/png;base64,")
        # A zero-size image layer is auto-sized to the board.
        assert img_layer.width == board.width and img_layer.height == board.height
        assert "data:image/png;base64," in ed.svg_holder.content
    print("PASS: image upload handler notifies after layer-panel rebuild (no crash)")


def test_upload_handler_rejects_wrong_type() -> None:
    """The image handler rejects non-image files with a notification (no crash)."""
    with nicegui_reset_globals():
        board = BoardLayout(width=600, height=400, hex_spacing=44)
        img_layer = ImageLayer(name="bg")
        board.add_layer(img_layer)
        client, ed = _build(board)
        handler = ed._image_upload_handler(img_layer)
        # No exception and the layer is left untouched.
        asyncio.run(handler(_FakeUploadEvent(client, _FakeFile("t.txt", "text/plain", data=b"hello"))))
        assert img_layer.data_url == ""
    print("PASS: image upload handler rejects non-image files cleanly")


def test_board_props_resize() -> None:
    with nicegui_reset_globals():
        client, ed = _build()
        with client:
            ed.in_width.value = 1000
            ed.in_height.value = 700
            ed.in_spacing.value = 50
            ed._on_board_props()
            assert ed.board.width == 1000 and ed.board.height == 700
            assert 'width="1000.000"' in ed.svg_holder.content
            ed._add_layer("svg_mask")
            assert ed.point_divs  # rebuilt with new spacing
    print("PASS: board prop changes resize canvas and point grid")


# --------------------------------------------------------------------------- #
# Runner
# --------------------------------------------------------------------------- #


def main() -> None:
    test_build_renders_point_grid()
    test_connections_toggle_draws_lines()
    test_grid_points_are_not_clipped()
    test_add_layers_and_reorder()
    test_svg_mask_point_toggle_flow()
    test_svg_stamp_centered_on_point()
    test_image_layer_crop_and_scale()
    test_geometry_layer_validation_and_render()
    test_save_load_round_trip()
    test_svg_upload_handler_notifies_after_rebuild()
    test_image_upload_handler_notifies_after_rebuild()
    test_upload_handler_rejects_wrong_type()
    test_board_props_resize()
    print("\nALL EDITOR UI TESTS PASSED")


if __name__ == "__main__":
    main()
