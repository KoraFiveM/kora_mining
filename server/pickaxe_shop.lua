-- The shop catalog stays in one place so every vendor sells the same tools.
local PICKAXES_FOR_SALE = MiningConfig.pickaxes

local shopConfig = {
    model = 's_m_m_dockwork_01',
    locations = {},
    prices = {},
}

for _, pickaxe in ipairs(PICKAXES_FOR_SALE) do
    shopConfig.prices[pickaxe.item] = pickaxe.price
end

local shopReady = false
local pendingPurchases = {}

local function fail(message)
    return false, message
end

local isAdmin = MiningUtil.isAdmin
local function decode(raw) return MiningUtil.decodeJson(raw, {}) end

local function publishShop()
    GlobalState.koraMiningPickaxeShop = shopConfig
    TriggerClientEvent('kora_mining:pickaxeShop:reload', -1, shopConfig)
end

local function getMiningLevel(source)
    local ok, skill = pcall(function()
        return exports.kora_skills:getRep(source, 'mining')
    end)

    if not ok or type(skill) ~= 'table' then return 0 end
    return tonumber(skill.level) or 0
end

local function getItemDefinition(itemName)
    return MiningUtil.getSharedItems()[itemName]
end

local function isAtVendor(source)
    local found = Kora.distance.playerNearAny(source, shopConfig.locations, {
        radius = 5.0,
        coordsOf = function(location) return location.coords or location end,
    })
    return found
end

local function getCatalog(source)
    if not shopReady then
        return fail('Pickaxe shop is still loading.')
    end

    if not isAtVendor(source) then
        return fail('You are too far from the pickaxe shop.')
    end

    local miningLevel = getMiningLevel(source)
    local items = {}

    for _, pickaxe in ipairs(PICKAXES_FOR_SALE) do
        local definition = getItemDefinition(pickaxe.item)
        local owned = (exports.kora_inventory:GetItemCount(source, pickaxe.item) or 0) > 0
        local image

        if definition and type(definition.image) == 'string' and definition.image ~= '' then
            image = 'nui://kora_inventory/images/' .. definition.image
        end

        items[#items + 1] = {
            item = pickaxe.item,
            label = definition and definition.label or pickaxe.name,
            image = image,
            level = pickaxe.level,
            price = tonumber(shopConfig.prices[pickaxe.item]) or pickaxe.price,
            unlocked = miningLevel >= pickaxe.level,
            owned = owned,
        }
    end

    return { items = items, level = miningLevel }
end

local function saveShop()
    local ok, err = Kora.sql.update(
        'INSERT INTO `kora_mining_pickaxe_shop` (`id`, `data`) VALUES (?, ?) ON DUPLICATE KEY UPDATE `data`=VALUES(`data`)',
        { 'main', json.encode(shopConfig) }
    )
    if not ok then return false, err end

    publishShop()
    return true
end

local function loadShop()
    local rows = Kora.sql.query(
        'SELECT `data` FROM `kora_mining_pickaxe_shop` WHERE `id` = ? LIMIT 1',
        { 'main' }
    ) or {}

    if not rows[1] then
        shopReady = true
        publishShop()
        return
    end

    local stored = decode(rows[1].data)
    if type(stored.model) == 'string' and stored.model:match('^[%w_%-]+$') then
        shopConfig.model = stored.model
    end

    for _, pickaxe in ipairs(PICKAXES_FOR_SALE) do
        local price = type(stored.prices) == 'table' and tonumber(stored.prices[pickaxe.item])
        if price and price >= 0 and price <= 100000000 and price % 1 == 0 then
            shopConfig.prices[pickaxe.item] = price
        end
    end

    -- Accept the old single-coordinate format so existing vendor data survives upgrades.
    if type(stored.locations) == 'table' then
        for _, location in ipairs(stored.locations) do
            local coords = location.coords or location
            if type(coords) == 'table' and tonumber(coords.x) and tonumber(coords.y) and tonumber(coords.z) then
                shopConfig.locations[#shopConfig.locations + 1] = {
                    coords = {
                        x = tonumber(coords.x),
                        y = tonumber(coords.y),
                        z = tonumber(coords.z),
                        w = tonumber(coords.w) or 0.0,
                    },
                }
            end
        end
    elseif type(stored.coords) == 'table' then
        local coords = stored.coords
        if tonumber(coords.x) and tonumber(coords.y) and tonumber(coords.z) then
            shopConfig.locations[1] = {
                coords = {
                    x = tonumber(coords.x),
                    y = tonumber(coords.y),
                    z = tonumber(coords.z),
                    w = tonumber(coords.w) or 0.0,
                },
            }
        end
    end

    shopReady = true
    publishShop()
end

CreateThread(function()
    if not KoraMining.schemaReady() then return end
    loadShop()
end)

Kora.callback.register('kora_mining:pickaxeShop:get', function(source)
    return getCatalog(source)
end)

