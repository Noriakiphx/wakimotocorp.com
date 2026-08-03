// deno-lint-ignore no-import-prefix
import { createClient } from "npm:@supabase/supabase-js@2.57.4";

function response(body: Record<string, unknown>, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "content-type": "application/json; charset=utf-8",
      "cache-control": "no-store, private",
    },
  });
}

Deno.serve(async (request) => {
  if (request.method !== "GET") {
    return response({ error: "Method not allowed" }, 405);
  }
  const expected = Deno.env.get("VGI_DASHBOARD_TOKEN");
  if (!expected || request.headers.get("x-vgi-dashboard-token") !== expected) {
    return response({ error: "Unauthorized" }, 401);
  }

  const url = Deno.env.get("SUPABASE_URL");
  const key = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ??
    Deno.env.get("SUPABASE_SECRET_KEY");
  if (!url || !key) return response({ error: "Service unavailable" }, 503);

  const requested = Number(new URL(request.url).searchParams.get("days") ?? 30);
  const days = Number.isFinite(requested)
    ? Math.max(1, Math.min(365, requested))
    : 30;
  const since = new Date(Date.now() - days * 86400000).toISOString();
  const client = createClient(url, key, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const [rollup, visitors, sessions, companies] = await Promise.all([
    client.rpc("vgi_dashboard_rollup", { p_since: since }),
    client.from("vgi_visitors")
      .select(
        "id,last_seen_at,visit_count,country_code,region_name,city,device_class,browser,intelligence_score,latest_referrer_host,latest_utm_source,latest_utm_medium",
      )
      .gte("last_seen_at", since).order("intelligence_score", {
        ascending: false,
      })
      .limit(250),
    client.from("vgi_sessions")
      .select(
        "id,started_at,duration_seconds,page_view_count,event_count,maximum_scroll_percent,entry_path,country_code,region_name,city,converted",
      )
      .gte("started_at", since).order("started_at", { ascending: false }).limit(
        1000,
      ),
    client.from("vgi_companies")
      .select(
        "id,company_name,domain,country_code,confidence_score,last_detected_at",
      )
      .eq("is_business", true).order("confidence_score", { ascending: false })
      .limit(50),
  ]);

  const failure = [rollup, visitors, sessions, companies]
    .map((result) => result.error).find(Boolean);
  if (failure) {
    console.error(failure.message);
    return response({ error: "Dashboard query failed" }, 500);
  }

  const visitorRows = (visitors.data ?? []) as Record<string, unknown>[];
  const sessionRows = (sessions.data ?? []) as Record<string, unknown>[];
  const metrics = (rollup.data ?? {}) as Record<string, unknown>;

  return response({
    ok: true,
    generatedAt: new Date().toISOString(),
    periodDays: days,
    summary: metrics.summary ?? {},
    topPages: metrics.topPages ?? [],
    topReferrers: metrics.topReferrers ?? [],
    topLocations: metrics.topLocations ?? [],
    topVisitors: visitorRows.slice(0, 100),
    topCompanies: companies.data ?? [],
    recentSessions: sessionRows.slice(0, 100),
  });
});
