from functools import cached_property

from nicegui import app
from pydantic import BaseModel, Field

from sheets.storage import ModelStorage


class CharacterSheet(BaseModel):
    last_form: dict[str, str] = Field(default_factory=dict)
    edits: dict[str, str] = Field(default_factory=dict)

    @cached_property
    def next_form(self) -> dict[str, str]:
        return {}

    def complete_form(self):
        for k in list(self.edits.keys()):
            if k in self.last_form and k not in self.next_form:
                del self.edits[k]
        self.last_form = self.next_form.copy()
        self.next_form.clear()


sheet_storage = ModelStorage("sheet_", CharacterSheet, app.storage.general)
