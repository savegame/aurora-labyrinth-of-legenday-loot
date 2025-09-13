local EnemyDef = class()
local ELITES = require("definitions.elites")
local Hash = require("utils.classes.hash")
local Array = require("utils.classes.array")
local CONSTANTS = require("logic.constants")
function EnemyDef:initialize(id, data)
    self.id = id
    self.minFloor = data.minFloor
    self.frequency = data.frequency or 1
    self.count = data.count or 1
    self.stats = Hash:new()
    self.bannedElites = data.bannedElites or Array.EMPTY
    self:setStatsFromData(data)
end

function EnemyDef:isEliteIDBanned(eliteID)
    return self.bannedElites:contains(eliteID)
end

function EnemyDef:setStatsFromData(data)
    self.stats:set(Tags.STAT_MAX_HEALTH, round(data.health * (CONSTANTS.ENEMY_HEALTH_BASE + self.minFloor * CONSTANTS.ENEMY_HEALTH_PER_FLOOR)))
    local baseDamage = (data.damage * (CONSTANTS.ENEMY_DAMAGE_BASE + self.minFloor * CONSTANTS.ENEMY_DAMAGE_PER_FLOOR))
    local damageMin = round(baseDamage * (1 - CONSTANTS.ENEMY_DAMAGE_VARIANCE) - 0.01)
    local damageMax = round(baseDamage * (1 + CONSTANTS.ENEMY_DAMAGE_VARIANCE) + 0.01)
    self.stats:set(Tags.STAT_ATTACK_DAMAGE_MIN, damageMin)
    self.stats:set(Tags.STAT_ATTACK_DAMAGE_MAX, damageMax)
    if data.ability then
        local baseAbility = baseDamage * data.ability
        local abilityMin = round(baseAbility * (1 - CONSTANTS.ENEMY_ABILITY_VARIANCE) - 0.01)
        local abilityMax = round(baseAbility * (1 + CONSTANTS.ENEMY_ABILITY_VARIANCE) + 0.01)
        self.stats:set(Tags.STAT_ABILITY_DAMAGE_MIN, abilityMin)
        self.stats:set(Tags.STAT_ABILITY_DAMAGE_MAX, abilityMax)
    end

end

return EnemyDef

