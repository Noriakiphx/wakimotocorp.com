import type { AnalyticsPayload, AnalyticsType } from "./types.ts";

const TYPES = new Set<AnalyticsType>([
  "pageview",
  "engagement",
  "event",
  "heatmap",
]);
const DEVICES = new Set(["desktop", "tablet", "mobile", "unknown"]);
const POINTS = new Set(["click", "scroll", "attention", "exit"]);
const MAX_PAST_AGE_MS = 24 * 60 * 60 * 1000;
const MAX_FUTURE_SKEW_MS = 5 * 60 * 1000;

function object(value: unknown): Record<string, unknown> {
  return value && typeof value === "object" && !Array.isArray(value)
    ? value as Record<string, unknown>
    : {};
}

function text(value: unknown, max: number): string | undefined {
  if (typeof value !== "string") return undefined;
  // deno-lint-ignore no-control-regex
  const result = value.replace(/[\u0000-\u001f\u007f]/g, "").trim();
  return result ? result.slice(0, max) : undefined;
}

function id(value: unknown): string | undefined {
  const result = text(value, 128);
  return result && /^[A-Za-z0-9._:-]+$/.test(result) ? result : undefined;
}

function number(value: unknown, min: number, max: number): number | undefined {
  return typeof value === "number" && Number.isFinite(value)
    ? Math.max(min, Math.min(max, value))
    : undefined;
}

export function validatePayload(
  raw: unknown,
  now = Date.now(),
): AnalyticsPayload {
  const input = object(raw);
  const type = text(input.type, 24) as AnalyticsType | undefined;
  const visitorKey = id(input.visitorKey);
  const sessionKey = id(input.sessionKey);
  const eventKey = id(input.eventKey);
  if (!type || !TYPES.has(type)) throw new Error("Invalid analytics type");
  if (!visitorKey || !sessionKey || !eventKey) {
    throw new Error("visitorKey, sessionKey and eventKey are required");
  }

  const occurredAt = text(input.occurredAt, 64) ?? new Date(now).toISOString();
  const occurredAtMs = Date.parse(occurredAt);
  if (
    Number.isNaN(occurredAtMs) ||
    occurredAtMs < now - MAX_PAST_AGE_MS ||
    occurredAtMs > now + MAX_FUTURE_SKEW_MS
  ) {
    throw new Error("Invalid occurredAt");
  }

  const geo = object(input.geo);
  const device = object(input.device);
  const attribution = object(input.attribution);
  const metadata = object(input.metadata);
  if (JSON.stringify(metadata).length > 4096) {
    throw new Error("Metadata too large");
  }

  const deviceClass = text(device.deviceClass, 16) ?? "unknown";
  const pointType = text(input.pointType, 24);
  if (type === "heatmap" && (!pointType || !POINTS.has(pointType))) {
    throw new Error("Invalid heatmap pointType");
  }

  return {
    type,
    visitorKey,
    sessionKey,
    eventKey,
    occurredAt,
    pageUrl: text(input.pageUrl, 2000),
    pagePath: text(input.pagePath, 1000) ?? "/",
    pageTitle: text(input.pageTitle, 300),
    durationSeconds: number(input.durationSeconds, 0, 86400),
    scrollPercent: number(input.scrollPercent, 0, 100),
    eventName: text(input.eventName, 128),
    eventCategory: text(input.eventCategory, 128),
    numericValue: number(input.numericValue, -1e9, 1e9),
    converted: input.converted === true,
    pointType: pointType as AnalyticsPayload["pointType"],
    xPercent: number(input.xPercent, 0, 100),
    yPercent: number(input.yPercent, 0, 100),
    elementTag: text(input.elementTag, 64),
    elementRole: text(input.elementRole, 128),
    elementLabel: text(input.elementLabel, 200),
    geo: {
      countryCode: text(geo.countryCode, 8)?.toUpperCase(),
      countryName: text(geo.countryName, 128),
      regionCode: text(geo.regionCode, 64),
      regionName: text(geo.regionName, 128),
      city: text(geo.city, 128),
      timezone: text(geo.timezone, 128),
      latitude: number(geo.latitude, -90, 90),
      longitude: number(geo.longitude, -180, 180),
    },
    device: {
      language: text(device.language, 64),
      browser: text(device.browser, 64),
      operatingSystem: text(device.operatingSystem, 64),
      deviceClass: DEVICES.has(deviceClass)
        ? deviceClass as AnalyticsPayload["device"]["deviceClass"]
        : "unknown",
      viewportWidth: number(device.viewportWidth, 0, 100000),
      viewportHeight: number(device.viewportHeight, 0, 100000),
      screenWidth: number(device.screenWidth, 0, 100000),
      screenHeight: number(device.screenHeight, 0, 100000),
    },
    attribution: {
      referrerUrl: text(attribution.referrerUrl, 2000),
      referrerHost: text(attribution.referrerHost, 255),
      utmSource: text(attribution.utmSource, 255),
      utmMedium: text(attribution.utmMedium, 255),
      utmCampaign: text(attribution.utmCampaign, 255),
      utmTerm: text(attribution.utmTerm, 255),
      utmContent: text(attribution.utmContent, 255),
    },
    metadata,
  };
}
