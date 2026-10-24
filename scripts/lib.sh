#!/usr/bin/env bash
# Shared helpers. Compatible with bash 3.2 (default on macOS).

# psql_on <container> <sql...>: run SQL as postgres inside a container, unaligned output.
psql_on() {
  local container="$1"; shift
  docker exec "$container" psql -U postgres -X -A -t -v ON_ERROR_STOP=1 -c "$*"
}

now_ms() {
  # Portable millisecond timestamp (macOS date has no %N; perl ships with macOS).
  perl -MTime::HiRes=time -e 'printf("%d\n", time() * 1000)'
}
