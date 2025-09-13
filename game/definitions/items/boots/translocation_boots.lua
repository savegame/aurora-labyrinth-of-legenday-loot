local Vector = require("utils.classes.vector")
local Array = require("utils.classes.array")
local Common = require("common")
local CONSTANTS = require("logic.constants")
local ActionUtils = require("actions.utils")
local ACTIONS_FRAGMENT = require("actions.fragment")
local PLAYER_COMMON = require("actions.player_common")
local TRIGGERS = require("actions.triggers")
local ACTION_CONSTANTS = require("actions.constants")
local BUFFS = require("definitions.buffs")
local COLORS = require("draw.colors")
local TERMS = require("text.terms")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.item_def"):new("Translocation Boots")
local ABILITY = require("structures.ability_def"):new("Translocate")
ABILITY:addTag(Tags.ABILITY_TAG_MOVEMENT_EXTENDABLE)
ABILITY:addTag(Tags.ABILITY_TAG_DIRECTIONAL_RECASTABLE)
ITEM.ability = ABILITY
ITEM.slot = Tags.SLOT_BOOTS
ITEM.icon = Vector:new(15, 21)
ITEM:setToStatsBase({ [Tags.STAT_MAX_MANA] = 40, [Tags.STAT_ABILITY_POWER] = 1.6, [Tags.STAT_SECONDARY_RANGE] = 2 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_SECONDARY_RANGE] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_SECONDARY_RANGE] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
local FORMAT = "Teleport an adjacent enemy up to %s away."
ABILITY.getDescription = function(item)
    return textStatFormat(FORMAT, item, Tags.STAT_SECONDARY_RANGE)
end
ABILITY.icon = Vector:new(1, 7)
ABILITY.iconColor = COLORS.STANDARD_PSYCHIC
local function getMoveTo(entity, targetEntity, direction, abilityStats)
    local body = entity.body
    local range = abilityStats:get(Tags.STAT_SECONDARY_RANGE) + 1
    if isDiagonal(direction) then
        range = round((range - 1) / math.sqrtOf2) + 1
    end

    local source = body:getPosition()
    for i = range, 2, -1 do
        local target = source + Vector[direction] * i
        if entity.vision:isVisible(target) and body:isPassable(target) then
            return target
        end

    end

    return false
end

ABILITY.getInvalidReason = function(entity, direction, abilityStats)
    local enemy, isBlocked = ActionUtils.getEnemyWithinRange(entity, direction, abilityStats)
        if isBlocked then
        return TERMS.INVALID_DIRECTION_BLOCKED
    elseif not enemy then
        return TERMS.INVALID_DIRECTION_NO_ENEMY
    else
        if not getMoveTo(entity, enemy, direction, abilityStats) then
            return TERMS.INVALID_DIRECTION_BLOCKED
        else
            return false
        end

    end

end
ABILITY.indicate = function(entity, direction, abilityStats, castingGuide)
    local targetEntity = ActionUtils.indicateEnemyWithinRange(entity, direction, abilityStats, castingGuide)
    local moveTo = false
    if targetEntity then
        moveTo = getMoveTo(entity, targetEntity, direction, abilityStats)
    end

        if moveTo then
        castingGuide:indicate(moveTo)
    elseif targetEntity then
        castingGuide:indicateWeak(targetEntity.body:getPosition())
    end

end
local ACTION = class(ACTIONS_FRAGMENT.CAST)
ABILITY.actionClass = ACTION
function ACTION:initialize(entity, direction, abilityStats)
    ACTION:super(self, "initialize", entity, direction, abilityStats)
    self.color = ABILITY.iconColor
end

function ACTION:process(currentEvent)
    currentEvent = ACTION:super(self, "process", currentEvent)
    local lastEvent = currentEvent
    local direction = self.direction
    local targetEntity = self.entity.body:getEntityAt(self.entity.body:getPosition() + Vector[direction])
    if targetEntity and targetEntity:hasComponent("agent") then
        local moveTo = getMoveTo(self.entity, targetEntity, direction, self.abilityStats)
        if moveTo then
            lastEvent = currentEvent:chainEvent(function()
                targetEntity.tank.drawBar = false
            end)
            local teleportAction = targetEntity.actor:create(PLAYER_COMMON.TELEPORT, reverseDirection(direction))
            teleportAction.moveTo = moveTo
            lastEvent = teleportAction:parallelChainEvent(lastEvent):chainEvent(function()
                targetEntity.tank.drawBar = true
                targetEntity.buffable:apply(BUFFS:get("IMMOBILIZE_HIDDEN"):new(1))
            end)
        end

    end

    return lastEvent
end

local LEGENDARY = ITEM:createLegendary("Boots of the Timeless Realm")
local LEGENDARY_EXTRA_LINE = "If there is still an adjacent enemy after casting, restore %s mana and take another turn."
LEGENDARY:setToStatsBase({ [Tags.STAT_MODIFIER_DAMAGE_BASE] = 60, [Tags.STAT_MODIFIER_DAMAGE_VARIANCE] = 0 })
LEGENDARY:setGrowthMultiplier({ [Tags.STAT_MODIFIER_DAMAGE_BASE] = 0 })
LEGENDARY.abilityExtraLine = function(item)
    return textStatFormat(LEGENDARY_EXTRA_LINE, item, Tags.STAT_MODIFIER_DAMAGE_MIN)
end
local LEGENDARY_TRIGGER = class(TRIGGERS.POST_CAST)
function LEGENDARY_TRIGGER:isEnabled()
    if self.triggeringSlot ~= self:getSlot() then
        return false
    end

    local body = self.entity.body
    for direction in DIRECTIONS_AA() do
        if body:hasEntityWithAgent(body:getPosition() + Vector[direction]) then
            return true
        end

    end

    return false
end

function LEGENDARY_TRIGGER:process(currentEvent)
    local entity = self.entity
    currentEvent:chainEvent(function()
        local hit = self.entity.hitter:createHit()
        local manaCost = self.entity.equipment:getBaseSlotStat(self:getSlot(), Tags.STAT_MODIFIER_DAMAGE_MIN)
        hit:setHealing(manaCost, manaCost, self.abilityStats)
        hit.affectsMana = true
        hit:applyToEntity(currentEvent, self.entity)
    end)
    entity.charactereffects:flash(ACTION_CONSTANTS.STANDARD_FLASH_DURATION, COLORS.STANDARD_PSYCHIC)
    entity.buffable:forceApply(BUFFS:get("REACTIVE_TIME_STOP"):new(1))
    return currentEvent:chainProgress(ACTION_CONSTANTS.STANDARD_FLASH_DURATION)
end

LEGENDARY.modifyItem = function(item)
    item.triggers:push(LEGENDARY_TRIGGER)
end
return ITEM

