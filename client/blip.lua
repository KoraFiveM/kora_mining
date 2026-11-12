-- Map blips drawn from the database (kora_mining_blips), edited in the Mining Creator.
--
-- Blips are created through kora_lib's exports, so they belong to kora_lib: they
-- are gone after kora_lib restarts, and creating them fails while kora_lib's client
-- side is not up yet. syncBlips is retried until every blip exists and runs again
-- whenever kora_lib starts or the server publishes a new list.
local RETRY_ATTEMPTS = 10
local RETRY_DELAY_MS = 2000

local handles = {}
local desired = {}
local syncing, resync = false, false

local function removeAll()
    for id, handle in pairs(handles) do
        if handle and DoesBlipExist(handle) then pcall(Kora.blips.remove, handle) end
        handles[id] = nil
    end
end

-- Creates the missing blips; returns the last error if any failed.
local function createMissing()
    local lastErr
    for _, blip in ipairs(desired) do
        local handle = handles[blip.id]
        if not (handle and DoesBlipExist(handle)) then
            handles[blip.id] = nil
            local description = blip.description
            local ok, created, err = pcall(Kora.blips.create, vec3(blip.x, blip.y, blip.z), {
                sprite = blip.sprite,
                color = blip.color,
                scale = blip.scale,
                shortRange = blip.shortRange,
                name = blip.name,
                info = description and description ~= '' and {
                    title = blip.name,
                    rows = { { kind = 'wrappedText', value = description } },
                } or nil,
            })
            if ok and created then
                handles[blip.id] = created
            else
                lastErr = ('%s: %s'):format(blip.name, tostring(ok and err or created))
            end
        end
    end
    return lastErr
end

local function syncBlips(list, fresh)
    if type(list) == 'table' then
        desired = list
        fresh = true
    end
    if syncing then
        resync = resync or fresh
        return
    end
    syncing = true
    CreateThread(function()
        repeat
            resync = false
            if fresh then removeAll() end
            fresh = false
            local err
            for attempt = 1, RETRY_ATTEMPTS do
                err = createMissing()
                if not err or resync then break end
                if attempt < RETRY_ATTEMPTS then Wait(RETRY_DELAY_MS) end
            end
            if err and not resync then
                print(('^3[kora_mining] map blip was not created: %s^7'):format(err))
            end
            fresh = resync
        until not resync
        syncing = false
    end)
end

RegisterNetEvent('kora_mining:blips:reload', function(list)
    if type(list) == 'table' then syncBlips(list) end
end)

CreateThread(function()
    local list = Kora.state.awaitGlobal('koraMiningBlips', 30000, 100)
    if not list then
        print('[kora_mining] timed out waiting for map blips')
        return
    end
    syncBlips(list)
end)

AddEventHandler('onClientResourceStart', function(resource)
    -- A real kora_lib restart removed our blips; createMissing sees they no longer
    -- exist and recreates only those. A late start event with blips intact is a no-op.
    if resource == 'kora_lib' then syncBlips() end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then removeAll() end
end)
