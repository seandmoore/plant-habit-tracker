// Regenerates PlantCompanion/Core/Services/StarterCatalog.swift from the shared contract.
// PlantCompanionTests/ContractParityTests.swift fails when the two diverge, so running this is
// the intended way to adopt a catalog change.
//
// The catalog is generated as Swift source rather than a bundled JSON resource so it cannot fail
// to load at runtime, and so tests can read it without a bundle.
import { readFileSync, writeFileSync } from "node:fs";
import { fileURLToPath } from "node:url";

const contractPath = fileURLToPath(new URL("../Contract/catalog.json", import.meta.url));
const outputPath = fileURLToPath(new URL("../PlantCompanion/Core/Services/StarterCatalog.swift", import.meta.url));

const swiftString = (value) => JSON.stringify(value);
const swiftOptional = (value) => (value == null ? "nil" : swiftString(value));

export function renderCatalogSource(contract) {
  const entries = contract.species.map((species) => `        PlantSpecies(
            id: ${swiftString(species.id)},
            commonName: ${swiftString(species.commonName)},
            scientificName: ${swiftString(species.scientificName)},
            summary: ${swiftString(species.summary)},
            baselineWateringDays: ${species.baselineWateringDays},
            light: ${swiftString(species.light)},
            soil: ${swiftString(species.soil)},
            humidity: ${swiftString(species.humidity)},
            environments: [${species.environments.map((value) => `.${value}`).join(", ")}],
            toxicityNote: ${swiftOptional(species.toxicityNote)},
            symbolName: ${swiftString(species.symbolName)}
        )`).join(",\n");

  return `// Generated from Contract/catalog.json by Scripts/sync-swift-catalog.mjs. Do not edit by hand.
import Foundation

/// The curated catalog compiled into the app. Being source rather than a bundled resource means
/// it cannot fail to load at runtime and needs no bundle lookup in tests.
enum StarterCatalog {
    static let version = ${contract.version}

    static let species: [PlantSpecies] = [
${entries}
    ]
}
`;
}

export function readContract() {
  return JSON.parse(readFileSync(contractPath, "utf8"));
}

export function readGeneratedSource() {
  return readFileSync(outputPath, "utf8");
}

if (import.meta.url === `file://${process.argv[1]}`) {
  writeFileSync(outputPath, renderCatalogSource(readContract()));
  console.log(`Wrote ${outputPath}`);
}
