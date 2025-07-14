-- Bins management module
Garbage = Garbage or {}
Garbage.Bins = {}

-- Local state
local markedBins = {}
local currentGarbageBins = {}
local binMaxUses = {}
local activeZones = {} -- Track active zone IDs
local allBinsEmpty = false -- Track if all bins in the current zone are empty
local createdZones = {} -- Track only zones that were successfully created
local currentLocationKey = nil -- Track current location key

-- Function to create a bin entity at coordinates and add target
function Garbage.Bins.CreateAtCoords(coords, index)
  -- Find closest bin model to these coordinates
  local closestBin = nil
  local closestDistance = 5.0 -- Maximum distance to search
  
  -- Get all objects in the area
  local objects = GetGamePool('CObject')
  for _, object in ipairs(objects) do
      -- Check if this object is one of our bin models
      local isValidModel = false
      local objectModel = GetEntityModel(object)
      for _, modelHash in ipairs(Config.Models) do
          if objectModel == modelHash then
              isValidModel = true
              break
          end
      end
      
      if isValidModel then
          local objectCoords = GetEntityCoords(object)
          local distance = #(vector3(coords.x, coords.y, coords.z) - objectCoords)
          
          if distance < closestDistance then
              closestDistance = distance
              closestBin = object
          end
      end
  end
  
  -- If we found a bin, add it to our marked bins
  if closestBin and DoesEntityExist(closestBin) then
      -- Create a blip for this bin
      local binBlip = AddBlipForEntity(closestBin)
      SetBlipSprite(binBlip, 318)
      SetBlipColour(binBlip, 33) -- Yellow
      SetBlipScale(binBlip, 0.5)
      SetBlipAsShortRange(binBlip, true)
      BeginTextCommandSetBlipName("STRING")
      AddTextComponentString("Garbage Pickup #" .. index)
      EndTextCommandSetBlipName(binBlip)
      
      -- Generate a random max uses for this bin (1-3)
      local maxUses = math.random(1, 3)
      binMaxUses[closestBin] = maxUses
      
      -- Add this bin to our tracking table
      markedBins[closestBin] = {
          blip = binBlip,
          collected = false,
          index = index,
          uses = 0,
          maxUses = maxUses
      }
      
      -- Add target to this specific bin
      exports.ox_target:addLocalEntity(closestBin, {
          {
              name = 'garbage_bin_' .. index,
              label = Config.GetLocale('collect_bag'),
              icon = 'fas fa-trash',
              distance = 2.0,
              onSelect = function() Garbage.Bins.CollectBag(closestBin) end,
              canInteract = function()
                  -- Check if bin has reached its max uses
                  local binData = markedBins[closestBin]
                  if not binData then return false end
                  
                  return not IsHoldingBag() and Garbage.IsOnDuty() and 
                         binData.uses < binData.maxUses and 
                         GetBags() < Config.MaxBags
              end
          }
      })
      
      return closestBin
  else
      -- Create a manual marker at the exact coordinates
      local coordBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
      SetBlipSprite(coordBlip, 318)
      SetBlipColour(coordBlip, 33)
      SetBlipScale(coordBlip, 0.5)
      SetBlipAsShortRange(coordBlip, true)
      BeginTextCommandSetBlipName("STRING")
      AddTextComponentString("Garbage Pickup #" .. index)
      EndTextCommandSetBlipName(coordBlip)
      
      -- Generate a random max uses for this location (1-3)
      local maxUses = math.random(1, 3)
      
      -- Create a unique zone ID - use a more unique identifier
      local zoneId = 'garbage_zone_' .. GetGameTimer() .. '_' .. index
      
      -- Create a manual target zone at these coordinates
      local success = false
      local zoneResult = nil
      
      -- Try to create the zone with error handling
      pcall(function()
          zoneResult = exports.ox_target:addSphereZone({
              coords = vector3(coords.x, coords.y, coords.z),
              radius = 1.5,
              options = {
                  {
                      name = zoneId,
                      label = Config.GetLocale('collect_bag'),
                      icon = 'fas fa-trash',
                      distance = 2.0,
                      onSelect = function() 
                          -- Check if this zone has reached its max uses
                          local zoneData = currentGarbageBins[index]
                          if zoneData and zoneData.uses and zoneData.uses >= zoneData.maxUses then
                              Notify('error', Config.GetLocale('bin_empty'))
                              return
                          end
                          
                          -- Create a temporary entity for collection
                          local tempBin = CreateObject(Config.Models[1], coords.x, coords.y, coords.z, false, false, false)
                          SetEntityAlpha(tempBin, 0, false)
                          FreezeEntityPosition(tempBin, true)
                          SetEntityCollision(tempBin, false, false)
                          
                          -- Add to marked bins
                          markedBins[tempBin] = {
                              blip = coordBlip,
                              collected = false,
                              index = index,
                              isTemp = true,
                              uses = 0,
                              maxUses = maxUses
                          }
                          
                          -- Collect the bag
                          Garbage.Bins.CollectBag(tempBin)
                          
                          -- Clean up temp entity after a delay
                          SetTimeout(10000, function()
                              if DoesEntityExist(tempBin) then
                                  DeleteEntity(tempBin)
                              end
                          end)
                      end,
                      canInteract = function()
                          -- Check if zone has reached its max uses
                          local zoneData = currentGarbageBins[index]
                          if zoneData and zoneData.uses and zoneData.uses >= zoneData.maxUses then
                              return false
                          end
                          
                          return not IsHoldingBag() and Garbage.IsOnDuty() and GetBags() < Config.MaxBags
                      end
                  }
              }
          })
          
          -- Check if zone creation was successful
          if zoneResult then
              success = true
          end
      end)
      
      -- Only track the zone if it was successfully created
      if success then
          -- Store the zone ID for later cleanup
          table.insert(activeZones, zoneId)
          
          -- Also store in our createdZones table with the actual zone result
          createdZones[zoneId] = zoneResult
          
          -- We'll return nil for the bin but still track the blip
          currentGarbageBins[index] = {
              coords = coords,
              blip = coordBlip,
              collected = false,
              uses = 0,
              maxUses = maxUses,
              zoneId = zoneId -- Store the zone ID with the bin data
          }
      else
          -- If zone creation failed, just remove the blip
          RemoveBlip(coordBlip)
      end
      
      return nil
  end
