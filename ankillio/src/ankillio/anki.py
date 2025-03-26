import os
from typing import ClassVar

import requests
from bs4 import BeautifulSoup, NavigableString
from dotenv import load_dotenv
from pydantic import BaseModel

load_dotenv()


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


class AnswerCardEasing(BaseModel):
    cardId: int
    ease: int


class AnswerCardsRequest(BaseModel):
    class Params(BaseModel):
        answers: list[AnswerCardEasing]

    params: Params
    action: str = "answerCards"
    version: int = 6

    class Response(BaseModel):
        error: str | None


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


class RemoveTagsRequest(BaseModel):
    class Params(BaseModel):
        notes: list[int]
        tags: str | list[str]

    params: Params
    action: str = "removeTags"
    version: int = 6

    class Response(BaseModel):
        error: str | None


class AnkiService(BaseModel):
    host: str = "http://127.0.0.1:8765"

    def request(self, r: BaseModel) -> BaseModel:
        res = requests.post(self.host, json=r.model_dump())
        result = r.Response.model_validate(res.json())
        if result.error:
            raise RuntimeError(result.error)
        return result

    def search_cards(self, search: str) -> list[CardsResponse.Card]:
        ids_response: IdsResponse = self.request(
            FindCardsRequest(
                params=FindCardsRequest.Params(query=search),
            )
        )
        ids = ids_response.result

        cards_response: CardsResponse = self.request(
            CardsInfoRequest(params=CardsInfoRequest.Params(cards=ids))
        )
        return cards_response.result

    def card_info(self, cardId: int) -> CardsResponse.Card | None:
        cards_response: CardsResponse = self.request(
            CardsInfoRequest(params=CardsInfoRequest.Params(cards=[cardId]))
        )

        if cards_response.result:
            return cards_response.result[0]
        return None

    def answer_cards(self, answers: list[AnswerCardEasing]) -> None:
        self.request(
            AnswerCardsRequest(params=AnswerCardsRequest.Params(answers=answers))
        )

    def edit_cards(self, card: CardsResponse.Card) -> None:
        self.request(
            GuiEditNoteRequest(params=GuiEditNoteRequest.Params(note=card.note))
        )

    def remove_tags(self, card: CardsResponse.Card, tag: str) -> None:
        self.request(
            RemoveTagsRequest(
                params=RemoveTagsRequest.Params(notes=[card.note], tag=tag)
            )
        )


class SyncRequest(BaseModel):
    cards: list[CardsResponse.Card]


class SyncResponse(BaseModel):
    studied: list[AnswerCardEasing]


class StudyItems(BaseModel):
    cards: list[CardsResponse.Card]
    studied: list[AnswerCardEasing]

    def find_next(self) -> CardsResponse.Card | None:
        studied_ids = set(c.cardId for c in self.studied)
        for card in self.cards:
            if card.cardId in studied_ids:
                continue
            return card

    def answer(self, card: CardsResponse.Card, ease: int) -> None:
        self.studied.append(AnswerCardEasing(cardId=card.cardId, ease=ease))
        self.cards = [c for c in self.cards if c.cardId != card.cardId]


class SyncService(BaseModel):
    host: str
    anki_service: AnkiService
    twilio_auth_token: str

    def sync(self):
        request = SyncRequest(cards=self.anki_service.search_cards("tag:audio"))
        print(f"Pushing {len(request.cards)} cards")
        resp = SyncResponse.model_validate(
            requests.put(
                self.host + "/sync",
                json=request.model_dump(),
                headers={"Authorization": self.twilio_auth_token},
            ).json()
        )
        for studied in resp.studied:
            if studied.ease != 0:
                card = self.anki_service.card_info(studied.cardId)
                if card is not None:
                    print("Receiving update...")
                    self.anki_service.answer_cards([studied])
                    self.anki_service.remove_tags(card, "audio")


def sync(server: str):
    SyncService(
        host=server,
        anki_service=AnkiService(),
        twilio_auth_token=os.environ["TWILIO_AUTH_TOKEN"],
    ).sync()


if __name__ == "__main__":
    sync("https://ankillio.kaihatsu.io")
