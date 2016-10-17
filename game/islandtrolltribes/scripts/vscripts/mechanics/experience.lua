XP_RANGE = 1200
XP_MULTIPLIER = 3.0
XP_BOUNTY_TABLE = {
    1.5, --1
    40, --2 +15
    60, --3 +20
    85, --4 +25
    115,--5 +30
    150,--6 +35
    190,--7 +40
    235,--8 +45
    285,--9 +50
    340,--10 +55
    400,--11 +60
    465,--12 +65
    535,--13 +70
    610,--14 +75
    690,--15 +80
    775,--16 +85
    865,--17 +90
    960,--18 +95
    1060,--19 +100
    1165,--20 +105
}
XP_BOUNTY_TABLE[0] = 1

function CDOTA_BaseNPC_Creature:SplitExperienceBounty(teamID)
    local killed = self
    local level = killed:GetLevel()
    local killedTeam = killed:GetTeamNumber()
    local XPGain = XP_BOUNTY_TABLE[level] * XP_MULTIPLIER

    local heroesNearby = FindUnitsInRadius(killed:GetTeamNumber(), killed:GetAbsOrigin(), nil, XP_RANGE, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)
    local validHeroes = {}
    for _,hero in pairs(heroesNearby) do
        if hero:IsRealHero() and hero:GetTeamNumber() ~= killedTeam then
            -- If the hero in range was part of who did the last hit, always give XP
            if hero:GetTeamNumber() == teamID then
                table.insert(validHeroes, hero)

            -- Otherwise, they need to have done damage to the killed creep
            elseif killed.attackers and killed.attackers[hero:GetEntityIndex()] then
                table.insert(validHeroes, hero)
            end
        end
    end

    for _,hero in pairs(validHeroes) do
        local xp = math.floor( XPGain / #validHeroes )

        -- Add bonus experience if the hero is carrying a Gem of Knowledge
        local gem = hero:FindItemByName("item_gem_of_knowledge")
        local heroClass = hero:GetHeroClass()
        local benefits_from_gem = heroClass == "gatherer" or heroClass == "mage" or heroClass == "priest" or heroClass == "scout" or hero:HasSubClass()
        if gem and benefits_from_gem then
            local bonus = gem:GetSpecialValueFor("exp_bonus") or 0
            xp = xp + (1 + bonus * 0.01)
        end

        hero:AddExperience(xp, 0, false, false)
        PopupExperience(hero, xp)
    end
end

function CDOTA_BaseNPC_Hero:SplitExperienceBounty(teamID)
    local killed = self
    local level = killed:GetLevel()
    local killedTeam = killed:GetTeamNumber()
    local previousLevel = (level > 1 and XP_PER_LEVEL_TABLE[level-1]) or 0
    local XPGain =  XP_PER_LEVEL_TABLE[killed:GetLevel()] - previousLevel

    local heroesNearby = FindUnitsInRadius(killed:GetTeamNumber(), killed:GetAbsOrigin(), nil, XP_RANGE, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)
    local validHeroes = {}
    for _,hero in pairs(heroesNearby) do
        if hero:IsRealHero() and hero:GetTeamNumber() ~= killedTeam then
            -- If the hero in range was part of who did the last hit, always give XP
            if hero:GetTeamNumber() == teamID then
                table.insert(validHeroes, hero)

            -- Otherwise, they need to have done damage to the killed creep
            elseif killed.attackers and killed.attackers[hero:GetEntityIndex()] then
                table.insert(validHeroes, hero)
            end
        end
    end

    for _,hero in pairs(validHeroes) do
        local xp = XPGain -- not split

        -- Add bonus experience if the hero is carrying a Gem of Knowledge
        local gem = hero:FindItemByName("item_gem_of_knowledge")
        local heroClass = hero:GetHeroClass()
        local benefits_from_gem = heroClass == "gatherer" or heroClass == "mage" or heroClass == "priest" or heroClass == "scout" or hero:HasSubClass()
        if gem and benefits_from_gem then
            local bonus = gem:GetSpecialValueFor("exp_bonus") or 0
            xp = xp + (1 + bonus * 0.01)
        end

        hero:AddExperience(xp, 0, false, false)
        PopupExperience(hero, xp)
    end
end
