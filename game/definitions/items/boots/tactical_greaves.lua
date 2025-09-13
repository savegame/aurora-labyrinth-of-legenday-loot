local Set = require("utils.classes.set")
local Vector = require("utils.classes.vector")
local BUFFS = require("definitions.buffs")
local ActionUtils = require("actions.utils")
local ACTIONS_FRAGMENT = require("actions.fragment")
local TRIGGERS = require("actions.triggers")
local COLORS = require("draw.colors")
local TERMS = require("text.terms")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.item_def"):new("Tactical Greaves")
local ABILITY = require("structures.ability_def"):new("Tactical Shift")
ABILITY:addTag(Tags.ABILITY_TAG_MOVEMENT_EXTENDABLE)
ABILITY:addTag(Tags.ABILITY_TAG_IMMOBILIZED_DISABLED)
ITEM.ability = ABILITY
ITEM.slot = Tags.SLOT_BOOTS
ITEM.icon = Vector:new(2, 19)
ITEM:setToStatsBase({ [Tags.STAT_MAX_HEALTH] = 32, [Tags.STAT_MAX_MANA] = 8, [Tags.STAT_ABILITY_POWER] = 1.6, [Tags.STAT_ABILITY_QUICK] = 1, [Tags.STAT_ABILITY_RANGE] = 1 })
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
local FORMAT = "Move %s. {C:KEYWORD}Quick."
ABILITY.getDescription = function(item)
    return textStatFormat(FORMAT, item, Tags.STAT_ABILITY_RANGE)
end
ABILITY.icon = Vector:new(4, 4)
ABILITY.iconColor = COLORS.STANDARD_STEEL
ABILITY.getInvalidReason = ActionUtils.getInvalidReasonFrontIsNotPassable
ABILITY.indicate = function(entity, direction, abilityStats, castingGuide)
    local moveTo = ActionUtils.getDashMoveTo(entity, direction, abilityStats)
    if moveTo and moveTo ~= entity.body:getPosition() then
        castingGuide:indicateMoveTo(moveTo)
    end

end
local ACTION = class(ACTIONS_FRAGMENT.TRAIL_MOVE)
ABILITY.actionClass = ACTION
function ACTION:parallelResolve(currentEvent)
    if self.abilityStats:get(Tags.STAT_ABILITY_RANGE) == 2 then
        local body = self.entity.body
        if body:isPassable(body:getPosition() + Vector[self.direction] * 2) then
            self.distance = 2
            self.stepDuration = self.stepDuration * 0.8
        end

    end

    return ACTION:super(self, "parallelResolve", currentEvent)
end

local LEGENDARY = ITEM:createLegendary("Duelist's Footwork")
LEGENDARY:setToStatsBase({ [Tags.STAT_ABILITY_MANA_COST] = -10, [Tags.STAT_ABILITY_COOLDOWN] = -1 })
LEGENDARY.abilityExtraLine = "Can be cast multiple times in a turn without cooling down."
local LEGENDARY_TRIGGER = class(TRIGGERS.ON_SLOT_DEACTIVATE)
local COOLDOWNER = BUFFS:define("QUICK_STEP_COOLDOWNER")
function COOLDOWNER:initialize()
    COOLDOWNER:super(self, "initialize", 1)
    self.expiresImmediately = true
end

function COOLDOWNER:onExpire(anchor, entity)
    entity.equipment:setOnCooldown(Tags.SLOT_BOOTS, 1)
end

function LEGENDARY_TRIGGER:isEnabled()
    return self.triggeringSlot == self:getSlot()
end

function LEGENDARY_TRIGGER:process(currentEvent)
    self.entity.equipment:resetCooldown(self.triggeringSlot)
    self.entity.buffable:forceApply(COOLDOWNER:new())
    return currentEvent
end

LEGENDARY.modifyItem = function(item)
    item:markAltered(Tags.STAT_ABILITY_MANA_COST, Tags.STAT_UPGRADED)
    item.triggers:push(LEGENDARY_TRIGGER)
end
return ITEM

