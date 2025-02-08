import dataclasses
import json
import os
from functools import cached_property
from typing import Generic, TypeVar

import dotenv
from mistralai import Mistral
from pydantic import BaseModel

dotenv.load_dotenv(dotenv.find_dotenv())
_B = TypeVar("_B", bound=BaseModel)


@dataclasses.dataclass
class Chat(Generic[_B]):
    tool: type[_B] | None = None
    system_prompt: str | None = None
    model: str = "open-mistral-nemo"
    max_tokens: int = 500

    @cached_property
    def client(self) -> Mistral:
        return Mistral(os.environ["MISTRAL_AI_KEY"])

    def __call__(self, message: str) -> _B | None:
        messages = []
        message = message.strip()

        if self.system_prompt:
            messages.append(
                {
                    "role": "system",
                    "content": self.system_prompt,
                }
            )
        messages.append(
            {
                "role": "user",
                "content": message,
            }
        )

        response = self.client.chat.complete(
            model=self.model,
            max_tokens=self.max_tokens,
            messages=messages,
            tools=(
                [
                    {
                        "type": "function",
                        "function": {
                            "name": self.tool.__name__.lower(),
                            "description": self.tool.__doc__,
                            "parameters": self.tool.model_json_schema(),
                        },
                    }
                ]
                if self.tool
                else None
            ),
            tool_choice="auto" if self.tool else None,
        )

        if response.choices:
            c = response.choices[0]
            if c.message.tool_calls:
                tc = c.message.tool_calls[0]
                return self.tool.model_validate(json.loads(tc.function.arguments))
            return c.message.content
