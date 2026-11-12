-- Map blips are data: stored in kora_mining_blips, edited in the Mining Creator
-- and drawn on every client by client/blip.lua.
local MAX_BLIPS = 50

local blips = {}
local blipsReady = false

local function fail(message)
    return false, message
end

local isAdmin = MiningUtil.isAdmin

local function list()
    local out = {}
    for _, blip in pairs(blips) do out[#out + 1] = blip end
    table.sort(out, function(a, b) return a.id < b.id end)
    return out
end

local function publishBlips()
    local current = list()
    GlobalState.koraMiningBlips = current
    TriggerClientEvent('kora_mining:blips:reload', -1, current)
end

---Validates raw values (stored or from a client) and returns a clean blip, or nil, error.
local function clean(id, raw)
    if type(raw) ~= 'table' then return nil, Kora.lang('Error.invalid_blip') end
    if type(id) ~= 'string' or not id:match('^[%w_]+$') or #id > 32 then return nil, Kora.lang('Error.invalid_blip_id') end

    local name = type(raw.name) == 'string' and raw.name:match('^%s*(.-)%s*$')
    if not name or name == '' or #name > 48 then return nil, Kora.lang('Error.enter_a_blip_name_up') end

    local description = raw.description
    if description == nil then description = '' end
    if type(description) ~= 'string' or #description > 200 then return nil, Kora.lang('Error.description_must_be_200_characters') end

    local sprite, color, scale = tonumber(raw.sprite), tonumber(raw.color), tonumber(raw.scale)
    if not MiningUtil.inRange(sprite, 0, 900, true) then return nil, Kora.lang('Error.sprite_must_be_a_whole') end
    if not MiningUtil.inRange(color, 0, 85, true) then return nil, Kora.lang('Error.colour_must_be_a_whole') end
    if not MiningUtil.inRange(scale, 0.1, 3.0) then return nil, Kora.lang('Error.size_must_be_between_0') end
    if type(raw.shortRange) ~= 'boolean' then return nil, Kora.lang('Error.short_range_must_be_true') end

    local x, y, z = tonumber(raw.x), tonumber(raw.y), tonumber(raw.z)
    -- NaN fails every comparison, so reject it explicitly before isWorldCoord.
    if not x or not y or not z or x ~= x or y ~= y or z ~= z or not MiningUtil.isWorldCoord(x, y, z) then
        return nil, Kora.lang('Error.blip_coordinates_are_invalid')
    end

    return {
        id = id, name = name, description = description,
        sprite = sprite, color = color, scale = scale, shortRange = raw.shortRange,
        x = x, y = y, z = z,
    }
end

local function persist(blip)
    local ok, err = Kora.sql.update(
        'INSERT INTO `kora_mining_blips` (`id`, `data`) VALUES (?, ?) ON DUPLICATE KEY UPDATE `data`=VALUES(`data`)',
        { blip.id, json.encode({
            name = blip.name, description = blip.description, sprite = blip.sprite, color = blip.color,
            scale = blip.scale, shortRange = blip.shortRange, x = blip.x, y = blip.y, z = blip.z,
        }) }
    )
    if not ok then return false, err end
    return true
end

local function slug(name)
    local base = name:lower():gsub('[^%w]+', '_'):gsub('^_+', ''):gsub('_+$', '')
    if base == '' then base = 'blip' end
    base = base:sub(1, 26)
    local id, n = base, 1
    while blips[id] do
        n = n + 1
        id = ('%s_%d'):format(base, n)
    end
    return id
end

CreateThread(function()
    if not KoraMining.schemaReady() then return end
    local rows = Kora.sql.query('SELECT `id`, `data` FROM `kora_mining_blips`') or {}
    for _, row in ipairs(rows) do
        local blip, err = clean(row.id, MiningUtil.decodeJson(row.data, nil))
        if blip then
            blips[blip.id] = blip
        else
            print(('^3[kora_mining] skipped blip %s: %s^7'):format(tostring(row.id), tostring(err)))
        end
    end
    blipsReady = true
    publishBlips()
end)

Kora.callback.register('kora_mining:blips:creator:get', function(source)
    if not isAdmin(source) then return fail(Kora.lang('Error.admin_permission_required')) end
    if not blipsReady then return fail(Kora.lang('Error.blips_are_still_loading')) end
    return list()
end)

-- `values` holds the form fields plus x/y/z; `id` is nil when creating.
Kora.callback.register('kora_mining:blips:creator:save', function(source, id, values)
    if not isAdmin(source) then return fail(Kora.lang('Error.admin_permission_required')) end
    if not blipsReady then return fail(Kora.lang('Error.blips_are_still_loading')) end
    if type(values) ~= 'table' then return fail(Kora.lang('Error.invalid_blip')) end

    if id ~= nil then
        if type(id) ~= 'string' or not blips[id] then return fail(Kora.lang('Error.blip_not_found')) end
    else
        local count = 0
        for _ in pairs(blips) do count = count + 1 end
        if count >= MAX_BLIPS then return fail(Kora.lang('Error.blip_limit', MAX_BLIPS)) end
        if type(values.name) ~= 'string' then return fail(Kora.lang('Error.enter_a_blip_name_up')) end
        id = slug(values.name)
    end

    local blip, err = clean(id, values)
    if not blip then return fail(err) end

    local saved, saveErr = persist(blip)
    if not saved then return fail(saveErr or Kora.lang('Error.could_not_save_blip')) end
    blips[id] = blip
    publishBlips()
    return list()
end)

Kora.callback.register('kora_mining:blips:creator:delete', function(source, id)
    if not isAdmin(source) then return fail(Kora.lang('Error.admin_permission_required')) end
    if not blipsReady then return fail(Kora.lang('Error.blips_are_still_loading')) end
    if type(id) ~= 'string' or not blips[id] then return fail(Kora.lang('Error.blip_not_found')) end

    local ok, err = Kora.sql.update('DELETE FROM `kora_mining_blips` WHERE `id` = ?', { id })
    if not ok then return fail(err or Kora.lang('Error.could_not_delete_blip')) end
    blips[id] = nil
    publishBlips()
    return list()
end)
