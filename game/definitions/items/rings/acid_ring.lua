local Vector = require("utils.classes.vector")
local COLORS = require("draw.colors")
local Common = require("common")
local BUFFS = require("definitions.buffs")
local ActionUtils = require("actions.utils")
local TRIGGERS = require("actions.triggers")
local textStatFormat = require("text.stat_format")
local ITEM = require("structures.item_def"):new("Acid Ring")
ITEM.slot = Tags.SLOT_RING
ITEM.icon = Vector:new(17, 20)
ITEM:setToStatsBase({ [Tags.STAT_ABILITY_COOLDOWN] = 16, [Tags.STAT_POISON_DAMAGE_BASE] = 6, [Tags.STAT_ABILITY_DEBUFF_DURATION] = 3, [Tags.STAT_ABILITY_RANGE] = 2 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
ITEM:addPowerSpike({ [Tags.STAT_ABILITY_COOLDOWN] = -1 })
local FORMAT = "At the start of your turn, {C:KEYWORD}Poison a random enemy within %s, " .. "making it lose %s health over %s."
ITEM.getPassiveDescription = function(item)
    return textStatFormat(FORMAT, item, Tags.STAT_ABILITY_RANGE, Tags.STAT_POISON_DAMAGE_TOTAL, Tags.STAT_ABILITY_DEBUFF_DURATION)
end
local TRIGGER = class(TRIGGERS.START_OF_TURN)
local TRAVEL_DURATION = 0.14
function TRIGGER:initialize(entity, direction, abilityStats)
    TRIGGER:super(self, "initialize", entity, direction, abilityStats)
    self:addComponent("acidspit")
end

function TRIGGER:isEnabled()
    return self.entity.equipment:isReady(self:getSlot())
end

function TRIGGER:process(currentEvent)
    local range = self.abilityStats:get(Tags.STAT_ABILITY_RANGE)
    local source = self.entity.body:getPosition()
    local targetEntity = self.entity.agentvisitor:visit(function(agent)
        local target = agent.body:getPosition()
        if self:isVisible(target) then
            local distance = source:distanceManhattan(target)
            if distance <= range then
                if distance < 2 then
                    return agent
                else
                    local direction = Common.getDirectionTowards(source, target, false, true)
                    if direction % 2 == 1 or self.entity.body:isPassable(source + Vector[direction]) then
                        return agent
                    end

                end

            end

        end

    end, true, true)
    if targetEntity then
        local target = targetEntity.body:getPosition()
        local distance = source:distanceEuclidean(target)
        self.entity.equipment:setOnCooldown(self:getSlot(), 1)
        self.entity.equipment:recordCast(self:getSlot())
        Common.playSFX("VENOM_SPIT", 1.65, 0.4)
        return self.acidspit:chainSpitEvent(currentEvent, distance * TRAVEL_DURATION, target):chainEvent(function(_, anchor)
            if ActionUtils.isAliveAgent(targetEntity) then
                local hit = self.entity.hitter:createHit()
                local poisonDamage = self.abilityStats:get(Tags.STAT_POISON_DAMAGE_TOTAL)
                local duration = self.abilityStats:get(Tags.STAT_ABILITY_DEBUFF_DURATION)
                hit.sound = "POISON_DAMAGE"
                hit:addBuff(BUFFS:get("POISON"):new(duration, self.entity, poisonDamage))
                hit:applyToEntity(anchor, targetEntity)
            end

        end)
    else
        return currentEvent
    end

end

ITEM.triggers:push(TRIGGER)
local LEGENDARY = ITEM:createLegendary("Caustic Emerald")
LEGENDARY.strokeColor = COLORS.STANDARD_POISON
LEGENDARY.passiveExtraLine = "Your {C:KEYWORD}Poisons take health at the start of the enemy's " .. "turn instead of at the end."
LEGENDARY.decorateOutgoingHit = function(entity, hit, abilityStats)
    for buff in hit.buffs() do
        if BUFFS:get("POISON"):isInstance(buff) then
            buff.expiresAtStart = true
        end

    end

end
return ITEM

