local QBCore = exports['qb-core']:GetCoreObject()

-- Team management
local teams = {}
local playerTeams = {}

-- Generate a random team code
local function GenerateTeamCode()
    local code = ""
    for i = 1, 6 do
        code = code .. string.char(math.random(65, 90)) -- A-Z
    end
    return code
end

-- Create a new team
RegisterNetEvent('P_garbage:createTeam')
AddEventHandler('P_garbage:createTeam', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- Check if player is already in a team
    if playerTeams[src] then
        Notify(src, 'error', Config.GetLocale('team_already_in'))
        return
    end
    
    -- Generate a unique team code
    local teamCode = GenerateTeamCode()
    while teams[teamCode] do
        teamCode = GenerateTeamCode()
    end
    
    -- Create the team
    teams[teamCode] = {
        leader = src,
        members = {src},
        vehicle = nil,
        bags = 0,
        active = false
    }
    
    -- Add player to team
    playerTeams[src] = teamCode
    
    -- Notify player
    Notify(src, 'success', Config.GetLocale('team_created'):format(teamCode))
    
    -- Send team code to client
    TriggerClientEvent('P_garbage:teamCreated', src, teamCode)
end)

-- Join an existing team
RegisterNetEvent('P_garbage:joinTeam')
AddEventHandler('P_garbage:joinTeam', function(teamCode)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- Check if player is already in a team
    if playerTeams[src] then
        Notify(src, 'error', Config.GetLocale('team_already_in'))
        return
    end
    
    -- Check if team exists
    if not teams[teamCode] then
        Notify(src, 'error', Config.GetLocale('team_not_found'))
        return
    end
    
    -- Check if team is full
    if #teams[teamCode].members >= Config.TeamWork.MaxTeamSize then
        Notify(src, 'error', Config.GetLocale('team_full'))
        return
    end
    
    -- Add player to team
    table.insert(teams[teamCode].members, src)
    playerTeams[src] = teamCode
    
    -- Notify player
    Notify(src, 'success', Config.GetLocale('team_joined'))
    
    -- Notify team members
    local playerName = Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname
    for _, memberId in ipairs(teams[teamCode].members) do
        if memberId ~= src then
            Notify(memberId, 'primary', Config.GetLocale('team_member_joined'):format(playerName))
        end
    end
    
    -- Send team data to client
    TriggerClientEvent('P_garbage:teamJoined', src, teamCode, teams[teamCode].active)
    
    -- If team is already active, sync the job state
    if teams[teamCode].active and teams[teamCode].vehicle then
        TriggerClientEvent('P_garbage:teamJobStarted', src, teams[teamCode].vehicle)
    end
end)

-- Leave team
RegisterNetEvent('P_garbage:leaveTeam')
AddEventHandler('P_garbage:leaveTeam', function()
    local src = source
    
    -- Check if player is in a team
    local teamCode = playerTeams[src]
    if not teamCode or not teams[teamCode] then return end
    
    local team = teams[teamCode]
    local isLeader = team.leader == src
    
    -- Get player name
    local Player = QBCore.Functions.GetPlayer(src)
    local playerName = "Unknown"
    if Player then
        playerName = Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname
    end
    
    -- Remove player from team
    for i, memberId in ipairs(team.members) do
        if memberId == src then
            table.remove(team.members, i)
            break
        end
    end
    
    -- Clear player's team
    playerTeams[src] = nil
    
    -- If leader left, disband team
    if isLeader then
        -- Notify all members
        for _, memberId in ipairs(team.members) do
            Notify(memberId, 'error', Config.GetLocale('team_leader_left'))
            TriggerClientEvent('P_garbage:teamDisbanded', memberId)
            playerTeams[memberId] = nil
        end
        
        -- Remove team
        teams[teamCode] = nil
        
        -- Notify player
        Notify(src, 'primary', Config.GetLocale('team_disbanded'))
    else
        -- Notify remaining members
        for _, memberId in ipairs(team.members) do
            Notify(memberId, 'primary', Config.GetLocale('team_member_left'):format(playerName))
        end
        
        -- Notify player
        Notify(src, 'primary', Config.GetLocale('team_left'))
    end
end)

-- Start team job
RegisterNetEvent('P_garbage:startTeamJob')
AddEventHandler('P_garbage:startTeamJob', function(vehicleNetId)
    local src = source
    
    -- Check if player is in a team and is the leader
    local teamCode = playerTeams[src]
    if not teamCode or not teams[teamCode] or teams[teamCode].leader ~= src then
        return
    end
    
    -- Set team as active
    teams[teamCode].active = true
    teams[teamCode].vehicle = vehicleNetId
    
    -- Notify all members
    for _, memberId in ipairs(teams[teamCode].members) do
        if memberId ~= src then
            TriggerClientEvent('P_garbage:teamJobStarted', memberId, vehicleNetId)
        end
    end
end)

