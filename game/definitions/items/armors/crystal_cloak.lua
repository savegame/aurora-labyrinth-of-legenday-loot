local Vector = require("utils.classes.vector")
local Color = require("utils.classes.color")
local Common = require("common")
local CONSTANTS = require("logic.constants")
local BUFFS = require("definitions.buffs")
local ActionUtils = require("actions.utils")
local ACTION_CONSTANTS = require("actions.constants")
local TRIGGERS = require("actions.triggers")
local COLORS = require("draw.colors")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.item_def"):new("Crystal Cloak")
local ABILITY = require("structures.ability_def"):new("Diamond Skin")
ABILITY:addTag(Tags.ABILITY_TAG_BUFF_NOT_CONSIDERED)
ABILITY:addTag(Tags.ABILITY_TAG_BUFF_NO_EXTEND)
ITEM.ability = ABILITY
ITEM.slot = Tags.SLOT_ARMOR
ITEM.icon = Vector:new(14, 20)
ITEM:setToStatsBase({ [Tags.STAT_MAX_HEALTH] = 6, [Tags.STAT_MAX_MANA] = 54, [Tags.STAT_ABILITY_POWER] = 4.5, [Tags.STAT_ABILITY_BUFF_DURATION] = 10, [Tags.STAT_SECONDARY_DAMAGE_BASE] = 36, [Tags.STAT_SECONDARY_DAMAGE_VARIANCE] = 0, [Tags.STAT_ABILITY_QUICK] = 1 })
ITEM:setGrowthMultiplier({ [Tags.STAT_SECONDARY_DAMAGE_BASE] = (10 / 3 - 1) / 1.5 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
local FORMAT = "{C:KEYWORD}Quick {C:KEYWORD}Buff %s - Absorb up to %s damage."
ABILITY.getDescription = function(item)
    return textStatFormat(FORMAT, item, Tags.STAT_ABILITY_BUFF_DURATION, Tags.STAT_SECONDARY_DAMAGE_MIN)
end
ABILITY.icon = Vector:new(9, 8)
ABILITY.iconColor = COLORS.STANDARD_ICE
ABILITY.directions = false
ABILITY.indicate = ActionUtils.indicateSelf
local BUFF = class(BUFFS.DEACTIVATOR)
ABILITY.buffClass = BUFF
local POST_HIT_CANCEL = class(TRIGGERS.POST_HIT)
function BUFF:initialize(duration, abilityStats)
    BUFF:super(self, "initialize", duration, abilityStats)
    self.expiresImmediately = true
    self.toAbsorb = abilityStats:get(Tags.STAT_SECONDARY_DAMAGE_MIN)
    self.triggerClasses:push(POST_HIT_CANCEL)
end

function BUFF:toData()
    return { toAbsorb = self.toAbsorb }
end

function BUFF:fromData(data)
    self.toAbsorb = data.toAbsorb
end

local SHIELD_COLOR = Color:new(0.1, 0.5, 0.8)
function BUFF:decorateIncomingHit(hit)
    if hit:isDamagePositiveDirect() then
        if self.abilityStats:get(Tags.STAT_LEGENDARY, 0) > 0 then
            hit:reduceDamage(self.abilityStats:get(Tags.STAT_MODIFIER_DAMAGE_MIN))
            hit:decreaseBonusState()
        end

        hit:forceResolve()
        local damage = hit.minDamage
        if hit.minDamage <= self.toAbsorb then
            hit.minDamage = 0
            hit.maxDamage = 0
            hit.sound = "HIT_BLOCKED"
        else
            hit.minDamage = damage - self.toAbsorb
        end

        self.toAbsorb = self.toAbsorb - damage
        hit.forceFlash = true
    end

end

function BUFF:decorateTriggerAction(action)
    BUFF:super(self, "decorateTriggerAction", action)
    action.buff = self
end

function POST_HIT_CANCEL:initialize(entity, direction, abilityStats)
    POST_HIT_CANCEL:super(self, "initialize", entity, direction, abilityStats)
    self.sortOrder = 0
    self.buff = false
end

function POST_HIT_CANCEL:process(currentEvent)
    if self.buff.toAbsorb <= 0 then
        self.entity.equipment:deactivateSlot(currentEvent, self.abilityStats:get(Tags.STAT_SLOT))
    end

    return currentEvent
end

local ACTION = class("actions.action")
ABILITY.actionClass = ACTION
function ACTION:initialize(entity, direction, abilityStats)
    ACTION:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("outline")
    self.outline.color = SHIELD_COLOR
end

function ACTION:setFromLoad()
    self.entity.sprite.strokeColor:push(SHIELD_COLOR)
end

function ACTION:process(currentEvent)
    Common.playSFX("GLOW_MODAL")
    return self.outline:chainFullEvent(currentEvent, ACTION_CONSTANTS.MAJOR_CAST_CHARGE_DURATION):chainEvent(function()
        self.entity.sprite.strokeColor:push(SHIELD_COLOR)
    end)
end

function ACTION:deactivate()
    self.entity.sprite.strokeColor:delete(SHIELD_COLOR)
end

local LEGENDARY = ITEM:createLegendary("Mythrilweave")
local LEGENDARY_EXTRA_LINE = "{C:KEYWORD}Resist %s while this {C:KEYWORD}Buff is active."
LEGENDARY:setToStatsBase({ [Tags.STAT_MODIFIER_DAMAGE_BASE] = 8 / 2.5, [Tags.STAT_MODIFIER_DAMAGE_VARIANCE] = 0 })
LEGENDARY.abilityExtraLine = function(item)
    return textStatFormat(LEGENDARY_EXTRA_LINE, item, Tags.STAT_MODIFIER_DAMAGE_MIN)
end
return ITEM

