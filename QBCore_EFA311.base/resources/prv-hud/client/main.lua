local QBCore = exports['qb-core']:GetCoreObject()
local hudVisible = true

-- Inicializar HUD cuando el jugador spawna
CreateThread(function()
    Wait(1000)
    SendNUIMessage({
        action = "show",
        display = true
    })
end)

-- Actualizar estadísticas del HUD
CreateThread(function()
    while true do
        Wait(500) -- Actualizar cada 500ms
        
        if hudVisible then
            local player = PlayerPedId()
            
            -- Obtener salud (0-100)
            local health = GetEntityHealth(player) - 100
            if health < 0 then health = 0 end
            
            -- Obtener armadura (0-100)
            local armor = GetPedArmour(player)
            
            -- Obtener hambre y sed desde QBCore
            local PlayerData = QBCore.Functions.GetPlayerData()
            local hunger = 100
            local thirst = 100
            
            if PlayerData.metadata then
                if PlayerData.metadata["hunger"] then
                    hunger = PlayerData.metadata["hunger"]
                end
                if PlayerData.metadata["thirst"] then
                    thirst = PlayerData.metadata["thirst"]
                end
            end
            
            -- Enviar datos al NUI
            SendNUIMessage({
                action = "updateHUD",
                health = health,
                armor = armor,
                hunger = hunger,
                thirst = thirst
            })
        end
    end
end)

-- Comando para mostrar/ocultar HUD
RegisterCommand('togglehud', function()
    hudVisible = not hudVisible
    SendNUIMessage({
        action = "show",
        display = hudVisible
    })
end, false)

-- Ocultar HUD nativo de GTA
CreateThread(function()
    while true do
        Wait(0)
        -- Ocultar componentes del HUD nativo
        HideHudComponentThisFrame(1)  -- Wanted Stars
        HideHudComponentThisFrame(2)  -- Weapon Icon
        HideHudComponentThisFrame(3)  -- Cash
        HideHudComponentThisFrame(4)  -- MP Cash
        HideHudComponentThisFrame(6)  -- Vehicle Name
        HideHudComponentThisFrame(7)  -- Area Name
        HideHudComponentThisFrame(8)  -- Vehicle Class
        HideHudComponentThisFrame(9)  -- Street Name
        HideHudComponentThisFrame(13) -- Cash Change
        HideHudComponentThisFrame(17) -- Save Game
        HideHudComponentThisFrame(20) -- Weapon Stats
    end
end)

-- Control del Minimapa y Calles (Solo en vehículo)
CreateThread(function()
    while true do
        Wait(200)
        local player = PlayerPedId()
        if IsPedInAnyVehicle(player, false) then
            DisplayRadar(true)
            
            -- Obtener nombre de la calle
            local coords = GetEntityCoords(player)
            local streetHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
            local streetName = GetStreetNameFromHashKey(streetHash)
            
            -- Debug print
            print("Street Hash: " .. tostring(streetHash) .. " - Name: " .. tostring(streetName))
            
            SendNUIMessage({
                action = "updateStreet",
                street = streetName or "Desconocida",
                inVehicle = true
            })
        else
            DisplayRadar(false)
            SendNUIMessage({
                action = "updateStreet",
                inVehicle = false
            })
        end
    end
end)
