#!/usr/bin/env bash
# T4: simulate a primary crash and fail over to pg-replica-1.
#   1. kill pg-primary (crash, not a clean shutdown)
#   2. promote pg-replica-1
#   3. repoint pg-replica-2 to the new primary
set -euo pipefail
# shellcheck source=scripts/lib.sh
. "$(dirname "$0")/lib.sh"

NEW_PRIMARY=pg-replica-1
FOLLOWER=pg-replica-2

start=$(now_ms)
echo "[1/4] Killing pg-primary"
docker kill pg-primary > /dev/null

echo "[2/4] Promoting $NEW_PRIMARY"
psql_on "$NEW_PRIMARY" "SELECT pg_promote(wait => true);" > /dev/null
promoted=$(now_ms)

echo "[3/4] Repointing $FOLLOWER to $NEW_PRIMARY"
# The follower keeps primary_slot_name='replica_2' from its base backup,
# so the new primary needs a slot with that name.
psql_on "$NEW_PRIMARY" "SELECT pg_create_physical_replication_slot('replica_2')
                        WHERE NOT EXISTS (SELECT 1 FROM pg_replication_slots WHERE slot_name = 'replica_2');" > /dev/null
# Since PostgreSQL 13, primary_conninfo changes apply on reload, no restart needed.
docker exec "$FOLLOWER" sh -c "psql -U postgres -X -q \
  -c \"ALTER SYSTEM SET primary_conninfo = 'host=$NEW_PRIMARY port=5432 user=replicator password=\$REPLICATION_PASSWORD application_name=pg_replica_2';\" \
  -c 'SELECT pg_reload_conf();'" > /dev/null

echo "[4/4] Checking writes on the new primary"
psql_on "$NEW_PRIMARY" "CREATE TABLE IF NOT EXISTS failover_check (id serial, at timestamptz DEFAULT now());
                        INSERT INTO failover_check DEFAULT VALUES;" > /dev/null
writable=$(now_ms)

"$(dirname "$0")/assert_streaming.sh" "$NEW_PRIMARY" 1
"$(dirname "$0")/check_replication.sh" "$NEW_PRIMARY"

echo
echo "Kill to promotion done:   $((promoted - start)) ms"
echo "Kill to first write:      $((writable - start)) ms"
echo "Note: this is the scripted, best case. Without automation, add the time a human needs to notice and react."
