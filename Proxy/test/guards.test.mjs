import assert from "node:assert/strict";
import test, { describe } from "node:test";
import { hasValidImageSignature, readBodyWithLimit } from "../src/guards.mjs";
import { JPEG_HEADER, PNG_HEADER, streamOf } from "./helpers.mjs";

describe("readBodyWithLimit", () => {
  test("returns an empty buffer for a missing body", async () => {
    assert.equal((await readBodyWithLimit(null, 16)).byteLength, 0);
  });

  test("joins chunks that fit inside the limit", async () => {
    const body = await readBodyWithLimit(streamOf([1, 2], [3, 4]), 16);

    assert.deepEqual([...body], [1, 2, 3, 4]);
  });

  test("stops reading once the byte limit is exceeded", async () => {
    await assert.rejects(() => readBodyWithLimit(streamOf([1, 2, 3], [4, 5, 6]), 5), { code: "image_too_large" });
  });

  test("accepts a body that lands exactly on the limit", async () => {
    const body = await readBodyWithLimit(streamOf([1, 2, 3], [4, 5]), 5);

    assert.equal(body.byteLength, 5);
  });

  test("cancels the stream rather than draining it", async () => {
    let cancelledWith;
    const stream = new ReadableStream({
      start(controller) {
        controller.enqueue(new Uint8Array([1, 2, 3, 4, 5, 6]));
      },
      cancel(reason) {
        cancelledWith = reason;
      },
    });

    await assert.rejects(() => readBodyWithLimit(stream, 2));
    assert.equal(cancelledWith, "payload_too_large");
  });
});

describe("hasValidImageSignature", () => {
  test("accepts real JPEG and PNG headers", () => {
    assert.equal(hasValidImageSignature(new Uint8Array([...JPEG_HEADER, 0x00]), "image/jpeg"), true);
    assert.equal(hasValidImageSignature(new Uint8Array(PNG_HEADER), "image/png"), true);
  });

  test("rejects bytes that only claim to be an image", () => {
    assert.equal(hasValidImageSignature(new Uint8Array([0x6e, 0x6f, 0x70, 0x65]), "image/jpeg"), false);
    assert.equal(hasValidImageSignature(new Uint8Array(JPEG_HEADER), "image/png"), false);
  });

  test("rejects a buffer too short to carry a signature", () => {
    assert.equal(hasValidImageSignature(new Uint8Array([0xff, 0xd8]), "image/jpeg"), false);
    assert.equal(hasValidImageSignature(new Uint8Array([0x89, 0x50]), "image/png"), false);
  });
});
