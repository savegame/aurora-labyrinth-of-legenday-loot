local Vector = require("utils.classes.vector")
local Array = require("utils.classes.array")
local Common = require("common")
local CONSTANTS = require("logic.constants")
local COLORS = require("draw.colors")
local textStatFormat = require("text.stat_format")
local ACTIONS_FRAGMENT = require("actions.fragment")
local TRIGGERS = require("actions.triggers")
local ITEM = require("structures.item_def"):new("Cascade Ring")
ITEM.slot = Tags.SLOT_RING
ITEM.icon = Vector:new(16, 17)
ITEM:setToStatsBase({ [Tags.STAT_ABILITY_DAMAGE_BASE] = 12.2, [Tags.STAT_ABILITY_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.25), [Tags.STAT_ABILITY_PROJECTILE_SPEED] = CONSTANTS.PLAYER_PROJECTILE_SPEED })
local FORMAT = "Your {C:KEYWORD}Attacks create "
local FORMAT_NORMAL = "a {C:KEYWORD}Projectile behind the target that deals %s damage."
local FORMAT_LEGENDARY = "%s {C:KEYWORD}Projectiles behind the target that deal %s damage each."
ITEM.getPassiveDescription = function(item)
    if item.stats:get(Tags.STAT_LEGENDARY, 0) > 0 then
        return textStatFormat(FORMAT .. FORMAT_LEGENDARY, item, Tags.STAT_MODIFIER_VALUE, Tags.STAT_ABILITY_DAMAGE_MIN)
    else
        return textStatFormat(FORMAT .. FORMAT_NORMAL, item, Tags.STAT_ABILITY_DAMAGE_MIN)
    end

end
local ON_HIT = class(ACTIONS_FRAGMENT.EXPLOSIVE_HIT)
function ON_HIT:initialize(entity, direction, abilityStats)
    ON_HIT:super(self, "initialize", entity, direction, abilityStats)
    self.explosion:setHueToArcane()
end

function ON_HIT:parallelResolve(anchor)
    ON_HIT:super(self, "parallelResolve", anchor)
    self.hit:setDamageFromAbilityStats(Tags.DAMAGE_TYPE_SPELL, self.abilityStats)
end

local TRIGGER = class(TRIGGERS.ON_DAMAGE)
function TRIGGER:isEnabled()
    return (self.hit.damageType == Tags.DAMAGE_TYPE_MELEE and self.hit:isDamagePositive())
end

function TRIGGER:process(currentEvent)
    local directions = Array:new(self.direction)
    if self.abilityStats:get(Tags.STAT_LEGENDARY, 0) > 0 then
        directions = Array:new(ccwDirection(self.direction, 1), self.direction, cwDirection(self.direction, 1))
    end

    local lastEvent = currentEvent
    for direction in directions() do
        lastEvent, projectileEntity = self.entity.projectilespawner:spawn(currentEvent, direction, self.abilityStats, Vector:new(1, 2), true)
        projectileEntity.projectile.position = self.hit.targetEntity.body:getPosition()
    end

    return lastEvent
end

ITEM.triggers:push(TRIGGER)
local LEGENDARY = ITEM:createLegendary("Luminarius")
LEGENDARY.strokeColor = COLORS.STANDARD_PSYCHIC
LEGENDARY:setToStatsBase({ [Tags.STAT_MODIFIER_VALUE] = 3 })
LEGENDARY.modifyItem = function(item)
    item:markAltered(Tags.STAT_MODIFIER_VALUE, Tags.STAT_UPGRADED)
end
return ITEM