end

-- Function to check if an entity is a marked bin
function Garbage.Bins.IsMarked(entity)
  if not entity or not DoesEntityExist(entity) then 
      return false 
  end
  
  return markedBins[entity] ~= nil
end

-- Collect bag from a bin
function Garbage.Bins.CollectBag(entity)
    if not entity or not Garbage.IsOnDuty() or IsProcessingAction() or IsHoldingBag() then 
        return 
    end
    
    -- Check if this is a marked bin
    if not Garbage.Bins.IsMarked(entity) then
        Notify('error', Config.GetLocale('marked_bins_only'))
        return
    end
    
    SetProcessingAction(true)
    local playerPed = PlayerPedId()
    
    -- Check if bin has reached its max uses
    local binData = markedBins[entity]
    if binData.uses >= binData.maxUses then
        Notify('error', Config.GetLocale('bin_empty'))
        SetProcessingAction(false)
        return
    end
    
    -- Get one bag per collection
    local bagsToCollect = 1
    
    -- Make sure we don't exceed the max bags limit
    if (GetBags() + bagsToCollect) > Config.MaxBags then
        bagsToCollect = Config.MaxBags - GetBags()
    end
    
    -- If no bags to collect, exit
    if bagsToCollect <= 0 then
        Notify('error', Config.GetLocale('max_bags'))
        SetProcessingAction(false)
        return
    end
    
    -- Load animation dictionary
    if not Garbage.Utils.LoadAnimDict("anim@heists@narcotics@trash") then
        Notify('error', 'Failed to load animation')
        SetProcessingAction(false)
        return
    end
    
    -- Start progress bar
    ProgressBar(5000, Config.GetLocale('collecting_bag'), {scenario = 'PROP_HUMAN_BUM_BIN'}, {move = true, mouse = false, combat = true, sprint = true, car = true})
    
    -- Create and attach bag prop
    SetHoldingBag(true)
    local bagProp = CreateObject(Config.BagProp, 0, 0, 0, true, true, true)
    SetBagProp(bagProp)
    
    if not DoesEntityExist(bagProp) then
        Notify('error', 'Failed to create bag prop')
        SetHoldingBag(false)
        SetProcessingAction(false)
        return
    end
    
    AttachEntityToEntity(bagProp, playerPed, GetPedBoneIndex(playerPed, 57005), 0.4, 0, 0, 0, 270.0, 60.0, true, true, false, true, 1, true)
    
    -- Increment uses for this bin
    binData.uses = binData.uses + 1
    
    -- Mark bin as collected if it has reached max uses
    if binData.uses >= binData.maxUses then
        binData.collected = true
        
        -- Change blip color to indicate empty bin
        if binData.blip and DoesBlipExist(binData.blip) then
            SetBlipColour(binData.blip, 1) -- Red color for empty
        end
        
        -- Debug bin status
        if Config.Debug.Enabled and Config.Debug.LogBinStatus then
            DebugPrint("BinStatus", "Bin #" .. binData.index .. " is now EMPTY!")
        end
    end
    
    -- Also update the zone data if this is a sphere zone
    local zoneIndex = binData.index
    if currentGarbageBins[zoneIndex] then
        currentGarbageBins[zoneIndex].uses = (currentGarbageBins[zoneIndex].uses or 0) + 1
        
        -- Mark zone bin as collected if it has reached max uses
        if currentGarbageBins[zoneIndex].uses >= currentGarbageBins[zoneIndex].maxUses then
            currentGarbageBins[zoneIndex].collected = true
            
            -- Update the blip color for zone-based bins too
            if currentGarbageBins[zoneIndex].blip and DoesBlipExist(currentGarbageBins[zoneIndex].blip) then
                SetBlipColour(currentGarbageBins[zoneIndex].blip, 1) -- Red color for empty
            end
        end
    end
    
    -- Store the number of bags collected for deposit
    SetCurrentBagsCollected(bagsToCollect)
    
    -- Notify player about the number of bags collected
    Notify('success', Config.GetLocale('bags_collected_msg'):format(bagsToCollect))
    
    -- Log bag collection if debug is enabled
    if Config.Debug.Enabled and Config.Debug.LogBagCollection then
        DebugPrint("BagCollection", "Collected bag from bin at " .. tostring(GetEntityCoords(entity)))
    end
    
    TriggerServerEvent('P_garbage:logBagCollected', GetEntityCoords(entity))
    
    -- Play animation
    TaskPlayAnim(playerPed, 'anim@heists@narcotics@trash', 'walk', 1.0, -1.0, -1, 49, 0, 0, 0, 0)
    
    -- Check if all bins are now empty after this collection
    Garbage.Bins.CheckAllBinsEmpty()
    
    SetProcessingAction(false)
