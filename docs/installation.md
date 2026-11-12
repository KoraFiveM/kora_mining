---
title: "Installation"
sidebar_position: 2
---


# Installation

Kora Mining spawns minable rock entities whose type, location, loot and pickaxe speed bonuses are stored in the database and editable in-game through an admin creator NUI. Players mine rocks for raw materials, buy pickaxes from a vendor, and smelt/process raw materials into bars, jewellery and cut gemstones at smelting stations (also DB-backed and admin-editable). It depends on `kora_sql`, `kora_skills` (for the `mining` and `smelting` skills), `kora_inventory`, `kora_core`, `kora_target` and the `props` resource (for rock/vendor prop models).

## Install Kora Mining

1. **Add the folder** — Place `kora_mining` in your resources directory.

2. **Dependencies** — Declares `dependency` on `kora_lib`, `kora_core`, `kora_sql`, `kora_skills`, `kora_inventory`, `kora_target` and `props`. Start all of them first.

   ```lua title="fxmanifest.lua"
   dependency 'kora_lib'
   dependency 'kora_core'
   dependency 'kora_sql'
   dependency 'kora_skills'
   dependency 'kora_inventory'
   dependency 'kora_target'
   dependency 'props'

   shared_scripts {
       '@kora_lib/init.lua',
       '@kora_core/init.lua',
       'shared/config.lua',
   }

   server_scripts {
       '@kora_sql/init.lua',
       'server/schema.lua',
       'server/util.lua',
       'server/main.lua',
       'server/pickaxe_shop.lua',
       'server/blips.lua',
       'server/smelting.lua',
   }
   client_scripts {
       'client/**.lua',
   }
   ```

3. **Skills** — Two `kora_skills` skill names are used: `mining` (rock mining XP and level gates) and `smelting` (processing XP and level gates). Both must be registered in your `kora_skills` setup.

4. **Database tables** — `server/schema.lua` defines five tables applied through the Kora SQL schema helper: `kora_mining_pickaxe_shop` (one row, `id = 'main'`, holds the shop model/locations/prices), `kora_mining_blips` (one blip per row), `kora_mining_rockspawns` (one row per rock type: `data` and `locations` JSON columns), `kora_mining_smelting_recipes` (one recipe per row) and `kora_mining_smelting_stations` (station data and locations). All five are seeded once with the default rock types, pickaxe prices, blips, smelting recipes and stations shown in `server/schema.lua` — editing them afterwards is done in-game via the creator NUIs, not by re-editing the seed. See [Database](./database.md).

5. **Items** — Every item referenced by the seeded rock loot, pickaxes (`bronze_pickaxe`, `iron_pickaxe`, `steel_pickaxe`, `titanium_pickaxe`, `obsidian_pickaxe`) and smelting recipe outputs/inputs must exist in your `kora_core` shared item registry, or the reward/smelt-ingredient checks silently fail.

6. **Start it** — Add to `server.cfg` after its dependencies.

   ```bash title="server.cfg"
   ensure kora_skills
   ensure kora_inventory
   ensure kora_target
   ensure kora_mining
   ```

## Dependency details

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

## Full ensure order

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

## First start

No SQL import is needed. On start the resource waits up to 60 seconds for `kora_sql` and creates its five tables and seed rows (see [Database](./database.md)). If the database is not ready or table creation fails, mining is disabled and an error is printed to the server console. Make sure the items used by the seed data exist in the `kora_core` shared items (see [Items](./items.md)). Give admins the `command` ACE so they can use [/miningCreator](./commands.md).

## Compatibility

`MiningUtil.getSharedItems` reads the item registry from `exports['qb-core']:GetShared('Items')` first and falls back to `exports.kora_core:getShared('items')` (`server/util.lua:21`).
