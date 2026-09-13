"""
NutriGuide backend — a thin, secured proxy between the Android app and the
Claude API.

Why a proxy exists at all:
  An LLM API key embedded in a mobile app is effectively public (APKs are
  trivially unpacked). The app talks only to this service; the
  ANTHROPIC_API_KEY never leaves the server.

Endpoints:
  GET  /health  — liveness probe (used by Cloud Run / load balancers)
  POST /v1/chat — disease & nutrition Q&A; streams the reply as SSE events
                  of the form:  data: {"delta": "..."}
                  terminating with:  data: {"done": true}
"""

from __future__ import annotations

import asyncio
import json
import logging
import os
import time
from collections import defaultdict, deque
from contextlib import asynccontextmanager
from typing import AsyncIterator

try:
    import anthropic  # type: ignore[import-not-found]
except ModuleNotFoundError:
    anthropic = None  # type: ignore[assignment]
try:
    from fastapi import FastAPI, Header, HTTPException, Request  # type: ignore[import-not-found]
    from fastapi.middleware.cors import CORSMiddleware  # type: ignore[import-not-found]
    from fastapi.responses import StreamingResponse  # type: ignore[import-not-found]
except ModuleNotFoundError as exc:
    if exc.name == "fastapi":
        raise RuntimeError(
            "FastAPI is not installed. Install the backend dependencies with "
            "`python -m pip install fastapi uvicorn anthropic`."
        ) from exc
    raise
from pydantic import BaseModel, Field

logger = logging.getLogger("nutriguide")
logging.basicConfig(level=os.getenv("LOG_LEVEL", "INFO"))

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

ANTHROPIC_MODEL = os.getenv("ANTHROPIC_MODEL", "claude-opus-5")
MAX_TOKENS = int(os.getenv("MAX_TOKENS", "4096"))

# Optional shared secret. If set, requests must send  X-App-Key: <value>.
APP_KEY = os.getenv("APP_KEY") or None

# Simple per-IP sliding-window rate limit (production: move to Redis).
RATE_LIMIT_REQUESTS = int(os.getenv("RATE_LIMIT_REQUESTS", "20"))
RATE_LIMIT_WINDOW_SECONDS = int(os.getenv("RATE_LIMIT_WINDOW_SECONDS", "60"))

# Conversation history the app is allowed to send (older turns are dropped —
# bounds token cost and keeps the request body small).
MAX_HISTORY_MESSAGES = int(os.getenv("MAX_HISTORY_MESSAGES", "20"))

ALLOWED_ORIGINS = [
    o.strip() for o in os.getenv("ALLOWED_ORIGINS", "*").split(",")
]

SYSTEM_PROMPT = """You are NutriGuide, a health-education assistant inside a \
nutrition app. You answer questions about human diseases affecting any organ \
or body system, and about the natural foods and supplements that research \
suggests may help heal, manage, or suppress their harmful effects.

Scope and style rules:
- Cover: what the disease is, its causes/risk factors, its harmful effects on \
the body, and the most appropriate world-known natural foods (raw or cooked) \
and food supplements studied for that condition.
- Ground nutritional claims in reputable sources: WHO, NIH (ODS, NCCIH, \
NIDDK, NEI), CDC, Cochrane reviews, and peer-reviewed nutrition research. \
Cite the source type by name (e.g. "NIH ODS magnesium fact sheet", "Cochrane \
review") where practical.
- This is general wellness and education information, NOT medical advice. \
Never diagnose, never prescribe, never give dosage instructions beyond \
published reference intakes. If a question needs a clinician (symptoms, \
medication interactions, pregnancy, pediatric, emergency symptoms), say so \
clearly and advise seeing a qualified healthcare professional.
- Food and supplement suggestions are supportive options, never a \
replacement for medical treatment. Mention interactions that matter \
(e.g. curcumin and blood thinners) briefly.
- If asked about something outside disease/nutrition/health, politely \
redirect to those topics.
- Prefer concise Markdown with short sections and bullet lists. If you don't \
know or evidence is weak, say so plainly.

When the conversation starts, the app itself already shows this exact \
greeting to the user, so do not repeat it; just answer the first question:
"Ask me what you want to know about any particular human disease and I will \
tell you everything about the disease, its cause, its harmful effects, and \
the most appropriate world-known natural food or food supplement that can \
cure or suppress it harmful effects."
"""


