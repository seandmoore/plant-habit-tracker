const PLANTNET_ORIGIN = "https://my-api.plantnet.org";
const MAX_IMAGE_BYTES = 10 * 1024 * 1024;
const UPSTREAM_TIMEOUT_MS = 15_000;

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

    const contentLength = request.headers.get("content-length");
    if (contentLength !== null) {
      const declaredLength = Number(contentLength);
      if (!Number.isSafeInteger(declaredLength) || declaredLength < 0) {
        return json({ error: "invalid_content_length" }, 400);
      }
      if (declaredLength > MAX_IMAGE_BYTES) {
        return json({ error: "image_too_large" }, 413);
      }
    }

    const requestCost = mode === "both" ? 2 : 1;
    const rateLimitKey = `${request.headers.get("cf-connecting-ip") || "unknown"}:identify`;
    for (let index = 0; index < requestCost; index += 1) {
      const { success } = await env.PLANT_RATE_LIMITER.limit({ key: rateLimitKey });
      if (!success) {
        return json({ error: "rate_limited" }, 429, { "Retry-After": "60" });
      }
    }

    let image;
    try {
      image = await readBodyWithLimit(request.body, MAX_IMAGE_BYTES);
    } catch (error) {
      if (error instanceof PayloadTooLargeError) {
        return json({ error: "image_too_large" }, 413);
      }
      throw error;
    }
    if (image.byteLength === 0) {
      return json({ error: "empty_image" }, 400);
    }
    if (!hasValidImageSignature(image, contentType)) {
      return json({ error: "invalid_image_data" }, 415);
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
    signal: AbortSignal.timeout(UPSTREAM_TIMEOUT_MS),
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
      "Cache-Control": "no-store",
      "Referrer-Policy": "no-referrer",
      "X-Content-Type-Options": "nosniff",
      ...extraHeaders,
    },
  });
}

export async function readBodyWithLimit(body, maxBytes) {
  if (!body) return new Uint8Array();

  const reader = body.getReader();
  const output = new Uint8Array(maxBytes);
  let length = 0;

  try {
    while (true) {
      const { done, value } = await reader.read();
      if (done) break;

      const chunk = value instanceof Uint8Array ? value : new Uint8Array(value);
      if (length + chunk.byteLength > maxBytes) {
        await reader.cancel("payload_too_large");
        throw new PayloadTooLargeError();
      }
      output.set(chunk, length);
      length += chunk.byteLength;
    }
  } finally {
    reader.releaseLock();
  }

  return output.subarray(0, length);
}

export function hasValidImageSignature(image, contentType) {
  if (contentType === "image/jpeg") {
    return image.byteLength >= 3
      && image[0] === 0xff
      && image[1] === 0xd8
      && image[2] === 0xff;
  }

  const pngSignature = [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a];
  return image.byteLength >= pngSignature.length
    && pngSignature.every((byte, index) => image[index] === byte);
}

class PayloadTooLargeError extends Error {}

class UpstreamError extends Error {
  constructor(status) {
    super("Plant service request failed");
    this.status = status;
  }
}
