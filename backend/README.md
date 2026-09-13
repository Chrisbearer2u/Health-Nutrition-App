# NutriGuide Backend

FastAPI proxy between the NutriGuide Android app and the Claude API.
The app never holds LLM credentials — all model calls happen here.

## Local development

```bash
cd backend
python -m venv .venv
.venv/Scripts/pip install -r requirements.txt   # Windows
# source .venv/bin/activate && pip install -r requirements.txt  # macOS/Linux

cp .env.example .env    # then set ANTHROPIC_API_KEY
# On PowerShell: set ANTHROPIC_API_KEY=sk-ant-... before launching

.venv/Scripts/uvicorn main:app --reload --port 8080
```

The Flutter app's default `API_BASE_URL` is `http://10.0.2.2:8080`, which is
how the Android emulator reaches your machine's localhost.

## Tests

```bash
.venv/Scripts/python -m pytest tests/ -q
```

Tests mock the Anthropic client — no API key or network needed.

## Deploying to Google Cloud Run (recommended)

```bash
# One-time setup
gcloud auth login
gcloud config set project YOUR_PROJECT_ID
gcloud services enable run.googleapis.com cloudbuild.googleapis.com

# Deploy (Cloud Build builds the Dockerfile and pushes the image)
gcloud run deploy nutriguide-backend \
  --source . \
  --region us-central1 \
  --allow-unauthenticated \
  --set-env-vars ANTHROPIC_API_KEY=sk-ant-...,APP_KEY=GENERATE_ONE,ANTHROPIC_MODEL=claude-opus-5
```

Storing the secret properly (instead of plain `--set-env-vars`) for production:

```bash
echo -n "sk-ant-..." | gcloud secrets create anthropic-key --data-file=-
gcloud run deploy nutriguide-backend --source . --region us-central1 \
  --allow-unauthenticated \
  --set-secrets ANTHROPIC_API_KEY=anthropic-key:latest
```

Note the deployed URL (`https://nutriguide-backend-...-uc.a.run.app`) — the
app is built with it:

```bash
flutter build appbundle --release \
  --dart-define=API_BASE_URL=https://nutriguide-backend-xxxx-uc.a.run.app \
  --dart-define=APP_KEY=GENERATE_ONE
```

## Hardening notes before real production traffic

- Replace the in-memory rate limiter with Redis if you run >1 instance.
- Set `ALLOWED_ORIGINS` explicitly (mobile apps don't need CORS at all).
- Add Firebase App Check to bind the endpoint to your app only.
- Add billing caps/alerts in the Anthropic Console.
- Log request IDs for abuse investigation; never log full message bodies
  (privacy — your privacy policy promises not to retain chat content).
