# Google Play Store Deployment Checklist — NutriGuide

Complete, in order. (References current Play Console policy; re-verify
items marked ⚠ at upload time — Play policy is updated quarterly.)

## 1. Prerequisites

- [ ] Google Play Developer account ($25 one-time fee) —
      https://play.google.com/console
- [ ] D-U-N-S number if publishing as an organization (not needed for
      personal accounts)
- [ ] Flutter SDK installed (`flutter doctor` green) with Android toolchain
      (Android Studio + SDK 36 + JDK 17)
- [ ] Anthropic API key + deployed backend URL (see `backend/README.md`)
- [ ] A real domain or free host (GitHub Pages works) for Privacy Policy &
      Terms of Service URLs — Play requires a publicly reachable link

## 2. First-time project setup (one-off)

- [ ] `cd app && flutter create --platforms=android --org com.nutriguide --project-name nutriguide .`
      — generates the missing generated files (launcher icons, styles,
      gradle wrapper jar) without overwriting the files in this repo
- [ ] `flutter pub get`
- [ ] Run on device/emulator: `flutter run`
      (chat works against a local backend at `http://10.0.2.2:8080`)
- [ ] Apply the branded launcher icons (art already in `assets/branding/`):
      `dart run flutter_launcher_icons`
      (regenerate the art any time with
      `backend/.venv/Scripts/python tool/generate_assets.py`)

## 3. Signing keys

- [ ] Generate an upload keystore (Play App Signing recommended — Google
      holds the final app-signing key, you hold the upload key):
  ```bash
  keytool -genkey -v -keystore upload-keystore.jks \
    -keyalg RSA -keysize 2048 -validity 10000 -alias nutriguide-upload
  ```
- [ ] Copy `android/key.properties.example` → `android/key.properties` and
      fill in the real values (never commit it — already `.gitignore`d)
- [ ] Back up the keystore + passwords somewhere safe. **If you lose the
      upload key you must request a key reset from Google.**
- [ ] Enroll in **Play App Signing** when first creating the app in Console

## 4. Pre-release checks

- [ ] Version bumped in `app/pubspec.yaml` (`version: 1.0.0+1` — the `+N`
      is `versionCode`, must increase every upload)
- [ ] App built against your **production** backend URL (not 10.0.2.2):
  ```bash
  flutter build appbundle --release \
    --dart-define=API_BASE_URL=https://YOUR-CLOUD-RUN-URL \
    --dart-define=APP_KEY=YOUR_SHARED_SECRET
  ```
  Output: `app/build/app/outputs/bundle/release/app-release.aab`
- [ ] `flutter analyze` — no errors
- [ ] Test the `.aab` itself, not just a debug run:
  `flutter install` or upload to internal testing track first
- [ ] Offline behavior: Browse tab works with airplane mode on
- [ ] Greeting message displays **exactly** the required string on first
      chat open

## 5. Store listing assets

Copy-paste-ready text (title, descriptions, captions, reviewer notes) is in
**`docs/STORE_LISTING.md`**. Brand art is in `app/assets/branding/`.

- [ ] App name: ≤ 30 chars ("NutriGuide — Foods for Health")
- [ ] Short description: ≤ 80 chars
- [ ] Full description: ≤ 4000 chars (include the informational-only
      framing and key terms — health/wellness)
- [ ] App icon: 512×512 PNG, 32-bit
- [ ] Feature graphic: 1024×500 PNG/JPG
- [ ] Phone screenshots: minimum 2 (recommend 4–8), 16:9 or 9:16,
      min 320px, max 3840px
- [ ] 7-inch and 10-inch tablet screenshots (recommended; improves
      tablet listing quality)
- [ ] Contact email (required)

## 6. Policy declarations (Health app — this is where health apps get rejected)

- [ ] **App category:** Health & Fitness
- [ ] **Health apps declaration:** this app does NOT provide medical
      advice/diagnosis — it is educational. Answers the Play Console
      "Health apps" questionnaire accordingly (no diagnosis, no treatment
      recommendations, no clinical decision-making)
- [ ] **Data safety form**, answered truthfully for this app:
  - Data collected: **none** (chats are sent to our backend per-request,
    not stored; no accounts, no analytics SDKs in v1)
  - Data transmitted: chat text is transmitted (encrypted in transit) to
    generate responses — declare "App activity / other user-generated
    content" if you keep any logs; if you log nothing, declare no
    collection and make sure the backend truly doesn't persist
  - No data shared with third parties except the LLM API call needed to
    provide the feature
  - Data encrypted in transit: yes (HTTPS)
  - Users can request deletion: yes (support email; nothing is retained
    beyond request processing)
- [ ] **Privacy policy URL** live and matching the Data safety answers
      (template: `docs/LEGAL/PRIVACY_POLICY.md`)
- [ ] **Health disclaimer** visible in-app (it is: banner on Browse, Chat,
      and every disease detail screen)
- [ ] Content rating questionnaire completed (expect "Everyone" or low
      maturity — educational content)
- [ ] Target audience: 13+ (avoid declaring a child audience — COPPA/Play
      Families policy adds heavy requirements)
- [ ] ⚠ **AI-generated content**: current Play policy requires declaring
      AI features and showing disclosures — add "Responses are
      AI-generated and may be inaccurate" near the chat UI (already in
      the disclaimer banner) and answer the AI disclosure questions in
      Console honestly
- [ ] Export compliance: app uses standard HTTPS — declare that it does
      not use encryption beyond standard, or complete the simplified
      encryption report
- [ ] Ads declaration: no ads (or declare ad SDKs accurately if added)

## 7. Technical requirements

- [ ] ⚠ Target API level within Google's current window (build files set
      `targetSdk = 36`; Play requires targeting a recent API level —
      check the current minimum at upload time)
- [ ] 64-bit support (Flutter default: yes)
- [ ] App Bundle (.aab) upload — APKs no longer accepted for new apps
- [ ] Android App Bundle size < 200 MB (NutriGuide is a few MB)
- [ ] No `INTERNET` permission surprises — the manifest requests only
      `android.permission.INTERNET`

## 8. Release

- [ ] Create app in Play Console → set defaults → upload `.aab` to
      **Internal testing** track first
- [ ] Install from the internal test link on a real device; verify chat,
      browse, greeting, disclaimer
- [ ] Complete the staged rollout: Internal → Closed → Open testing →
      Production (new personal accounts are limited to ~20 testers for
      the first 14 days before production access — plan for this)
- [ ] Production release: start with a small % staged rollout (e.g. 10%),
      watch crash reporting, then ramp
- [ ] Post-release: monitor Play Console pre-launch report, ANRs/crashes,
      and backend logs for abuse

## Common rejection reasons for apps like this (avoid)

1. **Missing/mismatched privacy policy** — must be reachable and match the
   Data safety form exactly.
2. **Data safety form false negatives** — "no data collected" while logs
   persist somewhere. Whatever the backend logs, the form must declare.
3. **Health claims too strong** — "cures X" in the listing or screenshots.
   Use "supports", "studied for", "may help".
4. **AI disclosure missing** — Play increasingly requires in-app
   disclosure for generative AI features.
5. **Broken backend at review time** — reviewers test the chat; make sure
   the Cloud Run service is deployed and the rate limiter isn't blocking
   Google's IP ranges.
