fx_version 'cerulean'
game 'gta5'

name "rabu_garajeeditorcar"
description "Cambiar ubicacion de garaje (solo admins)"
author "rabudev"
version "0.0.1"

lua54 'yes'
use_experimental_fxv2_oal 'yes'

shared_scripts {
	'shared/*.lua'
}

client_scripts {
	'client/*.lua'
}

server_scripts {
	'server/*.lua',
	'@oxmysql/lib/MySQL.lua'
}

ui_page 'ui/index.html'

files {
	'ui/*.html',
	'ui/*.css',
	'ui/*.js'
}

dependencies { 'oxmysql', 'qb-core' }

