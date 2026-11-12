---
title: "How to use"
sidebar_position: 3
---


# How to use

Rock types, their spawn points, loot items, per-pickaxe speed bonuses, the pickaxe shop and smelting recipes/stations are all configured through in-game admin NUIs and stored in the database — `shared/config.lua` only lists the rock prop models, UI categories, the five pickaxe tiers and a legacy `blip` table that no code reads (map blips are stored in `kora_mining_blips`). The server authorizes every mine/smelt attempt with its own timer so a modified client cannot finish them faster than the configured duration.

## Rockspawns: publishing and mining a rock

On boot the server loads every row from `kora_mining_rockspawns`, publishes each rock type's settings and spawn locations to `GlobalState` (one `GlobalState[id]` for locations, `GlobalState[id .. 'Data']` for settings, plus `GlobalState.koraMiningRockTypes` listing every id), and the client spawns a prop with a `kora_target` "mine" option at each untaken location.

1. **1. Player interacts with a rock** — The `kora_target` option calls `mineRock(name, id)` client-side, which requests a mining profile via `Kora.callback.trigger('kora_mining:mineProfile', name, id)`.

2. **2. Server validates and starts the timer** — The `kora_mining:mineProfile` callback (via the shared `mineProfile` helper) checks the rock/spot exist and are not already taken, the player is within 3 units, the player's `mining` skill level meets the rock's `levelRequired`, and the player holds an enabled pickaxe they qualify for (`findPickaxe` — highest-tier pickaxe the player owns and meets the level for, among those enabled on this rock). On success it records `activeMines[src] = { rockId, spotId, pickaxeId, started = GetGameTimer(), duration = miningDuration(...) }` and returns the profile (rock, spot, mining level, chosen pickaxe and its speed bonus) to the client.

3. **3. Client plays the progress bar** — The client computes the same `duration` locally (mirroring `miningDuration`: base `pickTime` reduced by up to 95% from the rock's `maxLevelSpeedBonus` scaled by mining-level progress plus the pickaxe's own `speedBonus`) and runs `Kora.progressbar.start` for that long. Only on a completed, non-cancelled bar does it fire `kora_mining:server:mine` with the rock id, spot id and pickaxe id.

4. **4. Server re-verifies and enforces the minimum elapsed time** — The `kora_mining:server:mine` handler re-runs `mineProfile` (so the rock/spot/level/pickaxe checks all happen again) and requires the reported pickaxe to match the one the profile just chose. It then requires a previously recorded `activeMines[src]` entry for the same rock/spot/pickaxe, and checks `GetGameTimer() - mine.started >= mine.duration - slack`, where `slack = min(1000, duration * 0.1)`. A client that fires the event early (with a patched or skipped progress bar) is silently ignored — no item or XP is granted and the pending entry is cleared regardless.

5. **5. Reward and respawn** — On success the spot is marked taken, `GlobalState[rockId]` is republished and `kora_mining:client:rockTaken` fires to remove the prop everywhere; after `rock.data.respawnTime` seconds the spot reopens and `kora_mining:client:rockRespawned` fires. The player receives a random amount from 1 to `rock.data.maxGive` of `rock.data.item`, and `rock.data.xpPerMine` XP in the `mining` skill (if greater than 0).

## Mining admin creator (`/miningCreator`)

An admin-only NUI for authoring rock types: create a new rock id, edit its category/model/reward item/limits/level requirement/XP/UI text, place spawn locations, and set per-pickaxe speed-bonus/enabled toggles.

- Every `kora_mining:creator:*` callback (`list`, `item-options`, `create`, `save`, `delete`, `pickaxes:save`) first calls `MiningUtil.isAdmin(src)` (`IsPlayerAceAllowed(source, 'command')`) and fails with "Admin permission required." if the caller lacks the `command` ACE.
- `cleanData` validates every field server-side before a save: category must be one of `Config.rockCategories`-equivalent `MiningConfig.rockCategories` (`resources`/`gemstones`/`crystals`), the model and reward item must exist/validate, `maxGive` 1–100, `respawnTime` 1–3600s, `pickTime` 500–60000ms, `levelRequired` 1–99, `xpPerMine` 0–10000, `maxLevelSpeedBonus` 0–99%, each pickaxe speed bonus 0–99%, and up to 200 spawn locations with finite in-world coordinates (`|x|,|y|,|z| <= 10000`).
- Saving republishes the affected rock type immediately to every client (`reloadRockspawn`) so running games pick up the change without a restart.

