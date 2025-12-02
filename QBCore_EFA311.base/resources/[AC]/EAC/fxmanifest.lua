fx_version 'cerulean'
game 'gta5'

name "ECLIPSE-AC"
description "Ac"
author "Eclipse network"
version "0.0.0.1"

lua54 'yes'
use_experimental_fxv2_oal 'yes'

shared_scripts {
	'shared/*.lua'
}

client_scripts {
	'client/*.lua'
}

server_scripts {
	'server/*.lua'
}

ui_page 'ui/index.html'

files {
    'ui/index.html',
    'ui/style.css',
    'ui/script.js'
}
