print("Server thread loaded.")

AddEventHandler('ulc:error', function(error)
  print("^1[ULC ERROR] " .. error)
end)

AddEventHandler('ulc:warn', function(error)
  print("^3[ULC WARNING] " .. error)
end)

local myVersion = GetResourceMetadata("ulc", "version", 0)
local latestVersion = ''

if GetCurrentResourceName() ~= 'ulc' then
  TriggerEvent('ulc:error', "Resource is named incorrectly. Version checks will not work.")
end

PerformHttpRequest("https://api.github.com/repos/Flohhhhh/ultimate-lighting-controller/releases/latest", function (errorCode, resultData, resultHeaders)

  print("My Version: [" .. myVersion .. "]")

  local errorString = tostring(errorCode)
  if errorString == "403" or errorString == "404" then
    print("Got code " .. errorString .. " when trying to get version.")
    return
  end

  latestVersion = json.decode(resultData).name
  print("^0Latest Version: [" .. latestVersion .. "]")

  print([[
    ___  ___   ___        ________     
   |\  \|\  \ |\  \      |\   ____\    
   \ \  \\\  \\ \  \     \ \  \___|    
    \ \  \\\  \\ \  \     \ \  \       
     \ \  \\\  \\ \  \____ \ \  \____  
      \ \_______\\ \_______\\ \_______\
       \|_______| \|_______| \|_______|
  
    ULTIMATE LIGHTING CONTROLLER
    by Dawnstar
    ^2Loaded
 ]])
  if myVersion and ("v" .. myVersion) == latestVersion then
    print('Up to date!')
  else
    print("^1ULC IS OUTDATED. A NEW VERSION (" .. latestVersion .. ") IS AVAILABLE.^0")
    print("^1YOUR VERSION: " .. myVersion .. "^0")
    print("GET LATEST VERSION HERE: https://github.com/Flohhhhh/ultimate-lighting-controller/releases/")
  end
end)


local function IsIntInTable(table, int)
  for k, v in ipairs(table) do
      if v == int then
          return true
      end
  end
  return false
end

if Config.ParkSettings.delay < 0.5 then
    TriggerEvent("ulc:warn", 'Park Pattern delay is too short! This will hurt performance! Recommended values are above 0.5s.')
end

if Config.SteadyBurnSettings.delay <= 2 then
    TriggerEvent("ulc:error", 'Steady burn delay is too short! Steady burns will be unstable or not work!')
end

if Config.SteadyBurnSettings.nightStartHour < Config.SteadyBurnSettings.nightEndHour then
    TriggerEvent("ulc:error", 'Steady burn night start hour should be later/higher than night end hour.')
end

if Config.SteadyBurnSettings.delay < 2 then
    TriggerEvent("ulc:error", "Steady burn check delay can never be lower than 2 seconds. Will cause stability issues.")
end

