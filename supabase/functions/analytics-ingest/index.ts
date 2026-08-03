// deno-lint-ignore no-import-prefix
import { createClient } from "npm:@supabase/supabase-js@2.57.4";
import { validatePayload } from "./validation.ts";
import { refreshSessionCounts, upsertVisitorSession } from "./upsert.ts";
import { recordPageView } from "./pageview.ts";
import { recordEvent } from "./events.ts";
import { cors, json } from "./response.ts";

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: cors(request) });
  }
  if (request.method !== "POST") {
    return json(request, { error: "Method not allowed" }, 405);
  }
  const origin = request.headers.get("origin");
  if (origin && cors(request)["access-control-allow-origin"] === "null") {
    return json(request, { error: "Origin not allowed" }, 403);
  }
  const url = Deno.env.get("SUPABASE_URL");
  const key = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ??
    Deno.env.get("SUPABASE_SECRET_KEY");
  if (!url || !key) return json(request, { error: "Service unavailable" }, 503);

  let payload: ReturnType<typeof validatePayload>;
  try {
    const body = await request.text();
    if (body.length > 32768) {
      return json(request, { error: "Body too large" }, 413);
    }
    payload = validatePayload(JSON.parse(body));
  } catch (error) {
    console.warn(error instanceof Error ? error.message : error);
    return json(request, { error: "Invalid analytics request" }, 400);
  }

  try {
    const client = createClient(url, key, {
      auth: { persistSession: false, autoRefreshToken: false },
    });
    const context = await upsertVisitorSession(client, payload);

    if (payload.type === "pageview") {
      await recordPageView(client, context, payload);
    }
    if (payload.type === "event" || payload.type === "engagement") {
      await recordEvent(client, context, payload);
    }
    if (payload.type === "heatmap") {
      const { error } = await client.from("vgi_heatmap_points").upsert({
        visitor_id: context.visitorId,
        session_id: context.sessionId,
        event_key: payload.eventKey,
        occurred_at: payload.occurredAt,
        page_path: payload.pagePath,
        point_type: payload.pointType ?? "attention",
        x_percent: payload.xPercent ?? null,
        y_percent: payload.yPercent ?? null,
        scroll_percent: Math.round(payload.scrollPercent ?? 0),
        viewport_width: payload.device.viewportWidth ?? null,
        viewport_height: payload.device.viewportHeight ?? null,
        element_tag: payload.elementTag ?? null,
        element_role: payload.elementRole ?? null,
        element_label: payload.elementLabel ?? null,
        metadata: payload.metadata,
      }, { onConflict: "event_key" });
      if (error) throw new Error(`Heatmap failed: ${error.message}`);
    }

    await refreshSessionCounts(client, context);
    return json(request, { ok: true, accepted: payload.type }, 202);
  } catch (error) {
    console.error(error instanceof Error ? error.message : error);
    return json(request, { error: "Analytics service failed" }, 500);
  }
});
