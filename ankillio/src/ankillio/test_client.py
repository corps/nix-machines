import time
from uuid import uuid4

import requests
from bs4 import BeautifulSoup, Tag
from pydantic import BaseModel, Field


class TestClient(BaseModel):
    server: str = "http://127.0.0.1:5000"
    call_sid: str = Field(default_factory=lambda: uuid4().hex)

    def make_call(self, speech_result: str | None):
        response = requests.post(
            self.server + "/handle_call",
            dict(
                From="+14158168826", SpeechResult=speech_result, CallSid=self.call_sid
            ),
        )

        if response.status_code != 200:
            raise Exception(f"HTTP Response: {response.status_code}")

        soup = BeautifulSoup(response.text, "xml")
        r = soup.find("Response")
        assert r, response.text
        for child in r.children:
            if not isinstance(child, Tag):
                continue
            if child.name == "Say":
                print(child.text)
            if child.name == "Pause":
                time.sleep(int(child.attrs["length"]) / 1000)
            if child.name == "Gather":
                for child in child.children:
                    if not isinstance(child, Tag):
                        continue
                    if child.name == "Say":
                        print(child.text)
                    if child.name == "Pause":
                        time.sleep(int(child.attrs["length"]) / 1000)
                gathered = input().strip()
                if not gathered:
                    continue
                else:
                    self.make_call(gathered)
                    break


if __name__ == "__main__":
    TestClient().make_call(None)
