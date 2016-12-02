-- Modifier living clay caster starts
modifier_living_clay_caster = class({})
-- Modifier living clay caster ends

LinkLuaModifier("modifier_living_clay_caster", "items/living_clay.lua", LUA_MODIFIER_MOTION_NONE)

function CheckPosition( event )
	local caster = event.caster
	local point = event.target_points[1]
	local distance = (point - caster:GetAbsOrigin()):Length2D()
    if not BuildingHelper:ValidPosition(2, point, event) or distance > 500 then
        caster:Interrupt()
        SendErrorMessage(caster:GetPlayerOwnerID(), "#error_invalid_build_position")
    end
end

function LivingClayCheckStacks(keys)
    local caster = keys.caster
    local target = keys.target
    local ability = keys.ability
    local curstacks = target:GetModifierStackCount("modifier_priest_painkillerbalm", caster)
	print(target,caster,curstacks)
	
	target:SetModifierStackCount("modifier_priest_painkillerbalm", nil, curstacks -1)
    if string.find(target:GetUnitName(), "npc_dota_hero_dazzle") then
        SendErrorMessage(caster:GetPlayerOwnerID(),"#invalid_priest_target")
        caster:Interrupt()
        ability:StartCooldown(1.0)
    else
    print("else")
    end
end


function MakeClayExplosion(keys)
    local caster = keys.caster
    local origin =  keys.target_points[1]
    local dieRoll = RandomInt(0, 3)
    for i=1,dieRoll do
        local pos_launch = origin + RandomVector(RandomInt(1,200))
        local item = CreateItem("item_clay_living", nil, nil)
        local drop = CreateItemOnPositionSync( origin, item )
        item:LaunchLoot(false, 200, 0.75, pos_launch)
    end
		print("Die roll for clay explosion: "..dieRoll)
end

function PlaceClay( keys )
	local caster = keys.caster
	local target_point = keys.target_points[1]
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1

	local placeDistance = (target_point - caster:GetAbsOrigin()):Length2D()
	if CheckPosition(keys) then
		caster:Interrupt()
		SendErrorMessage(caster:GetPlayerOwnerID(), "#error_invalid_build_position")
		return
	end

	-- Initialize the count and table
	caster.living_clay_count = caster.living_clay_count or 0
	caster.living_clay_table = caster.living_clay_table or {}

	-- Modifiers
	local modifier_living_clay = keys.modifier_living_clay
	local modifier_tracker = keys.modifier_tracker
	local modifier_caster = keys.modifier_caster

	-- Ability variables
	local activation_time = ability:GetLevelSpecialValueFor("activation_time", ability_level)
	local max_mines = ability:GetLevelSpecialValueFor("max_clay", ability_level)
	local fade_time = ability:GetLevelSpecialValueFor("fade_time", ability_level)
	-- Create the land mine and apply the land mine modifier
	local living_clay = CreateUnitByName("npc_clay_living", target_point, false, nil, nil, caster:GetTeamNumber())


	-- Update the count and table
	caster.living_clay_count = caster.living_clay_count + 1
	table.insert(caster.living_clay_table, living_clay)
	-- If we exceeded the maximum number of mines then kill the oldest one
	if caster.living_clay_count > max_mines then
		for K,V in pairs(caster.living_clay_table) do
			if V:IsNull() then
				table.remove(caster.living_clay_table, K)
			else
				KillLivingClay({caster = caster, living_clay = V})
				break
			end
		end
	end
	-- Increase caster stack count of the caster modifier and add it to the caster if it doesnt exist
	if not caster:HasModifier(modifier_caster) then
		ApplyModifier(caster,modifier_caster)
	end
	caster:SetModifierStackCount(modifier_caster, caster, caster.living_clay_count)

	local trackingInfo = {}
	trackingInfo.livingClay = living_clay
	trackingInfo.caster = keys.caster
	trackingInfo.trigger_radius = ability:GetLevelSpecialValueFor("radius", ability_level)
	trackingInfo.explode_delay = ability:GetLevelSpecialValueFor("explode_delay", ability_level)

	-- Apply the tracker after the activation time

	Timers:CreateTimer(DoUniqueString("living_clay_tracker"),{callback = LivingClayTracker, endTime = activation_time}, trackingInfo)
	-- Apply the invisibility after the fade time

	Timers:CreateTimer(fade_time, function()
		living_clay:AddNewModifier(living_clay,nil,"modifier_invisible",{duration = -1, hidden = true})
	end)
	ability:ApplyDataDrivenModifier(caster, living_clay, modifier_living_clay, {})
end

