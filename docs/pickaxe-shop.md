---
title: Pickaxes and shop
sidebar_position: 7
---

# Pickaxes and shop

## Pickaxes

Five tiers are defined in `MiningConfig.pickaxes` (see [Configuration](./api/configuration.md)). A player can use a pickaxe on a rock when all of these hold:

- the player owns the item (`GetItemCount` greater than 0);
- the player's Mining level is at least the pickaxe `level`;
- the rock has that pickaxe `enabled` (default is enabled when no setting exists).

If several tiers qualify, the server uses the highest tier and applies its `speedBonus` for that rock (see [Mining](./mining.md)).

## Vendor

Pickaxe vendors are ped entities (default model `s_m_m_dockwork_01`) with a `kora_target` option "Buy Pickaxes". Vendor model, locations and prices are stored in the `kora_mining_pickaxe_shop` row with id `main` and edited in the [Mining Creator](./creator.md). Up to 100 locations are accepted. The seed places one vendor at the quarry entrance.

Opening the shop shows a `kora_lib` NUI app ("Mining Pickaxes") listing every tier with its price, the required Mining level, and whether the player owns it.

## Purchase flow

The server callback `kora_mining:pickaxeShop:buy` checks, in order:

1. The shop is loaded and the player is within 5.0 of a vendor location.
2. No other purchase from the same player is processing.
3. The item is a pickaxe in the catalogue.
4. The player's Mining level is high enough.
5. The player does not already own that pickaxe.
6. The item exists in the shared items.
7. The player has enough cash (`removeMoney` with account `cash`, reason `mining-pickaxe-purchase`). Only cash is used.

The item is then added with `addItem`. If that fails the cash is refunded (reason `mining-pickaxe-refund`) and the player gets an error message; a failed refund is only printed to the server console.

## Price rules

Prices are whole numbers 0 to 100000000. The stored price overrides `MiningConfig.pickaxes[].price`; invalid stored prices are ignored.
