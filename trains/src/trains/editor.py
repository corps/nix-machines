"""NiceGUI board-layout editor.

Run with::

    python -m trains.editor

or, after installing the package, via the ``trains-editor`` console script.

The editor lets you configure a board (width, height, hex spacing) and an
ordered stack of layers:

* **Image** layers  — upload an image (embedded as a data URL), crop/scale it.
* **Geometry** layers — paste a JSON document of coloured shapes, rotate/scale.
* **SVG mask** layers — upload an SVG, then click points on the board to
  build the binary bitmap mask; the SVG is stamped onto every masked point.

The board grid is a **triangular lattice of points** — the hex corner vertices
plus the hex centres — not a grid of hex cells.  ``hex_spacing`` is the distance
between adjacent points (= the hex size).

The whole layout can be saved to / loaded from a single self-contained JSON
file (images embedded as base64 data URLs).
"""

from __future__ import annotations

from typing import cast

from nicegui import ui

from . import board_render, hexgrid
from .board_model import (
    BoardLayout,
    GeometryLayer,
    ImageLayer,
    SVGMaskLayer,
    bytes_to_data_url,
    guess_mime,
)

FIT_OPTIONS = [
    ("scale", "Scale (stretch)"),
    ("fit", "Fit (contain)"),
    ("crop", "Crop (cover)"),
]

CSS = """
.pt-hit { position:absolute; pointer-events:auto; cursor:pointer; background:transparent; border-radius:50%; }
.pt-hit:hover { background: rgba(15,23,42,0.12); }
.pt-hit.on { background: rgba(37,99,235,0.40); }
.pt-hit.on:hover { background: rgba(37,99,235,0.55); }
.layer-card-active { border: 2px solid #2563eb !important; }
"""


