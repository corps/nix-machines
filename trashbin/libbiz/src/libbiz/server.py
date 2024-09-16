from libbiz import research
from libbiz.components import main_column
from nicegui import ui

with main_column():
    research.manage()


if __name__ in {"__main__", "__mp_main__"}:
    ui.run(title="libbiz", port=8080)
