-- Ultimate Lighting Controller by Dawnstar FiveM
-- Written by Dawnstar
-- For support: https://discord.gg/dwnstr-fivem

Config = {
    -- whether to mute beep when sirens/lights are turned on and off;
    -- should be true if using another resource that adds a beep (ex. Luxart V3)
    muteBeepForLights = true,
    -- whether to use KPH instead of MPH
    useKPH = false,
    -- health threshold disables these effects while vehicle is damaged to prevent unrealistic repairs upon crashing
    healthThreshold = 990, -- 999 would disable effect with ANY damage to vehicle, between 900-999 are good values

    -- Park Pattern Settings;
    ParkSettings = {
        -- extras will toggle below this speed
        speedThreshold = 1,
        -- check if any doors are fully open before executing effect (prevents doors from always snapping shut)
        checkDoors = true,
        -- time between checks in seconds
        -- should not be any lower than .5 seconds
        delay = 0.5,
        -- distance at which to check for other vehicles to sync patterns with
        syncDistance = 32,
        -- seconds before a single client triggers sync again 
        syncCooldown = 10,
    },

    -- Steady Burn Config;
    -- changes settings for extras that are enabled at night, or enabled all the time.
    SteadyBurnSettings = {
        -- hour effect starts (extras are enabled)
        nightStartHour = 18,
        -- hour effect ends (extras are disabled)
        nightEndHour = 6,
        -- time between checks in seconds
        -- should be high (checks also occur when entering vehicle)
        -- should NEVER be lower than 2 seconds (bad things will happen)
        delay = 10,
    },

    -- Brake Extras/Patterns Config;
    BrakeSettings = {
        -- brake pattern will not activate below this speed
        -- if it's already active while you brake from 50 - 30 it will stay active until you release brakes
        speedThreshold = 30
    },

    -- the resource names of vehicle resources that include a ulc.lua config file
    ExternalVehResources = {
        -- ex. "my-police-vehicle",
    },

    Vehicles = {
        --[[
        {name = 'example', -- Vehicle Spawn Name
        
            -- Steady Burn/Alaways On Settings
            steadyBurnConfig = {
                forceOn = false,
                useTime = true,
                sbExtras = {1}
            },

            -- Park Pattern Settings
            parkConfig = {
                usePark = true,
                useSync = true,
                syncWith = {'example', 'sp18chrg'},
                pExtras = {10, 11},
                dExtras = {2}
            },

            -- Extras on Airhorn (E key)
            -- Could be scene lighting or another pattern
            hornConfig = {
                useHorn = true,
                hornExtras = {12}
            },

            -- Brake Lights/Patterns Settings;
            -- Could be another pattern or extra brake lights
            brakeConfig = {
                useBrakes = false,
                brakeExtras = {12}
            },

            -- Stage Control Button Mappings
            -- label = text that appears on the button 
            -- key = key that the button uses (num pad numbers)
            -- extra = extra that is toggled by the button
            buttons = {
                {label = 'EXAMPLE', key = 1, extra = 1},
                {label = 'EXAMPLE2', key = 5, extra = 8},
            }
        },
        ]]
    }
}
