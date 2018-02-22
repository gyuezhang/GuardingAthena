function OnCreated( t )
    local caster = t.caster
    local ability = t.ability
    local interval = ability:GetSpecialValueFor("interval")
    ability.shield_health = 0
    caster.ShieldFilter = function (damage,caster)
        if ability.shield_health > damage then
			damage = 0
			ability.shield_health = ability.shield_health - damage
		else
			damage = damage - ability.shield_health
			ability.shield_health = 0
        end
        return damage
    end
    caster.percent_bonus_damage = caster.percent_bonus_damage + ability:GetSpecialValueFor("damage_deepen")
    ability.timer = Timers:CreateTimer(function ()
        ClearBuff(caster,"debuff")
        ability.shield_health = caster:GetMaxHealth() * 0.5
        return interval
    end)
end
function OnDestroy( t )
    local caster = t.caster
    local ability = t.ability
    caster.percent_bonus_damage = caster.percent_bonus_damage - ability:GetSpecialValueFor("damage_deepen")
    Timers:RemoveTimer(ability.timer)
end
function OnDeath( t )
    local caster = t.caster
    local ability = t.ability
    if ability:IsCooldownReady() then
        caster:RespawnUnit()
        ability:StartCooldown(ability:GetCooldown(1))
        ability:ApplyDataDrivenModifier(caster, caster, "modifier_item_chaos_plate_buff", nil)
    end
end