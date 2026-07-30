import type { Config, Context } from "@netlify/edge-functions";

export default async function handler(request: Request, _context: Context) {
  if (request.method !== "GET") {
    return new Response("Method not allowed", { status: 405 });
  }
  const serviceKey = Netlify.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!serviceKey) return new Response("Service unavailable", { status: 503 });
  const incoming = new URL(request.url);
  const target = new URL(
    "https://emugamimrjvmfkshinxc.supabase.co/functions/v1/visitor-dashboard",
  );
  target.search = incoming.search;
  const headers = new Headers();
  headers.set("authorization", `Bearer ${serviceKey}`);
  headers.set("apikey", serviceKey);
  const dashboardToken = request.headers.get("x-vgi-dashboard-token");
  if (dashboardToken) headers.set("x-vgi-dashboard-token", dashboardToken);
  return fetch(target, { headers });
}

export const config: Config = { path: "/api/visitor-dashboard" };
