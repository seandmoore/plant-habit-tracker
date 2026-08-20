const BASE_HEADERS = {
  "Content-Type": "application/json; charset=utf-8",
  "Cache-Control": "no-store",
  "Referrer-Policy": "no-referrer",
  "X-Content-Type-Options": "nosniff",
};

export function json(value, status = 200, extraHeaders = {}) {
  return new Response(JSON.stringify(value), {
    status,
    headers: { ...BASE_HEADERS, ...extraHeaders },
  });
}

/**
 * Every failure leaves through here, so responses stay a fixed set of machine-readable
 * codes and never leak an upstream body, a stack, or the configured API key.
 */
export function fail(code, status, extraHeaders = {}) {
  return json({ error: code }, status, extraHeaders);
}

export class HttpError extends Error {
  constructor(code, status, headers = {}) {
    super(code);
    this.code = code;
    this.status = status;
    this.headers = headers;
  }

  toResponse() {
    return fail(this.code, this.status, this.headers);
  }
}

export class UpstreamError extends Error {
  constructor(status) {
    super("Plant service request failed");
    this.status = status;
  }
}
