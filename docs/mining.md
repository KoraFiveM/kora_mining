---
title: Mining
sidebar_position: 6
---

# Mining

## Rock types

Each row in `kora_mining_rockspawns` is a rock type with settings (`data`) and a list of spots (`locations`). The server publishes them through global state (see [Events and callbacks](./events.md)) and each client spawns a frozen, invincible prop with a `kora_target` option at every spot that is not currently taken.

Settings fields (validated by the server on save):

| Field | Range or rule |
| --- | --- |
| `category` | `resources`, `gemstones` or `crystals` |
| `model` | Prop model, letters, digits, `_`, `-`, `.`, up to 64 chars |
| `item` | Must exist in the shared items |
| `maxGive` | Whole number 1 to 100; the player gets a random amount from 1 to `maxGive` |
| `respawnTime` | 1 to 3600 seconds |
| `pickTime` | Whole number 500 to 60000 ms (base mining time) |
| `levelRequired` | Whole number 1 to 99 (Mining level) |
| `xpPerMine` | Whole number 0 to 10000, awarded once per completed mine |
| `maxLevelSpeedBonus` | Whole number 0 to 99 (percent speed bonus at Mining level 99) |
| `pickaxes` | Per pickaxe id: `enabled` and `speedBonus` (0 to 99) |
| `icon`, `targetLabel`, `progressLabel` | Target icon and labels, up to 64 chars |
| `locations` | Up to 200 spots with `coords` `x`, `y`, `z` |

## Mining flow

1. The player selects the target option. The client calls the callback `kora_mining:mineProfile`.
2. The server checks that the spot exists and is not taken, that the player is within 3.0 of it, that the player's Mining level (`kora_skills:getRep(src, 'mining').level`) meets `levelRequired`, and that the player owns an enabled pickaxe they are high enough level to use. The server picks the highest tier pickaxe that qualifies. It returns the profile and starts a server timer for that spot.
3. The client runs a progress bar for the computed duration. It can be cancelled and cannot be used while moving, fighting or in a vehicle.
4. On completion the client triggers `kora_mining:server:mine`. The server repeats the checks, requires that the timer started in step 2 has run for the full duration (minus slack), marks the spot taken, tells all clients to remove the prop, gives the item and awards XP.
5. After `respawnTime` seconds the spot is released and clients respawn the prop.

## Mining time

```text
levelProgress = clamp((miningLevel - 1) / 98, 0, 1)
totalBonus    = clamp(maxLevelSpeedBonus * levelProgress + pickaxeSpeedBonus, 0, 95)
duration      = max(500, floor(pickTime * (1 - totalBonus / 100)))
```

The client and the server use the same formula; the server enforces it as a minimum.

## Seeded rocks

These are the defaults inserted on first start. Mining time is the seeded `pickTime` in ms; spots is the number of seeded locations.

| Id | Model | Item | Category | Level | XP | Time | Spots |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `amethyst` | `amethyst_rock` | `amethyst_shard` | crystals | 92 | 350 | 17000 | 12 |
| `basalt` | `basalt_rock` | `basalt` | resources | 5 | 15 | 12000 | 12 |
| `bauxite` | `bauxite_rock` | `bauxite` | resources | 10 | 40 | 12000 | 11 |
| `carbon` | `carbon_rock` | `carbon` | resources | 30 | 85 | 12000 | 10 |
| `carbonatite` | `carbonatite_rock` | `carbonatite` | resources | 70 | 275 | 12000 | 11 |
| `copper` | `copper_rock` | `copper_ore` | resources | 1 | 18 | 12000 | 11 |
| `diamond` | `diamond_rock` | `uncut_diamond` | gemstones | 75 | 300 | 20000 | 9 |
| `emerald` | `emerald_rock` | `uncut_emerald` | gemstones | 65 | 250 | 20000 | 8 |
| `gold` | `gold_rock` | `gold_ore` | resources | 40 | 120 | 12000 | 13 |
| `iron` | `iron_rock` | `iron_ore` | resources | 15 | 60 | 12000 | 11 |
| `obsidian` | `obsidian_rock` | `obsidian` | resources | 80 | 315 | 12000 | 15 |
| `opal` | `opal_rock` | `opal_shard` | crystals | 40 | 120 | 17000 | 12 |
| `quartz` | `quartz_rock` | `quartz_shard` | crystals | 50 | 210 | 17000 | 10 |
| `ruby` | `ruby_rock` | `uncut_ruby` | gemstones | 70 | 275 | 20000 | 11 |
| `sandstone` | `sandstone_rock` | `sandstone` | resources | 35 | 95 | 12000 | 15 |
| `sapphire` | `sapphire_rock` | `uncut_sapphire` | gemstones | 60 | 230 | 20000 | 12 |
| `silver` | `silver_rock` | `silver_ore` | resources | 20 | 70 | 12000 | 15 |
| `tin` | `tin_rock` | `tin_ore` | resources | 1 | 30 | 12000 | 0 |
| `topaz` | `topaz_rock` | `topaz_shard` | crystals | 50 | 180 | 17000 | 12 |
| `zinc` | `zinc_rock` | `zinc_ore` | resources | 50 | 180 | 12000 | 11 |

The seeded `tin` rock has no spots, so it spawns nothing until spots are placed in the creator.

## Behaviour notes

- Saving, creating or deleting any rock in the creator reloads the rock types and resets the taken state: every spot becomes available again.
- Rock state is kept in server memory and global state only; a resource restart makes all spots available again.
- Only one mining action at a time per player. Disconnecting discards a pending mine.
