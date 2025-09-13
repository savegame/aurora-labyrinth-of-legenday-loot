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
local ITEM = require("structures.item_def"):new("Portal Boots")
local ABILITY = require("structures.ability_def"):new("Teleport")
ABILITY:addTag(Tags.ABILITY_TAG_IMMOBILIZED_DISABLED)
ITEM.ability = ABILITY
ITEM.slot = Tags.SLOT_BOOTS
ITEM.icon = Vector:new(14, 15)
ITEM:setToStatsBase({ [Tags.STAT_MAX_HEALTH] = 4, [Tags.STAT_MAX_MANA] = 36, [Tags.STAT_ABILITY_POWER] = 1.75, [Tags.STAT_ABILITY_RANGE] = 3 })
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
local DESCRIPTION = "Teleport exactly %s forward."
local IS_QUICK = " {C:UPGRADED}Quick."
ABILITY.getDescription = function(item)
    local description = textStatFormat(DESCRIPTION, item, Tags.STAT_ABILITY_RANGE)
    if item.stats:get(Tags.STAT_ABILITY_QUICK, 0) > 0 then
        description = description .. IS_QUICK
    end

    return description
end
ABILITY.icon = Vector:new(12, 8)
ABILITY.iconColor = COLORS.STANDARD_PSYCHIC
local function getMoveTo(entity, direction, abilityStats)
    local source = entity.body:getPosition()
    local distance = abilityStats:get(Tags.STAT_ABILITY_RANGE)
    local target = source + Vector[direction] * distance
    if entity.body:isPassable(target) and entity.vision:isVisible(target) then
        return target
    else
        return false
    end

end

ABILITY.getInvalidReason = function(entity, direction, abilityStats)
    local moveTo = getMoveTo(entity, direction, abilityStats)
    if moveTo then
        return false
    else
        return TERMS.INVALID_DIRECTION_BLOCKED
    end

end
ABILITY.indicate = function(entity, direction, abilityStats, castingGuide)
    local moveTo = getMoveTo(entity, direction, abilityStats)
    if moveTo then
        castingGuide:indicateMoveTo(moveTo)
    end

end
local ACTION = class(PLAYER_COMMON.TELEPORT)
ABILITY.actionClass = ACTION
function ACTION:initialize(entity, direction, abilityStats)
    ACTION:super(self, "initialize", entity, direction, abilityStats)
end

function ACTION:parallelResolve(anchor)
    self.moveTo = getMoveTo(self.entity, self.direction, self.abilityStats)
end

local LEGENDARY = ITEM:createLegendary("Unstable Continuum")
LEGENDARY:setToStatsBase({ [Tags.STAT_ABILITY_QUICK] = 1 })
LEGENDARY.statLine = "{C:KEYWORD}Chance before you are hit by a {C:KEYWORD}Melee " .. "{C:KEYWORD}Attack to teleport {C:NUMBER}2 spaces away in a random direction."
local LEGENDARY_TRIGGER = class(TRIGGERS.PRE_HIT)
function LEGENDARY_TRIGGER:initialize(entity, direction, abilityStats)
    LEGENDARY_TRIGGER:super(self, "initialize", entity, direction, abilityStats)
    self.activationType = Tags.TRIGGER_CHANCE
    self.abilityStats = self.abilityStats:clone()
    self.abilityStats:set(Tags.STAT_ABILITY_RANGE, 2)
    self.abilityStats:deleteKeyIfExists(Tags.STAT_LEGENDARY)
end

function LEGENDARY_TRIGGER:isEnabled()
    if not self.entity.buffable:canMove() then
        return false
    end

    if self.hit.damageType == Tags.DAMAGE_TYPE_MELEE and self.hit:isDamagePositive() then
        local directionTo = Common.getDirectionTowards(self.entity.body:getPosition(), self.hit.sourcePosition)
        for direction in DIRECTIONS_AA() do
            if direction ~= directionTo then
                if getMoveTo(self.entity, direction, self.abilityStats) then
                    return true
                end

            end

        end

    end

    return false
end

function LEGENDARY_TRIGGER:parallelResolve(anchor)
    self.hit:clear()
    self.hit.sound = false
end

function LEGENDARY_TRIGGER:process(currentEvent)
    local directions = DIRECTIONS_AA:shuffle(self:getLogicRNG())
    directions:delete(Common.getDirectionTowards(self.entity.body:getPosition(), self.hit.sourcePosition))
    for direction in directions() do
        local moveTo = getMoveTo(self.entity, direction, self.abilityStats)
        if moveTo then
            local teleportAction = self.entity.actor:create(ABILITY.actionClass, direction, self.abilityStats)
            return teleportAction:parallelChainEvent(currentEvent)
        end

    end

    return currentEvent
end

LEGENDARY.modifyItem = function(item)
    item.triggers:push(LEGENDARY_TRIGGER)
end
return ITEM

