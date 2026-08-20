import { catalog, CATALOG_VERSION, findSpecies, searchCatalog } from "./catalog.mjs";
import {
  assertDeclaredLengthWithinLimit,
  consumeRateLimit,
  readImageBody,
  readImageContentType,
  readScanMode,
  requireApiKey,
} from "./guards.mjs";
import { fail, json, UpstreamError } from "./http.mjs";
import { identify } from "./plantnet.mjs";
import { createRouter } from "./router.mjs";

const handle = createRouter([
  {
    method: "GET",
    path: "/health",
    handler: () => json({ status: "ok", catalogVersion: CATALOG_VERSION }),
  },
  {
    method: "GET",
    path: "/v1/plants",
    handler: ({ url }) => json(searchCatalog(url.searchParams.get("q") || "")),
  },
  {
    method: "GET",
    path: "/v1/plants/{id}",
    handler: ({ params }) => {
      const species = findSpecies(params.id);
      return species ? json(species) : fail("species_not_found", 404);
    },
  },
  {
    method: "POST",
    path: "/v1/identify",
    handler: identifyHandler,
  },
]);

export default {
  async fetch(request, env, context) {
    return handle(request, env, context);
  },
};

/**
 * Order matters here and is load-bearing: configuration, then cheap header checks, then the
 * rate limiter, and only then the request body. An unauthorized, malformed, or throttled
 * upload is rejected before this Worker buffers a single byte of it.
 */
async function identifyHandler({ request, env, url }) {
  const apiKey = requireApiKey(env);
  const mode = readScanMode(url);
  const contentType = readImageContentType(request);
  assertDeclaredLengthWithinLimit(request);
  await consumeRateLimit(request, env, mode);

  const image = await readImageBody(request, contentType);

  try {
    return json(await identify(image, contentType, apiKey, mode));
  } catch (error) {
    const status = error instanceof UpstreamError ? error.status : 502;
    return fail("upstream_unavailable", status >= 400 && status < 500 ? status : 502);
  }
}

export { catalog, findSpecies, searchCatalog };
