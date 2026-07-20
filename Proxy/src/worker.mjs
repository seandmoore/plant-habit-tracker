const PLANTNET_ORIGIN = "https://my-api.plantnet.org";
const MAX_IMAGE_BYTES = 10 * 1024 * 1024;

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    if (request.method === "GET" && url.pathname === "/health") {
      return json({ status: "ok" });
    }

    if (request.method !== "POST" || url.pathname !== "/v1/identify") {
      return json({ error: "not_found" }, 404);
    }

    if (!env.PLANTNET_API_KEY) {
      return json({ error: "service_not_configured" }, 503);
    }

    const mode = url.searchParams.get("mode") || "both";
    if (!["species", "health", "both"].includes(mode)) {
      return json({ error: "invalid_mode" }, 400);
    }

    const contentType = request.headers.get("content-type")?.split(";", 1)[0].trim();
    if (contentType !== "image/jpeg" && contentType !== "image/png") {
      return json({ error: "unsupported_image_type" }, 415);
    }

    const declaredLength = Number(request.headers.get("content-length") || 0);
    if (declaredLength > MAX_IMAGE_BYTES) {
      return json({ error: "image_too_large" }, 413);
    }

    const image = await request.arrayBuffer();
    if (image.byteLength === 0 || image.byteLength > MAX_IMAGE_BYTES) {
      return json({ error: image.byteLength === 0 ? "empty_image" : "image_too_large" }, image.byteLength === 0 ? 400 : 413);
    }

    const requestCost = mode === "both" ? 2 : 1;
    const rateLimitKey = `${request.headers.get("cf-connecting-ip") || "unknown"}:identify`;
    for (let index = 0; index < requestCost; index += 1) {
      const { success } = await env.PLANT_RATE_LIMITER.limit({ key: rateLimitKey });
      if (!success) {
        return json({ error: "rate_limited" }, 429, { "Retry-After": "60" });
      }
    }

    try {
      const tasks = [];
      if (mode === "species" || mode === "both") {
        tasks.push(fetchSpecies(image, contentType, env.PLANTNET_API_KEY));
      }
      if (mode === "health" || mode === "both") {
        tasks.push(fetchHealth(image, contentType, env.PLANTNET_API_KEY));
      }
      const results = (await Promise.all(tasks)).flat();
      return json(results, 200, { "Cache-Control": "no-store" });
    } catch (error) {
      const status = error instanceof UpstreamError ? error.status : 502;
      return json({ error: "upstream_unavailable" }, status >= 400 && status < 500 ? status : 502);
    }
  },
};

async function fetchSpecies(image, contentType, apiKey) {
  const response = await plantNetImageRequest(
    `/v2/identify/all?api-key=${encodeURIComponent(apiKey)}&lang=en&nb-results=4`,
    image,
    contentType,
  );
  return mapSpeciesResults(response.results || []);
}

async function fetchHealth(image, contentType, apiKey) {
  const response = await plantNetImageRequest(
    `/v2/diseases/identify?api-key=${encodeURIComponent(apiKey)}&lang=en&nb-results=3`,
    image,
    contentType,
  );
  return mapHealthResults(response.results || []);
}

async function plantNetImageRequest(path, image, contentType) {
  const form = new FormData();
  const extension = contentType === "image/png" ? "png" : "jpg";
  form.append("images", new Blob([image], { type: contentType }), `plant.${extension}`);
  form.append("organs", "auto");

  const response = await fetch(`${PLANTNET_ORIGIN}${path}`, {
    method: "POST",
    body: form,
    headers: { Accept: "application/json" },
  });
  if (!response.ok) {
    throw new UpstreamError(response.status);
  }
  return response.json();
}

export function mapSpeciesResults(results) {
  return results.slice(0, 4).map((result, index) => {
    const species = result.species || {};
    const scientificName = species.scientificNameWithoutAuthor || species.scientificName || "Unknown species";
    const commonName = Array.isArray(species.commonNames) && species.commonNames.length > 0
      ? species.commonNames[0]
      : scientificName;
    const family = species.family?.scientificNameWithoutAuthor || species.family?.scientificName;
    return {
      id: `species-${species.id || scientificName}-${index}`,
      title: commonName,
      scientificName,
      confidence: clampScore(result.score),
      detail: family ? `Plant family: ${family}. Compare several visible features before confirming.` : "Compare several visible features before confirming.",
      source: "Pl@ntNet",
    };
  });
}

export function mapHealthResults(results) {
  return results.slice(0, 3).map((result, index) => ({
    id: `health-${result.name || index}`,
    title: result.description || result.name || "Possible visible health concern",
    scientificName: null,
    confidence: clampScore(result.score),
    detail: `EPPO code: ${result.name || "unavailable"}. This photo result is a possibility, not a diagnosis.`,
    source: "Pl@ntNet disease identification",
  }));
}

function clampScore(value) {
  const number = Number(value);
  if (!Number.isFinite(number)) return 0;
  return Math.min(Math.max(number, 0), 1);
}

function json(value, status = 200, extraHeaders = {}) {
  return new Response(JSON.stringify(value), {
    status,
    headers: {
      "Content-Type": "application/json; charset=utf-8",
      "X-Content-Type-Options": "nosniff",
      ...extraHeaders,
    },
  });
}

class UpstreamError extends Error {
  constructor(status) {
    super("Plant service request failed");
    this.status = status;
  }
}
