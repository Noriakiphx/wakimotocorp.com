import type { AnalyticsPayload, IngestContext } from "./types.ts";
type Client = { from: (table: string) => any };

export async function recordPageView(
  client: Client, context: IngestContext, payload: AnalyticsPayload,
) {
  const { error } = await client.from("vgi_page_views").upsert({
    visitor_id: context.visitorId,
    session_id: context.sessionId,
    event_key: payload.eventKey,
    occurred_at: payload.occurredAt,
    page_url: payload.pageUrl ?? null,
    page_path: payload.pagePath,
    page_title: payload.pageTitle ?? null,
    referrer_url: payload.attribution.referrerUrl ?? null,
    referrer_host: payload.attribution.referrerHost ?? null,
    maximum_scroll_percent: payload.scrollPercent ?? null,
    utm_source: payload.attribution.utmSource ?? null,
    utm_medium: payload.attribution.utmMedium ?? null,
    utm_campaign: payload.attribution.utmCampaign ?? null,
    utm_term: payload.attribution.utmTerm ?? null,
    utm_content: payload.attribution.utmContent ?? null,
    metadata: payload.metadata,
  }, { onConflict: "event_key" });
  if (error) throw new Error(`Page view failed: ${error.message}`);
}
