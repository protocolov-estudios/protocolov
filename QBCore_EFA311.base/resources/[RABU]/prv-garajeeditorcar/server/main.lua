-- Server: listen for requests from client to fetch vehicle info
RegisterNetEvent('rabu_garajeeditorcar:requestVehicle')
AddEventHandler('rabu_garajeeditorcar:requestVehicle', function(identifier, requestKey)
	local _src = source
	print(string.format('[rabu_garajeeditorcar] requestVehicle from %s identifier=%s requestKey=%s', tostring(_src), tostring(identifier), tostring(requestKey)))
	if not identifier or identifier == '' then
		TriggerClientEvent('QBCore:Notify', _src, 'Identificador vacío', 'error')
		return
	end

	-- debug: notify request arrived
	TriggerClientEvent('QBCore:Notify', _src, 'Solicitud recibida — buscando en la DB (' .. tostring(requestKey) .. ')', 'primary')

	-- ensure MySQL/oxmysql connection is ready
	print('[rabu_garajeeditorcar] waiting for MySQL ready...')
	local okReady, _ = pcall(function() return MySQL.ready.await() end)
	if not okReady then
		print('[rabu_garajeeditorcar] WARNING: MySQL.ready.await failed or timed out')
	end

	-- try to fetch by numeric id OR by plate (string) using await (no callback)
	local ok, result = pcall(function()
		return MySQL.query.await('SELECT * FROM player_vehicles WHERE id = ? OR plate = ? LIMIT 1', { identifier, identifier })
	end)

	if not ok then
		print(('[rabu_garajeeditorcar] ERROR querying DB for identifier=%s : %s'):format(tostring(identifier), tostring(result)))

		-- fallback: try calling oxmysql directly (older/newer versions may require different call)
		local fallbackOk, fallbackRes = pcall(function()
			return exports.oxmysql:query('SELECT * FROM player_vehicles WHERE id = ? OR plate = ? LIMIT 1', { identifier, identifier })
		end)

		if fallbackOk and fallbackRes then
			print(('[rabu_garajeeditorcar] fallback returned %d rows'):format(#fallbackRes))
			TriggerClientEvent('rabu_garajeeditorcar:sendVehicle', _src, fallbackRes)
			return
		end

		TriggerClientEvent('rabu_garajeeditorcar:sendVehicle', _src, {})
		return
	end

	print(('[rabu_garajeeditorcar] db returned %d rows for identifier=%s'):format(result and #result or 0, tostring(identifier)))
	if result and #result > 0 then
		TriggerClientEvent('rabu_garajeeditorcar:sendVehicle', _src, result)
	else
		-- not found, return empty
		TriggerClientEvent('rabu_garajeeditorcar:sendVehicle', _src, {})
	end
end)

-- Server: update vehicle data (simple: garage & plate updates supported)
RegisterNetEvent('rabu_garajeeditorcar:updateVehicle')
AddEventHandler('rabu_garajeeditorcar:updateVehicle', function(data)
	local _src = source
	if not data or (not data.id and not data.plate) then
		TriggerClientEvent('QBCore:Notify', _src, 'Datos inválidos', 'error')
		return
	end

	local identifier = data.id or data.plate
	local updates = {}
	local params = {}

	if data.garage ~= nil then
		table.insert(updates, 'garage = ?')
		table.insert(params, data.garage)
	end

	if data.newPlate ~= nil and data.newPlate ~= '' then
		table.insert(updates, 'plate = ?')
		table.insert(params, data.newPlate)
	end

	if #updates == 0 then
		TriggerClientEvent('QBCore:Notify', _src, 'Nada que actualizar', 'error')
		return
	end

	-- add identifier twice for plate/id OR plate
	table.insert(params, identifier)
	table.insert(params, identifier)

	local sql = ('UPDATE player_vehicles SET %s WHERE id = ? OR plate = ?'):format(table.concat(updates, ', '))

	local ok2, rowsChanged = pcall(function()
		return MySQL.update.await(sql, params)
	end)

	if not ok2 then
		print(('[rabu_garajeeditorcar] ERROR updating DB for identifier=%s : %s'):format(tostring(identifier), tostring(rowsChanged)))
		TriggerClientEvent('QBCore:Notify', _src, 'Error actualizando vehículo', 'error')
		return
	end

	TriggerClientEvent('QBCore:Notify', _src, 'Vehículo actualizado (' .. tostring(rowsChanged or 0) .. ')', 'success')

	-- return updated record so client can refresh (await)
	local ok3, res = pcall(function()
		return MySQL.query.await('SELECT * FROM player_vehicles WHERE id = ? OR plate = ? LIMIT 1', { identifier, identifier })
	end)

	if ok3 and res then
		TriggerClientEvent('rabu_garajeeditorcar:sendVehicle', _src, res)
	else
		TriggerClientEvent('rabu_garajeeditorcar:sendVehicle', _src, {})
	end
end)

-- Diagnostic handler: queries DB and returns basic info to requester
RegisterNetEvent('rabu_garajeeditorcar:diagnose')
AddEventHandler('rabu_garajeeditorcar:diagnose', function()
	local _src = source
	print('[rabu_garajeeditorcar] diagnose requested by ' .. tostring(_src))

	-- check oxmysql ready
	local okReady, _ = pcall(function() return MySQL.ready.await() end)
	if not okReady then
		print('[rabu_garajeeditorcar] MySQL.ready.await failed')
		TriggerClientEvent('QBCore:Notify', _src, 'MySQL no está listo', 'error')
		return
	end

	-- try sample query (COUNT)
	local ok, result = pcall(function()
		return MySQL.query.await('SELECT COUNT(*) as cnt FROM player_vehicles', {})
	end)

	if not ok then
		print('[rabu_garajeeditorcar] Diagnose query failed: ' .. tostring(result))
		TriggerClientEvent('QBCore:Notify', _src, 'Consulta de diagnóstico falló', 'error')
		return
	end

	local count = (result and result[1] and result[1].cnt) or 'desconocido'
	local msg = ('player_vehicles rows: %s'):format(tostring(count))
	print('[rabu_garajeeditorcar] ' .. msg)
	TriggerClientEvent('QBCore:Notify', _src, msg, 'success')
end)


-- List garages: SELECT DISTINCT garage FROM player_vehicles
RegisterNetEvent('rabu_garajeeditorcar:listGarages')
AddEventHandler('rabu_garajeeditorcar:listGarages', function()
	local _src = source
	print('[rabu_garajeeditorcar] listGarages requested by ' .. tostring(_src))

	-- First try to use existing qb-garages export if available (static config)
	local okExport, garagesExport = pcall(function() return exports['qb-garages'] and exports['qb-garages']:getAllGarages() end)
	if okExport and garagesExport and type(garagesExport) == 'table' and #garagesExport > 0 then
		print(('[rabu_garajeeditorcar] listGarages: got %d garages from qb-garages export'):format(#garagesExport))
		local out = {}
		for _, g in ipairs(garagesExport) do
			if g and g.name then
				table.insert(out, { name = g.name, label = g.label or g.name })
			end
		end
		TriggerClientEvent('rabu_garajeeditorcar:sendGarages', _src, out)
		return
	end

	-- if export not available, fallback to DB query
	-- ensure DB ready
	local okReady = pcall(function() return MySQL.ready.await() end)
	if not okReady then
		print('[rabu_garajeeditorcar] listGarages: MySQL not ready')
		TriggerClientEvent('QBCore:Notify', _src, 'MySQL no está listo', 'error')
		return
	end

	local ok, result = pcall(function()
		return MySQL.query.await("SELECT DISTINCT garage FROM player_vehicles WHERE garage IS NOT NULL AND garage <> ''", {})
	end)

	if not ok then
		print('[rabu_garajeeditorcar] listGarages: query failed: ' .. tostring(result))
		-- try fallback
		local fallOk, fallRes = pcall(function()
			return exports.oxmysql:query("SELECT DISTINCT garage FROM player_vehicles WHERE garage IS NOT NULL AND garage <> ''", {})
		end)

		if not fallOk then
			TriggerClientEvent('QBCore:Notify', _src, 'Error al leer garajes', 'error')
			return
		end

		result = fallRes
	end

	local names = {}
	if result and #result > 0 then
		for _, row in ipairs(result) do
			if row.garage and row.garage ~= '' then
				table.insert(names, { name = row.garage, label = row.garage })
			end
		end
	end

	TriggerClientEvent('rabu_garajeeditorcar:sendGarages', _src, names)
end)