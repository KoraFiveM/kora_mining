local APP = 'kora_mining:creator'
local rocks, selected, selectedPickaxe, rewardItems = {}, nil, nil, {}
local smeltRecipes, smeltStations, smeltEditing, smeltItems = {}, {}, nil, {}
local selectedSmeltStation, stationRecipeQuery, pendingStationLocation = nil, '', nil
local smeltItemSearch={query=nil,results={}}
local pendingPlace = false
local pickaxeShop, pendingPickaxeVendor = nil, false
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
    message = message or 'Action failed.'
    Kora.notify.send({ title = 'Mining Creator', message = message, type = 'error' })
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
            label = 'Amount',
            type = 'number',
            min = 1,
            max = 1000,
            default = currentAmount or 1,
            required = true,
        },
    }
    local description = ('How many %s does this recipe need or make?'):format(itemLabel)
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
            { type = 'form', id = 'settings', title = 'Rockspawn settings', fields = {
                { id = 'category', label = 'Category', type = 'select', required = true,
                    default = d.category or 'resources', options = ROCK_CATEGORIES },
                { id = 'model', label = 'Rock prop model', type = 'select', required = true, default = d.model or '', options = modelOptions,
                    description = 'Models streamed by the props resource.' },
                { id = 'item', label = 'Item given', type = 'select', required = true, searchable = true,
                    options = rewardItems, default = d.item or '', description = 'Search by item label or item name.' },
                { id = 'icon', label = 'Target icon', type = 'text', default = d.icon or '' },
                { id = 'targetLabel', label = 'Target label', type = 'text', default = d.targetLabel or '' },
                { id = 'progressLabel', label = 'Progress bar label', type = 'text', default = d.progressLabel or '' },
                { id = 'maxGive', label = 'Max given per mine', type = 'number', min = 1, max = 100, default = d.maxGive or 2 },
                { id = 'respawnTime', label = 'Respawn time (seconds)', type = 'number', min = 1, max = 3600, default = d.respawnTime or 60 },
                { id = 'pickTime', label = 'Mining time (ms)', type = 'number', min = 500, max = 60000, default = d.pickTime or 5000 },
                { id = 'levelRequired', label = 'Mining level required', type = 'number', min = 1, max = 99, default = d.levelRequired or 1 },
                { id = 'xpPerMine', label = 'Mining XP per mine', type = 'number', min = 0, max = 10000, default = d.xpPerMine or 0 },
                { id = 'maxLevelSpeedBonus', label = 'Max Mining level speed bonus (%)', type = 'number', min = 0, max = 99,
                    default = d.maxLevelSpeedBonus or 0, description = 'Speed increase gained progressively, reaching this percentage at level 99.' },
            }, action = { id = 'settings:save', label = 'Save settings' } },
            { type = 'list', id = 'pickaxe-list', title = 'Pickaxes for this rock', items = (function()
                local items = {}
                for _, pick in ipairs(PICKAXES) do
                    local config = (d.pickaxes or {})[pick.id] or {}
                    items[#items + 1] = { id = pick.id, label = pick.name, icon = 'Pickaxe',
                        description = ('%d%% faster · %s'):format(config.speedBonus or 0,
                            config.enabled == false and ('disabled for this rock · Mining level %d'):format(pick.level)
                                or ('Mining level %d'):format(pick.level)),
                        action = { id = 'pick:speed:' .. pick.id, label = 'Set speed', variant = 'outline', fields = {
                            { id = 'speedBonus', label = 'Mining speed bonus (%)', type = 'number', min = 0, max = 99,
                                default = config.speedBonus or 0 },
                        } },
                        actions = { { id = 'pick:toggle:' .. pick.id,
                            label = config.enabled == false and 'Enable' or 'Disable',
                            variant = config.enabled == false and 'primary' or 'destructive' } } }
                end
                return items
            end)() },
            { type = 'actions', title = 'Spots', actions = { { id = 'spots:add', label = 'Place rock spots', variant = 'primary' } } },
            { type = 'list', id = 'spots', title = ('Spots (%d)'):format(#(selected.locations or {})), items = (function()
                local items = {}
                for i, spot in ipairs(selected.locations or {}) do
                    local c = spot.coords
                    items[#items + 1] = { id = tostring(i), label = ('Spot %d'):format(i), icon = 'MapPin',
                        description = ('%.2f, %.2f, %.2f'):format(c.x, c.y, c.z),
                        actions = { { id = 'spots:remove:' .. i, label = 'Delete', icon = 'Trash2', variant = 'destructive' } } }
                end
                return items
            end)(), empty = 'No rock spots placed.' },
            { type = 'actions', title = 'Danger zone', actions = { { id = 'delete', label = 'Delete rockspawn', variant = 'destructive' } } },
        }
    return { id = 'settings', label = 'Settings', icon = 'Settings', content = {
        title = selected.id,
        description = 'Rock prop, reward, mining time, Mining level, and the speed bonus at max Mining level.',
        blocks = blocks,
    } }
