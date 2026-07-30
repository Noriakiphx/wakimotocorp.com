import type { Config, Context } from "@netlify/edge-functions";

export default async function handler(request: Request, _context: Context) {
  if (request.method !== "POST" && request.method !== "OPTIONS") {
    return new Response("Method not allowed", { status: 405 });
  }
  const serviceKey = Netlify.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!serviceKey) return new Response("Service unavailable", { status: 503 });
  const target = "https://emugamimrjvmfkshinxc.supabase.co/functions/v1/analytics-ingest";
  const headers = new Headers(request.headers);
  headers.set("authorization", `Bearer ${serviceKey}`);
  headers.set("apikey", serviceKey);
  headers.delete("host");
  return fetch(target, {
    method: request.method,
    headers,
    body: request.method === "POST" ? request.body : undefined,
  });
}

export const config: Config = { path: "/api/analytics-ingest" };
