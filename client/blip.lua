-- Static map blip for the mining area (suggestion thread 1567879565496553522).
-- Settings live in MiningConfig.blip; set enabled = false to turn it off.
--
-- The blip is created through kora_lib's exports, so it belongs to kora_lib: it
-- is gone after kora_lib restarts, and creating it fails while kora_lib's client
-- side is not up yet. Both used to leave the map without a blip (the old code
-- tried once at load). It is now retried until it exists and created again
-- whenever kora_lib starts.
local RETRY_ATTEMPTS = 10
local RETRY_DELAY_MS = 2000

local handle
local creating = false

local function createBlip()
    local blip = MiningConfig.blip
    if type(blip) ~= 'table' or blip.enabled ~= true or not blip.coords then return true end

    local name = blip.name or 'Mine Shaft'
    local ok, created, err = pcall(Kora.blips.create, blip.coords, {
        sprite = blip.sprite,
        color = blip.color,
        scale = blip.scale,
        shortRange = blip.shortRange,
        category = blip.category,
        name = name,
        info = blip.description and {
            title = name,
            rows = {
                { kind = 'wrappedText', value = blip.description },
            },
        } or nil,
    })
    if ok and created then
        handle = created
        return true
    end
    return false, ok and err or created
end

local function ensureBlip()
    if creating then return end
    creating = true
    CreateThread(function()
        local err
        for attempt = 1, RETRY_ATTEMPTS do
            if handle and DoesBlipExist(handle) then break end
            handle = nil
            local done
            done, err = createBlip()
            if done then err = nil break end
            if attempt < RETRY_ATTEMPTS then Wait(RETRY_DELAY_MS) end
        end
        if err then
            print(('^3[kora_mining] map blip was not created: %s^7'):format(tostring(err)))
        end
        creating = false
    end)
end

ensureBlip()

AddEventHandler('onClientResourceStart', function(resource)
    -- A real kora_lib restart removed the blip it created for us (ensureBlip sees
    -- it no longer exists). A late start event with the blip still there is a no-op.
    if resource == 'kora_lib' then ensureBlip() end
end)
