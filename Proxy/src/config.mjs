export const PLANTNET_ORIGIN = "https://my-api.plantnet.org";

export const MAX_IMAGE_BYTES = 10 * 1024 * 1024;

export const UPSTREAM_TIMEOUT_MS = 15_000;

export const ACCEPTED_IMAGE_TYPES = ["image/jpeg", "image/png"];

export const SCAN_MODES = ["species", "health", "both"];

/** A "both" scan costs two upstream calls, so it draws two tokens from the limiter. */
export const RATE_LIMIT_COST = { species: 1, health: 1, both: 2 };

export const MAX_SPECIES_RESULTS = 4;

export const MAX_HEALTH_RESULTS = 3;
