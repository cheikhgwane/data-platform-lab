#!/usr/bin/env bash
# Runs once, on first start of the primary (docker-entrypoint-initdb.d).
set -euo pipefail

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname postgres <<SQL
CREATE ROLE replicator WITH REPLICATION LOGIN PASSWORD '${REPLICATION_PASSWORD}';
SELECT pg_create_physical_replication_slot('replica_1');
SELECT pg_create_physical_replication_slot('replica_2');
SQL

# Replication connections need their own pg_hba line: "all" does not match them.
echo "host replication replicator all scram-sha-256" >> "$PGDATA/pg_hba.conf"
