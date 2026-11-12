local APP = 'kora_mining:creator'
local rocks, selected, selectedPickaxe, rewardItems = {}, nil, nil, {}
local smeltRecipes, smeltStations, smeltEditing, smeltItems = {}, {}, nil, {}
local selectedSmeltStation, stationRecipeQuery, pendingStationLocation = nil, '', nil
local smeltItemSearch={query=nil,results={}}
local pendingPlace = false
local pickaxeShop, pendingPickaxeVendor = nil, false
local miningBlips, selectedBlipId, pendingBlip = {}, nil, nil
local buildCreatorNavigation
local ROCK_MODELS = MiningConfig.rockModels
local ROCK_CATEGORIES = MiningConfig.rockCategories
local SMELT_CATEGORIES = MiningConfig.smeltingCategories

local function isSupportedRockModel(model)
    for _, available in ipairs(ROCK_MODELS) do if model == available then return true end end
    return false
end
local PICKAXES = MiningConfig.pickaxes

local function notify(message, tone)
    return { tone = tone or 'success', message = message }
end

local function refresh(message)
    local creatorNavigation = buildCreatorNavigation()
    Kora.nui.updateApp(APP, { navigation = creatorNavigation })
    return { update = { navigation = creatorNavigation }, notice = message }
end

local function fail(message)
    message = message or Kora.lang('Error.action_failed')
    Kora.notify.send({ title = Kora.lang('Creator.mining_creator'), message = message, type = 'error' })
    return refresh(notify(message, 'destructive'))
end

local function loadSmeltingCreatorData()
    local result,err=Kora.callback.trigger('kora_mining:smelting:creator:get')
    if not result then return nil,err end
    smeltRecipes,smeltStations,smeltItems=result.recipes or {},result.stations or {},result.items or {}
    return result
end

local function promptForItemAmount(itemLabel, title, currentAmount)
    local fields = {
        {
            id = 'amount',
            label = Kora.lang('Creator.amount'),
            type = 'number',
            min = 1,
            max = 1000,
            default = currentAmount or 1,
            required = true,
        },
    }
    local description = Kora.lang('Creator.how_many_s_does_this', itemLabel)
    local result = Kora.nui.openInputDialog(fields, title, description)

    if not result or result.cancelled then
        return nil
    end

    local amount = tonumber(result.values and result.values.amount)
    if not amount then
        return nil
    end

    return { amount = amount }
end

