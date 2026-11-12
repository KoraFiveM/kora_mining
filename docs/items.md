---
title: Items
sidebar_position: 12
---

# Items

The resource defines no items itself. It reads the shared item registry (see [Installation](./installation.md)) and every item used by the seed data, the pickaxe catalogue and recipes must exist there. The repository root contains two reference files:

- `MINING_ITEMS.md` - copy-ready item definitions for the starter content, kept for review; its own text says the source of truth is the `kora_core` shared items.
- `images/` - item icons. Inventory images are served by `kora_inventory`, so these files must be available there.

## Items referenced

- **Pickaxes**: `bronze_pickaxe`, `iron_pickaxe`, `steel_pickaxe`, `titanium_pickaxe`, `obsidian_pickaxe`.
- **Mined**: `copper_ore`, `tin_ore`, `iron_ore`, `silver_ore`, `gold_ore`, `zinc_ore`, `basalt`, `bauxite`, `carbon`, `carbonatite`, `sandstone`, `obsidian`, `amethyst_shard`, `opal_shard`, `quartz_shard`, `topaz_shard`, `uncut_sapphire`, `uncut_emerald`, `uncut_ruby`, `uncut_diamond`.
- **Smelted**: `copper_ignot`, `bronze_ignot`, `iron_ingot`, `steel_ingot`, `silver_ingot`, `gold_ingot`, `zinc_ingot`, `obsidian_ignot`, `carbon_ignot`, `copper`, `iron`, `metalscrap`, `steel`, `plastic`, `glass`, `rubber`, cut `sapphire`, `emerald`, `ruby`, `diamond`, plus rings and necklaces (for example `ring_gold`, `ring_silver`, `ruby_ring_gold`, `emerald_necklace_silver`).

The spellings `copper_ignot`, `bronze_ignot`, `obsidian_ignot` and `carbon_ignot` come from the seed recipes, while gold, silver, iron, steel and zinc use `_ingot`. Item names must match the shared items exactly.

## Images

`images/` contains 72 PNG files. `MINING_ITEMS.md` lists 80 expected images; files such as `tin_ore.png`, `copper.png`, `copper_ignot.png`, `carbon_ignot.png`, `iron.png`, `steel.png`, `glass.png`, `plastic.png`, `rubber.png`, `metalscrap.png` and `emerald_necklace.png` are not in the folder.
