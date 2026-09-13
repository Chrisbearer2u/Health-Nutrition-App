# NutriGuide — Play Store Listing Copy & Screenshot Plan

Everything needed for the Store listing tab in Play Console. Character
limits are noted — respect them exactly (Play rejects overruns).

## App identity

| Field | Value | Limit |
|---|---|---|
| App name | `NutriGuide — Foods for Health` | 30 |
| Package | `com.nutriguide.app` | — |
| Category | Health & Fitness | — |
| Contact email | `support@yourdomain.com` | — |

## Short description (≤ 80 chars)

> Discover foods & supplements that support each organ — ask AI about any disease.

(exactly 80 characters — at the limit; trim to 78 by dropping "any" if
Play Console counts differently)

## Full description (≤ 4,000 chars)

> **NutriGuide — learn which natural foods and supplements support every part of your body.**
>
> NutriGuide is a health and nutrition education app with two simple sections:
>
> **1. Browse by organ & body system**
> Explore the heart, brain, liver, kidneys, lungs, gut, pancreas, bones and joints, skin, eyes, thyroid, and immune system. For each organ, see:
> • What it does, in plain language
> • Foods and supplements that research links to its health
> • Related diseases and conditions with their causes and harmful effects
>
> Each disease entry explains what the condition is, its known causes and risk factors, its effects on the body if unmanaged, and the world-known natural foods (raw or cooked) and food supplements studied for it — with sources from WHO, NIH, Cochrane reviews, and peer-reviewed nutrition research.
>
> **2. Ask the AI Health Assistant**
> Open the assistant and ask about any disease affecting any part of the body. You'll get a clear, structured answer: what the disease is, what causes it, its harmful effects, and the most appropriate well-known natural foods or supplements that may help heal, manage, or suppress those effects. Answers are for education and general wellness only.
>
> **Highlights**
> • Works offline — the full organ, disease, and food database is built in
> • 26 conditions across 12 organs and body systems
> • 40 foods and supplements with key nutrients and practical notes
> • AI chat with streamed, structured answers
> • Dark mode and accessibility support
> • No account needed, no ads, no tracking
>
> **Who it's for**
> Anyone curious about nutrition and how food supports the body — students, fitness enthusiasts, caregivers, and anyone who wants evidence-based food knowledge at their fingertips.
>
> **Important disclaimer**
> NutriGuide is an informational and educational resource only. It does not provide medical advice, diagnosis, or treatment. Always consult a qualified healthcare professional before making changes to your diet, taking supplements, or if you may have a medical condition. Never delay or disregard professional medical advice because of anything you read in this app. AI-generated responses may contain errors.

(~2,150 characters — room to add localized keywords later.)

## Feature graphic (1024×500)

Already generated: `app/assets/branding/feature-graphic.png` — brand-green
gradient, heart-with-leaf emblem left, "NutriGuide" wordmark and tagline
"Foods & supplements that support every organ of your body" right.

## App icon

512×512 store icon: `app/assets/branding/icon-512.png`. In-app launcher
icons are generated from `icon.png` via `dart run flutter_launcher_icons`.

## Phone screenshots — 6 shots (16:9 or 9:16, min 320px, max 3840px)

Capture on a Pixel 7/8 emulator (or equivalent, 1080×2400) in **dark mode**,
system language English. Take with the emulator screenshot button or
`adb exec-out screencap -p > shot1.png`.

| # | Screen to capture | How to stage it | Suggested caption overlay (top of screenshot) |
|---|---|---|---|
| 1 | Browse tab (organs list) | Fresh install, first screen. Shows search bar, disclaimer line, 4-5 organ cards visible | "Explore foods by organ & body system" |
| 2 | Search with results | Type "liver" — shows the search dropdown with organ + disease hits | "Search any organ or condition" |
| 3 | Organ detail (Heart) | Tap Heart & Blood Vessels — shows supporting foods + related diseases | "What supports your heart" |
| 4 | Disease detail (Hypertension) | Tap High blood pressure — description + causes visible, scroll so "Natural foods that may help" section shows | "Causes, effects & helpful foods" |
| 5 | Chat greeting | Open Assistant tab — the exact greeting bubble visible | "Ask about any disease" |
| 6 | Chat answer | Ask "What foods help with high blood pressure?" — show a streamed answer with food list visible | "Evidence-based food guidance" |

Caption style: white bold text (~64px) on a semi-transparent dark strip at
the top of each screenshot, or captions added above the screenshot on a
1200×2200 canvas with the screenshot below — pick one style for all 6.
Keep captions consistent with the disclaimer tone (no "cures" claims).

## Tablet screenshots (optional but recommended)

Reuse shots 1, 3, 4, 6 captured on a Pixel Tablet emulator (1600×2560).

## What's new (v1.0.0)

> Initial release: browse 12 organs and body systems, 26 conditions, 40 foods
> and supplements, and the AI health assistant.

## Reviewer notes (paste into "App access" / review notes in Console)

> No credentials needed — the entire app is accessible on launch.
> The AI Assistant tab requires our backend to be reachable; it is live at
> the URL baked into this build. The Browse tab is fully offline.
> The app is informational/educational and does not diagnose, treat, or
> prescribe.

## Localization (later)

The full description above leaves ~1,850 characters of headroom for
additional keywords. Prioritize translations by market: the short
description matters most (translated separately per language).

## Style guardrails (why the copy reads the way it does)

- "Supports", "studied for", "may help" — never "cures" or "treats" (Play
  health-app policy and the in-app disclaimer must agree).
- No before/after body imagery, no weight-loss promises, no fear language.
- AI disclosure is present ("AI-generated responses may contain errors") —
  current Play policy requires generative-AI features to be disclosed in
  the listing as well as in-app.
