function PiercingEye( t )
    local caster = t.caster
    local target = t.target
    local ability = t.ability
    local damage = t.DamageTaken
    local change = ability:GetSpecialValueFor("chance")
    PiercingEyeDamage( caster, target, damage, DAMAGE_TYPE_PURE, ability )
end
function PiercingEyeDamage( caster, target, damage, damageType, ability )
    local damageDeepen = (100 - target:GetHealthPercent()) * 0.05 + 1
    CauseDamage( caster, target, damage * damageDeepen, damageType, ability )
end
function OnDealDamage( t )
    local caster = t.caster
    local target = t.unit
    local damage = t.DamageTaken
    local damageDeepen = (100 - target:GetHealthPercent()) * t.ability:GetSpecialValueFor("damage_deep") * 0.01
    if caster.dealDeepDamage == nil then
        caster.dealDeepDamage = true
        CauseDamage( caster, target, damage * damageDeepen, DAMAGE_TYPE_PURE, ability )
        caster.dealDeepDamage = nil
    end
end
function OnTakeDamage( t )
    local caster = t.caster
    local attacker = t.attacker
    local damage = t.DamageTaken
    local damageReduce = (100 - attacker:GetHealthPercent()) * t.ability:GetSpecialValueFor("damage_reduce") * 0.01
    Heal(caster,damage * damageReduce,0,false)
end
function StickWind( t )
    local caster = t.caster
    local ability = t.ability
    local damage = ability:GetSpecialValueFor("damage") * caster:GetAverageTrueAttackDamage(caster) + ability:GetSpecialValueFor("base_damage")
    local strikeDamage = ability:GetSpecialValueFor("strike_damage") * caster:GetAgility()
    local damageType = ability:GetAbilityDamageType()
    local caster_location = caster:GetAbsOrigin()
    local target_point = t.target_points[1]
    local speed = ability:GetSpecialValueFor("speed")
    local radius = ability:GetSpecialValueFor("radius")
	local distance = (target_point - caster_location):Length2D()
    local traveled_distance = 0
	local maxDistance = ability:GetSpecialValueFor("distance")
	if distance > maxDistance then
		distance = maxDistance
	end
	local direction = (target_point - caster_location):Normalized()
    local duration = distance/speed
    speed = speed / 30
    CreateParticle("particles/heroes/monkey_king/stick_wind.vpcf",PATTACH_ABSORIGIN_FOLLOW,caster,duration)
    CreateSound("Hero_Juggernaut.BladeFuryStart",caster,duration)
    caster:StartGestureWithPlaybackRate(ACT_DOTA_MK_STRIKE, 1 - 0.5 * duration )
    ability:ApplyDataDrivenModifier(caster, caster, "modifier_stick_wind", {duration=duration})
    Timers:CreateTimer(function ()
        if traveled_distance < distance then
            local nextPath = caster:GetAbsOrigin() + direction * speed
            if GridNav:CanFindPath(caster:GetAbsOrigin(), nextPath) and #GetUnitsInRadius(caster,ability,nextPath,50) == 0 then
                SetUnitPosition(caster, nextPath, true)
            end
			traveled_distance = traveled_distance + speed
            ProjectileManager:ProjectileDodge(caster)
            local unitGroup = GetUnitsInRadius(caster,ability,caster:GetAbsOrigin(),radius)
            for k,v in pairs(unitGroup) do
                ability:ApplyDataDrivenModifier(caster, v, "modifier_stick_wind_debuff", nil)
            end
            CauseDamage(caster,unitGroup,damage * 0.01,damageType,ability)
            print(damage)
			return 0.01
        else
            local p = CreateParticle("particles/heroes/monkey_king/stick_wind_strike.vpcf",PATTACH_ABSORIGIN,caster,3)
            ParticleManager:SetParticleControl(p, 1, Vector(400,1,1))
            ParticleManager:SetParticleControl(p, 2, Vector(400,0,0))
            CreateSound("Hero_MonkeyKing.Strike.Impact.Immortal",caster)
			local unitGroup = GetUnitsInRadius(caster,ability,caster:GetAbsOrigin(),radius)
            for k,v in pairs(unitGroup) do
                CauseDamage(caster,v,damage * duration,damageType,ability)
                print(damage * duration)
                ability:ApplyDataDrivenModifier(caster, v, "modifier_stick_wind_knockback", nil)
                local direction = (v:GetAbsOrigin() - caster:GetAbsOrigin()):Normalized()
                local target_location = v:GetAbsOrigin() + direction * 100
                Jump(v,target_location,150,150,false,nil)
            end
		end
	end)
