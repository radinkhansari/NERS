#!/usr/bin/env bash
# Prepare ONLY the schema for the Auto-Parts web app.
# No data, just DDL + view.
#
# Requires:
#   - Docker container "oracle-xe" running (or adjust SQLPLUS_CMD).
#   - web_schema.sql in the ./sql directory.

set -Eeuo pipefail

APP_NAME="Auto-Parts Web Schema Setup"
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SQL_DIR="${BASE_DIR}/sql"

# sqlplus via Docker (same pattern as your old menu.sh)
SQLPLUS_CMD="${SQLPLUS_CMD:-docker exec -i oracle-xe sqlplus}"
read -r -a SQLPLUS_ARR <<< "$SQLPLUS_CMD"

prompt_creds() {
  if [[ -z "${ORA_USER:-}" ]]; then
    read -rp "Enter Oracle Username [system]: " ORA_USER
    ORA_USER=${ORA_USER:-system}
  fi
  if [[ -z "${ORA_PASS:-}" ]]; then
    read -rsp "Enter Oracle Password [oracle]: " ORA_PASS
    ORA_PASS=${ORA_PASS:-oracle}
    echo
  fi
  if [[ -z "${ORA_DB:-}" ]]; then
    echo "Enter Oracle Database (EZCONNECT, e.g., localhost:1521/XEPDB1):"
    read -rp "> " ORA_DB
  fi
}

run_sql_file() {
  local title="$1"; shift
  local file="$1"; shift || true

  if [[ ! -f "$file" ]]; then
    echo "❌ SQL file not found on host: $file"
    exit 1
  fi

  echo "========================================="
  echo "▶ ${title}"
  echo "   File: $file"
  echo "========================================="

  # Read script on the host and pipe it into sqlplus INSIDE the container
  local script
  script="$(cat "$file")"

  "${SQLPLUS_ARR[@]}" -s "${ORA_USER}/${ORA_PASS}@${ORA_DB}" <<SQL
WHENEVER SQLERROR EXIT SQL.SQLCODE;
${script}
EXIT;
SQL

  echo
}

main() {
  echo "=== ${APP_NAME} ==="
  echo "SQL directory: ${SQL_DIR}"
  echo

  prompt_creds

  # Step 1: Create base schema
  run_sql_file "Web schema (tables, FKs, view)" "${SQL_DIR}/web_schema.sql"
  
  # Step 2: Create listing_fitment bridge table
  if [[ -f "${SQL_DIR}/add_listing_fitment.sql" ]]; then
    run_sql_file "Create listing_fitment bridge table" "${SQL_DIR}/add_listing_fitment.sql"
  else
    echo "⚠️  Warning: add_listing_fitment.sql not found, skipping..."
  fi
  
  # Step 3: Fix the view to use listing_fitment
  if [[ -f "${SQL_DIR}/fix_view.sql" ]]; then
    run_sql_file "Fix View_NormalizedFitment to use listing_fitment" "${SQL_DIR}/fix_view.sql"
  else
    echo "⚠️  Warning: fix_view.sql not found, skipping..."
  fi

  echo "========================================="
  echo "Schema prep complete (no demo data)."
  echo ""
  echo "To populate with demo data, run:"
  echo "  ${SQLPLUS_CMD} ${ORA_USER}/${ORA_PASS}@${ORA_DB} @${SQL_DIR}/web_demo_seed.sql"
  echo ""
  echo "Next steps (in your app env):"
  echo "  conda activate cps510"
  echo "  export ORA_USER=${ORA_USER}"
  echo "  export ORA_PASS=${ORA_PASS}"
  echo "  export ORA_DB=${ORA_DB}"
  echo "  python app.py"
  echo "========================================="
}

main "$@"