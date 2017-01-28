function RadarTelegatherInit(keys)
    local caster = keys.caster
    local target = keys.target
    local ability = keys.ability
    local duration  = ability:GetSpecialValueFor("duration")
    if target:GetUnitName() == "npc_building_fire_basic" or target:GetUnitName() == "npc_building_fire_mage" then
        keys.caster.targetFire = target
    else
        SendErrorMessage(caster:GetPlayerOwnerID(),"#invalid_telegatherer_target")
        caster:Interrupt()
        ability:StartCooldown(1.0)
    end
end

function RadarTelegather(keys)
    local caster = keys.caster
    local target = keys.target
    local ability = keys.ability
    local duration  = ability:GetSpecialValueFor("duration")
    if target:GetUnitName() == "npc_building_fire_basic" or target:GetUnitName() == "npc_building_fire_mage" then
        keys.caster.targetFire = target
        ability:ApplyDataDrivenModifier(caster, caster, "modifier_telegather", {duration = duration})
        caster:EmitSound("Hero_ShadowShaman.Shackles.Cast")
    else
        SendErrorMessage(caster:GetPlayerOwnerID(),"#invalid_telegatherer_target")
        caster:Interrupt()
    end
end


function HerbRadarTelegather(keys)
    local caster = keys.caster
    local target = keys.target
    local ability = keys.ability
    local duration  = ability:GetSpecialValueFor("duration")
    if target:GetUnitName() == "npc_building_fire_basic" or target:GetUnitName() == "npc_building_fire_mage" then
        keys.caster.targetFire = target
        ability:ApplyDataDrivenModifier(caster, caster, "modifier_herbtelegather", {duration = duration})
        caster:EmitSound("Hero_ShadowShaman.Shackles.Cast")
    else
        SendErrorMessage(caster:GetPlayerOwnerID(),"#invalid_telegatherer_target")
        caster:Interrupt()
    end
end

-- ItemRadar, RadarManip
-- ToggleOn RadarManip:         ItemRadar, RadarManip, Ability1, 2, 3, 4.
function ToggleOnRadar( event )
    local caster = event.caster
    local ability = event.ability
    local level = ability:GetLevel()

    -- Toggle off the secondary subclass ability
    local advRadarAbility = caster:FindAbilityByName("ability_gatherer_advanced_radarmanipulations")
    if advRadarAbility then
        ToggleOffRadar(event)
    end

    local radarSkillTable = {
        [1] = {"ability_gatherer_findmushroomstickortinder", "ability_gatherer_findhide" },
        [2] = {"ability_gatherer_findmushroomstickortinder", "ability_gatherer_findhide", "ability_gatherer_findclayballcookedmeatorbone"},
        [3] = {"ability_gatherer_findmushroomstickortinder", "ability_gatherer_findhide", "ability_gatherer_findclayballcookedmeatorbone", "ability_gatherer_findmanacrystalorstone"},
    }

    local abilityTable = radarSkillTable[level]
    local currentSlot = 3

    for k,abilityName in pairs(abilityTable) do
        local swapAbility = GetAbilityOnVisibleSlot(caster, currentSlot)

        -- If there is already an ability on slot 4~6, swap it
        if swapAbility then
            caster:SwapAbilities(swapAbility:GetAbilityName(), abilityName, false, true)
        end

        -- All the _find abilities should already be added as hidden on the gatherer skill list
        local ability = caster:FindAbilityByName(abilityName)
        if ability then
            ability:SetHidden(false)
            ability:SetLevel(1)
            currentSlot = currentSlot+1
        end
    end

end

-- Turns the layout back to normal
function ToggleOffRadar(event)
    local caster = event.caster
    local abilityTable = {
        ["ability_gatherer_findmushroomstickortinder"]="",
        ["ability_gatherer_findhide"]="",
        ["ability_gatherer_findclayballcookedmeatorbone"]="",
        ["ability_gatherer_findmanacrystalorstone"]="",
        ["ability_gatherer_findflint"]="",
        ["ability_gatherer_findmagic"]="",
        ["ability_gatherer_findherbriver"]="",
        ["ability_gatherer_findherbmushroom"]="",
        ["ability_gatherer_findherbspecial"]="",
        ["ability_gatherer_findthistles"]=""
    }

    for i=0,15 do
        local ability = caster:GetAbilityByIndex(i)
        if ability then
            local abilityName = ability:GetAbilityName()
            if abilityTable[abilityName] then
                ability:SetHidden(true)
                ability:SetLevel(0)
            elseif not IsCastableWhileHidden(abilityName) then
                ability:SetHidden(false)
            end
        end        
    end
end

-- ItemRadar, RadarManip, AdvancedRadarManip
-- ToggleOnAdvancedRadarManip:  ItemRadar, RadarManip, AdvancedRadarManip, Ability1, 2
function ToggleOnAdvancedRadar( event )
    local caster = event.caster
    local ability = event.ability
    local level = ability:GetLevel()

    local abilityTable = { "ability_gatherer_findflint", "ability_gatherer_findmagic" }
    local currentSlot = 4

    for k,abilityName in pairs(abilityTable) do
        local swapAbility = GetAbilityOnVisibleSlot(caster, currentSlot)

        -- If there is already an ability on slot 4~5, swap it
        if swapAbility then
            caster:SwapAbilities(swapAbility:GetAbilityName(), abilityName, false, true)
        end

        -- All the _find abilities should already be added as hidden on the gatherer skill list
        local ability = caster:FindAbilityByName(abilityName)
        if ability then
            ability:SetHidden(false)
            ability:SetLevel(1)
            currentSlot = currentSlot+1
        end
    end

    -- Force the Radar Advanced into slot 3
    local swapAbility = GetAbilityOnVisibleSlot(caster, 3)
    caster:SwapAbilities(swapAbility:GetAbilityName(), "ability_gatherer_advanced_radarmanipulations", false, true)

end



function ToggleOnHerbRadar( event )
    local caster = event.caster
    local ability = event.ability
    local level = ability:GetLevel()

    local abilityTable = { "ability_gatherer_findherbriver", "ability_gatherer_findherbbutsu", "ability_gatherer_findherbmushroom", "ability_gatherer_findherbspecial", "ability_gatherer_findthistles" }
    local currentSlot = 2

    for k,abilityName in pairs(abilityTable) do
        local swapAbility = GetAbilityOnVisibleSlot(caster, currentSlot)

        -- If there is already an ability on slot 4~5, swap it
        if swapAbility then
            caster:SwapAbilities(swapAbility:GetAbilityName(), abilityName, false, true)
        end

        -- All the _find abilities should already be added as hidden on the gatherer skill list
        local ability = caster:FindAbilityByName(abilityName)
        if ability then
            ability:SetHidden(false)
            ability:SetLevel(1)
            currentSlot = currentSlot+1
        end
    end

    -- Force the Radar Advanced into slot 3
    local swapAbility = GetAbilityOnVisibleSlot(caster, 3)
    caster:SwapAbilities(swapAbility:GetAbilityName(), "ability_gatherer_findherb", false, true)

end