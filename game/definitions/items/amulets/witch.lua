local Vector = require("utils.classes.vector")
local Array = require("utils.classes.array")
local COLORS = require("draw.colors")
local TRIGGERS = require("actions.triggers")
local ActionUtils = require("actions.utils")
local BUFFS = require("definitions.buffs")
local TERMS = require("text.terms")
local textStatFormat = require("text.stat_format")
local Common = require("common")
local ITEM = require("structures.amulet_def"):new("Witch's Amulet")
ITEM.className = "Witch"
ITEM.classSprite = Vector:new(18, 3)
ITEM.icon = Vector:new(17, 18)
ITEM:setToStatsBase({ [Tags.STAT_ABILITY_DAMAGE_BASE] = 4, [Tags.STAT_ABILITY_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.75), [Tags.STAT_ABILITY_VALUE] = 1, [Tags.STAT_ABILITY_AREA_ROUND] = Tags.ABILITY_AREA_CROSS })
local FORMAT_1 = "Increase {C:KEYWORD}Poison duration by %s turn, adding an extra health loss " .. "tick equal to the last."
local FORMAT_2 = "Whenever an enemy loses health from your {C:KEYWORD}Poison, enemies adjacent " .. "to it lose %s health."
ITEM.getPassiveDescription = function(item)
    return Array:new(textStatFormat(FORMAT_1, item, Tags.STAT_ABILITY_VALUE), textStatFormat(FORMAT_2, item, Tags.STAT_ABILITY_DAMAGE_MIN))
end
local PLAGUE = BUFFS:define("WITCH_PLAGUE", "POISON")
local TRIGGER = class(TRIGGERS.PRE_MOVE)
function TRIGGER:isEnabled()
    for direction in DIRECTIONS_AA() do
        local entityAt = self.entity.body:getEntityAt(self.moveTo + Vector[direction])
        if entityAt ~= self.entity and ActionUtils.isAliveAgent(entityAt) then
            return true
        end

    end

    return false
end

function PLAGUE:initialize(duration, sourceEntity, abilityStats)
    PLAGUE:super(self, "initialize", duration, sourceEntity, false)
    self.triggerClasses:push(TRIGGER)
    self.abilityStats = abilityStats
end

function PLAGUE:toDamageTicks(duration, damage)
    return false
end

function PLAGUE:getDataArgs()
    return self.duration, self.sourceEntity, self.abilityStats
end

function PLAGUE:toData(convertToData)
    return { expiresAtStart = self.expiresAtStart, damageTicks = convertToData(self.damageTicks) }
end

function PLAGUE:fromData(data, convertFromData)
    self.expiresAtStart = data.expiresAtStart
    self.damageTicks = convertFromData(data.damageTicks)
    if data.expiresAtStart then
        self.triggerClasses:clear()
    end

end

function PLAGUE:tick(anchor, entity)
    PLAGUE:super(self, "tick", anchor, entity)
    local area = self.abilityStats:get(Tags.STAT_ABILITY_AREA_ROUND)
    local source = entity.body:getPosition()
    for position in (ActionUtils.getAreaPositions(entity, source, area, true))() do
        local entityAt = entity.body:getEntityAt(position)
        if ActionUtils.isAliveAgent(entityAt) then
            local hit = self.sourceEntity.hitter:createHit()
            hit:setDamageFromAbilityStats(Tags.DAMAGE_TYPE_POISON, self.abilityStats)
            hit:applyToEntity(anchor, entityAt)
        end

    end

end

ITEM.decorateOutgoingHit = function(entity, hit, abilityStats)
    hit.buffs:mapSelf(function(buff)
        if BUFFS:get("POISON"):isInstance(buff) then
            local extend = abilityStats:get(Tags.STAT_ABILITY_VALUE)
            local result = PLAGUE:new(buff.duration, entity, abilityStats)
            result.damageTicks = buff.damageTicks
            if buff.expiresAtStart then
                result.expiresAtStart = true
                result.triggerClasses:clear()
            end

            for i = 1, extend do
                result:extendLast()
            end

            return result
        else
            return buff
        end

    end)
end
local LEGENDARY = ITEM:createLegendary("Soul of Corruption")
LEGENDARY.statLine = TERMS.LEGENDARY_AMULET_DESCRIPTION
LEGENDARY.strokeColor = COLORS.STANDARD_POISON
return ITEM