Kora.callback.register('kora_mining:pickaxeShop:buy', function(source, itemName)
    if pendingPurchases[source] then
        return fail('Your purchase is already processing.')
    end

    pendingPurchases[source] = true

    local function finishPurchase(result, err)
        pendingPurchases[source] = nil
        return result, err
    end

    if not shopReady or not isAtVendor(source) then
        return finishPurchase(false, 'You are too far from the pickaxe shop.')
    end

    local pickaxe
    for _, entry in ipairs(PICKAXES_FOR_SALE) do
        if entry.item == itemName then
            pickaxe = entry
            break
        end
    end

    if not pickaxe then
        return finishPurchase(false, 'That pickaxe is not for sale.')
    end

    if getMiningLevel(source) < pickaxe.level then
        return finishPurchase(false, ('Mining level %d is required.'):format(pickaxe.level))
    end

    local owned = exports.kora_inventory:GetItemCount(source, pickaxe.item) or 0
    if owned > 0 then
        return finishPurchase(false, 'You already own this pickaxe.')
    end

    if not getItemDefinition(pickaxe.item) then
        return finishPurchase(false, 'This pickaxe item is not configured.')
    end

    local price = tonumber(shopConfig.prices[pickaxe.item]) or pickaxe.price
    if not exports.kora_core:removeMoney(source, 'cash', price, 'mining-pickaxe-purchase') then
        return finishPurchase(false, 'You do not have enough cash.')
    end

    local added, addError = exports.kora_inventory:addItem(source, pickaxe.item, 1)
    if not added then
        local refunded, refundError = exports.kora_core:addMoney(
            source,
            'cash',
            price,
            'mining-pickaxe-refund',
            true
        )
        if not refunded then
            print(('[kora_mining] pickaxe refund failed for player %s: %s')
                :format(source, tostring(refundError)))
        end

        return finishPurchase(false, addError or 'Your inventory could not fit the pickaxe; your cash was refunded.')
    end

    return finishPurchase(getCatalog(source))
end)

Kora.callback.register('kora_mining:pickaxeShop:creator:get', function(source)
    if not isAdmin(source) then return fail('Admin permission required.') end
    if not shopReady then return fail('Pickaxe shop is still loading.') end

    return shopConfig
end)

Kora.callback.register('kora_mining:pickaxeShop:creator:save', function(source, model, locations)
    if not isAdmin(source) then return fail('Admin permission required.') end
    if not shopReady then return fail('Pickaxe shop is still loading.') end
    if type(model) ~= 'string' or #model > 64 or not model:match('^[%w_%-]+$') then
        return fail('Enter a valid ped model.')
    end
    if type(locations) ~= 'table' or #locations > 100 then
        return fail('Provide up to 100 pickaxe vendor locations.')
    end

    local cleanLocations = {}
    for _, location in ipairs(locations) do
        local coords = type(location) == 'table' and (location.coords or location)
        local x = type(coords) == 'table' and tonumber(coords.x)
        local y = type(coords) == 'table' and tonumber(coords.y)
        local z = type(coords) == 'table' and tonumber(coords.z)

        if not MiningUtil.isWorldCoord(x, y, z) then
            return fail('A pickaxe vendor location has invalid coordinates.')
        end

        cleanLocations[#cleanLocations + 1] = {
            coords = { x = x, y = y, z = z, w = tonumber(coords.w) or 0.0 },
        }
    end

    local previousLocations = shopConfig.locations
    local previousModel = shopConfig.model
    shopConfig.locations = cleanLocations
    shopConfig.model = model

    local saved, err = saveShop()
    if not saved then
        shopConfig.locations = previousLocations
        shopConfig.model = previousModel
        return fail(err or 'Could not save pickaxe vendor.')
    end

    return shopConfig
end)

Kora.callback.register('kora_mining:pickaxeShop:creator:price', function(source, itemName, rawPrice)
    if not isAdmin(source) then return fail('Admin permission required.') end
    if not shopReady then return fail('Pickaxe shop is still loading.') end

    local pickaxe
    for _, entry in ipairs(PICKAXES_FOR_SALE) do
        if entry.item == itemName then
            pickaxe = entry
            break
        end
    end

    local price = tonumber(rawPrice)
    if not pickaxe then return fail('Unknown pickaxe.') end
    if not price or price % 1 ~= 0 or price < 0 or price > 100000000 then
        return fail('Price must be a whole number from 0 to 100,000,000.')
    end

    local previousPrice = shopConfig.prices[itemName]
    shopConfig.prices[itemName] = price

    local saved, err = saveShop()
    if not saved then
        shopConfig.prices[itemName] = previousPrice
        return fail(err or 'Could not save pickaxe price.')
    end

    return shopConfig
end)

AddEventHandler('playerDropped', function()
    pendingPurchases[source] = nil
end)
