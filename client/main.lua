local QBCore = exports['qb-core']:GetCoreObject()

-- State variables (using locals for faster access)
local bags, bagProp, jobVehicle, blip, zoneBlip = 0, nil, nil, nil, nil
local isHoldingBag, isOnDuty, isProcessingAction = false, false, false
local jobNPC, hasInitialized = nil, false
local currentGarbageLocation = nil
local currentBagsCollected = nil
local garbageZones = {} -- Track created zone IDs
local markedBins = {}
local currentGarbageBins = {}
local binMaxUses = {}

-- Team-related variables
local isInTeam, isTeamLeader = false, false
local teamCode, teamMembers, vehicleBlip = nil, {}, nil

-- Initialize player data
local PlayerData = QBCore.Functions.GetPlayerData()

-- Update player data when it changes
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function() PlayerData = QBCore.Functions.GetPlayerData(); InitializeJob() end)
RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo) PlayerData.job = JobInfo; UpdateBlip() end)
RegisterNetEvent('P_garbage:rentVehicleResponse', function(success) if success then ClockIn() end end)

-- Function to spawn the job NPC
function SpawnJobNPC()
    -- Clean up existing NPC
    if jobNPC and DoesEntityExist(jobNPC) then DeleteEntity(jobNPC); jobNPC = nil end
    
    -- Request the model with fallbacks
    local modelName = Config.NPC.Model
    local model = GetHashKey(modelName)
    
    if not IsModelInCdimage(model) then
        modelName = "s_m_y_construct_01"
        model = GetHashKey(modelName)
    end
    
    RequestModel(model)
    
    -- Wait for model to load with timeout
    local timeout = 0
    while not HasModelLoaded(model) and timeout < 50 do Wait(100); timeout = timeout + 1 end
    
    -- Use fallback model if needed
    if not HasModelLoaded(model) then
        modelName = "a_m_y_business_01"
        model = GetHashKey(modelName)
        RequestModel(model)
        timeout = 0
        while not HasModelLoaded(model) and timeout < 50 do Wait(100); timeout = timeout + 1 end
    end
    
    -- Final check if model loaded
    if not HasModelLoaded(model) then return end
    
    -- Create the NPC
    local coords = Config.NPC.Coords
    jobNPC = CreatePed(4, model, coords.x, coords.y, coords.z - 1.0, coords.w, false, true)
    
    -- Verify NPC was created
    if not DoesEntityExist(jobNPC) then SetModelAsNoLongerNeeded(model); return end
    
    -- Set NPC properties
    FreezeEntityPosition(jobNPC, true)
    SetEntityInvincible(jobNPC, true)
    SetBlockingOfNonTemporaryEvents(jobNPC, true)
    
    -- Set NPC animation
    if Config.NPC.Scenario then TaskStartScenarioInPlace(jobNPC, Config.NPC.Scenario, 0, true) end
    
    -- Add target options to the NPC
    if exports.ox_target then
        exports.ox_target:addLocalEntity(jobNPC, {
            {
                name = 'garbage_job_npc',
                label = Config.GetLocale('talk_to_boss'),
                icon = 'fas fa-clipboard',
                distance = 2.5,
                onSelect = function() OpenJobMenu() end,
                canInteract = function() return not isProcessingAction end
            }
        })
    end
    
    SetModelAsNoLongerNeeded(model)
end

-- Function to create/update the blip
function UpdateBlip()
    if blip then RemoveBlip(blip); blip = nil end
    
    local shouldShowBlip = Config.Blip.Show and (not Config.RequireJob or (PlayerData.job and PlayerData.job.name == Config.Job))
    
    if shouldShowBlip then
        blip = AddBlipForCoord(Config.JobClock)
        SetBlipSprite(blip, Config.Blip.Sprite)
        SetBlipScale(blip, Config.Blip.Scale)
        SetBlipColour(blip, Config.Blip.Color)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(Config.GetLocale('garbage_job'))
        EndTextCommandSetBlipName(blip)
    end
end

-- Function to initialize the job
function InitializeJob()
    if hasInitialized then return end
    
    -- Spawn the job NPC
    CreateThread(function()
        Wait(1000)
        SpawnJobNPC()
        UpdateBlip()
    end)
    
    -- Add target options to vehicles
    exports.ox_target:addGlobalVehicle({
        {
            label = Config.GetLocale('put_bag'),
            icon = 'fas fa-trash',
            bones = 'boot',
            distance = 2.0,
            onSelect = function() if not isProcessingAction then DepositBag() end end,
            canInteract = function(entity)
                return isHoldingBag and GetEntityModel(entity) == Config.VehicleHash and not isProcessingAction
            end
        }
    })
    
    hasInitialized = true
