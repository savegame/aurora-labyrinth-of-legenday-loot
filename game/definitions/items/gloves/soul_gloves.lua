local Vector = require("utils.classes.vector")
local Color = require("utils.classes.color")
local Common = require("common")
local BUFFS = require("definitions.buffs")
local ACTION_CONSTANTS = require("actions.constants")
local TRIGGERS = require("actions.triggers")
local ActionUtils = require("actions.utils")
local PLAYER_COMMON = require("actions.player_common")
local COLORS = require("draw.colors")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.item_def"):new("Soul Gloves")
local ABILITY = require("structures.ability_def"):new("Soul Siphon")
ABILITY:addTag(Tags.ABILITY_TAG_BOOSTABLE_PERIODIC_DAMAGE)
ABILITY:addTag(Tags.ABILITY_TAG_RANGE_EXTENDABLE)
ITEM.ability = ABILITY
ITEM.slot = Tags.SLOT_GLOVES
ITEM.icon = Vector:new(3, 19)
ITEM:setToStatsBase({ [Tags.STAT_MAX_HEALTH] = 8, [Tags.STAT_MAX_MANA] = 32, [Tags.STAT_ABILITY_COOLDOWN] = 30, [Tags.STAT_ABILITY_DAMAGE_BASE] = 14.5, [Tags.STAT_ABILITY_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.38), [Tags.STAT_ABILITY_BUFF_DURATION] = 3, [Tags.STAT_ABILITY_SUSTAIN_MODE] = Tags.SUSTAIN_MODE_FULL, [Tags.STAT_ABILITY_RANGE] = 3 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_BUFF_DURATION] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_RANGE] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_BUFF_DURATION] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
local FORMAT = "{C:KEYWORD}Range %s - Target an enemy. {FORCE_NEWLINE} {C:KEYWORD}Sustain %s - " .. "Deal %s damage to the target and restore mana equal to the damage."
ABILITY.getDescription = function(item)
    return textStatFormat(FORMAT, item, Tags.STAT_ABILITY_RANGE_MIN, Tags.STAT_ABILITY_BUFF_DURATION, Tags.STAT_ABILITY_DAMAGE_MIN)
end
ABILITY.icon = Vector:new(9, 4)
ABILITY.iconColor = COLORS.STANDARD_GHOST
ABILITY.getInvalidReason = ActionUtils.getInvalidReasonEnemy
ABILITY.indicate = ActionUtils.indicateEnemyWithinRange
local TRIGGER = class(TRIGGERS.END_OF_TURN)
function TRIGGER:initialize(entity, direction, abilityStats)
    self:super(self, "initialize", entity, direction, abilityStats)
    self.targetEntity = false
end

function TRIGGER:process(currentEvent)
    local hit = self.entity.hitter:createHit()
    hit:setDamageFromAbilityStats(Tags.DAMAGE_TYPE_SPELL, self.abilityStats)
    hit:applyToEntity(currentEvent, self.targetEntity)
    local healHit = self.entity.hitter:createHit()
    healHit:setHealing(hit.minDamage, hit.maxDamage, self.abilityStats)
    healHit.affectsMana = true
    healHit:applyToEntity(currentEvent, self.entity)
    if self.abilityStats:get(Tags.STAT_LEGENDARY, 0) > 0 then
        local value = self.abilityStats:get(Tags.STAT_MODIFIER_VALUE)
        for slot in (self.entity.equipment:getSlotsWithAbilities())() do
            self.entity.equipment:reduceCooldown(slot, value)
        end

    end

    return currentEvent
end

local BUFF = class(BUFFS.DEACTIVATOR)
ABILITY.buffClass = BUFF
function BUFF:initialize(duration, abilityStats)
    BUFF:super(self, "initialize", duration, abilityStats)
    self.triggerClasses:push(TRIGGER)
    self.expiresImmediately = true
end

function BUFF:onTurnStart(anchor, entity)
    if self.action:shouldDeactivate() then
        self.action:deactivate()
        entity.equipment:deactivateSlot(anchor, self.abilityStats:get(Tags.STAT_SLOT))
    end

end

function BUFF:decorateTriggerAction(action)
    BUFF:super(self, "decorateTriggerAction", action)
    action.targetEntity = self.action.targetEntity
end

local ACTION = class("actions.action")
ABILITY.actionClass = ACTION
local EFFECT_COLOR = Color:new(0.15, 0.7, 1)
function ACTION:initialize(entity, direction, abilityStats)
    ACTION:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("outline")
    self.outline.color = ABILITY.iconColor
    self:addComponent("drain")
    self.drain.color = EFFECT_COLOR
    self.targetEntity = false
    self.sound = false
end

function ACTION:toData(convertToData)
    return { targetEntity = convertToData(self.targetEntity) }
end

function ACTION:setFromLoad(data, convertFromData)
    self.targetEntity = convertFromData(data.targetEntity)
    self.drain:start(self.entity, self.targetEntity)
    self.sound = Common.playSFX("DRAIN")
end

function ACTION:shouldDeactivate()
    if self.targetEntity.tank.hasDiedOnce then
        return true
    end

    return not self:isVisible(self.targetEntity.body:getPosition())
end

function ACTION:deactivate()
    self.drain:stop()
    self.sound:stop()
end

function ACTION:process(currentEvent)
    self.targetEntity = ActionUtils.getEnemyWithinRange(self.entity, self.direction, self.abilityStats)
    return self.outline:chainFullEvent(currentEvent, ACTION_CONSTANTS.MAJOR_CAST_CHARGE_DURATION):chainEvent(function()
        self.sound = Common.playSFX("DRAIN")
        self.drain:start(self.entity, self.targetEntity)
    end)
end

local LEGENDARY = ITEM:createLegendary("The Soulthief")
local LEGENDARY_EXTRA_LINE = "Whenever you {C:KEYWORD}Sustain, reduce all other ability " .. "cooldowns by %s."
LEGENDARY:setToStatsBase({ [Tags.STAT_MODIFIER_VALUE] = 2 })
LEGENDARY:addPowerSpike({ [Tags.STAT_MODIFIER_VALUE] = 1 })
LEGENDARY:addPowerSpike({ [Tags.STAT_MODIFIER_VALUE] = 1 })
LEGENDARY.abilityExtraLine = function(item)
    return textStatFormat(LEGENDARY_EXTRA_LINE, item, Tags.STAT_MODIFIER_VALUE)
end
LEGENDARY.modifyItem = function(item)
end
return ITEM