end

buildCreatorNavigation = function()
    local blocks = {}
    for _, category in ipairs(ROCK_CATEGORIES) do
        local items = {}
        for _, rock in ipairs(rocks) do
            if (rock.data.category or 'resources') == category.value then
                items[#items + 1] = { id = rock.id, label = rock.id, icon = 'Pickaxe',
                    description = ('%d spots · %s · Mining level %s'):format(rock.count or 0,
                        rock.data.item or 'configure reward', rock.data.levelRequired or 1),
                    action = 'select:' .. rock.id }
            end
        end
        blocks[#blocks + 1] = { type = 'list', id = 'rocks-' .. category.value, title = category.label,
            items = items, empty = ('No %s rockspawns created yet.'):format(category.label:lower()) }
    end
    blocks[#blocks + 1] = { type = 'form', id = 'create', title = 'Create rockspawn', fields = {
        { id = 'id', label = 'Rockspawn name', type = 'text', required = true, description = 'Letters, numbers and underscores.' },
    }, action = { id = 'create', label = 'Create' } }
    local pages = { { id = 'rockspawns', label = 'Rockspawns', icon = 'Mountain', content = {
        title = 'Rockspawns', description = 'Create and organize mineable rocks by category.', blocks = blocks,
    } } }
    if selected then pages[#pages + 1] = buildRockSettingsPage() end
    local recipesByCategory = {}
    for _, category in ipairs(SMELT_CATEGORIES) do
        recipesByCategory[category.value] = {}
    end

    for _, recipe in ipairs(smeltRecipes) do
        local image
        for _, item in ipairs(smeltItems) do
            if item.value == recipe.output then
                image = item.image
                break
            end
        end

        local description = 'Choose result and ingredients to finish this recipe'
        if recipe.output then
            description = ('Makes %dx %s · Level %d'):format(
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
            description = ('%d recipes · %d locations'):format(
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
                { id = 'smelt:recipe:new', label = 'Create new recipe', icon = 'Plus', variant = 'primary' },
            },
        },
    }

    for _, category in ipairs(SMELT_CATEGORIES) do
        recipeBlocks[#recipeBlocks + 1] = {
            type = 'list',
            id = 'smelt-list-' .. category.value,
            title = ('%s (%d)'):format(category.label, #recipesByCategory[category.value]),
            items = recipesByCategory[category.value],
            empty = ('No %s recipes.'):format(category.label:lower()),
        }
    end

    recipeBlocks[#recipeBlocks + 1] = {
        type = 'form',
        id = 'smelt-station-create',
        title = 'Create a crafter',
        fields = {
            { id = 'stationLabel', label = 'Crafter name', type = 'text', required = true },
        },
        action = { id = 'smelt:station:create', label = 'Create crafter' },
    }
    recipeBlocks[#recipeBlocks + 1] = {
        type = 'list',
        id = 'smelt-stations',
        title = ('Crafters (%d)'):format(#stationRows),
        items = stationRows,
        empty = 'No crafters created.',
    }

    pages[#pages + 1] = {
        id = 'smelting',
        label = 'Smelting',
        icon = 'Flame',
        content = {
            title = 'Smelting recipes and stations',
            description = 'Organize recipes by category, create them, then assign them to crafting stations.',
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
            label = ('Vendor location %d'):format(i),
            icon = 'MapPin',
            description = ('%0.2f, %0.2f, %0.2f'):format(c.x, c.y, c.z),
            actions = {
                {
                    id = 'pickaxe:vendor:location:remove:' .. i,
                    label = 'Remove',
                    icon = 'Trash2',
                    variant = 'destructive',
                },
            },
        }
    end
    pages[#pages + 1] = {
        id = 'pickaxe-vendor',
        label = 'Pickaxe Vendor',
        icon = 'Store',
        content = {
            title = 'Pickaxe Vendor',
            description = 'Add multiple vendor locations. Each one uses the same pickaxe catalog and Mining level requirements.',
            blocks = {
                {
                    type = 'actions',
                    actions = {
                        { id = 'pickaxe:vendor:place', label = 'Add Vendor Location', icon = 'MapPin', variant = 'primary' },
                    },
                },
                {
                    type = 'list',
                    id = 'pickaxe-vendor-locations',
                    title = ('Vendor Locations (%d)'):format(#vendorRows),
                    items = vendorRows,
                    empty = 'No vendor locations placed.',
                },
                {
                    type = 'list',
                    title = 'Pickaxes for sale',
                    items = (function()
                        local rows = {}

                        for _, pick in ipairs(PICKAXES) do
                            local price = pickaxeShop and pickaxeShop.prices and pickaxeShop.prices[pick.item]
                                or pick.price

                            rows[#rows + 1] = {
                                id = pick.item,
                                label = pick.name,
                                description = ('Mining level %d · $%d'):format(pick.level, price),
                                action = {
                                    id = 'pickaxe:price:' .. pick.item,
                                    label = 'Change price',
                                    icon = 'DollarSign',
                                    variant = 'outline',
                                    fields = {
                                        {
                                            id = 'price',
                                            label = 'Price in cash',
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
            for _,item in ipairs(smeltItems) do if item.value==recipe.output then output=item.label; image=item.image; break end end
            local row={id=recipe.id,label=recipe.label,description=('Makes %dx %s'):format(recipe.amount,output),image=image}
            if has[recipe.id] then
                row.actions={{id='smelt:station:remove:'..recipe.id,label='Remove',icon='Trash2',variant='destructive'}}
                attached[#attached+1]=row
            else
                local query=stationRecipeQuery:lower()
                if not categoriesEnabled[recipe.category] and (query=='' or recipe.label:lower():find(query,1,true) or recipe.id:lower():find(query,1,true)) then
                    row.actions={{id='smelt:station:add:'..recipe.id,label='Add',icon='Plus',variant='primary'}}
                    available[#available+1]=row
                end
            end
          end
        end
        local locations={}
        for i,loc in ipairs(station.locations or {}) do
            local c=loc.coords
            locations[#locations+1]={id=tostring(i),label=('Location %d%s'):format(i,loc.object and (' · '..loc.object) or ''),icon='MapPin',
                description=('%0.2f, %0.2f, %0.2f'):format(c.x,c.y,c.z),
                actions={{id='smelt:station:location:remove:'..i,label='Delete',icon='Trash2',variant='destructive'}}}
        end
        pages[#pages+1]={id='smelt-station',label=station.label,icon='Flame',content={title=station.label,description='Choose supported recipe categories. Every recipe in an enabled category is available here; individual recipes can also be assigned below.',blocks={
            {type='form',id='smelt-station-details',title='Station settings',fields={{id='label',label='Station name',type='text',required=true,default=station.label},{id='targetLabel',label='Target label',type='text',default=station.targetLabel or 'Smelt'},{id='targetIcon',label='Target icon',type='text',default=station.targetIcon or 'fa-solid fa-fire'}},action={id='smelt:station:details',label='Save'}},
            {type='actions',title='Available recipe categories',actions=categoryActions},
            {type='list',id='smelt-station-attached',title=('Recipes at station (%d)'):format(#attached),items=attached,empty='No recipes assigned yet.'},
            {type='form',id='smelt-station-search',title='Find recipes to add',fields={{id='query',label='Search recipes',type='text',default=stationRecipeQuery}},action={id='smelt:station:search',label='Search'}},
            {type='list',id='smelt-station-available',title=('Available recipes (%d)'):format(#available),items=available,empty='No matching recipes to add.'},
            {type='form',id='smelt-station-location',title='Place a target location',fields={{id='object',label='Object model (optional)',type='text',default='',description='Leave blank to grab coordinates for a zone; enter a prop model to spawn and target that object.'}},action={id='smelt:station:place',label='Aim and place location'}},
            {type='list',id='smelt-station-locations',title=('Locations (%d)'):format(#locations),items=locations,empty='No locations yet.'},
            {type='actions',title='Danger zone',actions={{id='smelt:station:delete',label='Delete station',variant='destructive'}}},
        }}}
    end
    local recipe
    for _,entry in ipairs(smeltRecipes) do if entry.id==smeltEditing then recipe=entry; break end end
    if recipe then
        local details={{id='label',label='Recipe name',type='text',required=true,default=recipe.label},
            {id='category',label='Category',type='select',required=true,default=recipe.category or 'materials',options=SMELT_CATEGORIES},
            {id='level',label='Smelting level required',type='number',min=1,max=99,default=recipe.level or 1},
            {id='xp',label='Smelting XP',type='number',min=0,max=10000,default=recipe.xp or 0},
            {id='duration',label='Smelting time (ms)',type='number',min=500,max=300000,default=recipe.duration or 10000}}
        local blocks={{type='form',id='smelt-details',title='Recipe details',fields=details,action={id='smelt:details',label='Save details'}}}
        local output={}
        if recipe.output then
            local label=recipe.output
            local image
            for _,item in ipairs(smeltItems) do if item.value==recipe.output then label=item.label; image=item.image; break end end
            output[1]={id='output',label=label,description=recipe.output,image=image,metadata={{label='Amount made',value=('%dx'):format(recipe.amount or 1)}},
                actions={{id='smelt:output:amount',label='Edit amount',icon='Pencil',variant='primary'}}}
        end
        blocks[#blocks+1]={type='list',id='smelt-output',title='What it makes',items=output,empty='Search for an item and choose Set as result.'}
        blocks[#blocks+1]={type='form',id='smelt-item-search',title='Find items',fields={{id='query',label='Search all items',type='text',default=smeltItemSearch.query or '',description='Search by item name or label. Choose Set as result or Add to recipe.'}},action={id='smelt:search',label='Search'}}
        if smeltItemSearch.query then
            local results={}; local query=smeltItemSearch.query:lower()
            for _,item in ipairs(smeltItemSearch.results) do
                local already=item.value==recipe.output
                for _,input in ipairs(recipe.inputs or {}) do if input.item==item.value then already=true end end
                results[#results+1]={id=item.value,label=item.label,description=item.value,image=item.image,metadata=already and {{label='Status',value='Already in this recipe'}} or nil,
                    actions={{id='smelt:result:set:'..item.value,label='Set as result',icon='Check',variant='primary'},
                        not already and {id='smelt:result:add:'..item.value,label='Add to recipe',icon='Plus',variant='primary'} or nil}}
                if #results>=15 then break end
            end
            blocks[#blocks+1]={type='list',id='smelt-search-results',layout='cards',columns=3,title=('Results for "%s"'):format(smeltItemSearch.query),items=results,empty='No items match that search.'}
        end
        local ingredients={}
        for _,input in ipairs(recipe.inputs or {}) do
            local label=input.item
            for _,item in ipairs(smeltItems) do if item.value==input.item then label=item.label; break end end
            local image; for _,item in ipairs(smeltItems) do if item.value==input.item then image=item.image; break end end
            ingredients[#ingredients+1]={id=input.item,label=label,description=input.item,image=image,metadata={{label='Amount needed',value=('%dx'):format(input.amount)}},
                actions={{id='smelt:ingredient:edit:'..input.item,label='Edit amount',icon='Pencil',variant='primary'},
                    {id='smelt:ingredient:remove:'..input.item,label='Remove',icon='Trash2',variant='destructive'}}}
        end
        blocks[#blocks+1]={type='list',id='smelt-ingredients',layout='cards',columns=3,title=('Required items (%d)'):format(#ingredients),items=ingredients,empty='No ingredients added. Search above and choose Add to recipe.'}
        blocks[#blocks+1]={type='actions',title='Danger zone',actions={{id='smelt:delete:'..recipe.id,label='Delete recipe',variant='destructive'}}}
        pages[#pages+1]={id='smelt-recipe',label=recipe.label,icon='Flame',content={title=recipe.label,description='Set the result item and add the required ingredients using the searchable item picker.',blocks=blocks}}
    end
    return pages
end

local function openMiningCreator()
    local loaded, err = Kora.callback.trigger('kora_mining:creator:list')
    if not loaded then
        Kora.notify.send({ title = 'Mining Creator', message = err or 'Could not load rockspawns.', type = 'error' })
        return
    end
    rocks = loaded
    selected, selectedPickaxe = nil, nil
    local items, itemErr = Kora.callback.trigger('kora_mining:creator:item-options')
    if not items then
        Kora.notify.send({ title = 'Mining Creator', message = itemErr or 'Could not load inventory items.', type = 'error' })
        return
    end
    rewardItems = items
    local vendor, vendorErr = Kora.callback.trigger('kora_mining:pickaxeShop:creator:get')
      if not vendor then Kora.notify.send({title='Mining Creator',message=vendorErr or 'Could not load pickaxe vendor.',type='error'}); return end
      pickaxeShop = vendor
      local smelting, smeltErr = Kora.callback.trigger('kora_mining:smelting:creator:get')
    if not smelting then
        Kora.notify.send({ title='Mining Creator', message=smeltErr or 'Could not load smelting recipes.', type='error' })
        return
    end
    smeltRecipes, smeltStations = smelting.recipes or {}, smelting.stations or {}
    smeltItems = items
    smeltEditing, selectedSmeltStation = nil, nil
    Kora.nui.registerApp({ id = APP, title = 'Mining Creator', description = 'Configure rockspawns', icon = 'Pickaxe', layout = 'standard', width = 1100, height = 800,
        navigation = buildCreatorNavigation(), onAction = function(action, context)
            local value = context and context.value or {}
            if action == 'smelt:recipe:new' then
                local dialog=Kora.nui.openInputDialog({{id='label',label='Recipe name',type='text',required=true}},'New smelting recipe','You can edit the recipe details and add its items next.')
                local label=dialog and not dialog.cancelled and dialog.values and dialog.values.label
                if not label or label=='' then return refresh() end
                local result,err=Kora.callback.trigger('kora_mining:smelting:creator:recipeCreate',label)
                if not result then return fail(err) end
                smeltRecipes,smeltStations=result.recipes or {},result.stations or {}; smeltEditing=result.id; smeltItemSearch={query=nil,results={}}
                return refresh(notify('Recipe created. Choose its result and add required items.'))
            elseif action == 'smelt:details' then
                local result,err=Kora.callback.trigger('kora_mining:smelting:creator:recipeDetails',smeltEditing,value)
                if not result then return fail(err) end
                smeltRecipes,smeltStations=result.recipes or {},result.stations or {}
                return refresh(notify('Recipe details saved.'))
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
                if not recipe or not recipe.output then return fail('Choose a result item first.') end
                local picked=promptForItemAmount(recipe.output,'Edit result amount',recipe.amount or 1)
                if not picked then return refresh() end
                local result,err=Kora.callback.trigger('kora_mining:smelting:creator:recipeOutput',smeltEditing,recipe.output,picked.amount)
                if not result then return fail(err) end
                smeltRecipes,smeltStations=result.recipes or {},result.stations or {}; return refresh(notify('Result amount updated.'))
            elseif action:match('^smelt:result:set:') then
                local itemName=action:sub(18); local amount=1
                local recipe; for _,entry in ipairs(smeltRecipes) do if entry.id==smeltEditing then recipe=entry end end
                if recipe and recipe.output==itemName then amount=recipe.amount or 1 end
                local option; for _,entry in ipairs(smeltItems) do if entry.value==itemName then option=entry end end
                if not option then return fail('Search for that item again first.') end
                local picked=promptForItemAmount(option.label,'Set recipe result amount',amount)
                if not picked then return refresh() end
                local result,err=Kora.callback.trigger('kora_mining:smelting:creator:recipeOutput',smeltEditing,itemName,picked.amount)
                if not result then return fail(err) end
                smeltRecipes,smeltStations=result.recipes or {},result.stations or {}
                return refresh(notify('Recipe result saved.'))
            elseif action:match('^smelt:result:add:') then
                local itemName=action:sub(18); local recipe
                for _,entry in ipairs(smeltRecipes) do if entry.id==smeltEditing then recipe=entry end end
                if not recipe then return fail('Choose a recipe first.') end
                for _,entry in ipairs(recipe.inputs or {}) do if entry.item==itemName then return fail('That item is already required.') end end
                local option; for _,entry in ipairs(smeltItems) do if entry.value==itemName then option=entry end end
                if not option then return fail('Search for that item again first.') end
                local picked=promptForItemAmount(option.label,'Add required item')
                if not picked then return refresh() end
                local inputs={table.unpack(recipe.inputs or {})}; inputs[#inputs+1]={item=itemName,amount=picked.amount}
                local result,err=Kora.callback.trigger('kora_mining:smelting:creator:recipeInputs',smeltEditing,inputs)
                if not result then return fail(err) end
                smeltRecipes,smeltStations=result.recipes or {},result.stations or {}
                return refresh(notify(('Added %dx %s.'):format(picked.amount,option.label)))
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
                return refresh(notify('Required item amount updated.'))
            elseif action:match('^smelt:ingredient:remove:') then
                local itemName=action:sub(25); local recipe
                for _,entry in ipairs(smeltRecipes) do if entry.id==smeltEditing then recipe=entry end end
                local inputs={}; for _,entry in ipairs(recipe and recipe.inputs or {}) do if entry.item~=itemName then inputs[#inputs+1]=entry end end
                local result,err=Kora.callback.trigger('kora_mining:smelting:creator:recipeInputs',smeltEditing,inputs)
                if not result then return fail(err) end
                smeltRecipes,smeltStations=result.recipes or {},result.stations or {}
                return refresh(notify('Required item removed.'))
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
                return refresh(notify('Smelting recipe deleted.'))
            elseif action == 'smelt:station:create' then
                local result,err=Kora.callback.trigger('kora_mining:smelting:creator:stationCreate',value.stationLabel)
                if not result then return fail(err) end
                smeltStations=result.stations or {}; selectedSmeltStation=result.id
                return refresh(notify('Crafter created. Choose categories and place a location.'))
            elseif action:match('^smelt:station:category:') then
                local category=action:match('^smelt:station:category:(.+)$')
                local station
                for _,entry in ipairs(smeltStations) do if entry.id==selectedSmeltStation then station=entry end end
                if not station or not category then return fail('Select a station and category first.') end
                local categories,enabled={},false
                for _,entry in ipairs(station.categories or {}) do if entry==category then enabled=true else categories[#categories+1]=entry end end
                if not enabled then categories[#categories+1]=category end
                local result,err=Kora.callback.trigger('kora_mining:smelting:creator:stationCategories',station.id,categories)
                if not result then return fail(err) end
                smeltRecipes,smeltStations=result.recipes or {},result.stations or {}
                return refresh(notify((enabled and 'Disabled ' or 'Enabled ')..category..' category.'))
            elseif action:match('^smelt:station:add:') or action:match('^smelt:station:remove:') then
                local add=action:match('^smelt:station:add:')~=nil
                local recipeId=action:match('^smelt:station:add:(.+)$') or action:match('^smelt:station:remove:(.+)$')
                local station
                for _,entry in ipairs(smeltStations) do if entry.id==selectedSmeltStation then station=entry end end
                if not station then return fail('Select a station first.') end
                local recipeIds={}; local present=false
                for _,id in ipairs(station.recipes or {}) do
                    if id==recipeId then present=true; if not add then else recipeIds[#recipeIds+1]=id end
                    else recipeIds[#recipeIds+1]=id end
                end
                if add and not present then recipeIds[#recipeIds+1]=recipeId end
                local result,err=Kora.callback.trigger('kora_mining:smelting:creator:stationRecipes',station.id,recipeIds)
                if not result then return fail(err) end
                smeltRecipes,smeltStations=result.recipes or {},result.stations or {}
                return refresh(notify(add and 'Recipe added to station.' or 'Recipe removed from station.'))
            elseif action == 'smelt:station:details' then
                local result,err=Kora.callback.trigger('kora_mining:smelting:creator:stationDetails',selectedSmeltStation,value)
                if not result then return fail(err) end
                smeltStations=result.stations or {}; return refresh(notify('Station saved.'))
            elseif action == 'smelt:station:search' then
                stationRecipeQuery=tostring(value.query or ''):match('^%s*(.-)%s*$'); return refresh()
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
                return refresh(notify('Vendor location removed.'))
            elseif action:match('^pickaxe:price:') then
                local item=action:match('^pickaxe:price:(.+)$')
                local saved,saveErr=Kora.callback.trigger('kora_mining:pickaxeShop:creator:price',item,value.price)
                if not saved then return fail(saveErr) end
                pickaxeShop=saved
                return refresh(notify('Pickaxe price saved.'))
            elseif action == 'smelt:station:place' then
                local object=tostring(value.object or ''):match('^%s*(.-)%s*$')
                if object=='' then object=nil elseif not IsModelInCdimage(GetHashKey(object)) then return fail('Unknown object model.') end
                pendingStationLocation={object=object}; return {close=true}
            elseif action:match('^smelt:station:location:remove:') then
                local index=tonumber(action:match('(%d+)$')); local station
                for _,entry in ipairs(smeltStations) do if entry.id==selectedSmeltStation then station=entry end end
                if not station or not index then return fail('Unknown station location.') end
                local locations={}; for i,loc in ipairs(station.locations or {}) do if i~=index then locations[#locations+1]=loc end end
                local result,err=Kora.callback.trigger('kora_mining:smelting:creator:stationLocations',station.id,locations)
                if not result then return fail(err) end
                smeltStations=result.stations or {}; return refresh(notify('Location removed.'))
            elseif action == 'smelt:station:delete' then
                local id=selectedSmeltStation
                local result,err=Kora.callback.trigger('kora_mining:smelting:creator:stationDelete',id)
                if not result then return fail(err) end
                smeltRecipes,smeltStations=result.recipes or {},result.stations or {}; selectedSmeltStation=nil
                return refresh(notify('Station deleted.'))
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
                return refresh(notify('Pickaxe saved.'))
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
                return refresh(notify(config.enabled == false and 'Pickaxe enabled for this rock.' or 'Pickaxe disabled for this rock.'))
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
                return refresh(notify('Rockspawn created. Set its settings and place spots.'))
            elseif action == 'settings:save' and selected then
                if not isSupportedRockModel(value.model) then return fail('Choose a rock prop from the loaded props list.') end
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
                return refresh(notify('Saved.'))
            elseif action == 'spots:add' and selected then
                local model = selected.data and selected.data.model
                if type(model) ~= 'string' or model == '' then
                    return fail('Choose and save a rock prop model in Settings before placing spots.')
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
                return refresh(notify('Spot removed.'))
            elseif action == 'delete' and selected then
                local ok, err = Kora.callback.trigger('kora_mining:creator:delete', selected.id)
                if not ok then return fail(err) end
                for i, entry in ipairs(rocks) do if entry.id == selected.id then table.remove(rocks, i); break end end
                selected = nil
                return refresh(notify('Rockspawn deleted.'))
            end
            return {}
        end })
    while true do
        Kora.nui.openApp(APP)
        local reopenCreator = pendingStationLocation ~= nil or pendingPickaxeVendor
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
                    if not result then Kora.notify.send({title='Mining Creator',message=err or 'Could not save station location.',type='error'})
                    else smeltRecipes,smeltStations=result.recipes or {},result.stations or {} end
                end
            elseif not ok then
                Kora.notify.send({title='Mining Creator',message=tostring(aimed),type='error'})
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
                    Kora.notify.send({title='Mining Creator',message=saveErr or 'Could not save vendor location.',type='error'})
                else
                    pickaxeShop = saved
                end
            elseif not ok then
                Kora.notify.send({title='Mining Creator',message=tostring(aimed),type='error'})
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
                    Kora.notify.send({ title = 'Mining Creator', message = tostring(aimed), type = 'error' })
                    break
                end
                if not aimed or not aimed.coords then break end
                selected.locations[#selected.locations + 1] = { coords = { x = aimed.coords.x, y = aimed.coords.y, z = aimed.coords.z } }
                local data = selected.data
                data.locations = selected.locations
                local result, err = Kora.callback.trigger('kora_mining:creator:save', selected.id, data)
                if not result then Kora.notify.send({ title = 'Mining Creator', message = err or 'Could not save spot.', type = 'error' }); break end
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

