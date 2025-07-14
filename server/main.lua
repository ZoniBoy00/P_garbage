local QBCore = exports['qb-core']:GetCoreObject()

-- Cache for recent payments to prevent exploits
local recentPayments = {}
local paymentCooldown = 10000 -- 10 seconds

-- Function to give vehicle keys (using standard QBCore method)
RegisterNetEvent('P_garbage:giveKeys')
AddEventHandler('P_garbage:giveKeys', function(vehicleNetId)
    local src = source
    local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
    
    if vehicle and DoesEntityExist(vehicle) then
        local plate = GetVehicleNumberPlateText(vehicle)
        if plate then
            -- Remove any spaces from the plate
            plate = string.gsub(plate, "%s+", "")
            -- Standard QBCore vehicle keys
            TriggerClientEvent('vehiclekeys:client:SetOwner', src, plate)
            
            -- Also try alternative key systems that might be used
            TriggerClientEvent('qb-vehiclekeys:client:AddKeys', src, plate)
            TriggerClientEvent('keys:addNew', src, vehicle, plate)
        end
    end
end)

-- Optimized payment event with better error handling and exploit prevention
RegisterNetEvent('P_garbage:pay')
AddEventHandler('P_garbage:pay', function(bagCount)
    local src = source
    
    -- Validate source and input
    if not src or not bagCount or type(bagCount) ~= "number" or bagCount > Config.MaxBags or bagCount < 0 then
        if src then TriggerEvent('P_garbage:logExploit', src, bagCount or 0) end
        return
    end
    
    -- Anti-exploit: Check for payment cooldown
    if recentPayments[src] and (GetGameTimer() - recentPayments[src] < paymentCooldown) then
        TriggerEvent('P_garbage:logExploit', src, bagCount)
        return
    end
    
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    -- Get the time of the last payment
    local lastPaymentTime = Player.PlayerData.metadata.lastGarbagePayment or 0
    local currentTime = os.time()
    local timeDiff = currentTime - lastPaymentTime
    
    -- Check if payment is too frequent (anti-exploit)
    if timeDiff < Config.AntiExploit.PaymentCooldown then
        TriggerEvent('P_garbage:logExploit', src, bagCount)
        Notify(src, 'error', Config.Locales[Config.Language]['payment_cooldown'])
        return
    end
    
    local payAmount = Config.PayPerBag * bagCount
    
    -- Check if payment exceeds maximum allowed (anti-exploit)
    if payAmount > Config.MaxPaymentPerRound then
        TriggerEvent('P_garbage:logExploit', src, bagCount)
        return
    end
    
    -- Process payment
    if payAmount > 0 then
        -- Add money to player
        Player.Functions.AddMoney('cash', payAmount)
        Notify(src, 'primary', Config.Locales[Config.Language]['pay_received']:format(payAmount))
        
        -- Update last payment time in player metadata
        Player.Functions.SetMetaData('lastGarbagePayment', currentTime)
    else
        Notify(src, 'primary', Config.Locales[Config.Language]['no_pay_received'])
    end
    
    -- Log payment
    TriggerEvent('P_garbage:logPayment', src, bagCount, payAmount)
    
    -- Set cooldown
    recentPayments[src] = GetGameTimer()
end)

-- Vehicle rental event
RegisterNetEvent('P_garbage:rentVehicle')
AddEventHandler('P_garbage:rentVehicle', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local canRent = false
    
    -- Check if player has enough money
    if Player.PlayerData.money.cash >= Config.RentalCost then
        Player.Functions.RemoveMoney('cash', Config.RentalCost)
        canRent = true
        Notify(src, 'success', Config.Locales[Config.Language]['rent_success'])
    elseif Player.PlayerData.money.bank >= Config.RentalCost then
        Player.Functions.RemoveMoney('bank', Config.RentalCost)
        canRent = true
        Notify(src, 'success', Config.Locales[Config.Language]['rent_success'])
    else
        Notify(src, 'error', Config.Locales[Config.Language]['not_enough_money'])
    end
    
    TriggerClientEvent('P_garbage:rentVehicleResponse', src, canRent)
end)

-- Optimized notification function with error handling
function Notify(playerId, type, message)
    if not playerId or not type or not message then return end
    
    if Config.Notify == 'qb' then
        TriggerClientEvent('QBCore:Notify', playerId, message, type)
    elseif Config.Notify == 'ox' then
        TriggerClientEvent('ox_lib:notify', playerId, {type = type, title = 'Garbage Job', description = message})
    end
end

-- Clear player from recent payments when they disconnect
AddEventHandler('playerDropped', function() recentPayments[source] = nil end)

-- Periodic cleanup of recentPayments to prevent memory leaks
CreateThread(function()
    while true do
        Wait(300000) -- Run every 5 minutes
        
        local currentTime = GetGameTimer()
        for playerId, timestamp in pairs(recentPayments) do
            if currentTime - timestamp > 600000 then -- 10 minutes
                recentPayments[playerId] = nil
            end
        end
    end
end)
