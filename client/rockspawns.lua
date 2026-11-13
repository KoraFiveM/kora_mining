local Settings = {}
local Spots = {}
local Objects = {}
local registered = {}
local Busy = false

-- Mining always uses an animation. Rock settings may choose the animation,
-- but they cannot turn it off.
local DEFAULT_MINING_ANIM = {
    dict = 'amb@world_human_hammering@male@base',
    clip = 'base',
    flag = 49,
}

local function mineRock(name, id)
    if Busy then return end
    local settings = Settings[name] or {}
    Busy = true
    local profile, err = Kora.callback.trigger('kora_mining:mineProfile', name, id)
    if not profile then
        Kora.notify.send({ title = Kora.lang('Ui.mining'), message = err or Kora.lang('Error.cannot_mine_rock'), type = 'error' })
        Busy = false
        return
    end

    local pickingData = settings.pickingData or {}
    local levelBonus = Kora.util.clamp(tonumber(profile.maxLevelSpeedBonus) or 0, 0, 99)
    local miningLevel = tonumber(profile.miningLevel) or 1
    local levelProgress = Kora.util.clamp((miningLevel - 1) / 98, 0, 1)
    local pickaxeBonus = Kora.util.clamp(tonumber(profile.pickaxeSpeedBonus) or 0, 0, 99)
    local totalSpeedBonus = Kora.util.clamp(levelBonus * levelProgress + pickaxeBonus, 0, 95)
    local duration = tonumber(pickingData.time or settings.pickTime) or 5000
    duration = math.max(500, math.floor(duration * (1 - totalSpeedBonus / 100)))

    local ok, completed = pcall(Kora.progressbar.start, {
        label = settings.progressLabel ~= '' and settings.progressLabel or Kora.lang('Ui.mining'),
        duration = duration,
        useWhileDead = false,
        canCancel = true,
        disable = pickingData.disable or { move = true, combat = true, vehicle = true },
        anim = { dict = DEFAULT_MINING_ANIM.dict, clip = DEFAULT_MINING_ANIM.clip, flag = DEFAULT_MINING_ANIM.flag },
    })
    if ok and completed then
        TriggerServerEvent('kora_mining:server:mine', name, id, profile.pickaxeId)
    elseif not ok then
        print(Kora.lang('Ui.kora_mining_mining_progress_failed', tostring(completed)))
    end
    Busy = false
end

local function spawnRock(name, id, spot)
    local settings = Settings[name]
    if not settings or not settings.model then return end
    local object = Kora.entities.create(settings.model, spot.coords, { freeze = true, invincible = true })
    exports.kora_target:addEntity(object, {
        {
            icon = settings.icon or 'fa-solid fa-hammer',
            label = settings.targetLabel or Kora.lang('Error.mine_rock'),
            onSelect = function() mineRock(name, id) end,
            canInteract = function() return not Busy end,
        }
    })
    Objects[name][id] = object
end

local function clearType(name)
    for _, object in pairs(Objects[name] or {}) do
        if DoesEntityExist(object) then DeleteEntity(object) end
    end
    Objects[name] = {}
end

local function buildType(name)
    clearType(name)
    for id, spot in pairs(Spots[name] or {}) do
        if not spot.taken then spawnRock(name, id, spot) end
    end
end

local function registerType(name)
    if registered[name] then return end
    registered[name] = true
    Objects[name] = Objects[name] or {}

    RegisterNetEvent('kora_mining:client:rockTaken', function(rockName, id)
        if rockName ~= name then return end
        local spot = Spots[name] and Spots[name][id]
        if spot then spot.taken = true end
        local object = Objects[name] and Objects[name][id]
        if object and DoesEntityExist(object) then DeleteEntity(object) end
        if Objects[name] then Objects[name][id] = nil end
    end)

    RegisterNetEvent('kora_mining:client:rockRespawned', function(rockName, id)
        if rockName ~= name then return end
        local spot = Spots[name] and Spots[name][id]
        if spot and not Objects[name][id] then
            spot.taken = false
            spawnRock(name, id, spot)
        end
    end)
end

local function initType(name)
    registerType(name)
    local settings = Kora.state.awaitGlobal(name .. 'Data', 30000, 100)
    local spots = Kora.state.awaitGlobal(name, 30000, 100)
    if not settings or not spots then
        print(Kora.lang('Ui.kora_mining_timed_out_waiting', name))
        return
    end
    Settings[name], Spots[name] = settings, spots
    buildType(name)
end

RegisterNetEvent('kora_mining:client:rockspawnsReload', function(name, settings, spots)
    registerType(name)
    Settings[name], Spots[name] = settings, spots
    buildType(name)
end)

RegisterNetEvent('kora_mining:client:rockspawnsRemove', function(name)
    clearType(name)
    Settings[name], Spots[name] = nil, nil
end)

CreateThread(function()
    local types = Kora.state.awaitGlobal('koraMiningRockTypes', 30000, 100)
    if not types then
        print('[kora_mining] timed out waiting for GlobalState.koraMiningRockTypes')
        return
    end
    for _, name in ipairs(types) do
        CreateThread(function() initType(name) end)
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    for name in pairs(Objects) do clearType(name) end
end)
