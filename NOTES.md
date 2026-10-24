# Lab 001 notes

Write in your own words, with evidence from your runs (numbers, CSVs, logs).

## Day 1: before building
- What does reliability mean for a data platform?
- Prediction: what happens when the primary dies?

## T2. Replication lag
- What drove lag up? (attach or summarise `results/lag_*.csv`)

## T3. Sync vs async

| Mode  | TPS | Avg latency (ms) |
|-------|-----|------------------|
| async |     |                  |
| sync  |     |                  |

- Experiment A: what happened to commits when the sync replica was stopped?
- Experiment B: the trade-off, in your words.

## T4. Failover
- Kill to first write: ___ ms
- Async burst then crash: did committed rows disappear? Why?

## T5. Split brain
- What did you observe with two primaries?
- How do real systems prevent it?

## Questions
1. What exactly is in the WAL, and what does a replica do with it?
2. Asynchronous replication: maximum data loss on failover, and what it depends on.
3. Synchronous replication: cost in latency and availability. When is it worth it?
4. What is a replication slot? What happens to the primary's disk if a replica with a slot disappears for a day?
5. Why can't the old primary simply rejoin after a failover?
6. Link each answer to the matching DDIA section.
