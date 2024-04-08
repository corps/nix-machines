import asyncio

import pydantic
from nicegui import ui
from sqlalchemy import select

from libbiz.components import row

__all__ = ["manage"]

from libbiz.db import AsyncSession, Research
from libbiz.utils import debounce


class ResearchConfig(pydantic.BaseModel):
    search_q: str = ""


async def load_research() -> list[Research]:
    async with AsyncSession() as session:
        result = await session.execute(select(Research))
        return list(result.scalars())


def manage():
    @debounce(1)
    async def do_search():
        research = await load_research()
        configs = [ResearchConfig.model_validate(r.config) for r in research]
        search.set_autocomplete([c.search_q for c in configs])

    async def create_research():
        async with AsyncSession() as session:
            session.add(
                Research(
                    config=ResearchConfig(search_q=search.value).model_dump(mode="json")
                )
            )
            await session.commit()
        search.set_value("")
        ui.notify("saved")

    with row():
        ui.label("Search: ")
        search = (
            ui.input(
                placeholder="Search",
                on_change=(
                    lambda: [
                        btn.set_text("Start" if search.value else ""),
                        list_research.refresh(filter=search.value),
                    ]
                ),
            )
            .props("rounded outlined input-class=mx-3")
            .classes("flex-grow")
        )

        btn = ui.button(on_click=create_research)
        btn.bind_visibility_from(btn, "text", bool)

    list_research(filter=search.value)


@ui.refreshable
async def list_research(filter: str = ""):
    def row(r: Research):
        config = ResearchConfig.model_validate(r.config)
        is_match = config.search_q.startswith(filter)
        if is_match:
            with row():
                ui.label(config.search_q)

    research = await load_research()
    for r in research:
        row(r)
