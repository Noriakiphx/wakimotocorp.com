import type { Context, Config } from "@netlify/edge-functions";

type GeoContext = {
  city?: string;
  country?: {
    code?: string;
    name?: string;
  };
  subdivision?: {
    code?: string;
    name?: string;
  };
  latitude?: number;
  longitude?: number;
  timezone?: string;
};

function maskIp(ip: string | undefined): string | null {
  if (!ip) return null;

  if (ip.includes(".")) {
    const parts = ip.split(".");
    if (parts.length === 4) {
      return `${parts[0]}.${parts[1]}.${parts[2]}.0`;
    }
  }

  if (ip.includes(":")) {
    const parts = ip.split(":").filter(Boolean);
    return `${parts.slice(0, 3).join(":")}::`;
  }

  return null;
}

function roundCoordinate(value: number | undefined): number | null {
  if (typeof value !== "number" || !Number.isFinite(value)) {
    return null;
  }

  // 約10km単位に丸め、不要な高精度位置情報を返さない
  return Math.round(value * 10) / 10;
}

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "content-type": "application/json; charset=utf-8",
      "cache-control": "no-store, private",
      "x-content-type-options": "nosniff",
      "referrer-policy": "strict-origin-when-cross-origin",
      "permissions-policy": "geolocation=(self)",
    },
  });
}

export default async function handler(
  request: Request,
  context: Context,
): Promise<Response> {
  if (request.method !== "GET") {
    return jsonResponse(
      { error: "Method not allowed" },
      405,
    );
  }

  const geo = (context.geo ?? {}) as GeoContext;
  const userAgent = request.headers.get("user-agent") ?? "";
  const language = request.headers.get("accept-language")?.split(",")[0] ?? null;
  const url = new URL(request.url);

  const payload = {
    version: "1.0",
    generatedAt: new Date().toISOString(),

    network: {
      maskedIp: maskIp(context.ip),
    },

    location: {
      countryCode: geo.country?.code ?? null,
      countryName: geo.country?.name ?? null,
      regionCode: geo.subdivision?.code ?? null,
      regionName: geo.subdivision?.name ?? null,
      city: geo.city ?? null,
      timezone: geo.timezone ?? null,
      approximateLatitude: roundCoordinate(geo.latitude),
      approximateLongitude: roundCoordinate(geo.longitude),
      precision: "coarse",
    },

    client: {
      language,
      deviceClass: /mobile|android|iphone|ipad/i.test(userAgent)
        ? "mobile"
        : "desktop",
    },

    request: {
      pathname: url.searchParams.get("path") ?? "/",
      referrerHost: url.searchParams.get("referrerHost") ?? null,
    },

    privacy: {
      rawIpStored: false,
      exactLocationStored: false,
      browserLocationRequiresConsent: true,
    },
  };

  return jsonResponse(payload);
}

export const config: Config = {
  path: "/api/visitor-geo",
  cache: "manual",
};
