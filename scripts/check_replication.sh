#!/usr/bin/env bash
# T1: show replication status as seen from the primary.
# Usage: scripts/check_replication.sh [primary-container]
set -euo pipefail
PRIMARY="${1:-pg-primary}"

docker exec "$PRIMARY" psql -U postgres -X -c "
  SELECT application_name,
         state,
         sync_state,
         write_lag,
         flush_lag,
         replay_lag,
         pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), replay_lsn)) AS replay_behind
  FROM pg_stat_replication
  ORDER BY application_name;"
