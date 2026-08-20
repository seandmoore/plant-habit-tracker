import assert from "node:assert/strict";
import test, { describe } from "node:test";
import worker from "../src/worker.mjs";
import {
  allowAll,
  countingLimiter,
  imageRequest,
  JPEG_HEADER,
  PNG_HEADER,
  streamOf,
  upstreamJson,
  withUpstream,
} from "./helpers.mjs";

describe("POST /v1/identify", () => {
  test("refuses to run without a configured API key", async () => {
    const response = await worker.fetch(imageRequest(), { PLANT_RATE_LIMITER: { limit: async () => ({ success: true }) } });

    assert.equal(response.status, 503);
    assert.deepEqual(await response.json(), { error: "service_not_configured" });
  });

  test("rejects an unknown scan mode", async () => {
    const response = await worker.fetch(imageRequest({ mode: "everything" }), allowAll());

    assert.equal(response.status, 400);
    assert.deepEqual(await response.json(), { error: "invalid_mode" });
  });

  test("rejects a content type that is not an accepted image", async () => {
    const response = await worker.fetch(imageRequest({ headers: { "content-type": "application/json" } }), allowAll());

    assert.equal(response.status, 415);
    assert.deepEqual(await response.json(), { error: "unsupported_image_type" });
  });

  test("accepts a content type that carries parameters", async () => {
    const response = await withUpstream(upstreamJson({ results: [] }), () =>
      worker.fetch(imageRequest({ headers: { "content-type": "image/jpeg; charset=binary" } }), allowAll()));

    assert.equal(response.status, 200);
  });

  test("rejects an oversized upload from its declared length alone", async () => {
    const response = await worker.fetch(
      imageRequest({
        headers: { "content-length": String(10 * 1024 * 1024 + 1) },
        body: { getReader() { throw new Error("body should not be read"); } },
      }),
      allowAll(),
    );

    assert.equal(response.status, 413);
    assert.deepEqual(await response.json(), { error: "image_too_large" });
  });

  test("rejects a malformed content-length", async () => {
    const response = await worker.fetch(imageRequest({ headers: { "content-length": "not-a-number" } }), allowAll());

    assert.equal(response.status, 400);
    assert.deepEqual(await response.json(), { error: "invalid_content_length" });
  });

  test("rejects a rate-limited request before reading its body", async () => {
    const { env } = countingLimiter(false);
    const response = await worker.fetch(
      imageRequest({ body: { getReader() { throw new Error("body should not be read"); } } }),
      env,
    );

    assert.equal(response.status, 429);
    assert.equal(response.headers.get("retry-after"), "60");
    assert.equal(response.headers.get("cache-control"), "no-store");
  });

  test("charges a both-mode scan two rate limit tokens", async () => {
    const { calls, env } = countingLimiter();
    await withUpstream(upstreamJson({ results: [] }), () => worker.fetch(imageRequest({ mode: "both" }), env));

    assert.equal(calls.length, 2);
    assert.deepEqual(new Set(calls), new Set(["203.0.113.8:identify"]));
  });

  test("charges a single-mode scan one rate limit token", async () => {
    const { calls, env } = countingLimiter();
    await withUpstream(upstreamJson({ results: [] }), () => worker.fetch(imageRequest({ mode: "health" }), env));

    assert.equal(calls.length, 1);
  });

  test("rejects an empty body", async () => {
    const response = await worker.fetch(imageRequest({ body: streamOf() }), allowAll());

    assert.equal(response.status, 400);
    assert.deepEqual(await response.json(), { error: "empty_image" });
  });

  test("rejects bytes that do not match the declared image type", async () => {
    const response = await worker.fetch(imageRequest({ body: streamOf(PNG_HEADER) }), allowAll());

    assert.equal(response.status, 415);
    assert.deepEqual(await response.json(), { error: "invalid_image_data" });
  });

  test("returns mapped candidates and never the upstream body", async () => {
    const upstream = upstreamJson({
      results: [{
        score: 0.86,
        species: {
          id: "123",
          commonNames: ["Monstera"],
          scientificNameWithoutAuthor: "Monstera deliciosa",
          family: { scientificNameWithoutAuthor: "Araceae" },
        },
      }],
      remainingIdentificationRequests: 421,
    });

    const response = await withUpstream(upstream, () => worker.fetch(imageRequest(), allowAll()));
    const body = await response.json();

    assert.equal(response.status, 200);
    assert.equal(body.length, 1);
    assert.deepEqual(Object.keys(body[0]).sort(), ["confidence", "detail", "id", "scientificName", "source", "title"]);
    assert.equal(JSON.stringify(body).includes("remainingIdentificationRequests"), false);
  });

  test("sends the image to Pl@ntNet with the key in the query and not in a header", async () => {
    let seen;
    const upstream = async (url, init) => {
      seen = { url, init };
      return new Response(JSON.stringify({ results: [] }), { status: 200 });
    };

    await withUpstream(upstream, () => worker.fetch(imageRequest({ body: streamOf(JPEG_HEADER) }), allowAll()));

    assert.match(seen.url, /^https:\/\/my-api\.plantnet\.org\/v2\/identify\/all\?api-key=test-key/);
    assert.equal(seen.init.headers.Accept, "application/json");
    assert.ok(seen.init.body instanceof FormData);
  });

  test("translates an upstream client error into the same status", async () => {
    const response = await withUpstream(upstreamJson({ error: "bad request" }, 400), () =>
      worker.fetch(imageRequest(), allowAll()));

    assert.equal(response.status, 400);
    assert.deepEqual(await response.json(), { error: "upstream_unavailable" });
  });

  test("translates an upstream server error into a bad gateway", async () => {
    const response = await withUpstream(upstreamJson({}, 500), () => worker.fetch(imageRequest(), allowAll()));

    assert.equal(response.status, 502);
    assert.deepEqual(await response.json(), { error: "upstream_unavailable" });
  });

  test("never caches a scan response", async () => {
    const response = await withUpstream(upstreamJson({ results: [] }), () => worker.fetch(imageRequest(), allowAll()));

    assert.equal(response.headers.get("cache-control"), "no-store");
    assert.equal(response.headers.get("referrer-policy"), "no-referrer");
    assert.equal(response.headers.get("x-content-type-options"), "nosniff");
  });
});