end

-- Function to deposit a bag
function DepositBag()
  if not isHoldingBag or isProcessingAction then return end
  
  isProcessingAction = true
  
  -- Start progress bar
  ProgressBar(800, Config.GetLocale('putting_bag'), {dict = 'anim@heists@narcotics@trash', clip = 'throw_b'}, {move = true, mouse = false, combat = true, sprint = true, car = true})
  
  -- Delete bag prop
  if DoesEntityExist(bagProp) then
      SetEntityAsMissionEntity(bagProp, true, true)
      DeleteEntity(bagProp)
  end
  bagProp = nil
  isHoldingBag = false
  
  -- Increment total bags count by the number of bags collected
  local bagsDeposited = currentBagsCollected or 1
  bags = bags + bagsDeposited
  
  -- Log bag deposited
  TriggerServerEvent('P_garbage:logBagDeposited')
  
  -- Notify about the number of bags deposited
  Notify('success', Config.GetLocale('bags_deposited_msg'):format(bagsDeposited))
  
  -- Debug message for bag deposit
  if Config.Debug.Enabled then
      DebugPrint("Debug", "Deposited " .. bagsDeposited .. " garbage bag(s) in the vehicle")
  end
  
  -- Reset current bags collected
  currentBagsCollected = nil
  
  -- Notify if max bags reached
  if bags >= Config.MaxBags then
      Notify('primary', Config.GetLocale('max_bags'))
      
      -- Debug message for max bags
      if Config.Debug.Enabled then
          DebugPrint("Debug", "Maximum number of bags reached (" .. Config.MaxBags .. ")")
      end
  end

  -- Always check if all bins are empty after depositing a bag
  if Config.AutoCreateNewZone and bags > 0 and bags < Config.MaxBags then
      -- Check if all bins are empty
      Garbage.Bins.CheckAllBinsEmpty()
  end
  
  isProcessingAction = false
end

-- Simplify the ClockIn function to use only QBCore's key system
function ClockIn()
    if isOnDuty or isProcessingAction then return end
    
    isProcessingAction = true
    
    ProgressBar(2000, Config.GetLocale('clocking_in'), nil, {move = true, mouse = false, combat = true, sprint = true, car = true})
    
    -- QBCore vehicle spawn
    QBCore.Functions.SpawnVehicle(Config.VehicleModel, function(vehicle)
        if not vehicle or not DoesEntityExist(vehicle) then
            Notify('error', Config.GetLocale('vehicle_spawn_failed'))
            isProcessingAction = false
            return
        end
        
        -- Optimize vehicle setup
        SetEntityHeading(vehicle, Config.VehicleSpawn.w)
        SetVehicleEngineOn(vehicle, true, true)
        SetVehicleDoorsLocked(vehicle, 1) -- Unlock the vehicle
        SetVehicleDirtLevel(vehicle, 0.0) -- Clean vehicle
        SetVehicleModKit(vehicle, 0)
        
        -- Disable unnecessary vehicle features to save resources
        SetVehicleRadioEnabled(vehicle, false)
        SetVehicleHandlingFloat(vehicle, "CHandlingData", "fDriveBiasFront", 0.5) -- Balanced handling
        
        -- Reduce physics calculations
        SetEntityLoadCollisionFlag(vehicle, true)
        SetEntityDynamic(vehicle, true)
        
        Notify('primary', Config.GetLocale('clocked_in'))
        
        -- Get the network ID and give keys
        local netId = NetworkGetNetworkIdFromEntity(vehicle)
        
        -- Ensure the vehicle has a plate
        local plate = GetVehicleNumberPlateText(vehicle)
        if not plate or plate == "" then
            -- Generate a random plate if none exists
            plate = "GARB" .. math.random(1000, 9999)
            SetVehicleNumberPlateText(vehicle, plate)
        end
        
        -- Request vehicle keys from server
        TriggerServerEvent('P_garbage:giveKeys', netId)
        
        -- Also set local keys for QBCore
        TriggerEvent('vehiclekeys:client:SetOwner', plate)
        
        -- Set as job vehicle
        jobVehicle = vehicle
        
        -- If in a team, notify server that job has started
        if Garbage.Team.IsInTeam() and Garbage.Team.IsLeader() then
            TriggerServerEvent('P_garbage:startTeamJob', netId)
        end
        
        -- Log clock-in event
        TriggerServerEvent('P_garbage:logClockIn')
        
        isOnDuty = true
        Garbage.SetOnDuty(true)
        isProcessingAction = false
        
        -- Select a random garbage location
        Garbage.Bins.SelectRandomLocation()
    end, Config.VehicleSpawn, true)
