#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MIGRATION="$ROOT_DIR/supabase/migrations/202607300002_visitor_geo_scoring.sql"

echo "[Phase 04] Visitor intelligence scoring"

test -f "$MIGRATION"

grep -q \
  "calculate_visitor_score" \
  "$MIGRATION"

grep -q \
  "refresh_visitor_score" \
  "$MIGRATION"

grep -q \
  "refresh_all_visitor_scores" \
  "$MIGRATION"

grep -q \
  "vgi_sessions_refresh_score" \
  "$MIGRATION"

grep -q \
  "vgi_page_views_refresh_score" \
  "$MIGRATION"

grep -q \
  "vgi_events_refresh_score" \
  "$MIGRATION"

echo "[Phase 04] Validation passed"
echo "Migration: $MIGRATION"
