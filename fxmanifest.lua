fx_version 'cerulean'
game 'gta5'

name 'P_garbage'
author 'ZoniBoy00 (QBox Conversion)'
description 'Garbage Collection Job for QBox Framework with Discord Logging'
version '1.0.0'

lua54 'yes'

shared_scripts {
    '@qb-core/shared/locale.lua',
    '@ox_lib/init.lua',
    'shared/config.lua',
    'shared/locations.lua',
}

client_scripts {
    'client/utils.lua',
    'client/bins.lua',
    'client/team.lua',
    'client/main.lua'
}

server_scripts {
    'server/webhook.lua',
    'server/teams.lua',
    'server/main.lua'
}

dependencies {
    'qb-core',
    'ox_lib',
    'ox_target'
}

escrow_ignore {
    'shared/config.lua',
    'shared/locations.lua',
    'README.md'
}
