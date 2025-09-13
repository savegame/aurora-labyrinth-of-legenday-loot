local Vector = require("utils.classes.vector")
local Array = require("utils.classes.array")
local Color = require("utils.classes.color")
local BUFFS = require("definitions.buffs")
local COLORS = require("draw.colors")
local Common = require("common")
local TERMS = require("text.terms")
local textStatFormat = require("text.stat_format")
local TRIGGERS = require("actions.triggers")
local ITEM = require("structures.amulet_def"):new("Cultist Amulet")
ITEM.className = "Cultist"
ITEM.classSprite = Vector:new(16, 1)
ITEM.icon = Vector:new(19, 19)
ITEM:setToStatsBase({ [Tags.STAT_ABILITY_DAMAGE_BASE] = 6.7, [Tags.STAT_ABILITY_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.54), [Tags.STAT_ABILITY_BUFF_DURATION] = 3 })
local FORMAT_1 = "You cannot die unless your health is zero or below for %s consecutive" .. " turns."
local FORMAT_2 = "Whenever you kill an adjacent enemy, restore %s health."
ITEM.getPassiveDescription = function(item)
    return Array:new(textStatFormat(FORMAT_1, item, Tags.STAT_ABILITY_BUFF_DURATION), textStatFormat(FORMAT_2, item, Tags.STAT_ABILITY_DAMAGE_MIN))
end
local TRIGGER = class(TRIGGERS.ON_KILL)
function TRIGGER:process(currentEvent)
    return currentEvent:chainEvent(function(_, anchor)
        local hit = self.entity.hitter:createHit()
        hit:setHealing(self.abilityStats:get(Tags.STAT_ABILITY_DAMAGE_MIN), self.abilityStats:get(Tags.STAT_ABILITY_DAMAGE_MAX), self.abilityStats)
        hit:applyToEntity(anchor, self.entity)
    end)
end

function TRIGGER:isEnabled()
    if not self.killingHit or self.killingHit:getApplyDistance() > 1 then
        return false
    end

    return self.killed:hasComponent("agent")
end

local DEATH_COLOR = Color:new(0.2, 0.1, 0.3, 0.4)
local DEATH_HIT_ICON = Vector:new(21, 7)
local DEATH_HIT = class("actions.action")
local FLASH_DURATION = 0.4
local FADEOUT_DURATION = 0.2
function DEATH_HIT:initialize(entity, direction, abilityStats)
    DEATH_HIT:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("iconflash")
    self.iconflash.icon = DEATH_HIT_ICON
    self.iconflash.color = COLORS.STANDARD_DEATH_BRIGHTER
end

function DEATH_HIT:process(currentEvent)
    Common.playSFX("DOOM")
    currentEvent = self.iconflash:chainFlashEvent(currentEvent, FLASH_DURATION):chainEvent(function(_, anchor)
        Common.playSFX("GENERIC_HIT")
        self.entity.tank.keepAlive = false
        self.entity.tank.preDeath = doNothing
        self.entity.tank.delayDeath = false
        self.entity.charactereffects.negativeOverlay = 1
        self.entity.tank:kill(anchor)
    end)
    self.iconflash:chainFadeEvent(currentEvent, FADEOUT_DURATION)
    return currentEvent
end

local BUFF = BUFFS:define("CULTIST_KILLER")
function BUFF:initialize(duration)
    BUFF:super(self, "initialize", duration)
    self.displayTimerColor = COLORS.STANDARD_DEATH_BRIGHTER
end

function BUFF:onExpire(anchor, entity)
    local action = entity.actor:create(DEATH_HIT)
    action:parallelChainEvent(anchor)
end

function BUFF:onTurnEnd(anchor, entity)
    if entity.tank:getCurrent() > 0 then
        entity.tank.keepAlive = false
        entity.buffable:delete(anchor, BUFF)
    end

end

ITEM.onEquip = function(entity, item)
    entity.tank.preDeath = function(entity)
        entity.tank.keepAlive = true
        if not entity.buffable:isAffectedBy(BUFF) then
            entity.buffable:apply(BUFF:new(item.stats:get(Tags.STAT_ABILITY_BUFF_DURATION)))
        end

    end
end
ITEM.onUnequip = function(entity, item)
    entity.tank.preDeath = doNothing
end
ITEM.triggers:push(TRIGGER)
local LEGENDARY = ITEM:createLegendary("Abyssal Will")
LEGENDARY.statLine = TERMS.LEGENDARY_AMULET_DESCRIPTION
LEGENDARY.strokeColor = COLORS.STANDARD_DEATH
return ITEM