end

-- Check if all bins in the current zone are empty
function Garbage.Bins.CheckAllBinsEmpty()
    -- Debug output to track function call
    if Config.Debug.Enabled and Config.Debug.LogBinStatus then
        DebugPrint("BinStatus", "CheckAllBinsEmpty function called")
    end
    
    -- Get a comprehensive count of both entity bins and current zone bins
    local totalZoneBins = 0
    local totalEmptyBins = 0
    local allBinsTracked = {}
    
    -- First, track all entity bins from markedBins table
    for entity, binData in pairs(markedBins) do
        if DoesEntityExist(entity) then
            local binId = binData.index or "unknown"
            if not allBinsTracked[binId] then
                allBinsTracked[binId] = {
                    isEmpty = (binData.uses >= binData.maxUses),
                    entity = entity,
                    type = "entity"
                }
                totalZoneBins = totalZoneBins + 1
                if binData.uses >= binData.maxUses then
                    totalEmptyBins = totalEmptyBins + 1
                end
            end
        end
    end
    
    -- Then also check currentGarbageBins 
    for index, binData in pairs(currentGarbageBins) do
        if not allBinsTracked[index] then
            local isEmpty = (binData.uses and binData.maxUses and binData.uses >= binData.maxUses)
            allBinsTracked[index] = {
                isEmpty = isEmpty,
                coords = binData.coords,
                type = "zone"
            }
            totalZoneBins = totalZoneBins + 1
            if isEmpty then
                totalEmptyBins = totalEmptyBins + 1
            end
        end
    end
    
    -- Debug output with detailed bin tracking
    if Config.Debug.Enabled and Config.Debug.LogBinStatus then
        DebugPrint("BinStatus", "COMPREHENSIVE Count - Total bins: " .. totalZoneBins .. ", Empty bins: " .. totalEmptyBins)
        for index, data in pairs(allBinsTracked) do
            DebugPrint("BinDetail", "Bin #" .. index .. " - Type: " .. data.type .. ", Empty: " .. (data.isEmpty and "Yes" or "No"))
        end
    end
    
    -- Only create a new zone if all bins are empty AND there are actually bins
    if totalEmptyBins >= totalZoneBins and totalZoneBins > 0 then
        -- Force create a new zone
        Notify('primary', Config.GetLocale('all_bins_empty'))
        
        -- Create a new zone marker immediately
        Garbage.Bins.CreateNewZoneMarker()
        
        -- Set flag to prevent creating multiple markers
        allBinsEmpty = true
        
        return true
    end
    
    return false
