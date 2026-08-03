export function cors(request: Request): Record<string, string> {
  const origin = request.headers.get("origin");
  const allowed = (Deno.env.get("VGI_ALLOWED_ORIGINS") ?? "")
    .split(",").map((value) => value.trim()).filter(Boolean);
  const permitted = !origin || allowed.includes(origin);
  return {
    "access-control-allow-origin": permitted && origin ? origin : "null",
    "access-control-allow-methods": "POST, OPTIONS",
    "access-control-allow-headers": "content-type",
    "access-control-max-age": "86400",
    "cache-control": "no-store",
    "vary": "origin",
  };
}

export function json(
  request: Request,
  body: Record<string, unknown>,
  status = 200,
): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...cors(request), "content-type": "application/json; charset=utf-8" },
  });
}
