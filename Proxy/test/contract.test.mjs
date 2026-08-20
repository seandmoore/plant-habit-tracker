import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import test, { describe } from "node:test";
import { catalog, CATALOG_VERSION } from "../src/catalog.mjs";
import { mapHealthResults, mapSpeciesResults } from "../src/mappers.mjs";
import { readContract, readGeneratedModule, renderCatalogModule } from "../scripts/sync-catalog.mjs";
import { validate } from "./schema.mjs";

const contractFile = (name) =>
  JSON.parse(readFileSync(fileURLToPath(new URL(`../../Contract/${name}`, import.meta.url)), "utf8"));

describe("contract parity", () => {
  test("the generated catalog module is not stale", () => {
    assert.equal(
      readGeneratedModule(),
      renderCatalogModule(readContract()),
      "src/catalog.mjs has drifted from Contract/catalog.json — run `npm run sync:catalog`",
    );
  });

  test("the served catalog matches the contract exactly", () => {
    const contract = contractFile("catalog.json");

    assert.equal(CATALOG_VERSION, contract.version);
    assert.deepEqual(catalog, contract.species);
  });

  test("every served species satisfies the published species schema", () => {
    assert.deepEqual(validate(contractFile("species.schema.json"), catalog), []);
  });

  test("mapped species candidates satisfy the published scan schema", () => {
    const candidates = mapSpeciesResults([
      { score: 0.86, species: { id: "1", commonNames: ["Monstera"], scientificNameWithoutAuthor: "Monstera deliciosa", family: { scientificNameWithoutAuthor: "Araceae" } } },
      { score: 2, species: {} },
    ]);

    assert.deepEqual(validate(contractFile("scan-candidate.schema.json"), candidates), []);
  });

  test("mapped health candidates satisfy the published scan schema", () => {
    const candidates = mapHealthResults([{ name: "APHISP", score: 0.61, description: "Aphis sp." }, { score: -1 }]);

    assert.deepEqual(validate(contractFile("scan-candidate.schema.json"), candidates), []);
  });

  test("catalog baseline intervals stay inside the contract bounds", () => {
    const { bounds } = contractFile("care-rules.json");

    for (const species of catalog) {
      assert.ok(
        species.baselineWateringDays >= bounds.minimumIntervalDays
        && species.baselineWateringDays <= bounds.maximumIntervalDays,
        `${species.id} baseline is outside the planner bounds`,
      );
    }
  });

  test("every catalog environment is one the care rules can score", () => {
    const known = new Set(contractFile("care-rules.json").environmentModifiers.map((entry) => entry.key));

    for (const species of catalog) {
      for (const environment of species.environments) {
        assert.ok(known.has(environment), `${species.id} lists unknown environment "${environment}"`);
      }
    }
  });
});
