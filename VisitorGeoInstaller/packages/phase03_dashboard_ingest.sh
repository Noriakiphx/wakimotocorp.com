#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"
files=(
  supabase/functions/analytics-ingest/index.ts
  supabase/functions/visitor-dashboard/index.ts
  supabase/migrations/20260730074419_phase03_dashboard_analytics_ingest.sql
  wakimotocorp-site/netlify/edge-functions/analytics-ingest-proxy.ts
  wakimotocorp-site/netlify/edge-functions/visitor-dashboard-proxy.ts
  wakimotocorp-site/assets/js/visitor-analytics.js
  wakimotocorp-site/assets/js/visitor-dashboard.js
  wakimotocorp-site/visitor-dashboard/index.html
)
for file in "${files[@]}"; do test -s "$file"; done
grep -q "validatePayload" supabase/functions/analytics-ingest/index.ts
grep -q "VGI_DASHBOARD_TOKEN" supabase/functions/visitor-dashboard/index.ts
grep -q "visitor-analytics.js" wakimotocorp-site/index.html
if rg -n '(raw_ip|ip_address)\s+(text|inet|varchar)' supabase; then
  echo "Raw IP persistence detected"; exit 1
fi
echo "[Phase 03] Validation passed"
