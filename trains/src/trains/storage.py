import dataclasses
from typing import Any, Callable, Generic, MutableMapping, TypeVar

from pydantic import BaseModel, ValidationError

_T = TypeVar("_T", bound=BaseModel)


@dataclasses.dataclass
class ModelStorage(Generic[_T]):
    prefix: str
    t: type[_T]
    storage: MutableMapping[str, Any]

    def store(self, identifier: Any, t: _T):
        self.storage[f"{self.prefix}{identifier}"] = t.model_dump(mode="json")

    def load(self, identifier: Any, failure: Callable[[], None]) -> _T | None:
        v = self.storage.get(f"{self.prefix}{identifier}", None)
        if v is None:
            return v
        try:
            return self.t.model_validate(v)
        except ValidationError:
            failure()
            return None
