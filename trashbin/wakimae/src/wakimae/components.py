import contextlib

from nicegui import ui


@contextlib.contextmanager
def main_column():
    with ui.column().classes("w-full max-w-xl mx-auto my-6"):
        yield


@contextlib.contextmanager
def row(classes: str = ""):
    with ui.row().classes(f"w-full no-wrap items-center {classes}"):
        yield
