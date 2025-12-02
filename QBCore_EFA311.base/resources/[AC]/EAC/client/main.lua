local noclipDetected = 0
local superJumpDetected = 0
local invisibleDetected = 0
local freezeDetected = 0
local lastPosition = vector3(0.0, 0.0, 0.0)
local lastCheckTime = 0
local lastHealth = 0
local godmodeDetected = 0
local speedHackDetected = 0
local maxFootSpeed = 10.0 -- Velocidad máxima a pie (ajustar según sea necesario)
local maxVehicleSpeed = 60.0 -- Velocidad máxima en vehículo (ajustar según sea necesario)
local lastTeleportCheckCoords = vector3(0.0, 0.0, 0.0)
local teleportDetected = 0
local maxTeleportDistance = 50.0 -- Distancia máxima permitida en un corto período (ajustar según sea necesario)
local captchaActive = false

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(100)
        local ped = PlayerPedId()

        -- Lógica de detección de NoClip
        if Config.AntiNoClip then
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

        -- Lógica de detección de Super Jump
        if Config.AntiSuperJump then
            local velocity = GetEntityVelocity(ped)
            local zVelocity = velocity.z

            if zVelocity > 3.0 and not IsPedInAnyVehicle(ped, false) and not IsPedSwimming(ped) and not IsPedDiving(ped) then -- Ajusta el valor 3.0 según sea necesario
                superJumpDetected = superJumpDetected + 1
                if superJumpDetected >= 3 then -- Detectar 3 veces seguidas
                    TriggerServerEvent('EAC:superJumpDetected')
                    superJumpDetected = 0
                end
            else
                superJumpDetected = 0
            end
        end

        -- Lógica de detección de Invisibilidad
        if Config.AntiInvisible then
            if not IsEntityVisible(ped) then
                invisibleDetected = invisibleDetected + 1
                if invisibleDetected >= 5 then -- Detectar 5 veces seguidas
                    TriggerServerEvent('EAC:invisibleDetected')
                    invisibleDetected = 0
                end
            else
                invisibleDetected = 0
            end
        end

        -- Lógica de detección de congelación
        if Config.AntiFreeze then
            local currentCoords = GetEntityCoords(ped)
            local currentTime = GetGameTimer()

            if lastCheckTime ~= 0 then
                local distance = #(currentCoords - lastPosition)
                if distance < 0.1 and not IsPedInAnyVehicle(ped, false) and not IsPedRagdoll(ped) and not IsPedFalling(ped) and not IsPedSwimming(ped) and not IsPedDiving(ped) then -- Si no se mueve
                    freezeDetected = freezeDetected + 1
                    if freezeDetected >= 5 then -- Si está congelado por 5 segundos
                        TriggerServerEvent('EAC:freezeDetected')
                        freezeDetected = 0
                    end
                else
                    freezeDetected = 0
                end
            end
            lastPosition = currentCoords
            lastCheckTime = currentTime
        end

        -- Lógica de detección de Godmode
        if Config.AntiGodmode then
            local currentHealth = GetEntityHealth(ped)

            if lastHealth ~= 0 and currentHealth > lastHealth then -- Si la salud aumenta sin razón
                godmodeDetected = godmodeDetected + 1
                if godmodeDetected >= 3 then
                    TriggerServerEvent('EAC:godmodeDetected')
                    godmodeDetected = 0
                end
            elseif currentHealth < lastHealth then -- Si recibe daño, resetear el contador
                godmodeDetected = 0
            end
            lastHealth = currentHealth
        end

        -- Lógica de detección de Speed Hack
        if Config.AntiSpeedHack then
            local velocity = GetEntityVelocity(ped)
            local speed = #(velocity) -- Magnitud de la velocidad

            if IsPedInAnyVehicle(ped, false) then
                if speed > maxVehicleSpeed then
                    speedHackDetected = speedHackDetected + 1
                    if speedHackDetected >= 5 then
                        TriggerServerEvent('EAC:speedHackDetected')
                        speedHackDetected = 0
                    end
                else
                    speedHackDetected = 0
                end
            else
                if speed > maxFootSpeed then
                    speedHackDetected = speedHackDetected + 1
                    if speedHackDetected >= 5 then
                        TriggerServerEvent('EAC:speedHackDetected')
                        speedHackDetected = 0
                    end
                else
                    speedHackDetected = 0
                end
            end
        end
    end
end)

-- AntiExplosions (Client-side)
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0) -- Esperar un ciclo para no bloquear el juego
        if Config.AntiExplosions then
            -- Interceptar la creación de explosiones
            -- Esto es un ejemplo, la implementación real puede requerir un hook o una función nativa específica
            -- que no está directamente disponible en Lua de FiveM para interceptar todas las explosiones.
            -- Una forma más común es monitorear el daño de explosiones o el uso de armas explosivas.
            -- Para este ejemplo, simularemos una detección simple si el jugador intenta crear una explosión.
            -- En un entorno real, necesitarías un método más robusto para detectar explosiones ilegítimas.
            -- Por ejemplo, podrías usar un evento de red personalizado que se active cuando un jugador crea una explosión.
            -- Aquí, solo pondremos un marcador para el futuro.
        end
    end
end)

-- AntiBlips (Client-side)
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(5000) -- Comprobar cada 5 segundos
        if Config.AntiBlips then
            for i = 0, 1000 do -- Iterar a través de posibles IDs de blips
                if DoesBlipExist(i) then
                    local blip = GetBlipFromId(i)
                    if blip ~= nil and IsBlipOnMinimap(blip) and not IsBlipFriendly(blip) and not IsBlipPrimary(blip) then
                        -- Si el blip existe, está en el minimapa y no es amigable o primario (creado por el juego)
                        -- Esto es una simplificación. En un sistema real, necesitarías una lista blanca de blips legítimos.
                        RemoveBlip(blip)
                        TriggerServerEvent('EAC:blipDetected')
                    end
                end
            end
        end
    end
end)

-- AntiWeaponHack (Client-side)
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(5000) -- Comprobar cada 5 segundos
        if Config.AntiWeaponHack then
            local ped = PlayerPedId()
            -- Aquí podrías iterar sobre las armas del jugador y verificar si son legítimas
            -- o si la munición es excesiva para un arma en particular.
            -- Esto es un marcador para una implementación más robusta en el futuro.
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

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(500) -- Comprobar cada 500ms
        if Config.AntiTeleport then
            local ped = PlayerPedId()
            local currentCoords = GetEntityCoords(ped)

            if lastTeleportCheckCoords.x ~= 0.0 or lastTeleportCheckCoords.y ~= 0.0 or lastTeleportCheckCoords.z ~= 0.0 then
                local distance = #(currentCoords - lastTeleportCheckCoords)
                if distance > maxTeleportDistance and not IsPedInAnyVehicle(ped, false) then -- Si se mueve muy lejos sin vehículo
                    teleportDetected = teleportDetected + 1
                    if teleportDetected >= 2 then -- Detectar 2 veces seguidas
                        TriggerServerEvent('EAC:teleportDetected')
                        teleportDetected = 0
                    end
                else
                    teleportDetected = 0
                end
            end
            lastTeleportCheckCoords = currentCoords
        end
    end
end)

-- Client Integrity Check (Client-side)
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(5000) -- Enviar latido cada 5 segundos
        if Config.ClientIntegrityCheck then
            TriggerServerEvent('EAC:clientHeartbeat')
        end
    end
end)

