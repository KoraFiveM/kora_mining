-- Small server-only helpers shared by main.lua, pickaxe_shop.lua and
-- smelting.lua, which each used to carry their own copy of these.
MiningUtil = MiningUtil or {}

---Raw `command` ACE check used to gate the mining creator and admin-only
---server exports.
function MiningUtil.isAdmin(source)
    return tonumber(source) ~= nil and tonumber(source) > 0 and IsPlayerAceAllowed(source, 'command')
end

---Decodes `raw` as JSON, returning `defaultValue` verbatim (including nil)
---for anything that isn't a string or doesn't decode to a table.
function MiningUtil.decodeJson(raw, defaultValue)
    if type(raw) ~= 'string' then return defaultValue end
    local value = Kora.util.decodeJson(raw)
    if type(value) == 'table' then return value end
    return defaultValue
end

---The qb-core/kora_core shared item registry, whichever is present.
function MiningUtil.getSharedItems()
    local ok, items = pcall(function() return exports['qb-core']:GetShared('Items') end)
    if not ok or type(items) ~= 'table' then
        ok, items = pcall(function() return exports.kora_core:getShared('items') end)
    end
    return ok and type(items) == 'table' and items or {}
end

---Whether `x`, `y`, `z` are all finite and within a sane in-world range.
function MiningUtil.isWorldCoord(x, y, z)
    return x ~= nil and y ~= nil and z ~= nil
        and math.abs(x) <= 10000 and math.abs(y) <= 10000 and math.abs(z) <= 10000
end

---Whether `value` is present and within `[min, max]`, optionally requiring a
---whole number. `value` is expected to already be `tonumber`'d by the caller.
function MiningUtil.inRange(value, min, max, wholeNumber)
    if not value then return false end
    if wholeNumber and value % 1 ~= 0 then return false end
    return value >= min and value <= max
end