end
function Jingubang( t )
    local caster = t.caster
    local ability = t.ability
    local caster_location = caster:GetAbsOrigin()
    local cast_location = t.target_points[1]
    local targetDirection = (cast_location - caster_location):Normalized()
    local target_location = caster_location + targetDirection * 1200
    local p0 = CreateParticle("particles/units/heroes/hero_monkey_king/monkey_king_strike_cast.vpcf",PATTACH_ABSORIGIN,caster,2)
    ParticleManager:SetParticleControlForward(p0,0,targetDirection)
    Timers:CreateTimer(0.2,function ()
        local unitGroup = GetUnitsInLine(caster,ability,caster_location,target_location,150)
        for k,v in pairs(unitGroup) do
            local damage = ability:GetSpecialValueFor("damage") * caster:GetAverageTrueAttackDamage(caster)
            local damageType = ability:GetAbilityDamageType()
            ability:ApplyDataDrivenModifier(caster, v, "modifier_jingubang_debuff", nil)
            CauseDamage(caster,v,damage,damageType,ability)
        end
        local p1 = CreateParticle("particles/units/heroes/hero_monkey_king/monkey_king_strike.vpcf",PATTACH_ABSORIGIN,caster,2)
        ParticleManager:SetParticleControlForward(p1,0,targetDirection)
        ParticleManager:SetParticleControl(p1, 1, target_location)
    end)
    for i,unit in pairs(caster.illusion_table) do
        if unit.use == true then
            unit:StartGesture(ACT_DOTA_MK_STRIKE)
            local unit_location = unit:GetAbsOrigin()
            local unitDirection = (cast_location - unit_location):Normalized()
            local target_pos = unit_location + unitDirection * 1200
            unit:SetForwardVector(unitDirection)
            local p0 = CreateParticle("particles/units/heroes/hero_monkey_king/monkey_king_strike_cast.vpcf",PATTACH_ABSORIGIN,unit,2)
            ParticleManager:SetParticleControlForward(p0,0,unitDirection)
            Timers:CreateTimer(0.2,function ()
                local unitGroup = GetUnitsInLine(unit,ability,unit_location,target_pos,150)
                for k,v in pairs(unitGroup) do
                    local damage = ability:GetSpecialValueFor("damage") * unit:GetAverageTrueAttackDamage(unit)
                    local damageType = ability:GetAbilityDamageType()
                    ability:ApplyDataDrivenModifier(unit, v, "modifier_jingubang_debuff", nil)
                    CauseDamage(unit,v,damage,damageType,ability)
                end
                local p1 = CreateParticle("particles/units/heroes/hero_monkey_king/monkey_king_strike.vpcf",PATTACH_ABSORIGIN,unit,2)
                ParticleManager:SetParticleControlForward(p1,0,unitDirection)
                ParticleManager:SetParticleControl(p1, 1, target_pos)
            end)
        end
    end
end
function Indestructible( t )
    local caster = t.caster
    local ability = t.ability
    if caster.IndestructibleAbsorb == nil then
        caster.IndestructibleAbsorb = 0
    end
    if ability.reduceValue == nil then
        ability.reduceValue = ability:GetSpecialValueFor("damage_reduce_percent")
        caster.percent_reduce_damage = caster.percent_reduce_damage + ability.reduceValue
    elseif ability.reduceValue ~= ability:GetSpecialValueFor("damage_reduce_percent") then
        caster.percent_reduce_damage = caster.percent_reduce_damage - ability.reduceValue
        ability.reduceValue = ability:GetSpecialValueFor("damage_reduce_percent")
        caster.percent_reduce_damage = caster.percent_reduce_damage + ability.reduceValue
    end
end
function IndestructibleAbsorb( t )
    local caster = t.caster
    local damage = t.DamageTaken
    caster.IndestructibleAbsorb = caster.IndestructibleAbsorb + damage
    Heal(caster,damage,0,false)
end
function IndestructibleCD( t )
    local caster = t.caster
    local ability = t.ability
    if caster.IndestructibleAbsorb == 0 then
        local cd = ability:GetCooldownTimeRemaining() * 0.2
        ability:EndCooldown()
        ability:StartCooldown(cd)
    else
        ability:ApplyDataDrivenModifier(caster, caster, "modifier_indestructible_buff", nil)
        CreateSound("Hero_Chen.PenitenceCast",caster)
    end
