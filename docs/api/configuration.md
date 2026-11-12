---
title: "Configuration reference"
sidebar_position: 2
---


# Configuration reference

Fixed, shared settings for rock models, UI categories, the map blip and the five pickaxe tiers. Per-rock, shop and smelting data itself is not configured here — it lives in the database and is edited through the in-game creator NUIs.

Namespace: `MiningConfig` · Source: `shared/config.lua`

## Options

`MiningConfig` is a plain table loaded on both client and server; there is no options table or function to call. Edit the values in `shared/config.lua` and restart the resource.

| Option | Type | Description |
| --- | --- | --- |
| `MiningConfig.rockModels` |  | List of 20 rock prop model names offered in the creator's model picker. The creator only accepts a model from this list when saving rock settings (`client/creator.lua:15`); the server only checks the model name format (`server/main.lua:148`). |
| `MiningConfig.rockCategories` |  | UI categories for rocks: `resources`, `gemstones`, `crystals` (`{ value, label }`). Used both client-side for display and server-side (`isRockCategory`) to validate saved rock data. |
| `MiningConfig.smeltingCategories` |  | UI categories for smelting recipes: `bars`, `materials`, `jewellery`, `pickaxes`, `gemstones`. |
| `MiningConfig.blip` |  | Legacy table for a static mine-entrance blip: `enabled`, `name`, `coords` (vec3), `sprite`, `color`, `scale`, `shortRange`, `category`, `description`. It is not read anywhere in the code, so editing it or setting `enabled = false` has no effect; blips come from the `kora_mining_blips` table (see [Map blips](../blips.md)). |
| `MiningConfig.pickaxes` |  | The five fixed pickaxe tiers: `{ id, name, item, level, price }` for `pick1`..`pick5` (Bronze/Iron/Steel/Titanium/Obsidian). `level` is read from this file at runtime (changes need a restart); `price` is the default cash price, overridden by prices stored in the database and changed through the pickaxe-shop creator. |

Category lists: unknown smelting categories on a stored recipe fall back to `materials`, and the server rejects any rock category other than the three above on save.

### Default pickaxes

| Id | Item | Level | Default price |
| --- | --- | --- | --- |
| `pick1` | `bronze_pickaxe` | 1 | 250 |
| `pick2` | `iron_pickaxe` | 20 | 1000 |
| `pick3` | `steel_pickaxe` | 40 | 2500 |
| `pick4` | `titanium_pickaxe` | 60 | 5000 |
| `pick5` | `obsidian_pickaxe` | 80 | 10000 |

Changing the pickaxe `item` or `level` takes effect on restart. Prices stored in the database (set in the creator) override `price`.

## Hard-coded values

| Value | Where | Notes |
| --- | --- | --- |
| Rock interaction distance 3.0, vendor 5.0, smelting station 4.0 | server | Checked with `Kora.distance` |
| Slack 1 second or 10 percent of the duration (whichever is smaller) | server | Allowed early completion for mining and smelting |
| Default vendor ped model `s_m_m_dockwork_01` | `server/pickaxe_shop.lua` | Changeable in the creator |
| Mining animation `amb@world_human_hammering@male@base` / `base`, smelting animation `mp_arresting` / `a_uncuff` | client | Not configurable |

Rocks, the vendor, blips, recipes and stations are database data edited in the [Mining Creator](../creator.md).