## Pickaxe shop

A single shop config (model, vendor locations, per-pickaxe price) is stored in `kora_mining_pickaxe_shop` and published to `GlobalState.koraMiningPickaxeShop`. The default seed is one vendor at the quarry using `s_m_m_dockwork_01` selling the five `MiningConfig.pickaxes` tiers at their configured prices.

- Opening the shop calls `kora_mining:pickaxeShop:get`, which fails unless the shop has finished loading and the player is within 5 units of a vendor location; it returns each pickaxe's label, price, level requirement, whether the player already owns it, and whether their `mining` level unlocks it.
- Buying calls `kora_mining:pickaxeShop:buy`. The server re-checks vendor distance, that the item is for sale, the player meets the level requirement, does not already own it, and that the item exists in the shared registry, then charges cash via `exports.kora_core:removeMoney` and grants the item — refunding the cash if the inventory add fails. A per-source `pendingPurchases` flag rejects a second concurrent purchase call.
- Admin-only callbacks `kora_mining:pickaxeShop:creator:get/save/price` let an admin (again gated by `MiningUtil.isAdmin`) move/add vendor locations, change the vendor ped model, and change per-pickaxe prices (0–100,000,000, whole numbers), persisting to the database and republishing.

## Smelting

Smelting stations (location + attached recipes/categories) and recipes (inputs, output, amount, duration, level, XP, UI category) both live in the database and are fully admin-editable; the default seed includes bars, jewellery, cut gemstones and processed materials for every mined resource.

1. **1. Open the menu** — `kora_mining:smelting:menu(stationId, locationIndex)` requires the player within 4 units of that station location, then returns every recipe attached to the station directly or by matching category, annotated with whether the player currently holds enough of each ingredient and meets the recipe's `smelting` level.

2. **2. Begin** — `kora_mining:smelting:begin(stationId, locationIndex, recipeId)` rejects a second concurrent task (unless the previous one's `expires` deadline — `duration + 15000`ms — has passed, which unblocks a client that never sent cancel/finish), re-validates distance/level/ingredients via `canPlayerUseRecipe`, and records `activeSmeltingTasks[source] = { station, key, recipe, started, expires }`. Returns the recipe's `duration` and a progress-bar label for the client to display.

3. **3. Finish** — `kora_mining:smelting:finish()` requires an active task that has not expired and whose elapsed time is at least `recipe.duration - slack` (same up-to-1s/10% slack formula as mining), re-checks the player can still use the recipe, then removes the input items (refunding any already-removed ones if a later removal fails) and adds the output — refunding all inputs if the output cannot be added. XP is granted in the `smelting` skill if the recipe's `xp` is greater than 0.

4. **Cancel** — `kora_mining:smelting:cancel` (client-triggered net event) and a player disconnect both clear `activeSmeltingTasks[source]` with no reward.

## Smelting admin creator

Reached through the same NUI family as the mining creator (admin-gated `kora_mining:smelting:creator:*` callbacks: recipe create/details/delete, station create/details/locations/delete). Recipe ids are auto-generated from the label (lowercased, non-alphanumeric runs collapsed to `_`, truncated to 24 chars, de-duplicated with a numeric suffix). Station and recipe ids must match `^[a-z][%w_]*$` and be at most 32 characters.

## Map blips

`client/blip.lua` draws the map blips stored in the `kora_mining_blips` table (published by the server in `GlobalState.koraMiningBlips`, pushed on change with `kora_mining:blips:reload`; edited in the Mining Creator, see [Map blips](./blips.md)). Blips are created through `kora_lib`'s blip export, which fails silently if `kora_lib`'s client side is not yet ready, so creation is retried up to 10 times (2s apart); it also re-creates missing blips whenever `kora_lib` itself (re)starts, since a `kora_lib` restart destroys blips it owns.
