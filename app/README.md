# NutriGuide — Flutter app (Android)

Health & nutrition information app: browse the organ/disease/food knowledge
base offline, and ask an AI assistant about any disease, its causes, its
harmful effects, and the natural foods/supplements studied for it.

## Project structure

```
app/
├── lib/
│   ├── main.dart                    # entry point, providers, MaterialApp
│   ├── theme.dart                   # Material 3 theme
│   ├── models/models.dart           # Organ / Disease / Food / ChatMessage
│   ├── data/knowledge_repository.dart  # offline knowledge base loader
│   ├── services/chat_service.dart   # SSE client for the backend proxy
│   │                                #   + the fixed greeting constant
│   ├── state/chat_controller.dart   # conversation state (ChangeNotifier)
│   ├── screens/
│   │   ├── home_screen.dart         # 2-tab shell: Browse | Assistant
│   │   ├── browse_screen.dart       # (a) browse/search organs & diseases
│   │   ├── organ_detail_screen.dart # organ → foods + related diseases
│   │   ├── disease_detail_screen.dart # full disease entry + disclaimer
│   │   └── chat_screen.dart         # (b) AI chat, streamed Markdown
│   └── widgets/disclaimer_banner.dart  # in-app medical disclaimer
├── assets/data/                     # knowledge base (see docs/DATA_SCHEMA.md)
├── android/                         # signing, manifest, target SDK config
└── pubspec.yaml
```

## First-time setup

```bash
cd app

# Generates the remaining generated Android files (icons, styles, gradle
# wrapper) without overwriting anything already in this repo:
flutter create --platforms=android --org com.nutriguide --project-name nutriguide .

flutter pub get
flutter run   # chat expects the backend at http://10.0.2.2:8080 (emulator)
```

## Building the Play Store bundle (.aab)

```bash
# Release build against your deployed backend (see ../backend/README.md):
flutter build appbundle --release \
  --dart-define=API_BASE_URL=https://YOUR-CLOUD-RUN-URL \
  --dart-define=APP_KEY=YOUR_SHARED_SECRET

# Output:
# build/app/outputs/bundle/release/app-release.aab
```

Signing is configured in `android/app/build.gradle.kts`; put your upload
keystore details in `android/key.properties` (see
`android/key.properties.example` and `docs/PLAY_STORE_CHECKLIST.md`).

## Where things are configured

| What | Where |
|---|---|
| App ID / version | `pubspec.yaml` (`version: 1.0.0+1`), `android/app/build.gradle.kts` |
| Backend URL / app key | `--dart-define` at build time (see above) |
| Target/min SDK | `android/app/build.gradle.kts` (target 36, min 23) |
| The exact chat greeting | `lib/services/chat_service.dart` → `kAssistantGreeting` |
| Knowledge base content | `assets/data/*.json` |
| Permissions | `android/app/src/main/AndroidManifest.xml` (INTERNET only) |
| Launcher icon / brand art | `assets/branding/` — regenerate with `backend/.venv/Scripts/python tool/generate_assets.py`, apply with `dart run flutter_launcher_icons` |
