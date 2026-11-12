---
title: Troubleshooting
sidebar_position: 14
---

# Troubleshooting

## Nothing spawns or the creator reports "still loading"

The server waits for `kora_sql` (up to 60 seconds) and then creates the tables. If you see `database not ready, mining is disabled` or `schema setup failed` in the console, fix the database connection and restart the resource.

## Rocks do not appear

- Check that the `props` resource is started and streams the rock model.
- A rock type with no spots (the seeded `tin` rock) spawns nothing.
- The client waits up to 30 seconds for global state and prints `timed out waiting for GlobalState` if it does not arrive.

## "You need an enabled pickaxe..."

The player needs an owned pickaxe whose level they meet and which is enabled for that rock in the creator. Per-rock flags are edited under the rock's pickaxe list.

## Mining or smelting level is always 0 or 1

The levels come from `kora_skills` (`mining` and `smelting`). If that resource is not running or does not define those skills, level checks fail.

## Items missing or "does not exist"

Every reward, input and output item must exist in the shared items. See [Items](./items.md).

## Known caveats

- The reward from mining is given with `addItem` without checking the result. If the inventory has no room, the rock is still consumed and XP is still awarded.
- Creator edits reset all spots to available.
- `MiningConfig.blip` is unused (see [Configuration](./api/configuration.md)).
- The default seed includes a station labelled `test`.
- Existing rows are never changed by a restart, so changing seed data in `server/schema.lua` does not affect an already initialised database.
