---
title: Database
sidebar_position: 13
---

# Database

Tables are created by `server/schema.lua` through `Kora.sql.ensureTables` on first start; there is no SQL file to import. Every table uses collation `utf8mb4_general_ci`, primary key `id`, and stores its content as JSON text.

Each table has a seed with `once = true`: the starter rows are inserted only the first time, so later edits and deletions are not overwritten by a restart.

| Table | Columns | Content |
| --- | --- | --- |
| `kora_mining_pickaxe_shop` | `id` varchar(16), `data` longtext | One row with id `main`: ped `model`, `locations`, `prices` per pickaxe item. 1 seed row. |
| `kora_mining_blips` | `id` varchar(32), `data` longtext | One blip per row (see [Map blips](./blips.md)). 2 seed rows. |
| `kora_mining_rockspawns` | `id` varchar(32), `data` longtext, `locations` longtext | Rock type settings and spots (see [Mining](./mining.md)). 20 seed rows. |
| `kora_mining_smelting_recipes` | `id` varchar(32), `data` longtext | One recipe per row (see [Smelting](./smelting.md)). 55 seed rows. |
| `kora_mining_smelting_stations` | `id` varchar(32), `data` longtext, `locations` longtext | Station settings and locations. 2 seed rows. |

Mining and Smelting XP are not stored here; they are handled by `kora_skills`. Cash and items are handled by `kora_core` and `kora_inventory`.

`test/schema.lua` is an offline Lua test of the seed tables (row counts, collation, key, no migrations). Run it from the repository root with `lua test/schema.lua`.
