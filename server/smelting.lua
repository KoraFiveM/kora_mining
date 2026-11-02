local smeltingRecipes, smeltingStations, ready = {}, {}, false
local activeSmeltingTasks = {}
local validRecipeCategories = {}
for _, category in ipairs(MiningConfig.smeltingCategories) do
    validRecipeCategories[category.value] = true
end

local function decodeJsonTable(raw, defaultValue)
    if type(raw) ~= 'string' then
        return defaultValue
    end

    local ok, value = pcall(json.decode, raw)
    if not ok or type(value) ~= 'table' then
        return defaultValue
    end

    return value
end

local function getSharedItems()
    local ok, value = pcall(function()
        return exports['qb-core']:GetShared('Items')
    end)

    if not ok or type(value) ~= 'table' then
        ok, value = pcall(function()
            return exports.kora_core:getShared('items')
        end)
    end

    if not ok or type(value) ~= 'table' then
        return {}
    end

    return value
end

local function doesItemExist(itemName)
    return type(itemName) == 'string' and type(getSharedItems()[itemName]) == 'table'
end

local function hasMiningAdminPermission(source)
    local playerId = tonumber(source)
    return playerId ~= nil and playerId > 0 and IsPlayerAceAllowed(source, 'command')
end

local function fail(message)
    return false, message
end

local function isValidRecordId(value)
    return type(value) == 'string'
        and #value <= 32
        and value:match('^[a-z][%w_]*$') ~= nil
end

local function buildPublicStationData(station)
    return {
        id = station.id,
        label = station.data.label,
        targetLabel = station.data.targetLabel,
        targetIcon = station.data.targetIcon,
        locations = station.locations,
        categories = station.data.categories,
    }
end

local function publish(id)
    local stations = {}
    for stationId, station in pairs(smeltingStations) do
        stations[stationId] = buildPublicStationData(station)
    end

    GlobalState.koraMiningSmelting = { stations = stations }
    if id then
        TriggerClientEvent('kora_mining:smelting:stationReload', -1, id, stations[id])
    end
end

