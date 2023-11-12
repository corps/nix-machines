import os

from ctransformers import AutoModelForCausalLM

llm = AutoModelForCausalLM.from_pretrained(
    os.environ["MODEL"], model_file=os.environ["MODEL_FILE"], hf=True, model_type="mistral", gpu_layers=0
)

from flask import Flask, make_response, request

app = Flask(__name__)


@app.route("/")
def complete():
    request_data = request.get_json(force=True)
    return make_response(dict(result=_do_completion(request_data)))


def _do_completion(data):
    return llm(
        data.get("prompt"),
        max_new_tokens=data.get("max_new_tokens", 255),
        temperature=data.get("temperature", 0.8),
        stop=data.get("stop", [".", "\n", "。"]),
    )


if __name__ == "__main__":
    # app.run(port=8000)
    print(_do_completion(dict(prompt="Hello world!  What should you say?")))
