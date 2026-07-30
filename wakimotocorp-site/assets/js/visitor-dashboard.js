(() => {
  "use strict";
  const tokenKey = "vgi_dashboard_token";
  const $ = (id) => document.getElementById(id);
  const escape = (value) => String(value ?? "").replace(
    /[&<>"']/g,
    (character) => ({
      "&": "&amp;",
      "<": "&lt;",
      ">": "&gt;",
      '"': "&quot;",
      "'": "&#39;",
    })[character],
  );
  const number = (value) =>
    new Intl.NumberFormat("ja-JP").format(Number(value ?? 0));
  const date = (value) =>
    value
      ? new Intl.DateTimeFormat("ja-JP", {
        dateStyle: "short",
        timeStyle: "short",
      }).format(new Date(value))
      : "—";

  function cards(summary) {
    const values = [
      ["訪問者", summary.visitors],
      ["セッション", summary.sessions],
      ["ページビュー", summary.pageViews],
      ["イベント", summary.events],
      ["CV", summary.conversions],
      ["CV率", `${summary.conversionRate}%`],
      ["直帰率", `${summary.bounceRate}%`],
      ["平均滞在", `${summary.averageDurationSeconds}秒`],
    ];
    $("summary").innerHTML = values.map(([label, value]) =>
      `<article><small>${escape(label)}</small><strong>${escape(value)}</strong></article>`
    ).join("");
  }

  function ranking(id, items) {
    $(id).innerHTML = (items ?? []).map((item) =>
      `<li><span>${escape(item.label)}</span><b>${number(item.value)}</b></li>`
    ).join("") || "<li>データなし</li>";
  }

  async function load() {
    const token = sessionStorage.getItem(tokenKey);
    if (!token) return;
    $("status").textContent = "読み込み中…";
    const response = await fetch(`/api/visitor-dashboard?days=${$("days").value}`, {
      headers: { "x-vgi-dashboard-token": token },
      cache: "no-store",
    });
    if (response.status === 401) {
      sessionStorage.removeItem(tokenKey);
      location.reload();
      return;
    }
    const data = await response.json();
    if (!response.ok) throw new Error(data.error ?? `HTTP ${response.status}`);
    cards(data.summary);
    ranking("pages", data.topPages);
    ranking("referrers", data.topReferrers);
    ranking("locations", data.topLocations);
    $("visitors").innerHTML = (data.topVisitors ?? []).map((row) =>
      `<tr><td>${escape(row.intelligence_score ?? "—")}</td>` +
      `<td>${escape(date(row.last_seen_at))}</td>` +
      `<td>${escape(
        [row.country_code, row.region_name, row.city].filter(Boolean).join(" / ")
          || "—",
      )}</td><td>${escape(row.device_class ?? "—")}</td>` +
      `<td>${number(row.visit_count)}</td></tr>`
    ).join("");
    $("status").textContent =
      `${data.periodDays}日間・更新 ${date(data.generatedAt)}`;
  }

  $("login").addEventListener("submit", (event) => {
    event.preventDefault();
    sessionStorage.setItem(tokenKey, $("token").value.trim());
    $("gate").hidden = true;
    $("dashboard").hidden = false;
    load().catch((error) => {
      $("status").textContent = error.message;
    });
  });
  $("refresh").addEventListener("click", () =>
    load().catch((error) => {
      $("status").textContent = error.message;
    })
  );
  $("days").addEventListener("change", () => $("refresh").click());
  if (sessionStorage.getItem(tokenKey)) {
    $("gate").hidden = true;
    $("dashboard").hidden = false;
    load().catch((error) => {
      $("status").textContent = error.message;
    });
  }
})();
