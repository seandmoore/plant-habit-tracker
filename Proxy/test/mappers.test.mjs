import assert from "node:assert/strict";
import test, { describe } from "node:test";
import { clampScore, mapHealthResults, mapSpeciesResults } from "../src/mappers.mjs";

describe("mapSpeciesResults", () => {
  test("projects an upstream result onto the contract shape", () => {
    const [candidate] = mapSpeciesResults([{
      score: 0.86,
      species: {
        id: "123",
        commonNames: ["Monstera"],
        scientificNameWithoutAuthor: "Monstera deliciosa",
        family: { scientificNameWithoutAuthor: "Araceae" },
      },
    }]);

    assert.deepEqual(candidate, {
      id: "species-123-0",
      title: "Monstera",
      scientificName: "Monstera deliciosa",
      confidence: 0.86,
      detail: "Plant family: Araceae. Compare several visible features before confirming.",
      source: "Pl@ntNet",
    });
  });

  test("falls back to the scientific name when no common name is offered", () => {
    const [candidate] = mapSpeciesResults([{ score: 0.4, species: { scientificNameWithoutAuthor: "Rosa canina", commonNames: [] } }]);

    assert.equal(candidate.title, "Rosa canina");
  });

  test("still produces a candidate when the species block is unusable", () => {
    const [candidate] = mapSpeciesResults([{ score: 0.1 }]);

    assert.equal(candidate.title, "Unknown species");
    assert.equal(candidate.detail, "Compare several visible features before confirming.");
  });

  test("caps the number of species candidates", () => {
    const results = mapSpeciesResults(Array.from({ length: 9 }, () => ({ score: 0.5, species: {} })));

    assert.equal(results.length, 4);
  });
});

describe("mapHealthResults", () => {
  test("words every health result as a possibility", () => {
    const [candidate] = mapHealthResults([{ name: "APHISP", score: 1.4, description: "Aphis sp." }]);

    assert.equal(candidate.title, "Aphis sp.");
    assert.equal(candidate.scientificName, null);
    assert.equal(candidate.confidence, 1);
    assert.match(candidate.detail, /not a diagnosis/);
  });

  test("never leaves a health result unlabelled", () => {
    const [candidate] = mapHealthResults([{ score: 0.2 }]);

    assert.equal(candidate.title, "Possible visible health concern");
    assert.match(candidate.detail, /EPPO code: unavailable/);
  });

  test("caps the number of health candidates", () => {
    assert.equal(mapHealthResults(Array.from({ length: 7 }, () => ({ score: 0.3 }))).length, 3);
  });
});

describe("clampScore", () => {
  test("keeps every score inside the contract range", () => {
    assert.equal(clampScore(1.4), 1);
    assert.equal(clampScore(-3), 0);
    assert.equal(clampScore("0.5"), 0.5);
    assert.equal(clampScore(undefined), 0);
    assert.equal(clampScore(Number.NaN), 0);
  });
});
