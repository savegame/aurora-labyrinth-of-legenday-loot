local Set = require("utils.classes.set")
local Vector = require("utils.classes.vector")
local Common = require("common")
local CONSTANTS = require("logic.constants")
local ActionUtils = require("actions.utils")
local TRIGGERS = require("actions.triggers")
local PLAYER_COMMON = require("actions.player_common")
local COLORS = require("draw.colors")
local TERMS = require("text.terms")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.item_def"):new("Clockwork Treads")
local ABILITY = require("structures.ability_def"):new("Rewind")
ABILITY:addTag(Tags.ABILITY_TAG_IMMOBILIZED_DISABLED)
ITEM.ability = ABILITY
ITEM.slot = Tags.SLOT_BOOTS
ITEM.icon = Vector:new(10, 19)
ITEM:setToStatsBase({ [Tags.STAT_MAX_HEALTH] = 22, [Tags.STAT_MAX_MANA] = 18, [Tags.STAT_ABILITY_POWER] = 1.75, [Tags.STAT_ABILITY_COUNT] = 3, [Tags.STAT_ABILITY_QUICK] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
local DESCRIPTION = "Teleport to your position %s turns ago, if it's visible. {C:KEYWORD}Quick."
ABILITY.getDescription = function(item)
    return textStatFormat(DESCRIPTION, item, Tags.STAT_ABILITY_COUNT)
end
local INVALID_POSITION_BLOCKED = "Target position is blocked."
local INVALID_NEEDS_3_TURNS = "Can't be used until it's been worn after 3 turns."
local INVALID_POSITION_INVISIBLE = "Target position is not visible."
ABILITY.icon = Vector:new(1, 11)
ABILITY.iconColor = COLORS.STANDARD_LIGHTNING
local function getMoveTo(entity, direction, abilityStats)
    local slot = abilityStats:get(Tags.STAT_SLOT)
    local x = entity.equipment:getTempStatBonus(slot, Tags.STAT_POSITION_4_X)
    if x > 0 then
        local y = entity.equipment:getTempStatBonus(slot, Tags.STAT_POSITION_4_Y)
        local target = Vector:new(x, y)
                if not entity.vision:isVisible(target) then
            return false, INVALID_POSITION_INVISIBLE
        elseif not entity.body:isPassable(target) then
            return target, INVALID_POSITION_BLOCKED
        end

        return target, false
    else
        return false, INVALID_NEEDS_3_TURNS
    end

end

ABILITY.getInvalidReason = function(entity, direction, abilityStats)
    local moveTo, reason = getMoveTo(entity, direction, abilityStats)
    if reason then
        return reason
    else
        return false
    end

end
ABILITY.indicate = function(entity, direction, abilityStats, castingGuide)
    local moveTo = getMoveTo(entity, direction, abilityStats)
    if moveTo then
        castingGuide:indicateMoveTo(moveTo)
    end

end
ABILITY.directions = false
local ACTION = class(PLAYER_COMMON.TELEPORT)
ABILITY.actionClass = ACTION
function ACTION:initialize(entity, direction, abilityStats)
    ACTION:super(self, "initialize", entity, direction, abilityStats)
    self.outline.color = ABILITY.iconColor
end

function ACTION:parallelResolve(anchor)
    self.moveTo = getMoveTo(self.entity, self.direction, self.abilityStats)
end

local SAVE_POSITION = class(TRIGGERS.START_OF_TURN)
function SAVE_POSITION:process(currentEvent)
    local slot = self.abilityStats:get(Tags.STAT_SLOT)
    local position = self.entity.body:getPosition()
    local equipment = self.entity.equipment
    local x3 = equipment:getTempStatBonus(slot, Tags.STAT_POSITION_3_X)
    local y3 = equipment:getTempStatBonus(slot, Tags.STAT_POSITION_3_Y)
    if x3 > 0 then
        equipment:setTempStatBonus(slot, Tags.STAT_POSITION_4_X, x3)
        equipment:setTempStatBonus(slot, Tags.STAT_POSITION_4_Y, y3)
    end

    local x2 = equipment:getTempStatBonus(slot, Tags.STAT_POSITION_2_X)
    local y2 = equipment:getTempStatBonus(slot, Tags.STAT_POSITION_2_Y)
    if x2 > 0 then
        equipment:setTempStatBonus(slot, Tags.STAT_POSITION_3_X, x2)
        equipment:setTempStatBonus(slot, Tags.STAT_POSITION_3_Y, y2)
    end

    local x1 = equipment:getTempStatBonus(slot, Tags.STAT_POSITION_X)
    local y1 = equipment:getTempStatBonus(slot, Tags.STAT_POSITION_Y)
    if x1 > 0 then
        equipment:setTempStatBonus(slot, Tags.STAT_POSITION_2_X, x1)
        equipment:setTempStatBonus(slot, Tags.STAT_POSITION_2_Y, y1)
    end

    equipment:setTempStatBonus(slot, Tags.STAT_POSITION_X, position.x)
    equipment:setTempStatBonus(slot, Tags.STAT_POSITION_Y, position.y)
    return currentEvent
end

ITEM.triggers:push(SAVE_POSITION)
local LEGENDARY = ITEM:createLegendary("Treads of Paradox")
LEGENDARY.modifyItem = function(item)
    item:multiplyStatAndGrowth(Tags.STAT_ABILITY_MANA_COST, 0)
    item:markAltered(Tags.STAT_ABILITY_MANA_COST, Tags.STAT_UPGRADED)
end
return ITEM

