Kora = { sql = { NULL = '\0qbsql:null\0' } }
dofile('server/schema.lua')

local EXPECTED_ROWS = {
    kora_mining_pickaxe_shop = 1,
    kora_mining_blips = 2,
    kora_mining_rockspawns = 20,
    kora_mining_smelting_recipes = 55,
    kora_mining_smelting_stations = 2,
}

local function readFile(path)
    local f = assert(io.open(path, 'rb'))
    local s = f:read('a')
    f:close()
    return s
end

assert(#KoraMiningSchema == 5, 'expected 5 tables')

local byName = {}
for _, spec in ipairs(KoraMiningSchema) do
    byName[spec.name] = spec
    assert(spec.collate == 'utf8mb4_general_ci', spec.name .. ' collate')
    assert(spec.primary and #spec.primary == 1 and spec.primary[1] == 'id', spec.name .. ' primary key')
    assert(spec.seed and spec.seed.once == true, spec.name .. ' seed must be once')
    assert(#spec.seed.rows == EXPECTED_ROWS[spec.name], spec.name .. ' row count ' .. #spec.seed.rows)
    local ids = {}
    for _, row in ipairs(spec.seed.rows) do
        assert(not ids[row.id], spec.name .. ' duplicate id ' .. row.id)
        ids[row.id] = true
    end
end
for name in pairs(EXPECTED_ROWS) do assert(byName[name], 'missing table ' .. name) end

local sapphire
for _, row in ipairs(byName.kora_mining_rockspawns.seed.rows) do
    if row.id == 'sapphire' then sapphire = row end
end
assert(sapphire, 'sapphire rockspawn missing')
assert(sapphire.data:find('"item":"uncut_sapphire"', 1, true), 'sapphire must yield uncut_sapphire')

for _, file in ipairs({ 'server/main.lua', 'server/pickaxe_shop.lua', 'server/blips.lua', 'server/smelting.lua', 'server/schema.lua' }) do
    local src = readFile(file):lower()
    for _, banned in ipairs({ 'migrate', 'alter table', 'create table' }) do
        assert(not src:find(banned, 1, true), file .. ' contains ' .. banned)
    end
end

print('kora_mining schema tests passed')
