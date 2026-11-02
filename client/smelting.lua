local APP_ID = 'kora_mining:smelting'

local stations = {}
local builtStations = {}
local selectedRecipe
local isSmelting = false

local CATEGORIES = MiningConfig.smeltingCategories

local function notify(message)
    Kora.notify.send({
        title = 'Smelting',
        message = message or 'Smelting failed.',
        type = 'error',
    })
end

local function createTargetZone(coords, options)
    return exports.kora_target:addBoxZone({
        coords = coords,
        size = vector3(2, 2, 2),
        rotation = 0,
        options = options,
    })
end

local function createTargetObject(model, coords, options)
    local entity = Kora.entities.create(model, coords, { freeze = true, invincible = true })
    if not entity then return nil end

    SetEntityHeading(entity, coords.w or 0.0)
    exports.kora_target:addEntity(entity, options)
    return entity
end

local function clearStation(stationId)
    local built = builtStations[stationId]
    if not built then
        stations[stationId] = nil
        return
    end

    for _, zone in ipairs(built.zones) do
        pcall(function()
            exports.kora_target:removeZone(zone)
        end)
    end

    for _, entity in ipairs(built.objects) do
        pcall(function()
            Kora.entities.remove(entity)
        end)
    end

    builtStations[stationId] = nil
    stations[stationId] = nil
end

local function buildRecipeCards(recipes)
    local recipesByCategory = {}
    local blocks = {}

    for _, category in ipairs(CATEGORIES) do
        recipesByCategory[category.value] = {}
    end

    for _, recipe in ipairs(recipes) do
        local ingredientLabels = {}
        local canSmelt = not recipe.locked and recipe.has

        for _, ingredient in ipairs(recipe.inputs) do
            ingredientLabels[#ingredientLabels + 1] = ('%dx %s'):format(ingredient.amount, ingredient.label)
            if not ingredient.has then canSmelt = false end
        end

        local card = {
            id = recipe.id,
            label = recipe.label,
            description = ('Makes %dx %s'):format(recipe.outputAmount, recipe.output),
            image = recipe.outputImage,
            metadata = {
                { label = 'Needs', value = table.concat(ingredientLabels, ', ') },
                {
                    label = 'Smelting',
                    value = ('Level %d · %d XP'):format(recipe.level, recipe.xp),
                    tone = recipe.locked and 'destructive' or nil,
                },
            },
            actions = canSmelt and {
                { id = 'smelt:' .. recipe.id, label = 'Smelt', icon = 'Flame', variant = 'primary' },
            } or {},
        }

        local categoryRecipes = recipesByCategory[recipe.category] or recipesByCategory.materials
        categoryRecipes[#categoryRecipes + 1] = card
    end

    for _, category in ipairs(CATEGORIES) do
        blocks[#blocks + 1] = {
            type = 'list',
            id = 'recipes-' .. category.value,
            layout = 'cards',
            columns = 2,
            title = category.label,
            items = recipesByCategory[category.value],
            empty = ('No %s at this station.'):format(category.label:lower()),
        }
    end

    return blocks
end

local function openSmeltingMenu(stationId, locationIndex)
    if isSmelting then return end

    local recipes, err = Kora.callback.trigger('kora_mining:smelting:menu', stationId, locationIndex)
    if not recipes then
        notify(err)
        return
    end

    while true do
        selectedRecipe = nil

        Kora.nui.updateApp(APP_ID, {
            navigation = {
                {
                    id = 'recipes',
                    label = 'Smelting',
                    icon = 'Flame',
                    content = {
                        title = 'Smelting',
                        description = 'Choose a recipe to smelt.',
                        blocks = buildRecipeCards(recipes),
                    },
                },
            },
        })

        Kora.nui.openApp(APP_ID, { viewId = 'recipes' })
        if not selectedRecipe then break end

        local started, startError = Kora.callback.trigger(
            'kora_mining:smelting:begin',
            stationId,
            locationIndex,
            selectedRecipe
        )

        if not started then
            notify(startError)
        else
            isSmelting = true

            local completed = Kora.progressbar.start({
                label = started.label,
                duration = started.duration,
                disable = { move = true, combat = true, vehicle = true },
                anim = { dict = 'mp_arresting', clip = 'a_uncuff', flag = 17 },
            })

            if not completed then
                TriggerServerEvent('kora_mining:smelting:cancel')
            else
                local success, finishError = Kora.callback.trigger('kora_mining:smelting:finish')
                if not success then notify(finishError) end
            end

            isSmelting = false
            recipes, err = Kora.callback.trigger('kora_mining:smelting:menu', stationId, locationIndex)
            if not recipes then
                notify(err)
                break
            end
        end
    end
end

Kora.nui.registerApp({
    id = APP_ID,
    title = 'Smelting',
    icon = 'Flame',
    layout = 'compact',
    placement = 'right',
    width = 680,
    height = 720,
    navigation = {
        {
            id = 'recipes',
            label = 'Smelting',
            icon = 'Flame',
            content = { title = 'Smelting', blocks = {} },
        },
    },
    onAction = function(action)
        local recipeId = action:match('^smelt:(.+)$')
        if not recipeId then return {} end

        selectedRecipe = recipeId
        return { close = true }
    end,
})

local function buildStation(stationId, station)
    clearStation(stationId)
    stations[stationId] = station

    if type(station) ~= 'table' or type(station.locations) ~= 'table' then return end

    local built = { zones = {}, objects = {} }
    builtStations[stationId] = built

    for locationIndex, location in ipairs(station.locations) do
        local coords = location.coords
        if coords then
            local options = {
                {
                    label = station.targetLabel or 'Smelt',
                    icon = station.targetIcon or 'fa-solid fa-fire',
                    onSelect = function()
                        openSmeltingMenu(stationId, locationIndex)
                    end,
                    canInteract = function()
                        return not isSmelting
                    end,
                },
            }

            if location.object then
                local entity = createTargetObject(
                    location.object,
                    vector4(coords.x, coords.y, coords.z, coords.w or 0.0),
                    options
                )
                if entity then built.objects[#built.objects + 1] = entity end
            else
                local zone = createTargetZone(vector3(coords.x, coords.y, coords.z), options)
                if zone then built.zones[#built.zones + 1] = zone end
            end
        end
    end
end

RegisterNetEvent('kora_mining:smelting:stationReload', function(stationId, station)
    buildStation(stationId, station)
end)

CreateThread(function()
    local data = Kora.state.awaitGlobal('koraMiningSmelting', 30000, 100)
    if not data then
        print('[kora_mining] timed out waiting for smelting stations')
        return
    end

    for stationId, station in pairs(data.stations or {}) do
        buildStation(stationId, station)
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    local stationIds = {}
    for stationId in pairs(builtStations) do
        stationIds[#stationIds + 1] = stationId
    end

    for _, stationId in ipairs(stationIds) do
        clearStation(stationId)
    end
end)
