import dataclasses
import enum
import logging
import os
from typing import Generator

from attr import dataclass
from bs4 import BeautifulSoup
from dotenv import load_dotenv
from flask import Flask, Response, request
from pydantic import BaseModel
from twilio.request_validator import RequestValidator
from twilio.twiml.voice_response import Gather, VoiceResponse
from werkzeug.exceptions import Unauthorized

from ankillio.anki import StudyItems, SyncRequest, SyncResponse
from ankillio.chat import Chat

load_dotenv()
app = Flask(__name__)


class YesNo(BaseModel):
    answer_yes: bool

    def __bool__(self):
        return self.answer_yes


class StudyContinueChoice(enum.Enum):
    Continue = "Continue"
    Stop = "Stop"
    Wait = "Wait"
    Unsure = "Unsure"


def script():
    study_items = load_study()
    chat = Chat()
    while (card := study_items.find_next()) is not None:
        soup = BeautifulSoup(card.question, "html.parser")
        card_text = soup.get_text()
        response = VoiceResponse()
        response.say("次の文書を読み上げますね", language="ja-JP")
        response.pause(1)
        gather: Gather = response.gather(timeout=60, language="ja-JP")
        for i in range(3):
            gather.say(card_text)
            gather.pause(2 ** (i + 1))
        gather.say("いかがでしょうか？", language="ja-JP")
        reply = yield response
        if chat(f"次の返事は肯定ですか？\n{reply}", YesNo):
            study_items.answer(card, 3)
        else:
            study_items.answer(card, 0)
        write_study(study_items)

    response = VoiceResponse()
    response.say(
        "この以上のスケジュールされている課題はありまません．失礼しいます．",
        language="ja-JP",
    )
    return response


@dataclass
class State:
    call_id: str
    script: Generator


state = State("", script())


@app.route("/handle_call", methods=["GET", "POST"])
def handle_call():
    if (auth_token := os.environ.get("TWILIO_AUTH_TOKEN")) is not None:
        validator = RequestValidator(auth_token)
        # Extract the necessary parameters from the request
        signature = request.headers.get("X-Twilio-Signature", "")
        params = request.args if request.method == "GET" else request.form
        request.scheme = "https"  # this is http due to proxy, force it
        if not validator.validate(request.url, params, signature):
            raise Unauthorized()

    global state
    resp = VoiceResponse()
    if request.values.get("From") != "+14158168826":
        resp.say("Sorry, this service is not available in your location.  Goodbye.")
        return str(resp)

    last_speech_result = request.values.get("SpeechResult", None)
    if (call_sid := request.values.get("CallSid")) != state.call_id:
        last_speech_result = None
    if last_speech_result is None:
        state = State(call_sid, script())

    try:
        resp = state.script.send(last_speech_result)
    except StopIteration as e:
        if e.value:
            resp = e.value
    return Response(str(resp), content_type="application/xml")


study_data_path = os.environ.get("STUDY_DATA_PATH", "study.json")


def load_study() -> StudyItems:
    if os.path.exists(study_data_path):
        return StudyItems.model_validate_json(open(study_data_path, "rb").read())
    return StudyItems(cards=[], studied=[])


def write_study(items: StudyItems):
    open(study_data_path, "wb").write(items.model_dump_json().encode("utf-8"))


@app.route("/sync", methods=["PUT"])
def sync():
    if request.headers.get("Authorization", "") != os.environ["TWILIO_AUTH_TOKEN"]:
        raise Unauthorized()
    items = load_study()
    seen_ids = set(c.cardId for c in items.studied) | set(c.cardId for c in items.cards)
    req = SyncRequest.model_validate(request.get_json(True))

    requested_ids = set()
    for card in req.cards:
        requested_ids.add(card.cardId)
        if card.cardId not in seen_ids:
            items.cards.append(card)

    items.cards = [c for c in items.cards if c.cardId in requested_ids]
    items.studied = [s for s in items.studied if s.cardId in requested_ids]

    res = SyncResponse(studied=items.studied)
    write_study(items)
    return Response(res.model_dump_json(), mimetype="application/json")


if __name__ == "__main__":
    app.logger.setLevel(logging.DEBUG)
    app.run(host="0.0.0.0", port=5000)
