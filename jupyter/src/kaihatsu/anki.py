from typing import ClassVar

import requests
from pydantic import BaseModel


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

    params: Params
    action: str = "cardsInfo"
    version: int = 6

    class Response(BaseModel):
        error: str | None


host = ""


def request(r: BaseModel) -> BaseModel:
    res = requests.post(host, json=r.model_dump())
    result = r.Response.model_validate(res.json())
    if result.error:
        raise RuntimeError(result.error)
    return result


def search_cards(search: str) -> list[CardsResponse.Card]:
    ids_response: IdsResponse = request(
        FindCardsRequest(
            params=FindCardsRequest.Params(query=search),
        )
    )
    ids = ids_response.result

    cards_response: CardsResponse = request(
        CardsInfoRequest(params=CardsInfoRequest.Params(cards=ids))
    )
    return cards_response.result


def edit_cards(card: CardsResponse.Card) -> None:
    request(GuiEditNoteRequest(params=GuiEditNoteRequest.Params(note=card.note)))
