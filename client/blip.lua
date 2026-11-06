-- Static map blip for the mining area (suggestion thread 1567879565496553522).
-- Settings live in MiningConfig.blip; set enabled = false to turn it off.
CreateThread(function()
    local blip = MiningConfig.blip
    if type(blip) ~= 'table' or blip.enabled ~= true or not blip.coords then return end

    local name = blip.name or 'Mine Shaft'
    local ok, handle, err = pcall(Kora.blips.create, blip.coords, {
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
    if not ok or not handle then
        print(('^3[kora_mining] map blip was not created: %s^7'):format(tostring(ok and err or handle)))
    end
end)
