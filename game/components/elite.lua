local Elite = require("components.create_class")()
local ACTIONS_BASIC = require("actions.basic")
local ACTIONS_FRAGMENT = require("actions.fragment")
local ACTION_CONSTANTS = require("actions.constants")
local CONSTANTS = require("logic.constants")
local COLORS = require("draw.colors")
local ELITES = require("definitions.elites")
local BUFFS = require("definitions.buffs")
local function multiplyStat(entity, stat, multiplier)
    local value = ceil(entity.stats:get(stat) * multiplier)
    entity.stats:set(stat, value)
end

function Elite:initialize(entity, eliteID)
    Elite:super(self, "initialize", entity)
    self._entity = entity
    self.eliteID = eliteID
    local healthMultiplier = CONSTANTS.ELITE_HEALTH_MULTIPLIER
    local damageMultiplier = CONSTANTS.ELITE_DAMAGE_MULTIPLIER
    local eliteData = ELITES.BY_ID:get(eliteID)
    entity.sprite.strokeColor = eliteData.color
    entity.buffable:apply(BUFFS:get(eliteID):new(math.huge))
    damageMultiplier = damageMultiplier * (eliteData.damageMultiplier or 1)
    healthMultiplier = healthMultiplier * (eliteData.healthMultiplier or 1)
    multiplyStat(entity, Tags.STAT_MAX_HEALTH, healthMultiplier)
    entity.tank:restoreToFull()
    multiplyStat(entity, Tags.STAT_ATTACK_DAMAGE_MIN, damageMultiplier)
    multiplyStat(entity, Tags.STAT_ATTACK_DAMAGE_MAX, damageMultiplier)
    multiplyStat(entity, Tags.STAT_ABILITY_DAMAGE_MIN, damageMultiplier)
    multiplyStat(entity, Tags.STAT_ABILITY_DAMAGE_MAX, damageMultiplier)
end

function Elite:fixMovementSlow()
    local movementSlow = self._entity.stats:get(Tags.STAT_MOVEMENT_SLOW)
    if movementSlow > 0 then
        if self._entity.buffable:isAffectedBy(BUFFS:get("HASTE")) then
            self._entity.buffable:delete(false, BUFFS:get("HASTE"))
            self._entity.stats:set(Tags.STAT_MOVEMENT_SLOW, movementSlow - 1)
        end

    end

end

return Elite

