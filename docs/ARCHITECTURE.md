# NutriGuide — Architecture

## High-level architecture

```
┌────────────────────────────────────────────────────────────────────┐
│                        ANDROID APP (Flutter)                       │
│                                                                    │
│  ┌──────────────┐   ┌───────────────┐   ┌──────────────────────┐   │
│  │  Browse tab  │   │ Assistant tab │   │  Legal / About       │   │
│  │  (offline)   │   │  (chat UI)    │   │  Disclaimer, Privacy │   │
│  └──────┬───────┘   └───────┬───────┘   └──────────────────────┘   │
│         │                   │                                      │
│  ┌──────▼────────────┐   ┌──▼─────────────────┐                    │
│  │ KnowledgeRepo     │   │ ChatController     │                    │
│  │ (assets/data/*.   │   │ (state, streaming  │                    │
│  │  json, bundled)   │   │  SSE parsing)      │                    │
│  └──────┬────────────┘   └──┬─────────────────┘                    │
│         │ no network          │ HTTPS only                          │
│         │ (works offline)     │ POST /v1/chat                       │
└─────────┼─────────────────────┼──────────────────────────────────────┘
          │                     │
          │            ┌────────▼─────────────────────────────┐
          │            │     BACKEND PROXY (Cloud Run)        │
          │            │     FastAPI, 1 container, no state   │
          │            │  ┌────────────────────────────────┐  │
          │            │  │ Auth (X-App-Key) + rate limit  │  │
          │            │  │ Input validation (Pydantic)    │  │
          │            │  │ Medical-safety system prompt   │  │
          │            │  │ History truncation             │  │
          │            │  └───────────────┬────────────────┘  │
          │            └──────────────────┼───────────────────┘
          │                               │ Anthropic SDK (server-side key)
          │                    ┌──────────▼──────────┐
          │                    │   Claude API        │
          │                    │   (Messages API,    │
          │                    │    streaming)       │
          │                    └─────────────────────┘
          │
   ┌──────▼──────────────┐
   │ Bundled JSON assets │      ← regenerated from any CMS/DB
   │ organs / diseases / │        without touching app code
   │ foods               │
   └─────────────────────┘
```

## Tech stack & justification

| Layer | Choice | Why |
|---|---|---|
| Mobile platform | **Flutter (Dart)** | Single codebase with true native performance; Material 3 widgets give an accessible health-app UI almost for free; first-class Android App Bundle tooling (`flutter build appbundle` + Play upload); same code can ship to iOS later. |
| State management | **provider** (ChangeNotifier) | Deliberately minimal — the app has two screens and one controller; Riverpod/BLoC would add ceremony without benefit at this scale. |
| LLM | **Claude API** (`claude-opus-5`, Messages API, streaming) | Strong instruction-following for the scoped medical-education system prompt; streaming keeps perceived latency low; adaptive reasoning suits multi-part answers (description → causes → effects → foods). |
| LLM access | **Backend proxy** (FastAPI on Cloud Run) | An API key inside an APK is public knowledge — the proxy keeps credentials server-side, enforces the safety system prompt server-side (prompt can't be tampered with by a modified client), and enables rate limiting/abuse control. |
| Data layer | **Bundled JSON assets** | Zero-latency, fully offline browse experience; simple to regenerate/expand; trivially portable to a remote CMS + cache later. Schema documented in `docs/DATA_SCHEMA.md`. |
| Deployment | **Google Cloud Run** | Scale-to-zero (idle costs ~$0), managed TLS, secret manager integration, container portability. |

## Design decisions worth knowing

1. **The greeting is rendered client-side, exactly.** The exact required
   greeting string lives in `app/lib/services/chat_service.dart`
   (`kAssistantGreeting`) and is displayed by `ChatController.ensureGreeting()`
   before any network call, so it is byte-for-byte identical on every launch
   and even offline. The server-side system prompt tells the model not to
   repeat it.
2. **The safety prompt runs server-side.** Even a decompiled/modified app
   cannot remove the medical-safety instructions — they're injected in the
   proxy on every request.
3. **Browse is offline-first.** All knowledge-base content is bundled; only
   the chat needs connectivity.
4. **Prompt caching opportunity.** The system prompt is static, so it's
   eligible for Anthropic prompt caching (add `cache_control` when traffic
   justifies it).
