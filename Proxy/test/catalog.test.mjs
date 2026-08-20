import assert from "node:assert/strict";
import test, { describe } from "node:test";
import worker from "../src/worker.mjs";
import { allowAll, getRequest } from "./helpers.mjs";

describe("catalog endpoints", () => {
  test("lists the whole catalog when no query is given", async () => {
    const response = await worker.fetch(getRequest("/v1/plants"), allowAll());
    const body = await response.json();

    assert.equal(response.status, 200);
    assert.equal(body.length, 10);
    assert.equal(new Set(body.map((species) => species.id)).size, body.length);
  });

  test("matches a common name and a scientific name", async () => {
    const byCommon = await (await worker.fetch(getRequest("/v1/plants?q=monstera"), allowAll())).json();
    const byScientific = await (await worker.fetch(getRequest("/v1/plants?q=ocimum"), allowAll())).json();

    assert.equal(byCommon[0].id, "monstera-deliciosa");
    assert.equal(byScientific[0].id, "ocimum-basilicum");
  });

  test("matches case insensitively and returns an empty list for no match", async () => {
    const upper = await (await worker.fetch(getRequest("/v1/plants?q=MONSTERA"), allowAll())).json();
    const missing = await (await worker.fetch(getRequest("/v1/plants?q=zzzznope"), allowAll())).json();

    assert.equal(upper[0].id, "monstera-deliciosa");
    assert.deepEqual(missing, []);
  });

  test("returns a single species by id", async () => {
    const response = await worker.fetch(getRequest("/v1/plants/ficus-lyrata"), allowAll());
    const body = await response.json();

    assert.equal(response.status, 200);
    assert.equal(body.scientificName, "Ficus lyrata");
    assert.equal(body.baselineWateringDays, 9);
  });

  test("reports an unknown species id as not found", async () => {
    const response = await worker.fetch(getRequest("/v1/plants/no-such-plant"), allowAll());

    assert.equal(response.status, 404);
    assert.deepEqual(await response.json(), { error: "species_not_found" });
  });

  test("serves the catalog without an API key, since it holds no secret", async () => {
    const response = await worker.fetch(getRequest("/v1/plants"), { PLANT_RATE_LIMITER: null });

    assert.equal(response.status, 200);
  });
});

describe("routing", () => {
  test("reports health with the catalog version", async () => {
    const response = await worker.fetch(getRequest("/health"), allowAll());

    assert.deepEqual(await response.json(), { status: "ok", catalogVersion: 1 });
  });

  test("rejects an unknown path", async () => {
    const response = await worker.fetch(getRequest("/v1/unknown"), allowAll());

    assert.equal(response.status, 404);
    assert.deepEqual(await response.json(), { error: "not_found" });
  });

  test("rejects a known path with the wrong method", async () => {
    const response = await worker.fetch({ method: "DELETE", url: "https://proxy.example/v1/identify", headers: new Headers() }, allowAll());

    assert.equal(response.status, 404);
  });

  test("does not treat a trailing segment as a species id match for the collection route", async () => {
    const response = await worker.fetch(getRequest("/v1/plants/rosa/extra"), allowAll());

    assert.equal(response.status, 404);
  });

  test("decodes a percent-encoded species id", async () => {
    const response = await worker.fetch(getRequest("/v1/plants/rosa%2Dpalmatum"), allowAll());

    assert.equal(response.status, 404);
    assert.deepEqual(await response.json(), { error: "species_not_found" });
  });
});
