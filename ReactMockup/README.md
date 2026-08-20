# Plant Companion React Mockup

An interactive preview of the SwiftUI Plant Companion. One Expo/TypeScript codebase runs on iOS,
Android, and the web. It does not modify or replace the native app, and it shares the native app's
care rules through [`Contract/`](../Contract/README.md) rather than a second hand-maintained copy.

## Included flows

- Responsive phone bottom tabs and wide web/Mac-style sidebar.
- Populated sample collection on first launch.
- Today care checks and seven-day watering summary.
- Add, edit, delete, search, and inspect plants.
- Quick watering and optional amount/unit/note logging.
- Curated Discover catalog and care details.
- Camera/photo selection with clearly labeled fixed scanner suggestions.
- Scripted contextual companion with a floating animated ring.
- Dark/light/system appearance, sample reset, clear-all, and onboarding replay.
- Versioned local persistence through AsyncStorage.

## Layout

The app is layered so that everything worth testing is reachable without rendering a screen.
Each layer may only import from the ones below it.

```text
src/app/        expo-router routes — one-line re-exports, so routing is a map and nothing else
src/features/   one screen per file, wiring state and UI together
src/ui/         the design system: Card, Button, Fields, Screen, ModalScreen, theme
src/state/      a pure reducer (plantsSlice) plus the thin React binding over it
src/services/   catalog, identification, and companion behind interfaces
src/data/       generated catalog, sample collection, versioned storage adapter
src/domain/     pure rules and derivations — no React, no React Native
```

Three consequences are worth knowing:

- **The planner is a pure function over a `CareProfile`,** not over a stored plant, so the contract's
  golden vectors can exercise it directly.
- **Ordering and filtering live in `domain/selectors.ts`.** The Today list and the collection grid
  read the same `careQueue`, so they cannot disagree about what is due.
- **Screens never build a plant or a care event.** They call the store, which owns `buildPlant` and
  `buildWateringEvent`, so trimming, defaulting, and id generation happen in exactly one place.

## Run it

Install Node.js 20.19 or newer, then from this directory run:

```bash
npm install
npx expo install --fix
npm run web
```

The final `expo install --fix` aligns native-module versions with the installed Expo SDK. Other useful
commands:

```bash
npm run ios
npm run android
npm run typecheck
npm test
npm run web:export
npm run sync:catalog   # regenerate src/data/catalog.ts from Contract/catalog.json
```

For a physical phone, run `npm start` and open the QR code in Expo Go. The iOS simulator requires
macOS and Xcode; Android emulation requires Android Studio.

## Tests

`npm test` runs Jest over the domain, state, data, and service layers, plus a store test that renders
the provider against an in-memory storage adapter.

`src/domain/contract.test.ts` is the important one: it replays every golden vector from
`Contract/recommendation-vectors.json` through this app's planner and asserts the interval, status,
due date, title, and wording all match. It also checks the rule tables and the generated catalog
against the contract. If a care rule changes in only one of the three codebases, this suite fails.

## Mock behavior

Scanner and companion output are deterministic demos. The scanner never uploads the selected image —
it stays on the device and fixed suggestions come back after a short delay. The companion answers only
from facts assembled by `groundingFacts`, which reads saved plant records and nothing else.

Plant and care changes persist locally through AsyncStorage under a versioned key. Storage written by
a schema version this build does not understand is refused rather than half-read, and the preview
falls back to the sample collection.
