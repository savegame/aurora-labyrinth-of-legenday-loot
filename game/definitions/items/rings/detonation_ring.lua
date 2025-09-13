local Vector = require("utils.classes.vector")
local COLORS = require("draw.colors")
local textStatFormat = require("text.stat_format")
local ActionUtils = require("actions.utils")
local TRIGGERS = require("actions.triggers")
local Common = require("common")
local ITEM = require("structures.item_def"):new("Detonation Ring")
ITEM:setToMediumComplexity()
ITEM.slot = Tags.SLOT_RING
ITEM.icon = Vector:new(9, 18)
ITEM:setToStatsBase({ [Tags.STAT_ABILITY_DAMAGE_BASE] = 10.5, [Tags.STAT_ABILITY_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.81), [Tags.STAT_ABILITY_AREA_ROUND] = Tags.ABILITY_AREA_3X3 })
local FORMAT = "Whenever you kill an enemy "
local FORMAT_END = "{C:NOTE}without using an {C:KEYWORD}Attack, " .. "it explodes, dealing %s damage to all spaces around it (except yours). "
ITEM.getPassiveDescription = function(item)
    local description = FORMAT
    return textStatFormat(description .. FORMAT_END, item, Tags.STAT_ABILITY_DAMAGE_MIN)
end
local EXPLOSION = class("actions.action")
local EXPLOSION_DURATION = 0.5
local EXPLOSION_SHAKE_INTENSITY = 1.0
function EXPLOSION:initialize(entity, direction, abilityStats)
    EXPLOSION:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("explosion")
    self.explosion.excludeSelf = false
    self.explosion.shakeIntensity = EXPLOSION_SHAKE_INTENSITY
    self.position = false
end

function EXPLOSION:process(currentEvent)
    self.explosion:setArea(self.abilityStats:get(Tags.STAT_ABILITY_AREA_ROUND))
    self.explosion.source = self.position
    currentEvent:chainEvent(function()
        Common.playSFX("EXPLOSION_MEDIUM")
    end)
    return self.explosion:chainFullEvent(currentEvent, EXPLOSION_DURATION, function(anchor, position)
        if position ~= self.entity.body:getPosition() then
            local hit = self.entity.hitter:createHit(self.explosion.source)
            local damageType = Tags.DAMAGE_TYPE_SPELL
            hit:setDamageFromAbilityStats(damageType, self.abilityStats)
            hit:applyToPosition(anchor, position)
        end

    end)
end

local TRIGGER = class(TRIGGERS.ON_KILL)
function TRIGGER:process(currentEvent)
    local action = self.entity.actor:create(EXPLOSION, self.direction, self.abilityStats)
    action.position = self.position
    return action:parallelChainEvent(currentEvent)
end

function TRIGGER:isEnabled()
    if not self.killed:hasComponent("agent") then
        return false
    end

    return self.killingHit and (not self.killingHit:isDamageAnyMelee())
end

ITEM.triggers:push(TRIGGER)
local LEGENDARY = ITEM:createLegendary("Anarchist's Prayer")
local LEGENDARY_EXTRA_LINE = "Whenever you reduce an enemy's health below %s without using " .. "an {C:KEYWORD}Attack, kill it."
LEGENDARY.strokeColor = COLORS.STANDARD_FIRE
LEGENDARY:setToStatsBase({ [Tags.STAT_MODIFIER_DAMAGE_BASE] = 5, [Tags.STAT_MODIFIER_DAMAGE_VARIANCE] = 0 })
LEGENDARY:setGrowthMultiplier({ [Tags.STAT_MODIFIER_DAMAGE_BASE] = 4 / 1.5 })
LEGENDARY.passiveExtraLine = function(item)
    return textStatFormat(LEGENDARY_EXTRA_LINE, item, Tags.STAT_MODIFIER_DAMAGE_MIN)
end
local LEGENDARY_TRIGGER = class(TRIGGERS.ON_DAMAGE)
local KILL_ICON = Vector:new(21, 7)
local KILL_FLASH_DURATION = 0.3
local KILL_LINGER_DURATION = 0.15
local KILL_EFFECT_DELAY = 0.2
function LEGENDARY_TRIGGER:initialize(entity, direction, abilityStats)
    LEGENDARY_TRIGGER:super(self, "initialize", entity, direction, abilityStats)
    self.sortOrder = 10
    self:addComponent("iconflash")
    self.iconflash.icon = KILL_ICON
    self.iconflash.color = COLORS.STANDARD_FIRE
end

function LEGENDARY_TRIGGER:process(currentEvent)
    local targetEntity = self.hit.targetEntity
    local threshold = self.abilityStats:get(Tags.STAT_MODIFIER_DAMAGE_MIN)
    if ActionUtils.isAliveAgent(targetEntity) and targetEntity.tank:getCurrent() < threshold then
        self.iconflash.target = targetEntity.sprite
        currentEvent = currentEvent:chainProgress(KILL_EFFECT_DELAY)
        Common.playSFX("DOOM")
        currentEvent = self.iconflash:chainFlashEvent(currentEvent, KILL_FLASH_DURATION):chainEvent(function(_, anchor)
            if ActionUtils.isAliveAgent(targetEntity) then
                targetEntity.charactereffects.negativeOverlay = 1
                targetEntity.tank:kill(anchor)
            end

        end)
        self.iconflash:chainFadeEvent(currentEvent, KILL_LINGER_DURATION)
    end

    return currentEvent
end

function LEGENDARY_TRIGGER:isEnabled()
    if not ActionUtils.isAliveAgent(self.hit.targetEntity) then
        return false
    end

    return self.hit:isDamagePositive() and self.hit.damageType ~= Tags.DAMAGE_TYPE_MELEE
end

LEGENDARY.modifyItem = function(item)
    item.triggers:push(LEGENDARY_TRIGGER)
end
return ITEM

