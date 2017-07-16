function SpaceRift( caster,originalPoint,minDistance,maxDistance )
    local ability = caster:FindAbilityByName("space_rift")
    local radius = ability:GetSpecialValueFor("radius")
    local centerRadius = ability:GetSpecialValueFor("center_radius")
    local damage = ability:GetSpecialValueFor("damage") * caster:GetIntellect()
    local centerDamage = ability:GetSpecialValueFor("center_damage")
    local damageType = ability:GetAbilityDamageType()
    local attackPoint = GetRandomPoint(originalPoint,minDistance,maxDistance)
    local unitGroup = GetUnitsInRadius( caster, ability, attackPoint, radius)
    for k, v in pairs( unitGroup ) do
        CauseDamage( caster, v, damage, damageType, ability )
    end
    local centerUnitGroup = GetUnitsInRadius( caster, ability, attackPoint, centerRadius)
    for k, v in pairs( centerUnitGroup ) do
        CauseDamage( caster, v, v:GetBaseMaxHealth() * centerDamage, damageType, ability )
    end
    local particleName = "particles/skills/space_phase.vpcf"
    if caster.gift then
        particleName = "particles/skills/space_gold_phase.vpcf"
    end
    local particle = CreateParticle(particleName,PATTACH_CUSTOMORIGIN,caster,2)
    ParticleManager:SetParticleControl( particle, 0, attackPoint )
    EmitSoundOn("Hero_SkywrathMage.MysticFlare.Target",caster)
