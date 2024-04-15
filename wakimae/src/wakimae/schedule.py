import dataclasses
import datetime
import math
import random
import re
import time
from typing import Iterable, NewType

import pydantic
from sqlalchemy import delete, select

from wakimae.db import AsyncSession, File, Scheduled, User
from wakimae.store import Store

Minutes = NewType("Minutes", int)


def from_time(time: float) -> Minutes:
    return Minutes(math.floor(time / 60))


def to_time(minutes: Minutes) -> float:
    return minutes * 60


class StudyCloze(pydantic.BaseModel):
    cloze_start: int
    cloze_end: int
    definition: str


class StudyItem(pydantic.BaseModel):
    path: str = ""
    due_minutes: Minutes = Minutes(0)
    interval_minutes: Minutes = Minutes(0)
    last_answered: Minutes = Minutes(0)
    last_answered_correct: bool = False
    content: str = ""
    clozes: list[StudyCloze] = pydantic.Field(default_factory=list)

    def search_chunks(self) -> Iterable[str]:
        yield self.content

        for cloze in self.clozes:
            left_side = self.content[: cloze.cloze_start]
            left_side_grab = min(50, len(left_side))
            partial_left_side = left_side[(len(left_side) - left_side_grab) :]
            unused_left = left_side[: len(left_side) - len(partial_left_side)]
            left_match = head_not_divisible_re.match(unused_left)
            if left_match:
                left_side_idx = left_match.pos
            else:
                left_side_idx = 0

            right_side = self.content[cloze.cloze_end :]
            unused_right = right_side[50:]
            right_match = tail_not_divisible_re.match(unused_right)
            if right_match:
                right_side_idx = cloze.cloze_end + right_match.pos
            else:
                right_side_idx = cloze.cloze_end + len(unused_right)

            yield self.content[left_side_idx:right_side_idx]

    def answer(self, correct: bool):
        if correct != self.last_answered_correct:
            self.last_answered = from_time(time.time())
            self.interval_minutes = Minutes(0)
            self.due_minutes = Minutes(0)
            self.last_answered_correct = correct

        self.schedule(2, from_time(time.time()))

    def schedule(self, factor: float, answered_at: Minutes):
        i = self.next_interval(factor, answered_at)
        self.last_answered = answered_at
        self.interval_minutes = i
        self.due_minutes = Minutes(self.last_answered + i)

    def next_interval(self, factor: float, answered: Minutes) -> Minutes:
        base_factor = min(factor, 1.0)
        bonus_factor = max(0.0, factor - 1.0)
        random_factor = random.random() * 0.9 + 0.2
        current_interval = Minutes(max(self.interval_minutes, Minutes(60 * 24)))
        answered_interval = answered - self.last_answered
        early_answer_multiplier = min(1.0, answered_interval / current_interval)
        early_answer_multiplier = 1 - math.sin(
            (math.pi / 2) * (1 - early_answer_multiplier)
        )

        effective_factor = (
            base_factor + bonus_factor * early_answer_multiplier * random_factor
        )
        return Minutes(math.floor(max(current_interval * effective_factor, 60 * 24)))


def is_study_item(path: str):
    return path.startswith("/wakimae/") and path.endswith(".json")


divisible = [
    "。",
    "︒",
    "﹒",
    "．",
    "｡",
    "𖫵",
    "𛲟",
    ".",
    "։",
    "۔",
    "܁",
    "܂",
    "።",
    "᙮",
    "\n",
    "?",
    "!",
    ";",
    "᥅",
    "⁇",
    "⁈",
    "⁉",
    "︖",
    "﹖",
    "？",
    "‼",
    "︕",
    "﹗",
    "！",
    "、",
    ",",
    ".",
]


tail_not_divisible_re = re.compile("[^" + "|".join(divisible) + "]*$")
head_not_divisible_re = re.compile("^[^" + "|".join(divisible) + "]*")


@dataclasses.dataclass
class ScheduleStore:
    user: User

    async def update_schedule(self, store: Store, file: File):
        async with AsyncSession() as session:
            await session.execute(
                delete(Scheduled).filter(Scheduled.file_id == file.id)
            )

            if not file.deleted and is_study_item(file.path):
                with open(store.content_path(file), "rb") as f:
                    study_item = StudyItem.model_validate_json(f.read())
                session.add(
                    Scheduled(
                        file_id=file.id,
                        schedule=study_item.due_minutes,
                        user_id=self.user.id,
                    )
                )

            await session.commit()

    async def find_next_already_due(self, now_minutes: Minutes) -> Scheduled | None:
        async with AsyncSession() as session:
            return await session.scalar(
                select(Scheduled)
                .filter(
                    Scheduled.user_id == self.user.id,
                    Scheduled.schedule <= int(now_minutes),
                )
                .order_by(Scheduled.schedule.desc())
                .limit(1)
            )

    async def find_next_soon_due(self, now_minutes: Minutes) -> Scheduled | None:
        async with AsyncSession() as session:
            return await session.scalar(
                select(Scheduled)
                .filter(
                    Scheduled.user_id == self.user.id,
                    Scheduled.schedule > int(now_minutes),
                )
                .order_by(Scheduled.schedule.asc())
                .limit(1)
            )