end
function IndestructibleArmor( t )
    local caster = t.caster
    local damage = t.DamageTaken
    local healAmount = damage
    if caster.IndestructibleAbsorb > damage then
        caster.IndestructibleAbsorb = caster.IndestructibleAbsorb - damage
    else
        healAmount = damage - caster.IndestructibleAbsorb
    end
    Heal(caster,healAmount,0,false)
end
function IndestructibleRemove( t )
    local caster = t.caster
    caster.IndestructibleAbsorb = 0
end
function EndlessOffensive( t )
    local caster = t.caster
    local target = t.target
    local ability = t.ability
    local unitGroup = GetUnitsInRadius( caster, ability, target:GetAbsOrigin(), 600 )
    local count = 0
    for k,v in pairs(unitGroup) do
        if count < 3 and v:IsAlive() then
            for i,unit in pairs(caster.illusion_table) do
                if unit.use == false then
                    unit.use = true
                    local heroLevel = caster:GetLevel() - unit:GetLevel()
                    if heroLevel > 0 then 
                        for i=1,heroLevel do
                            unit:HeroLevelUp(false)
                        end
                    end
                    unit:SetAbilityPoints(0)
                    for abilitySlot=0,15 do
                        local illusionAbility = caster:GetAbilityByIndex(abilitySlot)
                        if illusionAbility ~= nil then 
                            local abilityLevel = illusionAbility:GetLevel()
                            local abilityName = illusionAbility:GetAbilityName()
                            local unitAbility = unit:GetAbilityByIndex(abilitySlot)
                            if unitAbility then
                                unitAbility:SetLevel(abilityLevel)
                            end
                        end
                    end
                    for itemSlot=0,5 do
                        local itemOld = unit:GetItemInSlot(itemSlot)
                        if itemOld then
                            unit:RemoveItem(itemOld)
                        end
                        local item = caster:GetItemInSlot(itemSlot)
                        if item ~= nil then
                            local itemName = item:GetName()
                            local newItem = CreateItem(itemName, unit, unit)
                            unit:AddItem(newItem)
                        end
                    end
                    SetUnitPosition(unit,target:GetAbsOrigin() + Vector(RandomInt(-200, 200),RandomInt(-200, 200),0))
                    unit:RemoveModifierByName("modifier_endless_offensive_debuff")
                    unit:MoveToTargetToAttack(target)
                    unit:RemoveNoDraw()
                    local particle = CreateParticle("particles/units/heroes/hero_monkey_king/monkey_king_disguise.vpcf", PATTACH_ABSORIGIN, unit)
                    Timers:CreateTimer(3,function ()
                        unit.use = false
                        unit:AddNoDraw()
                        ability:ApplyDataDrivenModifier(unit, unit, "modifier_endless_offensive_debuff", nil)
                        unit:Stop()
                    end)
                    break
                end
            end
            count = count + 1
        else
            break
        end
    end
end
function EndlessOffensiveCleave( t )
    local caster = t.caster
    local target = t.target
    local ability = t.ability
    local damage = t.DamageTaken
    local position = caster:GetAbsOrigin()
    local radius = ability:GetSpecialValueFor("radius")
    local forwardVector = (target:GetAbsOrigin() - position):Normalized()
    local unitGroup = GetUnitsInSector( caster, ability, position, forwardVector, radius, radius )
    for k,v in pairs(unitGroup) do
        if v ~= target then
            CauseDamage(caster,v,damage,DAMAGE_TYPE_PURE,ability)
        end
    end
end
function IllusionAttack( t )
    --[[local caster = t.caster
    local ability = t.ability
    local attacker = t.attacker
    attacker.use = false
    attacker:AddNoDraw()
    ability:ApplyDataDrivenModifier(caster, attacker, "modifier_endless_offensive_debuff", nil)
    attacker:Stop()]]--