# ---------------------------------------------------------------------------
# Rate limiting (per-IP sliding window, in-memory)
# ---------------------------------------------------------------------------

class RateLimiter:
    def __init__(self, max_requests: int, window_seconds: int) -> None:
        self.max_requests = max_requests
        self.window = window_seconds
        self._hits: dict[str, deque[float]] = defaultdict(deque)
        self._lock = asyncio.Lock()

    async def check(self, key: str) -> bool:
        async with self._lock:
            now = time.monotonic()
            hits = self._hits[key]
            while hits and now - hits[0] > self.window:
                hits.popleft()
            if len(hits) >= self.max_requests:
                return False
            hits.append(now)
            return True


limiter = RateLimiter(RATE_LIMIT_REQUESTS, RATE_LIMIT_WINDOW_SECONDS)


# ---------------------------------------------------------------------------
# App setup
# ---------------------------------------------------------------------------

@asynccontextmanager
async def lifespan(_: FastAPI) -> AsyncIterator[None]:
    # Client resolves ANTHROPIC_API_KEY (or an `ant auth login` profile)
    # from the environment — never hardcode it here.
    yield


app = FastAPI(
    title="NutriGuide backend",
    version="1.0.0",
    description="Disease & nutrition Q&A proxy for the NutriGuide Android app.",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOWED_ORIGINS,
    allow_methods=["GET", "POST"],
    allow_headers=["*"],
)

client = anthropic.AsyncAnthropic() if anthropic is not None else None


class ChatTurn(BaseModel):
    role: str = Field(pattern="^(user|assistant)$")
    content: str = Field(min_length=1, max_length=8000)


class ChatRequest(BaseModel):
    messages: list[ChatTurn] = Field(min_length=1, max_length=MAX_HISTORY_MESSAGES)


def _client_key(request: Request, app_key: str | None) -> str:
    if app_key:
        return f"key:{app_key[:8]}"
    return f"ip:{request.client.host if request.client else 'unknown'}"


def _validate_messages(messages: list[ChatTurn]) -> list[dict]:
    """Drop trailing assistant turns and cap history; API needs user-first."""
    turns = [m.model_dump() for m in messages]
    while turns and turns[0]["role"] != "user":
        turns.pop(0)
    return turns[-MAX_HISTORY_MESSAGES:]


# ---------------------------------------------------------------------------
# Routes
# ---------------------------------------------------------------------------

@app.get("/health")
async def health() -> dict:
    return {"status": "ok", "model": ANTHROPIC_MODEL}


@app.post("/v1/chat")
async def chat(
    body: ChatRequest,
    request: Request,
    x_app_key: str | None = Header(default=None),
) -> StreamingResponse:
    if client is None:
        raise HTTPException(
            status_code=503,
            detail="Anthropic SDK is missing. Install it with: python -m pip install anthropic",
        )

    if APP_KEY is not None and x_app_key != APP_KEY:
        raise HTTPException(status_code=401, detail="Invalid or missing app key")

    key = _client_key(request, x_app_key)
    if not await limiter.check(key):
        raise HTTPException(
            status_code=429,
            detail="Rate limit exceeded. Please wait a moment and try again.",
        )

    messages = _validate_messages(body.messages)
    if not messages:
        raise HTTPException(status_code=400, detail="No user message found.")

    async def event_stream() -> AsyncIterator[bytes]:
        try:
            async with client.messages.stream(
                model=ANTHROPIC_MODEL,
                max_tokens=MAX_TOKENS,
                system=SYSTEM_PROMPT,
                thinking={"type": "adaptive"},
                messages=messages,
            ) as stream:
                async for text in stream.text_stream:
                    if text:
                        yield f"data: {json.dumps({'delta': text})}\n\n".encode()
            yield b"data: {\"done\": true}\n\n"
        except anthropic.RateLimitError:
            yield f"data: {json.dumps({'error': 'The assistant is busy right now. Please try again shortly.'})}\n\n".encode()
        except anthropic.APIStatusError as exc:
            logger.exception("Anthropic API error")
            yield f"data: {json.dumps({'error': f'Upstream error ({exc.status_code}).'})}\n\n".encode()
        except anthropic.APIConnectionError:
            yield f"data: {json.dumps({'error': 'Could not reach the assistant. Check your connection.'})}\n\n".encode()

    return StreamingResponse(
        event_stream(),
        media_type="text/event-stream",
        headers={"Cache-Control": "no-cache", "X-Accel-Buffering": "no"},
    )
