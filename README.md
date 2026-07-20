# Plant Companion

Plant Companion is a hobby-friendly SwiftUI app for keeping a plant collection, logging care habits, getting explainable soil-check reminders, identifying plants from photos, and talking with a grounded on-device companion.

An independent universal React/Expo preview is available in [`ReactMockup/`](ReactMockup/README.md). It runs on web, iOS, and Android with local sample data and does not replace the native app.

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
- Dynamic Type, VoiceOver labels, keyboard-friendly native controls, Reduce Motion, and system contrast/transparency behavior.

## Run the app

Requirements:

- Xcode 26 or newer on a Mac
- iOS/iPadOS 26 or macOS 26 deployment target
- An Apple development team if running on a physical iPhone or using notifications/camera entitlements

Open `PlantCompanion.xcodeproj`, select the shared `PlantCompanion` scheme, choose an iPhone, iPad, or Mac destination, and Run. The app uses mock scanner results and the bundled catalog without credentials.

The bundle identifier is deliberately set to `com.example.PlantCompanion`; replace it with your own identifier before signing.

## Scanner proxy contract

Never put a Pl@ntNet API key in the app. Set the `PLANTNET_PROXY_URL` user-defined Xcode build setting to the HTTPS origin of a small server-side proxy. If the value is absent, the app uses `MockIdentificationService`.

The included `ProxyIdentificationService` sends:

```text
POST {PLANTNET_PROXY_URL}/v1/identify?mode=species|health|both
Content-Type: image/jpeg
Accept: application/json

<raw JPEG bytes>
```

The proxy must return a JSON array matching this shape:

```json
[
  {
    "id": "stable-result-id",
    "title": "Monstera",
    "scientificName": "Monstera deliciosa",
    "confidence": 0.86,
    "detail": "Compare the leaf and growth habit before confirming.",
    "source": "Pl@ntNet"
  }
]
```

The deployable Worker in `Proxy/` handles the secret, upload validation, rate limiting, normalized species/disease responses, and no-store behavior. Follow `Proxy/README.md` to configure its secret and deploy it.

The app also supports an optional care-enriched catalog at `GET {PLANTNET_PROXY_URL}/v1/plants?q=monstera` and `GET {PLANTNET_PROXY_URL}/v1/plants/{id}`. Those endpoints return the `PlantSpecies` JSON shape defined in `PlantModels.swift`. The included Worker intentionally does not invent care schedules from taxonomy data, so `ResilientCatalogService` automatically uses the curated bundled catalog until you add a trustworthy care-data source.

## Product guardrails

- A care date means “inspect the plant and soil,” not “water automatically.”
- Scanner health output is always presented as a possibility, never a diagnosis.
- Companion prompts contain saved care facts; the language model is not used as a botanical database or care calculator.
- Toxicity notes are starter hints and direct users to an authoritative professional source for decisions.

## Next milestones

1. Replace the example bundle identifier and add an app icon in Icon Composer.
2. Connect and contract-test a private Pl@ntNet proxy.
3. Add image attribution and remote species catalog caching.
4. Add CloudKit only after exercising SwiftData migrations with real test data.
5. Add WeatherKit as an optional, explained input for outdoor recommendations.
