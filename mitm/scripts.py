from mitmproxy import http


def forward_to(flow: http.HTTPFlow, to: str):
    flow.response = http.Response.make(
        307,
        b"Temporarily Moved",
        {
            b"Location": to.encode(),
        },
    )


def request(flow: http.HTTPFlow):
    if flow.request.pretty_host in (
        "www.reddit.com",
        "reddit.com",
        "news.jchk.net",
        "jchk.net",
    ):
        forward_to(flow, "https://miniflux.kaihatsu.io")
    if flow.request.pretty_host in ("awful.systems",):
        forward_to(flow, "https://miniflux.kaihatsu.io")
    if flow.request.pretty_host in ("politico.com",):
        forward_to(flow, "https://b.hatena.ne.jp")
