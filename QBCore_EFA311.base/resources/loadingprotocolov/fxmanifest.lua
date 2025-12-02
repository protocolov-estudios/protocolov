fx_version 'cerulean'
game 'gta5'

author 'Copilot (auto-generated)'
description 'Pantalla de carga para jugadores al entrar (loadingprotocolov)'
version '1.0.0'

loadscreen 'html/index.html'
loadscreen_manual_shutdown 'yes'

ui_page 'html/index.html'

client_script 'client/client.lua'
server_script 'server/server.lua'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}
