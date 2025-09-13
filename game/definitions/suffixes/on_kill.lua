local Vector = require("utils.classes.vector")
local textStatFormat = require("text.stat_format")
local ModifierDef = require("structures.modifier_def")
local COLORS = require("draw.colors")
local Common = require("common")
local ActionUtils = require("actions.utils")
local TRIGGERS = require("actions.triggers")
local REVELATION = ModifierDef:new("Revelation")
local REVELATION_FORMAT = "Whenever you kill an enemy, reduce this ability's cooldown by %s turns."
REVELATION:setToStatsBase({ [Tags.STAT_MODIFIER_VALUE] = 2 })
REVELATION.statLine = function(item)
    return textStatFormat(REVELATION_FORMAT, item, Tags.STAT_MODIFIER_VALUE)
end
REVELATION.canRoll = function(itemDef)
    return itemDef:getStatAtMax(Tags.STAT_ABILITY_COOLDOWN) >= 3 or itemDef.ability:hasTag(Tags.ABILITY_TAG_DYNAMIC_COOLDOWN)
end
local REVELATION_TRIGGER = class(TRIGGERS.ON_KILL)
function REVELATION_TRIGGER:process(currentEvent)
    local equipment = self.entity.equipment
    local value = self.abilityStats:get(Tags.STAT_MODIFIER_VALUE)
    equipment:reduceCooldown(self.abilityStats:get(Tags.STAT_SLOT), value)
    return currentEvent
end

function REVELATION_TRIGGER:isEnabled()
    return self.killed:hasComponent("agent")
end

REVELATION.modifyItem = function(item)
    item.triggers:push(REVELATION_TRIGGER)
end
local MALEFICE = ModifierDef:new("Malefice")
local MALEFICE_FORMAT = "{C:KEYWORD}Chance on kill to deal %s damage to another enemy around the target."
MALEFICE:setToStatsBase({ [Tags.STAT_MODIFIER_DAMAGE_BASE] = 12, [Tags.STAT_MODIFIER_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.48) })
MALEFICE.statLine = function(item)
    return textStatFormat(MALEFICE_FORMAT, item, Tags.STAT_MODIFIER_DAMAGE_MIN)
end
MALEFICE.canRoll = function(itemDef)
    return itemDef.slot ~= Tags.SLOT_BOOTS
end
local MALEFICE_DELAY = 0.13
local MALEFICE_TRIGGER = class(TRIGGERS.ON_KILL)
function MALEFICE_TRIGGER:initialize(entity, direction, abilityStats)
    MALEFICE_TRIGGER:super(self, "initialize", entity, direction, abilityStats)
    self.activationType = Tags.TRIGGER_CHANCE
    self:addComponent("lightningspawner")
    self.lightningspawner.lightningCount = 2
    self.lightningspawner.color = COLORS.STANDARD_DEATH_BRIGHTER
end

function MALEFICE_TRIGGER:isEnabled()
    return self.killed:hasComponent("agent")
end

function MALEFICE_TRIGGER:process(currentEvent)
    local body = self.entity.body
    for direction in (DIRECTIONS:shuffle(self:getLogicRNG()))() do
        local target = self.position + Vector[direction]
        local entityAt = body:getEntityAt(target)
        if ActionUtils.isAliveAgent(entityAt) then
            currentEvent = currentEvent:chainProgress(MALEFICE_DELAY):chainEvent(function()
                Common.playSFX("LIGHTNING", 1.5, 0.75)
            end)
            return self.lightningspawner:spawn(currentEvent, target, self.position):chainEvent(function(_, anchor)
                local hit = self.entity.hitter:createHit()
                hit:setDamageFromModifierStats(Tags.DAMAGE_TYPE_SPELL, self.abilityStats)
                hit:applyToEntity(anchor, entityAt, target)
            end)
        end

    end

    return currentEvent
end

MALEFICE.modifyItem = function(item)
    item.triggers:push(MALEFICE_TRIGGER)
end
local ENDURANCE = ModifierDef:new("Endurance")
local ENDURANCE_FORMAT = "Extend this ability's duration by %s turn whenever you kill an enemy."
ENDURANCE:setToStatsBase({ [Tags.STAT_MODIFIER_VALUE] = 1 })
ENDURANCE.abilityExtraLine = function(item)
    return textStatFormat(ENDURANCE_FORMAT, item, Tags.STAT_MODIFIER_VALUE)
end
ENDURANCE.canRoll = function(itemDef)
    local ability = itemDef.ability
        if ability:hasTag(Tags.ABILITY_TAG_BUFF_NO_EXTEND) then
        return false
    elseif itemDef.statsBase:get(Tags.STAT_ABILITY_SUSTAIN_MODE, 0) > 0 then
        return itemDef.ability:hasTag(Tags.ABILITY_TAG_SUSTAIN_CAN_KILL)
    else
        return itemDef.statsBase:get(Tags.STAT_ABILITY_BUFF_DURATION, 0) > 1
    end

end
local ENDURANCE_TRIGGER = class(TRIGGERS.ON_KILL)
function ENDURANCE_TRIGGER:isEnabled()
    return self.killed:hasComponent("agent") and self.entity.equipment:isSlotActive(self:getSlot())
end

function ENDURANCE_TRIGGER:process(currentEvent)
    self.entity.equipment:extendSlotBuff(self:getSlot(), self.abilityStats:get(Tags.STAT_MODIFIER_VALUE))
    return currentEvent
end

ENDURANCE.modifyItem = function(item)
    item.triggers:push(ENDURANCE_TRIGGER)
end
return { REVELATION = REVELATION, MALEFICE = MALEFICE, ENDURANCE = ENDURANCE }

