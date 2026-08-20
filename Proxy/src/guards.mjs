import { ACCEPTED_IMAGE_TYPES, MAX_IMAGE_BYTES, RATE_LIMIT_COST, SCAN_MODES } from "./config.mjs";
import { HttpError } from "./http.mjs";

export function requireApiKey(env) {
  if (!env.PLANTNET_API_KEY) {
    throw new HttpError("service_not_configured", 503);
  }
  return env.PLANTNET_API_KEY;
}

export function readScanMode(url) {
  const mode = url.searchParams.get("mode") || "both";
  if (!SCAN_MODES.includes(mode)) {
    throw new HttpError("invalid_mode", 400);
  }
  return mode;
}

export function readImageContentType(request) {
  const contentType = request.headers.get("content-type")?.split(";", 1)[0].trim();
  if (!ACCEPTED_IMAGE_TYPES.includes(contentType)) {
    throw new HttpError("unsupported_image_type", 415);
  }
  return contentType;
}

/**
 * Rejects an oversized upload from its declared length before any body is read. The streamed
 * read in `readBodyWithLimit` still enforces the real limit for requests that lie or omit it.
 */
export function assertDeclaredLengthWithinLimit(request) {
  const contentLength = request.headers.get("content-length");
  if (contentLength === null) return;

  const declaredLength = Number(contentLength);
  if (!Number.isSafeInteger(declaredLength) || declaredLength < 0) {
    throw new HttpError("invalid_content_length", 400);
  }
  if (declaredLength > MAX_IMAGE_BYTES) {
    throw new HttpError("image_too_large", 413);
  }
}

/**
 * Draws the mode's cost from the limiter *before* the body is read, so a flood of oversized
 * uploads is refused without this Worker ever buffering them.
 */
export async function consumeRateLimit(request, env, mode) {
  const key = `${request.headers.get("cf-connecting-ip") || "unknown"}:identify`;
  const cost = RATE_LIMIT_COST[mode];

  for (let index = 0; index < cost; index += 1) {
    const { success } = await env.PLANT_RATE_LIMITER.limit({ key });
    if (!success) {
      throw new HttpError("rate_limited", 429, { "Retry-After": "60" });
    }
  }
}

export async function readImageBody(request, contentType) {
  const image = await readBodyWithLimit(request.body, MAX_IMAGE_BYTES);

  if (image.byteLength === 0) {
    throw new HttpError("empty_image", 400);
  }
  if (!hasValidImageSignature(image, contentType)) {
    throw new HttpError("invalid_image_data", 415);
  }
  return image;
}

/** Buffers at most `maxBytes`, cancelling the stream the moment an upload exceeds it. */
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
        throw new HttpError("image_too_large", 413);
      }
      output.set(chunk, length);
      length += chunk.byteLength;
    }
  } finally {
    reader.releaseLock();
  }

  return output.subarray(0, length);
}

/** Confirms the bytes actually match the declared type instead of trusting the header. */
export function hasValidImageSignature(image, contentType) {
  if (contentType === "image/jpeg") {
    return image.byteLength >= 3 && image[0] === 0xff && image[1] === 0xd8 && image[2] === 0xff;
  }

  const pngSignature = [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a];
  return image.byteLength >= pngSignature.length
    && pngSignature.every((byte, index) => image[index] === byte);
}
