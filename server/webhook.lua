local QBCore = exports['qb-core']:GetCoreObject()

-- Server-side webhook configuration
local WebhookConfig = {
    Enabled = true,                                -- Enable/disable Discord logging
    URL = "https://discord.com/api/webhooks/1359510777924554812/4fD-aNdnTc1sJRfgX4_o8Z5uUSmrqAbGw2IgOqeCJgIIU6klYC709MTj39JRPQEtYo8U",         -- Discord webhook URL
    Name = "Garbage Job Logs",                     -- Name that appears in Discord
    Color = 65280,                                 -- Embed color (65280 is green)
    Footer = "Garbage Job Logs | Made by Projekti", -- Footer text for embeds
    IncludeCoordinates = true,                     -- Include player coordinates in logs
    IncludeIdentifiers = false                     -- Include detailed player identifiers (disabled for performance)
}

-- Color codes for different log types
local Colors = {
    Green = 3066993,    -- Clock in
    Blue = 3447003,     -- Bag collected
    Purple = 10181046,  -- Bag deposited
    Gold = 15844367,    -- Payment (successful)
    Orange = 15105570,  -- Payment (no bags)
    Red = 15158332      -- Exploit attempt
}

-- Queue system for webhooks to prevent rate limiting
local webhookQueue = {}
local isProcessingQueue = false

-- Simple function to send Discord webhook
local function SendWebhook(title, description, fields, color)
    -- Check if webhook is enabled and URL is set
    if not WebhookConfig.Enabled or not WebhookConfig.URL or WebhookConfig.URL == "YOUR_DISCORD_WEBHOOK_URL_HERE" then 
        return 
    end
    
    -- Add to queue instead of sending immediately
    table.insert(webhookQueue, {
        title = title,
        description = description,
        fields = fields,
        color = color or WebhookConfig.Color
    })
    
    -- Start processing queue if not already processing
    if not isProcessingQueue then
        ProcessWebhookQueue()
    end
end

-- Process webhook queue to prevent rate limiting
function ProcessWebhookQueue()
    if #webhookQueue == 0 then
        isProcessingQueue = false
        return
    end
    
    isProcessingQueue = true
    
    -- Get the next webhook in queue
    local webhook = table.remove(webhookQueue, 1)
    
    -- Get current date and time
    local time = os.date("%Y-%m-%d %H:%M:%S")
    
    -- Create the embed
    local embed = {
        {
            ["title"] = webhook.title,
            ["description"] = webhook.description,
            ["color"] = webhook.color,
            ["fields"] = webhook.fields,
            ["footer"] = {
                ["text"] = WebhookConfig.Footer .. " | " .. time
            }
        }
    }
    
    -- Send the webhook
    PerformHttpRequest(WebhookConfig.URL, function(err, text, headers)
        -- Wait before processing next webhook to prevent rate limiting
        SetTimeout(1000, ProcessWebhookQueue)
    end, 'POST', json.encode({
        username = WebhookConfig.Name,
        embeds = embed
    }), { ['Content-Type'] = 'application/json' })
end

-- Function to get player information (optimized)
local function GetPlayerInfo(source)
    if not source then return "Unknown Player", "Unknown", "Unknown" end
    
    -- Get player data
    local xPlayer = QBCore.Functions.GetPlayer(source)
    if not xPlayer then return "Unknown Player", "Unknown", "Unknown" end
    
    local playerName = xPlayer.PlayerData.charinfo.firstname .. " " .. xPlayer.PlayerData.charinfo.lastname
    local identifier = xPlayer.PlayerData.citizenid
    local jobName = xPlayer.PlayerData.job.name
    
    return playerName, identifier, jobName
end

-- Function to format player information for webhook (optimized)
local function FormatPlayerInfo(source)
    local playerName, identifier, jobName = GetPlayerInfo(source)
    
    -- Basic player info field
    local fields = {
        {
            ["name"] = "Player Information",
            ["value"] = "**Name:** " .. playerName .. "\n**Server ID:** " .. source .. "\n**Citizen ID:** " .. identifier .. "\n**Job:** " .. jobName,
            ["inline"] = false
        }
    }
    
    -- Add player coordinates if enabled
    if WebhookConfig.IncludeCoordinates then
        local playerCoords = {x = 0, y = 0, z = 0}
        local ped = GetPlayerPed(source)
        if ped and DoesEntityExist(ped) then
            playerCoords = GetEntityCoords(ped)
        end
        
        table.insert(fields, {
            ["name"] = "Location",
            ["value"] = "X: " .. math.floor(playerCoords.x) .. ", Y: " .. math.floor(playerCoords.y) .. ", Z: " .. math.floor(playerCoords.z),
            ["inline"] = false
        })
    end
    
    return fields
