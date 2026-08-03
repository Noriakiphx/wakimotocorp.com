import type { AnalyticsPayload, IngestContext } from "./types.ts";

// Supabase's fluent query builder is intentionally duck-typed in this module.
// deno-lint-ignore no-explicit-any
type Client = { from: (table: string) => any };

export async function upsertVisitorSession(
  client: Client,
  payload: AnalyticsPayload,
  receivedAt = new Date().toISOString(),
): Promise<IngestContext> {
  const now = receivedAt;
  const { data: existingVisitor, error: visitorReadError } = await client
    .from("vgi_visitors").select("id").eq("visitor_key", payload.visitorKey)
    .maybeSingle();
  if (visitorReadError) {
    throw new Error(`Visitor lookup failed: ${visitorReadError.message}`);
  }
  const visitorValues = {
    visitor_key: payload.visitorKey,
    last_seen_at: now,
    country_code: payload.geo.countryCode ?? null,
    country_name: payload.geo.countryName ?? null,
    region_code: payload.geo.regionCode ?? null,
    region_name: payload.geo.regionName ?? null,
    city: payload.geo.city ?? null,
    timezone: payload.geo.timezone ?? null,
    approximate_latitude: payload.geo.latitude == null
      ? null
      : Math.round(payload.geo.latitude * 10) / 10,
    approximate_longitude: payload.geo.longitude == null
      ? null
      : Math.round(payload.geo.longitude * 10) / 10,
    language: payload.device.language ?? null,
    browser: payload.device.browser ?? null,
    operating_system: payload.device.operatingSystem ?? null,
    device_class: payload.device.deviceClass,
    latest_utm_source: payload.attribution.utmSource ?? null,
    latest_utm_medium: payload.attribution.utmMedium ?? null,
    latest_utm_campaign: payload.attribution.utmCampaign ?? null,
    latest_referrer_host: payload.attribution.referrerHost ?? null,
    updated_at: now,
  };
  const visitorQuery = existingVisitor
    ? client.from("vgi_visitors").update(visitorValues).eq(
      "id",
      existingVisitor.id,
    )
    : client.from("vgi_visitors").insert({
      ...visitorValues,
      first_seen_at: now,
      first_utm_source: payload.attribution.utmSource ?? null,
      first_utm_medium: payload.attribution.utmMedium ?? null,
      first_utm_campaign: payload.attribution.utmCampaign ?? null,
      first_referrer_host: payload.attribution.referrerHost ?? null,
      attributes: {},
    });
  const { data: visitor, error: visitorError } = await visitorQuery
    .select("id").single();
  if (visitorError) {
    throw new Error(`Visitor upsert failed: ${visitorError.message}`);
  }

  const { data: existingSession, error: sessionReadError } = await client
    .from("vgi_sessions")
    .select("id,duration_seconds,maximum_scroll_percent,converted")
    .eq("session_key", payload.sessionKey).maybeSingle();
  if (sessionReadError) {
    throw new Error(`Session lookup failed: ${sessionReadError.message}`);
  }
  const sessionValues = {
    session_key: payload.sessionKey,
    visitor_id: visitor.id,
    last_activity_at: now,
    exit_path: payload.pagePath,
    referrer_host: payload.attribution.referrerHost ?? null,
    utm_source: payload.attribution.utmSource ?? null,
    utm_medium: payload.attribution.utmMedium ?? null,
    utm_campaign: payload.attribution.utmCampaign ?? null,
    utm_term: payload.attribution.utmTerm ?? null,
    utm_content: payload.attribution.utmContent ?? null,
    country_code: payload.geo.countryCode ?? null,
    region_name: payload.geo.regionName ?? null,
    city: payload.geo.city ?? null,
    browser: payload.device.browser ?? null,
    operating_system: payload.device.operatingSystem ?? null,
    device_class: payload.device.deviceClass,
    viewport_width: payload.device.viewportWidth ?? null,
    viewport_height: payload.device.viewportHeight ?? null,
    screen_width: payload.device.screenWidth ?? null,
    screen_height: payload.device.screenHeight ?? null,
    duration_seconds: Math.max(
      Number(existingSession?.duration_seconds ?? 0),
      Math.round(payload.durationSeconds ?? 0),
    ),
    maximum_scroll_percent: Math.max(
      Number(existingSession?.maximum_scroll_percent ?? 0),
      Math.round(payload.scrollPercent ?? 0),
    ),
    converted: existingSession?.converted === true ||
      payload.converted === true,
    metadata: {},
    updated_at: now,
  };
  const sessionQuery = existingSession
    ? client.from("vgi_sessions").update(sessionValues).eq(
      "id",
      existingSession.id,
    )
    : client.from("vgi_sessions").insert({
      ...sessionValues,
      started_at: now,
      entry_path: payload.pagePath,
    });
  const { data: session, error: sessionError } = await sessionQuery
    .select("id").single();
  if (sessionError) {
    throw new Error(`Session upsert failed: ${sessionError.message}`);
  }
  return { visitorId: visitor.id, sessionId: session.id };
}

export async function refreshSessionCounts(
  client: Client,
  context: IngestContext,
) {
  const [pages, events] = await Promise.all([
    client.from("vgi_page_views").select("id", { count: "exact", head: true })
      .eq("session_id", context.sessionId),
    client.from("vgi_events").select("id", { count: "exact", head: true })
      .eq("session_id", context.sessionId),
  ]);
  if (pages.error || events.error) {
    throw new Error("Session count refresh failed");
  }
  await client.from("vgi_sessions").update({
    page_view_count: pages.count ?? 0,
    event_count: events.count ?? 0,
  }).eq("id", context.sessionId);
}