function WardTheArea( keys )
	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1

	-- Modifiers
	local modifier_living_clay = keys.modifier_living_clay
	local modifier_tracker = keys.modifier_tracker
	local modifier_caster = keys.modifier_caster

	-- Ability variables
	local activation_time = ability:GetLevelSpecialValueFor("explode_delay", ability_level)
	local expiration_time = ability:GetLevelSpecialValueFor("lifetime", ability_level)
	local num_wards = ability:GetLevelSpecialValueFor("wards", ability_level)
	local fade_time = ability:GetLevelSpecialValueFor("fade_time", ability_level)
	local aoe = ability:GetLevelSpecialValueFor("aoe", ability_level)

	--Generate random locations
	for i = 1, num_wards do
		local rand_vector = RandomVector(RandomFloat(0,aoe))
		local rand_point = caster:GetOrigin() + rand_vector
		print("random point for clay x:" .. rand_point.x .. " y:" .. rand_point.y .. " z:" .. rand_point.z)

		-- Create the land mine and apply the land mine modifier
		local living_clay = CreateUnitByName("npc_clay_living", rand_point, true, nil, nil, caster:GetTeamNumber())

		local trackingInfo = {}
		trackingInfo.livingClay = living_clay
		trackingInfo.caster = caster
		trackingInfo.trigger_radius = ability:GetLevelSpecialValueFor("radius", ability_level)
		trackingInfo.explode_delay = ability:GetLevelSpecialValueFor("explode_delay", ability_level)
		trackingInfo.expiration_time = GameRules:GetGameTime() + expiration_time

		-- Apply the tracker after the activation time
		Timers:CreateTimer(DoUniqueString("living_clay_tracker"),{callback = LivingClayTracker, endTime = activation_time}, trackingInfo)
		-- Apply the invisibility after the fade time

		Timers:CreateTimer(fade_time, function()
			living_clay:AddNewModifier(living_clay,nil,"modifier_invisible",{duration = -1, hidden = true})
		end)
		ability:ApplyDataDrivenModifier(caster, living_clay, "modifier_living_clay", {})
	end

end

--[[Author: Pizzalol
	Date: 24.03.2015.
	Stop tracking the mine and create vision on the mine area]]
function LivingClayDeath( livingClayInfo )
	local caster = livingClayInfo.caster
	local unit = livingClayInfo.livingClay
	if caster.living_clay_table then
		for i = 1, #caster.living_clay_table do
			if caster.living_clay_table[i] == unit then
				table.remove(caster.living_clay_table, i)
				caster.living_clay_count = caster.living_clay_count - 1
				break
			end
		end
		-- Update the stack count
		caster:SetModifierStackCount("modifier_living_clay_caster", caster, caster.living_clay_count)
		if caster.living_clay_count < 1 then
			caster:RemoveModifierByNameAndCaster("modifier_living_clay_caster", caster)
		end
	end
end

--[[Author: Pizzalol
	Date: 24.03.2015.
	Tracks if any enemy units are within the mine radius]]
function LivingClayTracker( trackingInfo )
	local livingClay = trackingInfo.livingClay

	if not livingClay:IsAlive() then
		return nil
	end

	--check if the mine has an expiration time
	if trackingInfo.expiration_time then
		if GameRules:GetGameTime() >= trackingInfo.expiration_time then
			KillLivingClay(trackingInfo)
			return nil
		end
	end

	-- Find the valid units in the trigger radius
	local trigger_radius = trackingInfo.trigger_radius
	local target_team = DOTA_UNIT_TARGET_TEAM_ENEMY
	local target_types = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_BUILDING
	local target_flags = DOTA_UNIT_TARGET_FLAG_NONE
	local units = FindUnitsInRadius(livingClay:GetTeamNumber(), livingClay:GetAbsOrigin(), nil, trigger_radius, target_team, target_types, target_flags, FIND_CLOSEST, false)

	local killMine = 0
	if #units > 0 then
		if livingClay:HasModifier("modifier_invisible") then
			livingClay:RemoveModifierByName("modifier_invisible")
		end
		for _,unit in pairs(units) do
			if unit:GetUnitName() ~= "npc_creep_hawk" then
				local damageTable = {
					victim = unit,
					attacker = trackingInfo.caster,
					damage = 10,
					damage_type = DAMAGE_TYPE_MAGICAL,
				}
				ApplyDamage(damageTable)
				killMine = 1
			end
		end
		if killMine == 1 then
			KillLivingClay(trackingInfo)
		end
	end
	return 1.0
end

function KillLivingClay(trackingInfo)
	local livingClay = trackingInfo.livingClay
	ApplyModifier(livingClay,"modifier_living_clay_explode_particle_effect")
	ApplyModifier(livingClay,"modifier_living_clay_explode_sound_effect")
	Timers:CreateTimer(0.5, function()
		LivingClayDeath(trackingInfo)
		if livingClay:IsAlive() then
			livingClay:ForceKill(true)
		end
	end)
end
