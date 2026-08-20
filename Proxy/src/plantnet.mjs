import { PLANTNET_ORIGIN, UPSTREAM_TIMEOUT_MS } from "./config.mjs";
import { UpstreamError } from "./http.mjs";
import { mapHealthResults, mapSpeciesResults } from "./mappers.mjs";

export async function identify(image, contentType, apiKey, mode) {
  const tasks = [];
  if (mode === "species" || mode === "both") tasks.push(fetchSpecies(image, contentType, apiKey));
  if (mode === "health" || mode === "both") tasks.push(fetchHealth(image, contentType, apiKey));
  return (await Promise.all(tasks)).flat();
}

async function fetchSpecies(image, contentType, apiKey) {
  const response = await imageRequest(
    `/v2/identify/all?api-key=${encodeURIComponent(apiKey)}&lang=en&nb-results=4`,
    image,
    contentType,
  );
  return mapSpeciesResults(response.results || []);
}

async function fetchHealth(image, contentType, apiKey) {
  const response = await imageRequest(
    `/v2/diseases/identify?api-key=${encodeURIComponent(apiKey)}&lang=en&nb-results=3`,
    image,
    contentType,
  );
  return mapHealthResults(response.results || []);
}

async function imageRequest(path, image, contentType) {
  const form = new FormData();
  const extension = contentType === "image/png" ? "png" : "jpg";
  form.append("images", new Blob([image], { type: contentType }), `plant.${extension}`);
  form.append("organs", "auto");

  const response = await fetch(`${PLANTNET_ORIGIN}${path}`, {
    method: "POST",
    body: form,
    headers: { Accept: "application/json" },
    signal: AbortSignal.timeout(UPSTREAM_TIMEOUT_MS),
  });

  if (!response.ok) throw new UpstreamError(response.status);
  return response.json();
}
