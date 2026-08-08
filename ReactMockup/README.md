# Plant Companion React Mockup

This is a separate interactive preview of the SwiftUI Plant Companion. One Expo/TypeScript codebase runs on iOS, Android, and the web. It does not modify or replace the native app.

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

## Run it

Install Node.js 20.19 or newer, then from this directory run:

```bash
npm install
npx expo install --fix
npm run web
```

The final `expo install --fix` aligns native-module versions with the installed Expo SDK. Other useful commands:

```bash
npm run ios
npm run android
npm run typecheck
npm test
npm run web:export
```

For a physical phone, run `npm start` and open the QR code in Expo Go. The iOS simulator requires macOS and Xcode; Android emulation requires Android Studio.

## Mock behavior

No account or API credential is required. Scanner photos remain local and produce deterministic sample results. The companion uses scripted replies grounded in local mock data. Use Demo Settings to restore the original plants, clear the collection, replay onboarding, or switch appearance.

AsyncStorage is used only for non-secret preview data. Do not store API keys, session tokens, or other credentials there if the mockup later gains accounts; use the platform keychain through a maintained secure-storage package.

If this mockup later connects to the included Pl@ntNet proxy, keep the “possibility, not diagnosis” language and continue to protect the provider key server-side.
