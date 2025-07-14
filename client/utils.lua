local QBCore = exports['qb-core']:GetCoreObject()

-- Utilities module
Garbage = Garbage or {}
Garbage.Utils = {}

-- Add these variables at the top of the file
local isOnDuty = false

-- Add this function to access the variable
function Garbage.IsOnDuty()
    return isOnDuty
end

-- Add this function to set the variable
function Garbage.SetOnDuty(value)
    isOnDuty = value
end

-- Cache lib reference to avoid repeated lookups
local lib = lib
local loadedDicts = {}

-- Debug function
function DebugPrint(type, message)
    if not Config.Debug.Enabled then return end
    
    -- Print to console for debugging
    print("[P_garbage] DEBUG: " .. type .. ": " .. message)
end

-- Simplify the notification function
function Notify(type, message)
    if not type or not message then return end
    
    -- Print to console for debugging if debug is enabled
    if Config.Debug.Enabled then
        print("[P_garbage] " .. type .. ": " .. message)
    end
    
    if Config.Notify == 'qb' then
        QBCore.Functions.Notify(message, type)
    elseif Config.Notify == 'ox' and lib then
        lib.notify({type = type, title = Config.GetLocale('garbage_job'), description = message})
    end
end

-- Simplify the progress bar function
function ProgressBar(length, text, animTable, disableTable)
    if not length or not text then return end
    
    -- Set default values for missing parameters
    animTable = animTable or {}
    disableTable = disableTable or {move = false, car = false, mouse = false, combat = false}
    
    if Config.Progress == 'circle' and lib then
        return lib.progressCircle({
            duration = length,
            label = text,
            position = 'bottom',
            useWhileDead = false,
            canCancel = false,
            disable = disableTable,
            anim = animTable
        })
    elseif Config.Progress == 'bar' and lib then
        return lib.progressBar({
            duration = length,
            label = text,
            position = 'bottom',
            useWhileDead = false,
            canCancel = false,
            disable = disableTable,
            anim = animTable
        })
    else
        -- Fallback to QBCore progress bar
        return QBCore.Functions.Progressbar("garbage_job", text, length, false, false, {
            disableMovement = not disableTable.move,
            disableCarMovement = not disableTable.car,
            disableMouse = not disableTable.mouse,
            disableCombat = not disableTable.combat,
        }, animTable, {}, {}, function() end)
    end
end

-- Optimized animation dictionary loading
function Garbage.Utils.LoadAnimDict(dict)
    if not dict then return false end
    if loadedDicts[dict] then return true end
    
    if not HasAnimDictLoaded(dict) then
        RequestAnimDict(dict)
        
        -- Use a timeout to prevent infinite loops
        local timeout = 0
        while not HasAnimDictLoaded(dict) and timeout < 50 do
            Wait(10)
            timeout = timeout + 1
        end
        
        -- If loading failed, return false
        if not HasAnimDictLoaded(dict) then
            return false
        end
    end
    
    loadedDicts[dict] = true
    return true
end

-- Function to clean up loaded animation dictionaries
function Garbage.Utils.CleanupAnimDicts()
    for dict in pairs(loadedDicts) do
        if HasAnimDictLoaded(dict) then
            RemoveAnimDict(dict)
        end
    end
    
    loadedDicts = {}
end

-- Optimized resource management
function Garbage.Utils.OptimizeMemory()
    -- Clear unnecessary caches
    collectgarbage("collect")
    
    -- Unload unused models
    SetModelAsNoLongerNeeded(GetHashKey(Config.NPC.Model))
    SetModelAsNoLongerNeeded(GetHashKey(Config.VehicleModel))
    
    -- Clear any streaming requests
    ClearFocus()
    ClearPedTasks(PlayerPedId())
    
    -- Clear area of non-mission entities
    ClearAreaOfObjects(GetEntityCoords(PlayerPedId()), 100.0, 0)
end

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
                canInteract = function() return not Garbage.IsProcessingAction() end
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

