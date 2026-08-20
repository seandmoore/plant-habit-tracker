# Contract

Plant Companion ships three codebases — a SwiftUI app, an Expo app, and a Cloudflare Worker — that each
have to agree about the same plant care rules and the same wire shapes. Before, each one carried its own
hand-maintained copy of the interval rules and the starter catalog, so the copies could drift apart and
nothing would notice. This directory is the single source of truth, and every project asserts against it
in its own test suite.

## Files

| File | Owns |
| --- | --- |
| `care-rules.json` | Watering-check interval modifiers, bounds, season windows, and the exact user-facing phrasing. |
| `recommendation-vectors.json` | Golden input/output vectors that every planner implementation must reproduce exactly. |
| `catalog.json` | The curated starter species, including the per-platform icon name each app renders. |
| `scan-candidate.schema.json` | Response shape of `POST /v1/identify`. |
| `species.schema.json` | Response shape of `GET /v1/plants` and `GET /v1/plants/{id}`. |

## How the projects use it

Each project keeps its own runtime copy of this data in its native format, so all three stay
independently buildable and deployable with no cross-directory build coupling:

- `PlantCompanion/Resources/StarterCatalog.json` — bundled resource decoded at launch.
- `ReactMockup/src/data/catalog.ts` — a typed module.
- `Proxy/src/catalog.mjs` — served by `GET /v1/plants`.

Parity is enforced at **test** time instead. Each suite reads the files here over a relative path and
fails if its runtime copy has drifted:

- `PlantCompanionTests/ContractParityTests.swift`
- `ReactMockup/src/domain/contract.test.ts`
- `Proxy/test/contract.test.mjs`

Change a rule or a species here first, then update the three runtime copies until the parity tests pass
again. A change that lands in only one project is a failing build, not a silent divergence.

## Rules encoded in `care-rules.json`

The planner starts from the species' `baselineWateringDays` and applies, in order:

1. an **environment** modifier (indoor, outdoor pot, garden bed),
2. a **light** modifier (low through direct sun),
3. at most one **season** modifier, resolved through `seasonPrecedence` — the warm-season window is
   checked first and never applies to indoor plants, then the cool-season window.

The result is clamped to `bounds`, added to the anchor date (the most recent watering, or the date the
plant was added), and compared against the current day to produce `overdue` / `dueToday` / `upcoming`.

Every factor that moved the number contributes its `factor` phrase to the explanation, which is why the
app can always say *why* a date is what it is. `phrasing` holds those strings so the three apps word the
explanation identically.

## Product guardrails these files carry

- A care date means "inspect the plant and soil," never "water automatically." `reasonSuffix` keeps
  "Feel the soil before watering." attached to every recommendation.
- Scanner health output is a possibility, never a diagnosis — enforced in `scan-candidate.schema.json`
  by keeping `scientificName` nullable and in the mapper text the Worker produces.
- Catalog care values are conservative starting points that the app adapts from recorded observations.
  They are not authoritative botanical guidance, and toxicity notes point people to a professional source.
