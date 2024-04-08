# import datetime
# import hashlib
# import uuid
# from typing import cast
#
# import aiohttp.web
# import pydantic
#
# from wakimae.login import TokenAuthorizationResponse, TokenRequest
#
# class AccessToken(pydantic.BaseModel):
#     authorization_token: str = pydantic.Field(default_factory=lambda: uuid.uuid4().hex)
#     access_token: str = pydantic.Field(default_factory=lambda: uuid.uuid4().hex)
#     refresh_token: str = pydantic.Field(default_factory=lambda: uuid.uuid4().hex)
#     expires_at: datetime.datetime = pydantic.Field(default_factory=lambda: datetime.datetime.utcnow() + datetime.timedelta(minutes=10))
#
# tokens_by_refresh_token: dict[str, AccessToken] = {}
# used_authorization_codes: set[str] = set()
#
# async def handle_oauth_token(request: aiohttp.web.Request):
#     post = cast(TokenRequest, await request.post())
#     if post['grant_type'] == "authorization_code":
#         if post['code'] in used_authorization_codes:
#             return aiohttp.web.Response(status=401)
#
#
#         return aiohttp.web.json_response(TokenAuthorizationResponse(
#             access_token=
#         ).model_dump(mode='json'))
#
# def create_server(port: int):
#     app = aiohttp.web.Application()
#     app.add_routes([
#         aiohttp.web.post("/oauth2/token", handle_oauth_token)
#     ])
#     aiohttp.web.run_app(app, port=port)
#
# if __name__ == "__main__":
#     import sys
#     port = int(sys.argv[1])
#     create_server(port, *dropbox_handlers)
