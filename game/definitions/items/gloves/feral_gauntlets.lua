local Vector = require("utils.classes.vector")
local Array = require("utils.classes.array")
local Common = require("common")
local ActionUtils = require("actions.utils")
local TRIGGERS = require("actions.triggers")
local COLORS = require("draw.colors")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.item_def"):new("Feral Gauntlets")
local ABILITY = require("structures.ability_def"):new("Rampage")
ABILITY:addTag(Tags.ABILITY_TAG_PLUS_BASIC_ATTACK)
ITEM.ability = ABILITY
ITEM.slot = Tags.SLOT_GLOVES
ITEM.icon = Vector:new(5, 12)
ITEM:setToStatsBase({ [Tags.STAT_MAX_HEALTH] = 36, [Tags.STAT_MAX_MANA] = 4, [Tags.STAT_ABILITY_POWER] = 1.65, [Tags.STAT_ABILITY_COUNT] = 3 })
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
local FORMAT = "Do %s {C:KEYWORD}Attacks, each in a different direction."
ABILITY.getDescription = function(item)
    return textStatFormat(FORMAT, item, Tags.STAT_ABILITY_COUNT)
end
ABILITY.icon = Vector:new(4, 10)
ABILITY.iconColor = COLORS.STANDARD_RAGE
ABILITY.indicate = function(entity, direction, abilityStats, castingGuide)
    if entity.stats:has(Tags.STAT_LUNGE) then
        ActionUtils.indicateExtendableAttack(entity, direction, abilityStats, castingGuide)
        local moveTo = castingGuide:getMoveTo()
        if not moveTo then
            moveTo = entity.body:getPosition()
        end

        castingGuide:indicate(moveTo + Vector[cwDirection(direction)])
        castingGuide:indicate(moveTo + Vector[ccwDirection(direction)])
    else
        ActionUtils.indicateExtendableAttack(entity, cwDirection(direction), abilityStats, castingGuide)
        ActionUtils.indicateExtendableAttack(entity, ccwDirection(direction), abilityStats, castingGuide)
        ActionUtils.indicateExtendableAttack(entity, direction, abilityStats, castingGuide)
    end

end
local ACTION = class("actions.action")
ABILITY.actionClass = ACTION
function ACTION:initialize(entity, direction, abilityStats)
    ACTION:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("charactertrail")
    self.charactertrail.silhouetteColor = ABILITY.iconColor
end

local ATTACK_DELAY = 0.14
function ACTION:process(currentEvent)
    self.charactertrail:start(currentEvent)
    local count = self.abilityStats:get(Tags.STAT_ABILITY_COUNT)
    local directionOrder = Array:new(cwDirection(self.direction), ccwDirection(self.direction))
    directionOrder:shuffleSelf(self:getLogicRNG())
    directionOrder:pushFirst(self.direction)
    for i = 1, count do
        local thisDirection = directionOrder[i]
        local waitGroup = currentEvent:createWaitGroup(1)
        currentEvent:chainEvent(function(_, anchor)
            local attackAction = self.entity.melee:createAction(thisDirection)
            attackAction:parallelChainEvent(anchor):chainWaitGroupDone(waitGroup)
        end)
        currentEvent = waitGroup
        if i ~= count then
            currentEvent = currentEvent:chainProgress(ATTACK_DELAY)
        end

    end

    return currentEvent:chainEvent(function()
        self.charactertrail:stop()
    end)
end

local LEGENDARY = ITEM:createLegendary("Bracers of Unbounded Fury")
local LEGENDARY_STAT_LINE = "{C:UPGRADED}+%s Max Attack Damage"
LEGENDARY:setToStatsBase({ [Tags.STAT_ATTACK_DAMAGE_MAX] = 8 })
LEGENDARY:addPowerSpike({ [Tags.STAT_ATTACK_DAMAGE_MAX] = 1 })
LEGENDARY:addPowerSpike({ [Tags.STAT_ATTACK_DAMAGE_MAX] = 1 })
LEGENDARY:addPowerSpike({ [Tags.STAT_ATTACK_DAMAGE_MAX] = 1 })
LEGENDARY:addPowerSpike({ [Tags.STAT_ATTACK_DAMAGE_MAX] = 1 })
LEGENDARY:addPowerSpike({ [Tags.STAT_ATTACK_DAMAGE_MAX] = 2 })
LEGENDARY:addPowerSpike({ [Tags.STAT_ATTACK_DAMAGE_MAX] = 1 })
LEGENDARY:addPowerSpike({ [Tags.STAT_ATTACK_DAMAGE_MAX] = 1 })
LEGENDARY:addPowerSpike({ [Tags.STAT_ATTACK_DAMAGE_MAX] = 1 })
LEGENDARY:addPowerSpike({ [Tags.STAT_ATTACK_DAMAGE_MAX] = 1 })
LEGENDARY:addPowerSpike({ [Tags.STAT_ATTACK_DAMAGE_MAX] = 2 })
LEGENDARY.statLine = function(item)
    return textStatFormat(LEGENDARY_STAT_LINE, item, Tags.STAT_ATTACK_DAMAGE_MAX)
end
LEGENDARY.modifyItem = function(item)
    item:markAltered(Tags.STAT_ATTACK_DAMAGE_MAX, Tags.STAT_UPGRADED)
end
return ITEM

