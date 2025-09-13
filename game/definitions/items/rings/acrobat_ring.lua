local Vector = require("utils.classes.vector")
local Array = require("utils.classes.array")
local COLORS = require("draw.colors")
local Common = require("common")
local CONSTANTS = require("logic.constants")
local textStatFormat = require("text.stat_format")
local TRIGGERS = require("actions.triggers")
local ITEM = require("structures.item_def"):new("Acrobat Ring")
ITEM:setToMediumComplexity()
ITEM.slot = Tags.SLOT_RING
ITEM.icon = Vector:new(13, 4)
ITEM:setToStatsBase({ [Tags.STAT_ABILITY_COOLDOWN] = 25, [Tags.STAT_ABILITY_DAMAGE_BASE] = 16.8, [Tags.STAT_ABILITY_DAMAGE_VARIANCE] = Common.getVarianceForRatio(0.22), [Tags.STAT_ABILITY_RANGE] = 2, [Tags.STAT_ABILITY_PROJECTILE_SPEED] = CONSTANTS.PLAYER_PROJECTILE_SPEED })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
local FORMAT = "At the start of your turn, throw a {C:KEYWORD}Projectile towards an aligned " .. "enemy at least %s away that deals %s damage."
ITEM.getPassiveDescription = function(item)
    return textStatFormat(FORMAT, item, Tags.STAT_ABILITY_RANGE, Tags.STAT_ABILITY_DAMAGE_MIN)
end
local ON_HIT = class("actions.hit")
function ON_HIT:parallelResolve(anchor)
    ON_HIT:super(self, "parallelResolve", anchor)
    self.hit:setDamageFromAbilityStats(Tags.DAMAGE_TYPE_RANGED, self.abilityStats)
end

local TRIGGER = class(TRIGGERS.START_OF_TURN)
function TRIGGER:isEnabled()
    return self.entity.equipment:isReady(self:getSlot())
end

function TRIGGER:process(currentEvent)
    local speed = self.abilityStats:get(Tags.STAT_ABILITY_PROJECTILE_SPEED)
    local diagonalSpeed = round(speed / math.sqrtOf2)
    local minTarget = false
    local minDistance = math.huge
    local source = self.entity.body:getPosition()
    local range = self.abilityStats:get(Tags.STAT_ABILITY_RANGE)
    self.entity.agentvisitor:visit(function(agent)
        local target = agent.body:getPosition()
        if self:isVisible(target) then
            if self.entity.body:isAlignedTo(target) then
                local distance = source:distanceManhattan(target)
                if distance >= range and distance < minDistance then
                    minTarget = target
                    minDistance = distance
                end

            end

        end

    end, true, true)
    if minTarget then
        Common.playSFX("THROW")
        currentEvent, projectileEntity = self.entity.projectilespawner:spawn(currentEvent, Common.getDirectionTowards(source, minTarget), self.abilityStats, Vector:new(2, 1), false)
        currentEvent:chainEvent(function()
            projectileEntity.projectile.frozen = false
        end)
        self.entity.equipment:setOnCooldown(self:getSlot())
        self.entity.equipment:recordCast(self:getSlot())
    end

    return currentEvent
end

ITEM.triggers:push(TRIGGER)
local LEGENDARY = ITEM:createLegendary("One Thousand Cuts")
LEGENDARY.strokeColor = COLORS.STANDARD_STEEL
LEGENDARY_EXTRA_LINE = "Reduce this ring's cooldown by %s whenever you {C:KEYWORD}Attack an adjacent enemy."
LEGENDARY:setToStatsBase({ [Tags.STAT_MODIFIER_VALUE] = 5 })
LEGENDARY:addPowerSpike({ [Tags.STAT_MODIFIER_VALUE] = 1 })
LEGENDARY:addPowerSpike({ [Tags.STAT_MODIFIER_VALUE] = 1 })
LEGENDARY:addPowerSpike({ [Tags.STAT_MODIFIER_VALUE] = 1 })
LEGENDARY.passiveExtraLine = function(item)
    return textStatFormat(LEGENDARY_EXTRA_LINE, item, Tags.STAT_MODIFIER_VALUE)
end
local LEGENDARY_TRIGGER = class(TRIGGERS.ON_ATTACK)
function LEGENDARY_TRIGGER:initialize(entity, direction, abilityStats)
    LEGENDARY_TRIGGER:super(self, "initialize", entity, direction, abilityStats)
    self.sortOrder = -2
end

function LEGENDARY_TRIGGER:isEnabled()
    if not self.entity.equipment:isReady(self:getSlot()) then
        if self.attackTarget:distanceManhattan(self.entity.body:getPosition()) <= 1 then
            return self.entity.body:hasEntityWithAgent(self.attackTarget)
        end

    end

    return false
end

function LEGENDARY_TRIGGER:process(currentEvent)
    self.entity.equipment:reduceCooldown(self:getSlot(), self.abilityStats:get(Tags.STAT_MODIFIER_VALUE))
    return currentEvent
end

LEGENDARY.modifyItem = function(item)
    item.triggers:push(LEGENDARY_TRIGGER)
end
return ITEM

