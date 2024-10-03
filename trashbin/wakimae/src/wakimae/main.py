import dataclasses

from nicegui import ui
from wakimae import components
from wakimae.components import main_column
from wakimae.state import UserState


async def main_page(state: UserState):
    with main_column():
        with components.row():
            ui.label("弁").classes("text-7xl text-center w-full")

        with components.row():
            content_input = ui.textarea("copy some content here").classes(
                "block p-2.5 w-full text-sm rounded-lg border border-gray-300 focus:ring-blue-500 focus:border-blue-500"
            )
            content_input.on("change", search)

        with components.row():
            search_results([SearchResult(summary="test", link="/")])


@dataclasses.dataclass
class SearchResult:
    summary: str
    link: str
