local PICKAXES = MiningConfig.pickaxes
local ROCK_CATEGORIES = MiningConfig.rockCategories

local function fail(message) return false, message end

local function isRockCategory(category)
    for _, option in ipairs(ROCK_CATEGORIES) do
        if option.value == category then return true end
    end

    return false
end

local isAdmin = MiningUtil.isAdmin
local allItems = MiningUtil.getSharedItems

local function itemExists(name)
    return type(name) == 'string' and name ~= '' and type(allItems()[name]) == 'table'
end

local function itemOptions()
    local items = allItems()
    local options = {}
    for name, definition in pairs(items) do
        if type(name) == 'string' and type(definition) == 'table' then
            local image = type(definition.image) == 'string' and definition.image ~= ''
                and ('nui://kora_inventory/images/' .. definition.image) or nil
            options[#options + 1] = { value = name, label = tostring(definition.label or name) .. ' (' .. name .. ')', image = image }
        end
    end
    table.sort(options, function(a, b) return a.label:lower() < b.label:lower() end)
    return options
end

local function decode(raw) return MiningUtil.decodeJson(raw, {}) end

local function readRock(row)
    local data = decode(row.data)
    local locations = decode(row.locations)
    if not isRockCategory(data.category) then
        data.category = 'resources'
    end
    if type(data.pickaxes) ~= 'table' or #data.pickaxes > 0 then data.pickaxes = {} end
    for _, pick in ipairs(PICKAXES) do
        local setting = data.pickaxes[pick]
        if type(setting) ~= 'table' then
            data.pickaxes[pick] = { speedBonus = 0, enabled = true }
        else
            setting.speedBonus = tonumber(setting.speedBonus) or 0
            setting.enabled = setting.enabled ~= false
        end
    end
    return {
        id = row.id, data = data, locations = locations,
        count = #locations,
    }
end

local function allRocks()
    local rows = Kora.sql.query('SELECT `id`, `data`, `locations` FROM `kora_mining_rockspawns` ORDER BY `id`') or {}
    local result = {}
    for _, row in ipairs(rows) do result[#result + 1] = readRock(row) end
    return result
end

local function defaultPickaxeSettings()
    local result = {}
    for _, pick in ipairs(PICKAXES) do result[pick.id] = { speedBonus = 0, enabled = true } end
    return result
end

local rockspawns, published = {}, {}

local function rockLocations(raw)
    local result = {}
    for _, spot in ipairs(decode(raw)) do
        local c = type(spot) == 'table' and spot.coords
        local x, y, z = c and tonumber(c.x), c and tonumber(c.y), c and tonumber(c.z)
        if x and y and z then result[#result + 1] = { coords = vec3(x, y, z), taken = false } end
    end
    return result
end

local function rockStateKey(id, isData)
    return id .. (isData and 'Data' or '')
end

local function refreshRockspawns()
    rockspawns = {}
    local rows = Kora.sql.query('SELECT `id`, `data`, `locations` FROM `kora_mining_rockspawns` ORDER BY `id`') or {}
    for _, row in ipairs(rows) do
        local data = decode(row.data)
        rockspawns[row.id] = { data = data, locations = rockLocations(row.locations) }
    end

    for id in pairs(published) do
        if not rockspawns[id] then
            GlobalState[rockStateKey(id)] = nil
            GlobalState[rockStateKey(id, true)] = nil
            published[id] = nil
            TriggerClientEvent('kora_mining:client:rockspawnsRemove', -1, id)
        end
    end

    local types = {}
    for id, rock in pairs(rockspawns) do
        GlobalState[rockStateKey(id)] = rock.locations
        GlobalState[rockStateKey(id, true)] = rock.data
        published[id] = true
        types[#types + 1] = id
    end
    table.sort(types)
    GlobalState.koraMiningRockTypes = types
end

local function reloadRockspawn(id)
    refreshRockspawns()
    local rock = rockspawns[id]
    if rock then
        TriggerClientEvent('kora_mining:client:rockspawnsReload', -1, id, rock.data, rock.locations)
    else
        TriggerClientEvent('kora_mining:client:rockspawnsRemove', -1, id)
    end
end

local function register(name, fn)
    Kora.callback.register(name, function(src, ...)
        if not isAdmin(src) then return fail('Admin permission required.') end
        return fn(src, ...)
    end)
end

local function cleanId(value)
    if type(value) ~= 'string' then return nil end
    value = value:match('^%s*(.-)%s*$')
    if #value < 1 or #value > 32 or not value:match('^%a[%w_]*$') then return nil end
    return value
end

local function cleanData(data)
    if type(data) ~= 'table' then return nil, 'Invalid rock settings.' end
    local model = type(data.model) == 'string' and data.model:match('^%s*(.-)%s*$')
    local item = type(data.item) == 'string' and data.item:match('^%s*(.-)%s*$')
    local category = data.category
    if not isRockCategory(category) then
        return nil, 'Choose Resources, Gemstones, or Crystals.'
    end
    if not model or model == '' or #model > 64 or not model:match('^[%w_%-%.]+$') then return nil, 'Enter a valid rock prop model.' end
    if not itemExists(item) then return nil, 'The reward item does not exist.' end
    local maxGive, respawnTime = tonumber(data.maxGive), tonumber(data.respawnTime)
    local pickTime = tonumber(data.pickTime)
    local level = tonumber(data.levelRequired)
    local xpPerMine = tonumber(data.xpPerMine) or 0
    local maxLevelSpeedBonus = tonumber(data.maxLevelSpeedBonus) or 0
    if not MiningUtil.inRange(maxGive, 1, 100, true) then return nil, 'Max give must be from 1 to 100.' end
    if not MiningUtil.inRange(respawnTime, 1, 3600, false) then return nil, 'Respawn time must be from 1 to 3600 seconds.' end
    if not MiningUtil.inRange(pickTime, 500, 60000, true) then return nil, 'Mining time must be from 500 to 60000 ms.' end
    if not MiningUtil.inRange(level, 1, 99, true) then return nil, 'Mining level must be from 1 to 99.' end
    if not MiningUtil.inRange(xpPerMine, 0, 10000, true) then return nil, 'Mining XP per mine must be from 0 to 10000.' end
    if not MiningUtil.inRange(maxLevelSpeedBonus, 0, 99, true) then return nil, 'Max Mining level speed bonus must be from 0% to 99%.' end
    local pickaxes, pickaxeInput = {}, type(data.pickaxes) == 'table' and data.pickaxes or {}
    for _, pick in ipairs(PICKAXES) do
        local setting = pickaxeInput[pick.id]
        if type(setting) ~= 'table' then setting = {} end
        local bonus = tonumber(setting.speedBonus) or 0
        if not MiningUtil.inRange(bonus, 0, 99, true) then return nil, ('%s speed bonus must be from 0%% to 99%%.'):format(pick.name) end
        pickaxes[pick.id] = { speedBonus = bonus, enabled = setting.enabled ~= false }
    end
    local locations = {}
    if type(data.locations) == 'table' then
        for _, spot in ipairs(data.locations) do
            local c = type(spot) == 'table' and spot.coords
            local x, y, z = c and tonumber(c.x), c and tonumber(c.y), c and tonumber(c.z)
            if MiningUtil.isWorldCoord(x, y, z) then
                locations[#locations + 1] = { coords = { x = x, y = y, z = z } }
            end
            if #locations >= 200 then break end
        end
    end
    return {
        category = category, model = model, item = item, maxGive = maxGive, respawnTime = respawnTime,
        pickTime = pickTime, levelRequired = level, xpPerMine = xpPerMine,
        maxLevelSpeedBonus = maxLevelSpeedBonus, pickaxes = pickaxes,
        icon = type(data.icon) == 'string' and data.icon:sub(1, 64) or '',
        targetLabel = type(data.targetLabel) == 'string' and data.targetLabel:sub(1, 64) or '',
        progressLabel = type(data.progressLabel) == 'string' and data.progressLabel:sub(1, 64) or '',
        locations = locations,
        pickingData = { time = pickTime, disable = { move = true, combat = true, vehicle = true } },
    }
end

register('kora_mining:creator:list', function() return allRocks() end)
register('kora_mining:creator:item-options', function() return itemOptions() end)
register('kora_mining:creator:pickaxes:save', function(_, rockId, pickId, input)
    local known = false
    for _, pick in ipairs(PICKAXES) do if pick.id == pickId then known = true; break end end
    rockId = cleanId(rockId)
    local row = known and rockId and Kora.sql.query(
        'SELECT `data`, `locations` FROM `kora_mining_rockspawns` WHERE `id` = ? LIMIT 1', { rockId }) or nil
    if not (row and row[1] and type(input) == 'table') then return fail('Unknown rockspawn or pickaxe.') end
    local data = decode(row[1].data)
    if type(data.pickaxes) ~= 'table' or #data.pickaxes > 0 then data.pickaxes = defaultPickaxeSettings() end
    local bonus = tonumber(input.speedBonus)
    if not bonus or bonus % 1 ~= 0 or bonus < 0 or bonus > 99 then return fail('Speed bonus must be from 0% to 99%.') end
    data.pickaxes[pickId] = { speedBonus = bonus, enabled = input.enabled ~= false }
    local ok, err = Kora.sql.update('UPDATE `kora_mining_rockspawns` SET `data` = ? WHERE `id` = ?', { json.encode(data), rockId })
    if not ok then return fail(err or 'Could not save pickaxe for this rock.') end
    reloadRockspawn(rockId)
    return readRock({ id = rockId, data = json.encode(data), locations = row[1].locations })
end)
register('kora_mining:creator:create', function(_, id)
    id = cleanId(id)
    if not id then return fail('Use a name starting with a letter, with letters, numbers and underscores.') end
    local empty = { category = 'resources', model = '', item = '', maxGive = 2, respawnTime = 60, pickTime = 5000, levelRequired = 1,
        xpPerMine = 0, maxLevelSpeedBonus = 0, pickaxes = defaultPickaxeSettings(), icon = 'fa-solid fa-hammer', targetLabel = 'Mine rock',
        progressLabel = 'Mining', disabled = false }
    local ok, err = Kora.sql.update('INSERT INTO `kora_mining_rockspawns` (`id`, `data`, `locations`) VALUES (?, ?, ?)', { id, json.encode(empty), '[]' })
    if not ok then return fail(err or 'Could not create rockspawn.') end
    reloadRockspawn(id)
    return { id = id, data = empty, locations = {} }
end)

local function isNear(src, coords, radius)
    return coords ~= nil and Kora.distance.player(src, coords, radius or 3.0)
end

local function getMiningLevel(src)
    local skill = exports.kora_skills:getRep(src, 'mining')
    return type(skill) == 'table' and tonumber(skill.level) or nil
end

local function findPickaxe(src, rock, miningLevel, requestedPickaxe)
    local configs = rock.data.pickaxes or {}
    for index = #PICKAXES, 1, -1 do
        local pick = PICKAXES[index]
        local setting = configs[pick.id] or {}
        if (not requestedPickaxe or requestedPickaxe == pick.id)
            and setting.enabled ~= false and miningLevel >= pick.level
            and exports.kora_inventory:GetItemCount(src, pick.item) > 0 then
            return pick, setting
        end
    end
end

local function mineProfile(src, rockId, spotId)
    if type(rockId) ~= 'string' or type(spotId) ~= 'number' or spotId % 1 ~= 0 then return end
    local rock = rockspawns[rockId]
    local spot = rock and rock.locations[spotId]
    if not spot or spot.taken then return false, 'This rock is unavailable.' end
    if not isNear(src, spot.coords, 3.0) then return false, 'Move closer to the rock.' end
    local miningLevel = getMiningLevel(src)
    local requiredLevel = tonumber(rock.data.levelRequired) or 1
    if not miningLevel or miningLevel < requiredLevel then
        return false, ('You need Mining level %d to mine this rock.'):format(requiredLevel)
    end
    local pick, setting = findPickaxe(src, rock, miningLevel)
    if not pick then return false, 'You need an enabled pickaxe that you can use to mine this rock.' end
    return {
        rock = rock, spot = spot, miningLevel = miningLevel,
        pickaxeId = pick.id, pickaxeLevel = pick.level,
        pickaxeSpeedBonus = tonumber(setting.speedBonus) or 0,
        maxLevelSpeedBonus = tonumber(rock.data.maxLevelSpeedBonus) or 0,
    }
end

Kora.callback.register('kora_mining:mineProfile', function(src, rockId, spotId)
    return mineProfile(src, rockId, spotId)
end)

RegisterNetEvent('kora_mining:server:mine', function(rockId, spotId, pickaxeId)
    local src = source
    local profile, err = mineProfile(src, rockId, spotId)
    if not profile or profile.pickaxeId ~= pickaxeId then
        if err then Kora.notify.send(src, { title = 'Mining', message = err, type = 'error' }) end
        return
    end
    local rock, spot = profile.rock, profile.spot

    spot.taken = true
    GlobalState[rockId] = rock.locations
    TriggerClientEvent('kora_mining:client:rockTaken', -1, rockId, spotId)
    CreateThread(function()
        Wait((tonumber(rock.data.respawnTime) or 60) * 1000)
        if rockspawns[rockId] ~= rock then return end
        spot.taken = false
        GlobalState[rockId] = rock.locations
        TriggerClientEvent('kora_mining:client:rockRespawned', -1, rockId, spotId)
    end)

    exports.kora_inventory:addItem(src, rock.data.item, math.random(1, tonumber(rock.data.maxGive) or 1))
    local xp = tonumber(rock.data.xpPerMine) or 0
    if xp > 0 then exports.kora_skills:addRep(src, 'mining', xp) end
end)
register('kora_mining:creator:save', function(_, id, raw)
    id = cleanId(id)
    if not id then return fail('Unknown rockspawn.') end
    local data, err = cleanData(raw)
    if not data then return fail(err) end
    local ok, saveErr = Kora.sql.update('UPDATE `kora_mining_rockspawns` SET `data` = ?, `locations` = ? WHERE `id` = ?',
        { json.encode(data), json.encode(data.locations), id })
    if not ok then return fail(saveErr or 'Could not save rockspawn.') end
    reloadRockspawn(id)
    data.locations = nil
    return { id = id, data = data, locations = raw.locations or {} }
end)
register('kora_mining:creator:delete', function(_, id)
    id = cleanId(id)
    if not id then return fail('Unknown rockspawn.') end
    local ok, err = Kora.sql.update('DELETE FROM `kora_mining_rockspawns` WHERE `id` = ?', { id })
    if not ok then return fail(err or 'Could not delete rockspawn.') end
    reloadRockspawn(id)
    return true
end)

CreateThread(function()
    if not KoraMining.schemaReady() then return end
    refreshRockspawns()
end)

RegisterCommand('miningCreator', function(src)
    if not isAdmin(src) then Kora.notify.send(src, { title = 'Mining Creator', message = 'Admin permission required.', type = 'error' }); return end
    TriggerClientEvent('kora_mining:creator:open', src)
end, false)

