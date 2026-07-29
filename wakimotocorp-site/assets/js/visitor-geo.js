(() => {
  "use strict";

  const ENDPOINT = "/api/visitor-geo";
  const STORAGE_KEY = "wakimoto_visitor_geo";
  const SESSION_KEY = "wakimoto_visitor_geo_sent";

  function safeReferrerHost() {
    if (!document.referrer) return "";

    try {
      return new URL(document.referrer).hostname;
    } catch {
      return "";
    }
  }

  function saveGeo(data) {
    try {
      localStorage.setItem(
        STORAGE_KEY,
        JSON.stringify({
          savedAt: new Date().toISOString(),
          data,
        }),
      );
    } catch {
      // Storage拒否時もページ動作を妨げない
    }
  }

  function emitReady(data) {
    window.dispatchEvent(
      new CustomEvent("wakimoto:visitor-geo-ready", {
        detail: data,
      }),
    );
  }

  async function loadVisitorGeo() {
    try {
      if (sessionStorage.getItem(SESSION_KEY) === "1") {
        const cached = localStorage.getItem(STORAGE_KEY);

        if (cached) {
          const parsed = JSON.parse(cached);
          emitReady(parsed.data);
          return parsed.data;
        }
      }

      const params = new URLSearchParams({
        path: window.location.pathname,
        referrerHost: safeReferrerHost(),
      });

      const response = await fetch(`${ENDPOINT}?${params.toString()}`, {
        method: "GET",
        credentials: "same-origin",
        headers: {
          accept: "application/json",
        },
      });

      if (!response.ok) {
        throw new Error(`Visitor Geo request failed: ${response.status}`);
      }

      const data = await response.json();

      saveGeo(data);
      sessionStorage.setItem(SESSION_KEY, "1");
      emitReady(data);

      return data;
    } catch (error) {
      console.warn("[Visitor Geo Intelligence]", error);
      return null;
    }
  }

  async function requestPreciseLocation() {
    if (!("geolocation" in navigator)) {
      throw new Error("Geolocation is not supported.");
    }

    return new Promise((resolve, reject) => {
      navigator.geolocation.getCurrentPosition(
        (position) => {
          resolve({
            latitude: position.coords.latitude,
            longitude: position.coords.longitude,
            accuracyMeters: position.coords.accuracy,
            collectedAt: new Date(position.timestamp).toISOString(),
            consent: true,
          });
        },
        reject,
        {
          enableHighAccuracy: false,
          timeout: 10000,
          maximumAge: 300000,
        },
      );
    });
  }

  window.WakimotoVisitorGeo = {
    load: loadVisitorGeo,
    requestPreciseLocation,
    readCached() {
      try {
        const value = localStorage.getItem(STORAGE_KEY);
        return value ? JSON.parse(value) : null;
      } catch {
        return null;
      }
    },
  };

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", loadVisitorGeo, {
      once: true,
    });
  } else {
    loadVisitorGeo();
  }
})();