class BoardEditor:
    """Per-client editor state and UI."""

    def __init__(self, board: BoardLayout | None = None) -> None:
        self.board = board if board is not None else BoardLayout()
        self.active_layer_id: str | None = None
        self.show_grid = True
        self.show_connections = True

        # UI refs (populated in build()). ``cast`` keeps the declared type
        # concrete for the type-checker while the value is filled in later.
        self.in_width = cast(ui.number, None)
        self.in_height = cast(ui.number, None)
        self.in_spacing = cast(ui.number, None)
        self.board_container = cast(ui.element, None)
        self.svg_holder = cast(ui.html, None)
        self.overlay = cast(ui.element, None)
        self.layers_container = cast(ui.column, None)
        self.status = cast(ui.label, None)

        self.point_divs: dict[tuple[int, int], ui.element] = {}
        self.geom_errors: dict[str, ui.label] = {}

    # ------------------------------------------------------------------ #
    # Page construction
    # ------------------------------------------------------------------ #

    def build(self) -> None:
        ui.add_head_html(f"<style>{CSS}</style>")

        with ui.header().classes("items-center gap-3"):
            ui.label("Hex Train — Board Editor").classes("text-xl font-bold")
            ui.space()
            self.in_width = ui.number("Width", value=self.board.width, min=100, max=6000, step=10)
            self.in_height = ui.number("Height", value=self.board.height, min=100, max=6000, step=10)
            self.in_spacing = ui.number("Hex spacing", value=self.board.hex_spacing, min=6, max=400, step=1)
            for inp in (self.in_width, self.in_height, self.in_spacing):
                inp.props("dense outlined").style("width:130px")
                inp.on_value_change(self._on_board_props)
            self.in_spacing.props("tooltip=Distance between adjacent lattice points (= hex size)")
            ui.button("Save JSON", on_click=self.save).props("color=primary")
            ui.upload(label="Load JSON", auto_upload=True, on_upload=self._load_handler()).props("color=secondary")

        with ui.row().classes("w-full q-pa-md gap-4 items-start"):
            # Left: layers panel.
            with ui.column().classes("gap-2").style("width:400px; flex-shrink:0"):
                ui.label("Layers (bottom → top)").classes("text-lg font-semibold")
                with ui.row().classes("gap-1"):
                    ui.button("+ Image", on_click=lambda: self._add_layer("image")).props("dense color=primary")
                    ui.button("+ Geometry", on_click=lambda: self._add_layer("geometry")).props("dense color=primary")
                    ui.button("+ SVG mask", on_click=lambda: self._add_layer("svg_mask")).props("dense color=primary")
                self.layers_container = ui.column().classes("gap-2 w-full")

            # Right: canvas.
            with ui.column().classes("gap-2 items-center").style("flex:1; min-width:0"):
                with ui.row().classes("gap-3 items-center"):
                    ui.switch("Show grid", value=True, on_change=lambda e: self._toggle_grid(e.value))
                    ui.switch("Connections", value=True, on_change=lambda e: self._toggle_connections(e.value))
                    ui.label("Grid = points (hex corners + centres). Select an SVG-mask layer, then click points to toggle the mask.").classes(
                        "text-sm text-gray-500"
                    )
                self.canvas_scroll = (
                    ui.element("div")
                    .classes("overflow-auto")
                    .style(
                        "max-width:100%; max-height:76vh; border:1px solid #cbd5e1; "
                        "border-radius:8px; background:#fff;"
                    )
                )
                with self.canvas_scroll:
                    self.board_container = ui.element("div").style("position:relative; overflow:hidden;")
                    with self.board_container:
                        self.svg_holder = ui.html("", sanitize=False)
                        self.overlay = ui.element("div").style("position:absolute; inset:0; pointer-events:none;")
                self.status = ui.label("").classes("text-sm text-gray-600")

        self.refresh_layers()
        self.refresh_all()

    # ------------------------------------------------------------------ #
    # Board-level actions
    # ------------------------------------------------------------------ #

    def _on_board_props(self, _e=None) -> None:
        self.board.width = float(self.in_width.value or 900)
        self.board.height = float(self.in_height.value or 640)
        self.board.hex_spacing = float(self.in_spacing.value or 44)
        self.refresh_all()

    def _toggle_grid(self, value: bool) -> None:
        self.show_grid = bool(value)
        self.refresh_svg()

    def _toggle_connections(self, value: bool) -> None:
        self.show_connections = bool(value)
        self.refresh_svg()

    def save(self) -> None:
        ui.download(self.board.to_json().encode("utf-8"), "board_layout.json", "application/json")
        ui.notify("Board layout saved", type="positive")

    @staticmethod
    def _notify(client, message: str, **kwargs) -> None:
        """Show a notification bound to a specific client.

        Async upload handlers run in the context of the upload element's parent
        slot, which is destroyed when :meth:`refresh_layers` rebuilds the layer
        panel.  Resolving the client through ``ui.notify``'s ambient context then
        raises ``RuntimeError`` ("The parent element this slot belongs to has
        been deleted.").  Binding the notification to the captured client
        (``e.client``) keeps it working after a rebuild.
        """
        with client:
            ui.notify(message, **kwargs)

    def _load_handler(self):
        async def handler(e):
            text = await e.file.text()
            try:
                self.board = BoardLayout.from_json(text)
            except Exception as exc:  # noqa: BLE001
                self._notify(e.client, f"Load failed: {exc}", type="negative")
                return
            self.active_layer_id = None
            # Sync header inputs to the loaded board.
            self.in_width.value = self.board.width
            self.in_height.value = self.board.height
            self.in_spacing.value = self.board.hex_spacing
            self.refresh_layers()
            self.refresh_all()
            self._notify(e.client, "Board layout loaded", type="positive")

        return handler

    # ------------------------------------------------------------------ #
    # Layer management
    # ------------------------------------------------------------------ #

    def _add_layer(self, kind: str) -> None:
        if kind == "image":
            layer: ImageLayer | GeometryLayer | SVGMaskLayer = ImageLayer(
                name="Image layer", width=self.board.width, height=self.board.height
            )
        elif kind == "geometry":
            layer = GeometryLayer(name="Geometry layer")
        else:
            layer = SVGMaskLayer(name="SVG mask layer")
        self.board.add_layer(layer)
        self.active_layer_id = layer.id
        self.refresh_layers()
        self.refresh_all()

    def _select(self, layer_id: str) -> None:
        self.active_layer_id = layer_id
        self.refresh_layers()
        self.refresh_overlay()
        self._update_status()

    def _move(self, layer_id: str, delta: int) -> None:
        self.board.move_layer(layer_id, delta)
        self.refresh_layers()
        self.refresh_svg()

    def _delete(self, layer_id: str) -> None:
        self.board.remove_layer(layer_id)
        if self.active_layer_id == layer_id:
            self.active_layer_id = None
        self.refresh_layers()
        self.refresh_all()

    def _rename(self, layer, value) -> None:
        layer.name = str(value or layer.name)

    # ------------------------------------------------------------------ #
    # Layers panel
    # ------------------------------------------------------------------ #

    def refresh_layers(self) -> None:
        self.layers_container.clear()
        self.geom_errors = {}
        with self.layers_container:
            if not self.board.layers:
                ui.label("No layers yet. Add one above.").classes("text-gray-500 italic")
            for layer in self.board.layers:
                self._build_layer_card(layer)

    def _build_layer_card(self, layer) -> None:
        active = layer.id == self.active_layer_id
        with ui.card().classes("w-full") as card:
            if active:
                card.classes("layer-card-active")
            with ui.row().classes("items-center gap-1 w-full"):
                ui.badge(layer.kind).props("color=grey-7")
                ui.input(value=layer.name, on_change=lambda e, l=layer: self._rename(l, e.value)).props(
                    "dense borderless"
                ).classes("flex-grow")
                ui.button(icon="arrow_upward", on_click=lambda: self._move(layer.id, -1)).props("flat dense")
                ui.button(icon="arrow_downward", on_click=lambda: self._move(layer.id, +1)).props("flat dense")
                ui.button(icon="delete", on_click=lambda: self._delete(layer.id)).props("flat dense color=negative")
            with ui.row().classes("gap-1"):
                ui.button(
                    "Editing" if active else "Select",
                    on_click=lambda: self._select(layer.id),
                ).props("dense color=primary" if active else "dense color=grey")
            with ui.expansion("Configure", icon="tune").classes("w-full"):
                self._build_layer_config(layer)

    def _build_layer_config(self, layer) -> None:
        if isinstance(layer, ImageLayer):
            self._build_image_config(layer)
        elif isinstance(layer, GeometryLayer):
            self._build_geometry_config(layer)
        elif isinstance(layer, SVGMaskLayer):
            self._build_svgmask_config(layer)

    # ---- Image layer -------------------------------------------------- #

    def _build_image_config(self, layer: ImageLayer) -> None:
        ui.select(
            {v: lbl for v, lbl in FIT_OPTIONS},
            value=layer.fit,
            label="Fit",
            on_change=lambda e, l=layer: self._set_image_fit(l, e.value),
        ).props("dense outlined")
        with ui.row().classes("gap-2"):
            ui.number("X", value=layer.x, step=1, on_change=lambda e, l=layer: self._set_image_num(l, "x", e.value)).props(
                "dense outlined"
            )
            ui.number("Y", value=layer.y, step=1, on_change=lambda e, l=layer: self._set_image_num(l, "y", e.value)).props(
                "dense outlined"
            )
            ui.number("W", value=layer.width, step=1, on_change=lambda e, l=layer: self._set_image_num(l, "width", e.value)).props(
                "dense outlined"
            )
            ui.number("H", value=layer.height, step=1, on_change=lambda e, l=layer: self._set_image_num(l, "height", e.value)).props(
                "dense outlined"
            )
        with ui.row().classes("gap-2"):
            ui.button("Set to board size", on_click=lambda: self._image_to_board(layer)).props("dense")
            ui.upload(label="Upload image", auto_upload=True, on_upload=self._image_upload_handler(layer)).props("dense")
        if layer.data_url:
            ui.image(layer.data_url).style("max-width:140px; max-height:90px; border:1px solid #e2e8f0;")
        else:
            ui.label("No image uploaded.").classes("text-gray-500 italic")

    def _set_image_fit(self, layer: ImageLayer, value) -> None:
        layer.fit = str(value or "scale")
        self.refresh_svg()

    def _set_image_num(self, layer: ImageLayer, attr: str, value) -> None:
        setattr(layer, attr, float(value) if value is not None else 0.0)
        self.refresh_svg()

    def _image_to_board(self, layer: ImageLayer) -> None:
        layer.x = 0.0
        layer.y = 0.0
        layer.width = self.board.width
        layer.height = self.board.height
        self.refresh_layers()
        self.refresh_svg()

    def _image_upload_handler(self, layer: ImageLayer):
        async def handler(e):
            data = await e.file.read()
            mime = guess_mime(e.file.name, e.file.content_type)
            if not mime.startswith("image/"):
                self._notify(e.client, "Please upload an image file", type="negative")
                return
            layer.data_url = bytes_to_data_url(data, mime)
            if layer.width <= 0 or layer.height <= 0:
                layer.width = self.board.width
                layer.height = self.board.height
            self.refresh_svg()
            self.refresh_layers()
            self._notify(e.client, "Image loaded", type="positive")

        return handler

    # ---- Geometry layer ----------------------------------------------- #

    def _build_geometry_config(self, layer: GeometryLayer) -> None:
        err_label = ui.label("").classes("text-negative text-sm")
        self.geom_errors[layer.id] = err_label
        self._update_geom_error(layer)

        ta = ui.textarea("Geometry JSON", value=layer.json_text, on_change=lambda e, l=layer: self._on_geom_json(l, e.value))
        ta.props("dense outlined").classes("w-full")
        ta.style("font-family:monospace; min-height:180px;")

        with ui.row().classes("gap-2"):
            ui.number(
                "Rotation", value=layer.rotation, step=1,
                on_change=lambda e, l=layer: self._set_geom_num(l, "rotation", e.value),
            ).props("dense outlined")
            ui.number(
                "Scale", value=layer.scale, step=0.1,
                on_change=lambda e, l=layer: self._set_geom_num(l, "scale", e.value),
            ).props("dense outlined")
        with ui.row().classes("gap-2"):
            ui.number(
                "Origin X", value=layer.origin_x, placeholder="board centre",
                on_change=lambda e, l=layer: self._set_geom_origin(l, "origin_x", e.value),
            ).props("dense outlined")
            ui.number(
                "Origin Y", value=layer.origin_y, placeholder="board centre",
                on_change=lambda e, l=layer: self._set_geom_origin(l, "origin_y", e.value),
            ).props("dense outlined")
        ui.button("Validate JSON", on_click=lambda: self._validate_geom(layer)).props("dense")

    def _on_geom_json(self, layer: GeometryLayer, value) -> None:
        layer.json_text = str(value or "")
        self._update_geom_error(layer)
        self.refresh_svg()

    def _set_geom_num(self, layer: GeometryLayer, attr: str, value) -> None:
        setattr(layer, attr, float(value) if value is not None else 0.0)
        self.refresh_svg()

    def _set_geom_origin(self, layer: GeometryLayer, attr: str, value) -> None:
        setattr(layer, attr, None if value is None else float(value))
        self.refresh_svg()

    def _update_geom_error(self, layer: GeometryLayer) -> None:
        label = self.geom_errors.get(layer.id)
        if label is None:
            return
        err = board_render.geometry_layer_error(layer)
        label.set_text(err or "")

    def _validate_geom(self, layer: GeometryLayer) -> None:
        err = board_render.geometry_layer_error(layer)
        if err:
            ui.notify(err, type="negative")
        else:
            ui.notify("Geometry JSON is valid", type="positive")

    # ---- SVG mask layer ----------------------------------------------- #

    def _build_svgmask_config(self, layer: SVGMaskLayer) -> None:
        ui.upload(label="Upload SVG", auto_upload=True, on_upload=self._svg_upload_handler(layer)).props("dense")
        if layer.svg_text:
            inner, vb = board_render.parse_svg(layer.svg_text)
            preview = (
                f'<svg xmlns="http://www.w3.org/2000/svg" width="90" height="90" '
                f'viewBox="{vb[0]:g} {vb[1]:g} {vb[2]:g} {vb[3]:g}">{inner}</svg>'
            )
            ui.html(preview, sanitize=False).style("border:1px solid #e2e8f0; background:#fff;")
            ui.label(f"viewBox: {vb[0]:g} {vb[1]:g} {vb[2]:g} {vb[3]:g}").classes("text-xs text-gray-600")
            ui.label(f"{len(layer.bitmap)} point(s) in mask").classes("text-xs text-gray-600")
        else:
            ui.label("No SVG uploaded.").classes("text-gray-500 italic")

        with ui.row().classes("gap-2"):
            ui.number(
                "Stamp scale", value=layer.scale, step=0.05, min=0.1, max=5,
                on_change=lambda e, l=layer: self._set_svgmask_scale(l, e.value),
            ).props("dense outlined")
            ui.button("Clear mask", on_click=lambda: self._clear_mask(layer)).props("dense color=negative")
        ui.label("Select this layer, then click points on the board to toggle the mask.").classes(
            "text-xs text-blue-600"
        )

    def _set_svgmask_scale(self, layer: SVGMaskLayer, value) -> None:
        layer.scale = float(value) if value is not None else 1.0
        self.refresh_svg()

    def _clear_mask(self, layer: SVGMaskLayer) -> None:
        layer.bitmap.clear()
        self.refresh_svg()
        self.refresh_overlay()
        self.refresh_layers()
        self._update_status()

    def _svg_upload_handler(self, layer: SVGMaskLayer):
        async def handler(e):
            text = await e.file.text()
            if "<svg" not in text.lower():
                self._notify(e.client, "File does not look like an SVG", type="warning")
                return
            layer.svg_text = text
            layer.viewbox = board_render.parse_svg(text)[1]
            self.refresh_svg()
            self.refresh_layers()
            self._update_status()
            self._notify(e.client, "SVG loaded", type="positive")

        return handler

    # ------------------------------------------------------------------ #
    # Canvas rendering
    # ------------------------------------------------------------------ #

    def refresh_all(self) -> None:
        self.board_container.style(f"width:{self.board.width}px; height:{self.board.height}px;")
        self.refresh_svg()
        self.refresh_overlay()
        self._update_status()

    def refresh_svg(self) -> None:
        svg = board_render.render_board_svg(
            self.board, show_grid=self.show_grid, show_connections=self.show_connections
        )
        self.svg_holder.set_content(svg)

    def refresh_overlay(self) -> None:
        """Rebuild circular point hit-areas (only when an SVG-mask layer is active)."""
        self.overlay.clear()
        self.point_divs = {}
        layer = self.get_active_layer()
        if not isinstance(layer, SVGMaskLayer):
            return

        spacing = self.board.hex_spacing
        # Hit-area radius (0.45*spacing) fits within grid_points' default inset
        # (0.5*spacing), so every hit-area is fully inside the board.
        d = spacing * 0.9
        points = hexgrid.grid_points(self.board.width, self.board.height, spacing)
        with self.overlay:
            for p in points:
                left = p.cx - d / 2.0
                top = p.cy - d / 2.0
                div = ui.element("div").classes("pt-hit")
                div.style(f"left:{left:.3f}px; top:{top:.3f}px; width:{d:.3f}px; height:{d:.3f}px;")
                if p.coord in layer.bitmap:
                    div.classes("on")
                coord = p.coord
                div.on("click", lambda e, c=coord: self._on_point_click(c))
                self.point_divs[coord] = div

    def _on_point_click(self, coord: tuple[int, int]) -> None:
        layer = self.get_active_layer()
        if not isinstance(layer, SVGMaskLayer):
            return
        if coord in layer.bitmap:
            layer.bitmap.discard(coord)
        else:
            layer.bitmap.add(coord)
        div = self.point_divs.get(coord)
        if div is not None:
            div.classes(toggle="on")
        self.refresh_svg()
        self._update_status()

    # ------------------------------------------------------------------ #
    # Misc
    # ------------------------------------------------------------------ #

    def get_active_layer(self):
        if self.active_layer_id is None:
            return None
        return self.board.get_layer(self.active_layer_id)

    def _update_status(self) -> None:
        layer = self.get_active_layer()
        if isinstance(layer, SVGMaskLayer):
            self.status.set_text(
                f'Editing SVG mask "{layer.name}" — {len(layer.bitmap)} point(s) stamped. '
                "Click points on the board to toggle them."
            )
        elif layer is not None:
            self.status.set_text(f'Active layer: {layer.name} ({layer.kind})')
        else:
            self.status.set_text("Select a layer to edit. SVG-mask layers are toggled by clicking points.")


# --------------------------------------------------------------------------- #
# App entry points
# --------------------------------------------------------------------------- #


@ui.page("/")
def index() -> None:
    BoardEditor().build()


def main() -> None:
    ui.run(title="Hex Train — Board Editor", port=8080, reload=False, show=True)


if __name__ in ("__main__", "__mp_main__"):
    main()
