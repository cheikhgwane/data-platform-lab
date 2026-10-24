#!/usr/bin/env bash
# T2/T3: write load on the primary with pgbench.
# Usage: DURATION=60 CLIENTS=8 scripts/load.sh
set -euo pipefail
DURATION="${DURATION:-60}"
CLIENTS="${CLIENTS:-8}"
PRIMARY="${PRIMARY:-pg-primary}"

if ! docker exec "$PRIMARY" psql -U postgres -X -A -t -c "SELECT to_regclass('pgbench_accounts');" | grep -q pgbench; then
  echo "Initialising pgbench tables (scale 10)..."
  docker exec "$PRIMARY" pgbench -U postgres -i -s 10 postgres
fi

echo "Running pgbench: ${CLIENTS} clients for ${DURATION}s"
docker exec "$PRIMARY" pgbench -U postgres -c "$CLIENTS" -j 2 -T "$DURATION" -P 5 postgres
