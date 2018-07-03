if not Attributes then
    Attributes = class({})
end

function Attributes:Init()
    self.itemTable = LoadKeyValues("scripts/npc/npc_items_custom.txt")
    self.abilityTable = LoadKeyValues("scripts/npc/npc_abilities_custom.txt")
    -- Custom Values
    self.HP_PER_STR           = 20
    self.HP_REGEN_PER_STR     = 0.06
    self.MANA_PER_INT         = 12
    self.MANA_REGEN_PER_INT   = 0.04
    self.ARMOR_PER_AGI        = 0.14
    self.ATKSPD_PER_AGI       = 0.05
    self.MAX_MS               = 750
    self.SP_INT			   = 0
    -- Default Dota Values
    self.DEFAULT_HP_PER_STR = 18
    self.DEFAULT_HP_REGEN_PER_STR = 0.55
    self.DEFAULT_RES_PER_STR = 0.08
    self.DEFAULT_MANA_PER_INT = 12
    self.DEFAULT_MANA_REGEN_PER_INT = 1.8
    self.DEFAULT_SPELLDMG_PER_INT = 0.07
    self.DEFAULT_ARMOR_PER_AGI = 0.16
    self.DEFAULT_ATKSPD_PER_AGI = 1
    self.DEFAULT_MOVSPD_PER_AGI = 0.05

    self.hp_adjustment = self.HP_PER_STR - self.DEFAULT_HP_PER_STR
    self.mana_adjustment = self.MANA_PER_INT - self.DEFAULT_MANA_PER_INT
    self.armor_adjustment = self.ARMOR_PER_AGI
    self.spellpower_adjustment = self.DEFAULT_SPELLDMG_PER_INT
    self.movespd_adjustment = self.DEFAULT_MOVSPD_PER_AGI

    self.applier = CreateItem("item_stat_modifier", nil, nil)
end

function Attributes:CalculateAdjustment(hero)
    local attribute = hero:GetPrimaryAttribute()
    if attribute == DOTA_ATTRIBUTE_STRENGTH then
        self.hp_adjustment = self.HP_PER_STR - self.DEFAULT_HP_PER_STR * 1.25
    elseif attribute == DOTA_ATTRIBUTE_AGILITY then
        self.movespd_adjustment = self.DEFAULT_MOVSPD_PER_AGI * 1.25
        self.armor_adjustment = self.ARMOR_PER_AGI * 1.25
    elseif attribute == DOTA_ATTRIBUTE_INTELLECT then
        self.spellpower_adjustment = self.DEFAULT_SPELLDMG_PER_INT * 1.25
        self.mana_adjustment = self.MANA_PER_INT - self.DEFAULT_MANA_PER_INT * 1.25
    end
end