local function CheckData(data, resourceName)

  if not data.name and not data.names then
      TriggerEvent("ulc:error", "^1Vehicle config in resource \"" .. resourceName .. "\" does not include model names!^0")
      return false
  elseif data.name then
    TriggerEvent("ulc:warn", "^1Vehicle config in resource \"" .. resourceName .. "\" uses deprecated 'name' field. Change to > names = {'yourvehicle'}^0")
    if type(data.name) ~= "string" then 
      TriggerEvent("ulc:error", "^1Vehicle config in resource \"" .. resourceName .. "\" 'name' field can only accept a string.^0")
      return false
    end
  elseif data.names then
    if type(data.names) ~= "table" then
      TriggerEvent("ulc:error", "^1Vehicle config in resource \"" .. resourceName .. "\" 'names' field can only accept a table of strings.^0")
      return false
    end
  end

  -- check if data is missing
  if not data.parkConfig or not data.brakeConfig or not data.buttons or not data.hornConfig then
    TriggerEvent("ulc:error", "^1Vehicle config in resource \"" .. resourceName .. "\" is missing data or not formatted properly. View docs.^0")
    return false
  end

  -- check if steady burns are enabled but no extras specified
  if (data.steadyBurnConfig.forceOn or data.steadyBurnConfig.useTime) and #data.steadyBurnConfig.sbExtras == 0 then
      TriggerEvent("ulc:warn", 'A config in "' .. resourceName .. '" uses Steady Burns, but no extras were specified (sbExtras = {})')
  end

  -- check if park pattern enabled but no extras specified
  if data.parkConfig.usePark then
      if #data.parkConfig.pExtras == 0 and #data.parkConfig.dExtras == 0 then
          TriggerEvent("ulc:warn", 'A config in "' .. resourceName .. '" uses Park Patterns, but no park or drive extras were specified (pExtras = {}, dExtras = {})')
      end

      if data.parkConfig.useSync and #data.parkConfig.syncWith == 0 then
        TriggerEvent("ulc:warn", 'A config in "' .. resourceName .. '" uses Park Pattern Syncing, but no other vehicle models were specified (syncWith = {})')
      end
  end

  -- check if brakes enabled but no extras specified
  if data.brakeConfig.useBrakes and #data.brakeConfig.brakeExtras == 0 then
      TriggerEvent("ulc:warn", 'A config in "' .. resourceName .. '" uses Brake Pattern, but no brake extras were specified.')
  end

  -- check if horn enabled but no extras specified
  if data.hornConfig.useHorn and #data.hornConfig.hornExtras == 0 then
    TriggerEvent("ulc:warn", 'A config in "' .. resourceName .. '" uses Horn Extras, but no horn extras were specified.')
  end

  --------------------
  -- DEFAULT STAGES --
  --------------------
  if data.defaultStages or false then
    if data.defaultStages.useDefaults then
      if #data.defaultStages.enableKeys == 0 then
        TriggerEvent("ulc:warn", 'A config in "'.. resourceName .. '" uses Default Stages, but no keys were specified to enable (enableKeys = {}).')
      else
        for _, v in pairs(data.defaultStages.enableKeys) do
          if v > 9 then
            TriggerEvent("ulc:error", 'A config in "'.. resourceName .. '" has an invalid key in enableKeys = {}. Value must be 1-9 representing numpad keys.')
          end
        end
      end
      if #data.defaultStages.disableKeys == 0 then
        TriggerEvent("ulc:warn", 'A config in "'.. resourceName .. '" uses Default Stages, but no keys were specified to disable (disableKeys = {}).')
      else
        for _, v in pairs(data.defaultStages.disableKeys) do
          if v > 9 then
            TriggerEvent("ulc:error", 'A config in "'.. resourceName .. '" has an invalid key in disableKeys = {}. Value must be 1-9 representing numpad keys.')
          end
        end
      end
    end
  end


  -- Buttons
  -- check if vehicle uses buttons but hud is disabled
  if #data.buttons > 0 and Config.hideHud == true then
    TriggerEvent("ulc:warn", 'A config in "' .. resourceName .. '" uses Stage Buttons, but HUD/UI is globally disabled. This is not recommended for user experience.')
  end

  local usedButtons = {}
  local usedExtras = {}
  for i, b in ipairs(data.buttons) do
      -- check if key is valid
      if b.key > 9 or b.key < 1 then
          TriggerEvent('ulc:error', 'Button ' .. i .. ' in a config found in the resource: "' .. resourceName .. '" has an invalid key. Key must be 1-9 representing number pad keys.')
          return false
      end
      -- check if label is empty
      if b.label == '' then
          TriggerEvent("ulc:error", 'A config in "' .. resourceName .. '" has an un-labeled button using extra: ' .. b.extra)
          return false
      end
      -- check if any keys are used twice
      if IsIntInTable(usedButtons, b.key) then
          TriggerEvent("ulc:error", 'A config in "' .. resourceName .. '" uses key: " .. b.key .. " more than once in button config.')
          return false
      end
      -- check if any extras are used twice
      if IsIntInTable(usedExtras, b.extra) then
          TriggerEvent("ulc:error", 'A config in "' .. resourceName .. '" uses extra: " .. b.extra .. " more than once in button config.')
          return false
      end
  end
  return true
end

RegisterNetEvent('baseevents:enteredVehicle')
AddEventHandler('baseevents:enteredVehicle', function()
  local src = source
  TriggerClientEvent("UpdateVehicleConfigs", src , Config.Vehicles)
  TriggerClientEvent('ulc:checkVehicle', src)
end)