-- Function to open the job menu with team options
function OpenJobMenu()
    if lib then
        if not Garbage.IsOnDuty() then
            local options = {}
            
            if Garbage.Team.IsInTeam() then
                -- Team options
                if Garbage.Team.IsLeader() then
                    -- Team leader options
                    table.insert(options, {
                        title = Config.GetLocale('team_management'),
                        description = Config.GetLocale('view_team'),
                        icon = 'fa-solid fa-users-gear',
                        onSelect = function() OpenTeamManagementMenu() end
                    })
                    
                    table.insert(options, {
                        title = Config.GetLocale(Config.Context.ClockIn.Title),
                        description = Config.GetLocale(Config.Context.ClockIn.Description),
                        icon = Config.Context.ClockIn.Icon,
                        onSelect = function() TriggerServerEvent('P_garbage:rentVehicle') end,
                        metadata = {
                            {label = Config.GetLocale('rental_cost'), value = '$' .. Config.RentalCost}
                        }
                    })
                else
                    -- Team member options
                    table.insert(options, {
                        title = Config.GetLocale('view_team'),
                        description = Config.GetLocale('team_members'),
                        icon = 'fa-solid fa-users',
                        onSelect = function() OpenTeamManagementMenu() end
                    })
                    
                    table.insert(options, {
                        title = Config.GetLocale('wait_for_leader'),
                        description = Config.GetLocale('leader_must_start'),
                        icon = 'fa-solid fa-hourglass',
                        disabled = true
                    })
                end
            else
                -- Solo/team selection options
                table.insert(options, {
                    title = Config.GetLocale(Config.Context.ClockInAlone.Title),
                    description = Config.GetLocale(Config.Context.ClockInAlone.Description),
                    icon = Config.Context.ClockInAlone.Icon,
                    onSelect = function() TriggerServerEvent('P_garbage:rentVehicle') end,
                    metadata = {
                        {label = Config.GetLocale('rental_cost'), value = '$' .. Config.RentalCost}
                    }
                })
                
                table.insert(options, {
                    title = Config.GetLocale(Config.Context.ClockInTeam.Title),
                    description = Config.GetLocale(Config.Context.ClockInTeam.Description),
                    icon = Config.Context.ClockInTeam.Icon,
                    onSelect = function() OpenTeamMenu() end
                })
            end
            
            lib.registerContext({
                id = 'garbage_job_menu',
                title = Config.GetLocale(Config.Context.Title),
                options = options
            })
        else
            -- On duty menu
            local options = {
                {
                    title = Config.GetLocale(Config.Context.ClockOut.Title),
                    description = Config.GetLocale(Config.Context.ClockOut.Description),
                    icon = Config.Context.ClockOut.Icon,
                    onSelect = function() 
                        if Garbage.Team.IsInTeam() and Garbage.Team.IsLeader() then
                            -- Team leader clocking out
                            ClockOut(true) 
                        elseif not Garbage.Team.IsInTeam() then
                            -- Solo player clocking out
                            ClockOut(false)
                        else
                            -- Team member can't clock out the whole team
                            Notify('error', Config.GetLocale('team_leader_only'))
                        end
                    end,
                    metadata = {
                        {label = Config.GetLocale('bags_collected'), value = GetBags()},
                        {label = Config.GetLocale('estimated_pay'), value = '$' .. (GetBags() * Config.PayPerBag)}
                    }
                },
                {
                    title = Config.GetLocale(Config.Context.Abort.Title),
                    description = Config.GetLocale(Config.Context.Abort.Description),
                    icon = Config.Context.Abort.Icon,
                    onSelect = function() 
                        if Garbage.Team.IsInTeam() and Garbage.Team.IsLeader() then
                            -- Team leader aborting
                            AbortJob(true)
                        elseif not Garbage.Team.IsInTeam() then
                            -- Solo player aborting
                            AbortJob(false)
                        else
                            -- Team member leaving
                            TriggerServerEvent('P_garbage:leaveTeam')
                            AbortJob(false)
                        end
                    end
                }
            }
            
            if Garbage.Team.IsInTeam() then
                table.insert(options, 1, {
                    title = Config.GetLocale('team_management'),
                    description = Config.GetLocale('view_team'),
                    icon = 'fa-solid fa-users',
                    onSelect = function() OpenTeamManagementMenu() end
                })
            end
            
            lib.registerContext({
                id = 'garbage_job_menu',
                title = Config.GetLocale(Config.Context.Title),
                options = options
            })
        end
        
        lib.showContext('garbage_job_menu')
    else
        -- Fallback for non-ox_lib users
        if not Garbage.IsOnDuty() then ClockIn() else ClockOut(false) end
    end
end

-- Function to clean up team resources
function CleanupAnimDicts()
    Garbage.Utils.CleanupAnimDicts()
end
