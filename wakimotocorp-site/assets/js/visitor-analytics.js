(() => {
  "use strict";
  const endpoint = "/api/analytics-ingest";
  let startedAt = Date.now();
  let maxScroll = 0;
  let initialized = false;

  const consent = () =>
    window.WakimotoVisitorGeo?.getConsent?.().analytics === true;
  const id = (prefix) => `${prefix}_${crypto.randomUUID()}`;

  function stored(storage, key, prefix) {
    let value = storage.getItem(key);
    if (!value) {
      value = id(prefix);
      storage.setItem(key, value);
    }
    return value;
  }

  function attribution() {
    const query = new URLSearchParams(location.search);
    let referrerHost = null;
    try {
      referrerHost = document.referrer
        ? new URL(document.referrer).hostname
        : null;
    } catch {
      referrerHost = null;
    }
    return {
      referrerUrl: document.referrer || null,
      referrerHost,
      utmSource: query.get("utm_source"),
      utmMedium: query.get("utm_medium"),
      utmCampaign: query.get("utm_campaign"),
      utmTerm: query.get("utm_term"),
      utmContent: query.get("utm_content"),
    };
  }

  function device() {
    const ua = navigator.userAgent;
    return {
      language: navigator.language,
      browser: /Edg\//.test(ua) ? "Edge"
        : /Chrome\//.test(ua) ? "Chrome"
        : /Firefox\//.test(ua) ? "Firefox"
        : /Safari\//.test(ua) ? "Safari"
        : "Unknown",
      operatingSystem: /iPhone|iPad/.test(ua) ? "iOS"
        : /Android/.test(ua) ? "Android"
        : /Mac OS X/.test(ua) ? "macOS"
        : /Windows/.test(ua) ? "Windows"
        : "Unknown",
      deviceClass: innerWidth < 768
        ? "mobile"
        : innerWidth < 1100
        ? "tablet"
        : "desktop",
      viewportWidth: innerWidth,
      viewportHeight: innerHeight,
      screenWidth: screen.width,
      screenHeight: screen.height,
    };
  }

  function geo() {
    const snapshot = window.WakimotoVisitorGeo?.getSnapshot?.()?.geo ?? {};
    const value = snapshot.location ?? {};
    return {
      countryCode: value.countryCode,
      countryName: value.countryName,
      regionCode: value.regionCode,
      regionName: value.regionName,
      city: value.city,
      timezone: value.timezone,
      latitude: value.approximateLatitude,
      longitude: value.approximateLongitude,
    };
  }

  function send(data, beacon = false) {
    if (!consent()) return;
    const body = JSON.stringify({
      visitorKey: stored(localStorage, "vgi_visitor_key", "visitor"),
      sessionKey: stored(sessionStorage, "vgi_session", "session"),
      eventKey: id("event"),
      occurredAt: new Date().toISOString(),
      pageUrl: location.href,
      pagePath: location.pathname,
      pageTitle: document.title,
      attribution: attribution(),
      device: device(),
      geo: geo(),
      ...data,
    });
    if (beacon && navigator.sendBeacon) {
      navigator.sendBeacon(
        endpoint,
        new Blob([body], { type: "application/json" }),
      );
      return;
    }
    fetch(endpoint, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body,
      credentials: "same-origin",
      keepalive: beacon,
    }).catch(() => {});
  }

  function initialize() {
    if (initialized || !consent()) return;
    initialized = true;
    startedAt = Date.now();
    send({ type: "pageview" });
  }

  function engagement() {
    send({
      type: "engagement",
      eventName: "page_engagement",
      eventCategory: "engagement",
      durationSeconds: Math.round((Date.now() - startedAt) / 1000),
      scrollPercent: maxScroll,
    }, true);
  }

  function showConsentNotice() {
    if (window.WakimotoVisitorGeo?.getConsent?.().updatedAt) return;
    const notice = document.createElement("aside");
    notice.setAttribute("aria-label", "アクセス解析の設定");
    notice.style.cssText =
      "position:fixed;z-index:9999;left:16px;right:16px;bottom:16px;" +
      "max-width:720px;margin:auto;padding:16px;border-radius:12px;" +
      "background:#15110f;color:#fff;box-shadow:0 12px 36px #0005;" +
      "font:14px/1.6 sans-serif";
    notice.innerHTML =
      "<div>サイト改善のため、匿名化した地域・閲覧情報を利用します。" +
      "生のIPアドレスや正確な位置情報は保存しません。</div>" +
      "<div style='display:flex;gap:8px;margin-top:10px'>" +
      "<button type='button' data-vgi='accept'>許可する</button>" +
      "<button type='button' data-vgi='decline'>拒否する</button></div>";
    notice.querySelectorAll("button").forEach((button) => {
      button.style.cssText =
        "padding:8px 14px;border:1px solid #fff6;border-radius:7px;" +
        "background:#fff;color:#15110f;cursor:pointer";
    });
    notice.addEventListener("click", (event) => {
      const action = event.target?.dataset?.vgi;
      if (!action) return;
      const accepted = action === "accept";
      window.WakimotoVisitorGeo?.setConsent?.({
        analytics: accepted,
        preciseLocation: false,
      });
      if (accepted) {
        window.VisitorGeoHeatmap?.grantConsent?.();
        initialize();
      } else {
        window.VisitorGeoHeatmap?.revokeConsent?.();
      }
      notice.remove();
    });
    document.body.appendChild(notice);
  }

  addEventListener("scroll", () => {
    const height = document.documentElement.scrollHeight - innerHeight;
    maxScroll = Math.max(
      maxScroll,
      height > 0 ? Math.round(scrollY / height * 100) : 100,
    );
  }, { passive: true });
  addEventListener("pagehide", engagement);
  addEventListener("wakimoto:vgi-consent-changed", (event) => {
    if (event.detail?.analytics) initialize();
  });

  window.VisitorGeoAnalytics = Object.freeze({
    initialize,
    track(eventName, options = {}) {
      send({
        type: "event",
        eventName,
        eventCategory: options.category ?? "interaction",
        numericValue: options.value,
        converted: options.converted === true,
        metadata: options.metadata ?? {},
      });
    },
  });
  initialize();
  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", showConsentNotice, {
      once: true,
    });
  } else {
    showConsentNotice();
  }
})();
