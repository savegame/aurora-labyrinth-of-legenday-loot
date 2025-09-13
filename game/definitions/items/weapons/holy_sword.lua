local Vector = require("utils.classes.vector")
local Common = require("common")
local ACTION_CONSTANTS = require("actions.constants")
local ATTACK_WEAPON = require("actions.attack_weapon")
local TRIGGERS = require("actions.triggers")
local ActionUtils = require("actions.utils")
local textStatFormat = require("text.stat_format")
local COLORS = require("draw.colors")
local ITEM = require("structures.item_def"):new("Holy Sword")
local ABILITY = require("structures.ability_def"):new("Sword of the Heavens")
ABILITY:addTag(Tags.ABILITY_TAG_RESTORES_HEALTH)
ABILITY:addTag(Tags.ABILITY_TAG_BOOSTABLE_ABILITY_DAMAGE)
ITEM.ability = ABILITY
ITEM.slot = Tags.SLOT_WEAPON
ITEM.icon = Vector:new(9, 10)
ITEM.attackClass = ATTACK_WEAPON.SWING_AND_DAMAGE
ITEM:setToStatsBase({ [Tags.STAT_ATTACK_DAMAGE_BASE] = 19.8, [Tags.STAT_ATTACK_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.35), [Tags.STAT_VIRTUAL_RATIO] = 0.74, [Tags.STAT_ABILITY_POWER] = 3.89, [Tags.STAT_ABILITY_RANGE] = 3, [Tags.STAT_ABILITY_DAMAGE_BASE] = 29, [Tags.STAT_ABILITY_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.32), [Tags.STAT_SECONDARY_DAMAGE_BASE] = 6.5, [Tags.STAT_SECONDARY_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.32) })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_RANGE] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_RANGE] = 1 })
local FORMAT = "Deal %s damage to all targets up to %s in a line. " .. "Restore %s health for every enemy hit."
ABILITY.getDescription = function(item)
    return textStatFormat(FORMAT, item, Tags.STAT_ABILITY_DAMAGE_MIN, Tags.STAT_ABILITY_RANGE, Tags.STAT_SECONDARY_DAMAGE_MIN)
end
ABILITY.icon = Vector:new(6, 6)
ABILITY.iconColor = COLORS.STANDARD_HOLY
ABILITY.indicate = function(entity, direction, abilityStats, castingGuide)
    local source = entity.body:getPosition()
    for i = 1, abilityStats:get(Tags.STAT_ABILITY_RANGE) do
        local target = source + Vector[direction] * i
        if not entity.body:canBePassable(target) then
            break
        end

        local entityAt = entity.body:getEntityAt(target)
        castingGuide:indicate(target)
    end

end
ABILITY.getInvalidReason = ActionUtils.getInvalidReasonFrontCantBePassable
local ACTION = class("actions.action")
ABILITY.actionClass = ACTION
local ITEM_ANGLE_START = math.tau * 0.3125
local BRACE_DURATION = 0.3
local CHARGE_DURATION = 0.2
local SWING_DURATION = 0.45
local HOLD_DURATION = 0.25
local BACK_DURATION = 0.1
local RANGE_EXTRA_DISTANCE = 0.4
function ACTION:initialize(entity, direction, abilityStats)
    ACTION:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("weaponswing")
    self.weaponswing:setTrailToLingering()
    self.weaponswing.angleStart = ITEM_ANGLE_START
    self.weaponswing:setSilhouetteColor(ABILITY.iconColor)
    self.weaponswing.layer = Tags.LAYER_ABOVE_VISION
    self:addComponent("tackle")
    self:addComponent("outline")
    self.outline.color = ABILITY.iconColor
    self.tackle.braceDistance = ACTION_CONSTANTS.DEFAULT_BRACE_DISTANCE
    self.tackle.forwardDistance = self.tackle.braceDistance
    self.attackTarget = false
    self.hasKilled = false
end

function ACTION:speedMultiply(factor)
end

