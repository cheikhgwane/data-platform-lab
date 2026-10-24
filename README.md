# data-platform-lab

Hands-on labs for becoming a data platform architect: distributed systems, data modelling, orchestration, lakehouse, streaming, governance, cloud and AI engineering.

Every lab follows the same method:

1. **Spec first.** Each lab starts as a spec in `specs/`, with goals, constraints, tasks and acceptance criteria.
2. **Build.** Implementation is done by hand or with a coding agent, from the spec.
3. **Review.** Every change is reviewed before merge. The person, not the model, is accountable for what lands.
4. **Notes.** Each lab ends with a `NOTES.md` explaining what was observed, with evidence.

## Labs

| # | Lab | Week | Status |
|---|-----|------|--------|
| 001 | [PostgreSQL replication and failover](specs/001-postgres-replication.md) | 1 | in progress |

## Requirements

- Docker Desktop (or another Docker engine) with Docker Compose
- make, perl (both ship with macOS)
- shellcheck (`brew install shellcheck`)

## Lab 001 quick start

```bash
make up          # primary + 2 replicas, waits until healthy
make status      # replication state and lag
make load & make lag   # write load + lag sampling into results/
make sync-on     # replica 1 becomes synchronous (make sync-off to undo)
make failover    # crash the primary, promote replica 1, repoint replica 2
make rejoin      # pg_rewind the old primary back in as a replica
make down        # delete everything
```

Ports: primary 5432, replica 1 5433, replica 2 5434. Run `make help` for all targets.
