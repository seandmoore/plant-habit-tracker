// Regenerates src/data/catalog.ts from the shared contract. `npm test` fails when the
// generated file is stale, so running this is the intended way to adopt a catalog change.
import { readFileSync, writeFileSync } from "node:fs";
import { fileURLToPath } from "node:url";

const contractPath = fileURLToPath(new URL("../../Contract/catalog.json", import.meta.url));
const outputPath = fileURLToPath(new URL("../src/data/catalog.ts", import.meta.url));

export function renderCatalogModule(contract) {
  const entries = contract.species.map((species) => `  {
    id: ${JSON.stringify(species.id)},
    commonName: ${JSON.stringify(species.commonName)},
    scientificName: ${JSON.stringify(species.scientificName)},
    summary: ${JSON.stringify(species.summary)},
    baselineWateringDays: ${species.baselineWateringDays},
    light: ${JSON.stringify(species.light)},
    soil: ${JSON.stringify(species.soil)},
    humidity: ${JSON.stringify(species.humidity)},
    environments: [${species.environments.map((value) => JSON.stringify(value)).join(", ")}],${
      species.toxicityNote ? `\n    toxicityNote: ${JSON.stringify(species.toxicityNote)},` : ""
    }
    icon: ${JSON.stringify(species.icon)},
  },`).join("\n");

  return `// Generated from Contract/catalog.json by scripts/sync-catalog.mjs. Do not edit by hand.
import type { PlantSpecies } from '@/domain/types';

export const catalogVersion = ${contract.version};

export const starterCatalog: PlantSpecies[] = [
${entries}
];

export const findSpecies = (id: string | undefined): PlantSpecies | undefined =>
  id ? starterCatalog.find((species) => species.id === id) : undefined;
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
