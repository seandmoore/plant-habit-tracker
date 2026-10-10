# Contract

This directory is the source of truth for the native SwiftUI app and its Cloudflare Worker backend.
It defines the shared catalog and API response shapes, plus the native app’s watering rules and golden
planner vectors. Each project verifies the data it uses in its own test suite.

## Files

| File | Owns |
| --- | --- |
| `care-rules.json` | Watering-check interval modifiers, bounds, season windows, and the exact user-facing phrasing. |
| `recommendation-vectors.json` | Golden input/output vectors that every planner implementation must reproduce exactly. |
| `catalog.json` | The curated starter species, including the SF Symbol rendered by the native app. |
| `scan-candidate.schema.json` | Response shape of `POST /v1/identify`. |
| `species.schema.json` | Response shape of `GET /v1/plants` and `GET /v1/plants/{id}`. |

## How the projects use it

The app and proxy each keep a generated catalog in their runtime format, so both remain independently
buildable with no cross-directory build coupling:

- `PlantCompanion/Core/Services/StarterCatalog.swift` — Swift source compiled into the native app.
- `Proxy/src/catalog.mjs` — served by `GET /v1/plants`.

The native planner’s rule table is in `PlantCompanion/Core/Domain/CareRules.swift`; native tests compare
it with `care-rules.json` and replay `recommendation-vectors.json`.

Parity is enforced at **test** time instead. Each suite reads the files here over a relative path and
fails if its runtime copy has drifted:

- `PlantCompanionTests/ContractParityTests.swift`
- `Proxy/test/contract.test.mjs`

Change a rule or a species here first, then update the corresponding runtime definitions until the
parity tests pass. After editing `catalog.json`, regenerate both catalog copies from the repository root:

```bash
node Scripts/sync-swift-catalog.mjs
node Proxy/scripts/sync-catalog.mjs
```

## Rules encoded in `care-rules.json`

The planner starts from the species' `baselineWateringDays` and applies, in order:

1. an **environment** modifier (indoor, outdoor pot, garden bed),
2. a **light** modifier (low through direct sun),
3. at most one **season** modifier, resolved through `seasonPrecedence` — the warm-season window is
   checked first and never applies to indoor plants, then the cool-season window.

The result is clamped to `bounds`, added to the anchor date (the most recent watering, or the date the
plant was added), and compared against the current day to produce `overdue` / `dueToday` / `upcoming`.

Every factor that moved the number contributes its `factor` phrase to the explanation, which is why the
app can always say *why* a date is what it is. `phrasing` holds those strings so the native planner’s
explanations can be checked against the contract.

## Product guardrails these files carry

- A care date means "inspect the plant and soil," never "water automatically." `reasonSuffix` keeps
  "Feel the soil before watering." attached to every recommendation.
- Scanner health output is a possibility, never a diagnosis — enforced in `scan-candidate.schema.json`
  by keeping `scientificName` nullable and in the mapper text the Worker produces.
- Catalog care values are conservative starting points that the app adapts from recorded observations.
  They are not authoritative botanical guidance, and toxicity notes point people to a professional source.
