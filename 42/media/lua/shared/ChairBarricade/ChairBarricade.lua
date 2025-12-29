print("*************************************")
print("CHAIR BARRICADE MOD - STARTING")
print("*************************************")

local ChairBarricade = {}

-- Function to determine which side of the door the player is on
local function getPlayerSideOfDoor(player, door)
   local doorSquare = door:getSquare()
   local playerSquare = player:getCurrentSquare()
  
   if door:getNorth() then
       -- Door is North-South oriented
       local distanceFromDoor = playerSquare:getY() - doorSquare:getY()
       print("N/S Door: Distance from door: " .. distanceFromDoor)
       
       local isSouth = playerSquare:getY() >= doorSquare:getY()
       print("Is player south? " .. tostring(isSouth))
       return isSouth and "south" or "north"
   else
       -- Door is East-West oriented
       local distanceFromDoor = playerSquare:getX() - doorSquare:getX()
       print("E/W Door: Distance from door: " .. distanceFromDoor)
       return (playerSquare:getX() >= doorSquare:getX()) and "east" or "west"
   end
end

local function playerHasChair(player)
    print("playerHasChair function called")
    if not player then
        print("Player is nil")
        return false, nil
    end

    local inv = player:getInventory()
    if not inv then
        print("Inventory is nil")
        return false, nil
    end

    local items = inv:getItems()
    print("Scanning player's inventory:")
    for i=0, items:size()-1 do
        local item = items:get(i)
        local itemID = item:getFullType()
        print(" - Found item: " .. itemID)

        -- Check for various chair types including player-crafted
        local isChair = itemID:find("Chair") or
                       itemID:find("furniture_seating") or
                       itemID:find("seats_") or
                       (item:getCategory() and item:getCategory() == "Furniture")

        if isChair then
            print(" >> Chair detected: " .. itemID)
            return true, item
        end
    end

    print("No chairs found in inventory.")
    return false, nil
end
 
local function onFillWorldObjectContextMenu(player, context, worldobjects)
    print("Context menu handler called")
    if not context then 
        print("Error: No context provided")
        return 
    end
    
    local door = nil
    local chairProp = nil

    for _, object in ipairs(worldobjects) do
        if instanceof(object, "IsoDoor") then
            door = object
            print("Found a door")
        elseif instanceof(object, "IsoThumpable") and 
               object:getName() == "BarricadeChair" then
            chairProp = object
            print("Found a barricade chair")
        end
    end

    local currentPlayer = getSpecificPlayer(player)
    
    -- Check if door is barricaded and add remove option
    if door and door:getModData().chairBarricaded then
        print("Door is already barricaded with a chair")
        context:addOption("Remove Chair Barricade", worldobjects, ChairBarricade.onRemoveBarricade, chairProp, door)
    -- Otherwise check if we can add a chair
    else
        local hasChair, chairItem = playerHasChair(currentPlayer)
        print("Has chair check result: " .. tostring(hasChair))
        
        if door and hasChair then
            context:addOption("Lock with Chair", worldobjects, ChairBarricade.onBarricade, player, door, chairItem)
            print("Added chair barricade option to menu")
        else
            print("Conditions not met for chair barricade:")
            print("Door found: " .. tostring(door ~= nil))
            print("Player valid: " .. tostring(currentPlayer ~= nil))
            print("Has chair: " .. tostring(hasChair))
            if door then
                print("Door already barricaded: " .. tostring(door:getModData().chairBarricaded))
            end
        end
    end
end

