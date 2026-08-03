#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

test -f "$ROOT/supabase/migrations/202607300005_visitor_geo_notifications.sql"
test -f "$ROOT/supabase/functions/visitor-alerts/index.ts"

grep -q "claim_notification_batch" \
  "$ROOT/supabase/migrations/202607300005_visitor_geo_notifications.sql"

echo "[Phase 07] Notifications validation passed"