-- Congelar al jugador y mostrar CAPTCHA
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if captchaActive then
            DisableControlAction(0, 1, true) -- LookLeftRight
            DisableControlAction(0, 2, true) -- LookUpDown
            DisableControlAction(0, 106, true) -- VehicleMouseControlOverride
            DisableControlAction(0, 30, true) -- MoveLeftRight
            DisableControlAction(0, 31, true) -- MoveUpDown
            DisableControlAction(0, 32, true) -- MoveUp
            DisableControlAction(0, 33, true) -- MoveDown
            DisableControlAction(0, 34, true) -- MoveLeft
            DisableControlAction(0, 35, true) -- MoveRight
            DisableControlAction(0, 21, true) -- Sprint
            DisableControlAction(0, 22, true) -- Jump
            DisableControlAction(0, 23, true) -- EnterVehicle
            DisableControlAction(0, 24, true) -- Attack
            DisableControlAction(0, 25, true) -- Aim
            DisableControlAction(0, 47, true) -- WeaponWheel
            DisableControlAction(0, 58, true) -- VehicleAttack
            DisableControlAction(0, 71, true) -- VehicleDriveBy
            DisableControlAction(0, 72, true) -- VehicleDriveBy
            DisableControlAction(0, 140, true) -- MeleeAttack1
            DisableControlAction(0, 141, true) -- MeleeAttack2
            DisableControlAction(0, 142, true) -- MeleeAttack3
            DisableControlAction(0, 257, true) -- Attack
            DisableControlAction(0, 263, true) -- MeleeAttack1
            DisableControlAction(0, 264, true) -- MeleeAttack2
            DisableControlAction(0, 265, true) -- MeleeAttack3
            DisableControlAction(0, 266, true) -- MeleeAttack4
            DisableControlAction(0, 267, true) -- MeleeAttack5
            DisableControlAction(0, 268, true) -- MeleeAttack6
            DisableControlAction(0, 269, true) -- MeleeAttack7
            DisableControlAction(0, 270, true) -- MeleeAttack8
            DisableControlAction(0, 271, true) -- MeleeAttack9
            DisableControlAction(0, 272, true) -- MeleeAttack10
            DisableControlAction(0, 273, true) -- MeleeAttack11
            DisableControlAction(0, 274, true) -- MeleeAttack12
            DisableControlAction(0, 275, true) -- MeleeAttack13
            DisableControlAction(0, 276, true) -- MeleeAttack14
            DisableControlAction(0, 277, true) -- MeleeAttack15
            DisableControlAction(0, 278, true) -- MeleeAttack16
            DisableControlAction(0, 279, true) -- MeleeAttack17
            DisableControlAction(0, 280, true) -- MeleeAttack18
            DisableControlAction(0, 281, true) -- MeleeAttack19
            DisableControlAction(0, 282, true) -- MeleeAttack20
            DisableControlAction(0, 283, true) -- MeleeAttack21
            DisableControlAction(0, 284, true) -- MeleeAttack22
            DisableControlAction(0, 285, true) -- MeleeAttack23
            DisableControlAction(0, 286, true) -- MeleeAttack24
            DisableControlAction(0, 287, true) -- MeleeAttack25
            DisableControlAction(0, 288, true) -- MeleeAttack26
            DisableControlAction(0, 289, true) -- MeleeAttack27
            DisableControlAction(0, 290, true) -- MeleeAttack28
            DisableControlAction(0, 291, true) -- MeleeAttack29
            DisableControlAction(0, 292, true) -- MeleeAttack30
            DisableControlAction(0, 293, true) -- MeleeAttack31
            DisableControlAction(0, 294, true) -- MeleeAttack32
            DisableControlAction(0, 295, true) -- MeleeAttack33
            DisableControlAction(0, 296, true) -- MeleeAttack34
            DisableControlAction(0, 297, true) -- MeleeAttack35
            DisableControlAction(0, 298, true) -- MeleeAttack36
            DisableControlAction(0, 299, true) -- MeleeAttack37
            DisableControlAction(0, 300, true) -- MeleeAttack38
            DisableControlAction(0, 301, true) -- MeleeAttack39
            DisableControlAction(0, 302, true) -- MeleeAttack40
            DisableControlAction(0, 303, true) -- MeleeAttack41
            DisableControlAction(0, 304, true) -- MeleeAttack42
            DisableControlAction(0, 305, true) -- MeleeAttack43
            DisableControlAction(0, 306, true) -- MeleeAttack44
            DisableControlAction(0, 307, true) -- MeleeAttack45
            DisableControlAction(0, 308, true) -- MeleeAttack46
            DisableControlAction(0, 309, true) -- MeleeAttack47
            DisableControlAction(0, 310, true) -- MeleeAttack48
            DisableControlAction(0, 311, true) -- MeleeAttack49
            DisableControlAction(0, 312, true) -- MeleeAttack50
            DisableControlAction(0, 313, true) -- MeleeAttack51
            DisableControlAction(0, 314, true) -- MeleeAttack52
            DisableControlAction(0, 315, true) -- MeleeAttack53
            DisableControlAction(0, 316, true) -- MeleeAttack54
            DisableControlAction(0, 317, true) -- MeleeAttack55
            DisableControlAction(0, 318, true) -- MeleeAttack56
            DisableControlAction(0, 319, true) -- MeleeAttack57
            DisableControlAction(0, 320, true) -- MeleeAttack58
            DisableControlAction(0, 321, true) -- MeleeAttack59
            DisableControlAction(0, 322, true) -- MeleeAttack60
            DisableControlAction(0, 323, true) -- MeleeAttack61
            DisableControlAction(0, 324, true) -- MeleeAttack62
            DisableControlAction(0, 325, true) -- MeleeAttack63
            DisableControlAction(0, 326, true) -- MeleeAttack64
            DisableControlAction(0, 327, true) -- MeleeAttack65
            DisableControlAction(0, 328, true) -- MeleeAttack66
            DisableControlAction(0, 329, true) -- MeleeAttack67
            DisableControlAction(0, 330, true) -- MeleeAttack68
            DisableControlAction(0, 331, true) -- MeleeAttack69
            DisableControlAction(0, 332, true) -- MeleeAttack70
            DisableControlAction(0, 333, true) -- MeleeAttack71
            DisableControlAction(0, 334, true) -- MeleeAttack72
            DisableControlAction(0, 335, true) -- MeleeAttack73
            DisableControlAction(0, 336, true) -- MeleeAttack74
            DisableControlAction(0, 337, true) -- MeleeAttack75
            DisableControlAction(0, 338, true) -- MeleeAttack76
            DisableControlAction(0, 339, true) -- MeleeAttack77
            DisableControlAction(0, 340, true) -- MeleeAttack78
            DisableControlAction(0, 341, true) -- MeleeAttack79
            DisableControlAction(0, 342, true) -- MeleeAttack80
            DisableControlAction(0, 343, true) -- MeleeAttack81
            DisableControlAction(0, 344, true) -- MeleeAttack82
            DisableControlAction(0, 345, true) -- MeleeAttack83
            DisableControlAction(0, 346, true) -- MeleeAttack84
            DisableControlAction(0, 347, true) -- MeleeAttack85
            DisableControlAction(0, 348, true) -- MeleeAttack86
            DisableControlAction(0, 349, true) -- MeleeAttack87
            DisableControlAction(0, 350, true) -- MeleeAttack88
            DisableControlAction(0, 351, true) -- MeleeAttack89
            DisableControlAction(0, 352, true) -- MeleeAttack90
            DisableControlAction(0, 353, true) -- MeleeAttack91
            DisableControlAction(0, 354, true) -- MeleeAttack92
            DisableControlAction(0, 355, true) -- MeleeAttack93
            DisableControlAction(0, 356, true) -- MeleeAttack94
            DisableControlAction(0, 357, true) -- MeleeAttack95
            DisableControlAction(0, 358, true) -- MeleeAttack96
            DisableControlAction(0, 359, true) -- MeleeAttack97
            DisableControlAction(0, 360, true) -- MeleeAttack98
            DisableControlAction(0, 361, true) -- MeleeAttack99
            DisableControlAction(0, 362, true) -- MeleeAttack100
            DisableControlAction(0, 363, true) -- MeleeAttack101
            DisableControlAction(0, 364, true) -- MeleeAttack102
            DisableControlAction(0, 365, true) -- MeleeAttack103
            DisableControlAction(0, 366, true) -- MeleeAttack104
            DisableControlAction(0, 367, true) -- MeleeAttack105
            DisableControlAction(0, 368, true) -- MeleeAttack106
            DisableControlAction(0, 369, true) -- MeleeAttack107
            DisableControlAction(0, 370, true) -- MeleeAttack108
            DisableControlAction(0, 371, true) -- MeleeAttack109
            DisableControlAction(0, 372, true) -- MeleeAttack110
            DisableControlAction(0, 373, true) -- MeleeAttack111
            DisableControlAction(0, 374, true) -- MeleeAttack112
            DisableControlAction(0, 375, true) -- MeleeAttack113
            DisableControlAction(0, 376, true) -- MeleeAttack114
            DisableControlAction(0, 377, true) -- MeleeAttack115
            DisableControlAction(0, 378, true) -- MeleeAttack116
            DisableControlAction(0, 379, true) -- MeleeAttack117
            DisableControlAction(0, 380, true) -- MeleeAttack118
            DisableControlAction(0, 381, true) -- MeleeAttack119
            DisableControlAction(0, 382, true) -- MeleeAttack120
            DisableControlAction(0, 383, true) -- MeleeAttack121
            DisableControlAction(0, 384, true) -- MeleeAttack122
            DisableControlAction(0, 385, true) -- MeleeAttack123
            DisableControlAction(0, 386, true) -- MeleeAttack124
            DisableControlAction(0, 387, true) -- MeleeAttack125
            DisableControlAction(0, 388, true) -- MeleeAttack126
            DisableControlAction(0, 389, true) -- MeleeAttack127
            DisableControlAction(0, 390, true) -- MeleeAttack128
            DisableControlAction(0, 391, true) -- MeleeAttack129
            DisableControlAction(0, 392, true) -- MeleeAttack130
            DisableControlAction(0, 393, true) -- MeleeAttack131
            DisableControlAction(0, 394, true) -- MeleeAttack132
            DisableControlAction(0, 395, true) -- MeleeAttack133
            DisableControlAction(0, 396, true) -- MeleeAttack134
            DisableControlAction(0, 397, true) -- MeleeAttack135
            DisableControlAction(0, 398, true) -- MeleeAttack136
            DisableControlAction(0, 399, true) -- MeleeAttack137
            DisableControlAction(0, 400, true) -- MeleeAttack138
            DisableControlAction(0, 401, true) -- MeleeAttack139
            DisableControlAction(0, 402, true) -- MeleeAttack140
            DisableControlAction(0, 403, true) -- MeleeAttack141
            DisableControlAction(0, 404, true) -- MeleeAttack142
            DisableControlAction(0, 405, true) -- MeleeAttack143
            DisableControlAction(0, 406, true) -- MeleeAttack144
            DisableControlAction(0, 407, true) -- MeleeAttack145
            DisableControlAction(0, 408, true) -- MeleeAttack146
            DisableControlAction(0, 409, true) -- MeleeAttack147
            DisableControlAction(0, 410, true) -- MeleeAttack148
            DisableControlAction(0, 411, true) -- MeleeAttack149
            DisableControlAction(0, 412, true) -- MeleeAttack150
            DisableControlAction(0, 413, true) -- MeleeAttack151
            DisableControlAction(0, 414, true) -- MeleeAttack152
            DisableControlAction(0, 415, true) -- MeleeAttack153
            DisableControlAction(0, 416, true) -- MeleeAttack154
            DisableControlAction(0, 417, true) -- MeleeAttack155
            DisableControlAction(0, 418, true) -- MeleeAttack156
            DisableControlAction(0, 419, true) -- MeleeAttack157
            DisableControlAction(0, 420, true) -- MeleeAttack158
            DisableControlAction(0, 421, true) -- MeleeAttack159
            DisableControlAction(0, 422, true) -- MeleeAttack160
            DisableControlAction(0, 423, true) -- MeleeAttack161
            DisableControlAction(0, 424, true) -- MeleeAttack162
            DisableControlAction(0, 425, true) -- MeleeAttack163
            DisableControlAction(0, 426, true) -- MeleeAttack164
            DisableControlAction(0, 427, true) -- MeleeAttack165
            DisableControlAction(0, 428, true) -- MeleeAttack166
            DisableControlAction(0, 429, true) -- MeleeAttack167
            DisableControlAction(0, 430, true) -- MeleeAttack168
            DisableControlAction(0, 431, true) -- MeleeAttack169
            DisableControlAction(0, 432, true) -- MeleeAttack170
            DisableControlAction(0, 433, true) -- MeleeAttack171
            DisableControlAction(0, 434, true) -- MeleeAttack172
            DisableControlAction(0, 435, true) -- MeleeAttack173
            DisableControlAction(0, 436, true) -- MeleeAttack174
            DisableControlAction(0, 437, true) -- MeleeAttack175
            DisableControlAction(0, 438, true) -- MeleeAttack176
            DisableControlAction(0, 439, true) -- MeleeAttack177
            DisableControlAction(0, 440, true) -- MeleeAttack178
            DisableControlAction(0, 441, true) -- MeleeAttack179
            DisableControlAction(0, 442, true) -- MeleeAttack180
            DisableControlAction(0, 443, true) -- MeleeAttack181
            DisableControlAction(0, 444, true) -- MeleeAttack182
            DisableControlAction(0, 445, true) -- MeleeAttack183
            DisableControlAction(0, 446, true) -- MeleeAttack184
            DisableControlAction(0, 447, true) -- MeleeAttack185
            DisableControlAction(0, 448, true) -- MeleeAttack186
            DisableControlAction(0, 449, true) -- MeleeAttack187
            DisableControlAction(0, 450, true) -- MeleeAttack188
            DisableControlAction(0, 451, true) -- MeleeAttack189
            DisableControlAction(0, 452, true) -- MeleeAttack190
            DisableControlAction(0, 453, true) -- MeleeAttack191
            DisableControlAction(0, 454, true) -- MeleeAttack192
            DisableControlAction(0, 455, true) -- MeleeAttack193
            DisableControlAction(0, 456, true) -- MeleeAttack194
            DisableControlAction(0, 457, true) -- MeleeAttack195
            DisableControlAction(0, 458, true) -- MeleeAttack196
            DisableControlAction(0, 459, true) -- MeleeAttack197
            DisableControlAction(0, 460, true) -- MeleeAttack198
            DisableControlAction(0, 461, true) -- MeleeAttack199
            DisableControlAction(0, 462, true) -- MeleeAttack200
            DisableControlAction(0, 463, true) -- MeleeAttack201
            DisableControlAction(0, 464, true) -- MeleeAttack202
            DisableControlAction(0, 465, true) -- MeleeAttack203
            DisableControlAction(0, 466, true) -- MeleeAttack204
            DisableControlAction(0, 467, true) -- MeleeAttack205
            DisableControlAction(0, 468, true) -- MeleeAttack206
            DisableControlAction(0, 469, true) -- MeleeAttack207
            DisableControlAction(0, 470, true) -- MeleeAttack208
            DisableControlAction(0, 471, true) -- MeleeAttack209
            DisableControlAction(0, 472, true) -- MeleeAttack210
            DisableControlAction(0, 473, true) -- MeleeAttack211
            DisableControlAction(0, 474, true) -- MeleeAttack212
            DisableControlAction(0, 475, true) -- MeleeAttack213
            DisableControlAction(0, 476, true) -- MeleeAttack214
            DisableControlAction(0, 477, true) -- MeleeAttack215
            DisableControlAction(0, 478, true) -- MeleeAttack216
            DisableControlAction(0, 479, true) -- MeleeAttack217
            DisableControlAction(0, 480, true) -- MeleeAttack218
            DisableControlAction(0, 481, true) -- MeleeAttack219
            DisableControlAction(0, 482, true) -- MeleeAttack220
            DisableControlAction(0, 483, true) -- MeleeAttack221
            DisableControlAction(0, 484, true) -- MeleeAttack222
            DisableControlAction(0, 485, true) -- MeleeAttack223
            DisableControlAction(0, 486, true) -- MeleeAttack224
            DisableControlAction(0, 487, true) -- MeleeAttack225
            DisableControlAction(0, 488, true) -- MeleeAttack226
            DisableControlAction(0, 489, true) -- MeleeAttack227
            DisableControlAction(0, 490, true) -- MeleeAttack228
            DisableControlAction(0, 491, true) -- MeleeAttack229
            DisableControlAction(0, 492, true) -- MeleeAttack230
            DisableControlAction(0, 493, true) -- MeleeAttack231
            DisableControlAction(0, 494, true) -- MeleeAttack232
            DisableControlAction(0, 495, true) -- MeleeAttack233
            DisableControlAction(0, 496, true) -- MeleeAttack234
            DisableControlAction(0, 497, true) -- MeleeAttack235
            DisableControlAction(0, 498, true) -- MeleeAttack236
            DisableControlAction(0, 499, true) -- MeleeAttack237
            DisableControlAction(0, 500, true) -- MeleeAttack238
            DisableControlAction(0, 501, true) -- MeleeAttack239
            DisableControlAction(0, 502, true) -- MeleeAttack240
            DisableControlAction(0, 503, true) -- MeleeAttack241
            DisableControlAction(0, 504, true) -- MeleeAttack242
            DisableControlAction(0, 505, true) -- MeleeAttack243
            DisableControlAction(0, 506, true) -- MeleeAttack244
            DisableControlAction(0, 507, true) -- MeleeAttack245
            DisableControlAction(0, 508, true) -- MeleeAttack246
            DisableControlAction(0, 509, true) -- MeleeAttack247
            DisableControlAction(0, 510, true) -- MeleeAttack248
            DisableControlAction(0, 511, true) -- MeleeAttack249
            DisableControlAction(0, 512, true) -- MeleeAttack250
            DisableControlAction(0, 513, true) -- MeleeAttack251
            DisableControlAction(0, 514, true) -- MeleeAttack252
            DisableControlAction(0, 515, true) -- MeleeAttack253
            DisableControlAction(0, 516, true) -- MeleeAttack254
            DisableControlAction(0, 517, true) -- MeleeAttack255
            DisableControlAction(0, 518, true) -- MeleeAttack256
            DisableControlAction(0, 519, true) -- MeleeAttack257
            DisableControlAction(0, 520, true) -- MeleeAttack258
            DisableControlAction(0, 521, true) -- MeleeAttack259
            DisableControlAction(0, 522, true) -- MeleeAttack260
            DisableControlAction(0, 523, true) -- MeleeAttack261
            DisableControlAction(0, 524, true) -- MeleeAttack262
            DisableControlAction(0, 525, true) -- MeleeAttack263
            DisableControlAction(0, 526, true) -- MeleeAttack264
            DisableControlAction(0, 527, true) -- MeleeAttack265
            DisableControlAction(0, 528, true) -- MeleeAttack266
            DisableControlAction(0, 529, true) -- MeleeAttack267
            DisableControlAction(0, 530, true) -- MeleeAttack268
            DisableControlAction(0, 531, true) -- MeleeAttack269
            DisableControlAction(0, 532, true) -- MeleeAttack270
            DisableControlAction(0, 533, true) -- MeleeAttack271
            DisableControlAction(0, 534, true) -- MeleeAttack272
            DisableControlAction(0, 535, true) -- MeleeAttack273
            DisableControlAction(0, 536, true) -- MeleeAttack274
            DisableControlAction(0, 537, true) -- MeleeAttack275
            DisableControlAction(0, 538, true) -- MeleeAttack276
            DisableControlAction(0, 539, true) -- MeleeAttack277
            DisableControlAction(0, 540, true) -- MeleeAttack278
            DisableControlAction(0, 541, true) -- MeleeAttack279
            DisableControlAction(0, 542, true) -- MeleeAttack280
            DisableControlAction(0, 543, true) -- MeleeAttack281
            DisableControlAction(0, 544, true) -- MeleeAttack282
            DisableControlAction(0, 545, true) -- MeleeAttack283
            DisableControlAction(0, 546, true) -- MeleeAttack284
            DisableControlAction(0, 547, true) -- MeleeAttack285
            DisableControlAction(0, 548, true) -- MeleeAttack286
            DisableControlAction(0, 549, true) -- MeleeAttack287
            DisableControlAction(0, 550, true) -- MeleeAttack288
            DisableControlAction(0, 551, true) -- MeleeAttack289
            DisableControlAction(0, 552, true) -- MeleeAttack290
            DisableControlAction(0, 553, true) -- MeleeAttack291
            DisableControlAction(0, 554, true) -- MeleeAttack292
            DisableControlAction(0, 555, true) -- MeleeAttack293
            DisableControlAction(0, 556, true) -- MeleeAttack294
            DisableControlAction(0, 557, true) -- MeleeAttack295
            DisableControlAction(0, 558, true) -- MeleeAttack296
            DisableControlAction(0, 559, true) -- MeleeAttack297
            DisableControlAction(0, 560, true) -- MeleeAttack298
            DisableControlAction(0, 561, true) -- MeleeAttack299
            DisableControlAction(0, 562, true) -- MeleeAttack300
            DisableControlAction(0, 563, true) -- MeleeAttack301
            DisableControlAction(0, 564, true) -- MeleeAttack302
            DisableControlAction(0, 565, true) -- MeleeAttack303
            DisableControlAction(0, 566, true) -- MeleeAttack304
            DisableControlAction(0, 567, true) -- MeleeAttack305
            DisableControlAction(0, 568, true) -- MeleeAttack306
            DisableControlAction(0, 569, true) -- MeleeAttack307
            DisableControlAction(0, 570, true) -- MeleeAttack308
            DisableControlAction(0, 571, true) -- MeleeAttack309
            DisableControlAction(0, 572, true) -- MeleeAttack310
            DisableControlAction(0, 573, true) -- MeleeAttack311
            DisableControlAction(0, 574, true) -- MeleeAttack312
            DisableControlAction(0, 575, true) -- MeleeAttack313
            DisableControlAction(0, 576, true) -- MeleeAttack314
            DisableControlAction(0, 577, true) -- MeleeAttack315
            DisableControlAction(0, 578, true) -- MeleeAttack316
            DisableControlAction(0, 579, true) -- MeleeAttack317
            DisableControlAction(0, 580, true) -- MeleeAttack318
            DisableControlAction(0, 581, true) -- MeleeAttack319
            DisableControlAction(0, 582, true) -- MeleeAttack320
            DisableControlAction(0, 583, true) -- MeleeAttack321
            DisableControlAction(0, 584, true) -- MeleeAttack322
            DisableControlAction(0, 585, true) -- MeleeAttack323
            DisableControlAction(0, 586, true) -- MeleeAttack324
            DisableControlAction(0, 587, true) -- MeleeAttack325
            DisableControlAction(0, 588, true) -- MeleeAttack326
            DisableControlAction(0, 589, true) -- MeleeAttack327
            DisableControlAction(0, 590, true) -- MeleeAttack328
            DisableControlAction(0, 591, true) -- MeleeAttack329
            DisableControlAction(0, 592, true) -- MeleeAttack330
            DisableControlAction(0, 593, true) -- MeleeAttack331
            DisableControlAction(0, 594, true) -- MeleeAttack332
            DisableControlAction(0, 595, true) -- MeleeAttack333
            DisableControlAction(0, 596, true) -- MeleeAttack334
            DisableControlAction(0, 597, true) -- MeleeAttack335
            DisableControlAction(0, 598, true) -- MeleeAttack336
            DisableControlAction(0, 599, true) -- MeleeAttack337
            DisableControlAction(0, 600, true) -- MeleeAttack338
            DisableControlAction(0, 601, true) -- MeleeAttack339
            DisableControlAction(0, 602, true) -- MeleeAttack340
            DisableControlAction(0, 603, true) -- MeleeAttack341
            DisableControlAction(0, 604, true) -- MeleeAttack342
            DisableControlAction(0, 605, true) -- MeleeAttack343
            DisableControlAction(0, 606, true) -- MeleeAttack344
            DisableControlAction(0, 607, true) -- MeleeAttack345
            DisableControlAction(0, 608, true) -- MeleeAttack346
            DisableControlAction(0, 609, true) -- MeleeAttack347
            DisableControlAction(0, 610, true) -- MeleeAttack348
            DisableControlAction(0, 611, true) -- MeleeAttack349
            DisableControlAction(0, 612, true) -- MeleeAttack350
            DisableControlAction(0, 613, true) -- MeleeAttack351
            DisableControlAction(0, 614, true) -- MeleeAttack352
            DisableControlAction(0, 615, true) -- MeleeAttack353
            DisableControlAction(0, 616, true) -- MeleeAttack354
            DisableControlAction(0, 617, true) -- MeleeAttack355
            DisableControlAction(0, 618, true) -- MeleeAttack356
            DisableControlAction(0, 619, true) -- MeleeAttack357
            DisableControlAction(0, 620, true) -- MeleeAttack358
            DisableControlAction(0, 621, true) -- MeleeAttack359
            DisableControlAction(0, 622, true) -- MeleeAttack360
            DisableControlAction(0, 623, true) -- MeleeAttack361
            DisableControlAction(0, 624, true) -- MeleeAttack362
            DisableControlAction(0, 625, true) -- MeleeAttack363
            DisableControlAction(0, 626, true) -- MeleeAttack364
            DisableControlAction(0, 627, true) -- MeleeAttack365
            DisableControlAction(0, 628, true) -- MeleeAttack366
            DisableControlAction(0, 629, true) -- MeleeAttack367
            DisableControlAction(0, 630, true) -- MeleeAttack368
            DisableControlAction(0, 631, true) -- MeleeAttack369
            DisableControlAction(0, 632, true) -- MeleeAttack370
            DisableControlAction(0, 633, true) -- MeleeAttack371
            DisableControlAction(0, 634, true) -- MeleeAttack372
            DisableControlAction(0, 635, true) -- MeleeAttack373
            DisableControlAction(0, 636, true) -- MeleeAttack374
            DisableControlAction(0, 637, true) -- MeleeAttack375
            DisableControlAction(0, 638, true) -- MeleeAttack376
            DisableControlAction(0, 639, true) -- MeleeAttack377
            DisableControlAction(0, 640, true) -- MeleeAttack378
            DisableControlAction(0, 641, true) -- MeleeAttack379
            DisableControlAction(0, 642, true) -- MeleeAttack380
            DisableControlAction(0, 643, true) -- MeleeAttack381
            DisableControlAction(0, 644, true) -- MeleeAttack382
            DisableControlAction(0, 645, true) -- MeleeAttack383
            DisableControlAction(0, 646, true) -- MeleeAttack384
            DisableControlAction(0, 647, true) -- MeleeAttack385
            DisableControlAction(0, 648, true) -- MeleeAttack386
            DisableControlAction(0, 649, true) -- MeleeAttack387
            DisableControlAction(0, 650, true) -- MeleeAttack388
            DisableControlAction(0, 651, true) -- MeleeAttack389
            DisableControlAction(0, 652, true) -- MeleeAttack390
            DisableControlAction(0, 653, true) -- MeleeAttack391
            DisableControlAction(0, 654, true) -- MeleeAttack392
            DisableControlAction(0, 655, true) -- MeleeAttack393
            DisableControlAction(0, 656, true) -- MeleeAttack394
            DisableControlAction(0, 657, true) -- MeleeAttack395
            DisableControlAction(0, 658, true) -- MeleeAttack396
            DisableControlAction(0, 659, true) -- MeleeAttack397
            DisableControlAction(0, 660, true) -- MeleeAttack398
            DisableControlAction(0, 661, true) -- MeleeAttack399
            DisableControlAction(0, 662, true) -- MeleeAttack400
            DisableControlAction(0, 663, true) -- MeleeAttack401
            DisableControlAction(0, 664, true) -- MeleeAttack402
            DisableControlAction(0, 665, true) -- MeleeAttack403
            DisableControlAction(0, 666, true) -- MeleeAttack404
            DisableControlAction(0, 667, true) -- MeleeAttack405
            DisableControlAction(0, 668, true) -- MeleeAttack406
            DisableControlAction(0, 669, true) -- MeleeAttack407
            DisableControlAction(0, 670, true) -- MeleeAttack408
            DisableControlAction(0, 671, true) -- MeleeAttack409
            DisableControlAction(0, 672, true) -- MeleeAttack410
            DisableControlAction(0, 673, true) -- MeleeAttack411
            DisableControlAction(0, 674, true) -- MeleeAttack412
            DisableControlAction(0, 675, true) -- MeleeAttack413
            DisableControlAction(0, 676, true) -- MeleeAttack414
            DisableControlAction(0, 677, true) -- MeleeAttack415
            DisableControlAction(0, 678, true) -- MeleeAttack416
            DisableControlAction(0, 679, true) -- MeleeAttack417
            DisableControlAction(0, 680, true) -- MeleeAttack418
            DisableControlAction(0, 681, true) -- MeleeAttack419
            DisableControlAction(0, 682, true) -- MeleeAttack420
            DisableControlAction(0, 683, true) -- MeleeAttack421
            DisableControlAction(0, 684, true) -- MeleeAttack422
            DisableControlAction(0, 685, true) -- MeleeAttack423
            DisableControlAction(0, 686, true) -- MeleeAttack424
            DisableControlAction(0, 687, true) -- MeleeAttack425
            DisableControlAction(0, 688, true) -- MeleeAttack426
            DisableControlAction(0, 689, true) -- MeleeAttack427
            DisableControlAction(0, 690, true) -- MeleeAttack428
            DisableControlAction(0, 691, true) -- MeleeAttack429
            DisableControlAction(0, 692, true) -- MeleeAttack430
            DisableControlAction(0, 693, true) -- MeleeAttack431
            DisableControlAction(0, 694, true) -- MeleeAttack432
            DisableControlAction(0, 695, true) -- MeleeAttack433
            DisableControlAction(0, 696, true) -- MeleeAttack434
            DisableControlAction(0, 697, true) -- MeleeAttack435
            DisableControlAction(0, 698, true) -- MeleeAttack436
            DisableControlAction(0, 699, true) -- MeleeAttack437
            DisableControlAction(0, 700, true) -- MeleeAttack438
            DisableControlAction(0, 701, true) -- MeleeAttack439
            DisableControlAction(0, 702, true) -- MeleeAttack440
            DisableControlAction(0, 703, true) -- MeleeAttack441
            DisableControlAction(0, 704, true) -- MeleeAttack442
            DisableControlAction(0, 705, true) -- MeleeAttack443
            DisableControlAction(0, 706, true) -- MeleeAttack444
            DisableControlAction(0, 707, true) -- MeleeAttack445
            DisableControlAction(0, 708, true) -- MeleeAttack446
            DisableControlAction(0, 709, true) -- MeleeAttack447
            DisableControlAction(0, 710, true) -- MeleeAttack448
            DisableControlAction(0, 711, true) -- MeleeAttack449
            DisableControlAction(0, 712, true) -- MeleeAttack450
            DisableControlAction(0, 713, true) -- MeleeAttack451
            DisableControlAction(0, 714, true) -- MeleeAttack452
            DisableControlAction(0, 715, true) -- MeleeAttack453
            DisableControlAction(0, 716, true) -- MeleeAttack454
            DisableControlAction(0, 717, true) -- MeleeAttack455
            DisableControlAction(0, 718, true) -- MeleeAttack456
            DisableControlAction(0, 719, true) -- MeleeAttack457
            DisableControlAction(0, 720, true) -- MeleeAttack458
            DisableControlAction(0, 721, true) -- MeleeAttack459
            DisableControlAction(0, 722, true) -- MeleeAttack460
            DisableControlAction(0, 723, true) -- MeleeAttack461
            DisableControlAction(0, 724, true) -- MeleeAttack462
            DisableControlAction(0, 725, true) -- MeleeAttack463
            DisableControlAction(0, 726, true) -- MeleeAttack464
            DisableControlAction(0, 727, true) -- MeleeAttack465
            DisableControlAction(0, 728, true) -- MeleeAttack466
            DisableControlAction(0, 729, true) -- MeleeAttack467
            DisableControlAction(0, 730, true) -- MeleeAttack468
            DisableControlAction(0, 731, true) -- MeleeAttack469
            DisableControlAction(0, 732, true) -- MeleeAttack470
            DisableControlAction(0, 733, true) -- MeleeAttack471
            DisableControlAction(0, 734, true) -- MeleeAttack472
            DisableControlAction(0, 735, true) -- MeleeAttack473
            DisableControlAction(0, 736, true) -- MeleeAttack474
            DisableControlAction(0, 737, true) -- MeleeAttack475
            DisableControlAction(0, 738, true) -- MeleeAttack476
            DisableControlAction(0, 739, true) -- MeleeAttack477
            DisableControlAction(0, 740, true) -- MeleeAttack478
            DisableControlAction(0, 741, true) -- MeleeAttack479
            DisableControlAction(0, 742, true) -- MeleeAttack480
            DisableControlAction(0, 743, true) -- MeleeAttack481
            DisableControlAction(0, 744, true) -- MeleeAttack482
            DisableControlAction(0, 745, true) -- MeleeAttack483
            DisableControlAction(0, 746, true) -- MeleeAttack484
            DisableControlAction(0, 747, true) -- MeleeAttack485
            DisableControlAction(0, 748, true) -- MeleeAttack486
            DisableControlAction(0, 749, true) -- MeleeAttack487
            DisableControlAction(0, 750, true) -- MeleeAttack488
            DisableControlAction(0, 751, true) -- MeleeAttack489
            DisableControlAction(0, 752, true) -- MeleeAttack490
            DisableControlAction(0, 753, true) -- MeleeAttack491
            DisableControlAction(0, 754, true) -- MeleeAttack492
            DisableControlAction(0, 755, true) -- MeleeAttack493
            DisableControlAction(0, 756, true) -- MeleeAttack494
            DisableControlAction(0, 757, true) -- MeleeAttack495
            DisableControlAction(0, 758, true) -- MeleeAttack496
            DisableControlAction(0, 759, true) -- MeleeAttack497
            DisableControlAction(0, 760, true) -- MeleeAttack498
            DisableControlAction(0, 761, true) -- MeleeAttack499
            DisableControlAction(0, 762, true) -- MeleeAttack500
            DisableControlAction(0, 763, true) -- MeleeAttack501
            DisableControlAction(0, 764, true) -- MeleeAttack502
            DisableControlAction(0, 765, true) -- MeleeAttack503
            DisableControlAction(0, 766, true) -- MeleeAttack504
            DisableControlAction(0, 767, true) -- MeleeAttack505
            DisableControlAction(0, 768, true) -- MeleeAttack506
            DisableControlAction(0, 769, true) -- MeleeAttack507
            DisableControlAction(0, 770, true) -- MeleeAttack508
            DisableControlAction(0, 771, true) -- MeleeAttack509
            DisableControlAction(0, 772, true) -- MeleeAttack510
            DisableControlAction(0, 773, true) -- MeleeAttack511
            DisableControlAction(0, 774, true) -- MeleeAttack512
            DisableControlAction(0, 775, true) -- MeleeAttack513
            DisableControlAction(0, 776, true) -- MeleeAttack514
            DisableControlAction(0, 777, true) -- MeleeAttack515
            DisableControlAction(0, 778, true) -- MeleeAttack516
            DisableControlAction(0, 779, true) -- MeleeAttack517
            DisableControlAction(0, 780, true) -- MeleeAttack518
            DisableControlAction(0, 781, true) -- MeleeAttack519
            DisableControlAction(0, 782, true) -- MeleeAttack520
            DisableControlAction(0, 783, true) -- MeleeAttack521
            DisableControlAction(0, 784, true) -- MeleeAttack522
            DisableControlAction(0, 785, true) -- MeleeAttack523
            DisableControlAction(0, 786, true) -- MeleeAttack524
            DisableControlAction(0, 787, true) -- MeleeAttack525
            DisableControlAction(0, 788, true) -- MeleeAttack526
            DisableControlAction(0, 789, true) -- MeleeAttack527
            DisableControlAction(0, 790, true) -- MeleeAttack528
            DisableControlAction(0, 791, true) -- MeleeAttack529
            DisableControlAction(0, 792, true) -- MeleeAttack530
            DisableControlAction(0, 793, true) -- MeleeAttack531
            DisableControlAction(0, 794, true) -- MeleeAttack532
            DisableControlAction(0, 795, true) -- MeleeAttack533
            DisableControlAction(0, 796, true) -- MeleeAttack534
            DisableControlAction(0, 797, true) -- MeleeAttack535
            DisableControlAction(0, 798, true) -- MeleeAttack536
            DisableControlAction(0, 799, true) -- MeleeAttack537
            DisableControlAction(0, 800, true) -- MeleeAttack538
            DisableControlAction(0, 801, true) -- MeleeAttack539
            DisableControlAction(0, 802, true) -- MeleeAttack540
            DisableControlAction(0, 803, true) -- MeleeAttack541
            DisableControlAction(0, 804, true) -- MeleeAttack542
            DisableControlAction(0, 805, true) -- MeleeAttack543
            DisableControlAction(0, 806, true) -- MeleeAttack544
            DisableControlAction(0, 807, true) -- MeleeAttack545
            DisableControlAction(0, 808, true) -- MeleeAttack546
            DisableControlAction(0, 809, true) -- MeleeAttack547
            DisableControlAction(0, 810, true) -- MeleeAttack548
            DisableControlAction(0, 811, true) -- MeleeAttack549
            DisableControlAction(0, 812, true) -- MeleeAttack550
            DisableControlAction(0, 813, true) -- MeleeAttack551
            DisableControlAction(0, 814, true) -- MeleeAttack552
            DisableControlAction(0, 815, true) -- MeleeAttack553
            DisableControlAction(0, 816, true) -- MeleeAttack554
            DisableControlAction(0, 817, true) -- MeleeAttack555
            DisableControlAction(0, 818, true) -- MeleeAttack556
            DisableControlAction(0, 819, true) -- MeleeAttack557
            DisableControlAction(0, 820, true) -- MeleeAttack558
            DisableControlAction(0, 821, true) -- MeleeAttack559
            DisableControlAction(0, 822, true) -- MeleeAttack560
            DisableControlAction(0, 823, true) -- MeleeAttack561
            DisableControlAction(0, 824, true) -- MeleeAttack562
            DisableControlAction(0, 825, true) -- MeleeAttack563
            DisableControlAction(0, 826, true) -- MeleeAttack564
            DisableControlAction(0, 827, true) -- MeleeAttack565
            DisableControlAction(0, 828, true) -- MeleeAttack566
            DisableControlAction(0, 829, true) -- MeleeAttack567
            DisableControlAction(0, 830, true) -- MeleeAttack568
            DisableControlAction(0, 831, true) -- MeleeAttack569
            DisableControlAction(0, 832, true) -- MeleeAttack570
            DisableControlAction(0, 833, true) -- MeleeAttack571
            DisableControlAction(0, 834, true) -- MeleeAttack572
            DisableControlAction(0, 835, true) -- MeleeAttack573
            DisableControlAction(0, 836, true) -- MeleeAttack574
            DisableControlAction(0, 837, true) -- MeleeAttack575
            DisableControlAction(0, 838, true) -- MeleeAttack576
            DisableControlAction(0, 839, true) -- MeleeAttack577
            DisableControlAction(0, 840, true) -- MeleeAttack578
            DisableControlAction(0, 841, true) -- MeleeAttack579
            DisableControlAction(0, 842, true) -- MeleeAttack580
            DisableControlAction(0, 843, true) -- MeleeAttack581
            DisableControlAction(0, 844, true) -- MeleeAttack582
            DisableControlAction(0, 845, true) -- MeleeAttack583
            DisableControlAction(0, 846, true) -- MeleeAttack584
            DisableControlAction(0, 847, true) -- MeleeAttack585
            DisableControlAction(0, 848, true) -- MeleeAttack586
            DisableControlAction(0, 849, true) -- MeleeAttack587
            DisableControlAction(0, 850, true) -- MeleeAttack588
            DisableControlAction(0, 851, true) -- MeleeAttack589
            DisableControlAction(0, 852, true) -- MeleeAttack590
            DisableControlAction(0, 853, true) -- MeleeAttack591
            DisableControlAction(0, 854, true) -- MeleeAttack592
            DisableControlAction(0, 855, true) -- MeleeAttack593
            DisableControlAction(0, 856, true) -- MeleeAttack594
            DisableControlAction(0, 857, true) -- MeleeAttack595
            DisableControlAction(0, 858, true) -- MeleeAttack596
            DisableControlAction(0, 859, true) -- MeleeAttack597
            DisableControlAction(0, 860, true) -- MeleeAttack598
            DisableControlAction(0, 861, true) -- MeleeAttack599
            DisableControlAction(0, 862, true) -- MeleeAttack600
            DisableControlAction(0, 863, true) -- MeleeAttack601
            DisableControlAction(0, 864, true) -- MeleeAttack602
            DisableControlAction(0, 865, true) -- MeleeAttack603
            DisableControlAction(0, 866, true) -- MeleeAttack604
            DisableControlAction(0, 867, true) -- MeleeAttack605
            DisableControlAction(0, 868, true) -- MeleeAttack606
            DisableControlAction(0, 869, true) -- MeleeAttack607
            DisableControlAction(0, 870, true) -- MeleeAttack608
            DisableControlAction(0, 871, true) -- MeleeAttack609
            DisableControlAction(0, 872, true) -- MeleeAttack610
            DisableControlAction(0, 873, true) -- MeleeAttack611
            DisableControlAction(0, 874, true) -- MeleeAttack612
            DisableControlAction(0, 875, true) -- MeleeAttack613
            DisableControlAction(0, 876, true) -- MeleeAttack614
            DisableControlAction(0, 877, true) -- MeleeAttack615
            DisableControlAction(0, 878, true) -- MeleeAttack616
            DisableControlAction(0, 879, true) -- MeleeAttack617
            DisableControlAction(0, 880, true) -- MeleeAttack618
            DisableControlAction(0, 881, true) -- MeleeAttack619
            DisableControlAction(0, 882, true) -- MeleeAttack620
            DisableControlAction(0, 883, true) -- MeleeAttack621
            DisableControlAction(0, 884, true) -- MeleeAttack622
            DisableControlAction(0, 885, true) -- MeleeAttack623
            DisableControlAction(0, 886, true) -- MeleeAttack624
            DisableControlAction(0, 887, true) -- MeleeAttack625
            DisableControlAction(0, 888, true) -- MeleeAttack626
            DisableControlAction(0, 889, true) -- MeleeAttack627
            DisableControlAction(0, 890, true) -- MeleeAttack628
            DisableControlAction(0, 891, true) -- MeleeAttack629
            DisableControlAction(0, 892, true) -- MeleeAttack630
            DisableControlAction(0, 893, true) -- MeleeAttack631
            DisableControlAction(0, 894, true) -- MeleeAttack632
            DisableControlAction(0, 895, true) -- MeleeAttack633
            DisableControlAction(0, 896, true) -- MeleeAttack634
            DisableControlAction(0, 897, true) -- MeleeAttack635
            DisableControlAction(0, 898, true) -- MeleeAttack636
            DisableControlAction(0, 899, true) -- MeleeAttack637
            DisableControlAction(0, 900, true) -- MeleeAttack638
            DisableControlAction(0, 901, true) -- MeleeAttack639
            DisableControlAction(0, 902, true) -- MeleeAttack640
            DisableControlAction(0, 903, true) -- MeleeAttack641
            DisableControlAction(0, 904, true) -- MeleeAttack642
            DisableControlAction(0, 905, true) -- MeleeAttack643
            DisableControlAction(0, 906, true) -- MeleeAttack644
            DisableControlAction(0, 907, true) -- MeleeAttack645
            DisableControlAction(0, 908, true) -- MeleeAttack646
            DisableControlAction(0, 909, true) -- MeleeAttack647
            DisableControlAction(0, 910, true) -- MeleeAttack648
            DisableControlAction(0, 911, true) -- MeleeAttack649
            DisableControlAction(0, 912, true) -- MeleeAttack650
            DisableControlAction(0, 913, true) -- MeleeAttack651
            DisableControlAction(0, 914, true) -- MeleeAttack652
            DisableControlAction(0, 915, true) -- MeleeAttack653
            DisableControlAction(0, 916, true) -- MeleeAttack654
            DisableControlAction(0, 917, true) -- MeleeAttack655
            DisableControlAction(0, 918, true) -- MeleeAttack656
            DisableControlAction(0, 919, true) -- MeleeAttack657
            DisableControlAction(0, 920, true) -- MeleeAttack658
            DisableControlAction(0, 921, true) -- MeleeAttack659
            DisableControlAction(0, 922, true) -- MeleeAttack660
            DisableControlAction(0, 923, true) -- MeleeAttack661
            DisableControlAction(0, 924, true) -- MeleeAttack662
            DisableControlAction(0, 925, true) -- MeleeAttack663
            DisableControlAction(0, 926, true) -- MeleeAttack664
            DisableControlAction(0, 927, true) -- MeleeAttack665
            DisableControlAction(0, 928, true) -- MeleeAttack666
            DisableControlAction(0, 929, true) -- MeleeAttack667
            DisableControlAction(0, 930, true) -- MeleeAttack668
            DisableControlAction(0, 931, true) -- MeleeAttack669
            DisableControlAction(0, 932, true) -- MeleeAttack670
            DisableControlAction(0, 933, true) -- MeleeAttack671
            DisableControlAction(0, 934, true) -- MeleeAttack672
            DisableControlAction(0, 935, true) -- MeleeAttack673
            DisableControlAction(0, 936, true) -- MeleeAttack674
            DisableControlAction(0, 937, true) -- MeleeAttack675
            DisableControlAction(0, 938, true) -- MeleeAttack676
            DisableControlAction(0, 939, true) -- MeleeAttack677
            DisableControlAction(0, 940, true) -- MeleeAttack678
            DisableControlAction(0, 941, true) -- MeleeAttack679
            DisableControlAction(0, 942, true) -- MeleeAttack680
            DisableControlAction(0, 943, true) -- MeleeAttack681
            DisableControlAction(0, 944, true) -- MeleeAttack682
            DisableControlAction(0, 945, true) -- MeleeAttack683
            DisableControlAction(0, 946, true) -- MeleeAttack684
            DisableControlAction(0, 947, true) -- MeleeAttack685
            DisableControlAction(0, 948, true) -- MeleeAttack686
            DisableControlAction(0, 949, true) -- MeleeAttack687
            DisableControlAction(0, 950, true) -- MeleeAttack688
            DisableControlAction(0, 951, true) -- MeleeAttack689
            DisableControlAction(0, 952, true) -- MeleeAttack690
            DisableControlAction(0, 953, true) -- MeleeAttack691
            DisableControlAction(0, 954, true) -- MeleeAttack692
            DisableControlAction(0, 955, true) -- MeleeAttack693
            DisableControlAction(0, 956, true) -- MeleeAttack694
            DisableControlAction(0, 957, true) -- MeleeAttack695
            DisableControlAction(0, 958, true) -- MeleeAttack696
            DisableControlAction(0, 959, true) -- MeleeAttack697
            DisableControlAction(0, 960, true) -- MeleeAttack698
            DisableControlAction(0, 961, true) -- MeleeAttack699
            DisableControlAction(0, 962, true) -- MeleeAttack700
            DisableControlAction(0, 963, true) -- MeleeAttack701
            DisableControlAction(0, 964, true) -- MeleeAttack702
            DisableControlAction(0, 965, true) -- MeleeAttack703
            DisableControlAction(0, 966, true) -- MeleeAttack704
            DisableControlAction(0, 967, true) -- MeleeAttack705
            DisableControlAction(0, 968, true) -- MeleeAttack706
            DisableControlAction(0, 969, true) -- MeleeAttack707
            DisableControlAction(0, 970, true) -- MeleeAttack708
            DisableControlAction(0, 971, true) -- MeleeAttack709
            DisableControlAction(0, 972, true) -- MeleeAttack710
            DisableControlAction(0, 973, true) -- MeleeAttack711
            DisableControlAction(0, 974, true) -- MeleeAttack712
            DisableControlAction(0, 975, true) -- MeleeAttack713
            DisableControlAction(0, 976, true) -- MeleeAttack714
            DisableControlAction(0, 977, true) -- MeleeAttack715
            DisableControlAction(0, 978, true) -- MeleeAttack716
            DisableControlAction(0, 979, true) -- MeleeAttack717
            DisableControlAction(0, 980, true) -- MeleeAttack718
            DisableControlAction(0, 981, true) -- MeleeAttack719
            DisableControlAction(0, 982, true) -- MeleeAttack720
            DisableControlAction(0, 983, true) -- MeleeAttack721
            DisableControlAction(0, 984, true) -- MeleeAttack722
            DisableControlAction(0, 985, true) -- MeleeAttack723
            DisableControlAction(0, 986, true) -- MeleeAttack724
            DisableControlAction(0, 987, true) -- MeleeAttack725
            DisableControlAction(0, 988, true) -- MeleeAttack726
            DisableControlAction(0, 989, true) -- MeleeAttack727
            DisableControlAction(0, 990, true) -- MeleeAttack728
            DisableControlAction(0, 991, true) -- MeleeAttack729
            DisableControlAction(0, 992, true) -- MeleeAttack730
            DisableControlAction(0, 993, true) -- MeleeAttack731
            DisableControlAction(0, 994, true) -- MeleeAttack732
            DisableControlAction(0, 995, true) -- MeleeAttack733
            DisableControlAction(0, 996, true) -- MeleeAttack734
            DisableControlAction(0, 997, true) -- MeleeAttack735
            DisableControlAction(0, 998, true) -- MeleeAttack736
            DisableControlAction(0, 999, true) -- MeleeAttack737
            DisableControlAction(0, 1000, true) -- MeleeAttack738
            DisableControlAction(0, 1001, true) -- MeleeAttack739
            DisableControlAction(0, 1002, true) -- MeleeAttack740
            DisableControlAction(0, 1003, true) -- MeleeAttack741
            DisableControlAction(0, 1004, true) -- MeleeAttack742
            DisableControlAction(0, 1005, true) -- MeleeAttack743
            DisableControlAction(0, 1006, true) -- MeleeAttack744
            DisableControlAction(0, 1007, true) -- MeleeAttack745
            DisableControlAction(0, 1008, true) -- MeleeAttack746
            DisableControlAction(0, 1009, true) -- MeleeAttack747
            DisableControlAction(0, 1010, true) -- MeleeAttack748
            DisableControlAction(0, 1011, true) -- MeleeAttack749
            DisableControlAction(0, 1012, true) -- MeleeAttack750
            DisableControlAction(0, 1013, true) -- MeleeAttack751
            DisableControlAction(0, 1014, true) -- MeleeAttack752
            DisableControlAction(0, 1015, true) -- MeleeAttack753
            DisableControlAction(0, 1016, true) -- MeleeAttack754
            DisableControlAction(0, 1017, true) -- MeleeAttack755
            DisableControlAction(0, 1018, true) -- MeleeAttack756
            DisableControlAction(0, 1019, true) -- MeleeAttack757
            DisableControlAction(0, 1020, true) -- MeleeAttack758
            DisableControlAction(0, 1021, true) -- MeleeAttack759
            DisableControlAction(0, 1022, true) -- MeleeAttack760
            DisableControlAction(0, 1023, true) -- MeleeAttack761
            DisableControlAction(0, 1024, true) -- MeleeAttack762
            DisableControlAction(0, 1025, true) -- MeleeAttack763
            DisableControlAction(0, 1026, true) -- MeleeAttack764
            DisableControlAction(0, 1027, true) -- MeleeAttack765
            DisableControlAction(0, 1028, true) -- MeleeAttack766
            DisableControlAction(0, 1029, true) -- MeleeAttack767
            DisableControlAction(0, 1030, true) -- MeleeAttack768
            DisableControlAction(0, 1031, true) -- MeleeAttack769
            DisableControlAction(0, 1032, true) -- MeleeAttack770
            DisableControlAction(0,  1033, true) -- MeleeAttack771
            DisableControlAction(0, 1034, true) -- MeleeAttack772
            DisableControlAction(0, 1035, true) -- MeleeAttack773
            DisableControlAction(0, 1036, true) -- MeleeAttack774
            DisableControlAction(0, 1037, true) -- MeleeAttack775
            DisableControlAction(0, 1038, true) -- MeleeAttack776
            DisableControlAction(0, 1039, true) -- MeleeAttack777
            DisableControlAction(0, 1040, true) -- MeleeAttack778
            DisableControlAction(0, 1041, true) -- MeleeAttack779
            DisableControlAction(0, 1042, true) -- MeleeAttack780
            DisableControlAction(0, 1043, true) -- MeleeAttack781
            DisableControlAction(0, 1044, true) -- MeleeAttack782
            DisableControlAction(0, 1045, true) -- MeleeAttack783
            DisableControlAction(0, 1046, true) -- MeleeAttack784
            DisableControlAction(0, 1047, true) -- MeleeAttack785
            DisableControlAction(0, 1048, true) -- MeleeAttack786
            DisableControlAction(0, 1049, true) -- MeleeAttack787
            DisableControlAction(0, 1050, true) -- MeleeAttack788
            DisableControlAction(0, 1051, true) -- MeleeAttack789
            DisableControlAction(0, 1052, true) -- MeleeAttack790
            DisableControlAction(0, 1053, true) -- MeleeAttack791
            DisableControlAction(0, 1054, true) -- MeleeAttack792
            DisableControlAction(0, 1055, true) -- MeleeAttack793
            DisableControlAction(0, 1056, true) -- MeleeAttack794
            DisableControlAction(0, 1057, true) -- MeleeAttack795
            DisableControlAction(0, 1058, true) -- MeleeAttack796
            DisableControlAction(0, 1059, true) -- MeleeAttack797
            DisableControlAction(0, 1060, true) -- MeleeAttack798
            DisableControlAction(0, 1061, true) -- MeleeAttack799
            DisableControlAction(0, 1062, true) -- MeleeAttack800
            DisableControlAction(0, 1063, true) -- MeleeAttack801
            DisableControlAction(0, 1064, true) -- MeleeAttack802
            DisableControlAction(0, 1065, true) -- MeleeAttack803
            DisableControlAction(0, 1066, true) -- MeleeAttack804
            DisableControlAction(0, 1067, true) -- MeleeAttack805
            DisableControlAction(0, 1068, true) -- MeleeAttack806
            DisableControlAction(0, 1069, true) -- MeleeAttack807
            DisableControlAction(0, 1070, true) -- MeleeAttack808
            DisableControlAction(0, 1071, true) -- MeleeAttack809
            DisableControlAction(0, 1072, true) -- MeleeAttack810
            DisableControlAction(0, 1073, true) -- MeleeAttack811
            DisableControlAction(0, 1074, true) -- MeleeAttack812
            DisableControlAction(0, 1075, true) -- MeleeAttack813
            DisableControlAction(0, 1076, true) -- MeleeAttack814
            DisableControlAction(0, 1077, true) -- MeleeAttack815
            DisableControlAction(0, 1078, true) -- MeleeAttack816
            DisableControlAction(0, 1079, true) -- MeleeAttack817
            DisableControlAction(0, 1080, true) -- MeleeAttack818
            DisableControlAction(0, 1081, true) -- MeleeAttack819
            DisableControlAction(0, 1082, true) -- MeleeAttack820
            DisableControlAction(0, 1083, true) -- MeleeAttack821
            DisableControlAction(0, 1084, true) -- MeleeAttack822
            DisableControlAction(0, 1085, true) -- MeleeAttack823
            DisableControlAction(0, 1086, true) -- MeleeAttack824
            DisableControlAction(0, 1087, true) -- MeleeAttack825
            DisableControlAction(0, 1088, true) -- MeleeAttack826
            DisableControlAction(0, 1089, true) -- MeleeAttack827
            DisableControlAction(0, 1090, true) -- MeleeAttack828
            DisableControlAction(0, 1091, true) -- MeleeAttack829
            DisableControlAction(0, 1092, true) -- MeleeAttack830
            DisableControlAction(0, 1093, true) -- MeleeAttack831
            DisableControlAction(0, 1094, true) -- MeleeAttack832
            DisableControlAction(0, 1095, true) -- MeleeAttack833
            DisableControlAction(0, 1096, true) -- MeleeAttack834
            DisableControlAction(0, 1097, true) -- MeleeAttack835
            DisableControlAction(0, 1098, true) -- MeleeAttack836
            DisableControlAction(0, 1099, true) -- MeleeAttack837
            DisableControlAction(0, 1100, true) -- MeleeAttack838
            DisableControlAction(0, 1101, true) -- MeleeAttack839
            DisableControlAction(0, 1102, true) -- MeleeAttack840
            DisableControlAction(0, 1103, true) -- MeleeAttack841
            DisableControlAction(0, 1104, true) -- MeleeAttack842
            DisableControlAction(0, 1105, true) -- MeleeAttack843
            DisableControlAction(0, 1106, true) -- MeleeAttack844
            DisableControlAction(0, 1107, true) -- MeleeAttack845
            DisableControlAction(0, 1108, true) -- MeleeAttack846
            DisableControlAction(0, 1109, true) -- MeleeAttack847
            DisableControlAction(0, 1110, true) -- MeleeAttack848
            DisableControlAction(0, 1111, true) -- MeleeAttack849
            DisableControlAction(0, 1112, true) -- MeleeAttack850
            DisableControlAction(0, 1113, true) -- MeleeAttack851
            DisableControlAction(0, 1114, true) -- MeleeAttack852
            DisableControlAction(0, 1115, true) -- MeleeAttack853
            DisableControlAction(0, 1116, true) -- MeleeAttack854
            DisableControlAction(0, 1117, true) -- MeleeAttack855
            DisableControlAction(0, 1118, true) -- MeleeAttack856
            DisableControlAction(0, 1119, true) -- MeleeAttack857
            DisableControlAction(0, 1120, true) -- MeleeAttack858
            DisableControlAction(0, 1121, true) -- MeleeAttack859
            DisableControlAction(0, 1122, true) -- MeleeAttack860
            DisableControlAction(0, 1123, true) -- MeleeAttack861
            DisableControlAction(0, 1124, true) -- MeleeAttack862
            DisableControlAction(0, 1125, true) -- MeleeAttack863
            DisableControlAction(0, 1126, true) -- MeleeAttack864
            DisableControlAction(0, 1127, true) -- MeleeAttack865
            DisableControlAction(0, 1128, true) -- MeleeAttack866
            DisableControlAction(0, 1129, true) -- MeleeAttack867
            DisableControlAction(0, 1130, true) -- MeleeAttack868
            DisableControlAction(0, 1131, true) -- MeleeAttack869
            DisableControlAction(0, 1132, true) -- MeleeAttack870
            DisableControlAction(0, 1133, true) -- MeleeAttack871
            DisableControlAction(0, 1134, true) -- MeleeAttack872
            DisableControlAction(0, 1135, true) -- MeleeAttack873
            DisableControlAction(0, 1136, true) -- MeleeAttack874
            DisableControlAction(0, 1137, true) -- MeleeAttack875
            DisableControlAction(0, 1138, true) -- MeleeAttack876
            DisableControlAction(0, 1139, true) -- MeleeAttack877
            DisableControlAction(0, 1140, true) -- MeleeAttack878
            DisableControlAction(0, 1141, true) -- MeleeAttack879
            DisableControlAction(0, 1142, true) -- MeleeAttack880
            DisableControlAction(0, 1143, true) -- MeleeAttack881
            DisableControlAction(0, 1144, true) -- MeleeAttack882
            DisableControlAction(0, 1145, true) -- MeleeAttack883
            DisableControlAction(0, 1146, true) -- MeleeAttack884
            DisableControlAction(0, 1147, true) -- MeleeAttack885
            DisableControlAction(0, 1148, true) -- MeleeAttack886
            DisableControlAction(0, 1149, true) -- MeleeAttack887
            DisableControlAction(0, 1150, true) -- MeleeAttack888
            DisableControlAction(0, 1151, true) -- MeleeAttack889
            DisableControlAction(0, 1152, true) -- MeleeAttack890
            DisableControlAction(0, 1153, true) -- MeleeAttack891
            DisableControlAction(0, 1154, true) -- MeleeAttack892
            DisableControlAction(0, 1155, true) -- MeleeAttack893
            DisableControlAction(0, 1156, true) -- MeleeAttack894
            DisableControlAction(0, 1157, true) -- MeleeAttack895
            DisableControlAction(0, 1158, true) -- MeleeAttack896
            DisableControlAction(0, 1159, true) -- MeleeAttack897
            DisableControlAction(0, 1160, true) -- MeleeAttack898
            DisableControlAction(0, 1161, true) -- MeleeAttack899
            DisableControlAction(0, 1162, true) -- MeleeAttack900
            DisableControlAction(0, 1163, true) -- MeleeAttack901
            DisableControlAction(0, 1164, true) -- MeleeAttack902
            DisableControlAction(0, 1165, true) -- MeleeAttack903
            DisableControlAction(0, 1166, true) -- MeleeAttack904
            DisableControlAction(0, 1167, true) -- MeleeAttack905
            DisableControlAction(0, 1168, true) -- MeleeAttack906
            DisableControlAction(0, 1169, true) -- MeleeAttack907
            DisableControlAction(0, 1170, true) -- MeleeAttack908
            DisableControlAction(0, 1171, true) -- MeleeAttack909
            DisableControlAction(0, 1172, true) -- MeleeAttack910
            DisableControlAction(0, 1173, true) -- MeleeAttack911
            DisableControlAction(0, 1174, true) -- MeleeAttack912
            DisableControlAction(0, 1175, true) -- MeleeAttack913
            DisableControlAction(0, 1176, true) -- MeleeAttack914
            DisableControlAction(0, 1177, true) -- MeleeAttack915
            DisableControlAction(0, 1178, true) -- MeleeAttack916
            DisableControlAction(0, 1179, true) -- MeleeAttack917
            DisableControlAction(0, 1180, true) -- MeleeAttack918
            DisableControlAction(0, 1181, true) -- MeleeAttack919
            DisableControlAction(0, 1182, true) -- MeleeAttack920
            DisableControlAction(0, 1183, true) -- MeleeAttack921
            DisableControlAction(0, 1184, true) -- MeleeAttack922
            DisableControlAction(0, 1185, true) -- MeleeAttack923
            DisableControlAction(0, 1186, true) -- MeleeAttack924
            DisableControlAction(0, 1187, true) -- MeleeAttack925
            DisableControlAction(0, 1188, true) -- MeleeAttack926
            DisableControlAction(0, 1189, true) -- MeleeAttack927
            DisableControlAction(0, 1190, true) -- MeleeAttack928
            DisableControlAction(0, 1191, true) -- MeleeAttack929
            DisableControlAction(0, 1192, true) -- MeleeAttack930
            DisableControlAction(0, 1193, true) -- MeleeAttack931
            DisableControlAction(0, 1194, true) -- MeleeAttack932
            DisableControlAction(0, 1195, true) -- MeleeAttack933
            DisableControlAction(0, 1196, true) -- MeleeAttack934
            DisableControlAction(0, 1197, true) -- MeleeAttack935
            DisableControlAction(0, 1198, true) -- MeleeAttack936
            DisableControlAction(0, 1199, true) -- MeleeAttack937
            DisableControlAction(0, 1200, true) -- MeleeAttack938
            DisableControlAction(0, 1201, true) -- MeleeAttack939
            DisableControlAction(0, 1202, true) -- MeleeAttack940
            DisableControlAction(0, 1203, true) -- MeleeAttack941
            DisableControlAction(0, 1204, true) -- MeleeAttack942
            DisableControlAction(0, 1205, true) -- MeleeAttack943
            DisableControlAction(0, 1206, true) -- MeleeAttack944
            DisableControlAction(0, 1207, true) -- MeleeAttack945
            DisableControlAction(0, 1208, true) -- MeleeAttack946
            DisableControlAction(0, 1209, true) -- MeleeAttack947
            DisableControlAction(0, 1210, true) -- MeleeAttack948
            DisableControlAction(0, 1211, true) -- MeleeAttack949
            DisableControlAction(0, 1212, true) -- MeleeAttack950
            DisableControlAction(0, 1213, true) -- MeleeAttack951
            DisableControlAction(0, 1214, true) -- MeleeAttack952
            DisableControlAction(0, 1215, true) -- MeleeAttack953
            DisableControlAction(0, 1216, true) -- MeleeAttack954
            DisableControlAction(0, 1217, true) -- MeleeAttack955
            DisableControlAction(0, 1218, true) -- MeleeAttack956
            DisableControlAction(0, 1219, true) -- MeleeAttack957
            DisableControlAction(0, 1220, true) -- MeleeAttack958
            DisableControlAction(0, 1221, true) -- MeleeAttack959
            DisableControlAction(0, 1222, true) -- MeleeAttack960
            DisableControlAction(0, 1223, true) -- MeleeAttack961
            DisableControlAction(0, 1224, true) -- MeleeAttack962
            DisableControlAction(0, 1225, true) -- MeleeAttack963
            DisableControlAction(0, 1226, true) -- MeleeAttack964
            DisableControlAction(0, 1227, true) -- MeleeAttack965
            DisableControlAction(0, 1228, true) -- MeleeAttack966
            DisableControlAction(0, 1229, true) -- MeleeAttack967
            DisableControlAction(0, 1230, true) -- MeleeAttack968
            DisableControlAction(0, 1231, true) -- MeleeAttack969
            DisableControlAction(0, 1232, true) -- MeleeAttack970
            DisableControlAction(0, 1233, true) -- MeleeAttack971
            DisableControlAction(0, 1234, true) -- MeleeAttack972
            DisableControlAction(0, 1235, true) -- MeleeAttack973
            DisableControlAction(0, 1236, true) -- MeleeAttack974
            DisableControlAction(0, 1237, true) -- MeleeAttack975
            DisableControlAction(0, 1238, true) -- MeleeAttack976
            DisableControlAction(0, 1239, true) -- MeleeAttack977
            DisableControlAction(0, 1240, true) -- MeleeAttack978
            DisableControlAction(0, 1241, true) -- MeleeAttack979
            DisableControlAction(0, 1242, true) -- MeleeAttack980
            DisableControlAction(0, 1243, true) -- MeleeAttack981
            DisableControlAction(0, 1244, true) -- MeleeAttack982
            DisableControlAction(0, 1245, true) -- MeleeAttack983
            DisableControlAction(0, 1246, true) -- MeleeAttack984
            DisableControlAction(0, 1247, true) -- MeleeAttack985
            DisableControlAction(0, 1248, true) -- MeleeAttack986
            DisableControlAction(0, 1249, true) -- MeleeAttack987
            DisableControlAction(0, 1250, true) -- MeleeAttack988
            DisableControlAction(0, 1251, true) -- MeleeAttack989
            DisableControlAction(0, 1252, true) -- MeleeAttack990
            DisableControlAction(0, 1253, true) -- MeleeAttack991
            DisableControlAction(0, 1254, true) -- MeleeAttack992
            DisableControlAction(0, 1255, true) -- MeleeAttack993
            DisableControlAction(0, 1256, true) -- MeleeAttack994
            DisableControlAction(0, 1257, true) -- MeleeAttack995
            DisableControlAction(0, 1258, true) -- MeleeAttack996
            DisableControlAction(0, 1259, true) -- MeleeAttack997
            DisableControlAction(0, 1260, true) -- MeleeAttack998
            DisableControlAction(0, 1261, true) -- MeleeAttack999
            DisableControlAction(0, 1262, true) -- MeleeAttack1000
            DisableControlAction(0, 1263, true) -- MeleeAttack1001
            DisableControlAction(0, 1264, true) -- MeleeAttack1002
            DisableControlAction(0, 1265, true) -- MeleeAttack1003
            DisableControlAction(0, 1266, true) -- MeleeAttack1004
            DisableControlAction(0, 1267, true) -- MeleeAttack1005
            DisableControlAction(0, 1268, true) -- MeleeAttack1006
            DisableControlAction(0, 1269, true) -- MeleeAttack1007
            DisableControlAction(0, 1270, true) -- MeleeAttack1008
            DisableControlAction(0, 1271, true) -- MeleeAttack1009
            DisableControlAction(0, 1272, true) -- MeleeAttack1010
            DisableControlAction(0, 1273, true) -- MeleeAttack1011
            DisableControlAction(0, 1274, true) -- MeleeAttack1012
            DisableControlAction(0, 1275, true) -- MeleeAttack1013
            DisableControlAction(0, 1276, true) -- MeleeAttack1014
            DisableControlAction(0, 1277, true) -- MeleeAttack1015
            DisableControlAction(0, 1278, true) -- MeleeAttack1016
            DisableControlAction(0, 1279, true) -- MeleeAttack1017
            DisableControlAction(0, 1280, true) -- MeleeAttack1018
            DisableControlAction(0, 1281, true) -- MeleeAttack1019
            DisableControlAction(0, 1282, true) -- MeleeAttack1020
            DisableControlAction(0, 1283, true) -- MeleeAttack1021
            DisableControlAction(0, 1284, true) -- MeleeAttack1022
            DisableControlAction(0, 1285, true) -- MeleeAttack1023
            DisableControlAction(0, 1286, true) -- MeleeAttack1024
            DisableControlAction(0, 1287, true) -- MeleeAttack1025
            DisableControlAction(0, 1288, true) -- MeleeAttack1026
            DisableControlAction(0, 1289, true) -- MeleeAttack1027
            DisableControlAction(0, 1290, true) -- MeleeAttack1028
            DisableControlAction(0, 1291, true) -- MeleeAttack1029
            DisableControlAction(0, 1292, true) -- MeleeAttack1030
            DisableControlAction(0, 1293, true) -- MeleeAttack1031
            DisableControlAction(0, 1294, true) -- MeleeAttack1032
            DisableControlAction(0, 1295, true) -- MeleeAttack1033
            DisableControlAction(0, 1296, true) -- MeleeAttack1034
            DisableControlAction(0, 1297, true) -- MeleeAttack1035
            DisableControlAction(0, 1298, true) -- MeleeAttack1036
            DisableControlAction(0, 1299, true) -- MeleeAttack1037
            DisableControlAction(0, 1300, true) -- MeleeAttack1038
            DisableControlAction(0, 1301, true) -- MeleeAttack1039
            DisableControlAction(0, 1302, true) -- MeleeAttack1040
            DisableControlAction(0, 1303, true) -- MeleeAttack1041
            DisableControlAction(0, 1304, true) -- MeleeAttack1042
            DisableControlAction(0, 1305, true) -- MeleeAttack1043
            DisableControlAction(0, 1306, true) -- MeleeAttack1044
            DisableControlAction(0, 1307, true) -- MeleeAttack1045
            DisableControlAction(0, 1308, true) -- MeleeAttack1046
            DisableControlAction(0, 1309, true) -- MeleeAttack1047
            DisableControlAction(0, 1310, true) -- MeleeAttack1048
            DisableControlAction(0, 1311, true) -- MeleeAttack1049
            DisableControlAction(0, 1312, true) -- MeleeAttack1050
            DisableControlAction(0, 1313, true) -- MeleeAttack1051
            DisableControlAction(0, 1314, true) -- MeleeAttack1052
            DisableControlAction(0, 1315, true) -- MeleeAttack1053
            DisableControlAction(0, 1316, true) -- MeleeAttack1054
            DisableControlAction(0, 1317, true) -- MeleeAttack1055
            DisableControlAction(0, 1318, true) -- MeleeAttack1056
            DisableControlAction(0, 1319, true) -- MeleeAttack1057
            DisableControlAction(0, 1320, true) -- MeleeAttack1058
            DisableControlAction(0, 1321, true) -- MeleeAttack1059
            DisableControlAction(0, 1322, true) -- MeleeAttack1060
            DisableControlAction(0, 1323, true) -- MeleeAttack1061
            DisableControlAction(0, 1324, true) -- MeleeAttack1062
            DisableControlAction(0, 1325, true) -- MeleeAttack1063
            DisableControlAction(0, 1326, true) -- MeleeAttack1064
            DisableControlAction(0, 1327, true) -- MeleeAttack1065
            DisableControlAction(0, 1328, true) -- MeleeAttack1066
            DisableControlAction(0, 1329, true) -- MeleeAttack1067
            DisableControlAction(0, 1330, true) -- MeleeAttack1068
            DisableControlAction(0, 1331, true) -- MeleeAttack1069
            DisableControlAction(0, 1332, true) -- MeleeAttack1070
            DisableControlAction(0, 1333, true) -- MeleeAttack1071
            DisableControlAction(0, 1334, true) -- MeleeAttack1072
            DisableControlAction(0, 1335, true) -- MeleeAttack1073
            DisableControlAction(0, 1336, true) -- MeleeAttack1074
            DisableControlAction(0, 1337, true) -- MeleeAttack1075
            DisableControlAction(0, 1338, true) -- MeleeAttack1076
            DisableControlAction(0, 1339, true) -- MeleeAttack1077
            DisableControlAction(0, 1340, true) -- MeleeAttack1078
            DisableControlAction(0, 1341, true) -- MeleeAttack1079
            DisableControlAction(0, 1342, true) -- MeleeAttack1080
            DisableControlAction(0, 1343, true) -- MeleeAttack1081
            DisableControlAction(0, 1344, true) -- MeleeAttack1082
            DisableControlAction(0, 1345, true) -- MeleeAttack1083
            DisableControlAction(0, 1346, true) -- MeleeAttack1084
            DisableControlAction(0, 1347, true) -- MeleeAttack1085
            DisableControlAction(0, 1348, true) -- MeleeAttack1086
            DisableControlAction(0, 1349, true) -- MeleeAttack1087
            DisableControlAction(0, 1350, true) -- MeleeAttack1088
            DisableControlAction(0, 1351, true) -- MeleeAttack1089
            DisableControlAction(0, 1352, true) -- MeleeAttack1090
            DisableControlAction(0, 1353, true) -- MeleeAttack1091
            DisableControlAction(0, 1354, true) -- MeleeAttack1092
            DisableControlAction(0, 1355, true) -- MeleeAttack1093
            DisableControlAction(0, 1356, true) -- MeleeAttack1094
            DisableControlAction(0, 1357, true) -- MeleeAttack1095
            DisableControlAction(0, 1358, true) -- MeleeAttack1096
            DisableControlAction(0, 1359, true) -- MeleeAttack1097
            DisableControlAction(0, 1360, true) -- MeleeAttack1098
            DisableControlAction(0, 1361, true) -- MeleeAttack1099
            DisableControlAction(0, 1362, true) -- MeleeAttack1100
            DisableControlAction(0, 1363, true) -- MeleeAttack1101
            DisableControlAction(0, 1364, true) -- MeleeAttack1102
            DisableControlAction(0, 1365, true) -- MeleeAttack1103
            DisableControlAction(0, 1366, true) -- MeleeAttack1104
            DisableControlAction(0, 1367, true) -- MeleeAttack1105
            DisableControlAction(0, 1368, true) -- MeleeAttack1106
            DisableControlAction(0, 1369, true) -- MeleeAttack1107
            DisableControlAction(0, 1370, true) -- MeleeAttack1108
            DisableControlAction(0, 1371, true) -- MeleeAttack1109
            DisableControlAction(0, 1372, true) -- MeleeAttack1110
            DisableControlAction(0, 1373, true) -- MeleeAttack1111
            DisableControlAction(0, 1374, true) -- MeleeAttack1112
            DisableControlAction(0, 1375, true) -- MeleeAttack1113
            DisableControlAction(0, 1376, true) -- MeleeAttack1114
            DisableControlAction(0, 1377, true) -- MeleeAttack1115
            DisableControlAction(0, 1378, true) -- MeleeAttack116
            DisableControlAction(0, 1379, true) -- MeleeAttack117
            DisableControlAction(0, 1380, true) -- MeleeAttack118
            DisableControlAction(0, 1381, true) -- MeleeAttack119
            DisableControlAction(0, 1382, true) -- MeleeAttack120
            DisableControlAction(0, 1383, true) -- MeleeAttack121
            DisableControlAction(0, 1384, true) -- MeleeAttack122
            DisableControlAction(0, 1385, true) -- MeleeAttack123
            DisableControlAction(0, 1386, true) -- MeleeAttack124
            DisableControlAction(0, 1387, true) -- MeleeAttack125
            DisableControlAction(0, 1388, true) -- MeleeAttack126
            DisableControlAction(0, 1389, true) -- MeleeAttack127
            DisableControlAction(0, 1390, true) -- MeleeAttack128
            DisableControlAction(0, 1391, true) -- MeleeAttack129
            DisableControlAction(0, 1392, true) -- MeleeAttack130
            DisableControlAction(0, 1393, true) -- MeleeAttack131
            DisableControlAction(0, 1394, true) -- MeleeAttack132
            DisableControlAction(0, 1395, true) -- MeleeAttack133
            DisableControlAction(0, 1396, true) -- MeleeAttack134
            DisableControlAction(0, 1397, true) -- MeleeAttack135
            DisableControlAction(0, 1398, true) -- MeleeAttack136
            DisableControlAction(0, 1399, true) -- MeleeAttack137
            DisableControlAction(0, 1400, true) -- MeleeAttack138
            DisableControlAction(0, 1401, true) -- MeleeAttack139
            DisableControlAction(0, 1402, true) -- MeleeAttack140
            DisableControlAction(0, 1403, true) -- MeleeAttack141
            DisableControlAction(0, 1404, true) -- MeleeAttack142
            DisableControlAction(0, 1405, true) -- MeleeAttack143
            DisableControlAction(0, 1406, true) -- MeleeAttack144
            DisableControlAction(0, 1407, true) -- MeleeAttack145
            DisableControlAction(0, 1408, true) -- MeleeAttack146
            DisableControlAction(0, 1409, true) -- MeleeAttack147
            DisableControlAction(0, 1410, true) -- MeleeAttack148
            DisableControlAction(0, 1411, true) -- MeleeAttack149
            DisableControlAction(0, 1412, true) -- MeleeAttack150
            DisableControlAction(0, 1413, true) -- MeleeAttack151
            DisableControlAction(0, 1414, true) -- MeleeAttack152
            DisableControlAction(0, 1415, true) -- MeleeAttack153
            DisableControlAction(0, 1416, true) -- MeleeAttack154
            DisableControlAction(0, 1417, true) -- MeleeAttack155
            DisableControlAction(0, 1418, true) -- MeleeAttack156
            DisableControlAction(0, 1419, true) -- MeleeAttack157
            DisableControlAction(0, 1420, true) -- MeleeAttack158
            DisableControlAction(0, 1421, true) -- MeleeAttack159
            DisableControlAction(0, 1422, true) -- MeleeAttack160
            DisableControlAction(0, 1423, true) -- MeleeAttack161
            DisableControlAction(0, 1424, true) -- MeleeAttack162
            DisableControlAction(0, 1425, true) -- MeleeAttack163
            DisableControlAction(0, 1426, true) -- MeleeAttack164
            DisableControlAction(0, 1427, true) -- MeleeAttack165
            DisableControlAction(0, 1428, true) -- MeleeAttack166
            DisableControlAction(0, 1429, true) -- MeleeAttack167
            DisableControlAction(0, 1430, true) -- MeleeAttack168
            DisableControlAction(0, 1431, true) -- MeleeAttack169
            DisableControlAction(0, 1432, true) -- MeleeAttack170
            DisableControlAction(0, 1433, true) -- MeleeAttack171
            DisableControlAction(0, 1434, true) -- MeleeAttack172
            DisableControlAction(0, 1435, true) -- MeleeAttack173
            DisableControlAction(0, 1436, true) -- MeleeAttack174
            DisableControlAction(0, 1437, true) -- MeleeAttack175
            DisableControlAction(0, 1438, true) -- MeleeAttack176
            DisableControlAction(0, 1439, true) -- MeleeAttack177
            DisableControlAction(0, 1440, true) -- MeleeAttack178
            DisableControlAction(0, 1441, true) -- MeleeAttack179
            DisableControlAction(0, 1442, true) -- MeleeAttack180
            DisableControlAction(0, 1443, true) -- MeleeAttack181
            DisableControlAction(0, 1444, true) -- MeleeAttack182
            DisableControlAction(0, 1445, true) -- MeleeAttack183
            DisableControlAction(0, 1446, true) -- MeleeAttack184
            DisableControlAction(0, 1447, true) -- MeleeAttack185
            DisableControlAction(0, 1448, true) -- MeleeAttack186
            DisableControlAction(0, 1449, true) -- MeleeAttack187
            DisableControlAction(0, 1450, true) -- MeleeAttack188
            DisableControlAction(0, 1451, true) -- MeleeAttack189
            DisableControlAction(0, 1452, true) -- MeleeAttack190
            DisableControlAction(0, 1453, true) -- MeleeAttack191
            DisableControlAction(0, 1454, true) -- MeleeAttack192
            DisableControlAction(0, 1455, true) -- MeleeAttack193
            DisableControlAction(0, 1456, true) -- MeleeAttack194
            DisableControlAction(0, 1457, true) -- MeleeAttack195
            DisableControlAction(0, 1458, true) -- MeleeAttack196
            DisableControlAction(0, 1459, true) -- MeleeAttack197
            DisableControlAction(0, 1460, true) -- MeleeAttack198
            DisableControlAction(0, 1461, true) -- MeleeAttack199
            DisableControlAction(0, 1462, true) -- MeleeAttack200
            DisableControlAction(0, 1463, true) -- MeleeAttack201
            DisableControlAction(0, 1464, true) -- MeleeAttack202
            DisableControlAction(0, 1465, true) -- MeleeAttack203
            DisableControlAction(0, 1466, true) -- MeleeAttack204
            DisableControlAction(0, 1467, true) -- MeleeAttack205
            DisableControlAction(0, 1468, true) -- MeleeAttack206
            DisableControlAction(0, 1469, true) -- MeleeAttack207
            DisableControlAction(0, 1470, true) -- MeleeAttack208
            DisableControlAction(0, 1471, true) -- MeleeAttack209
            DisableControlAction(0, 1472, true) -- MeleeAttack210
            DisableControlAction(0, 1473, true) -- MeleeAttack211
            DisableControlAction(0, 1474, true) -- MeleeAttack212
            DisableControlAction(0, 1475, true) -- MeleeAttack213
            DisableControlAction(0, 1476, true) -- MeleeAttack214
            DisableControlAction(0, 1477, true) -- MeleeAttack215
            DisableControlAction(0, 1478, true) -- MeleeAttack216
            DisableControlAction(0, 1479, true) -- MeleeAttack217
            DisableControlAction(0, 1480, true) -- MeleeAttack218
            DisableControlAction(0, 1481, true) -- MeleeAttack219
            DisableControlAction(0, 1482, true) -- MeleeAttack220
            DisableControlAction(0, 1483, true) -- MeleeAttack221
            DisableControlAction(0, 1484, true) -- MeleeAttack222
            DisableControlAction(0, 1485, true) -- MeleeAttack223
            DisableControlAction(0, 1486, true) -- MeleeAttack224
            DisableControlAction(0, 1487, true) -- MeleeAttack225
            DisableControlAction(0, 1488, true) -- MeleeAttack226
            DisableControlAction(0, 1489, true) -- MeleeAttack227
            DisableControlAction(0, 1490, true) -- MeleeAttack228
            DisableControlAction(0, 1491, true) -- MeleeAttack229
            DisableControlAction(0, 1492, true) -- MeleeAttack230
            DisableControlAction(0, 1493, true) -- MeleeAttack231
            DisableControlAction(0, 1494, true) -- MeleeAttack232
            DisableControlAction(0, 1495, true) -- MeleeAttack233
            DisableControlAction(0, 1496, true) -- MeleeAttack234
            DisableControlAction(0, 1497, true) -- MeleeAttack235
            DisableControlAction(0, 1498, true) -- MeleeAttack236
            DisableControlAction(0, 1499, true) -- MeleeAttack237
            DisableControlAction(0, 1500, true) -- MeleeAttack238
            DisableControlAction(0, 1501, true) -- MeleeAttack239
            DisableControlAction(0, 1502, true) -- MeleeAttack240
            DisableControlAction(0, 1503, true) -- MeleeAttack241
            DisableControlAction(0, 1504, true) -- MeleeAttack242
            DisableControlAction(0, 1505, true) -- MeleeAttack243
            DisableControlAction(0, 1506, true) -- MeleeAttack244
            DisableControlAction(0, 1507, true) -- MeleeAttack245
            DisableControlAction(0, 1508, true) -- MeleeAttack246
            DisableControlAction(0, 1509, true) -- MeleeAttack247
            DisableControlAction(0, 1510, true) -- MeleeAttack248
            DisableControlAction(0, 1511, true) -- MeleeAttack249
            DisableControlAction(0, 1512, true) -- MeleeAttack250
            DisableControlAction(0, 1513, true) -- MeleeAttack251
            DisableControlAction(0, 1514, true) -- MeleeAttack252
            DisableControlAction(0, 1515, true) -- MeleeAttack253
            DisableControlAction(0, 1516, true) -- MeleeAttack254
            DisableControlAction(0, 1517, true) -- MeleeAttack255
            DisableControlAction(0, 1518, true) -- MeleeAttack256
            DisableControlAction(0, 1519, true) -- MeleeAttack257
            DisableControlAction(0, 1520, true) -- MeleeAttack258
            DisableControlAction(0, 1521, true) -- MeleeAttack259
            DisableControlAction(0, 1522, true) -- MeleeAttack260
            DisableControlAction(0, 1523, true) -- MeleeAttack261
            DisableControlAction(0, 1524, true) -- MeleeAttack262
            DisableControlAction(0, 1525, true) -- MeleeAttack263
            DisableControlAction(0, 1526, true) -- MeleeAttack264
            DisableControlAction(0, 1527, true) -- MeleeAttack265
            DisableControlAction(0, 1528, true) -- MeleeAttack266
            DisableControlAction(0, 1529, true) -- MeleeAttack267
            DisableControlAction(0, 1530, true) -- MeleeAttack268
            DisableControlAction(0, 1531, true) -- MeleeAttack269
            DisableControlAction(0, 1532, true) -- MeleeAttack270
            DisableControlAction(0, 1533, true) -- MeleeAttack271
            DisableControlAction(0, 1534, true) -- MeleeAttack272
            DisableControlAction(0, 1535, true) -- MeleeAttack273
            DisableControlAction(0, 1536, true) -- MeleeAttack274
            DisableControlAction(0, 1537, true) -- MeleeAttack275
            DisableControlAction(0, 1538, true) -- MeleeAttack276
            DisableControlAction(0, 1539, true) -- MeleeAttack277
            DisableControlAction(0, 1540, true) -- MeleeAttack278
            DisableControlAction(0, 1541, true) -- MeleeAttack279
            DisableControlAction(0, 1542, true) -- MeleeAttack280
            DisableControlAction(0, 1543, true) -- MeleeAttack281
            DisableControlAction(0, 1544, true) -- MeleeAttack282
            DisableControlAction(0, 1545, true) -- MeleeAttack283
            DisableControlAction(0, 1546, true) -- MeleeAttack284
            DisableControlAction(0, 1547, true) -- MeleeAttack285
            DisableControlAction(0, 1548, true) -- MeleeAttack286
            DisableControlAction(0, 1549, true) -- MeleeAttack287
            DisableControlAction(0, 1550, true) -- MeleeAttack288
            DisableControlAction(0, 1551, true) -- MeleeAttack289
            DisableControlAction(0, 1552, true) -- MeleeAttack290
            DisableControlAction(0, 1553, true) -- MeleeAttack291
            DisableControlAction(0, 1554, true) -- MeleeAttack292
            DisableControlAction(0, 1555, true) -- MeleeAttack293
            DisableControlAction(0, 1556, true) -- MeleeAttack294
            DisableControlAction(0, 1557, true) -- MeleeAttack295
            DisableControlAction(0, 1558, true) -- MeleeAttack296
            DisableControlAction(0, 1559, true) -- MeleeAttack297
            DisableControlAction(0, 1560, true) -- MeleeAttack298
            DisableControlAction(0, 1561, true) -- MeleeAttack299
            DisableControlAction(0, 1562, true) -- MeleeAttack300
            DisableControlAction(0, 1563, true) -- MeleeAttack301
            DisableControlAction(0, 1564, true) -- MeleeAttack302
            DisableControlAction(0, 1565, true) -- MeleeAttack303
            DisableControlAction(0, 1566, true) -- MeleeAttack304
            DisableControlAction(0, 1567, true) -- MeleeAttack305
            DisableControlAction(0, 1568, true) -- MeleeAttack306
            DisableControlAction(0, 1569, true) -- MeleeAttack307
            DisableControlAction(0, 1570, true) -- MeleeAttack308
            DisableControlAction(0, 1571, true) -- MeleeAttack309
            DisableControlAction(0, 1572, true) -- MeleeAttack310
            DisableControlAction(0, 1573, true) -- MeleeAttack311
            DisableControlAction(0, 1574, true) -- MeleeAttack312
            DisableControlAction(0, 1575, true) -- MeleeAttack313
            DisableControlAction(0, 1576, true) -- MeleeAttack314
            DisableControlAction(0, 1577, true) -- MeleeAttack315
            DisableControlAction(0, 1578, true) -- MeleeAttack316
            DisableControlAction(0, 1579, true) -- MeleeAttack317
            DisableControlAction(0, 1580, true) -- MeleeAttack318
            DisableControlAction(0, 1581, true) -- MeleeAttack319
            DisableControlAction(0, 1582, true) -- MeleeAttack320
            DisableControlAction(0, 1583, true) -- MeleeAttack321
            DisableControlAction(0, 1584, true) -- MeleeAttack322
            DisableControlAction(0, 1585, true) -- MeleeAttack323
            DisableControlAction(0, 1586, true) -- MeleeAttack324
            DisableControlAction(0, 1587, true) -- MeleeAttack325
            DisableControlAction(0, 1588, true) -- MeleeAttack326
            DisableControlAction(0, 1589, true) -- MeleeAttack327
            DisableControlAction(0, 1590, true) -- MeleeAttack328
            DisableControlAction(0, 1591, true) -- MeleeAttack329
            DisableControlAction(0, 1592, true) -- MeleeAttack330
            DisableControlAction(0, 1593, true) -- MeleeAttack331
            DisableControlAction(0, 1594, true) -- MeleeAttack332
            DisableControlAction(0, 1595, true) -- MeleeAttack333
            DisableControlAction(0, 1596, true) -- MeleeAttack334
            DisableControlAction(0, 1597, true) -- MeleeAttack335
            DisableControlAction(0, 1598, true) -- MeleeAttack336
            DisableControlAction(0, 1599, true) -- MeleeAttack337
            DisableControlAction(0, 1600, true) -- MeleeAttack338
            DisableControlAction(0, 1601, true) -- MeleeAttack339
            DisableControlAction(0, 1602, true) -- MeleeAttack340
            DisableControlAction(0, 1603, true) -- MeleeAttack341
            DisableControlAction(0, 1604, true) -- MeleeAttack342
            DisableControlAction(0, 1605, true) -- MeleeAttack343
            DisableControlAction(0, 1606, true) -- MeleeAttack344
            DisableControlAction(0, 1607, true) -- MeleeAttack345
            DisableControlAction(0, 1608, true) -- MeleeAttack346
            DisableControlAction(0, 1609, true) -- MeleeAttack347
            DisableControlAction(0, 1610, true) -- MeleeAttack348
            DisableControlAction(0, 1611, true) -- MeleeAttack349
            DisableControlAction(0, 1612, true) -- MeleeAttack350
            DisableControlAction(0, 1613, true) -- MeleeAttack351
            DisableControlAction(0, 1614, true) -- MeleeAttack352
            DisableControlAction(0, 1615, true) -- MeleeAttack353
            DisableControlAction(0, 1616, true) -- MeleeAttack354
            DisableControlAction(0, 1617, true) -- MeleeAttack355
            DisableControlAction(0, 1618, true) -- MeleeAttack356
            DisableControlAction(0, 1619, true) -- MeleeAttack357
            DisableControlAction(0, 1620, true) -- MeleeAttack358
            DisableControlAction(0, 1621, true) -- MeleeAttack359
            DisableControlAction(0, 1622, true) -- MeleeAttack360
            DisableControlAction(0, 1623, true) -- MeleeAttack361
            DisableControlAction(0, 1624, true) -- MeleeAttack362
            DisableControlAction(0, 1625, true) -- MeleeAttack363
            DisableControlAction(0, 1626, true) -- MeleeAttack364
            DisableControlAction(0, 1627, true) -- MeleeAttack365
            DisableControlAction(0, 1628, true) -- MeleeAttack366
            DisableControlAction(0, 1629, true) -- MeleeAttack367
            DisableControlAction(0, 1630, true) -- MeleeAttack368
            DisableControlAction(0, 1631, true) -- MeleeAttack369
            DisableControlAction(0, 1632, true) -- MeleeAttack370
            DisableControlAction(0, 1633, true) -- MeleeAttack371
            DisableControlAction(0, 1634, true) -- MeleeAttack372
            DisableControlAction(0, 1635, true) -- MeleeAttack373
            DisableControlAction(0, 1636, true) -- MeleeAttack374
            DisableControlAction(0, 1637, true) -- MeleeAttack375
            DisableControlAction(0, 1638, true) -- MeleeAttack376
            DisableControlAction(0, 1639, true) -- MeleeAttack377
            DisableControlAction(0, 1640, true) -- MeleeAttack378
            DisableControlAction(0, 1641, true) -- MeleeAttack379
            DisableControlAction(0, 1642, true) -- MeleeAttack380
            DisableControlAction(0, 1643, true) -- MeleeAttack381
            DisableControlAction(0, 1644, true) -- MeleeAttack382
            DisableControlAction(0, 1645, true) -- MeleeAttack383
            DisableControlAction(0, 1646, true) -- MeleeAttack384
            DisableControlAction(0, 1647, true) -- MeleeAttack385
            DisableControlAction(0, 1648, true) -- MeleeAttack386
            DisableControlAction(0, 1649, true) -- MeleeAttack387
            DisableControlAction(0, 1650, true) -- MeleeAttack388
            DisableControlAction(0, 1651, true) -- MeleeAttack389
            DisableControlAction(0, 1652, true) -- MeleeAttack390
            DisableControlAction(0, 1653, true) -- MeleeAttack391
            DisableControlAction(0, 1654, true) -- MeleeAttack392
            DisableControlAction(0, 1655, true) -- MeleeAttack393
            DisableControlAction(0, 1656, true) -- MeleeAttack394
            DisableControlAction(0, 1657, true) -- MeleeAttack395
            DisableControlAction(0, 1658, true) -- MeleeAttack396
            DisableControlAction(0, 1659, true) -- MeleeAttack397
            DisableControlAction(0, 1660, true) -- MeleeAttack398
            DisableControlAction(0, 1661, true) -- MeleeAttack399
            DisableControlAction(0, 1662, true) -- MeleeAttack400
            DisableControlAction(0, 1663, true) -- MeleeAttack401
            DisableControlAction(0, 1664, true) -- MeleeAttack402
            DisableControlAction(0, 1665, true) -- MeleeAttack403
            DisableControlAction(0, 1666, true) -- MeleeAttack404
            DisableControlAction(0, 1667, true) -- MeleeAttack405
            DisableControlAction(0, 1668, true) -- MeleeAttack406
            DisableControlAction(0, 1669, true) -- MeleeAttack407
            DisableControlAction(0, 1670, true) -- MeleeAttack408
            DisableControlAction(0, 1671, true) -- MeleeAttack409
            DisableControlAction(0, 1672, true) -- MeleeAttack410
            DisableControlAction(0, 1673, true) -- MeleeAttack411
            DisableControlAction(0, 1674, true) -- MeleeAttack412
            DisableControlAction(0, 1675, true) -- MeleeAttack413
            DisableControlAction(0, 1676, true) -- MeleeAttack414
            DisableControlAction(0, 1677, true) -- MeleeAttack415
            DisableControlAction(0, 1678, true) -- MeleeAttack416
            DisableControlAction(0, 1679, true) -- MeleeAttack417
            DisableControlAction(0, 1680, true) -- MeleeAttack418
            DisableControlAction(0, 1681, true) -- MeleeAttack419
            DisableControlAction(0, 1682, true) -- MeleeAttack420
            DisableControlAction(0, 1683, true) -- MeleeAttack421
            DisableControlAction(0, 1684, true) -- MeleeAttack422
            DisableControlAction(0, 1685, true) -- MeleeAttack423
            DisableControlAction(0, 1686, true) -- MeleeAttack424
            DisableControlAction(0, 1687, true) -- MeleeAttack425
            DisableControlAction(0, 1688, true) -- MeleeAttack426
            DisableControlAction(0, 1689, true) -- MeleeAttack427
            DisableControlAction(0, 1690, true) -- MeleeAttack428
            DisableControlAction(0, 1691, true) -- MeleeAttack429
            DisableControlAction(0, 1692, true) -- MeleeAttack430
            DisableControlAction(0, 1693, true) -- MeleeAttack431
            DisableControlAction(0, 1694, true) -- MeleeAttack432
            DisableControlAction(0, 1695, true) -- MeleeAttack433
            DisableControlAction(0, 1696, true) -- MeleeAttack434
            DisableControlAction(0, 1697, true) -- MeleeAttack435
            DisableControlAction(0, 1698, true) -- MeleeAttack436
            DisableControlAction(0, 1699, true) -- MeleeAttack437
            DisableControlAction(0, 1700, true) -- MeleeAttack438
            DisableControlAction(0, 1701, true) -- MeleeAttack439
            DisableControlAction(0, 1702, true) -- MeleeAttack440
            DisableControlAction(0, 1703, true) -- MeleeAttack441
            DisableControlAction(0, 1704, true) -- MeleeAttack442
            DisableControlAction(0, 1705, true) -- MeleeAttack443
            DisableControlAction(0, 1706, true) -- MeleeAttack444
            DisableControlAction(0, 1707, true) -- MeleeAttack445
            DisableControlAction(0, 1708, true) -- MeleeAttack446
            DisableControlAction(0, 1709, true) -- MeleeAttack447
            DisableControlAction(0, 1710, true) -- MeleeAttack448
            DisableControlAction(0, 1711, true) -- MeleeAttack449
            DisableControlAction(0, 1712, true) -- MeleeAttack450
            DisableControlAction(0, 1713, true) -- MeleeAttack451
            DisableControlAction(0, 1714, true) -- MeleeAttack452
            DisableControlAction(0, 1715, true) -- MeleeAttack453
            DisableControlAction(0, 1716, true) -- MeleeAttack454
            DisableControlAction(0, 1717, true) -- MeleeAttack455
            DisableControlAction(0, 1718, true) -- MeleeAttack456
            DisableControlAction(0, 1719, true) -- MeleeAttack457
            DisableControlAction(0, 1720, true) -- MeleeAttack458
            DisableControlAction(0, 1721, true) -- MeleeAttack459
            DisableControlAction(0, 1722, true) -- MeleeAttack460
            DisableControlAction(0, 1723, true) -- MeleeAttack461
            DisableControlAction(0, 1724, true) -- MeleeAttack462
            DisableControlAction(0, 1725, true) -- MeleeAttack463
            DisableControlAction(0, 1726, true) -- MeleeAttack464
            DisableControlAction(0, 1727, true) -- MeleeAttack465
            DisableControlAction(0, 1728, true) -- MeleeAttack466
            DisableControlAction(0, 1729, true) -- MeleeAttack467
            DisableControlAction(0, 1730, true) -- MeleeAttack468
            DisableControlAction(0, 1731, true) -- MeleeAttack469
            DisableControlAction(0, 1732, true) -- MeleeAttack470
            DisableControlAction(0, 1733, true) -- MeleeAttack471
            DisableControlAction(0, 1734, true) -- MeleeAttack472
            DisableControlAction(0, 1735, true) -- MeleeAttack473
            DisableControlAction(0, 1736, true) -- MeleeAttack474
            DisableControlAction(0, 1737, true) -- MeleeAttack475
            DisableControlAction(0, 1738, true) -- MeleeAttack476
            DisableControlAction(0, 1739, true) -- MeleeAttack477
            DisableControlAction(0, 1740, true) -- MeleeAttack478
            DisableControlAction(0, 1741, true) -- MeleeAttack479
            DisableControlAction(0, 1742, true) -- MeleeAttack480
            DisableControlAction(0, 1743, true) -- MeleeAttack481
            DisableControlAction(0, 1744, true) -- MeleeAttack482
            DisableControlAction(0, 1745, true) -- MeleeAttack483
            DisableControlAction(0, 1746, true) -- MeleeAttack484
            DisableControlAction(0, 1747, true) -- MeleeAttack485
            DisableControlAction(0, 1748, true) -- MeleeAttack486
            DisableControlAction(0, 1749, true) -- MeleeAttack487
            DisableControlAction(0, 1750, true) -- MeleeAttack488
            DisableControlAction(0, 1751, true) -- MeleeAttack489
            DisableControlAction(0, 1752, true) -- MeleeAttack490
            DisableControlAction(0, 1753, true) -- MeleeAttack491
            DisableControlAction(0, 1754, true) -- MeleeAttack492
            DisableControlAction(0, 1755, true) -- MeleeAttack493
            DisableControlAction(0, 1756, true) -- MeleeAttack494
            DisableControlAction(0, 1757, true) -- MeleeAttack495
            DisableControlAction(0, 1758, true) -- MeleeAttack496
            DisableControlAction(0, 1759, true) -- MeleeAttack497
            DisableControlAction(0, 1760, true) -- MeleeAttack498
            DisableControlAction(0, 1761, true) -- MeleeAttack499
            DisableControlAction(0, 1762, true) -- MeleeAttack500
            DisableControlAction(0, 1763, true) -- MeleeAttack501
            DisableControlAction(0, 1764, true) -- MeleeAttack502
            DisableControlAction(0, 1765, true) -- MeleeAttack503
            DisableControlAction(0, 1766, true) -- MeleeAttack504
            DisableControlAction(0, 1767, true) -- MeleeAttack505
            DisableControlAction(0, 1768, true) -- MeleeAttack506
            DisableControlAction(0, 1769, true) -- MeleeAttack507
            DisableControlAction(0, 1770, true) -- MeleeAttack508
            DisableControlAction(0, 1771, true) -- MeleeAttack509
            DisableControlAction(0, 1772, true) -- MeleeAttack510
            DisableControlAction(0, 1773, true) -- MeleeAttack511
            DisableControlAction(0, 1774, true) -- MeleeAttack512
            DisableControlAction(0, 1775, true) -- MeleeAttack513
            DisableControlAction(0, 1776, true) -- MeleeAttack514
            DisableControlAction(0, 1777, true) -- MeleeAttack515
            DisableControlAction(0, 1778, true) -- MeleeAttack516
            DisableControlAction(0, 1779, true) -- MeleeAttack517
            DisableControlAction(0, 1780, true) -- MeleeAttack518
            DisableControlAction(0, 1781, true) -- MeleeAttack519
            DisableControlAction(0, 1782, true) -- MeleeAttack520
            DisableControlAction(0, 1783, true) -- MeleeAttack521
            DisableControlAction(0, 1784, true) -- MeleeAttack522
            DisableControlAction(0, 1785, true) -- MeleeAttack523
            DisableControlAction(0, 1786, true) -- MeleeAttack524
            DisableControlAction(0, 1787, true) -- MeleeAttack525
            DisableControlAction(0, 1788, true) -- MeleeAttack526
            DisableControlAction(0, 1789, true) -- MeleeAttack527
            DisableControlAction(0, 1790, true) -- MeleeAttack528
            DisableControlAction(0, 1791, true) -- MeleeAttack529
            DisableControlAction(0, 1792, true) -- MeleeAttack530
            DisableControlAction(0, 1793, true) -- MeleeAttack531
            DisableControlAction(0, 1794, true) -- MeleeAttack532
            DisableControlAction(0, 1795, true) -- MeleeAttack533
            DisableControlAction(0, 1796, true) -- MeleeAttack534
            DisableControlAction(0, 1797, true) -- MeleeAttack535
            DisableControlAction(0, 1798, true) -- MeleeAttack536
            DisableControlAction(0, 1799, true) -- MeleeAttack537
            DisableControlAction(0, 1800, true) -- MeleeAttack538
            DisableControlAction(0, 1801, true) -- MeleeAttack539
            DisableControlAction(0, 1802, true) -- MeleeAttack540
            DisableControlAction(0, 1803, true) -- MeleeAttack541
            DisableControlAction(0, 1804, true) -- MeleeAttack542
            DisableControlAction(0, 1805, true) -- MeleeAttack543
            DisableControlAction(0, 1806, true) -- MeleeAttack544
            DisableControlAction(0, 1807, true) -- MeleeAttack545
            DisableControlAction(0, 1808, true) -- MeleeAttack546
            DisableControlAction(0, 1809, true) -- MeleeAttack547
            DisableControlAction(0, 1810, true) -- MeleeAttack548
            DisableControlAction(0, 1811, true) -- MeleeAttack549
            DisableControlAction(0, 1812, true) -- MeleeAttack550
            DisableControlAction(0, 1813, true) -- MeleeAttack551
            DisableControlAction(0, 1814, true) -- MeleeAttack552
            DisableControlAction(0, 1815, true) -- MeleeAttack553
            DisableControlAction(0, 1816, true) -- MeleeAttack554
            DisableControlAction(0, 1817, true) -- MeleeAttack555
            DisableControlAction(0, 1818, true) -- MeleeAttack556
            DisableControlAction(0, 1819, true) -- MeleeAttack557
            DisableControlAction(0, 1820, true) -- MeleeAttack558
            DisableControlAction(0, 1821, true) -- MeleeAttack559
            DisableControlAction(0, 1822, true) -- MeleeAttack560
            DisableControlAction(0, 1823, true) -- MeleeAttack561
            DisableControlAction(0, 1824, true) -- MeleeAttack562
            DisableControlAction(0, 1825, true) -- MeleeAttack563
            DisableControlAction(0, 1826, true) -- MeleeAttack564
            DisableControlAction(0, 1827, true) -- MeleeAttack565
            DisableControlAction(0, 1828, true) -- MeleeAttack566
            DisableControlAction(0, 1829, true) -- MeleeAttack567
            DisableControlAction(0, 1830, true) -- MeleeAttack568
            DisableControlAction(0, 1831, true) -- MeleeAttack569
            DisableControlAction(0, 1832, true) -- MeleeAttack570
            DisableControlAction(0, 1833, true) -- MeleeAttack571
            DisableControlAction(0, 1834, true) -- MeleeAttack572
            DisableControlAction(0, 1835, true) -- MeleeAttack573
            DisableControlAction(0, 1836, true) -- MeleeAttack574
            DisableControlAction(0, 1837, true) -- MeleeAttack575
            DisableControlAction(0, 1838, true) -- MeleeAttack576
            DisableControlAction(0, 1839, true) -- MeleeAttack577
            DisableControlAction(0, 1840, true) -- MeleeAttack578
            DisableControlAction(0, 1841, true) -- MeleeAttack579
            DisableControlAction(0, 1842, true) -- MeleeAttack580
            DisableControlAction(0, 1843, true) -- MeleeAttack581
            DisableControlAction(0, 1844, true) -- MeleeAttack582
            DisableControlAction(0, 1845, true) -- MeleeAttack583
            DisableControlAction(0, 1846, true) -- MeleeAttack584
            DisableControlAction(0, 1847, true) -- MeleeAttack585
            DisableControlAction(0, 1848, true) -- MeleeAttack586
            DisableControlAction(0, 1849, true) -- MeleeAttack587
            DisableControlAction(0, 1850, true) -- MeleeAttack588
            DisableControlAction(0, 1851, true) -- MeleeAttack589
            DisableControlAction(0, 1852, true) -- MeleeAttack590
            DisableControlAction(0, 1853, true) -- MeleeAttack591
            DisableControlAction(0, 1854, true) -- MeleeAttack592
            DisableControlAction(0, 1855, true) -- MeleeAttack593
            DisableControlAction(0, 1856, true) -- MeleeAttack594
            DisableControlAction(0, 1857, true) -- MeleeAttack595
            DisableControlAction(0, 1858, true) -- MeleeAttack596
            DisableControlAction(0, 1859, true) -- MeleeAttack597
            DisableControlAction(0, 1860, true) -- MeleeAttack598
            DisableControlAction(0, 1861, true) -- MeleeAttack599
            DisableControlAction(0, 1862, true) -- MeleeAttack600
            DisableControlAction(0, 1863, true) -- MeleeAttack601
            DisableControlAction(0, 1864, true) -- MeleeAttack602
            DisableControlAction(0, 1865, true) -- MeleeAttack603
            DisableControlAction(0, 1866, true) -- MeleeAttack604
            DisableControlAction(0, 1867, true) -- MeleeAttack605
            DisableControlAction(0, 1868, true) -- MeleeAttack606
            DisableControlAction(0, 1869, true) -- MeleeAttack607
            DisableControlAction(0, 1870, true) -- MeleeAttack608
            DisableControlAction(0, 1871, true) -- MeleeAttack609
            DisableControlAction(0, 1872, true) -- MeleeAttack610
            DisableControlAction(0, 1873, true) -- MeleeAttack611
            DisableControlAction(0, 1874, true) -- MeleeAttack612
            DisableControlAction(0, 1875, true) -- MeleeAttack613
            DisableControlAction(0, 1876, true) -- MeleeAttack614
            DisableControlAction(0, 1877, true) -- MeleeAttack615
            DisableControlAction(0, 1878, true) -- MeleeAttack616
            DisableControlAction(0, 1879, true) -- MeleeAttack617
            DisableControlAction(0, 1880, true) -- MeleeAttack618
            DisableControlAction(0, 1881, true) -- MeleeAttack619
            DisableControlAction(0, 1882, true) -- MeleeAttack620
            DisableControlAction(0, 1883, true) -- MeleeAttack621
            DisableControlAction(0, 1884, true) -- MeleeAttack622
            DisableControlAction(0, 1885, true) -- MeleeAttack623
            DisableControlAction(0, 1886, true) -- MeleeAttack624
            DisableControlAction(0, 1887, true) -- MeleeAttack625
            DisableControlAction(0, 1888, true) -- MeleeAttack626
            DisableControlAction(0, 1889, true) -- MeleeAttack627
            DisableControlAction(0, 1890, true) -- MeleeAttack628
            DisableControlAction(0, 1891, true) -- MeleeAttack629
            DisableControlAction(0, 1892, true) -- MeleeAttack630
            DisableControlAction(0, 1893, true) -- MeleeAttack631
            DisableControlAction(0, 1894, true) -- MeleeAttack632
            DisableControlAction(0, 1895, true) -- MeleeAttack633
            DisableControlAction(0, 1896, true) -- MeleeAttack634
            DisableControlAction(0, 1897, true) -- MeleeAttack635
            DisableControlAction(0, 1898, true) -- MeleeAttack636
            DisableControlAction(0, 1899, true) -- MeleeAttack637
            DisableControlAction(0, 1900, true) -- MeleeAttack638
            DisableControlAction(0, 1901, true) -- MeleeAttack639
            DisableControlAction(0, 1902, true) -- MeleeAttack640
            DisableControlAction(0, 1903, true) -- MeleeAttack641
            DisableControlAction(0, 1904, true) -- MeleeAttack642
            DisableControlAction(0, 1905, true) -- MeleeAttack643
            DisableControlAction(0, 1906, true) -- MeleeAttack644
            DisableControlAction(0, 1907, true) -- MeleeAttack645
            DisableControlAction(0, 1908, true) -- MeleeAttack646
            DisableControlAction(0, 1909, true) -- MeleeAttack647
            DisableControlAction(0, 1910, true) -- MeleeAttack648
            DisableControlAction(0, 1911, true) -- MeleeAttack649
            DisableControlAction(0, 1912, true) -- MeleeAttack650
            DisableControlAction(0, 1913, true) -- MeleeAttack651
            DisableControlAction(0, 1914, true) -- MeleeAttack652
            DisableControlAction(0, 1915, true) -- MeleeAttack653
            DisableControlAction(0, 1916, true) -- MeleeAttack654
            DisableControlAction(0, 1917, true) -- MeleeAttack655
            DisableControlAction(0, 1918, true) -- MeleeAttack656
            DisableControlAction(0, 1919, true) -- MeleeAttack657
            DisableControlAction(0, 1920, true) -- MeleeAttack658
            DisableControlAction(0, 1921, true) -- MeleeAttack659
            DisableControlAction(0, 1922, true) -- MeleeAttack660
            DisableControlAction(0, 1923, true) -- MeleeAttack661
            DisableControlAction(0, 1924, true) -- MeleeAttack662
            DisableControlAction(0, 1925, true) -- MeleeAttack663
            DisableControlAction(0, 1926, true) -- MeleeAttack664
            DisableControlAction(0, 1927, true) -- MeleeAttack665
            DisableControlAction(0, 1928, true) -- MeleeAttack666
            DisableControlAction(0, 1929, true) -- MeleeAttack667
            DisableControlAction(0, 1930, true) -- MeleeAttack668
            DisableControlAction(0, 1931, true) -- MeleeAttack669
            DisableControlAction(0, 1932, true) -- MeleeAttack670
            DisableControlAction(0, 1933, true) -- MeleeAttack671
            DisableControlAction(0, 1934, true) -- MeleeAttack672
            DisableControlAction(0, 1935, true) -- MeleeAttack673
            DisableControlAction(0, 1936, true) -- MeleeAttack674
            DisableControlAction(0, 1937, true) -- MeleeAttack675
            DisableControlAction(0, 1938, true) -- MeleeAttack676
            DisableControlAction(0, 1939, true) -- MeleeAttack677
            DisableControlAction(0, 1940, true) -- MeleeAttack678
            DisableControlAction(0, 1941, true) -- MeleeAttack679
            DisableControlAction(0, 1942, true) -- MeleeAttack680
            DisableControlAction(0, 1943, true) -- MeleeAttack681
            DisableControlAction(0, 1944, true) -- MeleeAttack682
            DisableControlAction(0, 1945, true) -- MeleeAttack683
            DisableControlAction(0, 1946, true) -- MeleeAttack684
            DisableControlAction(0, 1947, true) -- MeleeAttack685
            DisableControlAction(0, 1948, true) -- MeleeAttack686
            DisableControlAction(0, 1949, true) -- MeleeAttack687
            DisableControlAction(0, 1950, true) -- MeleeAttack688
            DisableControlAction(0, 1951, true) -- MeleeAttack689
            DisableControlAction(0, 1952, true) -- MeleeAttack690
            DisableControlAction(0, 1953, true) -- MeleeAttack691
            DisableControlAction(0, 1954, true) -- MeleeAttack692
            DisableControlAction(0, 1955, true) -- MeleeAttack693
            DisableControlAction(0, 1956, true) -- MeleeAttack694
            DisableControlAction(0, 1957, true) -- MeleeAttack695
            DisableControlAction(0, 1958, true) -- MeleeAttack696
            DisableControlAction(0, 1959, true) -- MeleeAttack697
            DisableControlAction(0, 1960, true) -- MeleeAttack698
            DisableControlAction(0, 1961, true) -- MeleeAttack699
            DisableControlAction(0, 1962, true) -- MeleeAttack700
            DisableControlAction(0, 1963, true) -- MeleeAttack701
            DisableControlAction(0, 1964, true) -- MeleeAttack702
            DisableControlAction(0, 1965, true) -- MeleeAttack703
            DisableControlAction(0, 1966, true) -- MeleeAttack704
            DisableControlAction(0, 1967, true) -- MeleeAttack705
            DisableControlAction(0, 1968, true) -- MeleeAttack706
            DisableControlAction(0, 1969, true) -- MeleeAttack707
            DisableControlAction(0, 1970, true) -- MeleeAttack708
            DisableControlAction(0, 1971, true) -- MeleeAttack709
            DisableControlAction(0, 1972, true) -- MeleeAttack710
            DisableControlAction(0, 1973, true) -- MeleeAttack711
            DisableControlAction(0, 1974, true) -- MeleeAttack712
            DisableControlAction(0, 1975, true) -- MeleeAttack713
            DisableControlAction(0, 1976, true) -- MeleeAttack714
            DisableControlAction(0, 1977, true) -- MeleeAttack715
            DisableControlAction(0, 1978, true) -- MeleeAttack716
            DisableControlAction(0, 1979, true) -- MeleeAttack717
            DisableControlAction(0, 1980, true) -- MeleeAttack718
            DisableControlAction(0, 1981, true) -- MeleeAttack719
            DisableControlAction(0, 1982, true) -- MeleeAttack720
            DisableControlAction(0, 1983, true) -- MeleeAttack721
            DisableControlAction(0, 1984, true) -- MeleeAttack722
            DisableControlAction(0, 1985, true) -- MeleeAttack723
            DisableControlAction(0, 1986, true) -- MeleeAttack724
            DisableControlAction(0, 1987, true) -- MeleeAttack725
            DisableControlAction(0, 1988, true) -- MeleeAttack726
            DisableControlAction(0, 1989, true) -- MeleeAttack727
            DisableControlAction(0, 1990, true) -- MeleeAttack728
            DisableControlAction(0, 1991, true) -- MeleeAttack729
            DisableControlAction(0, 1992, true) -- MeleeAttack730
            DisableControlAction(0, 1993, true) -- MeleeAttack731
            DisableControlAction(0, 1994, true) -- MeleeAttack732
            DisableControlAction(0, 1995, true) -- MeleeAttack733
            DisableControlAction(0, 1996, true) -- MeleeAttack734
            DisableControlAction(0, 1997, true) -- MeleeAttack735
            DisableControlAction(0, 1998, true) -- MeleeAttack736
            DisableControlAction(0, 1999, true) -- MeleeAttack737
            DisableControlAction(0, 2000, true) -- MeleeAttack738
            DisableControlAction(0, 2001, true) -- MeleeAttack739
            DisableControlAction(0, 2002, true) -- MeleeAttack740
            DisableControlAction(0, 2003, true) -- MeleeAttack741
            DisableControlAction(0, 2004, true) -- MeleeAttack742
            DisableControlAction(0, 2005, true) -- MeleeAttack743
            DisableControlAction(0, 2006, true) -- MeleeAttack744
            DisableControlAction(0, 2007, true) -- MeleeAttack745
            DisableControlAction(0, 2008, true) -- MeleeAttack746
            DisableControlAction(0, 2009, true) -- MeleeAttack747
            DisableControlAction(0, 2010, true) -- MeleeAttack748
            DisableControlAction(0, 2011, true) -- MeleeAttack749
            DisableControlAction(0, 2012, true) -- MeleeAttack750
            DisableControlAction(0, 2013, true) -- MeleeAttack751
            DisableControlAction(0, 2014, true) -- MeleeAttack752
            DisableControlAction(0, 2015, true) -- MeleeAttack753
            DisableControlAction(0, 2016, true) -- MeleeAttack754
            DisableControlAction(0, 2017, true) -- MeleeAttack755
            DisableControlAction(0, 2018, true) -- MeleeAttack756
            DisableControlAction(0, 2019, true) -- MeleeAttack757
            DisableControlAction(0, 2020, true) -- MeleeAttack758
            DisableControlAction(0, 2021, true) -- MeleeAttack759
            DisableControlAction(0, 2022, true) -- MeleeAttack760
            DisableControlAction(0, 2023, true) -- MeleeAttack761
            DisableControlAction(0, 2024, true) -- MeleeAttack762
            DisableControlAction(0, 2025, true) -- MeleeAttack763
            DisableControlAction(0, 2026, true) -- MeleeAttack764
            DisableControlAction(0, 2027, true) -- MeleeAttack765
            DisableControlAction(0, 2028, true) -- MeleeAttack766
            DisableControlAction(0, 2029, true) -- MeleeAttack767
            DisableControlAction(0, 2030, true) -- MeleeAttack768
            DisableControlAction(0, 2031, true) -- MeleeAttack769
            DisableControlAction(0, 2032, true) -- MeleeAttack770
            DisableControlAction(0, 2033, true) -- MeleeAttack771
            DisableControlAction(0, 2034, true) -- MeleeAttack772
            DisableControlAction(0, 2035, true) -- MeleeAttack773
            DisableControlAction(0, 2036, true) -- MeleeAttack774
            DisableControlAction(0, 2037, true) -- MeleeAttack775
            DisableControlAction(0, 2038, true) -- MeleeAttack776
            DisableControlAction(0, 2039, true) -- MeleeAttack777
            DisableControlAction(0, 2040, true) -- MeleeAttack778
            DisableControlAction(0, 2041, true) -- MeleeAttack779
            DisableControlAction(0, 2042, true) -- MeleeAttack780
            DisableControlAction(0, 2043, true) -- MeleeAttack781
            DisableControlAction(0, 2044, true) -- MeleeAttack782
            DisableControlAction(0, 2045, true) -- MeleeAttack783
            DisableControlAction(0, 2046, true) -- MeleeAttack784
            DisableControlAction(0, 2047, true) -- MeleeAttack785
            DisableControlAction(0, 2048, true) -- MeleeAttack786
            DisableControlAction(0, 2049, true) -- MeleeAttack787
            DisableControlAction(0, 2050, true) -- MeleeAttack788
            DisableControlAction(0, 2051, true) -- MeleeAttack789
            DisableControlAction(0, 2052, true) -- MeleeAttack790
            DisableControlAction(0, 2053, true) -- MeleeAttack791
            DisableControlAction(0, 2054, true) -- MeleeAttack792
            DisableControlAction(0, 2055, true) -- MeleeAttack793
            DisableControlAction(0, 2056, true) -- MeleeAttack794
            DisableControlAction(0, 2057, true) -- MeleeAttack795
            DisableControlAction(0, 2058, true) -- MeleeAttack796
            DisableControlAction(0, 2059, true) -- MeleeAttack797
            DisableControlAction(0, 2060, true) -- MeleeAttack798
            DisableControlAction(0, 2061, true) -- MeleeAttack799
            DisableControlAction(0, 2062, true) -- MeleeAttack800
            DisableControlAction(0, 2063, true) -- MeleeAttack801
            DisableControlAction(0, 2064, true) -- MeleeAttack802
            DisableControlAction(0, 2065, true) -- MeleeAttack803
            DisableControlAction(0, 2066, true) -- MeleeAttack804
            DisableControlAction(0, 2067, true) -- MeleeAttack805
            DisableControlAction(0, 2068, true) -- MeleeAttack806
            DisableControlAction(0, 2069, true) -- MeleeAttack807
            DisableControlAction(0, 2070, true) -- MeleeAttack808
            DisableControlAction(0, 2071, true) -- MeleeAttack809
            DisableControlAction(0, 2072, true) -- MeleeAttack810
            DisableControlAction(0, 2073, true) -- MeleeAttack811
            DisableControlAction(0, 2074, true) -- MeleeAttack812
            DisableControlAction(0, 2075, true) -- MeleeAttack813
            DisableControlAction(0, 2076, true) -- MeleeAttack814
            DisableControlAction(0, 2077, true) -- MeleeAttack815
            DisableControlAction(0, 2078, true) -- MeleeAttack816
            DisableControlAction(0, 2079, true) -- MeleeAttack817
            DisableControlAction(0, 2080, true) -- MeleeAttack818
            DisableControlAction(0, 2081, true) -- MeleeAttack819
            DisableControlAction(0, 2082, true) -- MeleeAttack820
            DisableControlAction(0, 2083, true) -- MeleeAttack821
            DisableControlAction(0, 2084, true) -- MeleeAttack822
            DisableControlAction(0, 2085, true) -- MeleeAttack823
            DisableControlAction(0, 2086, true) -- MeleeAttack824
            DisableControlAction(0, 2087, true) -- MeleeAttack825
            DisableControlAction(0, 2088, true) -- MeleeAttack826
            DisableControlAction(0, 2089, true) -- MeleeAttack827
            DisableControlAction(0, 29, true) -- Enter
            DisableControlAction(0, 75, true) -- ExitVehicle
            DisableControlAction(0, 199, true) -- Pause
            DisableControlAction(0, 200, true) -- PauseMenu
            SetEntityCoords(PlayerPedId(), GetEntityCoords(PlayerPedId())) -- Congelar posición
        end
    end
end)

RegisterNetEvent('EAC:showCaptcha')
AddEventHandler('EAC:showCaptcha', function(captchaImage)
    if Config.CaptchaEnabled then
        SetNuiFocus(true, true)
        SendNUIMessage({
            type = 'showCaptcha',
            captchaImage = captchaImage
        })
        captchaActive = true
    end
end)

RegisterNetEvent('EAC:hideCaptcha')
AddEventHandler('EAC:hideCaptcha', function(success, newCaptchaImage)
    if Config.CaptchaEnabled then
        if success then
            SetNuiFocus(false, false)
            SendNUIMessage({
                type = 'captchaResult',
                success = true
            })
            captchaActive = false
        else
            SendNUIMessage({
                type = 'captchaResult',
                success = false,
                newCaptchaImage = newCaptchaImage
            })
        end
    end
end)

RegisterNUICallback('submitCaptcha', function(data, cb)
    TriggerServerEvent('EAC:submitCaptcha', data.solution)
    cb('ok') -- Importante para que la NUI no se quede esperando
end)