end

-- ClockOut function to handle team payments
function ClockOut(isTeam)
    if not isOnDuty or isProcessingAction then return end
    
    isProcessingAction = true
    
    ProgressBar(2000, Config.GetLocale('clocking_out'), nil, {move = true, mouse = false, combat = true, sprint = true, car = true})
    Notify('primary', Config.GetLocale('clocked_out'))
    
    -- Debug message for clocking out
    if Config.Debug.Enabled then
        DebugPrint("Debug", "Player clocked out and vehicle was returned")
    end
    
    -- Process payment based on whether it's a team or solo job
    if isTeam then
        TriggerServerEvent('P_garbage:teamPay', bags)
    else
        TriggerServerEvent('P_garbage:pay', bags)
    end
    
    -- Clean up resources
    CleanupJob()
    
    isProcessingAction = false
end

-- AbortJob function to handle team aborts
function AbortJob(isTeam)
    if not isOnDuty or isProcessingAction then return end
    
    isProcessingAction = true
    
    Notify('primary', Config.GetLocale('job_aborted'))
    
    -- Clean up resources
    CleanupJob()
    
    isProcessingAction = false
end

-- Function to cleanup job resources
function CleanupJob()
    -- Delete vehicle with proper cleanup
    if jobVehicle and DoesEntityExist(jobVehicle) then
        -- First detach any entities that might be attached
        local attachedEntities = GetAllAttachedEntities(jobVehicle)
        for _, entity in ipairs(attachedEntities) do
            if DoesEntityExist(entity) then
                DetachEntity(entity, true, true)
                SetEntityAsMissionEntity(entity, true, true)
                DeleteEntity(entity)
            end
        end
        
        -- Now delete the vehicle properly
        SetVehicleHasBeenOwnedByPlayer(jobVehicle, false)
        SetEntityAsMissionEntity(jobVehicle, true, true)
        DeleteVehicle(jobVehicle)
        
        -- Force cleanup if entity still exists
        if DoesEntityExist(jobVehicle) then
            SetEntityCoords(jobVehicle, 0.0, 0.0, 0.0, false, false, false, true)
            DeleteVehicle(jobVehicle)
        end
        
        jobVehicle = nil
    end
    
    -- Clear blips
    if zoneBlip and DoesBlipExist(zoneBlip) then 
        RemoveBlip(zoneBlip)
        zoneBlip = nil 
    end
    
    -- Use the Garbage.Bins.Cleanup function to properly clean up bins and zones
    Garbage.Bins.Cleanup()
    
    -- Additional team cleanup
    if DoesBlipExist(vehicleBlip) then
        RemoveBlip(vehicleBlip)
        vehicleBlip = nil
    end
    
    -- Reset state
    jobVehicle = nil
    bags = 0
    isOnDuty = false
    currentGarbageLocation = nil
    
    -- Clean up any bag prop if still holding
    if isHoldingBag and DoesEntityExist(bagProp) then
        SetEntityAsMissionEntity(bagProp, true, true)
        DeleteEntity(bagProp)
        bagProp = nil
        isHoldingBag = false
    end
    
    -- Clean up animation dictionaries
    CleanupAnimDicts()
    
    -- Force garbage collection to free memory
    collectgarbage("collect")
    
    -- Reset any remaining state variables
    currentBagsCollected = nil
    
    -- Clear any remaining timers or threads
    ClearAllThreads()
end

-- Helper function to get all entities attached to a vehicle
function GetAllAttachedEntities(vehicle)
    local attachedEntities = {}
    local objects = GetGamePool('CObject')
    
    for _, object in ipairs(objects) do
        if DoesEntityExist(object) and IsEntityAttachedToEntity(object, vehicle) then
            table.insert(attachedEntities, object)
        end
    end
    
    return attachedEntities
end

-- Helper function to clear all threads
function ClearAllThreads()
    -- This is a placeholder - in FiveM you can't directly clear threads
    -- But we can set flags to stop any running threads in our script
    
    -- Set any thread control flags to false
    -- Example: isThreadRunning = false
end

