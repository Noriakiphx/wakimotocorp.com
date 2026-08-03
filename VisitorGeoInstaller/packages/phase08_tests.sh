#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

test -f "$ROOT/supabase/tests/database/visitor_geo.test.sql"
test -x "$ROOT/VisitorGeoInstaller/test.sh"

echo "[Phase 08] Test assets validation passed"
