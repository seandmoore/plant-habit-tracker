# Plant Companion

[![CI](https://github.com/seandmoore/plant-habit-tracker/actions/workflows/ci.yml/badge.svg)](https://github.com/seandmoore/plant-habit-tracker/actions/workflows/ci.yml)

> **Built with AI assistance.** Plant Companion is developed with Claude (Anthropic) under maintainer
> review. It is a hobby project — not horticultural, veterinary, or safety advice. Please read
> [AI assistance and safe use](#ai-assistance-and-safe-use) before relying on anything it tells you,
> especially around plant toxicity.

Plant Companion is a hobby-friendly SwiftUI app for keeping a plant collection, logging care habits,
getting explainable soil-check reminders, identifying plants from photos, and talking with a grounded
on-device companion.

## Repository layout

| Directory | What it is |
| --- | --- |
| [`Contract/`](Contract/README.md) | The shared source of truth: care rules, golden planner vectors, the curated catalog, and the API schemas. |
| `PlantCompanion/` | The native SwiftUI app for iPhone, iPad, and Mac. |
| [`ReactMockup/`](ReactMockup/README.md) | An independent Expo/TypeScript preview that runs on web, iOS, and Android. It does not replace the native app. |
| [`Proxy/`](Proxy/README.md) | A Cloudflare Worker that holds the Pl@ntNet key and serves the catalog. |

The three codebases each need to agree about the same watering rules and the same wire shapes.
Rather than three hand-maintained copies that can quietly drift apart, `Contract/` owns that data and
every project asserts against it in its own test suite — so a rule that changes in only one place is a
failing build, not a silent divergence. See [`Contract/README.md`](Contract/README.md) for how it works.

## What is implemented

- Adaptive iPhone/iPad/Mac navigation with native Liquid Glass controls on iOS 26 and macOS 26.
- Local SwiftData storage for plants and care events; no account is required.
- Indoor and outdoor plant profiles with light and placement information.
- Quick watering plus optional amount, unit, date, and notes.
- Explainable recommendation rules and opt-in local notifications.
- Offline starter catalog and plant discovery.
- Photo-library scanning on every platform and camera capture on iOS.
- Demo scan results by default, with a production proxy adapter ready for Pl@ntNet.
- Apple Foundation Models companion when available, with a deterministic scripted fallback.
- Dynamic Type, VoiceOver labels, keyboard-friendly native controls, Reduce Motion, and system
  contrast/transparency behavior.

## Native app architecture

```text
PlantCompanion/
  App/            composition root, plus a router that owns navigation and nothing else
  Core/Domain/    pure value types and the rule-table-driven WateringPlanner
  Core/Persistence/  the SwiftData models and PlantStore, the only place plants are written
  Core/Services/  catalog, identification, companion, and notification implementations
  Features/       one folder per feature, with a model beside the view where there is real logic
  DesignSystem/   theme, cards, pills, artwork, and the companion ring
```

Three decisions carry most of the weight:

- **`WateringPlanner` operates on a `CareProfile`, not on a stored plant.** The rules are a pure
  function over a value type, so the shared golden vectors can exercise them without a SwiftData
  container, and the interval and its human explanation are built in one pass — the phrase travels
  with the number that moved it, which is why the app can always say *why* a date is what it is.
- **`PlantStore` is the only writer.** Every screen used to run the same four steps by hand — insert
  the event, append it, save, reschedule the reminder — in three places, behind a `try?` that
  swallowed failures. Now a write and its reminder side effect always happen together, and a failed
  save is surfaced instead of lost.
- **Navigation, services, and conversation state are separate objects.** They used to share one
  app-wide model, so unrelated screens re-rendered on each other's changes.

## Run the app

Requirements:

- Xcode 26 or newer on a Mac
- iOS/iPadOS 26 or macOS 26 deployment target
- An Apple development team if running on a physical iPhone or using notifications/camera entitlements

Open `PlantCompanion.xcodeproj`, select the shared `PlantCompanion` scheme, choose an iPhone, iPad, or
Mac destination, and Run. The app uses mock scanner results and the bundled catalog without credentials.

The bundle identifier is deliberately set to `com.example.PlantCompanion`; replace it with your own
identifier before signing.

## Scanner proxy contract

Never put a Pl@ntNet API key in the app. Set the `PLANTNET_PROXY_URL` user-defined Xcode build setting
to the HTTPS origin of a small server-side proxy. Anything that is not absolute HTTPS is refused and
the app falls back to `MockIdentificationService`, so photos are never sent to an unverified origin.

The proxy contract is:

```text
GET  {PLANTNET_PROXY_URL}/v1/plants?q=monstera   → PlantSpecies[]
GET  {PLANTNET_PROXY_URL}/v1/plants/{id}         → PlantSpecies
POST {PLANTNET_PROXY_URL}/v1/identify?mode=…     → ScanCandidate[]
```

`POST /v1/identify` takes raw JPEG bytes with `Content-Type: image/jpeg` and a mode of `species`,
`health`, or `both`. Both response shapes are specified in
[`Contract/scan-candidate.schema.json`](Contract/scan-candidate.schema.json) and
[`Contract/species.schema.json`](Contract/species.schema.json).

The deployable Worker in [`Proxy/`](Proxy/README.md) handles the secret, upload validation, rate
limiting, normalized species/disease responses, and no-store behavior. Its catalog endpoints serve the
curated contract catalog rather than care values inferred from taxonomy records, and
`ResilientCatalogService` still falls back to the bundled copy whenever the service is absent or empty.

## Product guardrails

- A care date means "inspect the plant and soil," not "water automatically."
- Scanner health output is always presented as a possibility, never a diagnosis.
- Companion prompts contain saved care facts; the language model is not used as a botanical database
  or care calculator.
- Toxicity notes are starter hints and direct users to an authoritative professional source for
  decisions.

These are enforced in code and in tests, not only in review: the reminder phrasing lives in
`Contract/care-rules.json`, the nullable `scientificName` in the scan schema keeps health results from
posing as species, and each suite asserts the wording.

## AI assistance and safe use

**How this project is built.** Plant Companion is written collaboratively with Claude (Anthropic).
The current architecture — the shared `Contract/`, all three codebases, and most of the test suite —
was authored with AI assistance. Every change is reviewed by the maintainer and gated by CI before it
lands. That is a real filter, but reviewed code is not proven code, and a confident-looking
explanation from an AI-written rule table is still only as good as the rule table.

**The app also ships AI features.** The on-device companion uses Apple's Foundation Models where
available, falling back to a deterministic scripted responder. It is deliberately constrained to the
care facts your device has already saved — it is not a botanical database, and it is not consulted to
calculate care schedules.

### What to verify before acting

- **Watering intervals are heuristics, not horticulture.** They come from a small rule table —
  species baseline, indoor/outdoor, light level, season — not from species-specific research. This is
  why the app always says "check the soil" and never "water now." Treat the date as a prompt to go
  look at the plant, and trust what you see over what the app predicted.
- **Scan results are guesses.** Species matches can be confidently wrong, and health output describes
  something worth checking, never a diagnosis. Compare candidates against a reliable reference before
  you act on one.
- **Toxicity notes are starter hints only.** They are short, incomplete, and not a safety database.
  **For anything involving pets, children, or ingestion, confirm with a veterinarian or a
  poison-control service.** Do not use this app to decide whether a plant is safe.
- **The companion inherits your records.** It answers from what you saved. If a plant is logged
  incorrectly, its answers will be wrong in the same direction, and it will sound just as certain.

If you rely on this app for a plant that matters to you, keep your own notes as the source of truth.
It is distributed under the GNU General Public License v3.0 and comes with no warranty of any kind —
see [`LICENSE`](LICENSE).

## Testing

```bash
# Native app (requires macOS and Xcode)
xcodebuild test -project PlantCompanion.xcodeproj -scheme PlantCompanion -destination 'platform=macOS'

# Expo preview
cd ReactMockup && npm ci && npm run typecheck && npm test

# Worker proxy
cd Proxy && npm ci && npm test
```

Each suite includes a contract parity test that replays the shared golden vectors and checks its own
copy of the rules and catalog against `Contract/`.

After editing `Contract/catalog.json`, regenerate the three runtime copies:

```bash
node Scripts/sync-swift-catalog.mjs
node Proxy/scripts/sync-catalog.mjs
node ReactMockup/scripts/sync-catalog.mjs
```

CI runs those generators and fails if the committed output has drifted. Three workflows run on a pull
request: `ci.yml` (the suites above, plus the contract drift check), and `claude-code-review.yml` and
`claude.yml`, which provide automated review and let a maintainer address feedback by mentioning
`@claude` in a comment.

## Next milestones

1. Replace the example bundle identifier and add an app icon in Icon Composer.
2. Connect and contract-test a private Pl@ntNet proxy.
3. Add image attribution and remote species catalog caching.
4. Add CloudKit only after exercising SwiftData migrations with real test data.
5. Add WeatherKit as an optional, explained input for outdoor recommendations.
