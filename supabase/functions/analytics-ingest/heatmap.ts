export interface HeatmapInput {
  eventKey: string;
  occurredAt?: string;
  pagePath: string;
  pointType: "click" | "scroll" | "attention" | "exit";
  xPercent?: number;
  yPercent?: number;
  scrollPercent?: number;
  viewportWidth?: number;
  viewportHeight?: number;
  elementTag?: string;
  elementRole?: string;
  elementLabel?: string;
  metadata?: Record<string, unknown>;
}

export interface HeatmapRpcPayload {
  target_visitor_id: string;
  target_session_id: string;
  event_key_value: string;
  occurred_at_value: string;
  page_path_value: string;
  point_type_value: HeatmapInput["pointType"];
  x_percent_value: number | null;
  y_percent_value: number | null;
  scroll_percent_value: number | null;
  viewport_width_value: number | null;
  viewport_height_value: number | null;
  element_tag_value: string | null;
  element_role_value: string | null;
  element_label_value: string | null;
  metadata_value: Record<string, unknown>;
}

function clamp(
  value: unknown,
  minimum: number,
  maximum: number,
): number | null {
  if (typeof value !== "number" || !Number.isFinite(value)) {
    return null;
  }

  return Math.max(minimum, Math.min(maximum, value));
}

function safeText(
  value: unknown,
  maximumLength: number,
): string | null {
  if (typeof value !== "string") {
    return null;
  }

  const normalized = value
    .replace(/\s+/g, " ")
    .trim();

  return normalized
    ? normalized.slice(0, maximumLength)
    : null;
}

export function buildHeatmapRpcPayload(
  visitorId: string,
  sessionId: string,
  input: HeatmapInput,
): HeatmapRpcPayload {
  if (!visitorId || !sessionId) {
    throw new Error("Visitor and session IDs are required");
  }

  if (!["click", "scroll", "attention", "exit"].includes(
    input.pointType,
  )) {
    throw new Error("Invalid heatmap point type");
  }

  return {
    target_visitor_id: visitorId,
    target_session_id: sessionId,
    event_key_value: safeText(input.eventKey, 128) ?? crypto.randomUUID(),
    occurred_at_value: input.occurredAt ?? new Date().toISOString(),
    page_path_value: safeText(input.pagePath, 1000) ?? "/",
    point_type_value: input.pointType,
    x_percent_value: clamp(input.xPercent, 0, 100),
    y_percent_value: clamp(input.yPercent, 0, 100),
    scroll_percent_value: clamp(input.scrollPercent, 0, 100),
    viewport_width_value: clamp(
      input.viewportWidth,
      0,
      100000,
    ),
    viewport_height_value: clamp(
      input.viewportHeight,
      0,
      100000,
    ),
    element_tag_value: safeText(input.elementTag, 64),
    element_role_value: safeText(input.elementRole, 128),
    element_label_value: safeText(input.elementLabel, 200),
    metadata_value: input.metadata ?? {},
  };
}
