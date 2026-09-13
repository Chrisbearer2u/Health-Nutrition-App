"""Unit tests for the backend that run WITHOUT calling the Claude API."""

from __future__ import annotations

import json
from unittest.mock import AsyncMock, Mock, patch

import pytest
from fastapi.testclient import TestClient

import main


@pytest.fixture()
def api():
    main.APP_KEY = None  # disable app-key auth for tests
    with TestClient(main.app) as client:
        yield client


def test_health(api):
    res = api.get("/health")
    assert res.status_code == 200
    assert res.json()["status"] == "ok"


def test_chat_requires_messages(api):
    res = api.post("/v1/chat", json={"messages": []})
    assert res.status_code == 422  # pydantic: min_length=1


def test_chat_rejects_bad_role(api):
    res = api.post(
        "/v1/chat",
        json={"messages": [{"role": "system", "content": "hi"}]},
    )
    assert res.status_code == 422


def test_app_key_enforced():
    main.APP_KEY = "secret123"
    with TestClient(main.app) as client:
        res = client.post(
            "/v1/chat",
            json={"messages": [{"role": "user", "content": "hi"}]},
        )
        assert res.status_code == 401

        res = client.post(
            "/v1/chat",
            json={"messages": [{"role": "user", "content": "hi"}]},
            headers={"X-App-Key": "secret123"},
        )
        assert res.status_code == 200
    main.APP_KEY = None


def test_leading_assistant_turns_dropped():
    turns = [
        {"role": "assistant", "content": "greeting"},
        {"role": "user", "content": "question"},
    ]
    cleaned = main._validate_messages([main.ChatTurn(**t) for t in turns])
    assert cleaned == [{"role": "user", "content": "question"}]


def test_rate_limit(api):
    # Default limiter allows 20/60s; hammer it with more and expect a 429.
    payload = {"messages": [{"role": "user", "content": "hi"}]}
    statuses = [api.post("/v1/chat", json=payload).status_code for _ in range(25)]
    assert 429 in statuses


class _TextStream:
    """Async iterable standing in for anthropic's stream.text_stream."""

    def __init__(self, chunks):
        self._chunks = iter(chunks)

    def __aiter__(self):
        return self

    async def __anext__(self):
        try:
            return next(self._chunks)
        except StopIteration as exc:
            raise StopAsyncIteration from exc


class _StreamContext:
    """Async context manager standing in for client.messages.stream(...)."""

    def __init__(self, chunks):
        self.text_stream = _TextStream(chunks)

    async def __aenter__(self):
        return self

    async def __aexit__(self, *exc):
        return False


def test_chat_streams_sse(api):
    payload = {"messages": [{"role": "user", "content": "What helps the liver?"}]}
    # Bypass the rate limiter's sliding window filling up in earlier tests.
    with patch.object(main, "limiter") as fake_limiter, patch.object(
        main.client.messages, "stream", new=Mock(return_value=_StreamContext(["An ", "apple ", "a day."]))
    ):
        fake_limiter.check = AsyncMock(return_value=True)
        res = api.post("/v1/chat", json=payload)
    assert res.status_code == 200
    assert res.headers["content-type"].startswith("text/event-stream")

    events = [
        json.loads(line[len("data: "):])
        for line in res.text.splitlines()
        if line.startswith("data: ")
    ]
    assert {"delta": "An "} in events
    assert {"delta": "apple "} in events
    assert {"delta": "a day."} in events
    assert {"done": True} in events
