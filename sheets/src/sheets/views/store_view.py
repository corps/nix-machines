from nicegui import Client, app, ui
from nicegui.element import Element
from pydantic import BaseModel, Field

from sheets.async_helpers import capture_events, run_async_renderer
from sheets.components import (
    aligned_baseline_row,
    col,
    full_input,
    growth_col,
    with_classes,
)
from sheets.ddb import load_character


class CharacterReference(BaseModel):
    ddb_id: int
    name: str


class UserData(BaseModel):
    characters: list[CharacterReference] = Field(default_factory=list)


async def store_page(client: Client):
    await client.connected()
    run_async_renderer(client, sheet_store())


container = with_classes(ui.row, "container mx-auto max-w-2xl")


async def sheet_store():
    user_data = UserData.model_validate(app.storage.user.get("data", {}))
    with container():
        events = capture_events()
        del_events = events.capture()
        submit_events = events.capture()
        change_url_events = events.capture()

        for character in user_data.characters:
            with aligned_baseline_row() as character_row:
                with growth_col():
                    with ui.link(target=f"/{character.ddb_id}"):
                        ui.markdown(f"#### {character.name}")
                with col():
                    with ui.button("Remove").classes("w-20"):
                        del_events.capture(["click"], (character, character_row))

        with aligned_baseline_row():
            with growth_col():
                with full_input("Your dndbeyond character id or url") as url_input:
                    submit_events.capture(["keydown.enter"])
                    change_url_events.capture(["change"])
            with col():
                with ui.button("Add").classes("w-20"):
                    submit_events.capture(["click"])

            while True:
                event, sources = await events.get()
                if del_events in sources:
                    character_row: Element
                    character, character_row = sources[0].payload
                    user_data.characters.remove(character)
                    app.storage.user["data"] = user_data.model_dump(mode="json")
                    character_row.delete()
                elif submit_events in sources:
                    with submit_events.busy():
                        await add_character(user_data, url_input.value)
                        return sheet_store()
                with change_url_events.validate(event):
                    assert parse_character_id(url_input.value), "Invalid character url"


async def add_character(user_data: UserData, input_value: str):
    character_id = parse_character_id(input_value)
    if character_id is None:
        return

    character = await load_character(character_id)

    character_sheet = CharacterReference(
        ddb_id=character_id,
        name=character.data.name,
    )
    user_data.characters.append(character_sheet)
    app.storage.user["data"] = user_data.model_dump(mode="json")


def parse_character_id(v: str) -> int | None:
    v = v.strip()
    if v.startswith("https://www.dndbeyond.com/characters/"):
        p = v.split("/")[-1]
    elif v.startswith(
        "https://character-service.dndbeyond.com/character/v5/character/"
    ):
        p = v.split("/")[-1]
    else:
        p = v
    try:
        return int(p)
    except (TypeError, ValueError):
        return None
