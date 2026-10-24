#!/usr/bin/env bash
# T2: sample replication lag every second and write a CSV in results/.
# Usage: DURATION=60 scripts/lag_watch.sh
set -euo pipefail
DURATION="${DURATION:-60}"
PRIMARY="${PRIMARY:-pg-primary}"

mkdir -p results
OUT="results/lag_$(date +%Y%m%d_%H%M%S).csv"
echo "time,replica,bytes_behind,replay_lag_seconds" > "$OUT"

end=$((SECONDS + DURATION))
while [ "$SECONDS" -lt "$end" ]; do
  docker exec "$PRIMARY" psql -U postgres -X -A -t -F, -c "
    SELECT to_char(clock_timestamp(), 'HH24:MI:SS.MS'),
           application_name,
           pg_wal_lsn_diff(pg_current_wal_lsn(), replay_lsn),
           COALESCE(EXTRACT(EPOCH FROM replay_lag), 0)
    FROM pg_stat_replication
    ORDER BY application_name;" >> "$OUT"
  sleep 1
done
echo "Wrote $OUT"