-- Team payment
RegisterNetEvent('P_garbage:teamPay')
AddEventHandler('P_garbage:teamPay', function(bagCount)
    local src = source
    
    -- Check if player is in a team and is the leader
    local teamCode = playerTeams[src]
    if not teamCode or not teams[teamCode] or teams[teamCode].leader ~= src then
        return
    end
    
    local team = teams[teamCode]
    
    -- Validate bag count
    if bagCount > Config.MaxBags or bagCount < 0 then
        TriggerEvent('P_garbage:logExploit', src, bagCount)
        return
    end
    
    -- Calculate base payment
    local basePayment = Config.PayPerBag * bagCount
    
    -- Pay each team member
    for _, memberId in ipairs(team.members) do
        local Player = QBCore.Functions.GetPlayer(memberId)
        if Player then
            local payAmount
            
            if memberId == team.leader then
                -- Leader gets full payment
                payAmount = basePayment * Config.TeamWork.PaymentDistribution.Leader
                Player.Functions.AddMoney('cash', payAmount)
                Notify(memberId, 'success', Config.GetLocale('team_leader_payment'):format(payAmount))
            else
                -- Members get reduced payment
                payAmount = basePayment * Config.TeamWork.PaymentDistribution.Member
                Player.Functions.AddMoney('cash', payAmount)
                Notify(memberId, 'success', Config.GetLocale('team_payment'):format(payAmount))
            end
            
            -- Update last payment time in player metadata
            Player.Functions.SetMetaData('lastGarbagePayment', os.time())
        end
    end
    
    -- Log payment
    TriggerEvent('P_garbage:logTeamPayment', src, team.members, bagCount, basePayment)
    
    -- Reset team
    team.active = false
    team.vehicle = nil
    team.bags = 0
end)

-- Clean up when player disconnects
AddEventHandler('playerDropped', function()
    local src = source
    
    -- Check if player is in a team
    if playerTeams[src] then
        TriggerEvent('P_garbage:leaveTeam')
    end
    
    -- Also clean up from recentPayments
    if recentPayments and recentPayments[src] then
        recentPayments[src] = nil
    end
end)

-- Get team members
RegisterNetEvent('P_garbage:getTeamMembers')
AddEventHandler('P_garbage:getTeamMembers', function()
    local src = source
    
    -- Check if player is in a team
    local teamCode = playerTeams[src]
    if not teamCode or not teams[teamCode] then return end
    
    local team = teams[teamCode]
    local members = {}
    
    -- Get member names
    for _, memberId in ipairs(team.members) do
        local Player = QBCore.Functions.GetPlayer(memberId)
        if Player then
            table.insert(members, {
                id = memberId,
                name = Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname,
                isLeader = (memberId == team.leader)
            })
        end
    end
    
    -- Send member list to client
    TriggerClientEvent('P_garbage:teamMembersList', src, members)
end)

-- Log team payment
RegisterNetEvent('P_garbage:logTeamPayment')
AddEventHandler('P_garbage:logTeamPayment', function(leaderId, members, bagCount, totalPayment)
    -- Get leader info
    local leaderName, leaderIdentifier, leaderJob = GetPlayerInfo(leaderId)
    
    -- Create fields for webhook
    local fields = {
        {
            ["name"] = "Team Leader",
            ["value"] = "**Name:** " .. leaderName .. "\n**Server ID:** " .. leaderId .. "\n**Citizen ID:** " .. leaderIdentifier .. "\n**Job:** " .. leaderJob,
            ["inline"] = false
        },
        {
            ["name"] = "Team Size",
            ["value"] = #members .. " members",
            ["inline"] = true
        },
        {
            ["name"] = "Payment Details",
            ["value"] = "**Bags Collected:** " .. bagCount .. "\n**Total Payment:** $" .. totalPayment,
            ["inline"] = false
        }
    }
    
    -- Add team members
    local membersText = ""
    for i, memberId in ipairs(members) do
        if memberId ~= leaderId then
            local memberName = GetPlayerInfo(memberId)
            membersText = membersText .. "- " .. memberName .. " (ID: " .. memberId .. ")\n"
        end
    end
    
    if membersText ~= "" then
        table.insert(fields, {
            ["name"] = "Team Members",
            ["value"] = membersText,
            ["inline"] = false
        })
    end
    
    -- Send webhook
    SendWebhook(
        "👥 Team Payment",
        "A garbage collection team has completed their job and received payment.",
        fields,
        15844367 -- Gold color
    )
end)