function Attributes:ModifyBonuses(hero)
    self:CalculateAdjustment(hero)
    Timers:CreateTimer(function()

        if not IsValidEntity(hero) then
            return
        end

        -- Initialize value tracking
        if not hero.custom_stats then
            hero.custom_stats = true
            hero.strength = 0
            hero.agility = 0
            hero.intellect = 0
        end

        -- Get player attribute values
        local strength = hero:GetStrength()
        local agility = hero:GetAgility()
        local intellect = hero:GetIntellect()
        
        -- Base Armor Bonus
        --local armor = agility * self.ARMOR_PER_AGI
        --hero:SetPhysicalArmorBaseValue(armor)
        -- Base Magic Resistance
        local itemRes = 0
        for i=1,6 do
            -- 获取物品
            local item = hero.bag_item[i]
            if item then
                if item:IsNull() then break end
                local itemName = item:GetAbilityName()
                -- 循环所有物品判断是否是身上的物品
                for k,v in pairs(self.itemTable) do
                    if k == itemName and v.Modifiers then
                        for k,v in pairs(v.Modifiers) do
                                -- 判断是否有魔抗属性
                                if v.Properties then
                                    for k,v in pairs(v.Properties) do
                                        if k == "MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS" then
                                            if string.sub(v,0,1) == "%" then
                                                itemRes = itemRes + item:GetSpecialValueFor(string.sub(v,2,string.len(v)))
                                            else
                                                itemRes = itemRes + v
                                            end
                                        end
                                    end
                                end
                        end
                    end
                end
            end
        end
        local abilityRes = 0
        for i=1,hero:GetModifierCount() do
            local modifierName = hero:GetModifierNameByIndex(i)
            local modifier = hero:FindModifierByName(modifierName)
            if not modifier then break end
            local ability = modifier:GetAbility()
            if not ability then break end
            local abilityName = hero:FindModifierByName(modifierName):GetAbility():GetAbilityName()
            -- 循环所有技能判断是否是身上的modifier所属技能
            for k,v in pairs(self.abilityTable) do
                if k == abilityName then
                    if v.Modifiers then
                        for k,v in pairs(v.Modifiers) do
                            if k == modifierName then
                                -- 判断是否有魔抗属性
                                if v.Properties then
                                    for k,v in pairs(v.Properties) do
                                        if k == "MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS" then
                                            if string.sub(v,0,1) == "%" then
                                                abilityRes = abilityRes + ability:GetSpecialValueFor(string.sub(v,2,string.len(v)))
                                            else
                                                abilityRes = abilityRes + v
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        hero:SetBaseMagicalResistanceValue((itemRes + abilityRes) * 0.01)
        -- STR
        if strength ~= hero.strength then
            
            -- HP Bonus
            if not hero:HasModifier("modifier_health_bonus") then
                self.applier:ApplyDataDrivenModifier(hero, hero, "modifier_health_bonus", {})
            end

            local health_stacks = math.abs(strength * self.hp_adjustment)
            hero:SetModifierStackCount("modifier_health_bonus", self.applier, health_stacks)

        end

        -- AGI
        if agility ~= hero.agility then        

            -- Move Speed Bonus
            if not hero:HasModifier("modifier_movespeed_bonus_percentage") then
                self.applier:ApplyDataDrivenModifier(hero, hero, "modifier_movespeed_bonus_percentage", {})
            end
            local movespeed_stacks = math.abs(self.movespd_adjustment * agility)
            hero:SetModifierStackCount("modifier_movespeed_bonus_percentage", self.applier, movespeed_stacks)
        end

        -- INT
        if intellect ~= hero.intellect then
            
            -- Mana Bonus
            if not hero:HasModifier("modifier_mana_bonus") then
                Attributes.applier:ApplyDataDrivenModifier(hero, hero, "modifier_mana_bonus", {})
            end

            local mana_stacks = math.abs(intellect * self.mana_adjustment)
            hero:SetModifierStackCount("modifier_mana_bonus", self.applier, mana_stacks)
           --[[print("MANA STACKS A:")
            print(mana_stacks)
            if hero:HasModifier("modifier_halcyon_soul_glove") then
               mana_stacks = mana_stacks - intellect*MANA_PER_INT*0.5
            end
            print("MANA STACKS B:")
            print(mana_stacks)
            if hero:GetMaxMana() - mana_stacks > 300 then
             hero:SetModifierStackCount("modifier_mana_bonus", Attributes.applier, mana_stacks)
            end

            -- Mana Regen Bonus
            if not hero:HasModifier("modifier_base_mana_regen") then
                Attributes.applier:ApplyDataDrivenModifier(hero, hero, "modifier_base_mana_regen", {})
            end

            local mana_regen_stacks = math.abs(intellect * Attributes.mana_regen_adjustment * 100)
            if hero:HasModifier("modifier_halcyon_soul_glove") then
               mana_regen_stacks = mana_regen_stacks + intellect*MANA_REGEN_PER_INT*0.5
            end
            hero:SetModifierStackCount("modifier_base_mana_regen", Attributes.applier, mana_regen_stacks)]]

            --SPELL DAMAGE STACKS
            if not hero:HasModifier("modifier_spell_damage_constant") then
                self.applier:ApplyDataDrivenModifier(hero, hero, "modifier_spell_damage_constant", {})
            end

            local spellpower_stacks = intellect * self.spellpower_adjustment * 100
            hero:SetModifierStackCount("modifier_spell_damage_constant", self.applier, spellpower_stacks)

            
        end

        -- Update the stored values for next timer cycle
        hero.strength = strength
        hero.agility = agility
        hero.intellect = intellect

        hero:CalculateStatBonus()
        return 0.03
    end)
end

-- if not Attributes.applier then Attributes:Init() end