-- Player is put to sleep
function ITT:Sleep(event)
    local playerID = event.PlayerID
    local hero = PlayerResource:GetSelectedHeroEntity(playerID)

    if hero then
        local abilityName = "sleep_outside"
        local ability = hero:FindAbilityByName(abilityName)
        if not ability then
            ability = TeachAbility(hero, abilityName, 1)
        end
        if ability:IsFullyCastable() then
            hero:CastAbilityNoTarget(ability, -1)
        end
    end
end

-- Player eats one raw meat
function ITT:EatMeat(event)
    local playerID = event.PlayerID
    local hero = PlayerResource:GetSelectedHeroEntity(playerID)

    if hero then
        local meatStacks = hero:GetModifierStackCount("modifier_meat_passive", nil)
        if meatStacks > 0 then
            local abilityName = "eat_meat"
            local ability = hero:FindAbilityByName(abilityName)
            if not ability then
                ability = TeachAbility(hero, abilityName)
            end
            if ability:IsFullyCastable() and not ability:IsChanneling() then
                hero:CastAbilityNoTarget(ability, -1)
                hero:SetModifierStackCount("modifier_meat_passive", nil, meatStacks-1)
            else
                SendErrorMessage(playerID, "#eat_raw_meat_channeling_is_in_progress")
            end
        else
            print("No Meat to eat!")
            SendErrorMessage(playerID, "#error_no_meat_to_eat")
        end
    end
end

-- Player drops one raw meat
function ITT:DropMeat(event)
    local playerID = event.PlayerID
    local hero = PlayerResource:GetSelectedHeroEntity(playerID)

    if hero then
        local meatStacks = hero:GetModifierStackCount("modifier_meat_passive", nil)
        if meatStacks > 0 and hero ~= nil then
            local newItem = CreateItem("item_meat_raw", nil, nil)
            CreateItemOnPositionSync(hero:GetOrigin() + RandomVector(RandomInt(50,100)), newItem)

            hero:SetModifierStackCount("modifier_meat_passive", nil, meatStacks - 1)
        else
            SendErrorMessage(playerID, "#error_no_meat_to_drop")
        end
    end
end

-- Player drops all raw meat
function ITT:DropAllMeat(event)
    local playerID = event.PlayerID
    local hero = PlayerResource:GetSelectedHeroEntity(playerID)

    if hero then
        local meatStacks = hero:GetModifierStackCount("modifier_meat_passive", nil)
        if meatStacks > 0 and hero ~= nil then
            for i = 1,meatStacks do
                local newItem = CreateItem("item_meat_raw", nil, nil)
                CreateItemOnPositionSync(hero:GetOrigin() + RandomVector(RandomInt(50,100)), newItem)

                hero:SetModifierStackCount("modifier_meat_passive", nil, 0)
            end
        else
            SendErrorMessage(playerID, "#error_no_meat_to_drop")
        end
    end
end

-- Player panics!
function ITT:Panic(event)
    local playerID = event.PlayerID
    local hero = PlayerResource:GetSelectedHeroEntity(playerID)

    if hero then
        local abilityName = "panic"
        local ability = hero:FindAbilityByName(abilityName)
        if not ability then
            ability = TeachAbility(hero, abilityName)
        end
        if ability:IsFullyCastable() then
            hero:CastAbilityNoTarget(ability, -1)
        end
        if hero:GetMana() < ability:GetManaCost(1) then
            SendErrorMessage(playerID, "#error_no_mana")
        end
    end
end

function ITT:DropAllItems(event)
    local playerID = event.PlayerID
    local hero = PlayerResource:GetSelectedHeroEntity(playerID)

    if hero then
        local abilityName = "ability_drop_items"
        local ability = hero:FindAbilityByName(abilityName)
        if not ability then
            ability = TeachAbility(hero, abilityName)
        end

        hero:CastAbilityImmediately(ability, playerID)
    end
end
