# NutriGuide — Health & Nutrition App

Production-ready Android health-nutrition app with an AI disease/nutrition
assistant.

- **Browse** (offline): organs & body systems → diseases → the natural foods
  and supplements research associates with each condition.
- **Assistant**: an AI chat that opens with a fixed greeting and answers
  questions about any disease — what it is, its causes, its harmful
  effects, and the world-known natural foods/supplements that may help.

## Repository layout

```
Health-Nutrition-App/
├── app/       # Flutter Android app (see app/README.md)
├── backend/   # FastAPI proxy to the Claude API (see backend/README.md)
├── docs/
│   ├── ARCHITECTURE.md          # architecture diagram + stack rationale
│   ├── DATA_SCHEMA.md           # knowledge-base schema & editorial policy
│   ├── STORE_LISTING.md         # store copy + screenshot plan
│   ├── PLAY_STORE_CHECKLIST.md  # full .aab → Play Store deployment guide
│   └── LEGAL/                   # disclaimer, privacy policy, terms
└── README.md
```

## Quick start

1. **Backend** — `cd backend && python -m venv .venv && ...` (full steps in
   `backend/README.md`); needs an Anthropic API key. Runs on port 8080.
2. **App** — `cd app && flutter create --platforms=android --org com.nutriguide --project-name nutriguide . && flutter pub get && flutter run`
   (the Android emulator reaches the local backend at `http://10.0.2.2:8080`).
3. **Ship** — follow `docs/PLAY_STORE_CHECKLIST.md`.

## Important

This app is **informational and educational only — not medical advice**.
See `docs/LEGAL/DISCLAIMER.md`.
