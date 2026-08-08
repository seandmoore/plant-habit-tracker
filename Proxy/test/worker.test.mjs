import assert from "node:assert/strict";
import test from "node:test";
import worker, {
  hasValidImageSignature,
  mapHealthResults,
  mapSpeciesResults,
  readBodyWithLimit,
} from "../src/worker.mjs";

test("maps species without exposing the upstream response", () => {
  const result = mapSpeciesResults([{
    score: 0.86,
    species: {
      id: "123",
      commonNames: ["Monstera"],
      scientificNameWithoutAuthor: "Monstera deliciosa",
      family: { scientificNameWithoutAuthor: "Araceae" },
    },
  }]);

  assert.deepEqual(result[0], {
    id: "species-123-0",
    title: "Monstera",
    scientificName: "Monstera deliciosa",
    confidence: 0.86,
    detail: "Plant family: Araceae. Compare several visible features before confirming.",
    source: "Pl@ntNet",
  });
});

test("maps health result with uncertainty language", () => {
  const result = mapHealthResults([{ name: "APHISP", score: 1.4, description: "Aphis sp." }]);

  assert.equal(result[0].title, "Aphis sp.");
  assert.equal(result[0].confidence, 1);
  assert.match(result[0].detail, /not a diagnosis/);
});

test("rejects a rate-limited request before reading its body", async () => {
  const request = {
    method: "POST",
    url: "https://proxy.example/v1/identify?mode=species",
    headers: new Headers({ "content-type": "image/jpeg", "cf-connecting-ip": "203.0.113.8" }),
    body: {
      getReader() {
        throw new Error("body should not be read");
      },
    },
  };
  const env = {
    PLANTNET_API_KEY: "test-key",
    PLANT_RATE_LIMITER: { limit: async () => ({ success: false }) },
  };

  const response = await worker.fetch(request, env);

  assert.equal(response.status, 429);
  assert.equal(response.headers.get("cache-control"), "no-store");
});

test("stops reading a streamed body once the byte limit is exceeded", async () => {
  const stream = new ReadableStream({
    start(controller) {
      controller.enqueue(new Uint8Array([1, 2, 3]));
      controller.enqueue(new Uint8Array([4, 5, 6]));
      controller.close();
    },
  });

  await assert.rejects(() => readBodyWithLimit(stream, 5));
});

test("checks that the declared image type matches its file signature", () => {
  assert.equal(hasValidImageSignature(new Uint8Array([0xff, 0xd8, 0xff, 0x00]), "image/jpeg"), true);
  assert.equal(hasValidImageSignature(new Uint8Array([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]), "image/png"), true);
  assert.equal(hasValidImageSignature(new Uint8Array([0x6e, 0x6f, 0x70, 0x65]), "image/jpeg"), false);
});
