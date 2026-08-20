export const JPEG_HEADER = [0xff, 0xd8, 0xff];
export const PNG_HEADER = [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a];

export function streamOf(...chunks) {
  return new ReadableStream({
    start(controller) {
      for (const chunk of chunks) controller.enqueue(new Uint8Array(chunk));
      controller.close();
    },
  });
}

export function imageRequest({ mode = "species", headers = {}, body = streamOf(JPEG_HEADER), url } = {}) {
  return {
    method: "POST",
    url: url ?? `https://proxy.example/v1/identify?mode=${mode}`,
    headers: new Headers({ "content-type": "image/jpeg", "cf-connecting-ip": "203.0.113.8", ...headers }),
    body,
  };
}

export function getRequest(path) {
  return { method: "GET", url: `https://proxy.example${path}`, headers: new Headers() };
}

export function allowAll() {
  return { PLANTNET_API_KEY: "test-key", PLANT_RATE_LIMITER: { limit: async () => ({ success: true }) } };
}

/** Records how many tokens the limiter was asked for, which is how the "both" cost is asserted. */
export function countingLimiter(success = true) {
  const calls = [];
  return {
    calls,
    env: {
      PLANTNET_API_KEY: "test-key",
      PLANT_RATE_LIMITER: {
        limit: async (options) => {
          calls.push(options.key);
          return { success };
        },
      },
    },
  };
}

/** Replaces global fetch for one test so no test ever reaches the real Pl@ntNet API. */
export function withUpstream(handler, run) {
  const original = globalThis.fetch;
  globalThis.fetch = handler;
  return (async () => {
    try {
      return await run();
    } finally {
      globalThis.fetch = original;
    }
  })();
}

export function upstreamJson(payload, status = 200) {
  return async () => new Response(JSON.stringify(payload), { status, headers: { "Content-Type": "application/json" } });
}
