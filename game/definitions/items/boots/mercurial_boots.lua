local Vector = require("utils.classes.vector")
local Common = require("common")
local BUFFS = require("definitions.buffs")
local CONSTANTS = require("logic.constants")
local ActionUtils = require("actions.utils")
local ACTION_CONSTANTS = require("actions.constants")
local TRIGGERS = require("actions.triggers")
local COLORS = require("draw.colors")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.item_def"):new("Mercurial Boots")
local ABILITY = require("structures.ability_def"):new("Haste")
ABILITY:addTag(Tags.ABILITY_TAG_IMMOBILIZED_DISABLED)
ITEM:setToMediumComplexity()
ITEM.ability = ABILITY
ITEM.slot = Tags.SLOT_BOOTS
ITEM.icon = Vector:new(20, 14)
ITEM:setToStatsBase({ [Tags.STAT_MAX_HEALTH] = 6, [Tags.STAT_MAX_MANA] = 34, [Tags.STAT_ABILITY_POWER] = 2.15, [Tags.STAT_ABILITY_BUFF_DURATION] = 3, [Tags.STAT_ABILITY_QUICK] = 1 })
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
local FORMAT = "{C:KEYWORD}Quick {C:KEYWORD}Buff %s - Your first step every turn is {C:KEYWORD}Quick."
ABILITY.getDescription = function(item)
    return textStatFormat(FORMAT, item, Tags.STAT_ABILITY_BUFF_DURATION)
end
ABILITY.icon = Vector:new(1, 9)
ABILITY.iconColor = COLORS.STANDARD_WIND
ABILITY.directions = false
ABILITY.indicate = ActionUtils.indicateSelf
local LEGENDARY_TRIGGER = class(TRIGGERS.POST_HIT)
local BUFF = class(BUFFS.DEACTIVATOR)
ABILITY.buffClass = BUFF
function BUFF:initialize(duration, abilityStats)
    BUFF:super(self, "initialize", duration, abilityStats)
    self.hasQuickStepped = false
    if abilityStats:get(Tags.STAT_LEGENDARY, 0) > 0 then
        self.triggerClasses:push(LEGENDARY_TRIGGER)
    end

end

function BUFF:toData()
    return { hasQuickStepped = self.hasQuickStepped }
end

function BUFF:fromData(data)
    self.hasQuickStepped = data.hasQuickStepped
end

function BUFF:onDelete(anchor, entity)
    BUFF:super(self, "onDelete", anchor, entity)
end

local HASTE = BUFFS:get("HASTE")
BUFF.decorateBasicMove = HASTE.decorateBasicMove
BUFF.onTurnStart = HASTE.onTurnStart
function BUFF:onTurnStart(anchor, entity)
    if not entity.buffable:canMove() then
        entity.equipment:deactivateSlot(anchor, self.abilityStats:get(Tags.STAT_SLOT))
    else
        return HASTE.onTurnStart(self, anchor, entity)
    end

end

local ACTION = class("actions.action")
ABILITY.actionClass = ACTION
function ACTION:initialize(entity, direction, abilityStats)
    ACTION:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("outline")
    self.outline.color = COLORS.ELITE_FAST
end

function ACTION:process(currentEvent)
    Common.playSFX("GLOW_MODAL")
    return self.outline:chainFullEvent(currentEvent, ACTION_CONSTANTS.MAJOR_CAST_CHARGE_DURATION):chainEvent(function()
        self.entity.sprite.strokeColor:push(COLORS.ELITE_FAST)
    end)
end

function ACTION:setFromLoad()
    self.entity.sprite.strokeColor:push(COLORS.ELITE_FAST)
end

function ACTION:deactivate()
    self.entity.sprite.strokeColor:delete(COLORS.ELITE_FAST)
end

local LEGENDARY = ITEM:createLegendary("Mistral Striders")
LEGENDARY:setToStatsBase({ [Tags.STAT_ABILITY_BUFF_DURATION] = 1 })
LEGENDARY.abilityExtraLine = "Whenever you get hit, reset this ability's duration."
function LEGENDARY_TRIGGER:process(currentEvent)
    local slot = self:getSlot()
    local entity = self.entity
    local currentDuration = entity.equipment:getDuration(slot)
    entity.equipment:extendSlotBuff(slot, self.abilityStats:get(Tags.STAT_ABILITY_BUFF_DURATION) - currentDuration)
    return currentEvent
end

LEGENDARY.modifyItem = function(item)
    item:markAltered(Tags.STAT_ABILITY_BUFF_DURATION, Tags.STAT_UPGRADED)
end
return ITEM

