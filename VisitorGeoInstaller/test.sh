#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$ROOT"

echo "===== Visitor Geo Intelligence Tests ====="

echo "[1/6] Git whitespace"
git diff --check

echo "[2/6] Required migrations"
test -f supabase/migrations/202607300001_visitor_geo_analytics.sql
test -f supabase/migrations/202607300002_visitor_geo_scoring.sql
test -f supabase/migrations/202607300003_visitor_geo_company_detection.sql
test -f supabase/migrations/202607300004_visitor_geo_heatmap.sql
test -f supabase/migrations/202607300005_visitor_geo_notifications.sql
test -f supabase/migrations/20260730074419_phase03_dashboard_analytics_ingest.sql
test -f supabase/migrations/202608030001_dashboard_rollup.sql

echo "[3/6] Privacy checks"
if grep -RInE \
  '(raw_ip|ip_address)[[:space:]]+(text|inet|varchar)|insert[^;]*(raw_ip|ip_address)' \
  supabase/migrations \
  supabase/functions
then
  echo "ERROR: Potential raw IP persistence detected."
  exit 1
fi

echo "[4/6] Heatmap checks"
grep -q "record_heatmap_point" \
  supabase/migrations/202607300004_visitor_geo_heatmap.sql

grep -q "VisitorGeoHeatmap" \
  wakimotocorp-site/assets/js/visitor-heatmap.js

grep -q "visitor-heatmap.js" \
  wakimotocorp-site/index.html

echo "[5/6] Notification checks"
grep -q "vgi_notification_queue" \
  supabase/migrations/202607300005_visitor_geo_notifications.sql

grep -q "VISITOR_ALERT_WEBHOOK_URL" \
  supabase/functions/visitor-alerts/index.ts

echo "[6/6] Installer packages"
for package in VisitorGeoInstaller/packages/*.sh; do
  bash "$package"
done

grep -q "visitor-analytics.js" wakimotocorp-site/index.html
grep -q "VGI_DASHBOARD_TOKEN" supabase/functions/visitor-dashboard/index.ts
grep -q "rateLimit" \
  wakimotocorp-site/netlify/edge-functions/analytics-ingest-proxy.ts

echo
echo "PASS: Static validation completed."
echo
echo "Database test command:"
echo "  npx supabase test db"
