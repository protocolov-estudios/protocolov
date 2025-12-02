local QBCore = exports['qb-core']:GetCoreObject()

RegisterNetEvent('EAC:noclipDetected')
    local _source = source
    local xPlayer = QBCore.Functions.GetPlayer(_source)
    print(xPlayer.name .. ' (' .. xPlayer.citizenid .. ') ha sido detectado usando noclip.')
    -- Aquí puedes añadir más acciones, como teletransportar al jugador, darle una advertencia, o banearlo.
    -- Ejemplo: DropPlayer(_source, "Detectado usando noclip. ¡No hagas trampas!")
end)

RegisterNetEvent('EAC:superJumpDetected')
AddEventHandler('EAC:superJumpDetected', function()
    local QBCore = exports['qb-core']:GetCoreObject()
    local _source = source
    local xPlayer = QBCore.Functions.GetPlayer(_source)
    print(xPlayer.name .. ' (' .. xPlayer.citizenid .. ') ha sido detectado usando super jump.')
    -- Aquí puedes añadir más acciones, como teletransportar al jugador, darle una advertencia, o banearlo.
end)

RegisterNetEvent('EAC:invisibleDetected')
AddEventHandler('EAC:invisibleDetected', function()
    local QBCore = exports['qb-core']:GetCoreObject()
    local _source = source
    local xPlayer = QBCore.Functions.GetPlayer(_source)
    print(xPlayer.name .. ' (' .. xPlayer.citizenid .. ') ha sido detectado usando invisibilidad.')
    -- Aquí puedes añadir más acciones.
end)

RegisterNetEvent('EAC:explosionDetected')
AddEventHandler('EAC:explosionDetected', function()
    local QBCore = exports['qb-core']:GetCoreObject()
    local _source = source
    local xPlayer = QBCore.Functions.GetPlayer(_source)
    print(xPlayer.name .. ' (' .. xPlayer.citizenid .. ') ha sido detectado creando explosiones ilegítimas.')
    -- Aquí puedes añadir más acciones.
end)

RegisterNetEvent('EAC:freezeDetected')
AddEventHandler('EAC:freezeDetected', function()
    local QBCore = exports['qb-core']:GetCoreObject()
    local _source = source
    local xPlayer = QBCore.Functions.GetPlayer(_source)
    print(xPlayer.name .. ' (' .. xPlayer.citizenid .. ') ha sido detectado congelado.')
    -- Aquí puedes añadir más acciones.
end)

RegisterNetEvent('EAC:blipDetected')
AddEventHandler('EAC:blipDetected', function()
    local _source = source
    local xPlayer = QBCore.Functions.GetPlayer(_source)
    print(xPlayer.name .. ' (' .. xPlayer.citizenid .. ') ha sido detectado creando blips ilegítimos.')
    -- Aquí puedes añadir más acciones.
end)

RegisterNetEvent('EAC:godmodeDetected')
AddEventHandler('EAC:godmodeDetected', function()
    local _source = source
    local xPlayer = QBCore.Functions.GetPlayer(_source)
    print(xPlayer.name .. ' (' .. xPlayer.citizenid .. ') ha sido detectado usando godmode.')
    -- Aquí puedes añadir más acciones.
end)

RegisterNetEvent('EAC:speedHackDetected')
AddEventHandler('EAC:speedHackDetected', function()
    local _source = source
    local xPlayer = QBCore.Functions.GetPlayer(_source)
    print(xPlayer.name .. ' (' .. xPlayer.citizenid .. ') ha sido detectado usando speed hack.')
    -- Aquí puedes añadir más acciones.
end)

RegisterNetEvent('EAC:teleportDetected')
AddEventHandler('EAC:teleportDetected', function()
    local _source = source
    local xPlayer = QBCore.Functions.GetPlayer(_source)
    print(xPlayer.name .. ' (' .. xPlayer.citizenid .. ') ha sido detectado usando teletransporte.')
    -- Aquí puedes añadir más acciones.
end)

RegisterNetEvent('EAC:weaponHackDetected')
AddEventHandler('EAC:weaponHackDetected', function()
    local _source = source
    local xPlayer = QBCore.Functions.GetPlayer(_source)
    print(xPlayer.name .. ' (' .. xPlayer.citizenid .. ') ha sido detectado usando hacks de armas.')
    -- Aquí puedes añadir más acciones.
end)

