-- TODO: Furniture is not going down the right way when you place it, its flawed since it relies on
-- the previous direction of the chair in order to calculate the new direction, so what if the new
-- direction was the correct direction? Then its screwed! 
print("*************************************")
print("CHAIR BARRICADE MOD - STARTING")
print("*************************************")

-- Initialize our mod table
local ChairBarricade = {}

-- Function to determine which side of the door the player is on
local function getPlayerSideOfDoor(player, door)
    local doorSquare = door:getSquare()
    local playerSquare = player:getCurrentSquare()
   
    if door:getNorth() then
        -- Door is North-South oriented
        local distanceFromDoor = playerSquare:getY() - doorSquare:getY()
        print("N/S Door: Distance from door: " .. distanceFromDoor)
        
        -- Use >= instead of > to consider being at the same Y as being on the south side
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
    for i=0, items:size()-1 do
        local item = items:get(i)
        if item:getFullType():contains("furniture_seating") then
            print("Found chair: " .. item:getFullType())
            return true, item
        end
    end
    
    return false, nil
end

local function onFillWorldObjectContextMenu(player, context, worldobjects)
    print("Context menu handler called")
    if not context then 
        print("Error: No context provided")
        return 
    end
    
    local door = nil
    for _,object in ipairs(worldobjects) do
        if instanceof(object, "IsoDoor") then
            door = object
            print("Found a door")
            break
        end
    end

    local currentPlayer = getSpecificPlayer(player)
    
    -- Add debug prints before the check
    print("Current player: " .. tostring(currentPlayer))
    if currentPlayer then
        print("Player inventory exists: " .. tostring(currentPlayer:getInventory() ~= nil))
    end
    
    -- Split the condition check to see which part fails
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
    end
end

ChairBarricade.onBarricade = function(worldobjects, playerNum, door, chairItem)
    local player = getSpecificPlayer(playerNum)
    if not player or not chairItem then return end
   
    print("Attempting to barricade door")
    local inv = player:getInventory()
    if not inv then return end

    -- Lock the door
    print("Attempting to lock door...")
    if door.setLockedByKey then door:setLockedByKey(true) end
    if door.setKeyId then door:setKeyId(-1) end
    if door.setLocked then door:setLocked(true) end
    if door.setBarricaded then door:setBarricaded(true) end
    
    -- Remove chair from inventory
    inv:Remove(chairItem)
    door:setHealth(door:getHealth() * 3.0)
    
    local doorSquare = door:getSquare()
    if doorSquare then
        local playerSide = getPlayerSideOfDoor(player, door)
        local chairSquare = doorSquare
        local chairRotation = 0

        -- Determine chair position and rotation based on door orientation and player position
        -- 0 = facing south, 1 = facing east, 2 = facing north, 3 = facing west
        if door:getNorth() then
            local yOffset = (playerSide == "south") and 0 or -1
            chairSquare = getCell():getGridSquare(doorSquare:getX(), doorSquare:getY() + yOffset, doorSquare:getZ())
            chairRotation = (playerSide == "south") and 0 or 2  -- Changed to make chair face the door
        else
            local xOffset = (playerSide == "east") and 0 or -1
            chairSquare = getCell():getGridSquare(doorSquare:getX() + xOffset, doorSquare:getY(), doorSquare:getZ())
            chairRotation = (playerSide == "east") and 1 or 3  -- Changed to make chair face the door
        end

        if chairSquare then
            local baseSprite = chairItem:getFullType():gsub("Moveables.", "")
            -- Get the base number and prefix
            local baseNum = tonumber(baseSprite:match("(%d+)$"))
            local basePrefix = baseSprite:match("(.+)_%d+$")
            
            print("Original chair sprite: " .. baseSprite)
            print("Base number: " .. tostring(baseNum))
            
            -- Calculate the correct sprite number based on desired rotation
            local rotatedNum
            if door:getNorth() then
                rotatedNum = (playerSide == "south") and baseNum+2 or baseNum  -- North = base+2, South = base
            else
                if playerSide == "east" then
                    rotatedNum = baseNum-1 --Spine should be west
                else
                    rotatedNum = baseNum+1 --Spine should be east facing
                end
            end
            
            -- Construct new sprite name
            local newSprite = basePrefix .. "_" .. rotatedNum
            print("New rotated sprite: " .. newSprite)
            
            -- Create chair with rotated sprite
            local chairObj = IsoThumpable.new(getCell(), chairSquare, newSprite, false, {})
            chairObj:setName("BarricadeChair")
            chairObj:setThumpDmg(0)
            chairObj:setCanPassThrough(false)
            chairObj:setBlockAllTheSquare(true)
            chairObj:transmitCompleteItemToServer()
            chairSquare:AddTileObject(chairObj)
            
            door:getModData().chairBarricaded = true
            door:getModData().blockingChair = chairObj
            print("Chair barricade placed successfully!")
        end
    end
end

local function onDoorInteraction(door)
   print("Door interaction triggered")
   if door and door:getModData().chairBarricaded then
       print("Blocked interaction with barricaded door")
       return false
   end
   return true
end

-- Initialize event handlers after we've defined all our functions
local function initializeEvents()
   print("CHAIR MOD: Attempting to initialize events")
   if Events then
       print("CHAIR MOD: Events table exists")
       if Events.OnFillWorldObjectContextMenu then
           print("CHAIR MOD: OnFillWorldObjectContextMenu event exists")
           Events.OnFillWorldObjectContextMenu.Add(onFillWorldObjectContextMenu)
           print("CHAIR MOD: Successfully added context menu event handler")
       else
           print("ERROR: OnFillWorldObjectContextMenu event not found!")
       end

       if Events.OnObjectInteraction then
           print("CHAIR MOD: OnObjectInteraction event exists")
           Events.OnObjectInteraction.Add(onDoorInteraction)
           print("CHAIR MOD: Successfully added door interaction handler")
       else
           print("ERROR: OnObjectInteraction event not found!")
       end
   end
end

-- Initialize everything after all functions are defined
Events.OnGameStart.Add(function()
   print("CHAIR MOD: OnGameStart triggered")
   initializeEvents()
   print("CHAIR MOD: Finished initialization")
end)