local Vector = require("utils.classes.vector")
local Color = require("utils.classes.color")
local Common = require("common")
local CONSTANTS = require("logic.constants")
local ActionUtils = require("actions.utils")
local ACTION_CONSTANTS = require("actions.constants")
local PLAYER_COMMON = require("actions.player_common")
local COLORS = require("draw.colors")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.item_def"):new("Conflagration Hat")
local ABILITY = require("structures.ability_def"):new("Conflagration Beam")
ABILITY:addTag(Tags.ABILITY_TAG_BOOSTABLE_ABILITY_DAMAGE)
ITEM.ability = ABILITY
ITEM.slot = Tags.SLOT_HELM
ITEM.icon = Vector:new(4, 18)
ITEM:setToStatsBase({ [Tags.STAT_MAX_HEALTH] = 8, [Tags.STAT_MAX_MANA] = 32, [Tags.STAT_ABILITY_POWER] = 6.0, [Tags.STAT_ABILITY_DAMAGE_BASE] = 32.6, [Tags.STAT_ABILITY_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.68), [Tags.STAT_SECONDARY_DAMAGE_BASE] = 16.3, [Tags.STAT_SECONDARY_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.68), [Tags.STAT_ABILITY_BURN_DURATION] = 5 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_BURN_DURATION] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_BURN_DURATION] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
local FORMAT = "Deal %s damage to all targets in a line in front of you. {FORCE_NEWLINE} "
local FORMAT_NORMAL = "%s, %s health lost per turn."
local FORMAT_LEGENDARY = "{C:KEYWORD}Burn - {C:UPGRADED}Infinite turns, %s health lost per turn."
ABILITY.getDescription = function(item)
    local burnDuration = item.stats:get(Tags.STAT_ABILITY_BURN_DURATION)
    return textStatFormat(FORMAT .. FORMAT_NORMAL, item, Tags.STAT_ABILITY_DAMAGE_MIN, Tags.STAT_ABILITY_BURN_DURATION, Tags.STAT_SECONDARY_DAMAGE_MIN)
end
ABILITY.icon = Vector:new(6, 10)
ABILITY.iconColor = COLORS.STANDARD_FIRE
ABILITY.getInvalidReason = ActionUtils.getInvalidReasonFrontCantBePassable
ABILITY.indicate = function(entity, direction, abilityStats, castingGuide)
    local target = entity.body:getPosition() + Vector[direction]
    while entity.body:canBePassable(target) do
        castingGuide:indicate(target)
        target = target + Vector[direction]
    end

end
local BEAM_COLOR = Color:new(1, 0.5, 0.25)
local ACTION = class(PLAYER_COMMON.BEAM)
ABILITY.actionClass = ACTION
function ACTION:initialize(entity, direction, abilityStats)
    ACTION:super(self, "initialize", entity, direction, abilityStats)
    self.color = ABILITY.iconColor
    self.beamColor = BEAM_COLOR
end

function ACTION:hitTarget(anchor, target)
    if not self.entity.body:canBePassable(target) then
        self.entity.entityspawner:spawn("temporary_vision", target)
    else
        local hit = self.entity.hitter:createHit()
        hit:setDamageFromAbilityStats(Tags.DAMAGE_TYPE_SPELL, self.abilityStats)
        hit:setSpawnFireFromSecondary(self.abilityStats)
        if hit.spawnFire.duration >= CONSTANTS.PRESUMED_INFINITE then
            hit.spawnFire.duration = math.huge
        end

        hit:applyToPosition(anchor, target)
    end

end

local LEGENDARY = ITEM:createLegendary("The Eternal Flame")
LEGENDARY:setToStatsBase({ [Tags.STAT_ABILITY_BURN_DURATION] = CONSTANTS.PRESUMED_INFINITE })
local LEGENDARY_BONUS = 0.2
LEGENDARY.modifyItem = function(item)
    item:markAltered(Tags.STAT_ABILITY_BURN_DURATION, Tags.STAT_UPGRADED)
    item:markAltered(Tags.STAT_SECONDARY_DAMAGE_MIN, Tags.STAT_UPGRADED)
    item:markAltered(Tags.STAT_SECONDARY_DAMAGE_MAX, Tags.STAT_UPGRADED)
    item:multiplyStatAndGrowth(Tags.STAT_SECONDARY_DAMAGE_MIN, 1 + LEGENDARY_BONUS)
    item:multiplyStatAndGrowth(Tags.STAT_SECONDARY_DAMAGE_MAX, 1 + LEGENDARY_BONUS)
end
return ITEM

