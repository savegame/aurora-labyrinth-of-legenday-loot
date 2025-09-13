local TRIGGERS = require("actions.triggers")
local BASE_ATTACK = class(TRIGGERS.ON_ATTACK)
function BASE_ATTACK:initialize(entity, direction, abilityStats)
    BASE_ATTACK:super(self, "initialize", entity, direction, abilityStats)
    self.bonusMinDamage = 0
    self.bonusMaxDamage = 0
    self.forcedMinDamage = false
    self.forcedMaxDamage = false
    self.buff = false
end

function BASE_ATTACK:setBonusFromAbilityStats(abilityStats)
    self.bonusMinDamage = abilityStats:get(Tags.STAT_ABILITY_DAMAGE_MIN)
    self.bonusMaxDamage = abilityStats:get(Tags.STAT_ABILITY_DAMAGE_MAX)
end

function BASE_ATTACK:setBonus(minDamage, maxDamage)
    self.bonusMinDamage = minDamage
    self.bonusMaxDamage = maxDamage
end

function BASE_ATTACK:getAttackDamage()
    return self.entity.stats:getAttack()
end

function BASE_ATTACK:createHit()
    local hit = self.entity.hitter:createHit()
    if self.forcedMinDamage then
        hit:setDamage(Tags.DAMAGE_TYPE_MELEE, self.forcedMinDamage, self.forcedMaxDamage)
        hit:increaseBonusState()
    else
        hit:setDamage(Tags.DAMAGE_TYPE_MELEE, self:getAttackDamage())
    end

    if self.bonusMinDamage > 0 or self.bonusMaxDamage > 0 then
        hit.minDamage = hit.minDamage + self.bonusMinDamage
        hit.maxDamage = hit.maxDamage + self.bonusMaxDamage
        if not self.forcedMinDamage then
            hit:increaseBonusState()
        end

    end

    if self.buff then
        hit.buffs:push(self.buff)
    end

    return hit
end

return BASE_ATTACK

