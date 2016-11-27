function MakeTrap( keys )
    local caster = keys.caster
	local target_point = keys.target_points[1]

    local particle = ParticleManager:CreateParticle( "particles/units/heroes/hero_furion/furion_sprout.vpcf", PATTACH_CUSTOMORIGIN, nil )
    ParticleManager:SetParticleControl( particle, 0, target_point )
    ParticleManager:SetParticleControl( particle, 1, Vector( 0.0, -30, 0.0 ) )

	local dummy = CreateUnitByName("npc_building_trap_ensnare", target_point, false, caster, caster, caster:GetTeam())

end

function KillTrap ( keys )
    local caster = keys.caster
	caster:EmitSound("sounds/weapons/hero/treant/overgrowth_cast.vsnd")
	caster:AddEffects(EF_NODRAW) --Hide it, so that it's still accessible after this script
    caster:ForceKill(true)
end