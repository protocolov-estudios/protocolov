
local noclipDetected = 0
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(100)
        if Config.AntiNoClip then
            local ped = PlayerPedId()
            if IsPedNoclipping(ped) then
                noclipDetected = noclipDetected + 1
                if noclipDetected >= 5 then -- Detectar 5 veces seguidas para evitar falsos positivos
                    TriggerServerEvent('EAC:noclipDetected')
                    noclipDetected = 0
                end
            else
                noclipDetected = 0
            end
        end
    end
end)

function IsPedNoclipping(ped)
    -- Esta es una función de ejemplo, la detección real de noclip es más compleja.
    -- Podrías comparar la posición del jugador con la del frame anterior,
    -- o verificar si está en un estado de "volar" sin un vehículo.
    -- Por ahora, usaremos una detección simple.
    local currentCoords = GetEntityCoords(ped)
    Citizen.Wait(1)
    local newCoords = GetEntityCoords(ped)
    local distance = #(currentCoords - newCoords)
    if distance > 5.0 and not IsPedInAnyVehicle(ped, false) then -- Si se mueve muy rápido sin vehículo
        return true
    end
    return false
end
