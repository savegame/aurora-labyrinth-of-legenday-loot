local Stats = require("components.create_class")()
local Array = require("utils.classes.array")
local Hash = require("utils.classes.hash")
function Stats:initialize(entity)
    Stats:super(self, "initialize")
    self._stats = Hash:new()
    self._entity = entity
    self._bonusSources = Array:new()
end

function Stats:addBonusSource(bonusSource)
    self._bonusSources:push(bonusSource)
end

function Stats:get(stat)
    local result = self._stats:get(stat, 0)
    for bonusSource in self._bonusSources() do
        result = result + bonusSource:getStatBonus(stat)
    end

    for bonusSource in self._bonusSources() do
        result = result * bonusSource:getStatMultiplier(stat)
    end

    return result
end

function Stats:has(stat)
    return self:get(stat) ~= 0
end

Stats.hasKey = Stats.has
function Stats:set(stat, value)
    self._stats:set(stat, value)
end

function Stats:multiply(stat, multiplier)
    self._stats:set(stat, self._stats:get(stat) * multiplier)
end

function Stats:setFromHash(stats)
    for key, value in stats() do
        self._stats:set(key, value)
    end

end

function Stats:getExtenderProperty()
        if self:get(Tags.STAT_LUNGE) > 0 then
        if not self._entity.buffable:canMove() then
            return false
        end

        return Tags.STAT_LUNGE
    elseif self:get(Tags.STAT_REACH) > 0 then
        return Tags.STAT_REACH
    else
        return false
    end

end

function Stats:getConstantEnemyAbility()
    local value = self:get(Tags.STAT_ABILITY_DAMAGE_MIN) + self:get(Tags.STAT_ABILITY_DAMAGE_MAX)
    return round(value / 2)
end

function Stats:getAttack()
    return self:get(Tags.STAT_ATTACK_DAMAGE_MIN), self:get(Tags.STAT_ATTACK_DAMAGE_MAX)
end

function Stats:getEnemyAbility(multiplier)
    multiplier = multiplier or 1
    local minDamage = round(self:get(Tags.STAT_ABILITY_DAMAGE_MIN) * multiplier)
    local maxDamage = round(self:get(Tags.STAT_ABILITY_DAMAGE_MAX) * multiplier)
    return minDamage, maxDamage
end

return Stats

