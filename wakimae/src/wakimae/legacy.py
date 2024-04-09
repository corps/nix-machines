import dataclasses
import enum
import json
import random
from typing import Callable

import pydantic


class LegacySchedule(pydantic.BaseModel):
    lastAnsweredMinutes: int = 0
    nextDueMinutes: int = 0
    delayIntervalMinutes: int | None = 0
    intervalMinutes: int = 0
    isNew: bool = True


class LegacyClozeType(enum.Enum):
    PRODUCE = "produce"
    RECOGNIZE = "recognize"
    LISTEN = "listen"
    SPEAK = "speak"
    FLASH = "flash"


class LegacyClozeAttributes(pydantic.BaseModel):
    type: LegacyClozeType = LegacyClozeType.PRODUCE
    clozed: str = ""
    schedule: LegacySchedule = pydantic.Field(default_factory=LegacySchedule)


class LegacyCloze(pydantic.BaseModel):
    attributes: LegacyClozeAttributes = pydantic.Field(
        default_factory=LegacyClozeAttributes
    )


class LegacyTermAttributes(pydantic.BaseModel):
    reference: str = ""
    marker: str = ""
    pronounce: str = ""
    definition: str = ""
    hint: str = ""
    related: list[str] | None = None
    imageFilePaths: list[str] | None = None
    audioStart: float | None = None
    audioEnd: float | None = None
    url: str | None = None
    clozes: list[LegacyCloze] = pydantic.Field(default_factory=list)


class LegacyTerm(pydantic.BaseModel):
    attributes: LegacyTermAttributes = pydantic.Field(
        default_factory=LegacyTermAttributes
    )


class LegacyNoteAttributes(pydantic.BaseModel):
    content: str = ""
    language: str = ""
    editsComplete: bool = False
    studyGuide: bool = False
    shareAudio: bool = False
    audioFileId: str | None = None
    imageFilePaths: list[str] | None = None
    tags: list[str] = pydantic.Field(default_factory=list)
    terms: list[LegacyTerm] = pydantic.Field(default_factory=list)


class LegacyNote(pydantic.BaseModel):
    attributes: LegacyNoteAttributes = pydantic.Field(
        default_factory=LegacyNoteAttributes
    )


def parse_note(note: str) -> LegacyNote:
    content, attributes = note.split("\n===\n")
    attributes = LegacyNoteAttributes.model_validate(json.loads(attributes))
    attributes.content = content
    return LegacyNote(attributes=attributes)


@dataclasses.dataclass
class LegacyScheduler:
    entropy_source: Callable[[], float] = dataclasses.field(
        default_factory=lambda: random.random
    )


def schedule_legacy(now_minutes: int, note: LegacyNote) -> float:
    return min(
        [
            min(
                [
                    now_minutes - cloze.attributes.schedule.nextDueMinutes
                    if now_minutes > cloze.attributes.schedule.nextDueMinutes
                    else cloze.attributes.schedule.nextDueMinutes
                    for cloze in term.attributes.clozes
                ]
            )
            for term in note.attributes.terms
        ]
    )
