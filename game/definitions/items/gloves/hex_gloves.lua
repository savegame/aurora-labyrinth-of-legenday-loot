local Vector = require("utils.classes.vector")
local Common = require("common")
local CONSTANTS = require("logic.constants")
local BUFFS = require("definitions.buffs")
local ActionUtils = require("actions.utils")
local ACTIONS_FRAGMENT = require("actions.fragment")
local ACTION_CONSTANTS = require("actions.constants")
local COLORS = require("draw.colors")
local MEASURES = require("draw.measures")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.item_def"):new("Hex Gloves")
local ABILITY = require("structures.ability_def"):new("Amplify Damage")
ABILITY:addTag(Tags.ABILITY_TAG_RANGE_EXTENDABLE)
ITEM.ability = ABILITY
ITEM.slot = Tags.SLOT_GLOVES
ITEM.icon = Vector:new(22, 17)
ITEM:setToStatsBase({ [Tags.STAT_MAX_HEALTH] = 4, [Tags.STAT_MAX_MANA] = 36, [Tags.STAT_ABILITY_POWER] = 2.15, [Tags.STAT_ABILITY_RANGE] = 3, [Tags.STAT_ABILITY_QUICK] = 1, [Tags.STAT_ABILITY_BUFF_DURATION] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_RANGE] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_RANGE] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
local FORMAT = "{C:KEYWORD}Range %s - Target enemy takes double damage until the start of your next turn. {C:KEYWORD}Quick."
ABILITY.getDescription = function(item)
    return textStatFormat(FORMAT, item, Tags.STAT_ABILITY_RANGE_MIN)
end
ABILITY.icon = Vector:new(10, 5)
ABILITY.iconColor = COLORS.STANDARD_DEATH
ABILITY.getInvalidReason = ActionUtils.getInvalidReasonEnemy
ABILITY.indicate = ActionUtils.indicateEnemyWithinRange
local DEBUFF = BUFFS:define("AMPLIFY")
function DEBUFF:initialize(duration, multiplier)
    DEBUFF:super(self, "initialize", duration)
    self.multiplier = multiplier or 2
    self.expiresAtStart = true
end

function DEBUFF:getDataArgs()
    return self.duration, self.multiplier
end

function DEBUFF:decorateIncomingHit(hit)
    if hit:isDamagePositiveDirect() then
        hit:multiplyDamage(self.multiplier)
        hit:increaseBonusState()
        if self.multiplier > 2 then
            hit:increaseBonusState()
        end

    end

end

local BUFF = class(BUFFS.DEACTIVATOR)
ABILITY.buffClass = BUFF
function BUFF:initialize(duration, abilityStats)
    BUFF:super(self, "initialize", duration, abilityStats, action)
    self.expiresAtStart = true
end

local ACTION = class("actions.action")
ABILITY.actionClass = ACTION
local HEX_ICON = Vector:new(22, 18)
local OUTLINE_DURATION = ACTION_CONSTANTS.MAJOR_CAST_CHARGE_DURATION
function ACTION:initialize(entity, direction, abilityStats)
    ACTION:super(self, "initialize", entity, direction, abilityStats)
    self.color = ABILITY.iconColor
    self:addComponent("outline")
    self.outline.color = COLORS.STANDARD_DEATH_BRIGHTER
    self.outline.hasModal = true
    self:addComponent("iconflash")
    self.iconflash.icon = HEX_ICON
    self.iconflash.color = COLORS.STANDARD_DEATH_BRIGHTER
    self.iconflash.originOffset = Vector:new(0, 0.85)
    self.targetEntity = false
end

function ACTION:process(currentEvent)
    self.targetEntity = ActionUtils.getEnemyWithinRange(self.entity, self.direction, self.abilityStats)
    Common.playSFX("CAST_CHARGE")
    currentEvent = self.outline:chainFadeIn(currentEvent, OUTLINE_DURATION):chainEvent(function()
        Common.playSFX("AFFLICT")
    end)
    self.iconflash.target = self.targetEntity.sprite
    currentEvent = self.iconflash:chainFlashEvent(currentEvent, OUTLINE_DURATION):chainEvent(function()
        local multiplier = 2
        if self.abilityStats:get(Tags.STAT_LEGENDARY, 0) > 0 and Common.isElite(self.targetEntity) then
            multiplier = 3
        end

        local debuff = DEBUFF:new(math.huge, multiplier)
        self.targetEntity.buffable:apply(debuff)
    end)
    self.outline:chainFadeOut(currentEvent, OUTLINE_DURATION)
    return currentEvent
end

function ACTION:setFromLoad()
    self.targetEntity = ActionUtils.getEnemyWithinRange(self.entity, self.direction, self.abilityStats)
    self.iconflash.target = self.targetEntity.sprite
    self.iconflash:display()
end

function ACTION:deactivate(currentEvent)
    self.targetEntity.buffable:delete(currentEvent, DEBUFF)
    self.iconflash:chainFadeEvent(currentEvent, OUTLINE_DURATION)
end

local LEGENDARY = ITEM:createLegendary("Mark of Death")
LEGENDARY.abilityExtraLine = "If it is {C:KEYWORD}Elite, it takes triple damage instead."
return ITEM

