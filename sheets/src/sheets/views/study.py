from typing import ClassVar

from nicegui import Client, app, ui
from pydantic import BaseModel

from sheets.async_helpers import capture_events, run_async_renderer
from sheets.components import with_classes
from sheets.storage import ModelStorage


class IdsResponse(BaseModel):
    result: list[int] | None
    error: str | None


class CardsResponse(BaseModel):
    class Card(BaseModel):
        answer: str
        question: str
        deckName: str

        class Field(BaseModel):
            value: str
            order: int

        fields: dict[str, Field]
        cardId: int
        note: int
        interval: int
        mod: int
        reps: int

    result: list[Card] | None
    error: str | None


class FindCardsRequest(BaseModel):
    class Params(BaseModel):
        query: str

    params: Params
    action: str = "findCards"
    version: int = 6
    Response: ClassVar[type[BaseModel]] = IdsResponse


class CardsToNotesRequest(BaseModel):
    class Params(BaseModel):
        cards: list[int]

    params: Params
    action: str = "cardsToNotes"
    version: int = 6

    Response: ClassVar[type[BaseModel]] = IdsResponse


class CardsInfoRequest(BaseModel):
    class Params(BaseModel):
        cards: list[int]

    params: Params
    action: str = "cardsInfo"
    version: int = 6

    Response: ClassVar[type[BaseModel]] = CardsResponse


class GuiEditNoteRequest(BaseModel):
    class Params(BaseModel):
        note: int

    action: str = "cardsInfo"
    version: int = 6

    class Response(BaseModel):
        error: str | None


class Wordset(BaseModel):
    pass


character_storage = ModelStorage("wordset_", Wordset, app.storage.general)


async def study_page(client: Client):
    await client.connected()
    ui.add_css(".nicegui-content { padding: 0px }")
    run_async_renderer(client, study_view())


container = with_classes(ui.row, "container mx-auto max-w-2xl")


# https://foosoft.net/projects/anki-connect/index.html#note-actions
async def study_view():
    clicks = capture_events()

    def add_container():
        with ui.element().props("contenteditable").classes(
            "h-screen w-full p-0 gap-y-0 gap-x-0"
        ):
            capture_events(["keydown"], clicks)

    with container():
        add_container()
