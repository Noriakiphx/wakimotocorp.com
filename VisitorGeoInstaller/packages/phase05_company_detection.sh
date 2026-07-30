#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

MIGRATION="$ROOT_DIR/supabase/migrations/202607300003_visitor_geo_company_detection.sql"
DETECTION="$ROOT_DIR/supabase/functions/analytics-ingest/company-detection.ts"
ENV_FILE="$ROOT_DIR/.env.example"

echo "[Phase 05] Company detection"

test -f "$MIGRATION"
test -f "$DETECTION"
test -f "$ENV_FILE"

grep -q "vgi_company_matches" "$MIGRATION"
grep -q "attach_company_match" "$MIGRATION"
grep -q "classify_network_owner" "$MIGRATION"
grep -q "company_confidence" "$MIGRATION"

grep -q "createNetworkLookupHash" "$DETECTION"
grep -q "lookupCompanyByNetwork" "$DETECTION"
grep -q "buildCompanyMatchPayload" "$DETECTION"
grep -q "getRequestNetworkAddress" "$DETECTION"

grep -q "COMPANY_LOOKUP_URL" "$ENV_FILE"
grep -q "COMPANY_LOOKUP_HASH_SECRET" "$ENV_FILE"

if grep -RInE \
  'insert.*raw_ip|raw_ip.*insert|ip_address.*(insert|update)' \
  "$MIGRATION" \
  "$DETECTION"
then
  echo "ERROR: Potential raw-IP persistence detected."
  exit 1
fi

echo "[Phase 05] Validation passed"
echo "Migration: $MIGRATION"
echo "Detection module: $DETECTION"
