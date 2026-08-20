// Regenerates src/catalog.mjs from the shared contract so the Worker cannot drift from
// Contract/catalog.json. `npm test` fails if the generated file is stale, so running this
// is the intended way to adopt a catalog change.
import { readFileSync, writeFileSync } from "node:fs";
import { fileURLToPath } from "node:url";

const contractPath = fileURLToPath(new URL("../../Contract/catalog.json", import.meta.url));
const outputPath = fileURLToPath(new URL("../src/catalog.mjs", import.meta.url));

export function renderCatalogModule(contract) {
  const species = JSON.stringify(contract.species, null, 2)
    .replace(/"([A-Za-z][A-Za-z0-9]*)":/g, "$1:");

  return `// Generated from Contract/catalog.json by scripts/sync-catalog.mjs. Do not edit by hand.
// Serving the curated catalog here means care guidance can be corrected without an app release;
// it is deliberately the same reviewed data the apps bundle, never care values inferred from taxonomy.

export const CATALOG_VERSION = ${contract.version};

export const catalog = ${species};

export function searchCatalog(query) {
  const normalized = query.trim().toLocaleLowerCase();
  if (!normalized) return catalog;
  return catalog.filter((species) =>
    species.commonName.toLocaleLowerCase().includes(normalized)
    || species.scientificName.toLocaleLowerCase().includes(normalized));
}

export function findSpecies(id) {
  return catalog.find((species) => species.id === id);
}
`;
}

export function readContract() {
  return JSON.parse(readFileSync(contractPath, "utf8"));
}

export function readGeneratedModule() {
  return readFileSync(outputPath, "utf8");
}

if (import.meta.url === `file://${process.argv[1]}`) {
  writeFileSync(outputPath, renderCatalogModule(readContract()));
  console.log(`Wrote ${outputPath}`);
}