end
function AttackEffect( t )
    local effectName = {
        "particles/units/heroes/hero_monkey_king/monkey_king_attack_01_blur_cud.vpcf",
        "particles/units/heroes/hero_monkey_king/monkey_king_attack_01_near_blur_cud.vpcf",
        "particles/units/heroes/hero_monkey_king/monkey_king_attack_03_near_blur_cud.vpcf",
        "particles/units/heroes/hero_monkey_king/monkey_king_attack_05_blur_cud.vpcf",
        "particles/units/heroes/hero_monkey_king/monkey_king_attack_05_near_blur_cud.vpcf",
        "particles/units/heroes/hero_monkey_king/monkey_king_attack_06_blur_cud.vpcf",
        "particles/units/heroes/hero_monkey_king/monkey_king_attack_06_near_blur_cud.vpcf"
    }
    local caster = t.attacker
    local ability = t.ability
    local particleIndex = RandomInt(1, 6)
    local particle = CreateParticle(effectName[particleIndex], PATTACH_ABSORIGIN_FOLLOW, caster)
    --ParticleManager:SetParticleControlEnt(particle, 0, caster, PATTACH_ABSORIGIN, "attach_hitloc", caster:GetAbsOrigin(), true)
end
function EndlessOffensiveCreate( t )
    local caster = t.caster
    local ability = t.ability
    if caster.illusion_table or caster.caster_hero then
        return
    end
    caster.illusion_table ={}
    for i=1,9 do
        local unit = CreateUnitByName("npc_dota_hero_monkey_king", caster:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS )
        unit:SetOwner(caster:GetPlayerOwner())
        unit:SetControllableByPlayer(caster:GetPlayerOwnerID(), true)
        local heroLevel = caster:GetLevel() - unit:GetLevel()
        if heroLevel > 0 then 
            for i=1,heroLevel do
                unit:HeroLevelUp(false)
            end
        end
        unit:SetAbilityPoints(0)
        --[[for abilitySlot=0,6 do
            local illusionAbility = caster:GetAbilityByIndex(abilitySlot)
            if illusionAbility ~= nil then 
                local abilityLevel = illusionAbility:GetLevel()
                local unitAbility = unit:GetAbilityByIndex(abilitySlot)
                if unitAbility then
                    unitAbility:SetLevel(abilityLevel)
                end
            end
        end]]--
        for itemSlot=0,5 do
            local itemOld = unit:GetItemInSlot(itemSlot)
            if itemOld then
                unit:RemoveItem(itemOld)
            end
            local item = caster:GetItemInSlot(itemSlot)
            if item ~= nil then
                local itemName = item:GetName()
                local newItem = CreateItem(itemName, unit, unit)
                unit:AddItem(newItem)
            end
        end
        unit.caster_hero = caster
        HeroState:InitIllusion(unit)
        unit:MakeIllusion()
        ability:ApplyDataDrivenModifier(caster, unit, "modifier_endless_offensive_illusion", nil)
        unit.use = false
        unit:AddNoDraw()
        ability:ApplyDataDrivenModifier(caster, unit, "modifier_endless_offensive_debuff", nil)
        table.insert(caster.illusion_table,unit)
        local particle = CreateParticle("particles/units/heroes/hero_monkey_king/monkey_king_tap_buff.vpcf", PATTACH_ABSORIGIN, unit)
        ParticleManager:SetParticleControlEnt(particle, 0, unit, PATTACH_POINT_FOLLOW, "attach_weapon_top", unit:GetAbsOrigin(), true)
        ParticleManager:SetParticleControlEnt(particle, 2, unit, PATTACH_POINT_FOLLOW, "attach_weapon_top", unit:GetAbsOrigin(), true)
        ParticleManager:SetParticleControlEnt(particle, 3, unit, PATTACH_POINT_FOLLOW, "attach_weapon_bot", unit:GetAbsOrigin(), true)
    end
end
function EndlessOffensiveActive( t )
    local caster = t.caster
    local ability = t.ability
    local duration = ability:GetSpecialValueFor("duration")
    local particle = CreateParticle("particles/units/heroes/hero_monkey_king/monkey_king_tap_buff.vpcf", PATTACH_ABSORIGIN, caster)
    ParticleManager:SetParticleControlEnt(particle, 0, caster, PATTACH_POINT_FOLLOW, "attach_weapon_top", caster:GetAbsOrigin(), true)
    ParticleManager:SetParticleControlEnt(particle, 2, caster, PATTACH_POINT_FOLLOW, "attach_weapon_top", caster:GetAbsOrigin(), true)
    ParticleManager:SetParticleControlEnt(particle, 3, caster, PATTACH_POINT_FOLLOW, "attach_weapon_bot", caster:GetAbsOrigin(), true)
    Timers:CreateTimer(duration,function ()
        ParticleManager:DestroyParticle(particle,false)
    end)
end