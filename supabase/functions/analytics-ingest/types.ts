export type AnalyticsType = "pageview" | "engagement" | "event" | "heatmap";

export interface AnalyticsPayload {
  type: AnalyticsType;
  visitorKey: string;
  sessionKey: string;
  eventKey: string;
  occurredAt: string;
  pageUrl?: string;
  pagePath: string;
  pageTitle?: string;
  durationSeconds?: number;
  scrollPercent?: number;
  eventName?: string;
  eventCategory?: string;
  numericValue?: number;
  converted?: boolean;
  pointType?: "click" | "scroll" | "attention" | "exit";
  xPercent?: number;
  yPercent?: number;
  elementTag?: string;
  elementRole?: string;
  elementLabel?: string;
  geo: {
    countryCode?: string;
    countryName?: string;
    regionCode?: string;
    regionName?: string;
    city?: string;
    timezone?: string;
    latitude?: number;
    longitude?: number;
  };
  device: {
    language?: string;
    browser?: string;
    operatingSystem?: string;
    deviceClass: "desktop" | "tablet" | "mobile" | "unknown";
    viewportWidth?: number;
    viewportHeight?: number;
    screenWidth?: number;
    screenHeight?: number;
  };
  attribution: {
    referrerUrl?: string;
    referrerHost?: string;
    utmSource?: string;
    utmMedium?: string;
    utmCampaign?: string;
    utmTerm?: string;
    utmContent?: string;
  };
  metadata: Record<string, unknown>;
}

export interface IngestContext {
  visitorId: string;
  sessionId: string;
}
