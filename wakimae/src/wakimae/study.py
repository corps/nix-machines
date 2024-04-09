from typing import NewType

import pydantic
from pygments.lexers import math

# Space one:    subject mater, word relational.  (What am I picking / adding?)
#   Space one will drag back towards conserving space two?  Or time since add?
# Space two:    scheduled ordering relative to last visit  (What is pending?)
# Commit to 5 minutes or 1 minute.  Get something wrong?  -30 seconds.
# Path:
#   Given where you are in space one,
#   Pick three options:
#     The closest in space two (move towards it) &
#     The closest in space one (is adjusted by schedule) &
#     The closest in conserved space of one and two ()

Minutes = NewType("Minutes", int)


def from_time(time: float) -> Minutes:
    return Minutes(math.floor(time / 60))


def to_time(minutes: Minutes) -> float:
    return minutes * 60


class StudyItem(pydantic.BaseModel):
    path: str
    due_minutes: Minutes
    interval_minutes: Minutes
    content: str
    cloze_start: int
    cloze_end: int
    definition: str
