#!/usr/bin/env bash
set -Eeuo pipefail

INSTALLER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_ROOT="$(cd "$INSTALLER_DIR/.." && pwd)"

MIGRATION="$REPO_ROOT/supabase/migrations/202607300001_visitor_geo_analytics.sql"
ENV_EXAMPLE="$REPO_ROOT/.env.example"

echo "[Phase 02] Supabase analytics schema"

if [[ ! -f "$MIGRATION" ]]; then
  echo "ERROR: Migration file not found:"
  echo "$MIGRATION"
  exit 1
fi

if [[ ! -f "$ENV_EXAMPLE" ]]; then
  echo "ERROR: .env.example not found"
  exit 1
fi

required_tables=(
  "vgi_visitors"
  "vgi_sessions"
  "vgi_page_views"
  "vgi_events"
  "vgi_heatmap_points"
  "vgi_companies"
  "vgi_intelligence_scores"
)

for table in "${required_tables[@]}"; do
  if ! grep -Fq "public.$table" "$MIGRATION"; then
    echo "ERROR: Table definition missing: $table"
    exit 1
  fi
done

required_rls_tables=(
  "vgi_visitors"
  "vgi_sessions"
  "vgi_page_views"
  "vgi_events"
  "vgi_heatmap_points"
  "vgi_companies"
  "vgi_intelligence_scores"
)

for table in "${required_rls_tables[@]}"; do
  if ! grep -Fq \
    "alter table public.$table enable row level security;" \
    "$MIGRATION"; then
    echo "ERROR: RLS configuration missing: $table"
    exit 1
  fi
done

if grep -Eq \
  'SUPABASE_(SECRET_KEY|SERVICE_ROLE_KEY)=.+(eyJ|sb_secret_[A-Za-z0-9_-]{10,})' \
  "$ENV_EXAMPLE"; then
  echo "ERROR: .env.example may contain a real secret."
  exit 1
fi

if command -v supabase >/dev/null 2>&1; then
  echo "Supabase CLI detected: $(supabase --version)"
else
  echo "INFO: Supabase CLI is not installed yet."
  echo "The migration file has still been prepared successfully."
fi

git diff --check -- \
  "$MIGRATION" \
  "$ENV_EXAMPLE" \
  "$INSTALLER_DIR/packages/phase02_supabase.sh"

echo
echo "[Phase 02] Schema validation passed"
echo "Migration: $MIGRATION"
echo "Environment template: $ENV_EXAMPLE"
