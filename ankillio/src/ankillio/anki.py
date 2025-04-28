import datetime
from typing import ClassVar

import aiohttp
import numpy as np
from dotenv import load_dotenv
from mistralai import Mistral
from pydantic import BaseModel, Field
from sklearn.metrics.pairwise import cosine_similarity

from ankillio.storage import ModelStorage

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
    action: str = "guiEditNote"
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

    async def request(self, r: BaseModel) -> BaseModel:
        async with aiohttp.ClientSession() as session:
            res = await session.post(self.host, json=r.model_dump())
            result = r.Response.model_validate(await res.json())
            if result.error:
                raise RuntimeError(result.error)
            return result

    async def search_cards(self, search: str) -> list[CardsResponse.Card]:
        ids_response: IdsResponse = await self.request(
            FindCardsRequest(
                params=FindCardsRequest.Params(query=search),
            )
        )
        ids = ids_response.result

        cards_response: CardsResponse = await self.request(
            CardsInfoRequest(params=CardsInfoRequest.Params(cards=ids))
        )
        return cards_response.result

    async def card_info(self, cardId: int) -> CardsResponse.Card | None:
        cards_response: CardsResponse = await self.request(
            CardsInfoRequest(params=CardsInfoRequest.Params(cards=[cardId]))
        )

        if cards_response.result:
            return cards_response.result[0]
        return None

    async def answer_cards(self, answers: list[AnswerCardEasing]) -> None:
        await self.request(
            AnswerCardsRequest(params=AnswerCardsRequest.Params(answers=answers))
        )

    async def gui_edit_note(self, note: int) -> None:
        await self.request(
            GuiEditNoteRequest(params=GuiEditNoteRequest.Params(note=note))
        )

    async def edit_cards(self, card: CardsResponse.Card) -> None:
        await self.request(
            GuiEditNoteRequest(params=GuiEditNoteRequest.Params(note=card.note))
        )

    async def remove_tags(self, card: CardsResponse.Card, tag: str) -> None:
        await self.request(
            RemoveTagsRequest(
                params=RemoveTagsRequest.Params(notes=[card.note], tag=tag)
            )
        )


class Embedded(BaseModel):
    card: CardsResponse.Card
    front_embedding: list[float] = Field(default_factory=list)
    back_embedding: list[float] = Field(default_factory=list)

    def needs_update(self, other: CardsResponse.Card) -> bool:
        return not self.front_embedding or self.card.mod < other.mod


class SyncState(BaseModel):
    last_date: datetime.date = Field(default_factory=lambda: datetime.date(2020, 1, 1))


async def sync(
    card_storage: ModelStorage[Embedded],
    client: Mistral,
) -> list[Embedded]:
    service = AnkiService()
    cards = await service.search_cards(f"deck:Language")
    needs_update: list[CardsResponse.Card] = []
    with_embedded: list[Embedded] = []
    for card in cards:
        existing = card_storage.load(card.cardId, lambda: Embedded(card=card))
        if existing.needs_update(card):
            needs_update.append(card)
        else:
            with_embedded.append(existing)

    if needs_update:
        print(f"needs_update {len(needs_update)}")
        for i in range(0, len(needs_update), 10):
            print("processing batch " + str(i))
            batch = needs_update[i : i + 10]
            response = await client.embeddings.create_async(
                model="mistral-embed",
                inputs=[
                    text
                    for card in batch
                    for text in (card.question[:6000], card.answer[:6000])
                ],
            )

            for (front, back), card in zip(
                [
                    (response.data[i].embedding, response.data[i + 1].embedding)
                    for i in range(0, len(response.data), 2)
                ],
                batch,
            ):
                embedded = Embedded(
                    card=card, front_embedding=front, back_embedding=back
                )
                card_storage.store(card.cardId, embedded)
                with_embedded.append(embedded)

    return with_embedded


async def query_similar(
    query: str, client: Mistral, embedded: list[Embedded]
) -> list[Embedded]:
    query_embedding = (
        (await client.embeddings.create_async(model="mistral-embed", inputs=[query]))
        .data[0]
        .embedding
    )

    similarities = cosine_similarity(
        [query_embedding],
        [
            embedding
            for e in embedded
            for embedding in (e.front_embedding, e.back_embedding)
        ],
    )
    top_indices = np.argsort(similarities[0])[::-1][:5]
    return [embedded[i] for i in set(i // 2 for i in top_indices)]
