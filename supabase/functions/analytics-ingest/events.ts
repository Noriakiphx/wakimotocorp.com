import type { AnalyticsPayload, IngestContext } from "./types.ts";
type Client = { from: (table: string) => any };

export async function recordEvent(
  client: Client, context: IngestContext, payload: AnalyticsPayload,
) {
  const { error } = await client.from("vgi_events").upsert({
    visitor_id: context.visitorId,
    session_id: context.sessionId,
    event_key: payload.eventKey,
    event_type: payload.eventName ?? payload.type,
    event_category: payload.eventCategory ?? payload.type,
    event_action: payload.eventName ?? null,
    occurred_at: payload.occurredAt,
    page_path: payload.pagePath,
    numeric_value: payload.numericValue ?? payload.durationSeconds ?? null,
    event_data: {
      ...payload.metadata,
      durationSeconds: payload.durationSeconds ?? null,
      scrollPercent: payload.scrollPercent ?? null,
      converted: payload.converted === true,
    },
  }, { onConflict: "event_key" });
  if (error) throw new Error(`Event failed: ${error.message}`);
}
