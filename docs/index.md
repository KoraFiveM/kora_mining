---
title: kora_mining
sidebar_position: 1
---

# kora_mining

`kora_mining` is a mining and smelting job for Kora servers. Players buy a pickaxe from a vendor, mine rock props placed around the map (props are removed for a respawn time after being mined), earn Mining XP and items, then smelt ore into bars, materials, jewellery and cut gems at smelting stations, earning Smelting XP. Everything (rocks, pickaxe vendor, map blips, smelting recipes and stations) is stored in the database and edited in game with the admin-only Mining Creator (`/miningCreator`). All gameplay checks (level, pickaxe, distance, timing, inventory) are decided on the server.

Current version: see `version` in `fxmanifest.lua`.

## Features

- **Rock mining** - rock props spawn at configured spots; a player with `kora_target` selects the rock, runs a progress bar with a hammering animation and receives a random 1 to `maxGive` of the rock's item plus XP. See [Mining](./mining.md).
- **Mining level and pickaxes** - each rock has a required Mining level and per-pickaxe enable flags and speed bonuses; five pickaxe tiers are defined in `shared/config.lua`. See [Pickaxes and shop](./pickaxe-shop.md).
- **Smelting** - stations offer recipes (inputs, output, level, XP, duration) filtered by category or assigned individually. See [Smelting](./smelting.md).
- **Map blips** - database-driven blips drawn for every player. See [Map blips](./blips.md).
- **Mining Creator** - an admin NUI app for rocks, spots, vendor, blips, recipes and stations. See [Mining Creator](./creator.md).
- **Seed data** - on first start the resource creates its tables and seeds 20 rock types, 55 recipes, 2 stations, a pickaxe vendor and 2 blips. See [Database](./database.md).

## Documentation map

- [Installation](./installation.md) - dependencies, manifest, tables, items, ensure order, first start
- [How to use](./how-to-use.md) - mining, creator, pickaxe shop, smelting and blip flows step by step
- [Commands and permissions](./commands.md) - `/miningCreator` and the `command` ACE requirement
- [API reference](./api/index.md) - module index for the shared configuration
- [Configuration reference](./api/configuration.md) - `MiningConfig` options, default pickaxes and hard-coded values
- [Mining](./mining.md) - rock data, mining flow, speed formula, seeded rocks
- [Pickaxes and shop](./pickaxe-shop.md) - pickaxe tiers, vendor, purchase flow
- [Smelting](./smelting.md) - recipes, stations, smelting flow
- [Map blips](./blips.md) - blip data and behaviour
- [Mining Creator](./creator.md) - the admin tool and `/miningCreator`
- [Events and callbacks](./events.md) - net events, callbacks, state bags
- [Items](./items.md) - items the resource references and bundled images
- [Database](./database.md) - tables, columns and seed data
- [Troubleshooting](./troubleshooting.md) - common problems and known caveats

This resource defines no exports.
