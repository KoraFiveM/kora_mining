fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'kora_mining'
author 'Kora'
description 'Mining rock spawn creator and configuration'
version '0.1.0'

dependency 'kora_lib'
dependency 'kora_core'
dependency 'kora_sql'
dependency 'kora_skills'
dependency 'kora_inventory'
dependency 'kora_target'
dependency 'props'
shared_scripts {
    '@kora_lib/init.lua',
    '@kora_core/init.lua',
    'shared/config.lua',
}

server_scripts {
    '@kora_sql/init.lua',
    'server/schema.lua',
    'server/util.lua',
    'server/main.lua',
    'server/pickaxe_shop.lua',
    'server/blips.lua',
    'server/smelting.lua',
}
client_scripts {
    'client/**.lua',
}

-- kora_qa: Gherkin test scenarios (converted legacy tests), see [kora]/kora_qa/README.md
qa_feature 'tests/*.feature'
