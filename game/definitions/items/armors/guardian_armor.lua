local Vector = require("utils.classes.vector")
local Common = require("common")
local CONSTANTS = require("logic.constants")
local ActionUtils = require("actions.utils")
local ACTIONS_FRAGMENT = require("actions.fragment")
local TRIGGERS = require("actions.triggers")
local COLORS = require("draw.colors")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.item_def"):new("Guardian Armor")
local ABILITY = require("structures.ability_def"):new("Righteous Stand")
ABILITY:addTag(Tags.ABILITY_TAG_RESTORES_HEALTH)
ITEM.ability = ABILITY
ITEM.slot = Tags.SLOT_ARMOR
ITEM.icon = Vector:new(13, 13)
ITEM:setToStatsBase({ [Tags.STAT_MAX_HEALTH] = 56, [Tags.STAT_MAX_MANA] = 4, [Tags.STAT_ABILITY_POWER] = 4.81, [Tags.STAT_ABILITY_DAMAGE_BASE] = 5.75, [Tags.STAT_ABILITY_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.31), [Tags.STAT_ABILITY_BUFF_DURATION] = 3, [Tags.STAT_ABILITY_QUICK] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_BUFF_DURATION] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_BUFF_DURATION] = 1 })
local FORMAT = "{C:KEYWORD}Quick {C:KEYWORD}Buff %s - Cannot move. At the end of your turn restore %s health for " .. "every adjacent enemy."
ABILITY.getDescription = function(item)
    return textStatFormat(FORMAT, item, Tags.STAT_ABILITY_BUFF_DURATION, Tags.STAT_ABILITY_DAMAGE_MIN)
end
local TRIGGER = class(TRIGGERS.END_OF_TURN)
function TRIGGER:isEnabled()
    for direction in DIRECTIONS_AA() do
        local source = self.entity.body:getPosition()
        if self.entity.body:hasEntityWithAgent(source + Vector[direction]) then
            return true
        end

    end

    return false
end

function TRIGGER:process(currentEvent)
    return currentEvent:chainEvent(function(_, anchor)
        local entity = self.entity
        local numAgents = DIRECTIONS_AA:countIf(function(direction)
            return entity.body:hasEntityWithAgent(entity.body:getPosition() + Vector[direction])
        end)
        if numAgents > 0 then
            local minDamage = self.abilityStats:get(Tags.STAT_ABILITY_DAMAGE_MIN) * numAgents
            local maxDamage = self.abilityStats:get(Tags.STAT_ABILITY_DAMAGE_MAX) * numAgents
            local hit = entity.hitter:createHit()
            hit:setHealing(minDamage, maxDamage, self.abilityStats)
            hit:applyToEntity(anchor, entity)
        end

    end)
end

ABILITY.icon = Vector:new(5, 11)
ABILITY.iconColor = COLORS.STANDARD_HOLY
ABILITY.directions = false
ABILITY.indicate = ActionUtils.indicateSelf
local BUFF = class("structures.item_buff")
ABILITY.buffClass = BUFF
function BUFF:initialize(duration, abilityStats)
    BUFF:super(self, "initialize", duration, abilityStats)
    self.outlinePulseColor = ABILITY.iconColor
    self.triggerClasses:push(TRIGGER)
    self.expiresAtStart = true
    self.disablesMovement = true
end

function BUFF:decorateIncomingHit(hit)
    if hit.knockback then
        hit.knockback.distance = 0
    end

end

local ACTION = class(ACTIONS_FRAGMENT.SHOW_ICON_SELF)
ABILITY.actionClass = ACTION
function ACTION:initialize(entity, direction, abilityStats)
    ACTION:super(self, "initialize", entity, direction, abilityStats)
    self.icon = ITEM.icon
    self.color = ABILITY.iconColor
end

local LEGENDARY = ITEM:createLegendary("Immortal Defender")
LEGENDARY:setToStatsBase({ [Tags.STAT_ABILITY_BUFF_DURATION] = CONSTANTS.PRESUMED_INFINITE, [Tags.STAT_ABILITY_DAMAGE_BASE] = 6.9 / 5, [Tags.STAT_ABILITY_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.31) })
LEGENDARY.modifyItem = function(item)
    item:markAltered(Tags.STAT_ABILITY_BUFF_DURATION, Tags.STAT_UPGRADED)
    item:markAltered(Tags.STAT_ABILITY_DAMAGE_MIN, Tags.STAT_UPGRADED)
    item:markAltered(Tags.STAT_ABILITY_DAMAGE_MAX, Tags.STAT_UPGRADED)
end
return ITEM

