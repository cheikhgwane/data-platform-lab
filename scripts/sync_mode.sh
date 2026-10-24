#!/usr/bin/env bash
# T3: switch pg_replica_1 between synchronous and asynchronous replication.
# Usage: scripts/sync_mode.sh on|off
set -euo pipefail
PRIMARY="${PRIMARY:-pg-primary}"

case "${1:-}" in
  on)  setting="ALTER SYSTEM SET synchronous_standby_names = 'pg_replica_1';" ;;
  off) setting="ALTER SYSTEM RESET synchronous_standby_names;" ;;
  *)   echo "Usage: $0 on|off" >&2; exit 2 ;;
esac

# ALTER SYSTEM cannot run inside a transaction block, so use separate -c flags.
docker exec "$PRIMARY" psql -U postgres -X -q -c "$setting" -c "SELECT pg_reload_conf();" > /dev/null
sleep 1
"$(dirname "$0")/check_replication.sh" "$PRIMARY"
