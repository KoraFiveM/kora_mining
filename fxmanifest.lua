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
    '@kora_sql/init.lua',
    'shared/config.lua',
}

server_scripts {
    'server/**.lua',
}
client_scripts {
    'client/**.lua',
}
