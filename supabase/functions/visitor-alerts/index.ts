import {
  createClient,
} from "https://esm.sh/@supabase/supabase-js@2";

interface NotificationItem {
  id: string;
  payload: Record<string, unknown>;
  attempt_count: number;
}

function jsonResponse(
  body: Record<string, unknown>,
  status = 200,
): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "content-type": "application/json; charset=utf-8",
      "cache-control": "no-store",
    },
  });
}

async function deliverWebhook(
  webhookUrl: string,
  item: NotificationItem,
): Promise<void> {
  const controller = new AbortController();
  const timeout = setTimeout(
    () => controller.abort(),
    5000,
  );

  try {
    const response = await fetch(webhookUrl, {
      method: "POST",
      headers: {
        "content-type": "application/json",
        "user-agent": "VisitorGeoIntelligence/1.0",
      },
      body: JSON.stringify({
        type: "visitor_geo_alert",
        notificationId: item.id,
        occurredAt: new Date().toISOString(),
        ...item.payload,
      }),
      signal: controller.signal,
    });

    if (!response.ok) {
      throw new Error(
        `Webhook returned HTTP ${response.status}`,
      );
    }
  } finally {
    clearTimeout(timeout);
  }
}

Deno.serve(async (request: Request) => {
  if (request.method !== "POST") {
    return jsonResponse(
      {
        error: "Method not allowed",
      },
      405,
    );
  }

  const expectedToken =
    Deno.env.get("VISITOR_ALERT_JOB_TOKEN");

  const suppliedToken =
    request.headers.get("x-vgi-job-token");

  if (
    expectedToken &&
    suppliedToken !== expectedToken
  ) {
    return jsonResponse(
      {
        error: "Unauthorized",
      },
      401,
    );
  }

  const supabaseUrl =
    Deno.env.get("SUPABASE_URL");

  const serviceKey =
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ??
    Deno.env.get("SUPABASE_SECRET_KEY");

  if (!supabaseUrl || !serviceKey) {
    return jsonResponse(
      {
        error: "Supabase service configuration missing",
      },
      500,
    );
  }

  const webhookUrl =
    Deno.env.get("VISITOR_ALERT_WEBHOOK_URL");

  if (!webhookUrl) {
    return jsonResponse({
      processed: 0,
      skipped: true,
      reason: "VISITOR_ALERT_WEBHOOK_URL is not configured",
    });
  }

  const supabase = createClient(
    supabaseUrl,
    serviceKey,
    {
      auth: {
        persistSession: false,
      },
    },
  );

  const {
    data,
    error,
  } = await supabase.rpc(
    "claim_notification_batch",
    {
      batch_size: 20,
    },
    {
      head: false,
    },
  );

  if (error) {
    console.error("Queue claim failed", error.message);

    return jsonResponse(
      {
        error: "Unable to claim notification queue",
      },
      500,
    );
  }

  const items = Array.isArray(data)
    ? data as NotificationItem[]
    : [];

  let sent = 0;
  let failed = 0;

  for (const item of items) {
    try {
      await deliverWebhook(webhookUrl, item);

      const { error: updateError } = await supabase
        .from("vgi_notification_queue")
        .update({
          status: "sent",
          sent_at: new Date().toISOString(),
          locked_at: null,
          last_error: null,
          updated_at: new Date().toISOString(),
        })
        .eq("id", item.id);

      if (updateError) {
        throw updateError;
      }

      sent += 1;
    } catch (deliveryError) {
      failed += 1;

      const message = deliveryError instanceof Error
        ? deliveryError.message
        : "Unknown notification failure";

      const retryMinutes = Math.min(
        1440,
        Math.max(
          5,
          5 * Math.pow(
            2,
            Math.max(0, item.attempt_count - 1),
          ),
        ),
      );

      await supabase
        .from("vgi_notification_queue")
        .update({
          status:
            item.attempt_count >= 5
              ? "failed"
              : "pending",
          next_attempt_at: new Date(
            Date.now() + retryMinutes * 60_000,
          ).toISOString(),
          locked_at: null,
          last_error: message.slice(0, 1000),
          updated_at: new Date().toISOString(),
        })
        .eq("id", item.id);
    }
  }

  return jsonResponse({
    processed: items.length,
    sent,
    failed,
  });
});
