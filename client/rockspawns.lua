local Settings = {}
local Spots = {}
local Objects = {}
local registered = {}
local Busy = false

local MINING = MiningConfig.mining
local ANIM, PROP, DUST = MINING.anim, MINING.prop, MINING.dust
local heldPickaxe = nil

local function waitFor(check, timeout)
    local deadline = GetGameTimer() + (timeout or 3000)
    while not check() do
        if GetGameTimer() > deadline then return false end
        Wait(0)
    end
    return true
end

local function loadAnimDict(dict)
    if HasAnimDictLoaded(dict) then return true end
    RequestAnimDict(dict)
    return waitFor(function() return HasAnimDictLoaded(dict) end, 3000)
end

local function loadPtfx(dict)
    if HasNamedPtfxAssetLoaded(dict) then return true end
    RequestNamedPtfxAsset(dict)
    return waitFor(function() return HasNamedPtfxAssetLoaded(dict) end, 3000)
end

local function faceRock(ped, rockCoords)
    local pos = GetEntityCoords(ped)
    local heading = GetHeadingFromVector_2d(rockCoords.x - pos.x, rockCoords.y - pos.y)
    TaskTurnPedToFaceCoord(ped, rockCoords.x, rockCoords.y, rockCoords.z, 600)
    local deadline = GetGameTimer() + 700
    while GetGameTimer() < deadline do
        local diff = math.abs(((GetEntityHeading(ped) - heading + 180.0) % 360.0) - 180.0)
        if diff < 8.0 then break end
        Wait(25)
    end
    ClearPedTasks(ped)
    SetEntityHeading(ped, heading)
end

local function destroyPickaxe()
    local pickaxe = heldPickaxe
    heldPickaxe = nil
    if pickaxe and DoesEntityExist(pickaxe) then
        DetachEntity(pickaxe, true, true)
        DeleteEntity(pickaxe)
    end
end

local function attachPickaxe(ped)
    destroyPickaxe()
    local model = joaat(PROP.model)
    if not IsModelInCdimage(model) then
        Kora.logging.warn('rocks.prop_missing', 'Pickaxe prop model not found', { model = PROP.model })
        return nil
    end
    RequestModel(model)
    if not waitFor(function() return HasModelLoaded(model) end, 3000) then
        Kora.logging.warn('rocks.prop_timeout', 'Pickaxe prop model failed to load', { model = PROP.model })
        return nil
    end

    local pos = GetEntityCoords(ped)
    local pickaxe = CreateObject(model, pos.x, pos.y, pos.z + 0.2, true, true, false)
    SetModelAsNoLongerNeeded(model)
    if not pickaxe or pickaxe == 0 then return nil end

    local o, r = PROP.offset, PROP.rotation
    AttachEntityToEntity(
        pickaxe, ped, GetPedBoneIndex(ped, PROP.bone),
        o.x, o.y, o.z, r.x, r.y, r.z,
        true, true, false, true, PROP.rotationOrder or 1, true
    )
    DisableCamCollisionForEntity(pickaxe)
    DisableCamCollisionForObject(pickaxe)
    heldPickaxe = pickaxe
    return pickaxe
end

local function startDust(ped)
    local state = { running = true }
    if not DUST.enabled or not loadPtfx(DUST.dict) then return state end
    local swing = math.max(300, math.floor(GetAnimDuration(ANIM.dict, ANIM.clip) * 1000))
    local beforeImpact = math.floor(swing * Kora.util.clamp(DUST.impact, 0, 1))
    local o = DUST.offset
    CreateThread(function()
        Wait(beforeImpact)
        while state.running do
            local at = GetOffsetFromEntityInWorldCoords(ped, o.x, o.y, o.z)
            UseParticleFxAsset(DUST.dict)
            StartNetworkedParticleFxNonLoopedAtCoord(
                DUST.name, at.x, at.y, at.z, 0.0, 0.0, 0.0, DUST.scale, false, false, false
            )
            Wait(swing)
        end
        RemoveNamedPtfxAsset(DUST.dict)
    end)
    return state
end

local function rockCoordsFor(name, id)
    local object = Objects[name] and Objects[name][id]
    if object and DoesEntityExist(object) then return GetEntityCoords(object) end
    local spot = Spots[name] and Spots[name][id]
    return spot and spot.coords or nil
end

local function textOrDefault(value, default)
    if type(value) == 'string' and value ~= '' then return value end
    return default
end

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

    local ped = PlayerPedId()
    local dust
    local ok, completed = pcall(function()
        local rockCoords = rockCoordsFor(name, id)
        if MINING.faceRock and rockCoords then faceRock(ped, rockCoords) end

        local animLoaded = loadAnimDict(ANIM.dict)
        if not animLoaded then
            Kora.logging.warn('rocks.anim_timeout', 'Mining animation failed to load', { dict = ANIM.dict })
        end
        if PROP.enabled then attachPickaxe(ped) end
        dust = startDust(ped)

        return Kora.progressbar.start({
            label = textOrDefault(settings.progressLabel, Kora.lang('Ui.mining')),
            duration = duration,
            useWhileDead = false,
            canCancel = true,
            disable = pickingData.disable or { move = true, combat = true, vehicle = true },
            anim = animLoaded and {
                dict = ANIM.dict, clip = ANIM.clip, flag = ANIM.flag, blendIn = 3.0, blendOut = 3.0,
            } or nil,
        })
    end)

    if dust then dust.running = false end
    destroyPickaxe()
    StopAnimTask(ped, ANIM.dict, ANIM.clip, 1.0)

    if ok and completed then
        TriggerServerEvent('kora_mining:server:mine', name, id, profile.pickaxeId)
    elseif not ok then
        Kora.logging.error('rocks.progress_failed', 'Mining progress failed', { error = tostring(completed) })
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
            label = textOrDefault(settings.targetLabel, Kora.lang('Error.mine_rock')),
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
        Kora.logging.warn('rocks.state_timed_out', 'Timed out waiting for rock spawn state', { state = name })
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
        Kora.logging.warn('rocks.types_timed_out', 'Timed out waiting for GlobalState.koraMiningRockTypes')
        return
    end
    for _, name in ipairs(types) do
        CreateThread(function() initType(name) end)
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    destroyPickaxe()
    for name in pairs(Objects) do clearType(name) end
end)
