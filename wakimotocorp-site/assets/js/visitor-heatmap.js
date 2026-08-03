(() => {
  "use strict";

  const ENDPOINT = "/api/analytics-ingest";
  const STORAGE_KEY = "vgi_heatmap_consent";
  const MAX_EVENTS_PER_PAGE = 80;
  const SCROLL_STEP = 10;

  let eventCount = 0;
  let previousScrollBucket = -1;

  function hasConsent() {
    return window.localStorage.getItem(STORAGE_KEY) === "granted";
  }

  function percent(value, maximum) {
    if (!maximum || maximum <= 0) return 0;
    return Math.max(0, Math.min(100, (value / maximum) * 100));
  }

  function cleanLabel(element) {
    if (!(element instanceof Element)) return null;

    const label =
      element.getAttribute("aria-label") ||
      element.getAttribute("title") ||
      element.textContent ||
      "";

    return label.replace(/\s+/g, " ").trim().slice(0, 120) || null;
  }

  function send(point) {
    if (!hasConsent() || eventCount >= MAX_EVENTS_PER_PAGE) {
      return;
    }

    eventCount += 1;

    const payload = JSON.stringify({
      type: "heatmap",
      eventKey: crypto.randomUUID(),
      occurredAt: new Date().toISOString(),
      pagePath: window.location.pathname,
      viewportWidth: window.innerWidth,
      viewportHeight: window.innerHeight,
      ...point,
    });

    if (navigator.sendBeacon) {
      navigator.sendBeacon(
        ENDPOINT,
        new Blob([payload], {
          type: "application/json",
        }),
      );
      return;
    }

    fetch(ENDPOINT, {
      method: "POST",
      headers: {
        "content-type": "application/json",
      },
      body: payload,
      keepalive: true,
      credentials: "same-origin",
    }).catch(() => {});
  }

  document.addEventListener("click", (event) => {
    const target = event.target instanceof Element
      ? event.target.closest(
        "a,button,input,select,textarea,[role]",
      ) || event.target
      : null;

    send({
      pointType: "click",
      xPercent: percent(
        event.clientX,
        window.innerWidth,
      ),
      yPercent: percent(
        window.scrollY + event.clientY,
        document.documentElement.scrollHeight,
      ),
      scrollPercent: percent(
        window.scrollY + window.innerHeight,
        document.documentElement.scrollHeight,
      ),
      elementTag: target?.tagName?.toLowerCase() || null,
      elementRole: target?.getAttribute?.("role") || null,
      elementLabel: cleanLabel(target),
    });
  }, {
    passive: true,
  });

  window.addEventListener("scroll", () => {
    const current = Math.round(
      percent(
        window.scrollY + window.innerHeight,
        document.documentElement.scrollHeight,
      ),
    );

    const bucket = Math.floor(current / SCROLL_STEP) * SCROLL_STEP;

    if (bucket === previousScrollBucket) {
      return;
    }

    previousScrollBucket = bucket;

    send({
      pointType: "scroll",
      scrollPercent: bucket,
    });
  }, {
    passive: true,
  });

  window.VisitorGeoHeatmap = {
    grantConsent() {
      window.localStorage.setItem(STORAGE_KEY, "granted");
    },

    revokeConsent() {
      window.localStorage.removeItem(STORAGE_KEY);
    },

    hasConsent,
  };
})();
