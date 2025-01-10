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
   
   print("Current player: " .. tostring(currentPlayer))
   if currentPlayer then
       print("Player inventory exists: " .. tostring(currentPlayer:getInventory() ~= nil))
   end
   
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

   print("Attempting to lock door...")
   if door.setLockedByKey then door:setLockedByKey(true) end
   if door.setKeyId then door:setKeyId(-1) end
   if door.setLocked then door:setLocked(true) end
   if door.setBarricaded then door:setBarricaded(true) end
   
   inv:Remove(chairItem)
   door:setHealth(door:getHealth() * 3.0)
   
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
           -- Standard chair sprites
           -- Words could not describe how many different ways I tried to avoid having to do this
           -- but because Indie Stone doesnt have a true convention for chair id's, you cant programmatically
           -- find which orientation a chair is without having one big lookup table
           local standardChairs = {
               south = "furniture_seating_indoor_01_59",
               east = "furniture_seating_indoor_01_58",
               north = "furniture_seating_indoor_01_57",
               west = "furniture_seating_indoor_01_56"
           }
           
           local chairDirection = door:getNorth() 
               and ((playerSide == "south") and "north" or "south")
               or ((playerSide == "east") and "west" or "east")
           
           print("Placing chair facing: " .. chairDirection)
           
           local chairObj = IsoThumpable.new(getCell(), chairSquare, standardChairs[chairDirection], false, {})
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