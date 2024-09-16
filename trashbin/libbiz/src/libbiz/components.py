import contextlib

from nicegui import ui


@contextlib.contextmanager
def main_column():
    with ui.column().classes("w-full max-w-3xl mx-auto my-6"):
        yield


@contextlib.contextmanager
def row():
    with ui.row().classes("w-full no-wrap items-center"):
        yield
