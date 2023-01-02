print("[ULC]: Park Patterns Loaded")

local veh = GetVehiclePedIsIn(PlayerPedId())
local parked = false
local lastSync = 0

function AreChecksPassed()

    if Config.ParkSettings.checkDoors then
        if not AreVehicleDoorsClosed(veh) then
            --print("A door was open, not setting park pattern.")
            return false
        end
    end

    if not IsVehicleHealthy(vehicle) then
        return false
    end

    return true
end

CreateThread(function()
    while true do
        if IsPedInAnyVehicle(PlayerPedId()) then

            TriggerEvent('ulc:checkParkState', veh, false)

            Wait(Config.ParkSettings.delay*1000)
        else
            Wait(2000)
        end
    end
end)

RegisterNetEvent("ulc:checkParkState", function(vehicle, delay)
    CreateThread(function()
        --print('Checking park state')

        if delay then 
            --print('Delay...')
            Wait(5000)
        end

        veh = GetVehiclePedIsIn(PlayerPedId())
        local speed = GetVehicleSpeedConverted(vehicle)

        --if parked then
            if speed > Config.ParkSettings.speedThreshold and parked then
                TriggerEvent("ulc:vehDrive")
                SendNUIMessage({
                    type = 'toggleParkIndicator',
                    state = false
                })
            end
        --else
            if speed < Config.ParkSettings.speedThreshold and not parked then
                TriggerEvent('ulc:vehPark')
                SendNUIMessage({
                    type = 'toggleParkIndicator',
                    state = true
                })
            end
        --end
    end)
end)

AddEventHandler('ulc:vehPark', function()
    
    if Lights then
		--print('[ulc:vehPark] My vehicle is parked.')
        parked = true
        local passed, vehConfig = GetVehicleFromConfig(veh)

        if passed and AreChecksPassed() and vehConfig.parkConfig.usePark then
            -- enable parkExtras
            for k,v in pairs(vehConfig.parkConfig.parkExtras) do
                SetStageByExtra(v, 0, false)
            end
            -- disable driveExtras
            for k,v in pairs(vehConfig.parkConfig.driveExtras) do
                SetStageByExtra(v, 1, false)
            end

            -- park pattern sync stuff
            if vehConfig.parkConfig.useSync then

                -- cooldown
                local gameSeconds = GetGameTimer() / 1000
                if gameSeconds >= lastSync + Config.ParkSettings.syncCooldown then
                    lastSync = gameSeconds

                    local loadedVehicles = GetGamePool("CVehicle")
                    --print(#loadedVehicles .. " vehicles in pool")
                    local vehsToSync = {}

                    for k, v in pairs(loadedVehicles) do
                        -- don't include my vehicle
                        if v ~= veh then
                            local vehCoords = GetEntityCoords(v)
                            local pedCoords = GetEntityCoords(PlayerPedId())
                            local distance = GetDistanceBetweenCoords(vehCoords, pedCoords)

                           
                            if distance < Config.ParkSettings.syncDistance then
                                if GetVehicleClass(v) == 18 then
                                    -- check if my vehicle is set to sync with this vehicle
                                    if IsVehicleInTable(v, vehConfig.parkConfig.syncWith) then
                                        --print('Vehicle' .. v .. ' should sync with me.')

                                        local speed = GetVehicleSpeedConverted(veh)

                                        if speed < Config.ParkSettings.speedThreshold then
                                            --print("Found an eligible sync vehicle.")
                                            table.insert(vehsToSync, v)
                                        end
                                    end
                                end
                            end
                        end
                    end
                    if #vehsToSync > 0 then

                        -- sync my vehicle
                        SetVehicleSiren(veh, false)
                        SetVehicleSiren(veh, true)

                        -- sync other vehicles on my screen
                        for k, v in pairs(vehsToSync) do
                            SetVehicleSiren(v, false)
                            SetVehicleSiren(v, true)
                        end

                        -- send sync to other clients nearby
                        --print("Preparing to send sync to server")
                        local vehsToSyncNet = {}
                        for k, v in pairs(vehsToSync) do
                            --print("Candidate: " .. VehToNet(v))
                            table.insert(vehsToSyncNet, VehToNet(v))
                        end
                        TriggerServerEvent("sync:send", vehsToSyncNet)

                    else --print('Found no vehicles to sync.')
                    end

                else print("Sync on cooldown, time left: " .. Config.ParkSettings.syncCooldown- (gameSeconds - lastSync) .. " seconds.")
                end
            end
        end
    end
end)

RegisterNetEvent('ulc:sync:receive', function(vehicles)
    --print("[sync:receive] Trying to sync " .. #vehicles .. " vehicles.")
    for k, v in pairs(vehicles) do
        --print("Attempting to sync: " .. NetToVeh(v))
        SetVehicleSiren(NetToVeh(v), false)
        SetVehicleSiren(NetToVeh(v), true)
    end
end)

AddEventHandler('ulc:vehDrive', function()

    if Lights then
		--print('[ulc:vehDrive] My vehicle is driving.')
        parked = false
        local passed, vehConfig = GetVehicleFromConfig(veh)
        if passed and AreChecksPassed() and vehConfig.parkConfig.usePark then

            -- disable parkExtras
            for k,v in pairs(vehConfig.parkConfig.parkExtras) do
                SetStageByExtra(v, 1, false)
            end
            -- enable driveExtras
            for k,v in pairs(vehConfig.parkConfig.driveExtras) do
                SetStageByExtra(v, 0, false)
            end
        end
    end
end)