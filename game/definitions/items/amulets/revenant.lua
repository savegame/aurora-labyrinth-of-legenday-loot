local Vector = require("utils.classes.vector")
local Array = require("utils.classes.array")
local CONSTANTS = require("logic.constants")
local COLORS = require("draw.colors")
local TRIGGERS = require("actions.triggers")
local Common = require("common")
local TERMS = require("text.terms")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.amulet_def"):new("Revenant's Amulet")
ITEM.className = "Revenant"
ITEM.classSprite = Vector:new(16, 2)
ITEM.icon = Vector:new(20, 19)
ITEM:setToStatsBase({ [Tags.STAT_ABILITY_DAMAGE_BASE] = 10.85, [Tags.STAT_ABILITY_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.51) })
local FORMAT_1 = "Whenever you kill an enemy, that enemy makes a random attack against another " .. "enemy before dying."
local FORMAT_2 = "Whenever you get hit by an enemy, gain %s mana."
ITEM.getPassiveDescription = function(item)
    return Array:new(FORMAT_1, textStatFormat(FORMAT_2, item, Tags.STAT_ABILITY_DAMAGE_MIN))
end
local POST_HIT = class(TRIGGERS.POST_HIT)
function POST_HIT:process(currentEvent)
    local value = self.entity.hitter:rollDamage(self.abilityStats:get(Tags.STAT_ABILITY_DAMAGE_MIN), self.abilityStats:get(Tags.STAT_ABILITY_DAMAGE_MAX))
    self.entity.mana:restoreSilent(value)
    return currentEvent
end

local ON_KILL = class(TRIGGERS.ON_KILL)
function ON_KILL:parallelResolve(currentEvent)
    self.killed.tank.delayDeath = true
end

local EFFECT_DELAY = 0.3
function ON_KILL:doAttackAction(currentEvent, action)
    currentEvent = currentEvent:chainProgress(EFFECT_DELAY)
    return action:parallelChainEvent(currentEvent):chainEvent(function(_, anchor)
        self.killed.tank:undelayDeath(anchor)
    end)
end

function ON_KILL:process(currentEvent)
    local killed = self.killed
    local entity = self.entity
    local directions = DIRECTIONS_AA:shuffle(self:getLogicRNG())
    for i = 1, CONSTANTS.ENEMY_PROJECTILE_SPEED do
        for iDir, direction in ipairs(directions) do
            local target = self.position + Vector[direction] * i
                        if entity.body:getPosition() == target or not entity.body:canBePassable(target) then
                directions[iDir] = false
            elseif entity.vision:isVisible(target) and killed.body:hasEntityWithAgent(target) then
                local action
                                if i == 1 and killed.agent:hasMeleeAttack() then
                    local action = killed.melee:createAction(direction)
                    return self:doAttackAction(currentEvent, action)
                elseif killed.agent:hasRangedAttack() then
                    local action = killed.ranged:createAction(direction)
                    return self:doAttackAction(currentEvent, action)
                end

            end

        end

        if not killed.agent:hasRangedAttack() then
            break
        end

        directions:acceptSelf(returnSelf)
    end

    return currentEvent:chainEvent(function(_, anchor)
        self.killed.tank:undelayDeath(anchor)
    end)
end

function ON_KILL:isEnabled()
    if not self.entity.vision:isVisible(self.position) then
        return false
    end

    return self.killed:hasComponent("agent")
end

ITEM.triggers:push(POST_HIT)
ITEM.triggers:push(ON_KILL)
local LEGENDARY = ITEM:createLegendary("Heart of Darkness")
LEGENDARY.statLine = TERMS.LEGENDARY_AMULET_DESCRIPTION
LEGENDARY.strokeColor = COLORS.STANDARD_DEATH
return ITEM