end

-- Register server events for logging
RegisterNetEvent('P_garbage:logClockIn')
AddEventHandler('P_garbage:logClockIn', function()
    local source = source
    local fields = FormatPlayerInfo(source)
    
    SendWebhook(
        "👷 Player Clocked In", 
        "A player has started working as a garbage collector.", 
        fields, 
        Colors.Green
    )
end)

RegisterNetEvent('P_garbage:logBagCollected')
AddEventHandler('P_garbage:logBagCollected', function(dumpsterCoords)
    -- Skip detailed logging for bag collection to improve performance
    -- Only log if in debug mode
    if not WebhookConfig.DebugMode then return end
    
    local source = source
    local fields = FormatPlayerInfo(source)
    
    -- Add dumpster location
    if dumpsterCoords then
        table.insert(fields, {
            ["name"] = "Dumpster Location",
            ["value"] = "X: " .. math.floor(dumpsterCoords.x) .. ", Y: " .. math.floor(dumpsterCoords.y) .. ", Z: " .. math.floor(dumpsterCoords.z),
            ["inline"] = false
        })
    end
    
    SendWebhook(
        "🗑️ Trash Bag Collected", 
        "A player has collected a trash bag from a dumpster.", 
        fields, 
        Colors.Blue
    )
end)

RegisterNetEvent('P_garbage:logBagDeposited')
AddEventHandler('P_garbage:logBagDeposited', function()
    -- Skip detailed logging for bag deposits to improve performance
    -- Only log if in debug mode
    if not WebhookConfig.DebugMode then return end
    
    local source = source
    local fields = FormatPlayerInfo(source)
    
    SendWebhook(
        "♻️ Trash Bag Deposited", 
        "A player has deposited a trash bag in their garbage truck.", 
        fields, 
        Colors.Purple
    )
end)

RegisterNetEvent('P_garbage:logPayment')
AddEventHandler('P_garbage:logPayment', function(playerId, bagCount, payAmount)
    -- Use the passed playerId instead of source
    local source = playerId
    local fields = FormatPlayerInfo(source)
    
    -- Add payment details
    table.insert(fields, {
        ["name"] = "Payment Details",
        ["value"] = "**Bags Collected:** " .. bagCount .. "\n**Payment Amount:** $" .. payAmount,
        ["inline"] = false
    })
    
    local description = payAmount > 0 
        and "A player has finished working as a garbage collector and received payment."
        or "A player has finished working as a garbage collector but received no payment (no bags collected)."
        
    local color = payAmount > 0 and Colors.Gold or Colors.Orange
    
    SendWebhook(
        "💰 Player Clocked Out", 
        description, 
        fields, 
        color
    )
end)

RegisterNetEvent('P_garbage:logExploit')
AddEventHandler('P_garbage:logExploit', function(playerId, bagCount)
    local source = playerId or source
    local fields = FormatPlayerInfo(source)
    
    -- Add exploit details
    table.insert(fields, {
        ["name"] = "Exploit Attempt Details",
        ["value"] = "**Attempted Bags:** " .. bagCount .. "\n**Max Allowed:** " .. Config.MaxBags,
        ["inline"] = false
    })
    
    SendWebhook(
        "⚠️ POTENTIAL EXPLOIT", 
        "Player tried to claim payment for more bags than allowed!", 
        fields, 
        Colors.Red
    )
end)

-- Debug command to test webhook
RegisterCommand('testgarbagewh', function(source, args, rawCommand)
    if source == 0 then -- Only allow from console
        print("^2[P_garbage] Testing webhook...^7")
        SendWebhook(
            "🧪 Webhook Test", 
            "This is a test of the garbage job webhook system.", 
            {
                {
                    ["name"] = "Test Information",
                    ["value"] = "If you can see this message, the webhook is working correctly!",
                    ["inline"] = false
                }
            }, 
            Colors.Green
        )
    end
end, true)

-- Print a message when the resource starts
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    if WebhookConfig.URL == "YOUR_DISCORD_WEBHOOK_URL_HERE" then
        print("^3[P_garbage] Webhook URL is not set. Set it in server/webhook.lua to enable logging.^7")
    else
        print("^2[P_garbage] Webhook system initialized^7")
    end
end)
