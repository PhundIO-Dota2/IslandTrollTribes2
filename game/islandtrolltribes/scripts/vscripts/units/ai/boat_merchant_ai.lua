function Spawn(entityKeyValues)
    
    Timers:CreateTimer(boatmerchantthink, thisEntity)
    print("Starting "..thisEntity:GetUnitName().." AI")

    thisEntity.waypointNum = 2
    thisEntity.spawnTime = GameRules:GetGameTime()
    thisEntity.endWait = 0
    thisEntity.state = "move"       --possible states = move, wait
end

function boatmerchantthink(thisEntity)
    if not IsValidAlive(thisEntity) then
        return nil
    end
    local path = thisEntity.path
    if path == nil then
        path = {"path_ship_waypoint_1","path_ship_waypoint_2","path_ship_waypoint_3","path_ship_waypoint_4","path_ship_waypoint_5", "path_ship_waypoint_6", "path_ship_waypoint_7"}
    end
    local waypointNum = thisEntity.waypointNum
    local waypointName = path[waypointNum]
    local waypointEnt = Entities:FindByName(nil, waypointName)
    local waypointPos = waypointEnt:GetOrigin()

    -- Move the trigger with the ship
    if thisEntity.trigger then
        thisEntity.trigger:SetOrigin(thisEntity:GetOrigin())
    else
        print("ERROR: No trigger found for "..thisEntity:GetUnitName())
    end

    local distanceToWaypoint = (thisEntity:GetOrigin() - waypointPos):Length2D()

    if (thisEntity.state == "move") then
        if (distanceToWaypoint > 10) then
            thisEntity:MoveToPosition(waypointPos)

        else
           thisEntity.state = "wait"
           thisEntity.endWait = GameRules:GetGameTime() + 15

        end

    elseif (thisEntity.state == "wait") then
        if (waypointNum >= #path) then

            local pathChosen = thisEntity.pathNum
            local newPath = pathChosen + 2
            if newPath > 4 then newPath = newPath - 4 end
            print("Despawning "..thisEntity:GetUnitName().." - Path was "..pathChosen.." - New Path: "..newPath)

            SpawnBoat(newPath)

            UTIL_Remove(thisEntity.trigger)
            UTIL_Remove(thisEntity)

            -- Create a new shop
        elseif (GameRules:GetGameTime() >= thisEntity.endWait) then
            thisEntity.state = "move"
            thisEntity.waypointNum = thisEntity.waypointNum + 1

        end
    end

    return 0.25
end
