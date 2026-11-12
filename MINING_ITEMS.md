# Mining item definitions and images

This list covers every item referenced by the starter content in `kora_mining/server/schema.lua` and the pickaxe catalog in `kora_mining/shared/config.lua`.

The mining tables and starter content are created automatically on first start; no SQL import is needed.

- Item definitions included: **80**
- Required item images included in `kora_mining/images`: **80**
- `emerald_necklace.png` uses the existing `emerald_necklace_gold.png` icon because the generic emerald necklace has the same item appearance.

## Item code

These are the existing Kora shared item definitions. They are collected here for review and transfer; the source of truth remains `[pre]/kora_core/shared/items.lua`.

```lua
{ name = 'amethyst_necklace_gold', label = 'Amethyst necklace gold', weight = 1000, type = 'item', image = 'amethyst_necklace_gold.png', unique = false, useable = false, shouldClose = true },
{ name = 'amethyst_necklace_silver', label = 'Amethyst necklace silver', weight = 1000, type = 'item', image = 'amethyst_necklace_silver.png', unique = false, useable = false, shouldClose = true },
{ name = 'amethyst_ring_gold', label = 'Amethyst ring gold', weight = 1000, type = 'item', image = 'amethyst_ring_gold.png', unique = false, useable = false, shouldClose = true },
{ name = 'amethyst_ring_silver', label = 'Amethyst ring silver', weight = 1000, type = 'item', image = 'amethyst_ring_silver.png', unique = false, useable = false, shouldClose = true },
{ name = 'amethyst_shard', label = 'Amethyst shard', weight = 100, type = 'item', image = 'amethyst_shard.png', unique = false, useable = false, shouldClose = true },
{ name = 'basalt', label = 'Basalt', weight = 100, type = 'item', image = 'basalt.png', unique = false, useable = false, shouldClose = true },
{ name = 'bauxite', label = 'Bauxite', weight = 100, type = 'item', image = 'bauxite.png', unique = false, useable = false, shouldClose = true },
{ name = 'bronze_ignot', label = 'Bronze ignot', weight = 200, type = 'item', image = 'bronze_ignot.png', unique = false, useable = false, shouldClose = true },
{ name = 'bronze_pickaxe', label = 'Bronze pickaxe', weight = 1000, type = 'item', image = 'bronze_pickaxe.png', unique = true, useable = false, shouldClose = true },
{ name = 'carbon', label = 'Carbon', weight = 100, type = 'item', image = 'carbon.png', unique = false, useable = false, shouldClose = true },
{ name = 'carbon_ignot', label = 'Carbon ignot', weight = 100, type = 'item', image = 'carbon_ignot.png', unique = false, useable = false, shouldClose = true },
{ name = 'carbonatite', label = 'Carbonatite', weight = 100, type = 'item', image = 'carbonatite.png', unique = false, useable = false, shouldClose = true },
{ name = 'copper',     label = 'Copper',      weight = 100, type = 'item', image = 'copper.png',     imageUrl = KoraCoreSeed.imageUrl('copper'),     unique = false, useable = false, shouldClose = true, description = 'Recovered copper.' },
{ name = 'copper_ignot', label = 'Copper ignot', weight = 100, type = 'item', image = 'copper_ignot.png', unique = false, useable = false, shouldClose = true },
{ name = 'copper_ore', label = 'Copper ore', weight = 100, type = 'item', image = 'copper_ore.png', unique = false, useable = false, shouldClose = true },
{ name = 'diamond', label = 'Diamond', weight = 100, type = 'item', image = 'diamond.png', unique = false, useable = false, shouldClose = true, description = 'A diamond seems like the jackpot to me!' },
{ name = 'diamond_necklace_gold', label = 'Diamond necklace gold', weight = 200, type = 'item', image = 'diamond_necklace_gold.png', unique = false, useable = false, shouldClose = true },
{ name = 'diamond_necklace_silver', label = 'Diamond necklace silver', weight = 200, type = 'item', image = 'diamond_necklace_silver.png', unique = false, useable = false, shouldClose = true },
{ name = 'diamond_ring_gold', label = 'Diamond ring gold', weight = 200, type = 'item', image = 'diamond_ring_gold.png', unique = false, useable = false, shouldClose = true },
{ name = 'diamond_ring_silver', label = 'Diamond ring silver', weight = 200, type = 'item', image = 'diamond_ring_silver.png', unique = false, useable = false, shouldClose = true },
{ name = 'emerald', label = 'Emerald', weight = 100, type = 'item', image = 'emerald.png', unique = false, useable = false, shouldClose = true },
{ name = 'emerald_necklace', label = 'Emerald necklace', weight = 200, type = 'item', image = 'emerald_necklace.png', unique = false, useable = false, shouldClose = true },
{ name = 'emerald_necklace_gold', label = 'Emerald necklace gold', weight = 200, type = 'item', image = 'emerald_necklace_gold.png', unique = false, useable = false, shouldClose = true },
{ name = 'emerald_necklace_silver', label = 'Emerald necklace silver', weight = 200, type = 'item', image = 'emerald_necklace_silver.png', unique = false, useable = false, shouldClose = true },
{ name = 'emerald_ring_gold', label = 'Emerald ring gold', weight = 200, type = 'item', image = 'emerald_ring_gold.png', unique = false, useable = false, shouldClose = true },
{ name = 'emerald_ring_silver', label = 'Emerald ring silver', weight = 200, type = 'item', image = 'emerald_ring_silver.png', unique = false, useable = false, shouldClose = true },
{ name = 'glass',      label = 'Glass',       weight = 100, type = 'item', image = 'glass.png',      imageUrl = KoraCoreSeed.imageUrl('glass'),      unique = false, useable = false, shouldClose = true, description = 'Sorted glass.' },
{ name = 'gold_ingot', label = 'Gold ingot', weight = 100, type = 'item', image = 'gold_ingot.png', unique = false, useable = false, shouldClose = true },
{ name = 'gold_ore', label = 'Gold ore', weight = 100, type = 'item', image = 'gold_ore.png', unique = false, useable = false, shouldClose = true },
{ name = 'iron',       label = 'Iron',        weight = 100, type = 'item', image = 'iron.png',       imageUrl = KoraCoreSeed.imageUrl('iron'),       unique = false, useable = false, shouldClose = true, description = 'Recovered iron.' },
{ name = 'iron_ingot', label = 'Iron ingot', weight = 100, type = 'item', image = 'iron_ingot.png', unique = false, useable = false, shouldClose = true },
{ name = 'iron_ore', label = 'Iron ore', weight = 100, type = 'item', image = 'iron_ore.png', unique = false, useable = false, shouldClose = true },
{ name = 'iron_pickaxe', label = 'Iron pickaxe', weight = 1000, type = 'item', image = 'iron_pickaxe.png', unique = true, useable = false, shouldClose = true },
{ name = 'metalscrap', label = 'Metal Scrap', weight = 100, type = 'item', image = 'metalscrap.png', imageUrl = KoraCoreSeed.imageUrl('metalscrap'), unique = false, useable = false, shouldClose = true, description = 'Salvaged mixed metal.' },
{ name = 'obsidian', label = 'Obsidian', weight = 100, type = 'item', image = 'obsidian.png', unique = false, useable = false, shouldClose = true },
{ name = 'obsidian_ignot', label = 'Obsidian ignot', weight = 100, type = 'item', image = 'obsidian_ignot.png', unique = false, useable = false, shouldClose = true },
{ name = 'obsidian_pickaxe', label = 'Obsidian pickaxe', weight = 1000, type = 'item', image = 'obsidian_pickaxe.png', unique = true, useable = false, shouldClose = true },
{ name = 'opal_necklace_gold', label = 'Opal necklace gold', weight = 200, type = 'item', image = 'opal_necklace_gold.png', unique = false, useable = false, shouldClose = true },
{ name = 'opal_necklace_silver', label = 'Opal necklace silver', weight = 200, type = 'item', image = 'opal_necklace_silver.png', unique = false, useable = false, shouldClose = true },
{ name = 'opal_ring_gold', label = 'Opal ring gold', weight = 200, type = 'item', image = 'opal_ring_gold.png', unique = false, useable = false, shouldClose = true },
{ name = 'opal_ring_silver', label = 'Opal ring silver', weight = 200, type = 'item', image = 'opal_ring_silver.png', unique = false, useable = false, shouldClose = true },
{ name = 'opal_shard', label = 'Opal shard', weight = 100, type = 'item', image = 'opal_shard.png', unique = false, useable = false, shouldClose = true },
{ name = 'plastic',    label = 'Plastic',     weight = 100, type = 'item', image = 'plastic.png',    imageUrl = KoraCoreSeed.imageUrl('plastic'),    unique = false, useable = false, shouldClose = true, description = 'Sorted recyclable plastic.' },
{ name = 'quartz_necklace_gold', label = 'Quartz necklace gold', weight = 200, type = 'item', image = 'quartz_necklace_gold.png', unique = false, useable = false, shouldClose = true },
{ name = 'quartz_necklace_silver', label = 'Quartz necklace silver', weight = 200, type = 'item', image = 'quartz_necklace_silver.png', unique = false, useable = false, shouldClose = true },
{ name = 'quartz_ring_gold', label = 'Quartz ring gold', weight = 200, type = 'item', image = 'quartz_ring_gold.png', unique = false, useable = false, shouldClose = true },
{ name = 'quartz_ring_silver', label = 'Quartz ring silver', weight = 200, type = 'item', image = 'quartz_ring_silver.png', unique = false, useable = false, shouldClose = true },
{ name = 'quartz_shard', label = 'Quartz shard', weight = 100, type = 'item', image = 'quartz_shard.png', unique = false, useable = false, shouldClose = true },
{ name = 'ring_gold', label = 'Ring gold', weight = 100, type = 'item', image = 'ring_gold.png', unique = false, useable = false, shouldClose = true },
{ name = 'ring_silver', label = 'Ring silver', weight = 100, type = 'item', image = 'ring_silver.png', unique = false, useable = false, shouldClose = true },
{ name = 'rubber',     label = 'Rubber',      weight = 100, type = 'item', image = 'rubber.png',     imageUrl = KoraCoreSeed.imageUrl('rubber'),     unique = false, useable = false, shouldClose = true, description = 'Reclaimed rubber.' },
{ name = 'ruby', label = 'Ruby', weight = 100, type = 'item', image = 'ruby.png', unique = false, useable = false, shouldClose = true },
{ name = 'ruby_necklace_gold', label = 'Ruby necklace gold', weight = 200, type = 'item', image = 'ruby_necklace_gold.png', unique = false, useable = false, shouldClose = true },
{ name = 'ruby_necklace_silver', label = 'Ruby necklace silver', weight = 200, type = 'item', image = 'ruby_necklace_silver.png', unique = false, useable = false, shouldClose = true },
{ name = 'ruby_ring_gold', label = 'Ruby ring gold', weight = 200, type = 'item', image = 'ruby_ring_gold.png', unique = false, useable = false, shouldClose = true },
{ name = 'ruby_ring_silver', label = 'Ruby ring silver', weight = 200, type = 'item', image = 'ruby_ring_silver.png', unique = false, useable = false, shouldClose = true },
{ name = 'sandstone', label = 'Sandstone', weight = 100, type = 'item', image = 'sandstone.png', unique = false, useable = false, shouldClose = true },
{ name = 'sapphire', label = 'Sapphire', weight = 100, type = 'item', image = 'sapphire.png', unique = false, useable = false, shouldClose = true },
{ name = 'sapphire_necklace_gold', label = 'Sapphire necklace gold', weight = 200, type = 'item', image = 'sapphire_necklace_gold.png', unique = false, useable = false, shouldClose = true },
{ name = 'sapphire_necklace_silver', label = 'Sapphire necklace silver', weight = 200, type = 'item', image = 'sapphire_necklace_silver.png', unique = false, useable = false, shouldClose = true },
{ name = 'sapphire_ring_gold', label = 'Sapphire ring gold', weight = 200, type = 'item', image = 'sapphire_ring_gold.png', unique = false, useable = false, shouldClose = true },
{ name = 'sapphire_ring_silver', label = 'Sapphire ring silver', weight = 200, type = 'item', image = 'sapphire_ring_silver.png', unique = false, useable = false, shouldClose = true },
{ name = 'silver_ingot', label = 'Silver ingot', weight = 100, type = 'item', image = 'silver_ingot.png', unique = false, useable = false, shouldClose = true },
{ name = 'silver_ore', label = 'Silver ore', weight = 100, type = 'item', image = 'silver_ore.png', unique = false, useable = false, shouldClose = true },
{ name = 'steel',      label = 'Steel',       weight = 100, type = 'item', image = 'steel.png',      imageUrl = KoraCoreSeed.imageUrl('steel'),      unique = false, useable = false, shouldClose = true, description = 'Recovered steel.' },
{ name = 'steel_ingot', label = 'Steel ingot', weight = 100, type = 'item', image = 'steel_ingot.png', unique = false, useable = false, shouldClose = true },
{ name = 'steel_pickaxe', label = 'Steel pickaxe', weight = 1000, type = 'item', image = 'steel_pickaxe.png', unique = true, useable = false, shouldClose = true },
{ name = 'tin_ore', label = 'Tin ore', weight = 100, type = 'item', image = 'tin_ore.png', unique = false, useable = false, shouldClose = true },
{ name = 'titanium_pickaxe', label = 'Titanium pickaxe', weight = 1000, type = 'item', image = 'titanium_pickaxe.png', unique = true, useable = false, shouldClose = true },
{ name = 'topaz_necklace_gold', label = 'Topaz necklace gold', weight = 200, type = 'item', image = 'topaz_necklace_gold.png', unique = false, useable = false, shouldClose = true },
{ name = 'topaz_necklace_silver', label = 'Topaz necklace silver', weight = 200, type = 'item', image = 'topaz_necklace_silver.png', unique = false, useable = false, shouldClose = true },
{ name = 'topaz_ring_gold', label = 'Topaz ring gold', weight = 200, type = 'item', image = 'topaz_ring_gold.png', unique = false, useable = false, shouldClose = true },
{ name = 'topaz_ring_silver', label = 'Topaz ring silver', weight = 200, type = 'item', image = 'topaz_ring_silver.png', unique = false, useable = false, shouldClose = true },
{ name = 'topaz_shard', label = 'Topaz shard', weight = 200, type = 'item', image = 'topaz_shard.png', unique = false, useable = false, shouldClose = true },
{ name = 'uncut_diamond', label = 'Uncut diamond', weight = 100, type = 'item', image = 'uncut_diamond.png', unique = false, useable = false, shouldClose = true },
{ name = 'uncut_emerald', label = 'Uncut emerald', weight = 100, type = 'item', image = 'uncut_emerald.png', unique = false, useable = false, shouldClose = true },
{ name = 'uncut_ruby', label = 'Uncut ruby', weight = 100, type = 'item', image = 'uncut_ruby.png', unique = false, useable = false, shouldClose = true },
{ name = 'uncut_sapphire', label = 'Uncut sapphire', weight = 100, type = 'item', image = 'uncut_sapphire.png', unique = false, useable = false, shouldClose = true },
{ name = 'zinc_ingot', label = 'Zinc ingot', weight = 100, type = 'item', image = 'zinc_ingot.png', unique = false, useable = false, shouldClose = true },
{ name = 'zinc_ore', label = 'Zinc ore', weight = 100, type = 'item', image = 'zinc_ore.png', unique = false, useable = false, shouldClose = true },
```

