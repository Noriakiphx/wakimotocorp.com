#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

test -f "$ROOT/supabase/migrations/202607300004_visitor_geo_heatmap.sql"
test -f "$ROOT/supabase/functions/analytics-ingest/heatmap.ts"
test -f "$ROOT/wakimotocorp-site/assets/js/visitor-heatmap.js"

grep -q "record_heatmap_point" \
  "$ROOT/supabase/migrations/202607300004_visitor_geo_heatmap.sql"

echo "[Phase 06] Heatmap validation passed"
