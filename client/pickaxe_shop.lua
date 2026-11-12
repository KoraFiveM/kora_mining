local APP_ID = 'kora_mining:pickaxeShop'

local vendors = {}
local catalog = {}

local function notify(message, tone)
    Kora.notify.send({
        title = Kora.lang('Ui.pickaxe_shop'),
        message = message or Kora.lang('Error.could_not_complete_purchase'),
        type = tone or 'error',
    })
end

local function formatMoney(amount)
    return Kora.lang('Ui.d', tonumber(amount) or 0)
end

local function buildNavigation(items)
    local rows = {}

    for _, pickaxe in ipairs(items or {}) do
        local pickaxeLabel = pickaxe.label or pickaxe.name or pickaxe.item or Kora.lang('Error.pickaxe')
        local requirement
        if pickaxe.unlocked then
            requirement = Kora.lang('Ui.mining_level_d_s', pickaxe.level, formatMoney(pickaxe.price))
        else
            requirement = Kora.lang('Ui.requires_mining_level_d_s', pickaxe.level, formatMoney(pickaxe.price))
        end

        rows[#rows + 1] = {
            id = pickaxe.item,
            label = pickaxeLabel,
            description = requirement,
            image = pickaxe.image,
            actions = {
                {
                    id = 'pickaxe:buy:' .. pickaxe.item,
                    label = pickaxe.owned and Kora.lang('Error.owned') or Kora.lang('Error.buy'),
                    icon = pickaxe.owned and 'Check' or 'ShoppingCart',
                    variant = 'primary',
                    disabled = pickaxe.owned or not pickaxe.unlocked,
                    confirm = not pickaxe.owned and pickaxe.unlocked
                        and Kora.lang('Ui.buy_s_for_s_cash', pickaxeLabel, formatMoney(pickaxe.price))
                        or nil,
                },
            },
        }
    end

    return {
        {
            id = 'shop',
            label = Kora.lang('Ui.pickaxes'),
            icon = 'Pickaxe',
            content = {
                title = Kora.lang('Ui.mining_pickaxes'),
                description = Kora.lang('Ui.purchase_a_pickaxe_when_you'),
                blocks = {
                    {
                        type = 'list',
                        id = 'pickaxe-list',
                        layout = 'cards',
                        columns = 2,
                        title = Kora.lang('Ui.pickaxes'),
                        items = rows,
                        empty = Kora.lang('Ui.no_pickaxes_are_configured'),
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
        title = Kora.lang('Ui.mining_pickaxes'),
        description = Kora.lang('Ui.buy_mining_tools'),
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
                        message = purchaseError or Kora.lang('Error.purchase_failed'),
                    },
                }
            end

            catalog = updated.items or catalog
            return {
                update = { navigation = buildNavigation(catalog) },
                notice = { tone = 'success', message = Kora.lang('Notify.pickaxe_purchased') },
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
                        label = Kora.lang('Ui.buy_pickaxes'),
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
