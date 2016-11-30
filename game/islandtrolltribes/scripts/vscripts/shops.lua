--Merchant Boat paths, and other lists
PATH1 = {"path_ship_waypoint_1","path_ship_waypoint_2","path_ship_waypoint_3","path_ship_waypoint_4","path_ship_waypoint_5", "path_ship_waypoint_6", "path_ship_waypoint_7"}
PATH2 = {"path_ship_waypoint_8","path_ship_waypoint_9","path_ship_waypoint_4","path_ship_waypoint_5", "path_ship_waypoint_6", "path_ship_waypoint_7"}
PATH3 = {"path_ship_waypoint_1","path_ship_waypoint_2","path_ship_waypoint_3","path_ship_waypoint_4","path_ship_waypoint_5", "path_ship_waypoint_10", "path_ship_waypoint_11", "path_ship_waypoint_12"}
PATH4 = {"path_ship_waypoint_8","path_ship_waypoint_9","path_ship_waypoint_4","path_ship_waypoint_5", "path_ship_waypoint_10", "path_ship_waypoint_11", "path_ship_waypoint_12"}
PATH_LIST = {PATH1, PATH2, PATH3, PATH4}
SHOP_UNIT_NAME_LIST = {"npc_ship_merchant_1", "npc_ship_merchant_2", "npc_ship_merchant_3", "npc_ship_merchant_4", "npc_ship_merchant_5", "npc_ship_merchant_6", "npc_ship_merchant_7"}
MAX_SHOPS_ON_MAP = 1

-- At any given time there are two boats on map, sailing at 120 move speed. They take a random path around the islands to an exit point.
-- Sometimes the ships will stop in shallow water for a few seconds. There are 8 Trading Ships in total.
function ITT:SetupShops()

    boatStartTime = math.floor(GameRules:GetGameTime())
    GameMode.spawnedShops = {}
    GameMode.shopEntities = Entities:FindAllByName("entity_ship_merchant_*")

    GameRules.ShopKV = LoadKeyValues("scripts/kv/shop_info.kv")

    local pathA = RollPercentage(50) and 1 or 3
    local pathB = RollPercentage(50) and 2 or 4
    local pathC = RollPercentage(50) and 1 or 2 or 3 or 4
   -- SpawnBoat(pathA)
    --SpawnBoat(pathB)
    SpawnBoat(pathC)
end

function SpawnBoat(pathNum)
    local currentTime = math.floor(GameRules:GetGameTime())
    local path = PATH_LIST[pathNum]
    local initialWaypoint = Entities:FindByName(nil, path[1])
    local spawnOrigin = initialWaypoint:GetOrigin()

    local merchantNum = RandomInt(1, #SHOP_UNIT_NAME_LIST)
    unitName = SHOP_UNIT_NAME_LIST[merchantNum]

    local shopUnit = CreateUnitByName(unitName, spawnOrigin, false, nil, nil, DOTA_TEAM_NEUTRALS)
    shopUnit.path = path
    shopUnit.pathNum = pathNum

    local shopEnt = Entities:FindByName(nil, "*trigger_shop_2") -- entity name in hammer
    local modelName = shopEnt:GetModelName()
    shopUnit.trigger = SpawnEntityFromTableSynchronous('trigger_shop', {origin = spawnOrigin, shoptype = 0, model = modelName}) -- shoptype is 0 for a "home" shop, 1 for a side shop and 2 for a secret shop

    print("Spawned "..unitName.." at path "..pathNum)

    TieShopToUnit(shopUnit)
end

function TieShopToUnit( unit )
    unit:AddNewModifier(unit, nil, "modifier_shopkeeper", {})

    local unitName = unit:GetUnitName()
    local itemTable = GameRules.ShopKV[unitName]
    local sItems,prices,stocks = CreateShopItems(itemTable)

    -- This somehow makes stuff other than trade ships into trade ships.
    -- Putting some prints here to see why.
    print("---- Tradeship shop creation debug: ")
    print("---- Unitname: ", unitName)
    --print(debug.traceback())


    -- Build the rows in a square
    local shopRows = math.ceil(math.sqrt(#sItems))
    local shopLayout = {}
    for i=1,shopRows-1 do
        shopLayout[i] = shopRows
    end
    shopLayout[shopRows] = #sItems - shopRows*(shopRows-1)

    local shop = Containers:CreateShop({
        layout =      shopLayout,
        skins =       {},
        headerText =  unitName,
        pids =        {},
        position =    "entity", --"1000px 300px 0px",
        entity =      unit,
        items =       sItems,
        prices =      prices,
        stocks =      stocks,
        closeOnOrder= true,
        range =       550,

        OnSelect = function(playerID, container, selected)
            print("Selected", selected:GetUnitName())
            print("---- Tradeship shop selection debug: ")
            print("---- Unitname: ", selected:GetUnitName())
            --print(debug.traceback())
            container:Open(playerID)
        end,

        OnDeselect = function(playerID, container, deselected)
            print("Deselected", deselected:GetUnitName())
            container:Close(playerID)
        end,

        OnRightClick = function(playerID, container, unit, item, slot)
          --shop item restriction check
          local iname = item:GetAbilityName()
          local exists = false
          local full = true
          local restricted = false

          local itemSlotRestriction = GameRules.ItemInfo['ItemSlots'][iname]

          for i=0,5 do
            local it = unit:GetItemInSlot(i)
            if not it then
              full = false
            elseif it:GetAbilityName() == iname then
              exists = true
            end
          end
          -- if itemSlotRestriction then
          --   print("trying to buy restricted item " .. iname .. " type: " ..itemSlotRestriction)
          -- end
          if full then
            SendErrorMessage(playerID, "#error_inventory_full")
          elseif itemSlotRestriction then
            local maxCarried = GameRules.ItemInfo['MaxCarried'][itemSlotRestriction]
            local count = GetNumItemsOfSlot(unit, itemSlotRestriction)

            if count >= maxCarried then
              --print("carrying too many "..iname)
              SendErrorMessage(playerID, "#error_cant_carry_more_"..itemSlotRestriction)
              return
            end
          end
          if not full or (full and item:IsStackable() and exists)then
            Containers:print("Shop:OnRightClick", playerID, container, unit, item:GetEntityIndex(), slot)

            local bought_item = container:BuyItem(playerID, unit, item)

            if bought_item then
              Containers:AddItemToUnit(unit, bought_item)
              bought_item:SetPurchaseTime(0) --disables the 10 second full price refund
            end
          end
        end,

        OnEntityOrder = function(playerID, container, unit, target)
            container:Open(playerID)
            local player = PlayerResource:GetPlayer(playerID)
            EmitSoundOnClient("Shop.Available", player)
            EmitSoundOnClient("Quickbuy.Available", player)
            unit:Stop()
            unit:Hold()
        end,
    })
end

-- Creates items from a table with name, price and stock
function CreateShopItems(ii)
  local sItems = {}
  local prices = {}
  local stocks = {}

  for _,i in pairs(ii) do
    local item = CreateItem(i.name, nil, nil)
    local index = item:GetEntityIndex()
    sItems[#sItems+1] = item
    if i.price then prices[index] = i.price end
    if i.stock then stocks[index] = i.stock end

    item:SetCurrentCharges(item:GetInitialCharges())

  end

  return sItems, prices, stocks
end
