#!/usr/bin/env bash
# Bootstraps a replica from the primary on first start, then runs postgres.
set -euo pipefail

if [ ! -s "$PGDATA/PG_VERSION" ]; then
  echo "Waiting for primary at ${PRIMARY_HOST}..."
  until pg_isready -h "$PRIMARY_HOST" -U postgres -q; do sleep 1; done

  echo "Taking base backup into $PGDATA using slot ${SLOT_NAME}..."
  # -R writes standby.signal and primary_conninfo; -S uses a replication slot.
  PGPASSWORD="$REPLICATION_PASSWORD" pg_basebackup \
    -h "$PRIMARY_HOST" -U replicator -D "$PGDATA" \
    -Fp -Xs -R -S "$SLOT_NAME" --progress
  chmod 0700 "$PGDATA"
fi

exec "$@"
