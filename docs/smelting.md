---
title: Smelting
sidebar_position: 8
---

# Smelting

## Stations

A station (`kora_mining_smelting_stations`) has a label, target label and icon, a list of locations, a list of categories and a list of individually assigned recipe ids. Each location is either a `kora_target` box zone (2 by 2 by 2) at the coordinates, or, when `object` is set, a spawned frozen prop model with a target option.

A recipe is available at a station when its id is in the station's recipe list, or when its category is in the station's categories. Categories come from `MiningConfig.smeltingCategories`.

## Recipes

A recipe (`kora_mining_smelting_recipes`) has:

| Field | Rule |
| --- | --- |
| `label` | Up to 48 chars |
| `category` | One of the smelting categories |
| `level` | Smelting level 1 to 99 |
| `xp` | Whole number 0 to 10000 |
| `duration` | 500 to 300000 ms |
| `inputs` | Up to 20 distinct items, amount 1 to 1000 each; every item must exist |
| `output`, `amount` | Existing item, amount 1 to 1000 |

A recipe without an output or without inputs is never shown and cannot be assigned to a station.

## Flow

1. Selecting the station target calls `kora_mining:smelting:menu`. The server requires the player to be within 4.0 of that location and returns the recipes the player's Smelting level allows, marking which ones the player has all ingredients for.
2. Choosing Smelt calls `kora_mining:smelting:begin`. The server checks station, recipe, level and ingredients again, rejects the request if the player is already smelting, and starts a timer (valid for the duration plus 15 seconds).
3. The client runs a progress bar with the recipe duration. Cancelling it triggers `kora_mining:smelting:cancel` and no materials are used.
4. On completion the client calls `kora_mining:smelting:finish`. The server verifies the timer (minus slack), re-checks level and ingredients, removes the inputs, adds the output and awards `xp` to the `smelting` skill. If an input cannot be removed or the output does not fit, removed inputs are returned.
5. The menu refreshes so the player can smelt again.

Ingredients are only consumed at the end, so a cancelled smelt costs nothing.

## Seeded content

- 55 recipes: bars (copper, bronze, iron, steel, silver, gold, zinc, obsidian), materials (copper, iron, metal scrap, steel, plastic, glass, rubber, carbon), cut gems (emerald, ruby, sapphire, diamond) and jewellery (rings and necklaces in gold and silver). Ids use the prefixes `j_` for jewellery and `material_` for materials.
- 2 stations: `cutter` (category `gemstones`, location near 1072.7, -1987.54) and `test` (categories `bars`, `materials`, `jewellery`, location near 1110.65, -2008.68).

Seed rows are inserted only once (see [Database](./database.md)).
