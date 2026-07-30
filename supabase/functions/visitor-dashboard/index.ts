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

function ranked(rows: Record<string, unknown>[], key: string, limit = 15) {
  const counts = new Map<string, number>();
  for (const row of rows) {
    const label = String(row[key] ?? "Unknown");
    counts.set(label, (counts.get(label) ?? 0) + 1);
  }
  return [...counts].map(([label, value]) => ({ label, value }))
    .sort((a, b) => b.value - a.value).slice(0, limit);
}

Deno.serve(async (request) => {
  if (request.method !== "GET") return response({ error: "Method not allowed" }, 405);
  const expected = Deno.env.get("VGI_DASHBOARD_TOKEN");
  if (!expected || request.headers.get("x-vgi-dashboard-token") !== expected) {
    return response({ error: "Unauthorized" }, 401);
  }

  const url = Deno.env.get("SUPABASE_URL");
  const key = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")
    ?? Deno.env.get("SUPABASE_SECRET_KEY");
  if (!url || !key) return response({ error: "Service unavailable" }, 503);

  const requested = Number(new URL(request.url).searchParams.get("days") ?? 30);
  const days = Number.isFinite(requested) ? Math.max(1, Math.min(365, requested)) : 30;
  const since = new Date(Date.now() - days * 86400000).toISOString();
  const client = createClient(url, key, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const [visitors, sessions, pages, events, companies] = await Promise.all([
    client.from("vgi_visitors")
      .select("id,last_seen_at,visit_count,country_code,region_name,city,device_class,browser,intelligence_score,latest_referrer_host,latest_utm_source,latest_utm_medium")
      .gte("last_seen_at", since).order("intelligence_score", { ascending: false })
      .limit(250),
    client.from("vgi_sessions")
      .select("id,started_at,duration_seconds,page_view_count,event_count,maximum_scroll_percent,entry_path,country_code,region_name,city,converted")
      .gte("started_at", since).order("started_at", { ascending: false }).limit(1000),
    client.from("vgi_page_views")
      .select("occurred_at,page_path,referrer_host")
      .gte("occurred_at", since).order("occurred_at", { ascending: false }).limit(5000),
    client.from("vgi_events").select("id", { count: "exact", head: true })
      .gte("occurred_at", since),
    client.from("vgi_companies")
      .select("id,company_name,domain,country_code,confidence_score,last_detected_at")
      .eq("is_business", true).order("confidence_score", { ascending: false }).limit(50),
  ]);

  const failure = [visitors, sessions, pages, events, companies]
    .map((result) => result.error).find(Boolean);
  if (failure) {
    console.error(failure.message);
    return response({ error: "Dashboard query failed" }, 500);
  }

  const visitorRows = (visitors.data ?? []) as Record<string, unknown>[];
  const sessionRows = (sessions.data ?? []) as Record<string, unknown>[];
  const pageRows = (pages.data ?? []) as Record<string, unknown>[];
  const conversions = sessionRows.filter((row) => row.converted === true).length;
  const bounces = sessionRows.filter((row) =>
    Number(row.page_view_count ?? 0) <= 1 && Number(row.event_count ?? 0) === 0
  ).length;
  const duration = sessionRows.reduce(
    (sum, row) => sum + Number(row.duration_seconds ?? 0), 0,
  );

  return response({
    ok: true,
    generatedAt: new Date().toISOString(),
    periodDays: days,
    summary: {
      visitors: visitorRows.length,
      sessions: sessionRows.length,
      pageViews: pageRows.length,
      events: events.count ?? 0,
      conversions,
      conversionRate: sessionRows.length
        ? Number((conversions / sessionRows.length * 100).toFixed(1)) : 0,
      bounceRate: sessionRows.length
        ? Number((bounces / sessionRows.length * 100).toFixed(1)) : 0,
      averageDurationSeconds: sessionRows.length
        ? Math.round(duration / sessionRows.length) : 0,
    },
    topPages: ranked(pageRows, "page_path"),
    topReferrers: ranked(pageRows, "referrer_host"),
    topLocations: ranked(visitorRows.map((row) => ({
      location: [row.country_code, row.region_name, row.city].filter(Boolean).join(" / ")
        || "Unknown",
    })), "location"),
    topVisitors: visitorRows.slice(0, 100),
    topCompanies: companies.data ?? [],
    recentSessions: sessionRows.slice(0, 100),
  });
});
