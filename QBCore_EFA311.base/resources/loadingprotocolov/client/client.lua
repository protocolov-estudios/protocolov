print('^1[DEBUG] loadingprotocolov/client.lua SCRIPT LOADED^7')

local loadingFinished = false

local function finishLoading()
    print('^1[DEBUG] finishLoading() function has been CALLED.^7')
    if loadingFinished then
        print('^1[DEBUG] finishLoading() exited because loading was already finished.^7')
        return
    end
    loadingFinished = true
    
    print('^2[loadingprotocolov] Finishing loading screen^7')
    SendNUIMessage({ action = 'complete' })
    
    -- Esperar a que la animación de fade-out termine (800ms + 1000ms = 1800ms total)
    Citizen.Wait(2000)
    
    -- Notificar a FiveM que la pantalla de carga ha terminado
    ShutdownLoadingScreenNui()
    print('^2[loadingprotocolov] Loading screen closed^7')
end

-- Thread que detecta cuando el jugador está listo (NUI focus activo = selector de personajes)
Citizen.CreateThread(function()
    print('^1[DEBUG] Character selection detection thread STARTED.^7')
    local checkCount = 0
    while not loadingFinished and checkCount < 120 do -- Máximo 60 segundos (120 * 500ms)
        Citizen.Wait(500)
        checkCount = checkCount + 1
        
        -- Verificar si el NUI tiene focus (indica que el selector de personajes está activo)
        if IsNuiFocused() then
            print('^1[DEBUG] NUI Focus detected - character selection screen is active!^7')
            Citizen.Wait(1500) -- Esperar un poco más para asegurar que todo esté cargado
            finishLoading()
            break
        end
        
        -- Debug cada 10 intentos (cada 5 segundos)
        if checkCount % 10 == 0 then
            print(string.format('^3[DEBUG] Still waiting for character selection... (%d seconds)^7', checkCount / 2))
        end
    end
    
    if not loadingFinished then
        print('^3[WARNING] Character selection not detected after 60 seconds - forcing close!^7')
        finishLoading()
    end
end)

-- Cuando QBCore reporta que el jugador está cargado (respaldo)
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    print('^1[DEBUG] QBCore:Client:OnPlayerLoaded event has been RECEIVED.^7')
    finishLoading()
end)