end

-- Create a new zone marker
function Garbage.Bins.CreateNewZoneMarker()
  -- Debug notification
  if Config.Debug.Enabled and Config.Debug.LogZoneCreation then
      DebugPrint("ZoneCreation", "CreateNewZoneMarker function called")
  end
  
  Notify('success', Config.GetLocale('new_zone_creating'))
  
  if Config.UseRandomZones then
      -- Random zone creation (old method)
      -- Get current location
      local currentLocation = GetCurrentLocation()
      if not currentLocation then 
          -- Fallback if no current location
          if Config.Debug.Enabled then
              DebugPrint("ZoneCreation", "No current location, selecting random location")
          end
          Notify('error', Config.GetLocale('location_failed'))
          Garbage.Bins.SelectRandomLocation()
          return 
      end
      
      -- Create a marker 50m away from current location
      local angle = math.random() * 2 * math.pi
      local distance = 50.0
      local x = currentLocation.Location.x + math.cos(angle) * distance
      local y = currentLocation.Location.y + math.sin(angle) * distance
      local z = 30.0  -- Fixed height to ensure visibility
      
      if Config.Debug.Enabled and Config.Debug.ShowCoords then
          DebugPrint("ZoneCreation", "Creating new random zone at: " .. x .. ", " .. y .. ", " .. z)
      end
      
      -- Create a blip for the new zone - make it VERY visible
      local newZoneBlip = AddBlipForCoord(x, y, z)
      SetBlipSprite(newZoneBlip, 162) -- Different sprite for new zone
      SetBlipColour(newZoneBlip, 2) -- Green
      SetBlipScale(newZoneBlip, 1.5) -- Larger scale
      SetBlipAsShortRange(newZoneBlip, false) -- Make it visible from further away
      BeginTextCommandSetBlipName("STRING")
      AddTextComponentString(Config.GetLocale('new_zone'))
      EndTextCommandSetBlipName(newZoneBlip)
      
      -- Make the blip flash to draw attention
      SetBlipFlashes(newZoneBlip, true)
      
      -- Create a zone that the player can interact with
      local newZoneId = 'new_garbage_zone_' .. GetGameTimer()
      
      -- Try to create the zone with error handling
      local success = false
      local zoneResult = nil
      
      pcall(function()
          zoneResult = exports.ox_target:addSphereZone({
              coords = vector3(x, y, z),
              radius = 10.0, -- Even larger radius for easier interaction
              options = {
                  {
                      name = newZoneId,
                      label = Config.GetLocale('get_new_location'),
                      icon = 'fas fa-map-marker-alt',
                      distance = 10.0, -- Larger interaction distance
                      onSelect = function()
                          -- Remove this zone and blip
                          if zoneResult then
                              pcall(function()
                                  exports.ox_target:removeZone(zoneResult)
                              end)
                          end
                          
                          if DoesBlipExist(newZoneBlip) then
                              RemoveBlip(newZoneBlip)
                          end
                          
                          -- Select a new garbage location
                          Garbage.Bins.SelectRandomLocation()
                      end,
                      canInteract = function()
                          return Garbage.IsOnDuty() and GetBags() < Config.MaxBags
                      end
                  }
              }
          })
          
          if zoneResult then
              success = true
          end
      end)
      
      -- If zone creation was successful, add to active zones
      if success and zoneResult then
          -- Store the zone result directly
          createdZones[newZoneId] = zoneResult
          
          -- Notify player again to make sure they know where to go
          Notify('success', Config.GetLocale('new_zone'))
          
          -- Set a waypoint to the new zone
          SetNewWaypoint(x, y)
          
          if Config.Debug.Enabled and Config.Debug.LogZoneCreation then
              DebugPrint("ZoneCreation", "New random zone created successfully")
          end
      else
          -- If zone creation failed, just remove the blip
          if DoesBlipExist(newZoneBlip) then
              RemoveBlip(newZoneBlip)
          end
          
          -- Try again with a completely different location
          if Config.Debug.Enabled and Config.Debug.LogZoneCreation then
              DebugPrint("ZoneCreation", "Random zone creation failed, selecting new location from locations.lua")
          end
          Notify('error', Config.GetLocale('zone_creation_failed'))
          Garbage.Bins.SelectRandomLocation()
      end
  else
      -- Use locations from locations.lua (new method)
      Garbage.Bins.SelectRandomLocation()
  end
