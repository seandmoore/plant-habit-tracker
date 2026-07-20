import assert from "node:assert/strict";
import test from "node:test";
import { mapHealthResults, mapSpeciesResults } from "../src/worker.mjs";

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
