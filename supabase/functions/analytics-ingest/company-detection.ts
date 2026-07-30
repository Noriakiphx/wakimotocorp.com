export type CompanyDetectionDecision =
  | "business"
  | "isp"
  | "hosting"
  | "vpn"
  | "proxy"
  | "tor"
  | "residential"
  | "unknown";

export interface CompanyProviderResult {
  organizationName?: string;
  domain?: string;
  asn?: string;
  asName?: string;
  countryCode?: string;
  regionName?: string;
  city?: string;
  providerReference?: string;
  providerConfidence?: number;
  isIsp?: boolean;
  isHosting?: boolean;
  isVpn?: boolean;
  isProxy?: boolean;
  isTor?: boolean;
}

export interface CompanyMatchPayload {
  target_visitor_id: string;
  lookup_hash_value: string;
  organization_name_value: string | null;
  domain_value: string | null;
  asn_value: string | null;
  as_name_value: string | null;
  country_code_value: string | null;
  region_name_value: string | null;
  city_value: string | null;
  provider_name_value: string | null;
  provider_reference_value: string | null;
  provider_confidence_value: number | null;
  provider_flags_value: {
    is_isp: boolean;
    is_hosting: boolean;
    is_vpn: boolean;
    is_proxy: boolean;
    is_tor: boolean;
  };
  safe_metadata_value: Record<string, unknown>;
}

const encoder = new TextEncoder();

function bytesToHex(bytes: ArrayBuffer): string {
  return Array.from(new Uint8Array(bytes))
    .map((value) => value.toString(16).padStart(2, "0"))
    .join("");
}

function normalizeOptionalText(
  value: unknown,
  maximumLength = 255,
): string | null {
  if (typeof value !== "string") {
    return null;
  }

  const normalized = value.trim();

  if (!normalized) {
    return null;
  }

  return normalized.slice(0, maximumLength);
}

function normalizeConfidence(value: unknown): number | null {
  if (typeof value !== "number" || !Number.isFinite(value)) {
    return null;
  }

  return Math.max(0, Math.min(100, value));
}

/**
 * Generates a one-way HMAC identifier.
 *
 * The raw address must only exist transiently inside the Edge Function.
 * Never return it to the browser and never insert it into Supabase.
 */
export async function createNetworkLookupHash(
  rawNetworkAddress: string,
  secret: string,
): Promise<string> {
  if (!rawNetworkAddress || !secret) {
    throw new Error(
      "Network address and COMPANY_LOOKUP_HASH_SECRET are required",
    );
  }

  const key = await crypto.subtle.importKey(
    "raw",
    encoder.encode(secret),
    {
      name: "HMAC",
      hash: "SHA-256",
    },
    false,
    ["sign"],
  );

  const signature = await crypto.subtle.sign(
    "HMAC",
    key,
    encoder.encode(rawNetworkAddress),
  );

  return bytesToHex(signature);
}

function providerHeaders(): HeadersInit {
  const apiKey = Deno.env.get("COMPANY_LOOKUP_API_KEY");

  return {
    Accept: "application/json",
    ...(apiKey
      ? {
        Authorization: `Bearer ${apiKey}`,
      }
      : {}),
  };
}

/**
 * Provider-neutral lookup.
 *
 * Expected normalized provider response:
 * {
 *   "organizationName": "...",
 *   "domain": "...",
 *   "asn": "AS12345",
 *   "asName": "...",
 *   "countryCode": "JP",
 *   "regionName": "Saitama",
 *   "city": "Honjo",
 *   "providerReference": "...",
 *   "providerConfidence": 80,
 *   "isIsp": false,
 *   "isHosting": false,
 *   "isVpn": false,
 *   "isProxy": false,
 *   "isTor": false
 * }
 */
