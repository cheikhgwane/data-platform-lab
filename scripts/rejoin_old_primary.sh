#!/usr/bin/env bash
# T5 stretch: rewind the old primary and rejoin it as a replica of pg-replica-1.
# Run after scripts/failover.sh.
set -euo pipefail
# shellcheck source=scripts/lib.sh
. "$(dirname "$0")/lib.sh"
NEW_PRIMARY=pg-replica-1

echo "[1/4] Making sure the old primary is stopped"
docker stop pg-primary > /dev/null 2>&1 || true

echo "[2/4] Creating slot old_primary on $NEW_PRIMARY"
psql_on "$NEW_PRIMARY" "SELECT pg_create_physical_replication_slot('old_primary')
                        WHERE NOT EXISTS (SELECT 1 FROM pg_replication_slots WHERE slot_name = 'old_primary');" > /dev/null

echo "[3/4] Running pg_rewind against $NEW_PRIMARY"
# Runs in a one-off container that shares pg-primary's volume and network.
docker compose run --rm --no-deps --user postgres --entrypoint sh pg-primary -c "
  pg_rewind -D \"\$PGDATA\" --progress \
    --source-server='host=$NEW_PRIMARY port=5432 user=postgres password='\"\$POSTGRES_PASSWORD\"' dbname=postgres' &&
  touch \"\$PGDATA/standby.signal\" &&
  {
    echo \"primary_conninfo = 'host=$NEW_PRIMARY port=5432 user=replicator password=\$REPLICATION_PASSWORD application_name=pg_primary'\";
    echo \"primary_slot_name = 'old_primary'\";
  } >> \"\$PGDATA/postgresql.auto.conf\""

echo "[4/4] Starting the old primary as a replica"
docker start pg-primary > /dev/null
sleep 3
psql_on pg-primary "SELECT 'pg_primary in recovery: ' || pg_is_in_recovery();"
"$(dirname "$0")/check_replication.sh" "$NEW_PRIMARY"
