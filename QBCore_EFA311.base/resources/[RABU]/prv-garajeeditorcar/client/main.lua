local QBCore = exports['qb-core']:GetCoreObject()

-- pending request tracker for server timeouts
local PendingRequests = {}

-- Client command /editorenugaraje <id|plate>
-- Opens a NUI window and requests vehicle data from the server

RegisterCommand('editorgaraje', function(_, args)
	local id = args[1]
	if not id or id == '' then
		QBCore.Functions.Notify('Uso: /editorgaraje <id|plate>', 'error')
		return
	end

	-- request vehicle information from server by id or plate
	QBCore.Functions.Notify('Buscando vehículo — solicitando al servidor', 'primary')

	-- create a request key and send it (helps with debug/timeouts)
	local requestKey = id .. ':' .. GetGameTimer()
	PendingRequests[requestKey] = true
	print(('[rabu_garajeeditorcar] sending request to server identifier=%s requestKey=%s'):format(tostring(id), tostring(requestKey)))
	TriggerServerEvent('rabu_garajeeditorcar:requestVehicle', id, requestKey)

	CreateThread(function()
		local start = GetGameTimer()
		while PendingRequests[requestKey] do
			if (GetGameTimer() - start) > 1000 then -- 5s timeout
				PendingRequests[requestKey] = nil
				QBCore.Functions.Notify('No hay respuesta del servidor (tiempo de espera)', 'error')
				return
			end
			Wait(100)
		end
	end)
end, false)

-- Handle results from server
RegisterNetEvent('rabu_garajeeditorcar:sendVehicle')
AddEventHandler('rabu_garajeeditorcar:sendVehicle', function(result)
	if not result or #result == 0 then
		QBCore.Functions.Notify('Vehículo no encontrado', 'error')
		return
	end

	local vehicle = result[1]
	-- clear any pending requests (best-effort)
	for k,_ in pairs(PendingRequests) do
		PendingRequests[k] = nil
	end
	print(('[rabu_garajeeditorcar] received vehicle from server (id=%s plate=%s)'):format(tostring(vehicle.id), tostring(vehicle.plate)))
	QBCore.Functions.Notify('Vehículo encontrado — abriendo editor', 'success')
	-- open NUI and send data
	SetNuiFocus(true, true)
	SendNUIMessage({ action = 'open', data = vehicle })
end)

-- Close NUI
RegisterNetEvent('rabu_garajeeditorcar:closeNui')
AddEventHandler('rabu_garajeeditorcar:closeNui', function()
	SetNuiFocus(false, false)
end)

-- Receive NUI callbacks
RegisterNUICallback('close', function(_, cb)
	SetNuiFocus(false, false)
	cb('ok')
end)

RegisterNUICallback('save', function(data, cb)
	-- data is expected to include id/plate and fields to update (e.g., garage, plate)
	TriggerServerEvent('rabu_garajeeditorcar:updateVehicle', data)
	cb('ok')
end)

RegisterNUICallback('copied', function(data, cb)
	-- called from NUI when the user copies a garage name
	if data and data.name then
		QBCore.Functions.Notify(('Nombre copiado: %s'):format(data.name), 'success')
	end
	SetNuiFocus(false, false)
	cb('ok')
end)

RegisterNUICallback('useInEditor', function(data, cb)
	if data and data.name then
		-- open editor in prefill mode with garage
		SetNuiFocus(true, true)
		SendNUIMessage({ action = 'open', data = { mode = 'prefill', garage = data.name } })
	end
	cb('ok')
end)

-- Helpful command alias
RegisterCommand('editorenugaraje:help', function()
	QBCore.Functions.Notify('Usa /editorenugaraje <id|plate> — abre editor de vehículo', 'primary')
end, false)

-- diagnostic command: runs a quick DB connectivity check on server
RegisterCommand('garajediag', function()
	QBCore.Functions.Notify('Solicitando diagnóstico de DB...', 'primary')
	TriggerServerEvent('rabu_garajeeditorcar:diagnose')
end, false)


-- listgarajes / listgaraje: solicitamos al servidor la lista y abrimos UI para copiar
local function requestGarages()
	QBCore.Functions.Notify('Solicitando lista de garajes...', 'primary')
	TriggerServerEvent('rabu_garajeeditorcar:listGarages')
end

RegisterCommand('listgarajes', function()
	requestGarages()
end, false)

-- alias singular (por conveniencia del usuario)
RegisterCommand('listgaraje', function()
	requestGarages()
end, false)

RegisterNetEvent('rabu_garajeeditorcar:sendGarages')
AddEventHandler('rabu_garajeeditorcar:sendGarages', function(names)
	if not names or #names == 0 then
		QBCore.Functions.Notify('No se encontraron garajes', 'error')
		return
	end

	-- open NUI list and send names
	SetNuiFocus(true, true)
	SendNUIMessage({ action = 'listGarages', data = names })
end)

