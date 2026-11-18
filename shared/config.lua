-- Shared mining settings used by the creator, mining logic, and pickaxe shop.
MiningConfig = {
    rockModels = {
        'amethyst_rock',
        'basalt_rock',
        'bauxite_rock',
        'carbon_rock',
        'carbonatite_rock',
        'copper_rock',
        'diamond_rock',
        'emerald_rock',
        'gold_rock',
        'iron_rock',
        'obsidian_rock',
        'opal_rock',
        'quartz_rock',
        'ruby_rock',
        'sandstone_rock',
        'sapphire_rock',
        'silver_rock',
        'tin_rock',
        'topaz_rock',
        'zinc_rock',
    },

    rockCategories = {
        { value = 'resources', label = 'Resources' },
        { value = 'gemstones', label = 'Gemstones' },
        { value = 'crystals', label = 'Crystals' },
    },

    smeltingCategories = {
        { value = 'bars', label = 'Bars' },
        { value = 'materials', label = 'Materials' },
        { value = 'jewellery', label = 'Jewellery' },
        { value = 'pickaxes', label = 'Pickaxes' },
        { value = 'gemstones', label = 'Gemstones' },
    },

    -- Map blip for the mine entrance (suggestion thread 1567879565496553522).
    -- Client-only, one blip per player. sprite/color/scale/shortRange fall back
    -- to kora_lib's Config.blips defaults when removed. category is a kora_lib
    -- blip category name (nil = Other); description fills the pause-map card.
    blip = {
        enabled = true,
        name = 'Mine Shaft',
        coords = vec3(2950.55, 2805.61, 41.57),
        sprite = 527,
        color = 81,
        scale = 0.7,
        shortRange = true,
        category = nil,
        description = 'Mine rocks here. Pickaxes are sold by the vendor at the quarry entrance.',
    },

    mining = {
        faceRock = true, -- turn the player toward the rock before mining
        anim = { dict = 'melee@large_wpn@streamed_core', clip = 'ground_attack_on_spot', flag = 1 }, -- flag 1 = loop
        prop = {
            enabled = true,
            model = 'prop_tool_pickaxe',
            bone = 57005, -- right hand
            offset = vec3(0.08, -0.1, -0.04),
            rotation = vec3(78.0, -20.0, 175.0),
            rotationOrder = 1,
        },
        dust = {
            enabled = true,
            dict = 'core',
            name = 'ent_dst_rocks',
            scale = 0.5,
            impact = 0.55,
            offset = vec3(0.0, 0.95, -0.95),
        },
    },

    pickaxes = {
        { id = 'pick1', name = 'Bronze Pickaxe', item = 'bronze_pickaxe', level = 1, price = 250 },
        { id = 'pick2', name = 'Iron Pickaxe', item = 'iron_pickaxe', level = 20, price = 1000 },
        { id = 'pick3', name = 'Steel Pickaxe', item = 'steel_pickaxe', level = 40, price = 2500 },
        { id = 'pick4', name = 'Titanium Pickaxe', item = 'titanium_pickaxe', level = 60, price = 5000 },
        { id = 'pick5', name = 'Obsidian Pickaxe', item = 'obsidian_pickaxe', level = 80, price = 10000 },
    },
}
