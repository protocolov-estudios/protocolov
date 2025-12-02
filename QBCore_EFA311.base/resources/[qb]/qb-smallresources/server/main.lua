

RegisterNetEvent('tackle:server:TacklePlayer', function(playerId)
    TriggerClientEvent('tackle:client:GetTackled', playerId)
end)

QBCore.Commands.Add('id', 'Check Your ID #', {}, false, function(source)
    TriggerClientEvent('QBCore:Notify', source, 'ID: ' .. source)
end)

QBCore.Functions.CreateUseableItem('harness', function(source, item)
    TriggerClientEvent('seatbelt:client:UseHarness', source, item)
end)

RegisterNetEvent('equip:harness', function(item)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    if not Player.PlayerData.items[item.slot].info.uses then
        Player.PlayerData.items[item.slot].info.uses = Config.HarnessUses - 1
        Player.Functions.SetInventory(Player.PlayerData.items)
    elseif Player.PlayerData.items[item.slot].info.uses == 1 then
        exports['qb-inventory']:RemoveItem(src, 'harness', 1, false, 'equip:harness')
        TriggerClientEvent('qb-inventory:client:ItemBox', src, QBCore.Shared.Items['harness'], 'remove')
    else
        Player.PlayerData.items[item.slot].info.uses -= 1
        Player.Functions.SetInventory(Player.PlayerData.items)
    end
end)

RegisterNetEvent('seatbelt:DoHarnessDamage', function(hp, data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    if hp == 0 then
        exports['qb-inventory']:RemoveItem(src, 'harness', 1, data.slot, 'seatbelt:DoHarnessDamage')
    else
        Player.PlayerData.items[data.slot].info.uses -= 1
        Player.Functions.SetInventory(Player.PlayerData.items)
    end
end)

RegisterNetEvent('qb-carwash:server:washCar', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if not Player then return end

    if Player.Functions.RemoveMoney('cash', Config.CarWash.defaultPrice, 'car-washed') then
        TriggerClientEvent('qb-carwash:client:washCar', src)
    elseif Player.Functions.RemoveMoney('bank', Config.CarWash.defaultPrice, 'car-washed') then
        TriggerClientEvent('qb-carwash:client:washCar', src)
    else
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.dont_have_enough_money'), 'error')
    end
end)

QBCore.Functions.CreateCallback('smallresources:server:GetCurrentPlayers', function(_, cb)
    cb(#GetPlayers())
end)

unction AddLog(data)
    local name = 'phone'
    local title = data.title
    local message = data.message ~= nil and data.message or 'BLANK MESSAGE from log: '..data.type
    local tag = tagEveryone ~= nil and tagEveryone or false
    local webHook = 'https://discord.com/api/webhooks/1440317726693527632/31O3FY21U4KAInZTt1NkwpIhU57x_TOnSurbLeKob5RihjlUt0QjiImHFCVimxT2iwE5'
    local embedData = {
        {
            ["title"] = title,
            ["color"] = 16711680,
            ["footer"] = {
                ["text"] = os.date("%c"),
            },
            ["description"] = message,
        }
    }
    PerformHttpRequest(webHook, function(err, text, headers) end, 'POST', json.encode({ username = "QB Logs",embeds = embedData}), { ['Content-Type'] = 'application/json' })
    Wait(100)
    if tag then
        PerformHttpRequest(webHook, function(err, text, headers) end, 'POST', json.encode({ username = "QB Logs", content = "@everyone"}), { ['Content-Type'] = 'application/json' })
    end
end
exports('AddLog', AddLog)