local eventCounts = {}
local maxEventsPerSecond = 10 -- Ajusta este valor según sea necesario

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000) -- Reiniciar contadores cada segundo
        if Config.AntiEventSpam then
            for k, v in pairs(eventCounts) do
                if v > maxEventsPerSecond then
                    local xPlayer = QBCore.Functions.GetPlayer(k)
                    print(xPlayer.name .. ' (' .. xPlayer.citizenid .. ') ha sido detectado haciendo spam de eventos.')
                    TriggerClientEvent('EAC:eventSpamDetected', k) -- Notificar al cliente si es necesario
                    -- Aquí puedes añadir más acciones, como kickear o banear al jugador.
                end
                eventCounts[k] = 0 -- Reiniciar el contador
            end
        end
    end
end)

AddEventHandler('playerConnecting', function(playerName, setKickReason, deferrals)
    local _source = source
    eventCounts[_source] = 0 -- Inicializar el contador para el nuevo jugador
    lastHeartbeat[_source] = GetGameTimer() -- Inicializar el latido al conectar
end)

AddEventHandler('playerDropped', function(reason)
    local _source = source
    eventCounts[_source] = nil -- Eliminar el contador del jugador desconectado
    lastHeartbeat[_source] = nil -- Eliminar el latido del jugador desconectado
    activeCaptchas[_source] = nil -- Limpiar CAPTCHA si el jugador se desconecta
end)

-- Hook para contar todos los eventos de red
AddEventHandler('__cfx_rpc_request', function(eventName, args, source)
    if Config.AntiEventSpam then
        if eventCounts[source] then
            eventCounts[source] = eventCounts[source] + 1
        else
            eventCounts[source] = 1
        end
    end
end)

local lastHeartbeat = {}
local heartbeatTimeout = 15000 -- 15 segundos sin latido es sospechoso

RegisterNetEvent('EAC:clientHeartbeat')
AddEventHandler('EAC:clientHeartbeat', function()
    local _source = source
    lastHeartbeat[_source] = GetGameTimer()
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(5000) -- Comprobar cada 5 segundos
        if Config.ClientIntegrityCheck then
            local currentTime = GetGameTimer()
            for k, v in pairs(lastHeartbeat) do
                if (currentTime - v) > heartbeatTimeout then
                    local xPlayer = QBCore.Functions.GetPlayer(k)
                    if xPlayer then
                        print(xPlayer.name .. ' (' .. xPlayer.citizenid .. ') no ha enviado un latido. Posible cliente modificado.')
                        -- Aquí puedes añadir más acciones, como kickear o banear al jugador.
                        -- Ejemplo: DropPlayer(k, "No se recibió el latido del cliente. Posible cliente modificado.")
                    end
                    lastHeartbeat[k] = nil -- Eliminar para evitar múltiples detecciones
                end
            end
        end
    end
end)

local activeCaptchas = {}

-- Función para generar un CAPTCHA simple
local function GenerateCaptchaText(length)
    local chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'
    local captcha = ''
    for i = 1, length do
        captcha = captcha .. string.sub(chars, math.random(1, #chars), math.random(1, #chars))
    end
    return captcha
end

RegisterNetEvent('playerSpawned') -- Usar playerSpawned para asegurar que el cliente está listo
AddEventHandler('playerSpawned', function()
    local _source = source
    if Config.CaptchaEnabled then
        print("Intentando mostrar CAPTCHA para el jugador: " .. _source)
        local captchaText = GenerateCaptchaText(6) -- CAPTCHA de 6 caracteres
        activeCaptchas[_source] = captchaText
        TriggerClientEvent('EAC:showCaptcha', _source, captchaText) -- Enviar el texto como si fuera la imagen
    end
end)

RegisterNetEvent('EAC:submitCaptcha')
AddEventHandler('EAC:submitCaptcha', function(solution)
    local _source = source
    if Config.CaptchaEnabled and activeCaptchas[_source] then
        if solution == activeCaptchas[_source] then
            TriggerClientEvent('EAC:hideCaptcha', _source, true) -- CAPTCHA correcto
            activeCaptchas[_source] = nil -- Eliminar CAPTCHA resuelto
        else
            local newCaptchaText = GenerateCaptchaText(6)
            activeCaptchas[_source] = newCaptchaText
            TriggerClientEvent('EAC:hideCaptcha', _source, false, newCaptchaText) -- CAPTCHA incorrecto, enviar nuevo
        end
    end
end)