function ACTION:affectTarget(anchor, target)
    local hit = self.entity.hitter:createHit()
    hit:setDamageFromAbilityStats(Tags.DAMAGE_TYPE_SPELL, self.abilityStats)
    hit:applyToPosition(anchor, target)
    return hit
end

function ACTION:process(currentEvent)
    self.entity.sprite:turnToDirection(self.direction)
    if self.entity.sprite.layer == Tags.LAYER_CHARACTER and (self.direction == LEFT or self.direction == RIGHT) then
        self.entity.sprite.layer = Tags.LAYER_ABOVE_EFFECTS
    end

    self.tackle:createOffset()
    local range = self.abilityStats:get(Tags.STAT_ABILITY_RANGE)
    local swingItem = self.weaponswing:createSwingItem()
    swingItem.opacity = 0
    swingItem.fillOpacity = 0
    swingItem.scale = range + RANGE_EXTRA_DISTANCE
    swingItem.filterOutline = true
    self.tackle:chainBraceEvent(currentEvent, BRACE_DURATION)
    currentEvent:chainProgress(BRACE_DURATION + CHARGE_DURATION, function(progress)
        swingItem.fillOpacity = progress
    end)
    Common.playSFX("WEAPON_CHARGE")
    currentEvent = self.outline:chainFadeIn(currentEvent, BRACE_DURATION + CHARGE_DURATION):chainEvent(function()
        Common.playSFX("WHOOSH_BIG")
    end)
    self.tackle:chainForwardEvent(currentEvent, SWING_DURATION)
    currentEvent = self.weaponswing:chainSwingEvent(currentEvent, SWING_DURATION):chainEvent(function(_, anchor)
        local source = self.entity.body:getPosition()
        local totalHit = 0
        for i = 1, range do
            local target = source + Vector[self.direction] * i
            if not self.entity.body:canBePassable(target) then
                break
            end

            local entityAt = self.entity.body:getEntityAt(target)
            local isAlive = false
            if ActionUtils.isAliveAgent(entityAt) then
                totalHit = totalHit + 1
                isAlive = true
            end

            self:affectTarget(anchor, target)
            if isAlive and not ActionUtils.isAliveAgent(entityAt) then
                self.hasKilled = true
            end

        end

        if totalHit > 0 then
            local hit = self.entity.hitter:createHit()
            local minDamage = self.abilityStats:get(Tags.STAT_SECONDARY_DAMAGE_MIN) * totalHit
            local maxDamage = self.abilityStats:get(Tags.STAT_SECONDARY_DAMAGE_MAX) * totalHit
            hit:setHealing(minDamage, maxDamage, self.abilityStats)
            hit:applyToEntity(anchor, self.entity)
        end

    end)
    currentEvent:chainProgress(HOLD_DURATION, function(progress)
        swingItem.fillOpacity = 1 - progress
    end)
    currentEvent = self.outline:chainFadeOut(currentEvent, HOLD_DURATION):chainEvent(function()
        self.weaponswing:deleteSwingItem()
    end)
    return self.tackle:chainBackEvent(currentEvent, BACK_DURATION):chainEvent(function()
        self.tackle:deleteOffset()
    end)
end

local LEGENDARY = ITEM:createLegendary("Sword of the Archangel")
LEGENDARY.abilityExtraLine = "If this ability kills an enemy, reset the cooldown."
local LEGENDARY_TRIGGER = class(TRIGGERS.POST_CAST)
function LEGENDARY_TRIGGER:initialize(entity, direction, abilityStats)
    LEGENDARY_TRIGGER:super(self, "initialize", entity, direction, abilityStats)
end

function LEGENDARY_TRIGGER:isEnabled()
    return self.triggeringSlot == self:getSlot() and self.triggeringAction.hasKilled
end

function LEGENDARY_TRIGGER:process(currentEvent)
    self.entity.equipment:resetCooldown(self.triggeringSlot)
    return currentEvent
end

LEGENDARY.modifyItem = function(item)
    item.triggers:push(LEGENDARY_TRIGGER)
end
return ITEM

