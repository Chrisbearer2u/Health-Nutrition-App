# NutriGuide — Data Schema

The knowledge base ships as three JSON assets in `app/assets/data/`.
All IDs are lowercase kebab-case strings. Relationships are by ID reference,
validated by the consistency check in this repo.

## Entity-relationship overview

```
ORGAN (1) ────< DISEASE (belongs to one organ)        organs.json
ORGAN (1) ────< FOOD.supports[] (many-to-many)        foods.json
ORGAN.diseaseIds[] ──── mirrors DISEASE.organId       (keep in sync)
```

## `organs.json`

```jsonc
{
  "id": "heart",                    // unique, kebab-case
  "name": "Heart & Blood Vessels",  // display name
  "system": "Cardiovascular system",// body system label
  "icon": "heart",                  // icon key → browse_screen.dart map
  "summary": "…",                   // 1-3 sentence plain-language summary
  "supportingFoods": ["oats", "fatty-fish"],  // food IDs → foods.json
  "diseaseIds": ["hypertension"]    // disease IDs → diseases.json
}
```

## `diseases.json`

```jsonc
{
  "id": "hypertension",
  "name": "High blood pressure (hypertension)",
  "organId": "heart",                       // → organs.json
  "category": "Cardiovascular condition",
  "description": "…",                       // what the disease is
  "causes": ["…", "…"],                     // known/risk causes (informational)
  "harmfulEffects": ["…"],                  // effects if unmanaged
  "helpfulFoods": ["…"],                    // human-readable food guidance
  "helpfulSupplements": ["…"],              // supplements + role/notes
  "sources": ["WHO — …", "NIH ODS — …"]     // reputable source citations
}
```

## `foods.json`

```jsonc
{
  "id": "fatty-fish",
  "name": "Fatty fish (salmon, sardines, mackerel)",
  "kind": "food",                // "food" | "supplement"
  "keyNutrients": ["Omega-3 EPA/DHA", "Vitamin D"],
  "supports": ["heart", "brain"], // organ IDs → organs.json
  "notes": "…"                    // practical guidance / cautions
}
```

## Content rules (editorial policy)

1. **Sources:** every disease entry cites WHO, NIH (ODS/NCCIH/NIDDK/NEI),
   CDC, Cochrane, or peer-reviewed trials. No blogs, no stores, no anecdotes.
2. **Framing:** foods/supplements "may help", "are studied for",
   "are associated with" — never "cures" or "treats".
3. **Interactions flagged** where they matter (e.g. curcumin + anticoagulants,
   iodine + Hashimoto's, levothyroxine timing).
4. **Escalation language** for anything acute ("see a healthcare
   professional") is part of the template, not left to the writer.

## Scaling to a real database

The JSON assets are a v1 authoring format. To scale:

- Load the same documents into Firestore/Postgres using these exact shapes.
- Ship an ETag-cached remote fetch (`KnowledgeRepository` is already the
  single seam — swap its `load()` internals, call sites stay unchanged).
- Add an admin web UI or headless CMS that enforces the schema above with
  JSON-Schema validation, and a content-review workflow (medical reviewer
  sign-off) before publish.
