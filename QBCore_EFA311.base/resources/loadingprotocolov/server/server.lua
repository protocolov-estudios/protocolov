-- Simple server-side triggers so the server can ask clients to show the loading UI

AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    local src = source
    -- Show immediately when someone starts connecting
    TriggerClientEvent('loadingprotocolov:show', src, 0, 'BIENVENIDO A Protocolo V', 'ACCEDIENDO AL SERVIDOR')

    -- Simulate progress updates while they finish connecting (tunable)
    CreateThread(function()
        local progress = 0
        while progress < 100 do
            local step = math.random(5, 18)
            progress = progress + step
            if progress > 100 then progress = 100 end
            TriggerClientEvent('loadingprotocolov:update', src, progress)
            Wait(500)
        end

        TriggerClientEvent('loadingprotocolov:hide', src)
    end)
end)

-- Helper export / command for manual testing
RegisterCommand('startLoading', function(source, args, raw)
    local target = tonumber(args[1]) or source
    TriggerClientEvent('loadingprotocolov:show', target, 0)
end, false)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        print(('^2[loadingprotocolov] server started for resource %s^7'):format(resourceName))
    end
end)
