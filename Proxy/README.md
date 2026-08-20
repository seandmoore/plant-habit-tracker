# Scanner proxy

This Cloudflare Worker keeps the Pl@ntNet key out of the client apps. It validates image signatures,
stream-caps uploads at 10 MB, rate-limits *before* reading a request body, charges two tokens for a
combined species/health request, times out stalled upstream calls, never caches, and returns only the
normalized shapes published in [`Contract/`](../Contract/README.md).

## Layout

The Worker is a table of routes over a set of single-purpose modules, so the security order is visible
in one place rather than spread through a chain of conditionals.

| Module | Responsibility |
| --- | --- |
| `src/worker.mjs` | Route table and the identify handler's ordering. |
| `src/router.mjs` | Method + path matching, including a single `{param}` segment. |
| `src/guards.mjs` | Configuration, mode, content type, declared length, rate limit, streamed body cap, magic-byte check. |
| `src/plantnet.mjs` | The only module that talks to Pl@ntNet. |
| `src/mappers.mjs` | Projects upstream responses onto the `ScanCandidate` contract. |
| `src/catalog.mjs` | Generated from `Contract/catalog.json`; backs the catalog endpoints. |
| `src/http.mjs` | JSON responses, security headers, and the typed errors guards raise. |
| `src/config.mjs` | Every limit and constant. |

## Endpoints

```text
GET  /health                  → { "status": "ok", "catalogVersion": 1 }
GET  /v1/plants?q=monstera    → PlantSpecies[]   (Contract/species.schema.json)
GET  /v1/plants/{id}          → PlantSpecies     (404 species_not_found)
POST /v1/identify?mode=…      → ScanCandidate[]  (Contract/scan-candidate.schema.json)
```

`POST /v1/identify` takes raw `image/jpeg` or `image/png` bytes and a `mode` of `species`, `health`, or
`both`. Failures return a fixed set of machine-readable codes — `service_not_configured`, `invalid_mode`,
`unsupported_image_type`, `invalid_content_length`, `image_too_large`, `rate_limited`, `empty_image`,
`invalid_image_data`, `upstream_unavailable` — and never an upstream body, a stack, or the API key.

The catalog endpoints serve the same curated data the apps bundle, which is what lets care guidance be
corrected without an app release. They deliberately do **not** derive care schedules from taxonomy
records: Pl@ntNet identifies plants, it does not publish trustworthy watering intervals. The Swift
`ResilientCatalogService` still falls back to its bundled copy whenever this service is absent or empty.

Because the catalog holds no secret, it is served without an API key. Only `/v1/identify` requires one.

## Setup

1. Install Node.js 22 or newer, then run `npm install` in this directory.
2. Change `namespace_id` in `wrangler.jsonc` to a positive integer unique within your Cloudflare account.
3. Run `npx wrangler secret put PLANTNET_API_KEY` and paste the key generated in your Pl@ntNet account.
4. Run `npm test`, then `npm run deploy`.
5. Add the deployed HTTPS origin as the Xcode build setting `PLANTNET_PROXY_URL`.

## Working on it

```bash
npm test              # node --test; no network, upstream fetch is stubbed per test
npm run sync:catalog  # regenerate src/catalog.mjs after editing Contract/catalog.json
npm run dev           # wrangler dev
```

`test/contract.test.mjs` fails if `src/catalog.mjs` is stale, if the served catalog diverges from the
contract, or if a mapper produces a candidate the published schema rejects. Regenerating is the intended
fix — never hand-edit the generated module.

## Known limits

The Worker intentionally has no permissive browser CORS policy. The native app does not need CORS, and
this reduces accidental browser-based use.

The rate limit keys on the connecting IP because version one has no user accounts, so shared mobile
networks share a limit. Before broad public distribution, replace that key with a verified user or
platform-attestation identifier and add a service-wide quota alarm. Do not put a reusable proxy
credential in a client app.