RegisterNetEvent('baseevents:leftVehicle')
AddEventHandler('baseevents:leftVehicle', function()
  local src = source
  TriggerClientEvent('ulc:cleanup', src)
end)

RegisterNetEvent('ulc:sync:send')
AddEventHandler('ulc:sync:send', function(vehicles)
    print("Player ".. source .. " sent a sync request.")
    local players = GetPlayers()
    for i,v in ipairs(players) do
        if not v == source then 
            --print("Sending veh sync array to player: " .. v)
            TriggerClientEvent('ulc:sync:receive', vehicles)
        end
    end
end)


local function LoadExternalVehicleConfig(resourceName)
  local resourceState = GetResourceState(resourceName)

  if resourceState == "missing" then
    TriggerEvent("ulc:error", "^1Couldn't load external ulc.lua file from resource: \"" .. resourceName .. "\". Resource is missing.^0")
    return
  end

  if resourceState == "stopped" then
    TriggerEvent("ulc:error", "^1Couldn't load external ulc.lua file from resource: \"" .. resourceName .. "\". Resource is stopped.^0")
    return
  end

  if resourceState == "uninitialized" or resourceState == "unknown" then
    TriggerEvent("ulc:error", "^1Couldn't load external ulc.lua file from resource: \"" .. resourceName .. "\". Resource could not be loaded. Unknown issue.^0" )
    return
  end

  local data = LoadResourceFile(resourceName, "data/ulc.lua")
  if not data then
    data = LoadResourceFile(resourceName, "ulc.lua")
    if not data then
      print("Error loading 'ulc.lua' file. Make sure it is at the root of your resource or in the 'data' folder.")
      TriggerEvent("ulc:error", '^1Could not load external configuration in: "' .. resourceName .. '"^0')
      return
    end
  end

  local f, err = load(data)
  if err then
    TriggerEvent("ulc:error", '^1Could not load external configuration in: "' .. resourceName .. '"; error: "' .. err .. '"^0')
    return
  end
  if not f or not f() then
    TriggerEvent("ulc:error", '^1Could not load external configuration; data loaded from: "' .. resourceName .. '" was nil. ^0')
    return
  end

  -- NEW STUFF FOR MULTIPLE CONFIGS
  local configs = {f()}
  for _, v in pairs(configs) do
    if CheckData(v, resourceName) then
      if v.name then -- if using old single name
        print('^2Loaded external configuration for "' .. v.name .. '"^0')
      elseif v.names then -- if using new table
        for _, name in ipairs(v.names) do
          print('^2Loaded external configuration for "' .. name .. '"^0')
        end
      end
      
      table.insert(Config.Vehicles, v)
    else
      TriggerEvent("ulc:error", '^1Could not load external configuration in "' .. resourceName .. '"^0')
    end
  end

  -- if CheckData(f(), resourceName) then
  --   print('^2Loaded external configuration for "' .. f().name .. '"^0')
  --   table.insert(Config.Vehicles, f())
  -- else
  --   TriggerEvent("ulc:error", '^1Could not load external configuration for "' .. f().name .. '"^0')
  -- end
end

CreateThread(function ()
  Wait(2000)
  print("[ULC] Checking for external vehicle resources.")
  for k, v in ipairs(Config.ExternalVehResources) do
    local resourceState = GetResourceState(v)
    while resourceState == "starting" do
      print("^3Waiting for resource: " .. resourceName .. " to load.")
      Wait(100)
    end
    LoadExternalVehicleConfig(v)
  end
  TriggerClientEvent('ulc:Loaded', -1)
  --GlobalState.ulcloaded = true
  TriggerClientEvent("UpdateVehicleConfigs", -1 , Config.Vehicles)
  print("Done loading external vehicle resources.")
  for _, v in ipairs(Config.Vehicles) do
    if v.name then -- if using old single name
      print('Loaded: ' .. v.name)
    elseif v.names then -- if using new table
      for _, name in ipairs(v.names) do
        print('Loaded: ' .. name)
      end
    end
  end
end)

