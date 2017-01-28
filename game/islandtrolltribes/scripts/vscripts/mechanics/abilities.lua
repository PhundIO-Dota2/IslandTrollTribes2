------------------------------------------------
--              Ability functions             --
------------------------------------------------

-- Global variables
HUNTER = "npc_dota_hero_huskar"
PRIEST = "npc_dota_hero_dazzle"
MAGE = "npc_dota_hero_witch_doctor"
BEASTMASTER = "npc_dota_hero_lycan"
THIEF = "npc_dota_hero_riki"
SCOUT = "npc_dota_hero_lion"
GATHERER = "npc_dota_hero_shadow_shaman"

function IsCastableWhileHidden( abilityName )
    return GameRules.AbilityKV[abilityName] and GameRules.AbilityKV[abilityName]["IsCastableWhileHidden"]
end

function SetAbilityVisibility(unit, abilityName, visibility)
    local ability = unit:FindAbilityByName(abilityName)
    local hidden = (visibility == false)
    if ability ~= nil and unit ~= nil then
        ability:SetHidden(hidden)
    end
end

function TeachAbility( unit, ability_name, level )
    if not level then level = 1 end
    if unit:HasAbility(ability_name) then
        unit:FindAbilityByName(ability_name):SetLevel(tonumber(level))
        return
    end

    if GameRules.AbilityKV[ability_name] then
        unit:AddAbility(ability_name)
        local ability = unit:FindAbilityByName(ability_name)
        if ability then
            ability:SetLevel(tonumber(level))
            return ability
        end
    else
        print("ERROR: ability "..ability_name.." is not defined")
        return nil
    end
end

function PrintAbilities( unit )
    print("List of Abilities in "..unit:GetUnitName())
    for i=0,16 do
        local ability = unit:GetAbilityByIndex(i)
        if ability then
            local output = i.." - "..ability:GetAbilityName()
            if ability:IsHidden() then output = output.." (Hidden)" end
            print(output)
        end
    end
end

function HideAllAbilities(unit)
    for i=0,16 do
        local ability = unit:GetAbilityByIndex(i)
        if ability then
            ability:SetHidden(true)
        end
    end
end

function ReorderAbilities(caster, spellbook)
    Timers:CreateTimer({    -- Needs to happen on the next frame.
        callback = function()
            for i,ability_name in pairs(spellbook) do
                local ability_in_slot = GetAbilityOnVisibleSlot(caster, tonumber(i))
                if ability_in_slot then
                    local name = ability_in_slot:GetAbilityName()
                    if name ~= ability_name then
                        caster:SwapAbilities(name, ability_name, true, true)
                    end
                end
            end
        end
    })
end

function ShowTheSpellBook(caster, spellbook)
    for i,spell in pairs(spellbook) do
        local ability = caster:FindAbilityByName(spell)
        if ability then
            if ability:IsHidden() then
                ability:SetHidden(false)
            end
        end
    end
    ReorderAbilities(caster, spellbook)
end

function GetAbilityOnVisibleSlot( unit, slot )
    local visible_slot = 0
    for i=0,15 do
        local ability = unit:GetAbilityByIndex(i)
        if ability and not ability:IsHidden() then
            visible_slot = visible_slot + 1
            if visible_slot == slot then
                return ability
            end
        end
    end
end

function ClearAbilities( unit )
    for i=0,16 do
        local ability = unit:GetAbilityByIndex(i)
        if ability then
            unit:RemoveAbility(ability:GetAbilityName())
        end
    end
end

function GetAllAbilities( unit )
    local abilityList = {}
    for i=0,16 do
        local ability = unit:GetAbilityByIndex(i)
        if ability then
            table.insert(abilityList,ability)
        end
    end
    return abilityList
end

function EnableAllAbilities( unit, visibility )
    for i=0,16 do
        local ability = unit:GetAbilityByIndex(i)
        if ability then
--            SetAbilityVisibility(unit,ability:GetAbilityName(),visibility)
            ability:SetActivated(visibility)
        end
    end
end

function DropAllItems(keys)
    local caster = keys.caster
    if caster:HasInventory() then
        for itemSlot = 0, 5, 1 do
            local Item = caster:GetItemInSlot( itemSlot )
            if Item ~= nil then
                local itemCharges = Item:GetCurrentCharges()
                local newItem = CreateItem(Item:GetName(), nil, nil)
                newItem:SetCurrentCharges(itemCharges)
                CreateItemOnPositionSync(caster:GetOrigin() + RandomVector(RandomInt(100,160)), newItem)
                caster:RemoveItem(Item)
            end
        end
    end
end

function DropAllItemsTool(keys)
    local caster = keys.caster
    local itemName = item:GetName()--get the item's name
    if caster:HasInventory() then
        for itemSlot = 0, 5, 1 do
            local Item = caster:GetItemInSlot( itemSlot )
            if Item ~= nil and itemName ~= "item_slot_locked" then
                local itemCharges = Item:GetCurrentCharges()
                local newItem = CreateItem(Item:GetName(), nil, nil)
                newItem:SetCurrentCharges(itemCharges)
                CreateItemOnPositionSync(caster:GetOrigin() + RandomVector(RandomInt(100,160)), newItem)
                caster:RemoveItem(Item)
            end
        end
    end
end

function callModApplier( caster, modName, abilityLevel)
    if abilityLevel == nil then
        abilityLevel = 1
    end
    local applier = modName .. "_applier"
    local ab = caster:FindAbilityByName(applier)
    if ab == nil then
        caster:AddAbility(applier)
        ab = caster:FindAbilityByName( applier )
        ab:SetLevel(abilityLevel)
        print("trying to cast ability ", applier, "level", ab:GetLevel())
    end
    caster:CastAbilityNoTarget(ab, -1)
    caster:RemoveAbility(applier)
end

function ToggleAbility(keys)
    local caster = keys.caster

    if caster:HasAbility(keys.Ability) then
        local ability = caster:FindAbilityByName(keys.Ability)
        if ability:IsActivated() == true then
            ability:SetActivated(false)
        else
            ability:SetActivated(true)
        end
    end
end

function ToggleOn(ability)
    if ability:GetToggleState() == false then
        ability:ToggleAbility()
    end
end

function ToggleOff(ability)
    if ability:GetToggleState() == true then
        ability:ToggleAbility()
    end
end

function SetAbilityVisibility(unit, abilityName, visibility)
    local ability = unit:FindAbilityByName(abilityName)
    local hidden = (visibility == false)
    if ability ~= nil and unit ~= nil then
        ability:SetHidden(hidden)
    end
end

function KillDummyUnit(keys)
    local unitName = keys.UnitName
    local caster = keys.caster
    local teamnumber = caster:GetTeamNumber()
    local casterPosition = caster:GetAbsOrigin()

    local units = FindUnitsInRadius(teamnumber,
                                    casterPosition,
                                    nil,
                                    0,
                                    DOTA_UNIT_TARGET_TEAM_FRIENDLY,
                                    DOTA_UNIT_TARGET_ALL,
                                    DOTA_UNIT_TARGET_FLAG_NONE,
                                    FIND_ANY_ORDER,
                                    false)

    for _,unit in pairs(units) do
        if unit:GetName() == unitName then
            unit:ForceKill(true)
        end
    end
end
