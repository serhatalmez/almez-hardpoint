
shared_script '@FiveEye/FiveEye.lua'

fx_version 'adamant'
games { 'gta5' }
description 'trp-ctf'
lua54 'yes'

client_scripts {
  'config.lua',
  'client/lib.lua',
  'client/main.lua'
}

server_scripts {
  'config.lua',
  'server/main.lua'
}

server_script '@mysql-async/lib/MySQL.lua'