ChairBarricade.onBarricade = function(worldobjects, playerNum, door, chairItem)
   local player = getSpecificPlayer(playerNum)
   if not player or not chairItem then return end

   print("Attempting to barricade door")
   local inv = player:getInventory()
   if not inv then return end

   -- Store the chair item type for later retrieval
   local chairItemType = chairItem:getFullType()
   print("Storing chair type: " .. chairItemType)

   print("Attempting to close and lock door...")
   -- First, make sure the door is closed
   if door.setIsOpen then
       door:setIsOpen(false)
       print("Door closed")
   end

   -- Try all possible locking methods to ensure it works on all door types
   if door.setLockedByKey then door:setLockedByKey(true) end
   if door.setKeyId then door:setKeyId(-1) end
   if door.setLocked then door:setLocked(true) end
   if door.setIsLocked then door:setIsLocked(true) end
   if door.setBarricaded then door:setBarricaded(true) end
   print("Door locked successfully")

    inv:Remove(chairItem)
    -- Before changing door health
    local currentHealth = door:getHealth()
    print("Door health before barricade: " .. currentHealth)

    local multiplier = SandboxVars.ChairBarricade.DoorHealthMultiplier
    print("Using door health multiplier: " .. multiplier)

    -- Apply the multiplier
    door:setHealth(currentHealth * multiplier)
    print("Door health after barricade: " .. door:getHealth())
   
   local doorSquare = door:getSquare()
   if doorSquare then
       local playerSide = getPlayerSideOfDoor(player, door)
       local chairSquare = doorSquare
       
       -- Set position based on door orientation
       if door:getNorth() then
           local yOffset = (playerSide == "south") and 0 or -1
           chairSquare = getCell():getGridSquare(doorSquare:getX(), doorSquare:getY() + yOffset, doorSquare:getZ())
       else
           local xOffset = (playerSide == "east") and 0 or -1
           chairSquare = getCell():getGridSquare(doorSquare:getX() + xOffset, doorSquare:getY(), doorSquare:getZ())
       end

       if chairSquare then
           -- Chair should face AWAY from door (back against door for barricading)
           -- So if player is on south side, chair faces south (away from door to north)
           local chairDirection = door:getNorth()
               and ((playerSide == "south") and "south" or "north")
               or ((playerSide == "east") and "east" or "west")

           print("Placing chair facing: " .. chairDirection .. " (back against door)")

           -- Default fallback sprites
           local defaultChairs = {
               south = "furniture_seating_indoor_01_59",
               east = "furniture_seating_indoor_01_58",
               north = "furniture_seating_indoor_01_57",
               west = "furniture_seating_indoor_01_56"
           }

           -- Try to get the sprite from the actual chair item
           local chairSprite = nil
           local spriteName = defaultChairs[chairDirection]  -- Default fallback

           -- Safely attempt to get world sprite
           if chairItem and chairItem.getWorldSprite then
               local success, result = pcall(function() return chairItem:getWorldSprite() end)
               if success and result then
                   chairSprite = result
                   print("Chair world sprite: " .. tostring(chairSprite))
               else
                   print("Could not get world sprite, using default")
               end
           end

           -- If we got a valid sprite, try to apply orientation
           if chairSprite and type(chairSprite) == "string" and chairSprite ~= "" then
               spriteName = chairSprite

               -- For chairs with multiple orientations, try to get the right one
               -- Check if the sprite has an underscore followed by a number (orientation indicator)
               if chairSprite:match("_(%d+)$") then
                   -- Extract base sprite name without orientation
                   local baseSprite = chairSprite:match("(.+)_(%d+)$")
                   if baseSprite then
                       -- Try to find sprites for different orientations
                       local orientNumber = chairSprite:match("_(%d+)$")
                       local baseNumber = tonumber(orientNumber)

                       if baseNumber then
                           -- Calculate offset based on direction
                           local directionMap = {north = 0, east = 1, south = 2, west = 3}
                           local offset = directionMap[chairDirection] or 0

                           -- For furniture_seating_indoor_01_56-59 pattern
                           if baseNumber >= 56 and baseNumber <= 59 then
                               spriteName = baseSprite .. "_" .. (56 + offset)
                           -- For 0-3 pattern
                           elseif baseNumber >= 0 and baseNumber <= 3 then
                               spriteName = baseSprite .. "_" .. offset
                           -- For other patterns, calculate relative position
                           else
                               local baseInSet = baseNumber % 4
                               local setStart = baseNumber - baseInSet
                               spriteName = baseSprite .. "_" .. (setStart + offset)
                           end
                       end
                   end
               end
           else
               print("Using default sprite for direction: " .. chairDirection)
           end

           print("Final sprite: " .. spriteName)

           local chairObj = IsoThumpable.new(getCell(), chairSquare, spriteName, false, {})
           chairObj:setName("BarricadeChair")
           chairObj:setThumpDmg(0)
           chairObj:setCanPassThrough(false)
           chairObj:setBlockAllTheSquare(true)
           chairObj:transmitCompleteItemToServer()
           chairSquare:AddTileObject(chairObj)

           -- Store both the sprite name and item type in modData for removal
           door:getModData().chairBarricaded = true
           door:getModData().blockingChair = chairObj
           door:getModData().chairItemType = chairItemType
           door:getModData().chairSprite = spriteName
           print("Chair barricade placed successfully!")
       end
   end
