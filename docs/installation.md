---
title: Installation
sidebar_position: 2
---

# Installation

## Dependencies

Declared with `dependency` in `fxmanifest.lua`:

| Resource | Used for |
| --- | --- |
| `kora_lib` | `Kora.nui` apps, callbacks, notifications, progress bar, blips, entities, distance checks, global state waiting, raycast |
| `kora_core` | Shared items registry (`getShared`), cash removal and refund (`removeMoney`, `addMoney`) |
| `kora_sql` | Schema creation and all queries (`Kora.sql`) |
| `kora_skills` | `getRep` and `addRep` for the `mining` and `smelting` skills |
| `kora_inventory` | `GetItemCount`, `addItem`, `removeItem`, and item images served over `nui://kora_inventory/images/` |
| `kora_target` | Target options on rock props, the pickaxe vendor and smelting stations |
| `props` | Streams the rock prop models listed in `MiningConfig.rockModels` (see the creator text "Models streamed by the props resource") |

The `kora_skills` skills named `mining` and `smelting` must exist in that resource; this was not verified from this repository.

## Steps

1. Place the resource in your resources folder and ensure it after its dependencies:

   ```cfg
   ensure kora_lib
   ensure kora_sql
   ensure kora_core
   ensure kora_skills
   ensure kora_inventory
   ensure kora_target
   ensure props
   ensure kora_mining
   ```

2. No SQL import is needed. On start the resource waits up to 60 seconds for `kora_sql` and creates its five tables and seed rows (see [Database](./database.md)). If the database is not ready or table creation fails, mining is disabled and an error is printed to the server console.
3. Make sure the items used by the seed data exist in the `kora_core` shared items (see [Items](./items.md)).
4. Give admins the `command` ACE so they can use [/miningCreator](./commands.md).

## Compatibility

`MiningUtil.getSharedItems` reads the item registry from `exports['qb-core']:GetShared('Items')` first and falls back to `exports.kora_core:getShared('items')`.