end
function ChronosMagic( t )
    local caster = t.caster
    local ability = t.ability
    local caster_location = caster:GetAbsOrigin()
    local target_location = t.target_points[1]
    local damageType = t.ability:GetAbilityDamageType()
    local pull_damage = ability:GetSpecialValueFor("pull_damage")
    local pull_bonus = ability:GetSpecialValueFor("pull_bonus")
    local open_damage = ability:GetSpecialValueFor("open_damage") * caster:GetIntellect()
    local duration = ability:GetSpecialValueFor("duration")
    local radius = ability:GetSpecialValueFor("radius")
    local modifier = "modifier_chronos_magic"
    local pullUnitGroup = GetUnitsInRadius( caster, ability, caster_location, radius )
    local time = 0
    SpaceRift( caster,caster_location,10,300 )
    Timers:CreateTimer(function()
    	if time <= duration then    --吸引周围单位
		    for i,unit in ipairs(pullUnitGroup) do
		        local unit_location = unit:GetAbsOrigin()
		        local vector_distance = caster_location - unit_location
		        local distance = (vector_distance):Length2D()
		        local direction = (vector_distance):Normalized()
		        local speed = distance / 20
		        ability:ApplyDataDrivenModifier(caster, unit, modifier, {duration = duration})
			    unit:AddNewModifier(nil, nil, "modifier_phased", {duration = duration})
                SetUnitPosition(unit, unit_location + direction * speed)
                CauseDamage( caster, unit, pull_damage * (1 + pull_bonus * #pullUnitGroup), damageType, ability )
		    end
		    time = time + 0.01
		    return 0.01
		else    --传送被吸引的单位
			local particleName = "particles/skills/chronos_magic_open.vpcf"
			if caster.gift then
				particleName = "particles/skills/chronos_magic_gold_open.vpcf"
			end
            particle_open = CreateParticle(particleName, PATTACH_ABSORIGIN, caster)
			ParticleManager:SetParticleControl(particle_open, 0, target_location)
			caster:EmitSound("Hero_FacelessVoid.TimeWalk")
            local openUnitGroup = GetUnitsInRadius( caster, ability, target_location, radius )
            for i,unit in ipairs(pullUnitGroup) do
                SetUnitPosition(unit,target_location)
                table.insert(openUnitGroup,unit)
            end
            for i,unit in pairs(openUnitGroup) do
                CauseDamage( caster, unit, open_damage * (1 + pull_bonus * #openUnitGroup), damageType, ability )
            end
            SpaceRift( caster,target_location,10,300 )
		end
    end)
end
function TransferMatrix( t )
	local caster = t.caster
	local ability = t.ability
    local target_location = t.target_points[1]
    local caster_location = caster:GetAbsOrigin()
    local damage = ability:GetSpecialValueFor("damage") * caster:GetIntellect()
    local damageType = ability:GetAbilityDamageType()
    local delay = ability:GetSpecialValueFor("delay")
    local radius = ability:GetSpecialValueFor("radius")
    local particleName = "particles/skills/teleport_open.vpcf"
    if caster.gift then
        particleName = "particles/skills/teleport_open_gold.vpcf"
    end
    local particleOrigin = CreateParticle(particleName,PATTACH_CUSTOMORIGIN,caster,2)
    ParticleManager:SetParticleControl( particleOrigin, 0, caster_location )
    local particleTarget = CreateParticle(particleName,PATTACH_CUSTOMORIGIN,caster,2)
    ParticleManager:SetParticleControl( particleTarget, 0, target_location )
    Timers:CreateTimer(delay,function()
        SetUnitPosition(caster, target_location)
        -- 起始位置
        local patticleStart = CreateParticle("particles/skills/teleport_startleague.vpcf",PATTACH_CUSTOMORIGIN,caster,2)
        ParticleManager:SetParticleControl( patticleStart, 0, caster_location )
        local originUnitGroup = GetUnitsInRadius( caster, ability, caster_location, radius )
        for k, v in pairs( originUnitGroup ) do
            CauseDamage( caster, v, damage, damageType, ability )
        end
        SpaceRift( caster,caster_location,10,300 )
        local patticleEnd = CreateParticle("particles/skills/teleport_endflash_nexon_hero_cp_2014.vpcf",PATTACH_CUSTOMORIGIN,caster,2)
        ParticleManager:SetParticleControl( patticleEnd, 0, target_location )
        local targetUnitGroup = GetUnitsInRadius( caster, ability, target_location, radius )
        for k, v in pairs( targetUnitGroup ) do
            CauseDamage( caster, v, damage, damageType, ability )
        end
        SpaceRift( caster,target_location,10,300 )
        EmitSoundOn("Hero_Furion.Teleport_Disappear",caster)
    end)
end
function SpaceBarrier( t )
	local caster = t.caster
	local ability = t.ability
	local target_location = t.target_points[1]
    local caster_location = caster:GetAbsOrigin()
    local damage = ability:GetSpecialValueFor("damage") * caster:GetIntellect()
    local damageType = ability:GetAbilityDamageType()
    local delay = ability:GetSpecialValueFor("delay")
    local radius = ability:GetSpecialValueFor("radius")
    local particleName = "particles/skills/space_barrier.vpcf"
    if caster.gift then
        particleName = "particles/skills/space_barrier_gold.vpcf"
    end
    local patticle = CreateParticle(particleName,PATTACH_CUSTOMORIGIN,caster,6)
    ParticleManager:SetParticleControl( patticle, 0, target_location )
    ParticleManager:SetParticleControl( patticle, 1, Vector(radius,radius,0) )
    EmitSoundOn("Hero_FacelessVoid.Chronosphere",caster)
    Timers:CreateTimer(delay,function()
    	local time = 0
    	Timers:CreateTimer(function()
        	if time < 50 then
        		local unitGroup = GetUnitsInRadius( caster, ability, target_location, radius + 20 )
        		for i,unit in ipairs(unitGroup) do
			        local unit_location = unit:GetAbsOrigin()
			        local vector_distance = target_location - unit_location
			        local distance = (vector_distance):Length2D()
			        local direction = (vector_distance):Normalized()
			        local speed = distance / 20
			        local target_point = unit_location + direction * speed
					ability:ApplyDataDrivenModifier(caster, unit, "modifier_space_barrier", {duration = 0.2})
					unit:AddNewModifier(nil, nil, "modifier_phased", {duration=0.2})
                    SetUnitPosition(unit,unit_location + direction * speed)
			    end
        		time = time + 1
        		return 0.1
        	end
        end)
        local times = 0
        Timers:CreateTimer(function()
            if times < 10 then
                local barrierUnitGroup = GetUnitsInRadius( caster, ability, target_location, radius )
                for k, v in pairs( barrierUnitGroup ) do
                    CauseDamage( caster, v, damage, damageType, ability )
                end
                SpaceRift( caster,target_location,10,350 )
                times = times + 1
                return 0.5
            end
        end)
    end)
end
function Fluctuation( t )
	local caster = t.caster
	local ability = t.ability
    local target_location = t.target_points[1]
    local caster_location = caster:GetAbsOrigin()
    local damage = ability:GetSpecialValueFor("damage") * caster:GetIntellect()
    local damageType = ability:GetAbilityDamageType()
    local radius = ability:GetSpecialValueFor("radius")
    local particleName = "particles/skills/fluctuation.vpcf"
    if caster.gift then
        particleName = "particles/skills/fluctuation_gold.vpcf"
    end
    local patticle = CreateParticle(particleName,PATTACH_CUSTOMORIGIN,caster,12.5)
    ParticleManager:SetParticleControl( patticle, 0, target_location )
    ParticleManager:SetParticleControl( patticle, 1, target_location )
    ParticleManager:SetParticleControl( patticle, 2, target_location )
    ParticleManager:SetParticleControl( patticle, 4, target_location )
    ParticleManager:SetParticleControl( patticle, 5, target_location )
    EmitSoundOn("Hero_FacelessVoid.Chronosphere",caster)
    local time = 0
    local interval = 1
    Timers:CreateTimer(function()
        if time < 50 then
            local barrierUnitGroup = GetUnitsInRadius( caster, ability, target_location, radius )
            for k, v in pairs( barrierUnitGroup ) do
                CauseDamage( caster, v, damage, damageType, ability )
                ability:ApplyDataDrivenModifier(caster, v, "modifier_fluctuation", {duration = 1})
            end
            SpaceRift( caster,target_location,10,600 )
            time = time + 1
            interval = interval * 0.925
            return interval
        end
    end)
end