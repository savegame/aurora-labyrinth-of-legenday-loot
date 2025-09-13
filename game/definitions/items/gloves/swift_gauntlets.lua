local Vector = require("utils.classes.vector")
local Common = require("common")
local ActionUtils = require("actions.utils")
local TRIGGERS = require("actions.triggers")
local COLORS = require("draw.colors")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.item_def"):new("Swift Gauntlets")
local ABILITY = require("structures.ability_def"):new("Double Strike")
ABILITY:addTag(Tags.ABILITY_TAG_PLUS_BASIC_ATTACK)
ABILITY:addTag(Tags.ABILITY_TAG_DIRECTIONAL_RECASTABLE)
ITEM.ability = ABILITY
ITEM.slot = Tags.SLOT_GLOVES
ITEM.icon = Vector:new(2, 21)
ITEM:setToStatsBase({ [Tags.STAT_MAX_HEALTH] = 36, [Tags.STAT_MAX_MANA] = 4, [Tags.STAT_ABILITY_POWER] = 2, [Tags.STAT_ABILITY_COUNT] = 2 })
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
local FORMAT = "Do %s {C:KEYWORD}Attacks against an enemy."
ABILITY.getDescription = function(item)
    return textStatFormat(FORMAT, item, Tags.STAT_ABILITY_COUNT)
end
ABILITY.icon = Vector:new(2, 10)
ABILITY.iconColor = COLORS.STANDARD_STEEL
ABILITY.getInvalidReason = ActionUtils.getInvalidReasonEnemyAttack
ABILITY.indicate = function(entity, direction, abilityStats, castingGuide)
    local target = ActionUtils.indicateExtendableAttack(entity, direction, abilityStats, castingGuide)
    if ABILITY.getInvalidReason(entity, direction, abilityStats) then
        castingGuide:indicateWeak(target)
    end

end
local ACTION = class("actions.action")
ABILITY.actionClass = ACTION
function ACTION:initialize(entity, direction, abilityStats)
    ACTION:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("charactertrail")
    self.charactertrail.silhouetteColor = BLACK
end

local ATTACK_DELAY = 0.12
function ACTION:process(currentEvent)
    self.entity.sprite:turnToDirection(self.direction)
    self.charactertrail:start(currentEvent)
    local count = self.abilityStats:get(Tags.STAT_ABILITY_COUNT)
    for i = 1, count do
        local waitGroup = currentEvent:createWaitGroup(1)
        currentEvent:chainEvent(function(_, anchor)
            local attackAction = self.entity.melee:createAction(self.direction)
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

local LEGENDARY = ITEM:createLegendary("Gauntlets of the Relentless")
LEGENDARY:setToStatsBase({ [Tags.STAT_ABILITY_COOLDOWN] = -4 })
LEGENDARY.statLine = "{C:KEYWORD}Chance on {C:KEYWORD}Attack to {C:KEYWORD}Attack again."
local LEGENDARY_TRIGGER = class(TRIGGERS.ON_ATTACK)
function LEGENDARY_TRIGGER:initialize(entity, direction, abilityStats)
    LEGENDARY_TRIGGER:super(self, "initialize", entity, direction, abilityStats)
    self.activationType = Tags.TRIGGER_CHANCE
end

function LEGENDARY_TRIGGER:process(currentEvent)
    local entity = self.entity
    local direction = Common.getDirectionTowards(entity.body:getPosition(), self.attackTarget)
    local attackAction = entity.melee:createAction(direction)
    return attackAction:parallelChainEvent(currentEvent:chainProgress(ATTACK_DELAY))
end

LEGENDARY.modifyItem = function(item)
    item.triggers:push(LEGENDARY_TRIGGER)
    item:markAltered(Tags.STAT_ABILITY_COOLDOWN, Tags.STAT_UPGRADED)
end
return ITEM

