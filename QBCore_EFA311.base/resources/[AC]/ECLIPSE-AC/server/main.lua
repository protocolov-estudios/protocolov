
RegisterNetEvent('EAC:noclipDetected')
AddEventHandler('EAC:noclipDetected', function()
    local _source = source
    local xPlayer = QBCore.Functions.GetPlayer(_source)
    print(xPlayer.name .. ' (' .. xPlayer.citizenid .. ') ha sido detectado usando noclip.')
    -- Aquí puedes añadir más acciones, como teletransportar al jugador, darle una advertencia, o banearlo.
    -- Ejemplo: DropPlayer(_source, "Detectado usando noclip. ¡No hagas trampas!")
end)