end

-- Select a random garbage location
function Garbage.Bins.SelectRandomLocation()
  -- Get all location keys
  local locationKeys = {}
  for k in pairs(Locations) do
      table.insert(locationKeys, k)
  end
  
  if #locationKeys > 0 then
      -- Select a random location different from the current one
      local randomIndex
      local locationKey
      
      -- Try to find a different location if possible
      if currentLocationKey and #locationKeys > 1 then
          repeat
              randomIndex = math.random(1, #locationKeys)
              locationKey = locationKeys[randomIndex]
          until locationKey ~= currentLocationKey
      else
          randomIndex = math.random(1, #locationKeys)
          locationKey = locationKeys[randomIndex]
      end
      
      -- Store the current location key
      currentLocationKey = locationKey
      
      local currentGarbageLocation = Locations[locationKey]
      SetCurrentLocation(currentGarbageLocation)
      
      if Config.Debug.Enabled and Config.Debug.LogZoneCreation then
          DebugPrint("ZoneCreation", "Selected location: " .. locationKey)
          if Config.Debug.ShowCoords then
              DebugPrint("ZoneCreation", "Location coords: " .. 
                  currentGarbageLocation.Location.x .. ", " .. 
                  currentGarbageLocation.Location.y)
          end
      end
      
      -- Set waypoint to the location
      SetNewWaypoint(currentGarbageLocation.Location.x, currentGarbageLocation.Location.y)
      
      -- Create zone blip - optimize blip creation
      local zoneBlip = AddBlipForRadius(currentGarbageLocation.Zone.x, currentGarbageLocation.Zone.y, currentGarbageLocation.Zone.z, 100.0)
      SetBlipSprite(zoneBlip, 9)
      SetBlipAlpha(zoneBlip, 100)
      SetBlipColour(zoneBlip, 5)
      SetBlipAsShortRange(zoneBlip, true) -- Make it short range to save resources
      SetZoneBlip(zoneBlip)
      
      -- Clean up previous bins and zones
      Garbage.Bins.Cleanup()
      
      -- Reset all bins empty flag
      allBinsEmpty = false
      
      -- Reset bin tracking variables
      markedBins = {}
      currentGarbageBins = {}
      binMaxUses = {}
      
      -- Create bin blips and targets
      local numBins = math.min(Config.MaxBags, #currentGarbageLocation.Garbages)
      
      -- Shuffle the bins array to get random bins - optimize the shuffle
      local shuffledBins = {}
      local indices = {}
      
      -- Create an array of indices
      for i = 1, #currentGarbageLocation.Garbages do
          indices[i] = i
      end
      
      -- Shuffle the indices (more efficient than shuffling the actual bins)
      for i = #indices, 2, -1 do
          local j = math.random(i)
          indices[i], indices[j] = indices[j], indices[i]
      end
      
      -- Use the shuffled indices to create the shuffled bins array
      for i = 1, math.min(numBins, #indices) do
          shuffledBins[i] = currentGarbageLocation.Garbages[indices[i]]
      end
      
      -- Create blips and targets for selected bins (limit to Config.MaxBinsPerZone for performance)
      local maxBinsToShow = math.min(numBins, Config.MaxBinsPerZone)
      
      -- Create bins in batches to avoid frame drops
      CreateThread(function()
          for i = 1, maxBinsToShow do
              local binCoords = shuffledBins[i]
              
              -- Create bin entity and add target
              local binEntity = Garbage.Bins.CreateAtCoords(binCoords, i)
              
              -- If bin entity was created, add to our tracking
              if binEntity then
                  currentGarbageBins[i] = {
                      coords = binCoords,
                      entity = binEntity,
                      collected = false,
                      uses = 0,
                      maxUses = markedBins[binEntity].maxUses
                  }
              end
              
              -- Small delay to prevent overloading the system
              Wait(50)
          end
          
          -- After setting up all bins, log how many were created
          if Config.Debug.Enabled and Config.Debug.LogBinStatus then
              local binCount = 0
              for _, _ in pairs(markedBins) do
                  binCount = binCount + 1
              end
              DebugPrint("BinStatus", "Created " .. binCount .. " marked bins in zone " .. locationKey)
          end
          
          Notify('primary', Config.GetLocale('go_to_area'))
      end)
  else
      Notify('error', Config.GetLocale('no_locations'))
  end
end

-- Clean up bins and zones
function Garbage.Bins.Cleanup()
  -- Clear marked bins and their targets
  for entity, binData in pairs(markedBins) do
      if binData.blip and DoesBlipExist(binData.blip) then 
          RemoveBlip(binData.blip) 
      end
      
      if DoesEntityExist(entity) then 
          pcall(function()
              exports.ox_target:removeLocalEntity(entity)
          end)
          
          if binData.isTemp then
              SetEntityAsMissionEntity(entity, true, true)
              DeleteEntity(entity)
              
              -- Force cleanup if entity still exists
              if DoesEntityExist(entity) then
                  SetEntityCoords(entity, 0.0, 0.0, 0.0, false, false, false, true)
                  DeleteEntity(entity)
              end
          end
      end
  end
  
  -- Clear bin blips
  for _, bin in pairs(currentGarbageBins) do
      if bin.blip and DoesBlipExist(bin.blip) then 
          RemoveBlip(bin.blip) 
      end
  end
  
  -- Clear sphere zones - use the stored zone results
  for zoneId, zoneResult in pairs(createdZones) do
      pcall(function()
          exports.ox_target:removeZone(zoneResult)
      end)
  end
  
  -- Reset state with proper cleanup
  for k in pairs(markedBins) do markedBins[k] = nil end
  for k in pairs(currentGarbageBins) do currentGarbageBins[k] = nil end
  for k in pairs(binMaxUses) do binMaxUses[k] = nil end
  for k in pairs(activeZones) do activeZones[k] = nil end
  for k in pairs(createdZones) do createdZones[k] = nil end
  
  -- Reset flags
  allBinsEmpty = false
  
  -- Force garbage collection
  collectgarbage("collect")
end

-- Expose functions
Garbage.Bins.GetMarkedBins = function() return markedBins end
Garbage.Bins.GetCurrentBins = function() return currentGarbageBins end
Garbage.Bins.IsAllBinsEmpty = function() return allBinsEmpty end
Garbage.Bins.GetCurrentLocationKey = function() return currentLocationKey end
