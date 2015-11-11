CONTAINERS_VERSION = "0.80"

require('libraries/timers')
require('libraries/playertables')

local ID_BASE = "cont_"
FORCE_NIL = false

--[[
  Lua-controlled Frankenstein Containers Library by BMD

  Installation
  -"require" this file inside your code in order to gain access to the Containers global table.
  -Optionally require "libraries/notifications" before this file so that the Attachment Configuration GUI can display messages via the Notifications library.
  -Additionally, ensure that this file is placed in the vscripts/libraries path
  -Additionally, ensure that you have the barebones_Containers.xml, barebones_Containers.js, and barebones_Containers.css files in your panorama content folder to use the GUI.
  -Finally, include the "Containers.txt" in your scripts directory if you have a pre-build database of attachment settings.

  Library Usage
  -The library when required in loads in the "scripts/Containers.txt" file containing the attachment properties database for use during your game mode.
  -Attachment properties are specified as a 3-tuple of unit model name, attachment point string, and attachment prop model name.
    -Ex: ("models/heroes/antimage/antimage.vmdl" // "attach_hitloc" // "models/items/axe/weapon_heavy_cutter.vmdl")
  -Optional particles can be specified in the "Particles" block of attachmets.txt.
  -To attach a prop to a unit, use the Containers:AttachProp(unit, attachPoint, model[, scale[, properties] ]) function
    -Ex: Containers:AttachProp(unit, "attach_hitloc", "models/items/axe/weapon_heavy_cutter.vmdl", 1.0)
    -This will create the prop and retrieve the properties from the database to attach it to the provided unit
    -If you pass in an already created prop or unit as the 'model' parameter, the attachment system will scale, position, and attach that prop/unit without creating a new one
    -Scale is the prop scale to be used, and defaults to 1.0.  The scale of the prop will also be scaled based on the unit model scale.
    -It is possible not to use the attachment database, but to instead provide the properties directly in the 'properties' parameter.
    -This properties table will look like:
      {
        pitch = 45.0,
        yaw = 55.0,
        roll = 65.0,
        XPos = 10.0,
        YPos = -10.0,
        ZPos = -33.0,
        Animation = "idle_hurt"
      }
  -To retrieve the currently attached prop entity, you can call Containers:GetCurrentAttachment(unit, attachPoint)
    -Ex: local prop = Containers:AttachProp(unit, "attach_hitloc")
    -Calling prop:RemoveSelf() will automatically detach the prop from the unit
  -To access the loaded Attachment database directly (for reading properties directly), you can call Containers:GetAttachmentDatabase()

  Attachment Configuration Usage
  -In tools-mode, execute "attachment_configure <ADDON_NAME>" to activate the attachment configuration GUI for setting up the attachment database.
  -See https://www.youtube.com/watch?v=PS1XmHGP3sw for an example of how to generally use the GUI
  -The Load button will reload the database from disk and update the current attach point/prop model if values are stored therein.
  -The Hide button will hide/remove the current atatach point/prop model being displayed
  -The Save button will save the current properties as well as any other adjusted properties in the attachment database to disk.  
  -Databases will be saved to the scripts/Containers.txt file of the addon you set when calling the attachment_configure <ADDON_NAME> command.
  -More detail to come...

  Notes
  -"attach_origin" can be used as the attachment string for attaching a prop do the origin of the unit, even if that unit has no attachment point named "attach_origin"
  -Attached props will automatically scale when the parent unit/models are scaled, so rescaling individual props after attachment is not necessary.
  -This library requires that the "libraries/timers.lua" be present in your vscripts directory.

  Examples:
  --Attach an Axe axe model to the "attach_hitloc" to a given unit at a 1.0 Scale.
    Containers:AttachProp(unit, "attach_hitloc", "models/items/axe/weapon_heavy_cutter.vmdl", 1.0)

  --For GUI use, see https://www.youtube.com/watch?v=PS1XmHGP3sw

]]

--LinkLuaModifier( "modifier_animation_freeze", "libraries/modifiers/modifier_animation_freeze.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_shopkeeper", "libraries/modifiers/modifier_shopkeeper.lua", LUA_MODIFIER_MOTION_NONE )

--"dota_hud_error_not_enough_gold"        "Not Enough Gold"
--"dota_hud_error_item_out_of_stock"        "Item is out of Stock"
--"dota_hud_error_cant_pick_up_item"        "Inventory Full"
--"dota_hud_error_cant_sell_shop_not_in_range"  "No Shop In Range"
--"dota_hud_error_target_out_of_range"      "Target Out Of Range"
--"dota_hud_error_unit_command_restricted"    "Can't Act"
--"DOTA_FantasyTeamCreate_Error_Header"       "Error"
--"DOTA_Trading_Response_UnknownError"      "Unknown Error"

local GetItem = function(item)
  if type(item) == "number" then
    return EntIndexToHScript(item)
  elseif item and IsValidEntity(item) and item.IsItem and item:IsItem() then 
    return item
  end
end

if not Containers then
  Containers = class({})
end

function Containers:start()
  self.containers = {}
  self.nextID = 0
  self.closeOnOrders = {}
  for i=0,DOTA_MAX_TEAM_PLAYERS do
    self.closeOnOrders[i] = {}
  end

  self.nextFilter = nil
  self.nextContext = nil
  self.disableItemLimit = false

  self.itemKV = LoadKeyValues("scripts/npc/npc_items_custom.txt")
  self.itemIDs = {}

  self.entityShops = {}
  self.defaultInventories = {}

  self.rangeActions = {}
  self.entOrderActions = {}

  for k,v in pairs(LoadKeyValues("scripts/npc/items.txt")) do
    if not self.itemKV[k] then
      self.itemKV[k] = v
    end

    if type(v) == "table" and v.ID then
      self.itemIDs[v.ID] = k
    end
  end

  for k,v in pairs(self.itemKV) do
    if type(v) == "table" and v.ID then
      self.itemIDs[v.ID] = k
    end
  end

  self.oldUniversal = GameRules.SetUseUniversalShopMode
  self.universalShopMode = false
  GameRules.SetUseUniversalShopMode = function(gamerules, universal)
    Containers.universalShopMode = universal
    Containers.oldUniversal(gamerules, universal)
  end

  CustomGameEventManager:RegisterListener("Containers_EntityShopRange", Dynamic_Wrap(Containers, "Containers_EntityShopRange"))
  CustomGameEventManager:RegisterListener("Containers_HideProxy", Dynamic_Wrap(Containers, "Containers_HideProxy"))

  CustomGameEventManager:RegisterListener("Containers_OnLeftClick", Dynamic_Wrap(Containers, "Containers_OnLeftClick"))
  CustomGameEventManager:RegisterListener("Containers_OnRightClick", Dynamic_Wrap(Containers, "Containers_OnRightClick"))
  CustomGameEventManager:RegisterListener("Containers_OnDragFrom", Dynamic_Wrap(Containers, "Containers_OnDragFrom"))
  CustomGameEventManager:RegisterListener("Containers_OnDragWorld", Dynamic_Wrap(Containers, "Containers_OnDragWorld"))
  CustomGameEventManager:RegisterListener("Containers_OnCloseClicked", Dynamic_Wrap(Containers, "Containers_OnCloseClicked"))
  CustomGameEventManager:RegisterListener("Containers_OnButtonPressed", Dynamic_Wrap(Containers, "Containers_OnButtonPressed"))

  Timers:CreateTimer(function()
    local mode = GameRules:GetGameModeEntity()
    if not mode then return .01 end

    mode:SetExecuteOrderFilter(Dynamic_Wrap(Containers, 'OrderFilter'), Containers)
    self.oldFilter = mode.SetExecuteOrderFilter
    mode.SetExecuteOrderFilter = function(mode, fun, context)
      --print('SetExecuteOrderFilter', fun, context)
      Containers.nextFilter = fun
      Containers.nextContext = context
    end
  end)

  

  Timers:CreateTimer(function()
    for id,action in pairs(Containers.rangeActions) do
      local unit = action.unit
      if unit then
        if action.entity and not IsValidEntity(action.entity) then
          Containers.rangeActions[id] = nil  
        else
          local range2 = action.range * action.range
          local pos = action.position or action.entity:GetAbsOrigin()
          local dist = unit:GetAbsOrigin() - pos

          if (dist.x * dist.x + dist.y * dist.y) <= range2 then
            local status, err = pcall(action.action, action.playerID, unit, action.entity or action.position)
            if not status then print('[containers.lua] RangeAction failure:' .. err) end

            Containers.rangeActions[id] = nil  
          end
        end
      else
        Containers.rangeActions[id] = nil
      end
    end
    return .01
  end)
end

--not in range of secret shop
--[   PanoramaScript         ]: ErrorMessage: {"splitscreenplayer":0,"reason":62,"message":""}

--can't purchase inventory full
--[   PanoramaScript         ]: ErrorMessage: {"splitscreenplayer":0,"reason":80,"message":"#dota_hud_error_cant_purchase_inventory_full"}

--tutorial shop not in range
--[   PanoramaScript         ]: ErrorMessage: {"splitscreenplayer":0,"reason":67}

--purchased item
--by unit with inventory
  -- not in range of shop -> purchase to stash of player issuer
  -- secret shop only, purchased non-ss item -> purcahse to stash of player issuer
  -- secret shop only, purchased ss item -> purchase to inventory
  -- side shop only, purchased non-side item -> purchase to stash of player issuer
  -- side shop only, purchased side item -> purchase to inventory
  -- home shop only, full inventory -> drop on position
  -- home shop only, not full inventory -> purchase to inventory
--by courier
  -- same as unit with inventory except purchase can happen without direct selection of the unit
--by selected hero unit
  -- same as unit with inventory except
  -- home shop only, full inventory -> purchase to stash
  -- if SetStashPurchasingDisabled and not in range of shop, deny



local closeOnOrderSkip = {
  [DOTA_UNIT_ORDER_PURCHASE_ITEM] = true,
  [DOTA_UNIT_ORDER_GLYPH] = true,
  [DOTA_UNIT_ORDER_HOLD_POSITION] = true,
  [DOTA_UNIT_ORDER_STOP] = true,
  [DOTA_UNIT_ORDER_EJECT_ITEM_FROM_STASH] = true,
  [DOTA_UNIT_ORDER_DISASSEMBLE_ITEM] = true,
  [DOTA_UNIT_ORDER_PING_ABILITY] = true,
  --[DOTA_UNIT_ORDER_TRAIN_ABILITY] = true,
}

function Containers:AddItemToUnit(unit, item)
  if item and unit then
    local defInventory = Containers:GetDefaultInventory(unit)
    if defInventory then
      if not defInventory:AddItem(item) then
        CreateItemOnPositionSync(unit:GetAbsOrigin() + RandomVector(10), item)
      end
    else
      local iname = item:GetAbilityName()
      local exists = false
      local full = true
      for i=0,5 do
        local it = unit:GetItemInSlot(i)
        if not it then
          full = false
        elseif it:GetAbilityName() == iname then
          exists = true
        end
      end

      if not full or (full and item:IsStackable() and exists) then
        unit:AddItem(item)
      else
        CreateItemOnPositionSync(unit:GetAbsOrigin() + RandomVector(10), item)
      end
    end
  end
end

function Containers:SetDisableItemLimit(disable)
  self.disableItemLimit = disable
end

function Containers:DisplayError(pid, message)
  local player = PlayerResource:GetPlayer(pid)
  if player then
    CustomGameEventManager:Send_ServerToPlayer(player, "cont_create_error_message", {message=message})
  end
end

function Containers:EmitSoundOnClient(pid, sound)
  local player = PlayerResource:GetPlayer(pid)
  if player then
    CustomGameEventManager:Send_ServerToPlayer(player, "cont_emit_client_sound", {sound=sound})
  end
end

function Containers:OrderFilter(order)
  --print('Containers:OrderFilter')
  --PrintTable(order)

  local ret = true

  if Containers.nextFilter then
    ret = Containers.nextFilter(Containers.nextContext, order)
  end

  if not ret then
    return false
  end

  local issuerID = order.issuer_player_id_const
  local queue = order.queue == 1

  if issuerID == -1 then return true end

  -- close on order
  if not closeOnOrderSkip[order.order_type] then
    local oConts = Containers.closeOnOrders[issuerID]
    for id,cont in pairs(oConts) do
      if IsValidContainer(cont) then
        cont:Close(issuerID)
      else
        oConts[id] = nil
      end
    end
  end

  if not queue and order.units["0"] then
    Containers.rangeActions[order.units["0"]] = nil
  end

  if order.units["0"] and Containers.entOrderActions[order.entindex_target] then
    local unit = EntIndexToHScript(order.units["0"])
    local tab = Containers.entOrderActions[order.entindex_target]
    local target = EntIndexToHScript(order.entindex_target)
    local range = tab.range or 150
    if tab.container then range = (tab.container:GetRange() or 150) end
    local test = tab.test
    local success = false
    local unitpos = unit:GetAbsOrigin()
    local diff = unitpos - target:GetAbsOrigin()
    local dist = diff:Length2D()
    local pos = unitpos
    if dist > range * .9 then
      pos = target:GetAbsOrigin() + diff:Normalized() * range * .9
    end

    if test and type(test) == "function" then
      local result, err = pcall(test, order)
      if err then
        print("[containers.lua] Order Action Test Failure: " .. err)
      else
        success = result
        if result then
          if target.GetContainedItem then
            order.order_type = DOTA_UNIT_ORDER_MOVE_TO_POSITION
            order.position_x = pos.x
            order.position_y = pos.y
            order.position_z = pos.z
          else
            order.order_type = DOTA_UNIT_ORDER_MOVE_TO_TARGET
          end
        end
      end
    else
      if target.GetContainedItem then
        order.order_type = DOTA_UNIT_ORDER_MOVE_TO_POSITION
        order.position_x = pos.x
        order.position_y = pos.y
        order.position_z = pos.z
      else
        order.order_type = DOTA_UNIT_ORDER_MOVE_TO_TARGET
      end
      success = true
    end

    if success then
      Containers.rangeActions[order.units["0"]] = {
        unit = unit,
        entity = target,
        --position = pos,
        range = range,
        playerID = issuerID,
        action = tab.action,
      }
    end
  end

  --DOTA_UNIT_ORDER_GIVE_ITEM
  if order.units["0"] and order.order_type == DOTA_UNIT_ORDER_GIVE_ITEM then
    local unit = EntIndexToHScript(order.units["0"])
    local item = EntIndexToHScript(order.entindex_ability)
    local target = EntIndexToHScript(order.entindex_target)

    local defInventory = Containers:GetDefaultInventory(target)
    if defInventory then
      order.order_type = DOTA_UNIT_ORDER_MOVE_TO_TARGET

      Containers.rangeActions[order.units["0"]] = {
        unit = unit,
        entity = target,
        range = 180,
        playerID = issuerID,
        action = function(playerID, unit, target)
          if IsValidEntity(target) and target:IsAlive() then
            unit:DropItemAtPositionImmediate(item, unit:GetAbsOrigin())
            local drop = nil
            for i=GameRules:NumDroppedItems()-1,0,-1 do
              drop = GameRules:GetDroppedItem(i)
              if drop:GetContainedItem() == item then
                Containers:AddItemToUnit(target, item)
                drop:RemoveSelf()
                break
              end
            end
          end

          unit:Stop()
        end,
      }
    else
      return true
    end
  end

  if order.units["0"] and order.order_type == DOTA_UNIT_ORDER_PICKUP_ITEM then
    local unit = EntIndexToHScript(order.units["0"])
    local physItem = EntIndexToHScript(order.entindex_target)
    local unitpos = unit:GetAbsOrigin()
    local diff = unitpos - physItem:GetAbsOrigin()
    local dist = diff:Length2D()
    local pos = unitpos
    if dist > 90 then
      pos = physItem:GetAbsOrigin() + diff:Normalized() * 90
    end

    local defInventory = Containers:GetDefaultInventory(unit)
    if defInventory then
      order.order_type = DOTA_UNIT_ORDER_MOVE_TO_POSITION
      order.position_x = pos.x
      order.position_y = pos.y
      order.position_z = pos.z

      Containers.rangeActions[order.units["0"]] = {
        unit = unit,
        position = physItem:GetAbsOrigin(),
        range = 100,
        playerID = issuerID,
        action = function(playerID, unit, target)
          if IsValidEntity(physItem) then
            local item = physItem:GetContainedItem()
            if item and defInventory:AddItem(item) then
              physItem:RemoveSelf()
            end
          end
        end,
      }
    end
  end

  if order.units["0"] and order.order_type == DOTA_UNIT_ORDER_PURCHASE_ITEM then
    local unit = EntIndexToHScript(order.units["0"])
    local itemID = order.entindex_ability
    local itemName = Containers.itemIDs[itemID]
    local player = PlayerResource:GetPlayer(issuerID)
    local ownerID = issuerID --unit:GetMainControllingPlayer()
    local owner = PlayerResource:GetSelectedHeroEntity(ownerID)

    local defInventory = Containers:GetDefaultInventory(unit)

    if defInventory then
      local item = CreateItem(itemName, owner, owner)
      if not defInventory:AddItem(item) then
        CreateItemOnPositionSync(unit:GetAbsOrigin() + RandomVector(10), item)
      end
      return false
    elseif Containers.disableItemLimit then
      if not unit:HasInventory() then
        unit = owner
        if unit == nil then return false end
      end

      local itemDefinition = Containers.itemKV[itemName]
      local itemSide = itemDefinition["SideShop"] == 1
      local itemSecret = itemDefinition["SecretShop"] == 1

      local toStash = true
      local full = true
      for i=0,5 do
        if unit:GetItemInSlot(i) == nil then
          full = false
          break
        end
      end

      local shops = Containers.entityShops[unit:GetEntityIndex()] or {home=false, side=false, secret=false}
      if not unit:IsAlive() then
        shops = {home=true, side=false, secret=false}
      end
      local stashPurchasingDisabled = GameRules:GetGameModeEntity():GetStashPurchasingDisabled()
      local universalShopMode = Containers.universalShopMode

      if universalShopMode then
        if not shops.home and not shops.side and not shops.secret then
          if stashPurchasingDisabled then 
            CustomGameEventManager:Send_ServerToPlayer(player, "cont_create_error_message", {reason=67})
            return false 
          end

          toStash = true
        end
      else
        if not shops.home and not shops.side and not shops.secret then
          -- not in range of any shops
          if stashPurchasingDisabled then 
            CustomGameEventManager:Send_ServerToPlayer(player, "cont_create_error_message", {reason=67})
            return false 
          end
        elseif itemSecret and shops.secret then
          toStash = false
        elseif itemSide and shops.side then
          toStash = false
        elseif shops.home and not full then
          toStash = false
        end
      end

      local item = CreateItem(itemName, owner, owner)
      local fullyShareStacking = Containers.itemKV[itemName]["ItemShareability"] == "ITEM_FULLY_SHAREABLE_STACKING"
      local dropped = {}
      local cost = item:GetCost()

      if toStash then
        local restore = {}
        for i=0,5 do
          local slot = owner:GetItemInSlot(i)
          if slot == nil then
            local item = CreateItem("item_blank_item", owner, owner)
            owner:AddItem(item)
          elseif fullyShareStacking and slot:GetAbilityName() == itemName 
            or ((slot:GetAbilityName() == "item_ward_dispenser" or slot:GetAbilityName() == "item_ward_observer" or slot:GetAbilityName() == "item_ward_sentry")and 
              (itemName == "item_ward_observer" or itemName == "item_ward_sentry")) then
            owner:DropItemAtPositionImmediate(slot, owner:GetAbsOrigin())
            for i=GameRules:NumDroppedItems()-1,0,-1 do
              local drop = GameRules:GetDroppedItem(i)
              if drop:GetContainedItem() == slot then
                table.insert(dropped, drop)
                break
              end
            end

            local item = CreateItem("item_blank_item", owner, owner)
            owner:AddItem(item)
          elseif slot:GetOwner() == owner or slot:GetPurchaser() == owner then
            restore[slot:GetEntityIndex()] = {owner=slot:GetOwner(), purchaser=slot:GetPurchaser()}
            slot:SetPurchaser(nil)
            slot:SetOwner(nil)
          end
        end

        if owner:GetNumItemsInStash() == 6 then
          if not unit.HasAnyAvailableInventorySpace and shops.home then
            CreateItemOnPositionSync(unit:GetAbsOrigin() + RandomVector(20), item)
          else
            local slot = DOTA_STASH_SLOT_6
            local slotItem = owner:GetItemInSlot(slot)
            if slotItem and slotItem:GetAbilityName() == item:GetAbilityName() then
              slot = DOTA_STASH_SLOT_5
            end
            owner:SwapItems(slot,14)
            owner:AddItem(item)
            owner:EjectItemFromStash(item)
            owner:SwapItems(14,slot)
          end
        else
          owner:AddItem(item)
        end

        for i=0,5 do
          local item = owner:GetItemInSlot(i)
          if item and restore[item:GetEntityIndex()] ~= nil then
            item:SetPurchaser(restore[item:GetEntityIndex()].purchaser)
            item:SetOwner(restore[item:GetEntityIndex()].owner)
          end
        end
      else
        if full then
          local physItem = CreateItemOnPositionSync(unit:GetAbsOrigin() + RandomVector(5), item)
          unit:PickupDroppedItem(physItem)
        else
          for i=6,11 do
            local item = unit:GetItemInSlot(i)
            if not shops.home and item and item:GetPurchaser() == owner then
              item:SetPurchaser(nil)
            end
          end

          unit:AddItem(item)

          for i=6,11 do
            local item = unit:GetItemInSlot(i)
            if not shops.home and item and item:GetPurchaser() == nil then
              item:SetPurchaser(owner)
            end
          end
        end
      end

      for i=0,11 do
        local item = owner:GetItemInSlot(i)
        if item and item:GetAbilityName() == "item_blank_item" then
          owner:RemoveItem(item)
        end
      end

      local queue = false
      for _,drop in ipairs(dropped) do
        ExecuteOrderFromTable({
          UnitIndex = owner:GetEntityIndex(),
          TargetIndex = drop:GetEntityIndex(),
          OrderType = DOTA_UNIT_ORDER_PICKUP_ITEM,
          Queue = queue,
          })
        queue = true
        --owner:AddItem(drop:GetContainedItem())
        --drop:RemoveSelf()
      end

      PlayerResource:SpendGold(ownerID, cost, DOTA_ModifyGold_PurchaseItem)

      return false
    end
  end

  return ret
end

function Containers:Containers_EntityShopRange(args)
  local unit = args.unit
  local shop = args.shop

  local cs = Containers.entityShops
  if not cs[unit] then cs[unit] = {home=false, side=false, secret=false} end

  cs[unit].home = bit.band(shop, 1) ~= 0
  cs[unit].side = bit.band(shop, 2) ~= 0
  cs[unit].secret = bit.band(shop, 4) ~= 0
end

function Containers:Containers_HideProxy(args)
  local abil = EntIndexToHScript(args.abilID)
  if abil and abil.GetAbilityName and (abil:GetAbilityName() == "containers_lua_targeting" or abil:GetAbilityName() == "containers_lua_targeting_tree" )
      and abil:GetOwner():GetPlayerOwnerID() == args.PlayerID then
    abil:SetHidden(true)
  end
end

function Containers:Containers_OnLeftClick(args)
  print('Containers_OnLeftClick')
  PrintTable(args)

  local playerID = args.PlayerID
  local unit = args.unit == nil and nil or EntIndexToHScript(args.unit)
  local contID = args.contID
  local itemID = args.itemID
  local slot =  args.slot

  if not playerID then return end
  if unit and unit:GetMainControllingPlayer() ~= playerID then return end

  local container = Containers.containers[contID]
  if not container then return end

  local fun = container._OnLeftClick
  if fun == false then return end

  local item = EntIndexToHScript(args.itemID)
  if not (item and IsValidEntity(item) and item.IsItem and item:IsItem()) then return end

  local itemInSlot = container:GetItemInSlot(slot)
  if itemInSlot ~= item then return end

  local range = container:GetRange()
  local ent = container:GetEntity()
  if range == nil and ent and unit ~= ent then return end
  if range and ent and unit and (ent:GetAbsOrigin() - unit:GetAbsOrigin()):Length2D() >= range then 
    Containers:DisplayError(playerID,"#dota_hud_error_target_out_of_range")
    return 
  end

  if type(fun) == "function" then
    fun(playerID, unit, container, item, slot)
  else
    Containers:OnLeftClick(playerID, unit, container, item, slot)
  end
end

function Containers:Containers_OnRightClick(args)
  print('Containers_OnRightClick')
  PrintTable(args)

  local playerID = args.PlayerID
  local unit = args.unit == nil and nil or EntIndexToHScript(args.unit)
  local contID = args.contID
  local itemID = args.itemID
  local slot =  args.slot

  if not playerID then return end
  if unit and unit:GetMainControllingPlayer() ~= playerID then return end

  local container = Containers.containers[contID]
  if not container then return end

  local fun = container._OnRightClick
  if fun == false then return end

  local item = EntIndexToHScript(args.itemID)
  if not (item and IsValidEntity(item) and item.IsItem and item:IsItem()) then return end

  local itemInSlot = container:GetItemInSlot(slot)
  if itemInSlot ~= item then return end

  local range = container:GetRange()
  local ent = container:GetEntity()
  if range == nil and ent and unit ~= ent then return end
  if range and ent and unit and (ent:GetAbsOrigin() - unit:GetAbsOrigin()):Length2D() >= range then 
    Containers:DisplayError(playerID,"#dota_hud_error_target_out_of_range")
    return 
  end

  if type(fun) == "function" then
    fun(playerID, unit, container, item, slot)
  else
    Containers:OnRightClick(playerID, unit, container, item, slot)
  end
end

function Containers:Containers_OnDragFrom(args)
  print('Containers_OnDragFrom')
  PrintTable(args)

  local playerID = args.PlayerID
  local unit = args.unit == nil and nil or EntIndexToHScript(args.unit)
  local contID = args.contID
  local itemID = args.itemID
  local fromSlot = args.fromSlot
  local toContID = args.toContID
  local toSlot = args.toSlot

  if not playerID then return end
  if unit and unit:GetMainControllingPlayer() ~= playerID then return end

  local container = Containers.containers[contID]
  if not container then return end

  local toContainer = Containers.containers[toContID]
  if not toContainer then return end

  local item = EntIndexToHScript(args.itemID)
  if not (item and IsValidEntity(item) and item.IsItem and item:IsItem()) then return end

  local itemInSlot = container:GetItemInSlot(fromSlot)
  if itemInSlot ~= item then return end

  if toSlot > toContainer:GetSize() then return end

  local range = container:GetRange()
  local ent = container:GetEntity()
  if range == nil and ent and unit ~= ent then return end
  if range and ent and unit and (ent:GetAbsOrigin() - unit:GetAbsOrigin()):Length2D() >= range then 
    Containers:DisplayError(playerID,"#dota_hud_error_target_out_of_range")
    return 
  end
  
  if container == toContainer then
    if container.canDragWithin[playerID] == false then return end

    local fun = container._OnDragWithin
    if fun == false then return end

    if type(fun) == "function" then
      fun(playerID, unit, container, item, fromSlot, toSlot)
    else
      Containers:OnDragWithin(playerID, unit, container, item, fromSlot, toSlot)
    end
  else
    if container.canDragFrom[playerID] == false or toContainer.canDragTo[playerID] == false then return end

    local range = toContainer:GetRange()
    local ent = toContainer:GetEntity()
    if range and ent and unit and (ent:GetAbsOrigin() - unit:GetAbsOrigin()):Length2D() >= range then 
      Containers:DisplayError(playerID,"#dota_hud_error_target_out_of_range")
      return 
    end

    local fun = container._OnDragFrom
    if fun == false then return end

    if type(fun) == "function" then
      fun(playerID, unit, container, item, fromSlot, toContainer, toSlot)
    else
      Containers:OnDragFrom(playerID, unit, container, item, fromSlot, toContainer, toSlot)
    end
  end
end

function Containers:Containers_OnDragWorld(args)
  print('Containers_OnDragWorld')
  PrintTable(args)

  local playerID = args.PlayerID
  local unit = args.unit == nil and nil or EntIndexToHScript(args.unit)
  local contID = args.contID
  local itemID = args.itemID
  local slot =  args.slot
  local position = args.position
  local entity = nil
  if type(args.entity) == "number" then entity = EntIndexToHScript(args.entity) end

  if not playerID then return end
  if unit and unit:GetMainControllingPlayer() ~= playerID then return end

  local container = Containers.containers[contID]
  if not container then return end

  local fun = container._OnDragWorld
  if fun == false then return end

  local item = EntIndexToHScript(args.itemID)
  if not (item and IsValidEntity(item) and item.IsItem and item:IsItem()) then return end

  local itemInSlot = container:GetItemInSlot(slot)
  if itemInSlot ~= item then return end

  if not position["0"] or not position["1"] or not position["2"] then return end
  position = Vector(position["0"], position["1"], position["2"])

  if container.canDragFrom[playerID] == false then return end

  local range = container:GetRange()
  local ent = container:GetEntity()
  if range == nil and ent and unit ~= ent then return end
  if range and ent and unit and (ent:GetAbsOrigin() - unit:GetAbsOrigin()):Length2D() >= range then 
    Containers:DisplayError(playerID,"#dota_hud_error_target_out_of_range")
    return 
  end

  if type(fun) == "function" then
    fun(playerID, unit, container, item, slot, position, entity)
  else
    Containers:OnDragWorld(playerID, unit, container, item, slot, position, entity)
  end
end

function Containers:Containers_OnCloseClicked(args)
  print('Containers_OnCloseClicked')
  PrintTable(args)

  local playerID = args.PlayerID
  local unit = args.unit == nil and nil or EntIndexToHScript(args.unit)
  local contID = args.contID

  if not playerID then return end

  local container = Containers.containers[contID]
  if not container then return end

  local fun = container._OnCloseClicked
  if fun == false then return end

  if type(fun) == "function" then
    fun(playerID, unit, container)
  else
    Containers:OnCloseClicked(playerID, unit, container)
  end
end

function Containers:Containers_OnButtonPressed(args)
  print('Containers_OnButtonPressed')
  PrintTable(args)

  local playerID = args.PlayerID
  local unit = args.unit == nil and nil or EntIndexToHScript(args.unit)
  local contID = args.contID
  local buttonNumber = args.button

  if not playerID then return end
  if unit and unit:GetMainControllingPlayer() ~= playerID then return end

  local container = Containers.containers[contID]
  if not container then return end

  local fun = container._OnButtonPressed
  if fun == false then return end

  if buttonNumber < 1 then return end
  local buttonName = container:GetButtonName(buttonNumber)

  if not buttonName then return end

  local range = container:GetRange()
  local ent = container:GetEntity()
  if range == nil and ent and unit ~= ent then return end
  if range and ent and unit and (ent:GetAbsOrigin() - unit:GetAbsOrigin()):Length2D() >= range then 
    Containers:DisplayError(playerID,"#dota_hud_error_target_out_of_range")
    return 
  end

  if type(fun) == "function" then
    fun(playerID, unit, container, buttonNumber, buttonName)
  else
    Containers:OnButtonPressed(playerID, unit, container, buttonNumber, buttonName)
  end
end


function Containers:OnLeftClick(playerID, unit, container, item, slot)
  print("Containers:OnLeftClick", playerID, unit, container, item:GetEntityIndex(), slot)

  local hero = PlayerResource:GetSelectedHeroEntity(playerID)
  container:ActivateItem(hero, item, playerID)
end

function Containers:OnRightClick(playerID, unit, container, item, slot)
  print("Containers:OnRightClick", playerID, unit, container, item:GetEntityIndex(), slot)
end

function Containers:OnDragWithin(playerID, unit, container, item, fromSlot, toSlot)
  print('Containers:OnDragWithin', playerID, unit, container, item, fromSlot, toSlot)

  container:SwapSlots(fromSlot, toSlot, true)
end

function Containers:OnDragFrom(playerID, unit, container, item, fromSlot, toContainer, toSlot)
  print('Containers:OnDragFrom', playerID, unit, container, item, fromSlot, toContainer, toSlot)

  if toContainer._OnDragTo == false then return end

  local fun = nil
  if type(toContainer._OnDragTo) == "function" then
    fun = toContainer._OnDragTo
  end

  if fun then
    fun(playerID, unit, container, item, fromSlot, toContainer, toSlot)
  else
    Containers:OnDragTo(playerID, unit, container, item, fromSlot, toContainer, toSlot)
  end

end

function Containers:OnDragTo(playerID, unit, container, item, fromSlot, toContainer, toSlot)
  print('Containers:OnDragTo', playerID, unit, container, item, fromSlot, toContainer, toSlot)

  local item2 = toContainer:GetItemInSlot(toSlot)
  local addItem = nil
  if item2 and IsValidEntity(item2) and (item2:GetAbilityName() ~= item:GetAbilityName() or not item2:IsStackable() or not item:IsStackable()) then
    toContainer:RemoveItem(item2)
    addItem = item2
  end

  if toContainer:AddItem(item, toSlot) then
    container:ClearSlot(fromSlot)
    if addItem then
      container:AddItem(addItem, fromSlot)
    end
    return true
  end
   
  return false 
end

function Containers:OnDragWorld(playerID, unit, container, item, slot, position, entity)
  print('Containers:OnDragWorld', playerID, unit, container, item, slot, position, entity)

  local unitpos = unit:GetAbsOrigin()
  local diff = unitpos - position
  local dist = diff:Length2D()

  if IsValidEntity(entity) and entity.GetContainedItem and Containers.entOrderActions[entity:GetEntityIndex()] and Containers.entOrderActions[entity:GetEntityIndex()].container then
    local tcont = Containers.entOrderActions[entity:GetEntityIndex()].container
    Containers:SetRangeAction(unit,{
      container = tcont,
      entity = entity,
      playerID = playerID,
      action = function(playerID, unit, target)
        if IsValidEntity(target) and container:ContainsItem(item) then
          container:RemoveItem(item)
          if not tcont:AddItem(item) then
            CreateItemOnPositionSync(unit:GetAbsOrigin() + RandomVector(10), item)
          end
        end

        unit:Stop()
      end
    })
  elseif IsValidEntity(entity) and entity:GetTeam() == unit:GetTeam() and entity.HasInventory and entity:HasInventory() and entity:IsAlive() then
    ExecuteOrderFromTable({
      UnitIndex=   unit:GetEntityIndex(),
      OrderType=   DOTA_UNIT_ORDER_MOVE_TO_TARGET,
      TargetIndex= entity:GetEntityIndex(),
    })

    Containers.rangeActions[unit:GetEntityIndex()] = {
      unit = unit,
      entity = entity,
      range = 180,
      playerID = playerID,
      action = function(playerID, unit, target)
        if IsValidEntity(target) and target:IsAlive() and container:ContainsItem(item) then
          container:RemoveItem(item)
          Containers:AddItemToUnit(target, item)
        end

        unit:Stop()
      end,
    }
  else
    local pos = unitpos
    if dist > 150 *.9 then
      pos = position + diff:Normalized() * 150 * .9
    end

    --DebugDrawCircle(pos, Vector(255,0,0), 1, 50.0, true, 1)

    --unit:MoveToPosition(pos)
    ExecuteOrderFromTable({
      UnitIndex= unit:GetEntityIndex(),
      OrderType= DOTA_UNIT_ORDER_MOVE_TO_POSITION,
      Position=  pos,
    })

    Containers.rangeActions[unit:GetEntityIndex()] = {
      unit = unit,
      --entity = target,
      position = position,
      range = 150,
      playerID = playerID,
      action = function(playerID, unit, target)
        if container:ContainsItem(item) then
          container:RemoveItem(item)
          CreateItemOnPositionSync(position, item)
        end
      end,
    }
  end
end


function Containers:OnCloseClicked(playerID, unit, container)
  print('Containers:OnCloseClicked', playerID, unit, container)
  container:Close(playerID)
end

function Containers:OnButtonPressed(playerID, unit, container, buttonNumber, buttonName)
  print('Button ' .. buttonNumber .. ':\'' .. buttonName .. '\' Pressed by player:' .. playerID .. ' for container ' .. container.id .. '.  No OnButtonPressed handler.')
end

--search bar?
--dragtoworld other than give and drop
--drag to regular inventory
--UNIT CHECKS ON COMMANDS

-- change casting unit handling?
-- test out Equipping items
-- callback events like item added?

-- container context menu?
-- add unit checks to event functions
-- add unit checks to activate
-- add filter checks on stuff?
-- equipment container

function Containers:SetEntityOrderAction(entity, tab)
  --{test=tab.test, action=tab.action, range=tab.range, container=tab.container}
  if IsValidEntity(entity) then
    self.entOrderActions[entity:GetEntityIndex()] = tab
  end
end

function Containers:SetRangeAction(unit, tab)
  if not IsValidEntity(unit) then
    return
  end

  local range = tab.range or 150
  if tab.container then range = (tab.container:GetRange() or 150) end
  local tpos = tab.position or tab.entity:GetAbsOrigin()
  local unitpos = unit:GetAbsOrigin()
  local diff = unitpos - tpos
  local dist = diff:Length2D()
  local pos = unitpos
  if dist > range * .9 then
    pos = tpos + diff:Normalized() * range * .9
  end

  tab.unit = unit

  if tab.entity then
    ExecuteOrderFromTable({
      UnitIndex=   unit:GetEntityIndex(),
      OrderType=   DOTA_UNIT_ORDER_MOVE_TO_TARGET,
      TargetIndex= tab.entity:GetEntityIndex(),
    })
  else
    ExecuteOrderFromTable({
      UnitIndex=   unit:GetEntityIndex(),
      OrderType=   DOTA_UNIT_ORDER_MOVE_TO_POSITION,
      Position =   pos,
    })
  end

  Containers.rangeActions[unit:GetEntityIndex()] = tab
end

function Containers:SetDefaultInventory(unit, container)
  self.defaultInventories[unit:GetEntityIndex()] = container
end

function Containers:GetDefaultInventory(unit)
  local di = self.defaultInventories[unit:GetEntityIndex()]
  if IsValidContainer(di) then
    return di
  else
    self.defaultInventories[unit:GetEntityIndex()] = nil
    return nil
  end
end

function Containers:CreateShop(cont)
  local shop = self:CreateContainer(cont)

  local ptID = shop.ptID
  local pt = {shop = 1,
              }

  if cont.prices then
    for k,v in pairs(cont.prices) do
      local item = k
      if type(k) ~= "number" then
        item = k:GetEntityIndex()
      end

      pt['price' .. k] = v
    end
  end

  if cont.stocks then
    for k,v in pairs(cont.stocks) do
      local item = k
      if type(k) ~= "number" then
        item = k:GetEntityIndex()
      end

      pt['stock' .. k] = v
    end
  end

  PlayerTables:SetTableValues(ptID, pt)

  function shop:BuyItem(playerID, unit, item)
    local cost = self:GetPrice(item)
    local stock = self:GetStock(item)
    local owner = PlayerResource:GetSelectedHeroEntity(playerID)
    local gold = PlayerResource:GetGold(playerID)
    if gold >= cost and (stock == nil or stock > 0) then
      local newItem = CreateItem(item:GetAbilityName(), owner, owner)
      newItem:SetLevel(item:GetLevel())
      newItem:SetCurrentCharges(item:GetCurrentCharges())

      PlayerResource:SpendGold(playerID, cost, DOTA_ModifyGold_PurchaseItem)

      if stock then
        self:SetStock(item, stock-1)
      end

      Containers:EmitSoundOnClient(playerID, "General.Buy")

      return newItem
    elseif stock ~= nil and stock <= 0 then
      Containers:DisplayError(playerID, "#dota_hud_error_item_out_of_stock")
    elseif gold < cost then
      Containers:DisplayError(playerID, "#dota_hud_error_not_enough_gold")
    end
  end

  function shop:SellItem()

  end

  function shop:GetPrice(item)
    item = GetItem(item)
    return PlayerTables:GetTableValue(ptID, "price" .. item:GetEntityIndex()) or item:GetCost()
  end
  function shop:SetPrice(item, price)
    item = GetItem(item)
    if price then
      PlayerTables:SetTableValue(ptID, "price" .. item:GetEntityIndex(), price)
    else
      PlayerTables:DeleteTableKey(ptID, "price" .. item:GetEntityIndex())
    end
  end

  function shop:GetStock(item)
    item = GetItem(item)
    return PlayerTables:GetTableValue(ptID, "stock" .. item:GetEntityIndex())
  end
  function shop:SetStock(item, stock)
    item = GetItem(item)
    if stock then
      PlayerTables:SetTableValue(ptID, "stock" .. item:GetEntityIndex(), stock)
    else
      PlayerTables:DeleteTableKey(ptID, "stock" .. item:GetEntityIndex())
    end
  end

  shop.canDragWithin = {}
  shop:AddSkin("ContainerShop")
  shop:OnDragWorld(false)
  shop:OnDragWithin(false)
  shop:OnLeftClick(false)
  shop:OnDragTo(function(playerID, unit, container, item, fromSlot, toContainer, toSlot)
    print('Shop:OnDragTo', playerID, unit, container, item, fromSlot, toContainer, toSlot)
  end)
  shop:OnDragFrom(function(playerID, unit, container, item, fromSlot, toContainer, toSlot)
    print('Shop:OnDragFrom', playerID, unit, container, item, fromSlot, toContainer, toSlot)
  end)
  --[[shop:OnLeftClick(function(playerID, unit, container, item, slot)
    print("Shop:OnLeftClick", playerID, unit, container, item:GetEntityIndex(), slot)
  end)]]
  shop:OnRightClick(function(playerID, unit, container, item, slot)
    print("Shop:OnRightClick", playerID, unit, container, item:GetEntityIndex(), slot)

    local defInventory = Containers:GetDefaultInventory(unit)
    if not defInventory and not unit:HasInventory() then return end

    local item = container:BuyItem(playerID, unit, item)
    Containers:AddItemToUnit(unit, item)
  end)


  return shop
end

function Containers:CreateContainer(cont)
  local pt =
    {id =          self.nextID,
     ptID =        ID_BASE .. self.nextID,
     --unit =        cont.unit

     layout =      cont.layout or {2,2},
     size =        0, -- calculated below
     rowStarts =   {}, -- calculated below
     --slot1 =       1111, -- set up below
     --slot2 =       1122, -- set up below 
     skins =       {},
     buttons =     cont.buttons or {},
     headerText =  cont.headerText or "Container",
     draggable =   cont.draggable or true,
     position =    cont.position or "100px 200px 0px",

     OnLeftClick =     type(cont.OnLeftClick) == "function" and true or cont.OnLeftClick,
     OnRightClick =    type(cont.OnRightClick) == "function" and true or cont.OnRightClick,
     OnDragFrom  =     type(cont.OnDragFrom) == "function" and true or cont.OnDragFrom,
     OnDragWorld =     false,
     OnCloseClicked =  type(cont.OnCloseClicked) == "function" and true or cont.OnCloseClicked,
     OnButtonPressed = type(cont.OnButtonPressed) == "function" and true or cont.OnButtonPressed,
    }

  local c = {id = pt.id,
    ptID = pt.ptID,
    items = {},
    itemNames = {},
    subs = {},
    opens = {},
    range = cont.range,
    closeOnOrder = cont.closeOnOrder == nil and false or cont.closeOnOrder,

    canDragFrom = {},
    canDragTo = {},
    canDragWithin = {},

    forceOwner =         cont.forceOwner,
    forcePurchaser =     cont.forcePurchaser,
    --entity     =     nil,

    _OnLeftClick =     cont.OnLeftClick,
    _OnRightClick =    cont.OnRightClick,
    _OnDragTo =        cont.OnDragTo,
    _OnDragFrom =      cont.OnDragFrom,
    _OnDragWithin =    cont.OnDragWithin,
    _OnDragWorld =     cont.OnDragWorld,
    _OnCloseClicked =  cont.OnCloseClicked,
    _OnButtonPressed = cont.OnButtonPressed,
    _OnEmptyAndClosed= cont.OnEmptyAndClosed,
  }

  if cont.OnDragWorld ~= nil and (type(cont.OnDragWorld) == "function" or cont.OnDragWorld == true) then
    pt.OnDragWorld = true
  end

  --if cont.setOwner then c.setOwner = cont.setOwner end
  --if cont.setPurchaser then c.setOwner = cont.setPurchaser end
  
  if cont.entity and type(cont.entity) == "number" then
    pt.entity = cont.entity
  elseif cont.entity and cont.entity.GetEntityIndex then
    pt.entity = cont.entity:GetEntityIndex()
  end

  for i,row in ipairs(pt.layout) do
    table.insert(pt.rowStarts, pt.size+1)
    pt.size = pt.size + row
  end

  if cont.skins then
    for k,v in pairs(cont.skins) do
      if type(v) == "string" then
        pt.skins[v] = true
      end
    end
  end

  if cont.items then
    for k,v in pairs(cont.items) do
      if type(k) == "number" then
        local item = v
        if type(v) == "number" then 
          item = EntIndexToHScript(item)
        end

        if item and IsValidEntity(item) and item.IsItem and item:IsItem() then 
          local itemid = item:GetEntityIndex() 
          local itemname = item:GetAbilityName()
          pt['slot' .. k] = itemid 
          c.items[itemid] = k
          c.itemNames[itemname] = c.itemNames[itemname] or {}
          c.itemNames[itemname][itemid] = k
        end
      end
    end
  end

  if cont.cantDragFrom then
    for _,pid in ipairs(cont.cantDragFrom) do
      if type(pid) == "number" then
        c.canDragFrom[pid] = false
      end
    end
  end

  if cont.cantDragTo then
    for _,pid in ipairs(cont.cantDragTo) do
      if type(pid) == "number" then
        c.canDragTo[pid] = false
      end
    end
  end

  if cont.pids then
    for _,pid in ipairs(cont.pids) do
      c.subs[pid] = true
    end
  end

  PlayerTables:CreateTable(c.ptID, pt, c.subs)

  function c:ActivateItem(unit, item, playerID)
    if item:GetOwner() ~= unit or not item:IsFullyCastable() then 
      Containers:EmitSoundOnClient(playerID, "General.Cancel")
      return
    end

    local playerID = playerID or unit:GetPlayerOwnerID()

    local behavior =     item:GetBehavior()
    local targetType =   item:GetAbilityTargetType()
    local unrestricted = bit.band(behavior, DOTA_ABILITY_BEHAVIOR_UNRESTRICTED) ~= 0
    local rootDisables = bit.band(behavior, DOTA_ABILITY_BEHAVIOR_ROOT_DISABLES) ~= 0
    local channelled =   bit.band(behavior, DOTA_ABILITY_BEHAVIOR_CHANNELLED) ~= 0
    local noTarget =     bit.band(behavior, DOTA_ABILITY_BEHAVIOR_NO_TARGET) ~= 0
    local treeTarget =   bit.band(targetType, DOTA_UNIT_TARGET_TREE) ~= 0

    if unit:IsStunned() and not unrestricted then
      Containers:DisplayError(playerID, "#dota_hud_error_unit_command_restricted")
      return
    end
    if unit:IsRooted() and rootDisables then
      Containers:DisplayError(playerID, "#dota_hud_error_ability_disabled_by_root")
      return
    end
    if noTarget and not channelled then
      item:PayGoldCost()
      item:PayManaCost()
      item:StartCooldown(item:GetCooldown(item:GetLevel()))
      item:OnSpellStart()
    else
      local abil = unit:FindAbilityByName("containers_lua_targeting")
      if treeTarget then
        unit:RemoveAbility("containers_lua_targeting")
        abil = unit:FindAbilityByName("containers_lua_targeting_tree")
      else
        unit:RemoveAbility("containers_lua_targeting_tree")
      end
      if not abil then
        -- no ability proxy found, add
        local abilSlot = -1
        for i=15,0,-1 do
          local ab = unit:GetAbilityByIndex(i)
          if not ab then
            abilSlot = i
            break
          end
        end

        if abilSlot == -1 then
          print("[containers.lua]  ERROR: 'containers_lua-targeting' ability not found for unit '" .. unit:GetUnitName() .. '" and all ability slots are full.')
          return
        end

        if treeTarget then
          unit:AddAbility("containers_lua_targeting_tree")
          abil = unit:FindAbilityByName("containers_lua_targeting_tree")
        else
          unit:AddAbility("containers_lua_targeting")
          abil = unit:FindAbilityByName("containers_lua_targeting")
        end
        abil:SetLevel(1)
      end

      abil:SetHidden(false)
      abil.proxyItem = item

      local aoe = nil
      local iname = item:GetAbilityName()
      if iname == "item_veil_of_discord" then
        aoe = 600
      elseif Containers.itemKV[iname] then
        aoe = Containers.itemKV[iname].AOERadius
      end

      CustomNetTables:SetTableValue("containers_lua", tostring(abil:GetEntityIndex()), {behavior=behavior, aoe=aoe, range=item:GetCastRange(), 
        targetType=targetType, targetTeam=item:GetAbilityTargetTeam(), targetFlags=item:GetAbilityTargetFlags(), 
        channelTime=item:GetChannelTime(), channelCost=item:GetChannelledManaCostPerSecond(item:GetLevel())})

      local player = PlayerResource:GetPlayer(playerID)
      if player then
        CustomGameEventManager:Send_ServerToPlayer(player, "cont_execute_proxy", {unit=unit:GetEntityIndex()})
      end
    end
  end

  function c:GetAllOpen()
    return self.opens
  end

  function c:IsOpen(pid)
    return self.opens[pid] ~= nil
  end

  function c:Open(pid)
    self.opens[pid] = true
    PlayerTables:AddPlayerSubscription(self.ptID, pid)

    if self:IsCloseOnOrder() then
      Containers.closeOnOrders[pid][self.id] = self
    end

    local player = PlayerResource:GetPlayer(pid)
    if player then  
      CustomGameEventManager:Send_ServerToPlayer(player, "cont_open_container", {id=self.id} )
    end
  end

  function c:Close(pid)
    if self.opens[pid] == nil then return end

    self.opens[pid] = nil
    if not self.subs[pid] then
      PlayerTables:RemovePlayerSubscription(self.ptID, pid)
    end

    if self:IsCloseOnOrder() then
      Containers.closeOnOrders[pid][self.id] = nil
    end

    local player = PlayerResource:GetPlayer(pid)
    if player then  
      CustomGameEventManager:Send_ServerToPlayer(player, "cont_close_container", {id=self.id} )
    end

    if self._OnEmptyAndClosed and next(self.opens)==nil and #self:GetAllItems() == 0 then
      self._OnEmptyAndClosed(self)
    end
  end

  function c:Delete(deleteContents)
    Containers:DeleteContainer(c, deleteContents)
  end

  function c:AddSubscription(pid)
    self.subs[pid] = true
    PlayerTables:AddPlayerSubscription(self.ptID, pid)
  end

  function c:RemoveSubscription(pid)
    self.subs[pid] = nil
    if not self.opens[pid] then
      PlayerTables:RemovePlayerSubscription(self.ptID, pid)
    end
  end

  function c:GetSubscriptions()
    return self.subs
  end

  function c:IsSubscribed(pid)
    return self.subs[pid] ~= nil
  end

  function c:SwapSlots(slot1, slot2, allowCombine)
    local item1 = self:GetItemInSlot(slot1)
    local item2 = self:GetItemInSlot(slot2)

    if item1 and item2 then
      return self:SwapItems(item1, item2, allowCombine)
    elseif item1 then
      local itemid = item1:GetEntityIndex()
      local itemname = item1:GetAbilityName()
      self.items[itemid] = slot2
      self.itemNames[itemname][itemid] = slot2

      PlayerTables:SetTableValue(self.ptID, "slot"..slot2, itemid)
      PlayerTables:DeleteTableKey(self.ptID, "slot"..slot1)
      return true
    elseif item2 then
      local itemid = item2:GetEntityIndex()
      local itemname = item2:GetAbilityName()
      self.items[itemid] = slot1
      self.itemNames[itemname][itemid] = slot1

      PlayerTables:SetTableValue(self.ptID, "slot"..slot1, itemid)
      PlayerTables:DeleteTableKey(self.ptID, "slot"..slot2)
      return true
    end
    return false
  end

  function c:SwapItems(item1, item2, allowCombine)
    item1 = GetItem(item1)
    item2 = GetItem(item2)

    local i1id = item1:GetEntityIndex()
    local i1name = item1:GetAbilityName()
    local i2id = item2:GetEntityIndex()
    local i2name = item2:GetAbilityName()

    local i1 = self.items[i1id]
    local i2 = self.items[i2id]

    if i1 and i2 then
      if allowCombine and i1name == i2name and item1:IsStackable() and item2:IsStackable() then
        self:RemoveItem(item1)
        item2:SetCurrentCharges(item2:GetCurrentCharges() + item1:GetCurrentCharges())
        item1:RemoveSelf()
        return true
      end
      self.items[i1id] = i2
      self.items[i2id] = i1
      self.itemNames[i1name][i1id] = i2
      self.itemNames[i2name][i2id] = i1

      PlayerTables:SetTableValues(self.ptID, {["slot"..i1]=i2id, ["slot"..i2]=i1id})
      return true
    end

    return false
  end

  function c:ContainsItem(item)
    item = GetItem(item)
    if not item then return false end
    return self.items[item:GetEntityIndex()] ~= nil
  end

  function c:GetSlotForItem(item)
    item = GetItem(item)
    return self.items[item:GetEntityIndex()]
  end

  function c:GetRowColumnForItem(item)
    item = GetItem(item)

    local itemid = item:GetEntityIndex()
    local slot = self.items[itemid]
    if not slot then
      return nil, nil
    end

    local size = self:GetSize()
    if slot > size then
      return nil, nil 
    end
    local rowStarts = PlayerTables:GetTableValue(self.ptID, "rowStarts")
    for row,start in ipairs(rowStarts) do
      if start > slot then
        local prev = row-1
        return prev, (slot - rowStarts[prev] + 1)
      end
    end

    local row = #rowStarts

    return row, (slot - rowStarts[row] + 1)
  end

  function c:GetAllItems()
    local items = {}
    for slot=1,self:GetSize() do
      local item = self:GetItemInSlot(slot)
      if item then
        table.insert(items, item)
      end
    end

    return items
  end

  function c:GetItemsByName(name)
    local nameTable = self.itemNames[name]
    local items = {}
    if not nameTable then
      return items
    end

    for id,slot in pairs(nameTable) do
      local item = GetItem(id)
      if item then
        table.insert(items, item)
      else
        nameTable[id] = nil
      end
    end
    return items
  end

  function c:GetItemInSlot(slot)
    local item = PlayerTables:GetTableValue(self.ptID, "slot" .. slot)
    if item then
      item = EntIndexToHScript(item)
      if item and not IsValidEntity(item) then
        PlayerTables:DeleteTableKey(self.ptID, "slot" .. slot)
        return nil
      elseif item and IsValidEntity(item) and item.IsItem and item:IsItem() then
        return item
      end
    end
      
    return nil
  end

  function c:GetItemInRowColumn(row, column)
    local rowStarts = PlayerTables:GetTableValue(self.ptID, "rowStarts")
    if not rowStarts[row] then
      return nil
    end

    local nextRowStart = rowStarts[row+1] or self:GetSize() + 1
    local slot = rowStarts[row] + column - 1

    if slot >= nextRowStart then
      return nil
    end

    return self:GetItemInSlot(slot)
  end

  function c:AddItem(item, slot, column)
    item = GetItem(item)
    if slot and type(slot) == "number" and column and type(column) == "number" then
      local rowStarts = PlayerTables:GetTableValue(self.ptID, "rowStarts")
      if not rowStarts[slot] then
        print("[containers.lua]  Request to add item in row " .. slot .. " -- row not found. ")
        return false
      end

      local nextRowStart = rowStarts[slot+1] or self:GetSize() + 1
      local newslot = rowStarts[slot] + column - 1

      if newslot >= nextRowStart then
        print("[containers.lua]  Request to add item in row " .. slot .. ", column " .. column .. " -- column exceeds row length. ")
        return false
      end

      slot = newslot
    end

    local findStack = slot == nil
    slot = slot or 1

    local size = self:GetSize()
    if slot > size then
      print("[containers.lua]  Request to add item in slot " .. slot .. " -- exceeding container size " .. size)
      return false
    end

    local itemid = item:GetEntityIndex()
    local itemname = item:GetAbilityName()

    if findStack and item:IsStackable() then
      local nameTable = self.itemNames[itemname]
      if nameTable then
        local lowestSlot = size+1
        local lowestItem = nil
        for itemid, nameslot in pairs(nameTable) do
          if nameslot < lowestSlot then
            local item = self:GetItemInSlot(nameslot)
            if item then
              lowestSlot = nameslot
              lowestItem = item
            else
              nameTable[itemid] = nil
            end
          end
        end

        if lowestItem and lowestItem:IsStackable() then
          lowestItem:SetCurrentCharges(lowestItem:GetCurrentCharges() + item:GetCurrentCharges())
          item:RemoveSelf()
          return true
        end
      end
    end

    -- check if the slot specified is stackable
    if not findStack and item:IsStackable() then
      local slotitem = self:GetItemInSlot(slot)

      if slotitem and itemname == slotitem:GetAbilityName() and slotitem:IsStackable() then
        slotitem:SetCurrentCharges(slotitem:GetCurrentCharges() + item:GetCurrentCharges())
        item:RemoveSelf()
        return true
      end
    end

    for i=slot,size do
      local slotitem = self:GetItemInSlot(i)
      if not slotitem then

        self.items[itemid] = i
        self.itemNames[itemname] = self.itemNames[itemname] or {}
        self.itemNames[itemname][itemid] = i

        if self.forceOwner then 
          item:SetOwner(self.forceOwner) 
        elseif self.forceOwner == false then
          item:SetOwner(nil)
        end
        if self.forcePurchaser then
          item:SetPurchaser(self.forcePurchaser) 
        elseif self.forceOwner == false then
          item:SetPurchaser(nil)
        end

        PlayerTables:SetTableValue(self.ptID, "slot" .. i, itemid)
        return true
      end
    end

    return false
  end

  function c:RemoveItem(item)
    item = GetItem(item)
    local slot = self.items[item:GetEntityIndex()]
    local nameTable = self.itemNames[item:GetAbilityName()]

    self.items[item:GetEntityIndex()] = nil
    nameTable[item:GetEntityIndex()] = nil

    PlayerTables:DeleteTableKey(self.ptID, "slot" .. slot)
  end

  function c:ClearSlot(slot)
    local item = self:GetItemInSlot(slot)
    if IsValidEntity(item) then
      self:RemoveItem(item)
    else
      PlayerTables:DeleteTableKey(self.ptID, "slot" .. slot)
    end
  end

  function c:GetContainerIndex()
    return self.id
  end

  function c:GetHeaderText()
    local headerText = PlayerTables:GetTableValue(self.ptID, "headerText")
    return headerText
  end

  function c:SetHeaderText(header)
    PlayerTables:SetTableValue(self.ptID, "headerText", header)
  end

  function c:GetSize()
    local size = PlayerTables:GetTableValue(self.ptID, "size")
    return size
  end

  function c:GetNumItems()
    return #c:GetAllItems()
  end

  function c:GetLayout()
    local layout = PlayerTables:GetTableValue(self.ptID, "layout")
    return layout
  end

  function c:SetLayout(layout, removeOnContract)
    local size = 0
    local rowStarts = {}

    for i,row in ipairs(layout) do
      table.insert(rowStarts, size+1)
      size = size + row
    end

    local oldSize = c:GetSize()
    local changes = {}

    if removeOnContract and size < oldSize then
      local deletions = {}
      for i=size+1,oldSize do
        local item = self:GetItemInSlot(i)
        if item then
          local itemid = item:GetEntityIndex()
          local itemname = item:GetAbilityName()
          local nameTable = self.itemNames[item:GetAbilityName()]

          self.items[item:GetEntityIndex()] = nil
          nameTable[item:GetEntityIndex()] = nil

          table.insert(deletions, "slot"..i)
        end
      end

      PlayerTables:DeleteTableKeys(self.ptID, deletions)
    end

    changes.layout = layout
    changes.size = size
    changes.rowStarts = rowStarts

    PlayerTables:SetTableValues(self.ptID, changes)
  end

  function c:GetRange()
    return self.range
  end

  function c:SetRange(range)
    self.range = range
    --[[if range then
      PlayerTables:SetTableValue(self.ptID, "range", range)
    else
      PlayerTables:DeleteTableKey(self.ptID, "range")
    end]]
  end

  function c:AddSkin(skin)
    local skins = PlayerTables:GetTableValue(self.ptID, "skins")
    skins[skin] = true

    PlayerTables:SetTableValue(self.ptID, "skins", skins)
  end

  function c:RemoveSkin(skin)
    local skins = PlayerTables:GetTableValue(self.ptID, "skins")
    skins[skin] = nil

    PlayerTables:SetTableValue(self.ptID, "skins", skins)
  end

  function c:GetSkins()
    local skins = PlayerTables:GetTableValue(self.ptID, "skins")
    return skins
  end

  function c:HasSkin(skin)
    local skins = PlayerTables:GetTableValue(self.ptID, "skins")
    return skins[skin] ~= nil
  end

  function c:SetButton(number, name)
    local buttons = PlayerTables:GetTableValue(self.ptID, "buttons")
    buttons[number] = name

    PlayerTables:SetTableValue(self.ptID, "buttons", buttons)
  end

  function c:RemoveButton(number)
    local buttons = PlayerTables:GetTableValue(self.ptID, "buttons")
    buttons[number] = nil

    PlayerTables:SetTableValue(self.ptID, "buttons", buttons)
  end

  function c:GetButtons()
    local buttons = PlayerTables:GetTableValue(self.ptID, "buttons")
    return buttons
  end

  function c:GetButtonName(number)
    local buttons = PlayerTables:GetTableValue(self.ptID, "buttons")
    return buttons[number]
  end

  function c:GetEntity()
    local entity = PlayerTables:GetTableValue(self.ptID, "entity")
    if entity then 
      return EntIndexToHScript(entity) 
    end
    return nil
  end

  function c:SetEntity(entity)
    if entity and type(entity) == "number" then
      PlayerTables:SetTableValue(self.ptID, "entity", entity)
    elseif entity and entity.GetEntityIndex then
      PlayerTables:SetTableValue(self.ptID, "entity", entity:GetEntityIndex())
    elseif entity == nil then
      PlayerTables:DeleteTableValue(self.ptID, "entity")
    end
  end

  function c:GetCanDragFromPlayers()
    return self.canDragFrom
  end

  function c:CanDragFrom(pid)
    return self.canDragFrom[pid] ~= false
  end

  function c:SetCanDragFrom(pid, canDrag)
    self.canDragFrom[pid] = canDrag
  end

  function c:GetCanDragToPlayers()
    return self.canDragTo
  end

  function c:CanDragTo(pid)
    return self.canDragTo[pid] ~= false
  end

  function c:SetCanDragTo(pid, canDrag)
    self.canDragTo[pid] = canDrag
  end

  function c:GetCanDragWithinPlayers()
    return self.canDragWithin
  end

  function c:CanDragWithin(pid)
    return self.canDragWithin[pid] ~= false
  end

  function c:SetCanDragWithin(pid, canDrag)
    self.canDragWithin[pid] = canDrag
  end

  function c:IsDraggable()
    return PlayerTables:GetTableValue(self.ptID, "draggable")
  end

  function c:SetDraggable(drag)
    PlayerTables:SetTableValue(self.ptID, "draggable", drag)
  end

  function c:GetForceOwner()
    return self.forceOwner
  end

  function c:GetForcePurchaser()
    return self.ForcePurchaser
  end

  function c:SetForceOwner(owner)
    self.forceOwner = owner
  end

  function c:SetForcePurchaser(purchaser)
    self.ForcePurchaser = purchaser
  end

  function c:IsCloseOnOrder()
    return self.closeOnOrder
  end

  function c:SetCloseOnOrder(close)
    if close then
      for pid, _ in pairs(self.opens) do
        Containers.closeOnOrders[pid][self.id] = self
      end
    else
      for pid,v in pairs(Containers.closeOnOrders) do
        v[self.id] = nil
      end
    end
    self.closeOnOrder = close
  end

  function c:OnLeftClick(fun)
    if fun == nil then
      PlayerTables:DeleteTableKey(self.ptID, "OnLeftClick")
    elseif type(fun) == "function" then
      PlayerTables:SetTableValue(self.ptID, "OnLeftClick", true)
    else
      PlayerTables:SetTableValue(self.ptID, "OnLeftClick", fun)
    end

    self._OnLeftClick = fun
  end

  function c:OnRightClick(fun)
    if fun == nil then
      PlayerTables:DeleteTableKey(self.ptID, "OnRightClick")
    elseif type(fun) == "function" then
      PlayerTables:SetTableValue(self.ptID, "OnRightClick", true)
    else
      PlayerTables:SetTableValue(self.ptID, "OnRightClick", fun)
    end

    self._OnRightClick = fun
  end

  function c:OnDragTo(fun)
    self._OnDragTo = fun
  end

  function c:OnDragWithin(fun)
    self._OnDragWithin = fun
  end

  function c:OnDragFrom(fun)
    if fun == nil then
      PlayerTables:DeleteTableKey(self.ptID, "OnDragFrom")
    elseif type(fun) == "function" then
      PlayerTables:SetTableValue(self.ptID, "OnDragFrom", true)
    else
      PlayerTables:SetTableValue(self.ptID, "OnDragFrom", fun)
    end

    self._OnDragFrom = fun
  end

  function c:OnDragWorld(fun)
    if fun == nil then
      PlayerTables:DeleteTableKey(self.ptID, "OnDragWorld")
    elseif type(fun) == "function" then
      PlayerTables:SetTableValue(self.ptID, "OnDragWorld", true)
    else
      PlayerTables:SetTableValue(self.ptID, "OnDragWorld", fun)
    end

    self._OnDragWorld = fun
  end

  function c:OnCloseClicked(fun)
    if fun == nil then
      PlayerTables:DeleteTableKey(self.ptID, "OnCloseClicked")
    elseif type(fun) == "function" then
      PlayerTables:SetTableValue(self.ptID, "OnCloseClicked", true)
    else
      PlayerTables:SetTableValue(self.ptID, "OnCloseClicked", fun)
    end

    self._OnCloseClicked = fun
  end

  function c:OnButtonPressed(fun)
    if fun == nil then
      PlayerTables:DeleteTableKey(self.ptID, "OnButtonPressed")
    elseif type(fun) == "function" then
      PlayerTables:SetTableValue(self.ptID, "OnButtonPressed", true)
    else
      PlayerTables:SetTableValue(self.ptID, "OnButtonPressed", fun)
    end

    self._OnButtonPressed = fun
  end

  function c:OnEmptyAndClosed(fun)
    self._OnEmptyAndClosed = fun
  end


  self.containers[self.nextID] = c
  self.nextID = self.nextID + 1
  return c
end

function Containers:DeleteContainer(c, deleteContents)
  if deleteContents ~= false then
    local items = c:GetAllItems()
    for _, item in ipairs(items) do
      item:RemoveSelf()
    end
  end

  PlayerTables:DeleteTable(c.ptID)
  self.containers[c.id] = nil

  CustomGameEventManager:Send_ServerToAllClients("cont_delete_container", {id=c.id} )

  for k,v in pairs(c) do
    c[k] = nil
  end
end

function IsValidContainer(c)
  if c and c.GetAllOpen then 
    return true 
  else 
    return false 
  end
end

if not Containers.containers then Containers:start() end