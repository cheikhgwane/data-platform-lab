#!/usr/bin/env bash
# Fails unless the expected number of replicas are streaming. Used by CI.
# Usage: scripts/assert_streaming.sh [primary-container] [expected-count]
set -euo pipefail
# shellcheck source=scripts/lib.sh
. "$(dirname "$0")/lib.sh"
PRIMARY="${1:-pg-primary}"
EXPECTED="${2:-2}"

for _ in $(seq 1 30); do
  count=$(psql_on "$PRIMARY" "SELECT count(*) FROM pg_stat_replication WHERE state = 'streaming';")
  if [ "$count" -ge "$EXPECTED" ]; then
    echo "OK: $count replica(s) streaming"
    exit 0
  fi
  sleep 1
done
echo "FAIL: only ${count:-0} replica(s) streaming, expected $EXPECTED" >&2
exit 1
