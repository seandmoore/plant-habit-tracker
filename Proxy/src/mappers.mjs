import { MAX_HEALTH_RESULTS, MAX_SPECIES_RESULTS } from "./config.mjs";

/**
 * Upstream responses are never forwarded as-is. Both mappers project them onto the
 * ScanCandidate shape in `Contract/scan-candidate.schema.json`, which keeps provider
 * fields, identifiers, and quota details out of the client.
 */
export function mapSpeciesResults(results) {
  return results.slice(0, MAX_SPECIES_RESULTS).map((result, index) => {
    const species = result.species || {};
    const scientificName = species.scientificNameWithoutAuthor || species.scientificName || "Unknown species";
    const commonName = Array.isArray(species.commonNames) && species.commonNames.length > 0
      ? species.commonNames[0]
      : scientificName;
    const family = species.family?.scientificNameWithoutAuthor || species.family?.scientificName;

    return {
      id: `species-${species.id || scientificName}-${index}`,
      title: commonName,
      scientificName,
      confidence: clampScore(result.score),
      detail: family
        ? `Plant family: ${family}. Compare several visible features before confirming.`
        : "Compare several visible features before confirming.",
      source: "Pl@ntNet",
    };
  });
}

/** Health output is always worded as a possibility — the "not a diagnosis" phrasing is part of the contract. */
export function mapHealthResults(results) {
  return results.slice(0, MAX_HEALTH_RESULTS).map((result, index) => ({
    id: `health-${result.name || index}`,
    title: result.description || result.name || "Possible visible health concern",
    scientificName: null,
    confidence: clampScore(result.score),
    detail: `EPPO code: ${result.name || "unavailable"}. This photo result is a possibility, not a diagnosis.`,
    source: "Pl@ntNet disease identification",
  }));
}

export function clampScore(value) {
  const number = Number(value);
  if (!Number.isFinite(number)) return 0;
  return Math.min(Math.max(number, 0), 1);
}
