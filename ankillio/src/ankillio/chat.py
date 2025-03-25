import dataclasses
import json
import os
from functools import cached_property
from typing import TypeVar

import dotenv
from mistralai import Mistral, models
from pydantic import BaseModel

dotenv.load_dotenv(dotenv.find_dotenv())
_B = TypeVar("_B", bound=BaseModel)


@dataclasses.dataclass
class Chat:
    system_prompt: str | None = None
    model: str = "open-mistral-nemo"
    max_tokens: int = 500
    messages: list[models.Messages] = dataclasses.field(default_factory=list)

    @cached_property
    def client(self) -> Mistral:
        return Mistral(os.environ["MISTRAL_API_KEY"])

    def __call__(self, message: str, tool: type[_B] | None = None) -> _B | str | None:
        message = message.strip()
        if not self.messages and self.system_prompt:
            self.messages.append({"role": "system", "content": self.system_prompt})

        self.messages.append(
            {
                "role": "user",
                "content": message,
            }
        )

        response = self.client.chat.complete(
            model=self.model,
            max_tokens=self.max_tokens,
            messages=self.messages,
            tools=(
                [
                    {
                        "type": "function",
                        "function": {
                            "name": tool.__name__.lower(),
                            "description": tool.__doc__,
                            "parameters": tool.model_json_schema(),
                        },
                    }
                ]
                if tool
                else None
            ),
            tool_choice="auto" if tool else None,
        )

        if response.choices:
            c = response.choices[0]
            if c.message.tool_calls:
                tc = c.message.tool_calls[0]
                return tool.model_validate(json.loads(tc.function.arguments))
            self.messages.append(c.message)
            return c.message.content