## Required image files

- `kora_mining/images/amethyst_necklace_gold.png`
- `kora_mining/images/amethyst_necklace_silver.png`
- `kora_mining/images/amethyst_ring_gold.png`
- `kora_mining/images/amethyst_ring_silver.png`
- `kora_mining/images/amethyst_shard.png`
- `kora_mining/images/basalt.png`
- `kora_mining/images/bauxite.png`
- `kora_mining/images/bronze_ignot.png`
- `kora_mining/images/bronze_pickaxe.png`
- `kora_mining/images/carbon.png`
- `kora_mining/images/carbon_ignot.png`
- `kora_mining/images/carbonatite.png`
- `kora_mining/images/copper.png`
- `kora_mining/images/copper_ignot.png`
- `kora_mining/images/copper_ore.png`
- `kora_mining/images/diamond.png`
- `kora_mining/images/diamond_necklace_gold.png`
- `kora_mining/images/diamond_necklace_silver.png`
- `kora_mining/images/diamond_ring_gold.png`
- `kora_mining/images/diamond_ring_silver.png`
- `kora_mining/images/emerald.png`
- `kora_mining/images/emerald_necklace.png`
- `kora_mining/images/emerald_necklace_gold.png`
- `kora_mining/images/emerald_necklace_silver.png`
- `kora_mining/images/emerald_ring_gold.png`
- `kora_mining/images/emerald_ring_silver.png`
- `kora_mining/images/glass.png`
- `kora_mining/images/gold_ingot.png`
- `kora_mining/images/gold_ore.png`
- `kora_mining/images/iron.png`
- `kora_mining/images/iron_ingot.png`
- `kora_mining/images/iron_ore.png`
- `kora_mining/images/iron_pickaxe.png`
- `kora_mining/images/metalscrap.png`
- `kora_mining/images/obsidian.png`
- `kora_mining/images/obsidian_ignot.png`
- `kora_mining/images/obsidian_pickaxe.png`
- `kora_mining/images/opal_necklace_gold.png`
- `kora_mining/images/opal_necklace_silver.png`
- `kora_mining/images/opal_ring_gold.png`
- `kora_mining/images/opal_ring_silver.png`
- `kora_mining/images/opal_shard.png`
- `kora_mining/images/plastic.png`
- `kora_mining/images/quartz_necklace_gold.png`
- `kora_mining/images/quartz_necklace_silver.png`
- `kora_mining/images/quartz_ring_gold.png`
- `kora_mining/images/quartz_ring_silver.png`
- `kora_mining/images/quartz_shard.png`
- `kora_mining/images/ring_gold.png`
- `kora_mining/images/ring_silver.png`
- `kora_mining/images/rubber.png`
- `kora_mining/images/ruby.png`
- `kora_mining/images/ruby_necklace_gold.png`
- `kora_mining/images/ruby_necklace_silver.png`
- `kora_mining/images/ruby_ring_gold.png`
- `kora_mining/images/ruby_ring_silver.png`
- `kora_mining/images/sandstone.png`
- `kora_mining/images/sapphire.png`
- `kora_mining/images/sapphire_necklace_gold.png`
- `kora_mining/images/sapphire_necklace_silver.png`
- `kora_mining/images/sapphire_ring_gold.png`
- `kora_mining/images/sapphire_ring_silver.png`
- `kora_mining/images/silver_ingot.png`
- `kora_mining/images/silver_ore.png`
- `kora_mining/images/steel.png`
- `kora_mining/images/steel_ingot.png`
- `kora_mining/images/steel_pickaxe.png`
- `kora_mining/images/tin_ore.png`
- `kora_mining/images/titanium_pickaxe.png`
- `kora_mining/images/topaz_necklace_gold.png`
- `kora_mining/images/topaz_necklace_silver.png`
- `kora_mining/images/topaz_ring_gold.png`
- `kora_mining/images/topaz_ring_silver.png`
- `kora_mining/images/topaz_shard.png`
- `kora_mining/images/uncut_diamond.png`
- `kora_mining/images/uncut_emerald.png`
- `kora_mining/images/uncut_ruby.png`
- `kora_mining/images/uncut_sapphire.png`
- `kora_mining/images/zinc_ingot.png`
- `kora_mining/images/zinc_ore.png`

## Image coverage

The mining resource includes every referenced PNG under its `images` directory.
