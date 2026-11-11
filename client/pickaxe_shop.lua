local APP_ID = 'kora_mining:pickaxeShop'

local vendors = {}
local catalog = {}

local function notify(message, tone)
    Kora.notify.send({
        title = 'Pickaxe Shop',
        message = message or 'Could not complete that purchase.',
        type = tone or 'error',
    })
end

local function formatMoney(amount)
    return ('$%d'):format(tonumber(amount) or 0)
end

local function buildNavigation(items)
    local rows = {}

    for _, pickaxe in ipairs(items or {}) do
        local pickaxeLabel = pickaxe.label or pickaxe.name or pickaxe.item or 'Pickaxe'
        local requirement
        if pickaxe.unlocked then
            requirement = ('Mining level %d · %s'):format(pickaxe.level, formatMoney(pickaxe.price))
        else
            requirement = ('Requires Mining level %d · %s'):format(pickaxe.level, formatMoney(pickaxe.price))
        end

        rows[#rows + 1] = {
            id = pickaxe.item,
            label = pickaxeLabel,
            description = requirement,
            image = pickaxe.image,
            actions = {
                {
                    id = 'pickaxe:buy:' .. pickaxe.item,
                    label = pickaxe.owned and 'Owned' or 'Buy',
                    icon = pickaxe.owned and 'Check' or 'ShoppingCart',
                    variant = 'primary',
                    disabled = pickaxe.owned or not pickaxe.unlocked,
                    confirm = not pickaxe.owned and pickaxe.unlocked
                        and ('Buy %s for %s cash?'):format(pickaxeLabel, formatMoney(pickaxe.price))
                        or nil,
                },
            },
        }
    end

    return {
        {
            id = 'shop',
            label = 'Pickaxes',
            icon = 'Pickaxe',
            content = {
                title = 'Mining Pickaxes',
                description = 'Purchase a pickaxe when you meet its Mining level requirement.',
                blocks = {
                    {
                        type = 'list',
                        id = 'pickaxe-list',
                        layout = 'cards',
                        columns = 2,
                        title = 'Pickaxes',
                        items = rows,
                        empty = 'No pickaxes are configured.',
                    },
                },
            },
        },
    }
end

local function openShop()
    local result, err = Kora.callback.trigger('kora_mining:pickaxeShop:get')
    if not result then
        notify(err)
        return
    end

    catalog = result.items or {}

    Kora.nui.registerApp({
        id = APP_ID,
        title = 'Mining Pickaxes',
        description = 'Buy mining tools',
        icon = 'Pickaxe',
        layout = 'compact',
        placement = 'right',
        width = 680,
        height = 720,
        navigation = buildNavigation(catalog),
        onAction = function(action)
            local item = action:match('^pickaxe:buy:(.+)$')
            if not item then return {} end

            local updated, purchaseError = Kora.callback.trigger('kora_mining:pickaxeShop:buy', item)
            if not updated then
                return {
                    notice = {
                        tone = 'destructive',
                        message = purchaseError or 'Purchase failed.',
                    },
                }
            end

            catalog = updated.items or catalog
            return {
                update = { navigation = buildNavigation(catalog) },
                notice = { tone = 'success', message = 'Pickaxe purchased.' },
            }
        end,
    })

    Kora.nui.openApp(APP_ID, { viewId = 'shop' })
end

local function clearVendors()
    for _, vendor in ipairs(vendors) do
        if vendor.targetId and vendor.entity then
            pcall(function()
                exports.kora_target:removeEntity(vendor.entity, vendor.targetId)
            end)
        end

        if vendor.entity and DoesEntityExist(vendor.entity) then
            DeleteEntity(vendor.entity)
        end
    end

    vendors = {}
end

local function spawnVendors(shop)
    clearVendors()

    if type(shop) ~= 'table' or type(shop.locations) ~= 'table' or type(shop.model) ~= 'string' then
        return
    end

    for _, location in ipairs(shop.locations) do
        local coords = location.coords or location
        if type(coords) == 'table' and coords.x and coords.y and coords.z then
            local entity = Kora.entities.create(
                shop.model,
                vector4(coords.x, coords.y, coords.z, coords.w or 0.0),
                { preset = 'static' }
            )
            if entity then
                local targetId = exports.kora_target:addEntity(entity, {
                    {
                        label = 'Buy Pickaxes',
                        icon = 'Pickaxe',
                        onSelect = openShop,
                    },
                })

                vendors[#vendors + 1] = { entity = entity, targetId = targetId }
            end
        end
    end
end

RegisterNetEvent('kora_mining:pickaxeShop:reload', spawnVendors)

CreateThread(function()
    local shop = Kora.state.awaitGlobal('koraMiningPickaxeShop', 30000, 100)
    if not shop then
        print('[kora_mining] timed out waiting for pickaxe vendor settings')
        return
    end

    spawnVendors(shop)
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        clearVendors()
    end
end)
