# Scanner proxy

This Cloudflare Worker keeps the Pl@ntNet key out of the Apple app, validates image signatures, stream-caps uploads at 10 MB, rate-limits before reading request bodies, consumes two tokens for a combined species/health request, times out stalled upstream calls, avoids caching responses, and returns only the app’s normalized result shape.

## Setup

1. Install Node.js 22 or newer, then run `npm install` in this directory.
2. Change `namespace_id` in `wrangler.jsonc` to a positive integer unique within your Cloudflare account.
3. Run `npx wrangler secret put PLANTNET_API_KEY` and paste the key generated in your Pl@ntNet account.
4. Run `npm test`, then `npm run deploy`.
5. Add the deployed HTTPS origin as the Xcode build setting `PLANTNET_PROXY_URL`.

The Worker intentionally has no permissive browser CORS policy. The native app does not need CORS, and this reduces accidental browser-based use. The included rate limit uses the connecting IP because version one has no user account; shared mobile networks can therefore share a limit. Before broad public distribution, replace that key with a verified user or platform-attestation identifier and add a service-wide quota alarm. Do not put a reusable proxy credential in the client app.

Plant catalog search is a separate contract because Pl@ntNet taxonomy records do not include trustworthy care schedules. The Swift app falls back to its curated catalog until a care-enriched `/v1/plants` service is supplied.
