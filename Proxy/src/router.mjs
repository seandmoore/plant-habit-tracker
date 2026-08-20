import { fail, HttpError } from "./http.mjs";

/**
 * A route is matched on method plus an exact path or a single `{param}` segment. Keeping the
 * matcher this small means the entry point reads as a table of endpoints instead of a chain
 * of conditionals, and an unmatched request can only ever produce `not_found`.
 */
export function createRouter(routes) {
  const compiled = routes.map((route) => ({ ...route, segments: route.path.split("/") }));

  return async function handle(request, env, context) {
    const url = new URL(request.url);
    const segments = url.pathname.split("/");

    for (const route of compiled) {
      if (route.method !== request.method) continue;
      const params = matchSegments(route.segments, segments);
      if (!params) continue;

      try {
        return await route.handler({ request, env, context, url, params });
      } catch (error) {
        if (error instanceof HttpError) return error.toResponse();
        throw error;
      }
    }

    return fail("not_found", 404);
  };
}

function matchSegments(routeSegments, pathSegments) {
  if (routeSegments.length !== pathSegments.length) return null;

  const params = {};
  for (const [index, expected] of routeSegments.entries()) {
    const actual = pathSegments[index];
    if (expected.startsWith("{") && expected.endsWith("}")) {
      if (!actual) return null;
      params[expected.slice(1, -1)] = decodeURIComponent(actual);
      continue;
    }
    if (expected !== actual) return null;
  }
  return params;
}