-- Initialize on resource start
CreateThread(function()
    -- Wait for player to load
    while not QBCore.Functions.GetPlayerData().job do Wait(100) end
    
    -- Clean up any existing NPCs first to prevent duplicates
    local existingPeds = GetGamePool('CPed')
    for _, ped in ipairs(existingPeds) do
        if not IsPedAPlayer(ped) and #(GetEntityCoords(ped) - vector3(Config.NPC.Coords.x, Config.NPC.Coords.y, Config.NPC.Coords.z)) < 2.0 then
            SetEntityAsMissionEntity(ped, true, true)
            DeleteEntity(ped)
        end
    end
    
    PlayerData = QBCore.Functions.GetPlayerData()
    InitializeJob()
end)

-- Resource cleanup
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    -- Clean up entities
    if jobNPC and DoesEntityExist(jobNPC) then DeleteEntity(jobNPC) end
    if bagProp and DoesEntityExist(bagProp) then DeleteEntity(bagProp) end
    if jobVehicle and DoesEntityExist(jobVehicle) then DeleteEntity(jobVehicle) end
    
    -- Clean up blips
    if blip and DoesBlipExist(blip) then RemoveBlip(blip) end
    if zoneBlip and DoesBlipExist(zoneBlip) then RemoveBlip(zoneBlip) end
    if vehicleBlip and DoesBlipExist(vehicleBlip) then RemoveBlip(vehicleBlip) end
    
    -- Clean up target zones
    if exports.ox_target and DoesEntityExist(jobNPC) then 
        pcall(function()
            exports.ox_target:removeLocalEntity(jobNPC)
        end)
    end
end)

-- Add a command to force create a new zone (for emergencies)
RegisterCommand('garbagezone', function()
    if Garbage.IsOnDuty() then
        if Config.Debug.Enabled then
            DebugPrint("Command", "Forcing new garbage zone creation via command")
        end
        Notify('primary', Config.GetLocale('forcing_new_zone'))
        Garbage.Bins.CreateNewZoneMarker()
    else
        Notify('error', Config.GetLocale('must_be_on_duty'))
    end
end, false)

-- Add a periodic check for empty bins
CreateThread(function()
    while true do
        Wait(30000) -- Check every 30 seconds
        
        if Garbage.IsOnDuty() and GetBags() > 0 and GetBags() < Config.MaxBags then
            if Config.Debug.Enabled and Config.Debug.LogBinStatus then
                DebugPrint("BinStatus", "Running periodic empty bin check")
            end
            Garbage.Bins.CheckAllBinsEmpty()
        end
    end
end)

-- Force initialization
CreateThread(function()
    Wait(2000)
    if not hasInitialized then InitializeJob() end
end)

-- Add a periodic cleanup function to ensure resources are freed
CreateThread(function()
    while true do
        Wait(60000) -- Run every minute
        
        -- Force cleanup of any orphaned entities
        if not isOnDuty then
            -- Clean up any leftover props
            local objects = GetGamePool('CObject')
            for _, object in ipairs(objects) do
                if DoesEntityExist(object) then
                    -- Check if this is a garbage bag or temporary bin
                    if GetEntityModel(object) == Config.BagProp then
                        SetEntityAsMissionEntity(object, true, true)
                        DeleteEntity(object)
                    end
                end
            end
            
            -- Force garbage collection
            collectgarbage("collect")
        end
    end
end)

-- Expose functions to other files
function GetBags() return bags end
function SetBags(value) bags = value end
function GetJobVehicle() return jobVehicle end
function Garbage.IsOnDuty() 
    return isOnDuty 
end
function SetOnDuty(value) isOnDuty = value end
function IsProcessingAction() return isProcessingAction end
function SetProcessingAction(value) isProcessingAction = value end
function IsHoldingBag() return isHoldingBag end
function SetHoldingBag(value) isHoldingBag = value end
function GetBagProp() return bagProp end
function SetBagProp(value) bagProp = value end
function SetCurrentBagsCollected(value) currentBagsCollected = value end
function GetCurrentBagsCollected() return currentBagsCollected end
function GetCurrentLocation() return currentGarbageLocation end
function SetCurrentLocation(value) currentGarbageLocation = value end
function GetZoneBlip() return zoneBlip end
function SetZoneBlip(value) zoneBlip = value end
function AddGarbageZone(id) table.insert(garbageZones, id) end
function GetGarbageZones() return garbageZones end
function ClearGarbageZones() garbageZones = {} end