end

ChairBarricade.onRemoveBarricade = function(worldobjects, chair, door)
    print("Removal function called with:")
    print("Chair: " .. tostring(chair))
    print("Door: " .. tostring(door))
   
    -- Safety check
    if not door then
        print("ERROR: Door is nil!")
        return
    end
   
    if not door.getSquare then
        print("ERROR: Door doesn't have getSquare method!")
        return
    end
 
    -- Get current multiplier to properly reduce health
    local multiplier = SandboxVars.ChairBarricade.DoorHealthMultiplier
   
    -- Reduce door health back to original
    local currentHealth = door:getHealth()
    print("Door health before chair removal: " .. currentHealth)
    door:setHealth(currentHealth / multiplier)
    print("Door health after chair removal: " .. door:getHealth())
   
    -- Reset door state with safety checks - unlock all possible ways
    if door.setLockedByKey then
        door:setLockedByKey(false)
        print("Door unlocked (key)")
    end
    if door.setLocked then
        door:setLocked(false)
        print("Door unlocked")
    end
    if door.setIsLocked then
        door:setIsLocked(false)
        print("Door unlocked (IsLocked)")
    end
    -- Use modData instead of direct method call
    if door:getModData() then
        door:getModData().barricaded = false
        print("Door barricade flag reset")
    end
   
    -- Find and remove the chair object from the square
    local doorSquare = door:getSquare()
    if doorSquare then
        -- Check squares around the door for the chair
        local squares = {doorSquare}
        table.insert(squares, getCell():getGridSquare(doorSquare:getX(), doorSquare:getY() + 1, doorSquare:getZ()))
        table.insert(squares, getCell():getGridSquare(doorSquare:getX(), doorSquare:getY() - 1, doorSquare:getZ()))
        table.insert(squares, getCell():getGridSquare(doorSquare:getX() + 1, doorSquare:getY(), doorSquare:getZ()))
        table.insert(squares, getCell():getGridSquare(doorSquare:getX() - 1, doorSquare:getY(), doorSquare:getZ()))
       
        for _, square in ipairs(squares) do
            if square then
                local objects = square:getObjects()
                for i = 0, objects:size() - 1 do
                    local obj = objects:get(i)
                    if obj and instanceof(obj, "IsoThumpable") and obj:getName() == "BarricadeChair" then
                        square:RemoveTileObject(obj)
                        print("Chair object removed from square")

                        local player = getSpecificPlayer(0)
                        if player then
                            -- Get the stored chair type from modData, default to green chair if not found
                            local chairType = door:getModData().chairItemType or "Base.Mov_GreenChair"
                            print("Returning chair type: " .. chairType)
                            player:getInventory():AddItem(chairType)
                            print("Chair added to player inventory")
                        end

                        break
                    end
                end
            end
        end
    end
   
    door:getModData().chairBarricaded = false
    print("Chair barricade removed successfully!")
end


local function onDoorInteraction(door)
  print("Door interaction triggered")
  if door and door:getModData().chairBarricaded then
      print("Blocked interaction with barricaded door")
      return false
  end
  return true
end

local function initializeEvents()
   print("CHAIR MOD: Attempting to initialize events")
   if Events then
       print("CHAIR MOD: Events table exists")
       if Events.OnFillWorldObjectContextMenu then
           Events.OnFillWorldObjectContextMenu.Add(onFillWorldObjectContextMenu)
           print("CHAIR MOD: Successfully added context menu event handler")
       else
           print("ERROR: OnFillWorldObjectContextMenu event not found!")
       end

       if Events.OnObjectInteraction then
           Events.OnObjectInteraction.Add(onDoorInteraction)
           print("CHAIR MOD: Successfully added door interaction handler")
       else
           print("ERROR: OnObjectInteraction event not found!")
       end
   end
end

Events.OnGameStart.Add(function()
  print("CHAIR MOD: OnGameStart triggered")
  initializeEvents()
  print("CHAIR MOD: Finished initialization")
end)