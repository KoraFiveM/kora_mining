---
title: Events and callbacks
sidebar_position: 11
---

# Events and callbacks

All of these are internal to the resource. There are no exports. Callbacks use `Kora.callback` from `kora_lib`.

## Server net events

| Event | Payload | Behaviour |
| --- | --- | --- |
| `kora_mining:server:mine` | `rockId`, `spotId`, `pickaxeId` | Completes a mine started with `kora_mining:mineProfile`. Silently ignored unless the server timer started by the profile callback has elapsed. |
| `kora_mining:smelting:cancel` | none | Clears the player's active smelting task. |

## Client events (sent by the server)

| Event | Payload | Behaviour |
| --- | --- | --- |
| `kora_mining:client:rockTaken` | `rockId`, `spotId` | Marks the spot taken and deletes the prop. |
| `kora_mining:client:rockRespawned` | `rockId`, `spotId` | Respawns the prop. |
| `kora_mining:client:rockspawnsReload` | `rockId`, `data`, `locations` | Replaces a rock type's settings and rebuilds its props. |
| `kora_mining:client:rockspawnsRemove` | `rockId` | Removes a rock type and its props. |
| `kora_mining:pickaxeShop:reload` | shop table | Rebuilds the vendor peds. |
| `kora_mining:smelting:stationReload` | `stationId`, station | Rebuilds one station's targets. |
| `kora_mining:blips:reload` | blip list | Replaces all map blips. |
| `kora_mining:creator:open` | none | Opens the creator. Ignored unless it comes from the server. |

## Callbacks (player facing)

| Callback | Purpose |
| --- | --- |
| `kora_mining:mineProfile` | Validates a mine request and starts the server timer; returns the mining profile. |
| `kora_mining:pickaxeShop:get` | Returns the catalogue (needs to be near a vendor). |
| `kora_mining:pickaxeShop:buy` | Buys a pickaxe. |
| `kora_mining:smelting:menu` | Lists the recipes available at a station location. |
| `kora_mining:smelting:begin` | Starts a smelting task. |
| `kora_mining:smelting:finish` | Completes the task and swaps inputs for output. |

## Callbacks (admin only)

| Callback | Purpose |
| --- | --- |
| `kora_mining:creator:list`, `:item-options`, `:create`, `:save`, `:delete`, `:pickaxes:save` | Rock types |
| `kora_mining:pickaxeShop:creator:get`, `:save`, `:price` | Vendor |
| `kora_mining:blips:creator:get`, `:save`, `:delete` | Blips |
| `kora_mining:smelting:creator:get`, `:recipeCreate`, `:recipeDetails`, `:recipeOutput`, `:recipeInputs`, `:recipeDelete`, `:stationCreate`, `:stationDetails`, `:stationRecipes`, `:stationCategories`, `:stationLocations`, `:stationDelete` | Recipes and stations |

## State bags

| Key | Content |
| --- | --- |
| `GlobalState.koraMiningRockTypes` | Sorted list of rock type ids |
| `GlobalState.<rockId>` | Spots of a rock type with `coords` and `taken` |
| `GlobalState.<rockId>Data` | Settings of a rock type |
| `GlobalState.koraMiningPickaxeShop` | Vendor model, locations and prices |
| `GlobalState.koraMiningSmelting` | Public station data |
| `GlobalState.koraMiningBlips` | Blip list |

Because rock ids are used directly as global state keys, a rock id equal to one of the other keys above would collide with it.
