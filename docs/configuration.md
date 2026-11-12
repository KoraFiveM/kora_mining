---
title: Configuration
sidebar_position: 3
---

# Configuration

There is no config file for gameplay data. Rocks, the vendor, blips, recipes and stations live in the database and are edited in the [Mining Creator](./creator.md). The only static config is `MiningConfig` in `shared/config.lua`, loaded on both client and server.

## `MiningConfig`

| Key | Meaning |
| --- | --- |
| `rockModels` | List of 20 allowed rock prop model names (for example `copper_rock`). The creator only accepts a model from this list when saving rock settings; the server only checks the model name format. |
| `rockCategories` | Categories a rock can belong to: `resources`, `gemstones`, `crystals`. The server rejects any other category on save. |
| `smeltingCategories` | Recipe and station categories: `bars`, `materials`, `jewellery`, `pickaxes`, `gemstones`. Unknown categories on a stored recipe fall back to `materials`. |
| `pickaxes` | Pickaxe tiers: `id` (`pick1` to `pick5`), `name`, `item`, `level` (Mining level to use and buy), `price` (default cash price). |
| `blip` | A blip table with the same fields as a stored blip. See the note below. |

### Default pickaxes

| Id | Item | Level | Default price |
| --- | --- | --- | --- |
| `pick1` | `bronze_pickaxe` | 1 | 250 |
| `pick2` | `iron_pickaxe` | 20 | 1000 |
| `pick3` | `steel_pickaxe` | 40 | 2500 |
| `pick4` | `titanium_pickaxe` | 60 | 5000 |
| `pick5` | `obsidian_pickaxe` | 80 | 10000 |

Changing the pickaxe `item` or `level` takes effect on restart. Prices stored in the database (set in the creator) override `price`.

### `MiningConfig.blip`

`MiningConfig.blip` is not read anywhere in the code; blips come from the `kora_mining_blips` table (see [Map blips](./blips.md)). Editing it has no effect.

## Hard-coded values

| Value | Where | Notes |
| --- | --- | --- |
| Rock interaction distance 3.0, vendor 5.0, smelting station 4.0 | server | Checked with `Kora.distance` |
| Slack 1 second or 10 percent of the duration (whichever is smaller) | server | Allowed early completion for mining and smelting |
| Default vendor ped model `s_m_m_dockwork_01` | `server/pickaxe_shop.lua` | Changeable in the creator |
| Mining animation `amb@world_human_hammering@male@base` / `base`, smelting animation `mp_arresting` / `a_uncuff` | client | Not configurable |
