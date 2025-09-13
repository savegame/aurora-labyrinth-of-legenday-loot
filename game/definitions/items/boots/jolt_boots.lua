local Vector = require("utils.classes.vector")
local Common = require("common")
local BUFFS = require("definitions.buffs")
local ActionUtils = require("actions.utils")
local ACTIONS_FRAGMENT = require("actions.fragment")
local ACTION_CONSTANTS = require("actions.constants")
local TRIGGERS = require("actions.triggers")
local MEASURES = require("draw.measures")
local textStatFormat = require("text.stat_format")
local COLORS = require("draw.colors")
local ITEM = require("structures.item_def"):new("Jolt Boots")
local ABILITY = require("structures.ability_def"):new("Lightning Speed")
ABILITY:addTag(Tags.ABILITY_TAG_BUFF_NOT_CONSIDERED)
ABILITY:addTag(Tags.ABILITY_TAG_SURROUNDING_DISABLE)
ABILITY:addTag(Tags.ABILITY_TAG_MOVEMENT_NOT_IMMUNE)
ABILITY:addTag(Tags.ABILITY_TAG_IMMOBILIZED_DISABLED)
ITEM:setToMediumComplexity()
ITEM.ability = ABILITY
ITEM.slot = Tags.SLOT_BOOTS
ITEM.icon = Vector:new(18, 21)
ITEM:setToStatsBase({ [Tags.STAT_MAX_HEALTH] = 12, [Tags.STAT_MAX_MANA] = 28, [Tags.STAT_ABILITY_POWER] = 2.625, [Tags.STAT_ABILITY_BUFF_DURATION] = 3, [Tags.STAT_ABILITY_SUSTAIN_MODE] = Tags.SUSTAIN_MODE_MOBILE })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_BUFF_DURATION] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_MANA_DISCOUNT] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_BUFF_DURATION] = 1 })
local FORMAT = "{C:KEYWORD}Sustain %s - Freeze time, preventing everything else from taking " .. "any turns. You can only move while this is active."
ABILITY.getDescription = function(item)
    return textStatFormat(FORMAT, item, Tags.STAT_ABILITY_BUFF_DURATION)
end
ABILITY.icon = Vector:new(12, 10)
ABILITY.iconColor = COLORS.STANDARD_LIGHTNING
ABILITY.directions = false
ABILITY.indicate = ActionUtils.indicateSelf
local LEGENDARY_POST_MOVE = class(TRIGGERS.POST_MOVE)
local ACTION = class(ACTIONS_FRAGMENT.SHOW_ICON_SELF)
ABILITY.actionClass = ACTION
local BUFF = class(BUFFS.DEACTIVATOR)
ABILITY.buffClass = BUFF
function BUFF:initialize(duration, abilityStats)
    BUFF:super(self, "initialize", duration, abilityStats)
    self.outlinePulseColor = ABILITY.iconColor
    if self.abilityStats:get(Tags.STAT_LEGENDARY, 0) > 0 then
        self.triggerClasses:push(LEGENDARY_POST_MOVE)
    end

end

function ACTION:initialize(entity, direction, abilityStats)
    ACTION:super(self, "initialize", entity, direction, abilityStats)
    self.icon = ITEM.icon
    self.color = ABILITY.iconColor
    self.sound = false
end

function ACTION:setFromLoad()
    self.entity.agentvisitor:getSystemAgent():addTimeStop(1)
    self:getEffects():addTimeStop(1)
end

function ACTION:process(currentEvent)
    return ACTION:super(self, "process", currentEvent):chainEvent(function()
        local entity = self.entity
        local effects = self:getEffects()
        self.sound = Common.playSFX("TIME_STOP_LOOP")
        effects:addTimeStop(1)
        self.entity.agentvisitor:getSystemAgent():addTimeStop(1)
    end)
end

function ACTION:deactivate(anchor)
    self.entity.agentvisitor:getSystemAgent():addTimeStop(-1)
    self:getEffects():addTimeStop(-1)
    self.sound:stop()
end

local LEGENDARY = ITEM:createLegendary("Overload!")
local LEGENDARY_EXTRA_LINE = "Whenever you move, deal %s damage to a random adjacent enemy."
LEGENDARY:setToStatsBase({ [Tags.STAT_MODIFIER_DAMAGE_BASE] = 14, [Tags.STAT_MODIFIER_DAMAGE_VARIANCE] = Common.getVarianceForRatio(1) })
LEGENDARY.abilityExtraLine = function(item)
    return textStatFormat(LEGENDARY_EXTRA_LINE, item, Tags.STAT_MODIFIER_DAMAGE_MIN)
end
function LEGENDARY_POST_MOVE:initialize(entity, direction, abilityStats)
    LEGENDARY_POST_MOVE:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("lightningspawner")
    self.lightningspawner.lightningCount = 2
end

function LEGENDARY_POST_MOVE:process(currentEvent)
    local source = self.entity.body:getPosition()
    for direction in (DIRECTIONS_AA:shuffle(self:getLogicRNG()))() do
        local target = source + Vector[direction]
        local entityAt = self.entity.body:getEntityAt(target)
        if ActionUtils.isAliveAgent(entityAt) then
            Common.playSFX("LIGHTNING")
            return self.lightningspawner:spawn(currentEvent, target, source):chainEvent(function(_, anchor)
                local hit = self.entity.hitter:createHit()
                hit:setDamageFromModifierStats(Tags.DAMAGE_TYPE_SPELL, self.abilityStats)
                hit:applyToEntity(anchor, entityAt, target)
            end)
        end

    end

    return currentEvent
end

return ITEM

