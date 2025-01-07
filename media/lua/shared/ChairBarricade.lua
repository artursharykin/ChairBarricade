-- First make sure we're announcing our mod load
print("*************************************")
print("CHAIR BARRICADE MOD - STARTING")
print("*************************************")

-- Initialize our mod table
local ChairBarricade = {}

local function playerHasChair(player)
    print("playerHasChair function called")
    if not player then 
        print("Player is nil")
        return false 
    end
    
    local inv = player:getInventory()
    if not inv then 
        print("Inventory is nil")
        return false 
    end
    
    -- Try explicit check for Moveables
    local hasMoveableChair = inv:containsTypeRecurse("Moveables.furniture_seating_indoor_01_57") or
                            inv:containsTypeRecurse("Moveables.furniture_seating_indoor_02_4")
    print("Has moveable chair: " .. tostring(hasMoveableChair))
    
    return hasMoveableChair
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
    local hasChair = playerHasChair(currentPlayer)
    print("Has chair check result: " .. tostring(hasChair))
    
    if door and hasChair then
        context:addOption("Lock with Chair", worldobjects, ChairBarricade.onBarricade, player, door)
        print("Added chair barricade option to menu")
    else
        print("Conditions not met for chair barricade:")
        print("Door found: " .. tostring(door ~= nil))
        print("Player valid: " .. tostring(currentPlayer ~= nil))
        print("Has chair: " .. tostring(hasChair))
    end
end

-- Barricade action function
ChairBarricade.onBarricade = function(worldobjects, playerNum, door)
    local player = getSpecificPlayer(playerNum)
    if not player then 
        print("Player is nil!")
        return 
    end
   
    print("Attempting to barricade door")
    
    local inv = player:getInventory()
    if not inv then
        print("Inventory is nil!")
        return
    end
   
    local chairTypes = {
        "Moveables.furniture_seating_indoor_01_57",
        "Moveables.furniture_seating_indoor_02_4"
    }
    
    for _, chairType in ipairs(chairTypes) do
        local item = inv:getFirstTypeRecurse(chairType)
        if item then
            print("Door health before: " .. door:getHealth())
            inv:Remove(item) -- Use Remove instead of RemoveOneType
            door:setHealth(door:getHealth() * 1.5)
            print("Door health after: " .. door:getHealth())
           
            local square = door:getSquare()
            if square then
                -- Try to use the item's sprite for the prop
                local chairProp = IsoObject.new(square, item:getSprite():getName())
                if chairProp then
                    square:AddTileObject(chairProp)
                    print("Chair barricade placed successfully with chair type: " .. chairType)
                end
            end
            break
        end
    end
end

-- Initialize event handlers after we've defined all our functions
local function initializeEvents()
    if Events.OnFillWorldObjectContextMenu then
        Events.OnFillWorldObjectContextMenu.Add(onFillWorldObjectContextMenu)
        print("Successfully added context menu event handler")
    else
        print("ERROR: OnFillWorldObjectContextMenu event not found!")
    end
end

-- Initialize everything after all functions are defined
Events.OnGameStart.Add(function()
    print("CHAIR MOD: Game Started!")
    initializeEvents()
end)