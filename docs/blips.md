---
title: Map blips
sidebar_position: 9
---

# Map blips

Blips are stored in `kora_mining_blips` and drawn on every client through `Kora.blips.create` from `kora_lib`. They are edited in the [Mining Creator](./creator.md) (Blips tab, up to 50 blips).

## Fields

| Field | Rule |
| --- | --- |
| `name` | 1 to 48 chars |
| `description` | Up to 200 chars; shown as a wrapped text row in the pause map card when not empty |
| `sprite` | Whole number 0 to 900 |
| `color` | Whole number 0 to 85 |
| `scale` | 0.1 to 3.0 |
| `shortRange` | Boolean |
| `x`, `y`, `z` | World coordinates within plus or minus 10000 |

The id is generated from the name when creating (lowercase, underscores, at most 26 chars, with a numeric suffix if taken).

## Behaviour

- The server loads blips after the schema is ready, publishes them in `GlobalState.koraMiningBlips` and pushes changes with `kora_mining:blips:reload`.
- Blips owned by `kora_lib` disappear when `kora_lib` restarts; the client re-creates missing ones when `kora_lib` starts and retries up to 10 times, 2 seconds apart, if creation fails.
- Stored blips that fail validation are skipped with a server console warning.

Seeded blips: `mine_shaft` (Mine Shaft, sprite 527) and `pickaxe_vendor` (Pickaxe Vendor, sprite 59).