local function readStationRow(row)
    local savedData = decodeJsonTable(row.data, {})
    local stationData = {
        label = type(savedData.label) == 'string' and savedData.label or row.id,
        targetLabel = type(savedData.targetLabel) == 'string' and savedData.targetLabel or 'Smelt',
        targetIcon = type(savedData.targetIcon) == 'string' and savedData.targetIcon or 'fa-solid fa-fire',
        recipes = {},
        categories = {},
    }

    local savedRecipes = type(savedData.recipes) == 'table' and savedData.recipes or {}
    for _, recipeId in ipairs(savedRecipes) do
        if isValidRecordId(recipeId) and #stationData.recipes < 100 then
            stationData.recipes[#stationData.recipes + 1] = recipeId
        end
    end

    local seenCategories = {}
    local savedCategories = type(savedData.categories) == 'table' and savedData.categories or {}
    for _, category in ipairs(savedCategories) do
        if validRecipeCategories[category] and not seenCategories[category] then
            seenCategories[category] = true
            stationData.categories[#stationData.categories + 1] = category
        end
    end

    local locations = {}
    for _, location in ipairs(decodeJsonTable(row.locations, {})) do
        local coordinates = type(location) == 'table' and location.coords
        local x = coordinates and tonumber(coordinates.x)
        local y = coordinates and tonumber(coordinates.y)
        local z = coordinates and tonumber(coordinates.z)

        if x and y and z then
            locations[#locations + 1] = {
                coords = {
                    x = x,
                    y = y,
                    z = z,
                    w = tonumber(coordinates.w) or 0,
                },
                object = type(location.object) == 'string' and location.object or nil,
            }
        end
    end

    return {
        id = row.id,
        data = stationData,
        locations = locations,
    }
end

local function loadSmeltingData()
    smeltingRecipes, smeltingStations = {}, {}
    for _,row in ipairs(Kora.sql.query('SELECT `id`,`data` FROM `kora_mining_smelting_recipes`') or {}) do
        local recipe=decodeJsonTable(row.data,nil)
        if recipe then
            recipe.id=row.id; recipe.amount=tonumber(recipe.amount) or 1; recipe.duration=tonumber(recipe.duration) or 10000
            if not validRecipeCategories[recipe.category] then recipe.category='materials' end
            smeltingRecipes[row.id]=recipe
        end
    end
    for _,row in ipairs(Kora.sql.query('SELECT `id`,`data`,`locations` FROM `kora_mining_smelting_stations`') or {}) do
        if isValidRecordId(row.id) then smeltingStations[row.id]=readStationRow(row) end
    end
    ready=true; publish()
end

CreateThread(function()
    local ok,err=Kora.sql.ready(); assert(ok,err)
    loadSmeltingData()
end)

local function registerAdminCallback(name,handler)
    Kora.callback.register(name, function(source, ...)
        if not hasMiningAdminPermission(source) then
            return fail('Admin permission required.')
        end
        if not ready then
            return fail('Smelting is still loading.')
        end

        return handler(source, ...)
    end)
end

local function buildCreatorPayload()
    local recipes = {}
    local stations = {}
    local items = {}

    for _, recipe in pairs(smeltingRecipes) do
        recipes[#recipes + 1] = recipe
    end

    for _, station in pairs(smeltingStations) do
        stations[#stations + 1] = {
            id = station.id,
            label = station.data.label,
            recipes = station.data.recipes,
            categories = station.data.categories,
            locations = station.locations,
            targetLabel = station.data.targetLabel,
            targetIcon = station.data.targetIcon,
        }
    end

    for name, info in pairs(getSharedItems()) do
        items[#items + 1] = {
            value = name,
            label = ('%s (%s)'):format(info.label or name, name),
        }
    end

    local function sortByLabel(left, right)
        return left.label:lower() < right.label:lower()
    end

    table.sort(recipes, sortByLabel)
    table.sort(stations, sortByLabel)
    table.sort(items, sortByLabel)

    return { recipes = recipes, stations = stations, items = items }
end
registerAdminCallback('kora_mining:smelting:creator:get', function()
    return buildCreatorPayload()
end)

local function saveRecipe(recipe)
    local ok, err = Kora.sql.update(
        'INSERT INTO `kora_mining_smelting_recipes` (`id`, `data`) VALUES (?, ?) ON DUPLICATE KEY UPDATE `data` = VALUES(`data`)',
        { recipe.id, json.encode(recipe) }
    )
    if not ok then return false, err end

    smeltingRecipes[recipe.id] = recipe
    return true
end
registerAdminCallback('kora_mining:smelting:creator:recipeCreate',function(_,label)
    label=type(label)=='string' and label:match('^%s*(.-)%s*$')
    if not label or label=='' or #label>48 then return fail('Enter a recipe name (up to 48 characters).') end
    local base=label:lower():gsub('[^%w]+','_'):gsub('^_+',''):gsub('_+$',''):sub(1,24); if base=='' then base='recipe' end
    local id,n=base,1; while smeltingRecipes[id] do n=n+1; id=base..'_'..n end
    local recipe={id=id,label=label,category='bars',inputs={},amount=1,level=1,xp=0,duration=10000}
    local ok,err=saveRecipe(recipe); if not ok then return fail(err or 'Could not create recipe.') end
    publish(); local result=buildCreatorPayload(); result.id=id; return result
end)
registerAdminCallback('kora_mining:smelting:creator:recipeDetails',function(_,id,input)
    local recipe=smeltingRecipes[id]; if not recipe or type(input)~='table' then return fail('Unknown recipe.') end
    local label=type(input.label)=='string' and input.label:match('^%s*(.-)%s*$')
    local level,xp,duration=tonumber(input.level),tonumber(input.xp),tonumber(input.duration)
    local category=validRecipeCategories[input.category] and input.category or nil
    if not label or label=='' or #label>48 then return fail('Enter a recipe name (up to 48 characters).') end
    if not level or level%1~=0 or level<1 or level>99 then return fail('Smelting level must be 1 to 99.') end
    if not xp or xp%1~=0 or xp<0 or xp>10000 then return fail('XP must be 0 to 10000.') end
    if not duration or duration%1~=0 or duration<500 or duration>300000 then return fail('Smelting time must be 500 to 300000 ms.') end
    if not category then return fail('Choose a recipe category.') end
    recipe.label,recipe.category,recipe.level,recipe.xp,recipe.duration=label,category,level,xp,duration
    local ok,err=saveRecipe(recipe); if not ok then return fail(err or 'Could not save recipe.') end
    return buildCreatorPayload()
end)
registerAdminCallback('kora_mining:smelting:creator:recipeOutput',function(_,id,item,amount)
    local recipe=smeltingRecipes[id]; amount=tonumber(amount)
    if not recipe or not doesItemExist(item) then return fail('Choose an existing output item.') end
    if not amount or amount%1~=0 or amount<1 or amount>1000 then return fail('Output amount must be 1 to 1000.') end
    recipe.output,recipe.amount=item,amount
    local ok,err=saveRecipe(recipe); if not ok then return fail(err or 'Could not save result item.') end
    return buildCreatorPayload()
end)
registerAdminCallback('kora_mining:smelting:creator:recipeInputs',function(_,id,list)
    local recipe=smeltingRecipes[id]; if not recipe or type(list)~='table' or #list>20 then return fail('Invalid recipe items.') end
    local ingredients,seen={},{}
    for _,entry in ipairs(list) do
        local item,count=entry.item,tonumber(entry.amount)
        if not doesItemExist(item) then return fail('A required item does not exist.') end
        if seen[item] then return fail('Each required item can only be listed once.') end
        if not count or count%1~=0 or count<1 or count>1000 then return fail('Required item amounts must be 1 to 1000.') end
        seen[item]=true; ingredients[#ingredients+1]={item=item,amount=count}
    end
    recipe.inputs=ingredients
    local ok,err=saveRecipe(recipe); if not ok then return fail(err or 'Could not save required items.') end
    return buildCreatorPayload()
end)
registerAdminCallback('kora_mining:smelting:creator:recipeDelete',function(_,id)
    if not isValidRecordId(id) or not smeltingRecipes[id] then return fail('Unknown recipe.') end
    local ok,err=Kora.sql.update('DELETE FROM `kora_mining_smelting_recipes` WHERE `id`=?',{id})
    if not ok then return fail(err or 'Could not delete recipe.') end
    smeltingRecipes[id]=nil
    for stationId,station in pairs(smeltingStations) do
        local kept={}; for _,recipeId in ipairs(station.data.recipes) do if recipeId~=id then kept[#kept+1]=recipeId end end
        station.data.recipes=kept
        Kora.sql.update('UPDATE `kora_mining_smelting_stations` SET `data`=? WHERE `id`=?',{json.encode(station.data),stationId})
    end
    publish(); return buildCreatorPayload()
end)

local function saveStation(station)
    local ok,err=Kora.sql.update('INSERT INTO `kora_mining_smelting_stations` (`id`,`data`,`locations`) VALUES (?,?,?) ON DUPLICATE KEY UPDATE `data`=VALUES(`data`),`locations`=VALUES(`locations`)',
        {station.id,json.encode(station.data),json.encode(station.locations)})
    if not ok then return false,err end
    smeltingStations[station.id]=station; publish(station.id); return true
end
registerAdminCallback('kora_mining:smelting:creator:stationCreate',function(_,label)
    label=type(label)=='string' and label:match('^%s*(.-)%s*$')
    if not label or label=='' or #label>48 then return fail('Enter a station name (up to 48 characters).') end
    local base=label:lower():gsub('[^%w]+','_'):gsub('^_+',''):gsub('_+$',''):sub(1,24); if base=='' then base='station' end
    local id,n=base,1; while smeltingStations[id] do n=n+1; id=base..'_'..n end
    local station={id=id,data={label=label,targetLabel='Smelt',targetIcon='fa-solid fa-fire',recipes={},categories={}},locations={}}
    local ok,err=saveStation(station); if not ok then return fail(err or 'Could not create station.') end
    local result=buildCreatorPayload(); result.id=id; return result
end)
registerAdminCallback('kora_mining:smelting:creator:stationDetails',function(_,id,input)
    local station=smeltingStations[id]; if not station or type(input)~='table' then return fail('Unknown station.') end
    local label=type(input.label)=='string' and input.label:match('^%s*(.-)%s*$')
    if not label or label=='' or #label>48 then return fail('Enter a station name (up to 48 characters).') end
    station.data.label=label; station.data.targetLabel=type(input.targetLabel)=='string' and input.targetLabel:sub(1,48) or 'Smelt'
    station.data.targetIcon=type(input.targetIcon)=='string' and input.targetIcon:sub(1,64) or 'fa-solid fa-fire'
    local ok,err=saveStation(station); if not ok then return fail(err or 'Could not save station.') end
    return buildCreatorPayload()
end)
registerAdminCallback('kora_mining:smelting:creator:stationRecipes',function(_,id,list)
    local station=smeltingStations[id]; if not station or type(list)~='table' then return fail('Unknown station or invalid recipe list.') end
    local kept,seen={},{}
    for _,recipeId in ipairs(list) do
        local recipe=smeltingRecipes[recipeId]
        if not recipe or not recipe.output or type(recipe.inputs)~='table' or #recipe.inputs<1 then return fail('Finish setting the result and required items before adding a recipe to a station.') end
        if not seen[recipeId] then seen[recipeId]=true; kept[#kept+1]=recipeId end
    end
    if #kept>100 then return fail('A station can have at most 100 recipes.') end
    station.data.recipes=kept
    local ok,err=saveStation(station); if not ok then return fail(err or 'Could not save station recipes.') end
    return buildCreatorPayload()
end)
registerAdminCallback('kora_mining:smelting:creator:stationCategories',function(_,id,list)
    local station=smeltingStations[id]
    if not station or type(list)~='table' then return fail('Unknown station or invalid category list.') end
    local categories,seen={},{}
    for _,category in ipairs(list) do
        if not validRecipeCategories[category] then return fail('Choose valid recipe categories.') end
        if not seen[category] then seen[category]=true; categories[#categories+1]=category end
    end
    station.data.categories=categories
    local ok,err=saveStation(station); if not ok then return fail(err or 'Could not save station categories.') end
    return buildCreatorPayload()
end)
registerAdminCallback('kora_mining:smelting:creator:stationLocations',function(_,id,list)
    local station=smeltingStations[id]; if not station or type(list)~='table' then return fail('Unknown station or invalid locations.') end
    local locations={}
    for _,loc in ipairs(list) do
        if #locations>=100 then break end
        local c=type(loc)=='table' and loc.coords; local x,y,z=c and tonumber(c.x),c and tonumber(c.y),c and tonumber(c.z)
        local object=type(loc)=='table' and loc.object or nil
        if x and y and z and math.abs(x)<=10000 and math.abs(y)<=10000 and math.abs(z)<=10000 then
            if object~=nil and (type(object)~='string' or not object:match('^[%w_%-%.]+$')) then return fail('Invalid object model.') end
            locations[#locations+1]={coords={x=x,y=y,z=z,w=tonumber(c.w) or 0},object=object}
        else return fail('Each location needs valid coordinates.') end
    end
    station.locations=locations
    local ok,err=saveStation(station); if not ok then return fail(err or 'Could not save station locations.') end
    return buildCreatorPayload()
end)
registerAdminCallback('kora_mining:smelting:creator:stationDelete',function(_,id)
    if not smeltingStations[id] then return fail('Unknown station.') end
    local ok,err=Kora.sql.update('DELETE FROM `kora_mining_smelting_stations` WHERE `id`=?',{id})
    if not ok then return fail(err or 'Could not delete station.') end
    smeltingStations[id]=nil; publish(id); return buildCreatorPayload()
end)

local function findNearbyStation(source, stationId, locationIndex)
    local station = smeltingStations[stationId]
    if not station or type(locationIndex) ~= 'number' then
        return nil
    end

    local location = station.locations[locationIndex]
    if not location then
        return nil
    end

    local coordinates = location.coords
    local locationIsNearby = Kora.distance.player(
        source,
        vec3(coordinates.x, coordinates.y, coordinates.z),
        4.0
    )

    if not locationIsNearby then
        return nil
    end

    return station, location
end

local function getPlayerSmeltingLevel(source)
    local reputation = exports.kora_skills:getRep(source, 'smelting')
    if type(reputation) ~= 'table' then
        return 0
    end

    return tonumber(reputation.level) or 0
end

local function canPlayerUseRecipe(source, station, recipeId)
    local recipe = smeltingRecipes[recipeId]
    if not recipe or not recipe.output or type(recipe.inputs) ~= 'table' or #recipe.inputs < 1 then
        return false
    end

    local recipeIsAttached = false
    for _, attachedRecipeId in ipairs(station.data.recipes) do
        if attachedRecipeId == recipeId then
            recipeIsAttached = true
            break
        end
    end

    if not recipeIsAttached then
        for _, category in ipairs(station.data.categories) do
            if category == recipe.category then
                recipeIsAttached = true
                break
            end
        end
    end

    if not recipeIsAttached then
        return false
    end

    local requiredLevel = tonumber(recipe.level) or 1
    if getPlayerSmeltingLevel(source) < requiredLevel then
        return false
    end

    for _, ingredient in ipairs(recipe.inputs) do
        local itemCount = exports.kora_inventory:GetItemCount(source, ingredient.item)
        if itemCount < ingredient.amount then
            return false
        end
    end

    return true
end
Kora.callback.register('kora_mining:smelting:menu',function(src,stationId,key)
    if not ready then
        return fail('Smelting is still loading.')
    end

    local station = findNearbyStation(src, stationId, key)
    if not station then
        return fail('You are too far from this station.')
    end

    local playerLevel = getPlayerSmeltingLevel(src)
    local sharedItems = getSharedItems()
    local visibleRecipeIds = {}
    local seenRecipes = {}

    for _, recipeId in ipairs(station.data.recipes) do
        visibleRecipeIds[#visibleRecipeIds + 1] = recipeId
        seenRecipes[recipeId] = true
    end

    if #station.data.categories > 0 then
        for recipeId, recipe in pairs(smeltingRecipes) do
            for _, category in ipairs(station.data.categories) do
                if recipe.category == category and not seenRecipes[recipeId] then
                    visibleRecipeIds[#visibleRecipeIds + 1] = recipeId
                    seenRecipes[recipeId] = true
                    break
                end
            end
        end
    end

    local menuRecipes = {}
    for _, recipeId in ipairs(visibleRecipeIds) do
        local recipe = smeltingRecipes[recipeId]
        local requiredLevel = recipe and (tonumber(recipe.level) or 1)
        local hasValidIngredients = recipe and type(recipe.inputs) == 'table' and #recipe.inputs > 0

        if recipe and recipe.output and hasValidIngredients and playerLevel >= requiredLevel then
            local ingredients = {}
            local hasAllIngredients = true

            for _, ingredient in ipairs(recipe.inputs) do
                local item = sharedItems[ingredient.item]
                local itemCount = exports.kora_inventory:GetItemCount(src, ingredient.item)
                local hasEnough = itemCount >= ingredient.amount

                ingredients[#ingredients + 1] = {
                    label = item and item.label or ingredient.item,
                    amount = ingredient.amount,
                    has = hasEnough,
                }

                if not hasEnough then
                    hasAllIngredients = false
                end
            end

            local outputItem = sharedItems[recipe.output]
            local outputImage
            if outputItem and type(outputItem.image) == 'string' and outputItem.image ~= '' then
                outputImage = 'nui://kora_inventory/images/' .. outputItem.image
            end

            menuRecipes[#menuRecipes + 1] = {
                id = recipeId,
                label = recipe.label,
                category = recipe.category or 'materials',
                inputs = ingredients,
                output = outputItem and outputItem.label or recipe.output,
                outputImage = outputImage,
                outputAmount = recipe.amount,
                level = recipe.level,
                xp = recipe.xp,
                has = hasAllIngredients,
            }
        end
    end

    return menuRecipes
end)

Kora.callback.register('kora_mining:smelting:begin', function(source, stationId, key, recipeId)
    if activeSmeltingTasks[source] then
        return fail('You are already smelting.')
    end

    local station = findNearbyStation(source, stationId, key)
    local recipe = smeltingRecipes[recipeId]
    if not station or not canPlayerUseRecipe(source, station, recipeId) then
        return fail('You do not meet the level or item requirements.')
    end

    local startedAt = GetGameTimer()
    activeSmeltingTasks[source] = {
        station = stationId,
        key = key,
        recipe = recipeId,
        started = startedAt,
        expires = startedAt + recipe.duration + 15000,
    }

    return {
        duration = recipe.duration,
        label = 'Smelting ' .. recipe.label,
    }
end)

Kora.callback.register('kora_mining:smelting:finish', function(source)
    local task = activeSmeltingTasks[source]
    activeSmeltingTasks[source] = nil

    local recipe = task and smeltingRecipes[task.recipe]
    local station = task and findNearbyStation(source, task.station, task.key)
    if not task or not recipe or not station then
        return fail('Smelting could not be completed.')
    end

    local elapsedTime = GetGameTimer() - task.started
    local timeExpired = GetGameTimer() > task.expires
    local timeWasTooShort = elapsedTime < recipe.duration - 1000
    local canStillUseRecipe = canPlayerUseRecipe(source, station, task.recipe)
    if timeExpired or timeWasTooShort or not canStillUseRecipe then
        return fail('Smelting could not be completed.')
    end

    local removedIngredients = {}
    for _, ingredient in ipairs(recipe.inputs) do
        local removed = exports.kora_inventory:removeItem(source, ingredient.item, ingredient.amount)
        if not removed then
            for _, returnedIngredient in ipairs(removedIngredients) do
                exports.kora_inventory:addItem(source, returnedIngredient.item, returnedIngredient.amount)
            end

            return fail('Could not remove required materials.')
        end

        removedIngredients[#removedIngredients + 1] = ingredient
    end

    local addedResult = exports.kora_inventory:addItem(source, recipe.output, recipe.amount)
    if not addedResult then
        for _, ingredient in ipairs(removedIngredients) do
            exports.kora_inventory:addItem(source, ingredient.item, ingredient.amount)
        end

        return fail('You do not have room for the result.')
    end

    if recipe.xp > 0 then
        exports.kora_skills:addRep(source, 'smelting', recipe.xp)
    end

    return true
end)

RegisterNetEvent('kora_mining:smelting:cancel', function()
    activeSmeltingTasks[source] = nil
end)

AddEventHandler('playerDropped', function()
    activeSmeltingTasks[source] = nil
end)
