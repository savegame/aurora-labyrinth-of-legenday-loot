local Vector = require("utils.classes.vector")
local Common = require("common")
local COLORS = require("draw.colors")
local EASING = require("draw.easing")
local ATTACK_WEAPON = require("actions.attack_weapon")
local ACTION_CONSTANTS = require("actions.constants")
local PLAYER_COMMON = require("actions.player_common")
local CONSTANTS = require("logic.constants")
local ActionUtils = require("actions.utils")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.item_def"):new("Sword")
local ABILITY = require("structures.ability_def"):new("Cleave")
ITEM.minFloor = CONSTANTS.MAX_FLOORS * 2
ITEM.disableUpgrade = true
ITEM.slot = Tags.SLOT_WEAPON
ITEM.icon = Vector:new(11, 10)
ITEM.attackClass = ATTACK_WEAPON.SWING_AND_DAMAGE
ITEM:setToStatsBase({ [Tags.STAT_ATTACK_DAMAGE_BASE] = 17, [Tags.STAT_ATTACK_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.5), [Tags.STAT_VIRTUAL_RATIO] = 0.5, [Tags.STAT_ABILITY_POWER] = 2, [Tags.STAT_ABILITY_DAMAGE_BASE] = 23, [Tags.STAT_ABILITY_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.5), [Tags.STAT_ABILITY_AREA_CLEAVE] = 3 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_AREA_CLEAVE] = 2 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_AREA_CLEAVE] = 2 })
local FORMAT = "Deal %s damage to %s."
ABILITY.getDescription = function(item)
    return textStatFormat(FORMAT, item, Tags.STAT_ABILITY_DAMAGE_MIN, Tags.STAT_ABILITY_AREA_CLEAVE)
end
ABILITY.icon = Vector:new(2, 7)
ABILITY.iconColor = COLORS.STANDARD_STEEL
ABILITY.indicate = function(entity, direction, abilityStats, castingGuide)
    local source = entity.body:getPosition()
    local area = abilityStats:get(Tags.STAT_ABILITY_AREA_CLEAVE)
    for position in (ActionUtils.getCleavePositions(source, area, direction))() do
        castingGuide:indicate(position)
    end

end
ABILITY.actionClass = PLAYER_COMMON.WEAPON_CLEAVE
return ITEM

