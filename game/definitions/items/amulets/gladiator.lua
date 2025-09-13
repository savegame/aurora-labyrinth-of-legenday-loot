local Vector = require("utils.classes.vector")
local Array = require("utils.classes.array")
local BUFFS = require("definitions.buffs")
local COLORS = require("draw.colors")
local TERMS = require("text.terms")
local textStatFormat = require("text.stat_format")
local ActionUtils = require("actions.utils")
local TRIGGERS = require("actions.triggers")
local PLAYER_TRIGGERS = require("actions.player_triggers")
local ITEM = require("structures.amulet_def"):new("Gladiator's Amulet")
ITEM.className = "Gladiator"
ITEM.classSprite = Vector:new(20, 1)
ITEM.icon = Vector:new(13, 19)
ITEM:setToStatsBase({ [Tags.STAT_ABILITY_VALUE] = 2 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_VALUE] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_VALUE] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_VALUE] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_VALUE] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_VALUE] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_VALUE] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_VALUE] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_VALUE] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_VALUE] = 1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_VALUE] = 1 })
local FORMAT_1 = "Once per turn when you kill an enemy with an {C:KEYWORD}Attack, {C:KEYWORD}Attack another enemy."
local FORMAT_2 = "After you take damage from an enemy, gain {C:KEYWORD}Resist %s until the next turn."
ITEM.getPassiveDescription = function(item)
    return Array:new(FORMAT_1, textStatFormat(FORMAT_2, item, Tags.STAT_ABILITY_VALUE))
end
local TRIGGER = class(PLAYER_TRIGGERS.ATTACK_ANOTHER)
local STOPPER_BUFF = BUFFS:define("GLADIATOR_STOPPER")
function STOPPER_BUFF:initialize(duration)
    STOPPER_BUFF:super(self, "initialize", duration)
    self.expiresAtStart = true
end

function TRIGGER:initialize(entity, direction, abilityStats)
    TRIGGER:super(self, "initialize", entity, direction, abilityStats)
    self.targetEntity = false
end

function TRIGGER:parallelResolve(currentEvent)
    local entityAt = self.entity.body:getEntityAt(self.attackTarget)
    if ActionUtils.isAliveAgent(entityAt) then
        self.targetEntity = entityAt
    end

end

function TRIGGER:isAttackValid(entityAt, direction)
    if self.entity.buffable:isAffectedBy(STOPPER_BUFF) then
        return false
    end

    return self.targetEntity and not ActionUtils.isAliveAgent(self.targetEntity)
end

function TRIGGER:doAttack(currentEvent, direction)
    self.entity.buffable:forceApply(STOPPER_BUFF:new(1))
    return TRIGGER:super(self, "doAttack", currentEvent, direction)
end

local BUFF = BUFFS:define("GLADIATOR_DEFENSIVE")
function BUFF:initialize(duration, reduction)
    BUFF:super(self, "initialize", duration)
    self.expiresAtStart = true
    self.reduction = reduction
end

function BUFF:getDataArgs()
    return self.duration, self.reduction
end

function BUFF:decorateIncomingHit(hit)
    if hit:isDamagePositiveDirect() then
        hit:reduceDamage(self.reduction)
        hit:decreaseBonusState()
    end

end

local POST_HIT = class(TRIGGERS.POST_HIT)
function POST_HIT:isEnabled()
    return self.hit:isDamagePositiveDirect()
end

function POST_HIT:process(currentEvent)
    self.entity.buffable:apply(BUFF:new(1, self.abilityStats:get(Tags.STAT_ABILITY_VALUE)))
    return currentEvent
end

ITEM.triggers:push(TRIGGER)
ITEM.triggers:push(POST_HIT)
local LEGENDARY = ITEM:createLegendary("Legionsbane")
LEGENDARY.statLine = TERMS.LEGENDARY_AMULET_DESCRIPTION
LEGENDARY.strokeColor = COLORS.STANDARD_STEEL
return ITEM

