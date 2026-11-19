# Hex Train — Board Layout Editor

A browser-based editor (Python + [NiceGUI](https://nicegui.io)) for designing the
board used by the train game, inspired by Empire Builders.

The editor produces a **self-contained JSON payload** (images embedded as
base64 data URLs) that the game will later load to render the board.

## The grid: a triangular lattice of points, not hexes

The board grid is a **triangular lattice of points** rather than a grid of hex
cells. These points are exactly the union of:

* the **corner vertices** of the "potential" pointy-top hexes, and
* the **centres** of those hexes,

so the points "form triangles" — every point has six equidistant neighbours and
connecting neighbours yields a triangular mesh (the dual of the hex tiling). A
point is a hex **centre** iff `(r − q) % 3 == 0`, otherwise it is a hex corner.

* `hex_spacing` is the **distance between adjacent points**. This is also the hex
  *size* (centre-to-vertex radius), so:
  * hex width (flat-to-flat) = `√3 · hex_spacing`
  * hex height (point-to-point) = `2 · hex_spacing`
  * hex centre-to-centre distance = `√3 · hex_spacing`
* The displayed grid is **dots at each point** (no hexagon outlines). A
  **Connections** toggle draws the light triangular-mesh edges between adjacent
  points (on by default).
* **Only points fully inside the board are shown.** Points whose centre is within
  half a spacing of the edge are dropped, so no dot, hit-area, or connection is
  ever partially clipped (and every shown point is fully clickable).
* Each point has an axial coordinate `(q, r)`.

## Run

```bash
# from the repo root (the venv is already set up)
.venv/bin/trains-editor
# or
.venv/bin/python -m trains.editor
```

Then open <http://localhost:8080>.

## Board properties (header)

- **Width / Height** — pixel size of the entire board canvas.
- **Hex spacing** — distance between adjacent lattice points (= hex size).
- **Save JSON** — download the full board layout as a `.json` file.
- **Load JSON** — load a previously saved layout (replaces the current board).

## Layers

Layers are an **ordered stack, rendered bottom → top**. Each layer has a name,
move-up / move-down, delete, and a **Select** button (the *active* layer).
Add a layer with the **+ Image**, **+ Geometry**, or **+ SVG mask** buttons.

### 1. Image layer

Upload an image; it is embedded into the payload as a `data:` URL.

- **Fit**: how the image maps to the layer's `x/y/width/height` box:
  - `scale` — stretch to fill the box (may distort).
  - `fit` — contain (letterbox, whole image visible).
  - `crop` — cover (fill the box, clipping overflow).
- `x/y/width/height` — placement box (use **Set to board size** to fill the board).

### 2. Geometry layer

A JSON document describing a set of shapes, with a layer-level **rotation** and
**scale** (around an optional origin; blank = board centre).

```json
{
  "shapes": [
    {
      "type": "polygon",
      "points": [[100, 100], [300, 100], [200, 260]],
      "fill": "#3b82f6",
      "stroke": "#1e3a8a",
      "stroke_width": 3
    }
  ]
}
```

Supported `type`s: `polygon`, `polyline`, `rect`, `circle`, `ellipse`, `line`,
`path`. Geometry attributes (`points`, `x/y/width/height`, `cx/cy/r/rx/ry`,
`x1/y1/x2/y2`, `d`) plus style attributes: `fill`, `stroke`, `stroke_width`,
`opacity`, `stroke_dasharray`, `stroke_linecap`, `stroke_linejoin`,
`fill_opacity`, `fill_rule`. Invalid JSON is reported inline; use **Validate JSON**.

### 3. SVG mask layer

Upload an SVG object. It is then **stamped onto every point** listed in a binary
bitmap mask. Each stamp is **centred on the point** and scaled to fit a square of
side `hex_spacing · scale` (so stamps on adjacent points just touch at
`scale = 1`).

**Workflow:** upload an SVG → **Select** the layer → click points on the board to
toggle them in the mask (selected points are highlighted blue). The status bar
shows how many points are stamped. **Clear mask** empties the bitmap.

## Payload format (JSON)

```jsonc
{
  "format": "trains-board-layout",
  "version": 1,
  "width": 900,            // board pixel width
  "height": 640,           // board pixel height
  "hex_spacing": 44,       // distance between adjacent lattice points (= hex size)
  "background": "#e8eef5",
  "layers": [              // ordered bottom -> top
    { "type": "image", "id": "...", "name": "...", "data_url": "data:...;base64,...",
      "fit": "scale|fit|crop", "x": 0, "y": 0, "width": 900, "height": 640 },
    { "type": "geometry", "id": "...", "name": "...", "json_text": "{...}",
      "rotation": 0, "scale": 1, "origin_x": null, "origin_y": null },
    { "type": "svg_mask", "id": "...", "name": "...", "svg_text": "<svg ...>...</svg>",
      "viewbox": [0, 0, 24, 24], "bitmap": [[q, r], ...], "scale": 1.0 }
  ]
}
```

`bitmap` is the set of lattice-point coordinates `(q, r)` the SVG is stamped onto.

## Project layout

```
src/trains/
  hexgrid.py        # triangular point-lattice math (hex corners + centres)
  board_model.py    # BoardLayout + layer dataclasses + JSON (de)serialization
  board_render.py   # BoardLayout -> SVG markup (point grid, images, geometry, stamps)
  editor.py         # NiceGUI editor UI (run: python -m trains.editor)
tests/
  test_hexgrid.py   # lattice math tests
  test_editor_ui.py # headless editor tests (no browser)
examples/
  token.svg         # sample SVG to try the SVG-mask layer
  sample_geometry.json
```

## Tests

```bash
.venv/bin/python tests/test_hexgrid.py        # lattice math
.venv/bin/python tests/test_editor_ui.py      # editor (headless)
.venv/bin/python -m pytest tests/ -q
.venv/bin/python -m ty check src/trains       # type check
```
