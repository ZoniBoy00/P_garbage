-- Team management module
Garbage = Garbage or {}
Garbage.Team = {}

-- Local state
local isInTeam = false
local isTeamLeader = false
local teamCode = nil
local teamMembers = {}
local vehicleBlip = nil

-- Team event handlers
RegisterNetEvent('P_garbage:teamCreated')
AddEventHandler('P_garbage:teamCreated', function(code)
    isInTeam = true
    isTeamLeader = true
    teamCode = code
    teamMembers = {}
    
    -- Update job menu to show team options
    OpenJobMenu()
end)

RegisterNetEvent('P_garbage:teamJoined')
AddEventHandler('P_garbage:teamJoined', function(code, isActive)
    isInTeam = true
    isTeamLeader = false
    teamCode = code
    teamMembers = {}
    
    -- If team is already active, sync with the job
    if isActive then
        Notify('primary', Config.GetLocale('team_joined'))
    end
end)

RegisterNetEvent('P_garbage:teamDisbanded')
AddEventHandler('P_garbage:teamDisbanded', function()
    isInTeam = false
    isTeamLeader = false
    teamCode = nil
    teamMembers = {}
    
    -- If on duty, abort the job
    if Garbage.IsOnDuty() then
        AbortJob()
    end
    
    Notify('error', Config.GetLocale('team_leader_left'))
end)

RegisterNetEvent('P_garbage:teamMembersList')
AddEventHandler('P_garbage:teamMembersList', function(members)
    teamMembers = members
end)

RegisterNetEvent('P_garbage:teamJobStarted')
AddEventHandler('P_garbage:teamJobStarted', function(vehicleNetId)
    -- Team member joining the active job
    local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
    
    if vehicle and DoesEntityExist(vehicle) then
        -- Set as job vehicle
        jobVehicle = vehicle
        
        -- Set as on duty
        Garbage.SetOnDuty(true)
        
        -- Notify player
        Notify('primary', Config.GetLocale('team_truck_marked'))
        
        -- Create a blip for the vehicle
        if not DoesBlipExist(vehicleBlip) then
            vehicleBlip = AddBlipForEntity(vehicle)
            SetBlipSprite(vehicleBlip, 318)
            SetBlipColour(vehicleBlip, 2)
            SetBlipScale(vehicleBlip, 0.8)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentString(Config.GetLocale('team_garbage_truck'))
            EndTextCommandSetBlipName(vehicleBlip)
        end
    end
end)

-- Team UI functions
function OpenTeamMenu()
    if lib then
        lib.registerContext({
            id = 'garbage_team_menu',
            title = Config.GetLocale('garbage_job'),
            options = {
                {
                    title = Config.GetLocale('create_team'),
                    description = Config.GetLocale('create_new_team'),
                    icon = 'fa-solid fa-users-gear',
                    onSelect = function() 
                        TriggerServerEvent('P_garbage:createTeam')
                    end
                },
                {
                    title = Config.GetLocale('join_team'),
                    description = Config.GetLocale('join_existing_team'),
                    icon = 'fa-solid fa-user-plus',
                    onSelect = function() 
                        local input = lib.inputDialog(Config.GetLocale('enter_team_code'), {
                            { type = 'input', label = Config.GetLocale('team_code_label'), description = Config.GetLocale('team_code_description'), required = true }
                        })
                        
                        if input then
                            local code = input[1]
                            if code and string.len(code) == 6 then
                                TriggerServerEvent('P_garbage:joinTeam', string.upper(code))
                            else
                                Notify('error', Config.GetLocale('invalid_team_code'))
                            end
                        end
                    end
                }
            }
        })
        
        lib.showContext('garbage_team_menu')
    else
        -- Fallback for non-ox_lib users
        Notify('error', Config.GetLocale('team_functionality'))
    end
end

function OpenTeamManagementMenu()
    if not lib or not isInTeam then return end
    
    -- Request updated team members list
    TriggerServerEvent('P_garbage:getTeamMembers')
    
    -- Wait for server response
    Wait(200)
    
    local options = {
        {
            title = Config.GetLocale('team_code'):format(teamCode),
            description = Config.GetLocale('team_share_code'),
            icon = 'fa-solid fa-hashtag',
            onSelect = function()
                -- Copy to clipboard functionality would go here if available
                Notify('success', Config.GetLocale('team_code'):format(teamCode))
            end
        },
        {
            title = Config.GetLocale('leave_team'),
            description = isTeamLeader and Config.GetLocale('disband_team') or Config.GetLocale('leave_team'),
            icon = 'fa-solid fa-door-open',
            onSelect = function()
                TriggerServerEvent('P_garbage:leaveTeam')
                isInTeam = false
                isTeamLeader = false
                teamCode = nil
                teamMembers = {}
            end
        }
    }
    
    -- Add team members to the menu
    if #teamMembers > 0 then
        table.insert(options, {
            title = Config.GetLocale('team_members'),
            description = Config.GetLocale('team_current_members'),
            icon = 'fa-solid fa-users',
            metadata = {}
        })
        
        -- Add each member as metadata
        local lastOption = options[#options]
        for _, member in ipairs(teamMembers) do
            table.insert(lastOption.metadata, {
                label = member.name,
                value = member.isLeader and Config.GetLocale('team_leader') or Config.GetLocale('team_member')
            })
        end
    end
    
    lib.registerContext({
        id = 'garbage_team_management',
        title = Config.GetLocale('team_management'),
        options = options
    })
    
    lib.showContext('garbage_team_management')
end

-- Function to clean up team resources
function Garbage.Team.CleanupVehicleBlip()
    if DoesBlipExist(vehicleBlip) then
        RemoveBlip(vehicleBlip)
        vehicleBlip = nil
    end
end

-- Function to clean up all team resources
function Garbage.Team.Cleanup()
    Garbage.Team.CleanupVehicleBlip()
    isInTeam = false
    isTeamLeader = false
    teamCode = nil
    teamMembers = {}
end

-- Expose functions
Garbage.Team.IsInTeam = function() return isInTeam end
Garbage.Team.IsLeader = function() return isTeamLeader end
Garbage.Team.GetCode = function() return teamCode end
Garbage.Team.GetMembers = function() return teamMembers end
