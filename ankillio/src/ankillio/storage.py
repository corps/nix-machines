import dataclasses
import json
import os.path
from typing import Any, Callable, Generic, MutableMapping, TypeVar

from pydantic import BaseModel, ValidationError

_T = TypeVar("_T", bound=BaseModel)


class PerFileStorage(MutableMapping[str, Any]):
    def path(self, k: str):
        return os.path.join(os.path.dirname(__file__), ".nicegui", f"{k}.json")

    def __setitem__(self, key, value, /):
        with open(self.path(key), "w") as f:
            f.write(json.dumps(value))

    def __delitem__(self, key, /):
        os.remove(self.path(key))

    def __getitem__(self, key, /):
        if os.path.exists(self.path(key)) is False:
            return None
        with open(self.path(key), "r") as f:
            return json.loads(f.read())

    def __len__(self):
        return 0

    def __iter__(self):
        return iter([])


@dataclasses.dataclass
class ModelStorage(Generic[_T]):
    prefix: str
    t: type[_T]
    storage: MutableMapping[str, Any]

    def store(self, identifier: Any, t: _T):
        self.storage[f"{self.prefix}{identifier}"] = t.model_dump(mode="json")

    def load(self, identifier: Any, default: Callable[[], _T]) -> _T:
        v = self.storage.get(f"{self.prefix}{identifier}", None)
        if v is None:
            return default()
        try:
            return self.t.model_validate(v)
        except ValidationError:
            return default()