local function buildRockSettingsPage()
    local d = selected.data or {}
    local modelOptions = {}
    for _, model in ipairs(ROCK_MODELS) do modelOptions[#modelOptions + 1] = { value = model, label = model } end
    local blocks = {
            { type = 'form', id = 'settings', title = Kora.lang('Creator.rockspawn_settings'), fields = {
                { id = 'category', label = Kora.lang('Creator.category'), type = 'select', required = true,
                    default = d.category or 'resources', options = ROCK_CATEGORIES },
                { id = 'model', label = Kora.lang('Creator.rock_prop_model'), type = 'select', required = true, default = d.model or '', options = modelOptions,
                    description = Kora.lang('Creator.models_streamed_by_the_props') },
                { id = 'item', label = Kora.lang('Creator.item_given'), type = 'select', required = true, searchable = true,
                    options = rewardItems, default = d.item or '', description = Kora.lang('Creator.search_by_item_label_or') },
                { id = 'icon', label = Kora.lang('Creator.target_icon'), type = 'text', default = d.icon or '' },
                { id = 'targetLabel', label = Kora.lang('Creator.target_label'), type = 'text', default = d.targetLabel or '' },
                { id = 'progressLabel', label = Kora.lang('Creator.progress_bar_label'), type = 'text', default = d.progressLabel or '' },
                { id = 'maxGive', label = Kora.lang('Creator.max_given_per_mine'), type = 'number', min = 1, max = 100, default = d.maxGive or 2 },
                { id = 'respawnTime', label = Kora.lang('Creator.respawn_time_seconds'), type = 'number', min = 1, max = 3600, default = d.respawnTime or 60 },
                { id = 'pickTime', label = Kora.lang('Creator.mining_time_ms'), type = 'number', min = 500, max = 60000, default = d.pickTime or 5000 },
                { id = 'levelRequired', label = Kora.lang('Creator.mining_level_required'), type = 'number', min = 1, max = 99, default = d.levelRequired or 1 },
                { id = 'xpPerMine', label = Kora.lang('Creator.mining_xp_per_mine'), type = 'number', min = 0, max = 10000, default = d.xpPerMine or 0 },
                { id = 'maxLevelSpeedBonus', label = Kora.lang('Creator.max_mining_level_speed_bonus'), type = 'number', min = 0, max = 99,
                    default = d.maxLevelSpeedBonus or 0, description = Kora.lang('Creator.speed_increase_gained_progressively_reaching') },
            }, action = { id = 'settings:save', label = Kora.lang('Creator.save_settings') } },
            { type = 'list', id = 'pickaxe-list', title = Kora.lang('Creator.pickaxes_for_this_rock'), items = (function()
                local items = {}
                for _, pick in ipairs(PICKAXES) do
                    local config = (d.pickaxes or {})[pick.id] or {}
                    items[#items + 1] = { id = pick.id, label = pick.name, icon = 'Pickaxe',
                        description = Kora.lang('Creator.d_faster_s', config.speedBonus or 0,
                            config.enabled == false and Kora.lang('Creator.disabled_for_this_rock_mining', pick.level)
                                or Kora.lang('Creator.mining_level_d', pick.level)),
                        action = { id = 'pick:speed:' .. pick.id, label = Kora.lang('Creator.set_speed'), variant = 'outline', fields = {
                            { id = 'speedBonus', label = Kora.lang('Creator.mining_speed_bonus'), type = 'number', min = 0, max = 99,
                                default = config.speedBonus or 0 },
                        } },
                        actions = { { id = 'pick:toggle:' .. pick.id,
                            label = config.enabled == false and Kora.lang('Error.enable') or Kora.lang('Error.disable'),
                            variant = config.enabled == false and 'primary' or 'destructive' } } }
                end
                return items
            end)() },
            { type = 'actions', title = Kora.lang('Creator.spots'), actions = { { id = 'spots:add', label = Kora.lang('Creator.place_rock_spots'), variant = 'primary' } } },
            { type = 'list', id = 'spots', title = Kora.lang('Creator.spots_d', #(selected.locations or {})), items = (function()
                local items = {}
                for i, spot in ipairs(selected.locations or {}) do
                    local c = spot.coords
                    items[#items + 1] = { id = tostring(i), label = Kora.lang('Creator.spot_d', i), icon = 'MapPin',
                        description = Kora.lang('Creator.coords_2f_2f_2f', c.x, c.y, c.z),
                        actions = { { id = 'spots:remove:' .. i, label = Kora.lang('Creator.delete'), icon = 'Trash2', variant = 'destructive' } } }
                end
                return items
            end)(), empty = Kora.lang('Creator.no_rock_spots_placed') },
            { type = 'actions', title = Kora.lang('Creator.danger_zone'), actions = { { id = 'delete', label = Kora.lang('Creator.delete_rockspawn'), variant = 'destructive' } } },
        }
    return { id = 'settings', label = Kora.lang('Creator.settings'), icon = 'Settings', content = {
        title = selected.id,
        description = Kora.lang('Creator.rock_prop_reward_mining_time'),
        blocks = blocks,
    } }
end

local function blipValues(value, blip)
    value = value or {}
    return {
        name = value.name, description = value.description or '',
        sprite = tonumber(value.sprite), color = tonumber(value.color), scale = tonumber(value.scale),
        shortRange = value.shortRange ~= 'no' and value.shortRange ~= false,
        x = blip and blip.x, y = blip and blip.y, z = blip and blip.z,
    }
end

local function findBlip(id)
    for _, blip in ipairs(miningBlips) do if blip.id == id then return blip end end
end

local function buildBlipsPage()
    local rows = {}
    for _, blip in ipairs(miningBlips) do
        rows[#rows + 1] = {
            id = blip.id,
            label = blip.name,
            icon = 'MapPin',
            description = Kora.lang('Creator.sprite_d_colour_d_0', blip.sprite, blip.color, blip.x, blip.y, blip.z),
            actions = {
                { id = 'blips:edit:' .. blip.id, label = Kora.lang('Creator.edit'), icon = 'Pencil', variant = 'outline' },
                { id = 'blips:delete:' .. blip.id, label = Kora.lang('Creator.delete'), icon = 'Trash2', variant = 'destructive' },
            },
        }
    end
    local d = findBlip(selectedBlipId) or {}
    local editing = d.id ~= nil
    local blocks = {
        {
            type = 'list',
            id = 'blip-list',
            title = Kora.lang('Creator.map_blips_d', #rows),
            items = rows,
            empty = Kora.lang('Creator.no_blips_yet'),
        },
        {
            type = 'form',
            id = 'blip-details',
            title = editing and Kora.lang('Error.edit_blip', d.name) or Kora.lang('Creator.new_blip'),
            fields = {
                { id = 'name', label = Kora.lang('Creator.name'), type = 'text', required = true, default = d.name or '' },
                { id = 'sprite', label = Kora.lang('Creator.sprite'), type = 'number', min = 0, max = 900, default = d.sprite or 1, required = true },
                { id = 'color', label = Kora.lang('Creator.colour'), type = 'number', min = 0, max = 85, default = d.color or 0, required = true },
                { id = 'scale', label = Kora.lang('Creator.size'), type = 'number', min = 0.1, max = 3.0, default = d.scale or 0.7, required = true },
                { id = 'shortRange', label = Kora.lang('Creator.short_range'), type = 'select', required = true,
                    default = (d.shortRange == false) and 'no' or 'yes',
                    options = { { value = 'yes', label = Kora.lang('Creator.yes_only_shows_near_the') }, { value = 'no', label = Kora.lang('Creator.no_shows_on_the_whole') } } },
                { id = 'description', label = Kora.lang('Creator.description'), type = 'text', default = d.description or '' },
            },
            action = editing and { id = 'blips:save', label = Kora.lang('Creator.save_blip') }
                or { id = 'blips:place', label = Kora.lang('Creator.aim_and_place_location') },
        },
    }
    local actions = { { id = 'blips:new', label = Kora.lang('Creator.new_blip'), icon = 'Plus', variant = 'outline' } }
    if editing then actions[#actions + 1] = { id = 'blips:replace', label = Kora.lang('Creator.re_aim_location'), icon = 'MapPin', variant = 'outline' } end
    blocks[#blocks + 1] = { type = 'actions', actions = actions }
    return {
        id = 'blips',
        label = Kora.lang('Creator.blips'),
        icon = 'MapPin',
        content = {
            title = Kora.lang('Creator.blips'),
            description = Kora.lang('Creator.map_blips_shown_to_every'),
            blocks = blocks,
        },
    }
end

buildCreatorNavigation = function()
    -- Built once per call so every "look up a smelt item's label/image by value"
    -- below is O(1) instead of rescanning smeltItems per recipe/ingredient.
    local itemsByValue = {}
    for _, item in ipairs(smeltItems) do itemsByValue[item.value] = item end

    local blocks = {}
    for _, category in ipairs(ROCK_CATEGORIES) do
        local items = {}
        for _, rock in ipairs(rocks) do
            if (rock.data.category or 'resources') == category.value then
                items[#items + 1] = { id = rock.id, label = rock.id, icon = 'Pickaxe',
                    description = Kora.lang('Creator.d_spots_s_mining_level', rock.count or 0,
                        rock.data.item or 'configure reward', rock.data.levelRequired or 1),
                    action = 'select:' .. rock.id }
            end
        end
        blocks[#blocks + 1] = { type = 'list', id = 'rocks-' .. category.value, title = category.label,
            items = items, empty = Kora.lang('Creator.no_s_rockspawns_created_yet', category.label:lower()) }
    end
    blocks[#blocks + 1] = { type = 'form', id = 'create', title = Kora.lang('Creator.create_rockspawn'), fields = {
        { id = 'id', label = Kora.lang('Creator.rockspawn_name'), type = 'text', required = true, description = Kora.lang('Creator.letters_numbers_and_underscores') },
    }, action = { id = 'create', label = Kora.lang('Creator.create') } }
    local pages = { { id = 'rockspawns', label = Kora.lang('Creator.rockspawns'), icon = 'Mountain', content = {
        title = Kora.lang('Creator.rockspawns'), description = Kora.lang('Creator.create_and_organize_mineable_rocks'), blocks = blocks,
    } } }
    if selected then pages[#pages + 1] = buildRockSettingsPage() end
    local recipesByCategory = {}
    for _, category in ipairs(SMELT_CATEGORIES) do
        recipesByCategory[category.value] = {}
    end

    for _, recipe in ipairs(smeltRecipes) do
        local image = itemsByValue[recipe.output] and itemsByValue[recipe.output].image

        local description = Kora.lang('Creator.choose_result_and_ingredients_to')
        if recipe.output then
            description = Kora.lang('Creator.makes_dx_s_level_d',
                recipe.amount or 1,
                recipe.output,
                recipe.level or 1
            )
        end

        local row = {
            id = recipe.id,
            label = recipe.label,
            description = description,
            image = image,
            action = 'smelt:edit:' .. recipe.id,
        }

        local categoryRecipes = recipesByCategory[recipe.category] or recipesByCategory.materials
        categoryRecipes[#categoryRecipes + 1] = row
    end

    local stationRows = {}
    for _, station in ipairs(smeltStations) do
        stationRows[#stationRows + 1] = {
            id = station.id,
            label = station.label,
            icon = 'Flame',
            description = Kora.lang('Creator.d_recipes_d_locations',
                #(station.recipes or {}),
                #(station.locations or {})
            ),
            action = 'smelt:station:' .. station.id,
        }
    end

    local recipeBlocks = {
        {
            type = 'actions',
            actions = {
                { id = 'smelt:recipe:new', label = Kora.lang('Creator.create_new_recipe'), icon = 'Plus', variant = 'primary' },
            },
        },
    }

    for _, category in ipairs(SMELT_CATEGORIES) do
        recipeBlocks[#recipeBlocks + 1] = {
            type = 'list',
            id = 'smelt-list-' .. category.value,
            title = Kora.lang('Creator.s_d', category.label, #recipesByCategory[category.value]),
            items = recipesByCategory[category.value],
            empty = Kora.lang('Creator.no_s_recipes', category.label:lower()),
        }
    end

    recipeBlocks[#recipeBlocks + 1] = {
        type = 'form',
        id = 'smelt-station-create',
        title = Kora.lang('Creator.create_a_crafter'),
        fields = {
            { id = 'stationLabel', label = Kora.lang('Creator.crafter_name'), type = 'text', required = true },
        },
        action = { id = 'smelt:station:create', label = Kora.lang('Creator.create_crafter') },
    }
    recipeBlocks[#recipeBlocks + 1] = {
        type = 'list',
        id = 'smelt-stations',
        title = Kora.lang('Creator.crafters_d', #stationRows),
        items = stationRows,
        empty = Kora.lang('Creator.no_crafters_created'),
    }

    pages[#pages + 1] = {
        id = 'smelting',
        label = Kora.lang('Creator.smelting'),
        icon = 'Flame',
        content = {
            title = Kora.lang('Creator.smelting_recipes_and_stations'),
            description = Kora.lang('Creator.organize_recipes_by_category_create'),
            blocks = recipeBlocks,
        },
    }
    -- Vendor locations share one shop catalog, so admins can place the same shop in several areas.
    local vendorLocations = pickaxeShop and pickaxeShop.locations or {}
    local vendorRows = {}
    for i, location in ipairs(vendorLocations) do
        local c = location.coords or location
        vendorRows[#vendorRows + 1] = {
            id = tostring(i),
            label = Kora.lang('Creator.vendor_location_d', i),
            icon = 'MapPin',
            description = Kora.lang('Creator.coords_0_2f_0_2f_0', c.x, c.y, c.z),
            actions = {
                {
                    id = 'pickaxe:vendor:location:remove:' .. i,
                    label = Kora.lang('Creator.remove'),
                    icon = 'Trash2',
                    variant = 'destructive',
                },
            },
        }
    end
    pages[#pages + 1] = {
        id = 'pickaxe-vendor',
        label = Kora.lang('Creator.pickaxe_vendor'),
        icon = 'Store',
        content = {
            title = Kora.lang('Creator.pickaxe_vendor'),
            description = Kora.lang('Creator.add_multiple_vendor_locations_each'),
            blocks = {
                {
                    type = 'actions',
                    actions = {
                        { id = 'pickaxe:vendor:place', label = Kora.lang('Creator.add_vendor_location'), icon = 'MapPin', variant = 'primary' },
                    },
                },
                {
                    type = 'list',
                    id = 'pickaxe-vendor-locations',
                    title = Kora.lang('Creator.vendor_locations_d', #vendorRows),
                    items = vendorRows,
                    empty = Kora.lang('Creator.no_vendor_locations_placed'),
                },
                {
                    type = 'list',
                    title = Kora.lang('Creator.pickaxes_for_sale'),
                    items = (function()
                        local rows = {}

                        for _, pick in ipairs(PICKAXES) do
                            local price = pickaxeShop and pickaxeShop.prices and pickaxeShop.prices[pick.item]
                                or pick.price

                            rows[#rows + 1] = {
                                id = pick.item,
                                label = pick.name,
                                description = Kora.lang('Creator.mining_level_d_d', pick.level, price),
                                action = {
                                    id = 'pickaxe:price:' .. pick.item,
                                    label = Kora.lang('Creator.change_price'),
                                    icon = 'DollarSign',
                                    variant = 'outline',
                                    fields = {
                                        {
                                            id = 'price',
                                            label = Kora.lang('Creator.price_in_cash'),
                                            type = 'number',
                                            min = 0,
                                            max = 100000000,
                                            default = price,
                                            required = true,
                                        },
                                    },
                                },
                            }
                        end

                        return rows
                    end)(),
                },
            },
        },
    }
    pages[#pages + 1] = buildBlipsPage()
    local station
    for _,entry in ipairs(smeltStations) do if entry.id==selectedSmeltStation then station=entry; break end end
    if station then
        local attached,available,has,categoriesEnabled={},{},{},{}
        for _,id in ipairs(station.recipes or {}) do has[id]=true end
        for _,category in ipairs(station.categories or {}) do categoriesEnabled[category]=true end
        local categoryActions={}
        for _,category in ipairs(SMELT_CATEGORIES) do
            local enabled=categoriesEnabled[category.value]
            categoryActions[#categoryActions+1]={id='smelt:station:category:'..category.value,
                label=(enabled and '✓ ' or '+ ')..category.label,icon=enabled and 'Check' or 'Plus',variant=enabled and 'primary' or 'secondary'}
        end
        for _,recipe in ipairs(smeltRecipes) do
          if recipe.output and #(recipe.inputs or {})>0 then
            local output,image=recipe.output,nil
            local item=itemsByValue[recipe.output]
            if item then output,image=item.label,item.image end
            local row={id=recipe.id,label=recipe.label,description=Kora.lang('Creator.makes_dx_s', recipe.amount,output),image=image}
            if has[recipe.id] then
                row.actions={{id='smelt:station:remove:'..recipe.id,label = Kora.lang('Creator.remove'),icon='Trash2',variant='destructive'}}
                attached[#attached+1]=row
            else
                local query=stationRecipeQuery:lower()
                if not categoriesEnabled[recipe.category] and (query=='' or recipe.label:lower():find(query,1,true) or recipe.id:lower():find(query,1,true)) then
                    row.actions={{id='smelt:station:add:'..recipe.id,label = Kora.lang('Creator.add'),icon='Plus',variant='primary'}}
                    available[#available+1]=row
                end
            end
          end
        end
        local locations={}
        for i,loc in ipairs(station.locations or {}) do
            local c=loc.coords
            locations[#locations+1]={id=tostring(i),label=Kora.lang('Creator.location_d_s', i,loc.object and (' · '..loc.object) or ''),icon='MapPin',
                description=Kora.lang('Creator.coords_0_2f_0_2f_0', c.x,c.y,c.z),
                actions={{id='smelt:station:location:remove:'..i,label = Kora.lang('Creator.delete'),icon='Trash2',variant='destructive'}}}
        end
        pages[#pages+1]={id='smelt-station',label=station.label,icon='Flame',content={title=station.label,description = Kora.lang('Creator.choose_supported_recipe_categories_every'),blocks={
            {type='form',id='smelt-station-details',title = Kora.lang('Creator.station_settings'),fields={{id='label',label = Kora.lang('Creator.station_name'),type='text',required=true,default=station.label},{id='targetLabel',label = Kora.lang('Creator.target_label'),type='text',default=station.targetLabel or Kora.lang('Ui.smelt')},{id='targetIcon',label = Kora.lang('Creator.target_icon'),type='text',default=station.targetIcon or 'fa-solid fa-fire'}},action={id='smelt:station:details',label = Kora.lang('Creator.save')}},
            {type='actions',title = Kora.lang('Creator.available_recipe_categories'),actions=categoryActions},
            {type='list',id='smelt-station-attached',title=Kora.lang('Creator.recipes_at_station_d', #attached),items=attached,empty = Kora.lang('Creator.no_recipes_assigned_yet')},
            {type='form',id='smelt-station-search',title = Kora.lang('Creator.find_recipes_to_add'),fields={{id='query',label = Kora.lang('Creator.search_recipes'),type='text',default=stationRecipeQuery}},action={id='smelt:station:search',label = Kora.lang('Creator.search')}},
            {type='list',id='smelt-station-available',title=Kora.lang('Creator.available_recipes_d', #available),items=available,empty = Kora.lang('Creator.no_matching_recipes_to_add')},
            {type='form',id='smelt-station-location',title = Kora.lang('Creator.place_a_target_location'),fields={{id='object',label = Kora.lang('Creator.object_model_optional'),type='text',default='',description = Kora.lang('Creator.leave_blank_to_grab_coordinates')}},action={id='smelt:station:place',label = Kora.lang('Creator.aim_and_place_location')}},
            {type='list',id='smelt-station-locations',title=Kora.lang('Creator.locations_d', #locations),items=locations,empty = Kora.lang('Creator.no_locations_yet')},
            {type='actions',title = Kora.lang('Creator.danger_zone'),actions={{id='smelt:station:delete',label = Kora.lang('Creator.delete_station'),variant='destructive'}}},
        }}}
    end
    local recipe
    for _,entry in ipairs(smeltRecipes) do if entry.id==smeltEditing then recipe=entry; break end end
    if recipe then
        local details={{id='label',label = Kora.lang('Creator.recipe_name'),type='text',required=true,default=recipe.label},
            {id='category',label = Kora.lang('Creator.category'),type='select',required=true,default=recipe.category or 'materials',options=SMELT_CATEGORIES},
            {id='level',label = Kora.lang('Creator.smelting_level_required'),type='number',min=1,max=99,default=recipe.level or 1},
            {id='xp',label = Kora.lang('Creator.smelting_xp'),type='number',min=0,max=10000,default=recipe.xp or 0},
            {id='duration',label = Kora.lang('Creator.smelting_time_ms'),type='number',min=500,max=300000,default=recipe.duration or 10000}}
        local blocks={{type='form',id='smelt-details',title = Kora.lang('Creator.recipe_details'),fields=details,action={id='smelt:details',label = Kora.lang('Creator.save_details')}}}
        local output={}
        if recipe.output then
            local label,image=recipe.output,nil
            local item=itemsByValue[recipe.output]
            if item then label,image=item.label,item.image end
            output[1]={id='output',label=label,description=recipe.output,image=image,metadata={{label = Kora.lang('Creator.amount_made'),value=Kora.lang('Creator.dx', recipe.amount or 1)}},
                actions={{id='smelt:output:amount',label = Kora.lang('Creator.edit_amount'),icon='Pencil',variant='primary'}}}
        end
        blocks[#blocks+1]={type='list',id='smelt-output',title = Kora.lang('Creator.what_it_makes'),items=output,empty = Kora.lang('Creator.search_for_an_item_and')}
        blocks[#blocks+1]={type='form',id='smelt-item-search',title = Kora.lang('Creator.find_items'),fields={{id='query',label = Kora.lang('Creator.search_all_items'),type='text',default=smeltItemSearch.query or '',description = Kora.lang('Creator.search_by_item_name_or')}},action={id='smelt:search',label = Kora.lang('Creator.search')}}
        if smeltItemSearch.query then
            local results={}; local query=smeltItemSearch.query:lower()
            for _,item in ipairs(smeltItemSearch.results) do
                local already=item.value==recipe.output
                for _,input in ipairs(recipe.inputs or {}) do if input.item==item.value then already=true end end
                results[#results+1]={id=item.value,label=item.label,description=item.value,image=item.image,metadata=already and {{label = Kora.lang('Creator.status'),value='Already in this recipe'}} or nil,
                    actions={{id='smelt:result:set:'..item.value,label = Kora.lang('Creator.set_as_result'),icon='Check',variant='primary'},
                        not already and {id='smelt:result:add:'..item.value,label = Kora.lang('Creator.add_to_recipe'),icon='Plus',variant='primary'} or nil}}
                if #results>=15 then break end
            end
            blocks[#blocks+1]={type='list',id='smelt-search-results',layout='cards',columns=3,title=Kora.lang('Creator.results_for_s', smeltItemSearch.query),items=results,empty = Kora.lang('Creator.no_items_match_that_search')}
        end
        local ingredients={}
        for _,input in ipairs(recipe.inputs or {}) do
            local label,image=input.item,nil
            local item=itemsByValue[input.item]
            if item then label,image=item.label,item.image end
            ingredients[#ingredients+1]={id=input.item,label=label,description=input.item,image=image,metadata={{label = Kora.lang('Creator.amount_needed'),value=Kora.lang('Creator.dx', input.amount)}},
                actions={{id='smelt:ingredient:edit:'..input.item,label = Kora.lang('Creator.edit_amount'),icon='Pencil',variant='primary'},
                    {id='smelt:ingredient:remove:'..input.item,label = Kora.lang('Creator.remove'),icon='Trash2',variant='destructive'}}}
        end
        blocks[#blocks+1]={type='list',id='smelt-ingredients',layout='cards',columns=3,title=Kora.lang('Creator.required_items_d', #ingredients),items=ingredients,empty = Kora.lang('Creator.no_ingredients_added_search_above')}
        blocks[#blocks+1]={type='actions',title = Kora.lang('Creator.danger_zone'),actions={{id='smelt:delete:'..recipe.id,label = Kora.lang('Creator.delete_recipe'),variant='destructive'}}}
        pages[#pages+1]={id='smelt-recipe',label=recipe.label,icon='Flame',content={title=recipe.label,description = Kora.lang('Creator.set_the_result_item_and'),blocks=blocks}}
    end
    return pages
end

local function openMiningCreator()
    local loaded, err = Kora.callback.trigger('kora_mining:creator:list')
    if not loaded then
        Kora.notify.send({ title = Kora.lang('Creator.mining_creator'), message = err or Kora.lang('Error.could_not_load_rockspawns'), type = 'error' })
        return
    end
    rocks = loaded
    selected, selectedPickaxe = nil, nil
    local items, itemErr = Kora.callback.trigger('kora_mining:creator:item-options')
    if not items then
        Kora.notify.send({ title = Kora.lang('Creator.mining_creator'), message = itemErr or Kora.lang('Error.could_not_load_inventory_items'), type = 'error' })
        return
    end
    rewardItems = items
    local vendor, vendorErr = Kora.callback.trigger('kora_mining:pickaxeShop:creator:get')
      if not vendor then Kora.notify.send({title = Kora.lang('Creator.mining_creator'),message=vendorErr or Kora.lang('Error.could_not_load_vendor'),type='error'}); return end
      pickaxeShop = vendor
      local blipList, blipErr = Kora.callback.trigger('kora_mining:blips:creator:get')
      if not blipList then Kora.notify.send({title = Kora.lang('Creator.mining_creator'),message=blipErr or Kora.lang('Error.could_not_load_blips'),type='error'}); return end
      miningBlips, selectedBlipId, pendingBlip = blipList, nil, nil
      local smelting, smeltErr = Kora.callback.trigger('kora_mining:smelting:creator:get')
    if not smelting then
        Kora.notify.send({ title = Kora.lang('Creator.mining_creator'), message=smeltErr or Kora.lang('Error.could_not_load_recipes'), type='error' })
        return
    end
    smeltRecipes, smeltStations = smelting.recipes or {}, smelting.stations or {}
    smeltItems = items
    smeltEditing, selectedSmeltStation = nil, nil
    Kora.nui.registerApp({ id = APP, title = Kora.lang('Creator.mining_creator'), description = Kora.lang('Creator.configure_rockspawns'), icon = 'Pickaxe', layout = 'standard', width = 1100, height = 800,
        navigation = buildCreatorNavigation(), onAction = function(action, context)
            local value = context and context.value or {}
            if action == 'smelt:recipe:new' then
                local dialog=Kora.nui.openInputDialog({{id='label',label = Kora.lang('Creator.recipe_name'),type='text',required=true}}, Kora.lang('Creator.new_smelting_recipe'), Kora.lang('Creator.edit_recipe_and_add_items'))
                local label=dialog and not dialog.cancelled and dialog.values and dialog.values.label
                if not label or label=='' then return refresh() end
                local result,err=Kora.callback.trigger('kora_mining:smelting:creator:recipeCreate',label)
                if not result then return fail(err) end
                smeltRecipes,smeltStations=result.recipes or {},result.stations or {}; smeltEditing=result.id; smeltItemSearch={query=nil,results={}}
                return refresh(notify(Kora.lang('Notify.recipe_created_choose_its_result')))
            elseif action == 'smelt:details' then
                local result,err=Kora.callback.trigger('kora_mining:smelting:creator:recipeDetails',smeltEditing,value)
                if not result then return fail(err) end
                smeltRecipes,smeltStations=result.recipes or {},result.stations or {}
                return refresh(notify(Kora.lang('Notify.recipe_details_saved')))
            elseif action == 'smelt:search' then
                local query=tostring(value.query or ''):match('^%s*(.-)%s*$')
                smeltItemSearch={query=query~='' and query or nil,results={}}
                if smeltItemSearch.query then
                    local needle=smeltItemSearch.query:lower()
                    for _,item in ipairs(smeltItems) do
                        if item.value:lower():find(needle,1,true) or item.label:lower():find(needle,1,true) then
                            smeltItemSearch.results[#smeltItemSearch.results+1]=item
                            if #smeltItemSearch.results>=60 then break end
                        end
                    end
                end
                return refresh()
            elseif action == 'smelt:output:amount' then
                local recipe; for _,entry in ipairs(smeltRecipes) do if entry.id==smeltEditing then recipe=entry end end
                if not recipe or not recipe.output then return fail(Kora.lang('Error.choose_result_item_first')) end
                local picked=promptForItemAmount(recipe.output,'Edit result amount',recipe.amount or 1)
                if not picked then return refresh() end
                local result,err=Kora.callback.trigger('kora_mining:smelting:creator:recipeOutput',smeltEditing,recipe.output,picked.amount)
                if not result then return fail(err) end
                smeltRecipes,smeltStations=result.recipes or {},result.stations or {}; return refresh(notify(Kora.lang('Notify.result_amount_updated')))
            elseif action:match('^smelt:result:set:') then
                local itemName=action:sub(18); local amount=1
                local recipe; for _,entry in ipairs(smeltRecipes) do if entry.id==smeltEditing then recipe=entry end end
                if recipe and recipe.output==itemName then amount=recipe.amount or 1 end
                local option; for _,entry in ipairs(smeltItems) do if entry.value==itemName then option=entry end end
                if not option then return fail(Kora.lang('Error.search_for_item_again_first')) end
                local picked=promptForItemAmount(option.label,'Set recipe result amount',amount)
                if not picked then return refresh() end
                local result,err=Kora.callback.trigger('kora_mining:smelting:creator:recipeOutput',smeltEditing,itemName,picked.amount)
                if not result then return fail(err) end
                smeltRecipes,smeltStations=result.recipes or {},result.stations or {}
                return refresh(notify(Kora.lang('Notify.recipe_result_saved')))
            elseif action:match('^smelt:result:add:') then
                local itemName=action:sub(18); local recipe
                for _,entry in ipairs(smeltRecipes) do if entry.id==smeltEditing then recipe=entry end end
                if not recipe then return fail(Kora.lang('Error.choose_recipe_first')) end
                for _,entry in ipairs(recipe.inputs or {}) do if entry.item==itemName then return fail(Kora.lang('Error.item_already_required')) end end
                local option; for _,entry in ipairs(smeltItems) do if entry.value==itemName then option=entry end end
                if not option then return fail(Kora.lang('Error.search_for_item_again_first')) end
                local picked=promptForItemAmount(option.label,'Add required item')
                if not picked then return refresh() end
                local inputs={table.unpack(recipe.inputs or {})}; inputs[#inputs+1]={item=itemName,amount=picked.amount}
                local result,err=Kora.callback.trigger('kora_mining:smelting:creator:recipeInputs',smeltEditing,inputs)
                if not result then return fail(err) end
                smeltRecipes,smeltStations=result.recipes or {},result.stations or {}
                return refresh(notify(Kora.lang('Creator.added_dx_s', picked.amount,option.label)))
            elseif action:match('^smelt:ingredient:edit:') then
                local itemName=action:sub(23); local recipe
                for _,entry in ipairs(smeltRecipes) do if entry.id==smeltEditing then recipe=entry end end
                local input; for _,entry in ipairs(recipe and recipe.inputs or {}) do if entry.item==itemName then input=entry end end
                if not input then return refresh() end
                local option; for _,entry in ipairs(smeltItems) do if entry.value==itemName then option=entry end end
                local picked=promptForItemAmount(option and option.label or itemName,'Edit required amount',input.amount)
                if not picked then return refresh() end
                local inputs={}; for _,entry in ipairs(recipe.inputs) do inputs[#inputs+1]={item=entry.item,amount=entry.item==itemName and picked.amount or entry.amount} end
                local result,err=Kora.callback.trigger('kora_mining:smelting:creator:recipeInputs',smeltEditing,inputs)
                if not result then return fail(err) end
                smeltRecipes,smeltStations=result.recipes or {},result.stations or {}
                return refresh(notify(Kora.lang('Notify.required_item_amount_updated')))
            elseif action:match('^smelt:ingredient:remove:') then
                local itemName=action:sub(25); local recipe
                for _,entry in ipairs(smeltRecipes) do if entry.id==smeltEditing then recipe=entry end end
                local inputs={}; for _,entry in ipairs(recipe and recipe.inputs or {}) do if entry.item~=itemName then inputs[#inputs+1]=entry end end
                local result,err=Kora.callback.trigger('kora_mining:smelting:creator:recipeInputs',smeltEditing,inputs)
                if not result then return fail(err) end
                smeltRecipes,smeltStations=result.recipes or {},result.stations or {}
                return refresh(notify(Kora.lang('Notify.required_item_removed')))
            elseif action:match('^smelt:edit:') then
                smeltEditing=action:sub(12)
                return refresh()
            elseif action:match('^smelt:delete:') then
                local id=action:sub(14)
                local ok,err=Kora.callback.trigger('kora_mining:smelting:creator:recipeDelete',id)
                if not ok then return fail(err) end
                local loaded=Kora.callback.trigger('kora_mining:smelting:creator:get')
                smeltRecipes,smeltStations=loaded and loaded.recipes or {},loaded and loaded.stations or {}
                if smeltEditing==id then smeltEditing=nil end
                return refresh(notify(Kora.lang('Notify.smelting_recipe_deleted')))
            elseif action == 'smelt:station:create' then
                local result,err=Kora.callback.trigger('kora_mining:smelting:creator:stationCreate',value.stationLabel)
                if not result then return fail(err) end
                smeltStations=result.stations or {}; selectedSmeltStation=result.id
                return refresh(notify(Kora.lang('Notify.crafter_created_choose_categories_and')))
            elseif action:match('^smelt:station:category:') then
                local category=action:match('^smelt:station:category:(.+)$')
                local station
                for _,entry in ipairs(smeltStations) do if entry.id==selectedSmeltStation then station=entry end end
                if not station or not category then return fail(Kora.lang('Error.select_station_and_category')) end
                local categories,enabled={},false
                for _,entry in ipairs(station.categories or {}) do if entry==category then enabled=true else categories[#categories+1]=entry end end
                if not enabled then categories[#categories+1]=category end
                local result,err=Kora.callback.trigger('kora_mining:smelting:creator:stationCategories',station.id,categories)
                if not result then return fail(err) end
                smeltRecipes,smeltStations=result.recipes or {},result.stations or {}
                return refresh(notify(Kora.lang(enabled and 'Error.disabled_category' or 'Error.enabled_category', category)))
            elseif action:match('^smelt:station:add:') or action:match('^smelt:station:remove:') then
                local add=action:match('^smelt:station:add:')~=nil
                local recipeId=action:match('^smelt:station:add:(.+)$') or action:match('^smelt:station:remove:(.+)$')
                local station
                for _,entry in ipairs(smeltStations) do if entry.id==selectedSmeltStation then station=entry end end
                if not station then return fail(Kora.lang('Error.select_station')) end
                local recipeIds={}; local present=false
                for _,id in ipairs(station.recipes or {}) do
                    if id==recipeId then present=true; if not add then else recipeIds[#recipeIds+1]=id end
                    else recipeIds[#recipeIds+1]=id end
                end
                if add and not present then recipeIds[#recipeIds+1]=recipeId end
                local result,err=Kora.callback.trigger('kora_mining:smelting:creator:stationRecipes',station.id,recipeIds)
                if not result then return fail(err) end
                smeltRecipes,smeltStations=result.recipes or {},result.stations or {}
                return refresh(notify(Kora.lang(add and 'Error.recipe_added_to_station' or 'Error.recipe_removed_from_station')))
            elseif action == 'smelt:station:details' then
                local result,err=Kora.callback.trigger('kora_mining:smelting:creator:stationDetails',selectedSmeltStation,value)
                if not result then return fail(err) end
                smeltStations=result.stations or {}; return refresh(notify(Kora.lang('Notify.station_saved')))
            elseif action == 'smelt:station:search' then
                stationRecipeQuery=tostring(value.query or ''):match('^%s*(.-)%s*$'); return refresh()
            elseif action == 'blips:new' then
                selectedBlipId = nil
                return refresh()
            elseif action:match('^blips:edit:') then
                local id = action:sub(#'blips:edit:' + 1)
                if not findBlip(id) then return fail(Kora.lang('Error.blip_not_found')) end
                selectedBlipId = id
                return refresh()
            elseif action:match('^blips:delete:') then
                local id = action:sub(#'blips:delete:' + 1)
                local list, delErr = Kora.callback.trigger('kora_mining:blips:creator:delete', id)
                if not list then return fail(delErr) end
                miningBlips = list
                if selectedBlipId == id then selectedBlipId = nil end
                return refresh(notify(Kora.lang('Notify.blip_deleted')))
            elseif action == 'blips:save' then
                local blip = findBlip(selectedBlipId)
                if not blip then return fail(Kora.lang('Error.choose_edit_or_place_blip')) end
                local list, saveErr = Kora.callback.trigger('kora_mining:blips:creator:save', blip.id, blipValues(value, blip))
                if not list then return fail(saveErr) end
                miningBlips = list
                return refresh(notify(Kora.lang('Notify.blip_saved')))
            elseif action == 'blips:place' then
                pendingBlip = { id = nil, values = blipValues(value) }
                return {close=true}
            elseif action == 'blips:replace' then
                local blip = findBlip(selectedBlipId)
                if not blip then return fail(Kora.lang('Error.blip_not_found')) end
                pendingBlip = { id = blip.id, values = blipValues(blip, blip) }
                return {close=true}
            elseif action == 'pickaxe:vendor:place' then
                pendingPickaxeVendor = true
                return {close=true}
            elseif action:match('^pickaxe:vendor:location:remove:') then
                local index=tonumber(action:match('(%d+)$'))
                local locations={}
                for i,location in ipairs(pickaxeShop and pickaxeShop.locations or {}) do
                    if i~=index then locations[#locations+1]=location end
                end
                local saved,saveErr=Kora.callback.trigger('kora_mining:pickaxeShop:creator:save','s_m_m_dockwork_01',locations)
                if not saved then return fail(saveErr) end
                pickaxeShop=saved
                return refresh(notify(Kora.lang('Notify.vendor_location_removed')))
            elseif action:match('^pickaxe:price:') then
                local item=action:match('^pickaxe:price:(.+)$')
                local saved,saveErr=Kora.callback.trigger('kora_mining:pickaxeShop:creator:price',item,value.price)
                if not saved then return fail(saveErr) end
                pickaxeShop=saved
                return refresh(notify(Kora.lang('Notify.pickaxe_price_saved')))
            elseif action == 'smelt:station:place' then
                local object=tostring(value.object or ''):match('^%s*(.-)%s*$')
                if object=='' then object=nil elseif not IsModelInCdimage(GetHashKey(object)) then return fail(Kora.lang('Error.unknown_object_model')) end
                pendingStationLocation={object=object}; return {close=true}
            elseif action:match('^smelt:station:location:remove:') then
                local index=tonumber(action:match('(%d+)$')); local station
                for _,entry in ipairs(smeltStations) do if entry.id==selectedSmeltStation then station=entry end end
                if not station or not index then return fail(Kora.lang('Error.unknown_station_location')) end
                local locations={}; for i,loc in ipairs(station.locations or {}) do if i~=index then locations[#locations+1]=loc end end
                local result,err=Kora.callback.trigger('kora_mining:smelting:creator:stationLocations',station.id,locations)
                if not result then return fail(err) end
                smeltStations=result.stations or {}; return refresh(notify(Kora.lang('Notify.location_removed')))
            elseif action == 'smelt:station:delete' then
                local id=selectedSmeltStation
                local result,err=Kora.callback.trigger('kora_mining:smelting:creator:stationDelete',id)
                if not result then return fail(err) end
                smeltRecipes,smeltStations=result.recipes or {},result.stations or {}; selectedSmeltStation=nil
                return refresh(notify(Kora.lang('Notify.station_deleted')))
            elseif action:match('^smelt:station:') then
                local id=action:sub(15)
                for _,entry in ipairs(smeltStations) do if entry.id==id then selectedSmeltStation=id; stationRecipeQuery=''; break end end
                return refresh()
            elseif action:match('^pick:speed:') then
                local id = action:sub(12)
                local result, err = Kora.callback.trigger('kora_mining:creator:pickaxes:save', selected.id, id, {
                    speedBonus = tonumber(value.speedBonus),
                    enabled = ((selected.data.pickaxes or {})[id] or {}).enabled ~= false,
                })
                if not result then return fail(err) end
                selected = result
                for _, entry in ipairs(rocks) do if entry.id == result.id then entry.data = result.data; entry.count = result.count end end
                return refresh(notify(Kora.lang('Notify.pickaxe_saved')))
            elseif action:match('^pick:toggle:') then
                local id = action:sub(13)
                local config = (selected.data.pickaxes or {})[id] or {}
                local result, err = Kora.callback.trigger('kora_mining:creator:pickaxes:save', selected.id, id, {
                    speedBonus = tonumber(config.speedBonus) or 0,
                    enabled = config.enabled == false,
                })
                if not result then return fail(err) end
                selected = result
                for _, entry in ipairs(rocks) do if entry.id == result.id then entry.data = result.data; entry.count = result.count end end
                return refresh(notify(Kora.lang(config.enabled == false and 'Error.pickaxe_enabled' or 'Error.pickaxe_disabled')))
            elseif action:match('^select:') then
                local id = action:sub(8)
                for _, entry in ipairs(rocks) do
                    if entry.id == id then
                        selected = entry
                        selectedPickaxe = nil
                        break
                    end
                end
                return refresh()
            elseif action == 'create' then
                local record, err = Kora.callback.trigger('kora_mining:creator:create', value.id)
                if not record then return fail(err) end
                selected = record
                rocks[#rocks + 1] = { id = record.id, data = record.data, count = 0 }
                return refresh(notify(Kora.lang('Notify.rockspawn_created_set_its_settings')))
            elseif action == 'settings:save' and selected then
                if not isSupportedRockModel(value.model) then return fail(Kora.lang('Error.choose_loaded_rock_prop')) end
                local data = {
                    category = value.category or selected.data.category or 'resources',
                    model = value.model, item = value.item, icon = value.icon or '', targetLabel = value.targetLabel or '',
                    progressLabel = value.progressLabel or '', maxGive = tonumber(value.maxGive), respawnTime = tonumber(value.respawnTime),
                    pickTime = tonumber(value.pickTime), pickaxes = selected.data.pickaxes or {}, levelRequired = tonumber(value.levelRequired),
                    xpPerMine = tonumber(value.xpPerMine),
                    maxLevelSpeedBonus = tonumber(value.maxLevelSpeedBonus),
                    locations = selected.locations or {},
                }
                local saved, err = Kora.callback.trigger('kora_mining:creator:save', selected.id, data)
                if not saved then return fail(err) end
                selected = saved
                for _, entry in ipairs(rocks) do if entry.id == saved.id then entry.data = saved.data; entry.count = #saved.locations end end
                return refresh(notify(Kora.lang('Notify.saved')))
            elseif action == 'spots:add' and selected then
                local model = selected.data and selected.data.model
                if type(model) ~= 'string' or model == '' then
                    return fail(Kora.lang('Error.save_rock_prop_before_spots'))
                end
                pendingPlace = true
                return { close = true }
            elseif action:match('^spots:remove:') and selected then
                local index = tonumber(action:match('(%d+)$'))
                if index then table.remove(selected.locations, index) end
                local data = selected.data
                data.locations = selected.locations
                local saved, err = Kora.callback.trigger('kora_mining:creator:save', selected.id, data)
                if not saved then return fail(err) end
                selected = saved
                return refresh(notify(Kora.lang('Notify.spot_removed')))
            elseif action == 'delete' and selected then
                local ok, err = Kora.callback.trigger('kora_mining:creator:delete', selected.id)
                if not ok then return fail(err) end
                for i, entry in ipairs(rocks) do if entry.id == selected.id then table.remove(rocks, i); break end end
                selected = nil
                return refresh(notify(Kora.lang('Notify.rockspawn_deleted')))
            end
            return {}
        end })
    while true do
        Kora.nui.openApp(APP)
        local reopenCreator = pendingStationLocation ~= nil or pendingPickaxeVendor or pendingBlip ~= nil
        if pendingStationLocation then
            local placement = pendingStationLocation
            pendingStationLocation = nil
            local options=placement.object and {type='object',object=placement.object} or {}
            local ok, aimed = pcall(Kora.raycast.getCoords, options)
            if ok and aimed and aimed.coords then
                local station
                for _,entry in ipairs(smeltStations) do if entry.id==selectedSmeltStation then station=entry end end
                if station then
                    local locations={table.unpack(station.locations or {})}
                    locations[#locations+1]={coords={x=aimed.coords.x,y=aimed.coords.y,z=aimed.coords.z,w=aimed.heading or 0.0},object=placement.object}
                    local result,err=Kora.callback.trigger('kora_mining:smelting:creator:stationLocations',station.id,locations)
                    if not result then Kora.notify.send({title = Kora.lang('Creator.mining_creator'),message=err or Kora.lang('Error.could_not_save_station_location'),type='error'})
                    else smeltRecipes,smeltStations=result.recipes or {},result.stations or {} end
                end
            elseif not ok then
                Kora.notify.send({title = Kora.lang('Creator.mining_creator'),message=tostring(aimed),type='error'})
            end
            Kora.nui.updateApp(APP, { navigation=buildCreatorNavigation() })
        end
        if pendingPickaxeVendor then
            pendingPickaxeVendor = false
            local ok, aimed = pcall(function()
                return Kora.raycast.getCoords({ type = 'object', object = 's_m_m_dockwork_01' })
            end)
            local coords = ok and aimed and aimed.coords
            if coords then
                local locations={table.unpack(pickaxeShop and pickaxeShop.locations or {})}
                locations[#locations+1]={coords={x=coords.x,y=coords.y,z=coords.z,w=coords.w or aimed.heading or 0.0}}
                local saved, saveErr = Kora.callback.trigger('kora_mining:pickaxeShop:creator:save', 's_m_m_dockwork_01', locations)
                if not saved then
                    Kora.notify.send({title = Kora.lang('Creator.mining_creator'),message=saveErr or Kora.lang('Error.could_not_save_vendor_location'),type='error'})
                else
                    pickaxeShop = saved
                end
            elseif not ok then
                Kora.notify.send({title = Kora.lang('Creator.mining_creator'),message=tostring(aimed),type='error'})
            end
            Kora.nui.updateApp(APP, {navigation=buildCreatorNavigation()})
        end
        if pendingBlip then
            local placement = pendingBlip
            pendingBlip = nil
            local ok, aimed = pcall(Kora.raycast.getCoords, {})
            local coords = ok and aimed and aimed.coords
            if coords then
                local values = placement.values
                values.x, values.y, values.z = coords.x, coords.y, coords.z
                local list, saveErr = Kora.callback.trigger('kora_mining:blips:creator:save', placement.id, values)
                if not list then
                    Kora.notify.send({title = Kora.lang('Creator.mining_creator'),message=saveErr or Kora.lang('Error.could_not_save_blip'),type='error'})
                else
                    miningBlips = list
                    if not placement.id then selectedBlipId = nil end
                end
            elseif not ok then
                Kora.notify.send({title = Kora.lang('Creator.mining_creator'),message=tostring(aimed),type='error'})
            end
            Kora.nui.updateApp(APP, {navigation=buildCreatorNavigation()})
        end
        if pendingPlace then
            pendingPlace = false
            while true do
                local model = selected and selected.data and selected.data.model
                local options = type(model) == 'string' and model ~= ''
                    and { type = 'object', object = model } or {}
                local ok, aimed = pcall(Kora.raycast.getCoords, options)
                if not ok then
                    Kora.notify.send({ title = Kora.lang('Creator.mining_creator'), message = tostring(aimed), type = 'error' })
                    break
                end
                if not aimed or not aimed.coords then break end
                selected.locations[#selected.locations + 1] = { coords = { x = aimed.coords.x, y = aimed.coords.y, z = aimed.coords.z } }
                local data = selected.data
                data.locations = selected.locations
                local result, err = Kora.callback.trigger('kora_mining:creator:save', selected.id, data)
                if not result then Kora.notify.send({ title = Kora.lang('Creator.mining_creator'), message = err or Kora.lang('Error.could_not_save_spot'), type = 'error' }); break end
                selected = result
                for _, entry in ipairs(rocks) do if entry.id == result.id then entry.count = #result.locations end end
                Kora.nui.updateApp(APP, { navigation = buildCreatorNavigation() })
            end
        elseif not reopenCreator then
            break
        end
    end
end

RegisterNetEvent('kora_mining:creator:open', function()
    if source ~= 65535 then return end
    CreateThread(openMiningCreator)
end)

