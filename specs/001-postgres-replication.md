# Spec 001: PostgreSQL replication and failover

Week 1 of the Data Platform Architect roadmap.
Status: draft (refine it before any agent writes code)

## Goal

Run a 3-node PostgreSQL cluster (1 primary, 2 replicas) locally with streaming replication, then break it on purpose to understand replication lag, synchronous vs asynchronous commits, failover, and split brain. The code is secondary: the real output is `NOTES.md`, where you explain what you observed in your own words.

## Why this matters for an architect

Every data platform decision about durability, availability and consistency comes back to replication. After this lab you should be able to answer, with evidence from your own runs: "If the primary dies right now, what data do we lose, and how long are we down?"

## Constraints

- Runs entirely on the MacBook with Docker Compose. No cloud.
- PostgreSQL 17 official image.
- Everything is started, tested and torn down with `make` targets or scripts in `scripts/`. No manual clicking.
- Bash scripts pass `shellcheck`.
- No secrets in the repo: credentials come from a `.env` file that is git-ignored, with a committed `.env.example`.

## Architecture

```
            writes + reads
  client ─────────────────▶ pg-primary
                               │  WAL stream
                 ┌─────────────┴─────────────┐
                 ▼                           ▼
           pg-replica-1                pg-replica-2
           (read-only)                 (read-only)
```

- `pg-primary`: `wal_level=replica`, `max_wal_senders` and `max_replication_slots` set, a dedicated replication user, `pg_hba.conf` entry for replication.
- Replicas bootstrap with `pg_basebackup -R`, each with its own physical replication slot.

## Out of scope

- Automatic failover tools (Patroni, repmgr). Failover is manual in this lab so you see every step. Patroni is an optional stretch goal.
- Connection routing (PgBouncer, HAProxy).
- Backups and point-in-time recovery (later week).

## Tasks and acceptance criteria

### T1. Cluster up
- `make up` starts the 3 nodes; `make down` removes them and their volumes.
- `scripts/check_replication.sh` prints, from `pg_stat_replication` on the primary, each replica's state, sync state and `write_lag`, `flush_lag`, `replay_lag`.
- **Accept:** a row inserted on the primary is readable on both replicas; an `INSERT` on a replica fails with a read-only error.

### T2. Measure replication lag
- `scripts/load.sh` runs `pgbench` against the primary for 60 seconds.
- `scripts/lag_watch.sh` samples lag every second during the load (bytes behind, using `pg_wal_lsn_diff`, and time lag) and writes a CSV.
- **Accept:** a CSV of lag over time for both replicas, and one paragraph in `NOTES.md` on what drives lag up.
- **Experiment:** throttle one replica (for example `docker pause` it for 10 seconds, or limit its CPU) and show the lag grow and recover.

### T3. Synchronous vs asynchronous
- Make `pg-replica-1` synchronous (`synchronous_standby_names`, `synchronous_commit=on`).
- **Experiment A:** stop `pg-replica-1`. What happens to commits on the primary? Measure it.
- **Experiment B:** compare pgbench throughput (TPS) and latency in async mode vs sync mode.
- **Accept:** a small table in `NOTES.md` with TPS and latency for both modes, and your explanation of the trade-off.

### T4. Manual failover
- `scripts/failover.sh`:
  1. Stops the primary (simulated crash: `docker kill`, not a clean shutdown).
  2. Promotes `pg-replica-1` (`SELECT pg_promote();`).
  3. Repoints `pg-replica-2` to the new primary (update `primary_conninfo`, restart).
- **Accept:** writes succeed on the new primary and appear on `pg-replica-2`. You recorded how long the cluster could not accept writes.
- **Experiment:** in async mode, insert a burst of rows and kill the primary immediately. Did any committed rows disappear after failover? Explain why.

### T5. Split brain
- Start the old primary again without reconfiguring it, while the promoted replica is also accepting writes.
- **Accept:** in `NOTES.md`, describe what you observe (two nodes accepting writes), why it is dangerous, and how real systems prevent it (fencing, leader election with a consensus store, `pg_rewind` to rejoin the old primary as a replica).
- **Stretch:** rejoin the old primary as a replica using `pg_rewind`.

### T6. CI
- GitHub Actions workflow on every push:
  - `shellcheck` on `scripts/`
  - `docker compose config` to validate the compose file
  - a smoke test: start the cluster, run `check_replication.sh`, assert both replicas are `streaming`, tear down
- **Accept:** green badge in the README.

## NOTES.md: questions to answer in your own words

1. What exactly is in the WAL, and what does a replica do with it?
2. Asynchronous replication: what is the maximum data you can lose on failover, and what does it depend on?
3. Synchronous replication: what did it cost you in latency and availability? When is it worth it?
4. What is a replication slot, and what happens to the primary's disk if a replica with a slot disappears for a day?
5. Why can't the old primary simply rejoin after a failover?
6. Link each answer to the matching section of *Designing Data-Intensive Applications* (replication chapter: leaders and followers, replication lag, failover; and the consistency and consensus chapter).

## Definition of done

- All tasks pass their acceptance criteria.
- `NOTES.md` answers every question with evidence from your own runs (numbers, logs, CSVs).
- README explains how to run the lab in under 5 commands.
- You can explain the failover sequence and the sync vs async trade-off out loud in 3 minutes, without notes.
