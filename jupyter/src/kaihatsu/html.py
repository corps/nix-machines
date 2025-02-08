import base64
import dataclasses
from dataclasses import dataclass, field
from html import escape

stack: "list[Tag]" = []


class Node:
    def render(self):
        raise NotImplemented


@dataclass
class TextNode(Node):
    text: str = ""

    def render(self):
        yield 0, escape(self.text)

    def __post_init__(self):
        if stack:
            stack[-1].children.append(self)


@dataclass
class Tag(Node):
    tag_name: str
    attributes: list[tuple[str, str | bool]] = field(default_factory=list)
    children: list[Node] = field(default_factory=list)
    closed: bool = True

    def __post_init__(self):
        if stack:
            stack[-1].children.append(self)

    def __enter__(self):
        stack.append(self)
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        stack.pop()

    def __call__(self, *cls: str, **kwargs: str | bool):
        if cls:
            kwargs["class"] = " ".join(cls)
        return dataclasses.replace(
            self,
            attributes=[*self.attributes, *((k, v) for k, v in kwargs.items())],
            children=[*self.children],
        )

    def render(self):
        buff = f"<{escape(self.tag_name)}"

        for attr_name, value in self.attributes:
            if value is False:
                continue
            if value is True:
                buff += f" {escape(attr_name)}"
            else:
                buff += f' {escape(attr_name)}="{escape(value, True)}"'

        if not self.children and self.closed:
            yield 0, buff + " />"
        else:
            yield 0, buff + ">"

        if self.children:
            for child in self.children:
                for indent, line in child.render():
                    yield indent + 1, line
            yield 0, f"</{escape(self.tag_name)}>"

    def _repr_html_(self):
        return "\n".join(("  " * indent) + line for indent, line in self.render())

    def __html__(self):
        return self._repr_html_()


@dataclasses.dataclass
class Html(Tag):
    tag_name: str = "html"

    def render(self):
        yield 0, "<!DOCTYPE html>"
        yield from super().render()


html = Html()
head = Tag(tag_name="head")
body = Tag(tag_name="body")
a = Tag(tag_name="a")
title = Tag(tag_name="title")
meta = Tag(tag_name="title", closed=False)
link = Tag(tag_name="link")
div = Tag(tag_name="div")
script = Tag(tag_name="script")
h1 = Tag(tag_name="h1")
h2 = Tag(tag_name="h2")
h3 = Tag(tag_name="h3")
h4 = Tag(tag_name="h4")
text = TextNode
p = Tag(tag_name="p")
br = Tag(tag_name="br")
img = Tag(tag_name="img")
ol = Tag(tag_name="ol")
li = Tag(tag_name="li")
style = Tag(tag_name="style")


def lines(s: str):
    for line in s.split("\n"):
        text(line.strip())
        br()


def data_url(fn: str, content_type: str) -> str:
    with open(fn, "rb") as f:
        encoded = base64.standard_b64encode(f.read()).decode("utf-8")
    return f"data:{content_type};base64,{encoded}"