export async function lookupCompanyByNetwork(
  rawNetworkAddress: string,
): Promise<CompanyProviderResult | null> {
  const endpoint = Deno.env.get("COMPANY_LOOKUP_URL");

  if (!endpoint) {
    return null;
  }

  const url = new URL(endpoint);
  url.searchParams.set("ip", rawNetworkAddress);

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 2500);

  try {
    const response = await fetch(url, {
      method: "GET",
      headers: providerHeaders(),
      signal: controller.signal,
    });

    if (!response.ok) {
      console.warn(
        `Company lookup failed with HTTP ${response.status}`,
      );
      return null;
    }

    const data = await response.json() as Record<string, unknown>;

    return {
      organizationName:
        normalizeOptionalText(data.organizationName) ?? undefined,
      domain:
        normalizeOptionalText(data.domain) ?? undefined,
      asn:
        normalizeOptionalText(data.asn, 64) ?? undefined,
      asName:
        normalizeOptionalText(data.asName) ?? undefined,
      countryCode:
        normalizeOptionalText(data.countryCode, 8) ?? undefined,
      regionName:
        normalizeOptionalText(data.regionName) ?? undefined,
      city:
        normalizeOptionalText(data.city) ?? undefined,
      providerReference:
        normalizeOptionalText(data.providerReference) ?? undefined,
      providerConfidence:
        normalizeConfidence(data.providerConfidence) ?? undefined,
      isIsp: data.isIsp === true,
      isHosting: data.isHosting === true,
      isVpn: data.isVpn === true,
      isProxy: data.isProxy === true,
      isTor: data.isTor === true,
    };
  } catch (error) {
    console.warn(
      "Company lookup request failed",
      error instanceof Error ? error.message : error,
    );
    return null;
  } finally {
    clearTimeout(timeout);
  }
}

export async function buildCompanyMatchPayload(
  visitorId: string,
  rawNetworkAddress: string,
): Promise<CompanyMatchPayload | null> {
  const hashSecret =
    Deno.env.get("COMPANY_LOOKUP_HASH_SECRET");

  if (!hashSecret) {
    console.warn(
      "COMPANY_LOOKUP_HASH_SECRET is not configured",
    );
    return null;
  }

  const providerResult =
    await lookupCompanyByNetwork(rawNetworkAddress);

  if (!providerResult) {
    return null;
  }

  const lookupHash = await createNetworkLookupHash(
    rawNetworkAddress,
    hashSecret,
  );

  return {
    target_visitor_id: visitorId,
    lookup_hash_value: lookupHash,
    organization_name_value:
      providerResult.organizationName ?? null,
    domain_value:
      providerResult.domain?.toLowerCase() ?? null,
    asn_value:
      providerResult.asn ?? null,
    as_name_value:
      providerResult.asName ?? null,
    country_code_value:
      providerResult.countryCode?.toUpperCase() ?? null,
    region_name_value:
      providerResult.regionName ?? null,
    city_value:
      providerResult.city ?? null,
    provider_name_value:
      Deno.env.get("COMPANY_LOOKUP_PROVIDER") ?? "custom",
    provider_reference_value:
      providerResult.providerReference ?? null,
    provider_confidence_value:
      providerResult.providerConfidence ?? null,
    provider_flags_value: {
      is_isp: providerResult.isIsp === true,
      is_hosting: providerResult.isHosting === true,
      is_vpn: providerResult.isVpn === true,
      is_proxy: providerResult.isProxy === true,
      is_tor: providerResult.isTor === true,
    },
    safe_metadata_value: {
      lookup_version: "v1",
    },
  };
}

/**
 * Extracts the network address server-side.
 *
 * Never call this from browser code.
 * Never log or persist the returned raw value.
 */
export function getRequestNetworkAddress(
  request: Request,
): string | null {
  const candidates = [
    request.headers.get("cf-connecting-ip"),
    request.headers.get("x-nf-client-connection-ip"),
    request.headers.get("x-real-ip"),
    request.headers.get("x-forwarded-for")
      ?.split(",")[0]
      ?.trim(),
  ];

  return candidates.find((value) => Boolean(value)) ?? null;
}
