import dataclasses

from nicegui import ui

from wakimae import components
from wakimae.components import main_column
from wakimae.db import User
from wakimae.search import UserVectorStore
from wakimae.state import UserState
from wakimae.utils import debounce


async def main_page(state: UserState):
    @debounce(3)
    async def search():
        value = content_input.value
        related = await state.vector_store.find_related(value, 5)
        results: list[SearchResult] = []

        for note_id, content, distance in related:
            results.append(
                SearchResult(
                    summary=f"Study ({distance}) {content}", link=f"/study/{note_id}"
                )
            )

        search_results.refresh(results)

    @ui.refreshable
    def search_results(results: list[SearchResult]):
        for result in results:
            with ui.element("div").classes(
                "block p-2.5 w-full text-sm text-gray-900 rounded-lg border border-gray-300 focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:border-gray-600 dark:placeholder-gray-400 dark:text-white dark:focus:ring-blue-500 dark:focus:border-blue-500"
            ):
                ui.label(result.summary)

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
