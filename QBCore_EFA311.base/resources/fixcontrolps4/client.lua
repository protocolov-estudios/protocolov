-- Este script habilita el soporte básico para mandos de PS4 en FiveM.

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)

        -- Deshabilita la entrada del teclado cuando se usa el mando para evitar conflictos
        if IsControlPressed(2, 200) or IsControlPressed(2, 201) then -- Ejemplo: R2 o L2 (botones de gatillo)
            DisableControlAction(2, 1, true)  -- LookLeftRight
            DisableControlAction(2, 2, true)  -- LookUpDown
            DisableControlAction(2, 10, true) -- StandardAttack
            DisableControlAction(2, 24, true) -- Attack
            DisableControlAction(2, 25, true) -- Aim
            DisableControlAction(2, 37, true) -- SelectWeapon
            DisableControlAction(2, 44, true) -- Cover
            DisableControlAction(2, 45, true) -- Reload
            DisableControlAction(2, 58, true) -- EnterVehicle
            DisableControlAction(2, 71, true) -- VehicleAccelerate
            DisableControlAction(2, 72, true) -- VehicleBrake
            DisableControlAction(2, 75, true) -- ExitVehicle
            DisableControlAction(2, 140, true) -- MeleeAttackLight
            DisableControlAction(2, 141, true) -- MeleeAttackHeavy
            DisableControlAction(2, 142, true) -- MeleeAttackAlternate
            DisableControlAction(2, 257, true) -- Attack2
            DisableControlAction(2, 263, true) -- Context
            DisableControlAction(2, 264, true) -- ContextSecondary
        end

        -- Asegura que el juego reconozca la entrada del mando
        EnableControlAction(2, 1, true)   -- LookLeftRight
        EnableControlAction(2, 2, true)   -- LookUpDown
        EnableControlAction(2, 10, true)  -- StandardAttack
        EnableControlAction(2, 24, true)  -- Attack
        EnableControlAction(2, 25, true)  -- Aim
        EnableControlAction(2, 37, true)  -- SelectWeapon
        EnableControlAction(2, 44, true)  -- Cover
        EnableControlAction(2, 45, true)  -- Reload
        EnableControlAction(2, 58, true)  -- EnterVehicle
        EnableControlAction(2, 71, true)  -- VehicleAccelerate
        EnableControlAction(2, 72, true)  -- VehicleBrake
        EnableControlAction(2, 75, true)  -- ExitVehicle
        EnableControlAction(2, 140, true) -- MeleeAttackLight
        EnableControlAction(2, 141, true) -- MeleeAttackHeavy
        EnableControlAction(2, 142, true) -- MeleeAttackAlternate
        EnableControlAction(2, 257, true) -- Attack2
        EnableControlAction(2, 263, true) -- Context
        EnableControlAction(2, 264, true) -- ContextSecondary

        -- Puedes añadir más controles específicos del mando aquí si es necesario
        -- Por ejemplo, para mapear botones específicos del PS4 a acciones del juego.
        -- IsControlJustPressed(2, <control_id>) para detectar una pulsación única
        -- IsControlPressed(2, <control_id>) para detectar si se mantiene pulsado
    end
end)